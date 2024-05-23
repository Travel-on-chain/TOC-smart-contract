// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CityNft} from "../src/CityNft.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

// contract UpgradeBox is Script {
//     function run() external returns (address) {
//         address mostRecentlyDeployedProxy = DevOpsTools
//             .get_most_recent_deployment("ERC1967Proxy", block.chainid);

//         vm.startBroadcast();

//         vm.stopBroadcast();
//         address proxy = upgradeBox(mostRecentlyDeployedProxy, address(newBox));
//         return proxy;
//     }

//     function upgradeBox(
//         address proxyAddress,
//         address newBox
//     ) public returns (address) {
//         vm.startBroadcast();
//         BoxV1 proxy = BoxV1(payable(proxyAddress));
//         proxy.upgradeTo(address(newBox));
//         vm.stopBroadcast();
//         return address(proxy);
//     }
// }
