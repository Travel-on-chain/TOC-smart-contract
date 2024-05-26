// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CityNft} from "../src/CityNft.sol";
import {CityNftV2} from "../src/CityNftV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "@devops/src/DevOpsTools.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        //暂时还读取不到ffi中的内容
        // address mostRecentlyDeployedProxy = DevOpsTools
        //     .get_most_recent_deployment("ERC1967Proxy", block.chainid);

        //暂时写死上一步已经部署的地址
        address mostRecentlyDeployedProxy = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        vm.startBroadcast();
        CityNftV2 newBox = new CityNftV2();
        vm.stopBroadcast();
        address proxy = upgradeBox(mostRecentlyDeployedProxy, address(newBox));
        return proxy;
    }

    function upgradeBox(
        address proxyAddress,
        address newBox
    ) public returns (address) {
        vm.startBroadcast();
        CityNft proxy = CityNft(payable(proxyAddress));
        proxy.upgradeTo(address(newBox));
        vm.stopBroadcast();
        return address(proxy);
    }
}
