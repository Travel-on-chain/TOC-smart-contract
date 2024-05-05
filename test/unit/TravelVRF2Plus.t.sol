// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TravelVRFV2Plus} from "../../src/TravelVRFV2Plus.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {Vm} from "forge-std/Vm.sol";

contract TravelVRF2PlusTest is Test {
    event ShuffledWords(uint256[] words);

    TravelVRFV2Plus travelVRF2Plus;
    HelperConfig.NetworkConfig networkConfig;

    function setUp() public {
        HelperConfig helperConfig = new HelperConfig(3, true);
        (
            address oracle,
            bytes32 jobId,
            uint256 chainlinkFee,
            address link,
            uint256 updateInterval,
            address priceFeed,
            uint256 subscriptionId,
            address vrfCoordinator,
            bytes32 keyHash,
            bytes memory extraArgs
        ) = helperConfig.activeNetworkConfig();

        networkConfig = HelperConfig.NetworkConfig(
            oracle,
            jobId,
            chainlinkFee,
            link,
            updateInterval,
            priceFeed,
            subscriptionId,
            vrfCoordinator,
            keyHash,
            extraArgs
        );

        if (vrfCoordinator == address(0)) {
            // If vrfCoordinator is not provided, use default value
            // It will be used to call the VRFCoordinatorMock contract, but not now.
            vrfCoordinator = address(1);
        }

        // Deploy TravelVRF2Plus contract
        console.log("Deploying TravelVRF2Plus contract...");
        travelVRF2Plus = new TravelVRFV2Plus(subscriptionId, vrfCoordinator, keyHash);
    }

    function testVRFShuffle() public {
        (uint256 minNumber, uint256 maxNumberWords) = travelVRF2Plus.getValueRangeOfWord();
        // Define a mapping to store the occurrence of each number
        uint256[] memory numberOccurrences = new uint256[](maxNumberWords + 1);

        for (uint256 i = 1; i <= maxNumberWords; i++) {
            numberOccurrences = new uint256[](maxNumberWords + 1);
            uint256 numWords = i;
            uint256 entropy = 123456789 % i; // using fixed entropy for testing purposes
            uint256[] memory shuffledWords = travelVRF2Plus.shuffle(minNumber, numWords, entropy);

            // Assert that the length of the array equals numWords
            assertEq(shuffledWords.length, numWords);

            // Check that the shuffled words are different
            // Check that each word occurs exactly once within the range [1, maxNumberWords]
            for (uint256 index = 0; index < shuffledWords.length; index++) {
                uint256 word = shuffledWords[index];
                assertEq(true, word >= 1 && word <= maxNumberWords, "Invalid word value");
                assertEq(true, numberOccurrences[word] == 0, "Duplicate word found");
                numberOccurrences[word] += 1;
            }
        }
    }
}
