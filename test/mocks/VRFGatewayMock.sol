// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ISecretVRF, TravelVRFLinea} from "../../src/TravelVRFLinea.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console} from "forge-std/Test.sol";

contract VRFGatewayMock is ISecretVRF {
    error NotOwner();
    uint256 private s_requestId;
    uint32 private s_numWords;
    address private s_VRFConsumer;
    address private s_owner;
    uint256[] private s_RandomWords;

    modifier onlyOwner() {
        if (s_owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    constructor() {
        s_owner = msg.sender;
    }

    function getLastRandomWords() external view returns (uint256[] memory) {
        return s_RandomWords;
    }

    function requestRandomness(
        uint32 _numWords,
        uint32 _callbackGasLimit
    ) external payable override returns (uint256 requestId) {
        s_VRFConsumer = msg.sender;
        requestId = s_requestId;
        s_numWords = _numWords;
        s_requestId++;
        uint32 useless = _callbackGasLimit;
        console.log("In Gateway - requestId: ", requestId);
        return requestId;
    }

    function fulfillRandomWords() external onlyOwner {
        uint256[] memory words = new uint256[](s_numWords);
        for (uint256 i = 0; i < s_numWords; i++) {
            words[i] = block.timestamp;
        }
        console.log(
            "In Gateway - fulfillRandomWords: s_requestId--: ",
            s_requestId - 1
        );
        (bool success, bytes memory data) = s_VRFConsumer.call(
            abi.encodeWithSignature(
                "fulfillRandomWords(uint256,uint256[])",
                s_requestId - 1,
                words
            )
        );
        s_RandomWords = words;
        require(success, "failed to call VRFConsumer");
    }
}
