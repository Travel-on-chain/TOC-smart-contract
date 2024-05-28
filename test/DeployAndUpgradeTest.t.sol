// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CityNft} from "../src/CityNft.sol";
import {CityNftV2} from "../src/CityNftV2.sol";

contract DeployAndUpgradeTest is StdCheats, Test {
    DeployBox public deployBox;
    UpgradeBox public upgradeBox;
    address public OWNER = address(1);

    function setUp() public {
        deployBox = new DeployBox();
        upgradeBox = new UpgradeBox();
    }

    function testBoxWorks() public {
        address proxyAddress = deployBox.deployBox();
        uint256 expectedValue = 1;
        assertEq(expectedValue, CityNft(proxyAddress).version());
    }

    // function testDeploymentIsV1() public {
    //     address proxyAddress = deployBox.deployBox();
    //     uint256 expectedValue = 7;
    //     vm.expectRevert();
    //     CityNftV2(proxyAddress).setValue(expectedValue);
    // }

    function testUpgradeWorks() public {
        address proxyAddress = deployBox.deployBox();

        CityNftV2 box2 = new CityNftV2();

        // vm.prank(CityNft(proxyAddress).owner());
        // CityNft(proxyAddress).transferOwnership(msg.sender);

        //start upgrade
        address proxy = upgradeBox.upgradeBox(proxyAddress, address(box2));

        uint256 expectedValue = 2;
        assertEq(expectedValue, CityNftV2(proxy).version());
    }
}
