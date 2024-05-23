// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address oracle;
        bytes32 jobId;
        uint256 chainlinkFee;
        address link;
        uint256 updateInterval;
        address priceFeed;
        uint256 subscriptionId;
        address vrfCoordinator;
        bytes32 keyHash;
        bytes extraArgs;
    }

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    /**
     * @dev Constructor initializes the network configuration for the active chain ID.
     * @param _version The version of the network configuration to use.
     * @param _useNativeToken Whether to use the native token for payments.
     */
    constructor(uint8 _version, bool _useNativeToken) {
        chainIdToNetworkConfig[11155111] = _version <= 2
            ? getSepoliaEthConfigV2()
            : getSepoliaEthConfigV2Plus(_useNativeToken);

        chainIdToNetworkConfig[31337] = getAnvilEthConfig(_useNativeToken);

        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    /**
     * @dev Get V2 VRF configuration from sepolia testnet.
     */
    function getSepoliaEthConfigV2()
        internal
        pure
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            oracle: 0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD,
            jobId: "ca98366cc7314957b8c012c72f05aeeb",
            chainlinkFee: 1e17,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            updateInterval: 60, // every minute
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH / USD
            subscriptionId: 0, // UPDATE ME!
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            extraArgs: bytes("")
        });
    }

    /**
     * @dev Get V2Plus VRF configuration from sepolia testnet.
     */
    function getSepoliaEthConfigV2Plus(
        bool _useNativeToken
    ) internal pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            oracle: 0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD,
            jobId: "ca98366cc7314957b8c012c72f05aeeb",
            chainlinkFee: 1e17,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            updateInterval: 60, // every minute
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH / USD
            subscriptionId: 0, // UPDATE ME!
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: _useNativeToken})
            )
        });
    }

    function getAnvilEthConfig(
        bool _useNativeToken
    ) internal pure returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            oracle: address(0), // This is a mock
            jobId: "6b88e0402e5d415eb946e528b8e0c7ba",
            chainlinkFee: 1e17,
            link: address(0), // This is a mock
            updateInterval: 60, // every minute
            priceFeed: address(0), // This is a mock
            subscriptionId: 0,
            vrfCoordinator: address(0), // This is a mock
            keyHash: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: _useNativeToken})
            )
        });
    }
}
