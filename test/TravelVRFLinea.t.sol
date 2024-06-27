// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DeployTravelVRFLinea} from "../script/DeployVRFLinea.s.sol";
import {TravelVRFLinea} from "../src/TravelVRFLinea.sol";
import {VRFGatewayMock} from "./mocks/VRFGatewayMock.sol";
import {Test, console} from "forge-std/Test.sol";

contract TravelVRFLineaTest is Test {
    event RequestFulfilled(
        address indexed requester,
        uint256 indexed requestId,
        uint8 indexed dice,
        uint256 randomWord,
        uint256 paid,
        uint256 timestamp
    );

    address public OWNER = vm.addr(6433);
    address public USER = vm.addr(87);
    TravelVRFLinea private s_VRFLinea;
    VRFGatewayMock private s_VRFGateway;

    function setUp() external {
        vm.deal(OWNER, 100 ether);
        vm.deal(USER, 0.02 ether);
        vm.startPrank(OWNER);
        s_VRFGateway = new VRFGatewayMock();
        vm.stopPrank();
        DeployTravelVRFLinea deployer = new DeployTravelVRFLinea();
        s_VRFLinea = deployer.run(OWNER, address(s_VRFGateway));
    }

    function test_VRFLinea_requestRandomWords() public {
        vm.startPrank(USER);
        uint256 requestId = s_VRFLinea.requestRandomWords{value: 0.01 ether}();
        vm.stopPrank();
        assertEq(0, requestId);
    }

    function test_VRFLinea_requestRandomWords_by_Call() public {
        vm.startPrank(USER);
        (bool success, bytes memory data) = address(s_VRFLinea).call{
            value: 0.01 ether
        }(abi.encodeWithSignature("requestRandomWords()"));
        vm.stopPrank();
        uint256 requestId = abi.decode(data, (uint256));
        console.log("requestId: ", requestId);
        assertTrue(success);
    }

    function testFail_VRFLinea_requestRandomWords_by_Call(
        uint256 value
    ) public {
        uint256 input = (bound(value, 1, 9) / 1000) * 10 ** 18; // convert to wei
        vm.startPrank(USER);
        (bool success, bytes memory data) = address(s_VRFLinea).call{
            value: input
        }(abi.encodeWithSignature("requestRandomWords()"));
        vm.stopPrank();
        require(success == true);
    }

    function testFail_VRFLinea_requestRandomWords(uint256 value) public {
        uint256 input = (bound(value, 1, 9) / 1000) * 10 ** 18; // convert to wei
        vm.startPrank(USER);
        uint256 requestId = s_VRFLinea.requestRandomWords{value: input}();
        vm.stopPrank();
        assertEq(0, requestId);
    }

    function test_randomWordsWithFulfilled() public {
        vm.startPrank(USER);
        uint256 requestId = s_VRFLinea.requestRandomWords{value: 0.01 ether}();
        vm.stopPrank();
        vm.startPrank(OWNER);
        s_VRFGateway.fulfillRandomWords();
        vm.stopPrank();

        uint256[] memory gateway_randomNumbers = s_VRFGateway
            .getLastRandomWords();
        assertEq(1, gateway_randomNumbers.length);

        uint8 expect_dice = uint8(gateway_randomNumbers[0] % 6) + 1;

        (
            address requester,
            bool fulfilled,
            uint256 randomWord,
            uint8 dice,
            uint256 paid,
            uint256 timestamp
        ) = s_VRFLinea.getRequestStatus(requestId);
        assertEq(USER, requester);
        assertEq(true, fulfilled);
        assertEq(gateway_randomNumbers[0], randomWord);
        assertEq(expect_dice, dice);
        assertEq(0.01 ether, paid);
        assertEq(gateway_randomNumbers[0], timestamp);
    }
}
