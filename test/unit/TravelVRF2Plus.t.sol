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

    function testRandomWordsGenerationWithinRange() public {
        // seed = bound(seed, 100, 1e36); // limit the seed to a reasonable range
        // require(seed >= 100 && seed <= 1e36);
        (uint8 minNum, uint8 maxNum) = (1, 6);
        uint256 size = 12;
        for (uint256 i = 0; i < size; i++) {
            uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(i), i)));
            console.log("Generating random words with seed %s", seed);
            (uint256 init_state, uint8[] memory words) = travelVRF2Plus.generateNumbers(size, seed, minNum, maxNum);
            console.log("Initial state: %s", init_state);
            console.log("Generated %s words", words.length);
            assertEq(words.length, size, "Invalid number of words generated");

            for (uint256 index = 0; index < words.length; index++) {
                uint256 word = words[index];
                assertEq(true, word >= 1 && word <= 6, "Invalid word value");
                console.log("Word %s: %s", index, word);
            }
        }
    }

    function testRandomWordsGenerationWithFuzzy(uint256 seed) public {
        // seed = bound(seed, 100, 1e36); // limit the seed to a reasonable range
        // require(seed >= 100 && seed <= 1e36);
        (uint8 minNum, uint8 maxNum) = (1, 6);
        uint256 size = 12;
        (uint256 init_state, uint8[] memory words) = travelVRF2Plus.generateNumbers(size, seed, minNum, maxNum);
        console.log("Initial state: %s", init_state);
        console.log("Generated %s words", words.length);
        assertEq(words.length, size, "Invalid number of words generated");

        for (uint256 index = 0; index < words.length; index++) {
            uint256 word = words[index];
            assertEq(true, word >= 1 && word <= 6, "Invalid word value");
            console.log("Word %s: %s", index, word);
        }
    }
}
