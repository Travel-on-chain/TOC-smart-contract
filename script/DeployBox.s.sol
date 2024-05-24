// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CityNft} from "../src/CityNft.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBox is Script {
    function run() external returns (address) {
        address proxy = deployBox();
        return proxy;
    }

    function deployBox() public returns (address) {
        vm.startBroadcast();
        CityNft box = new CityNft();
        ERC1967Proxy proxy = new ERC1967Proxy(address(box), "");
        CityNft(address(proxy)).initialize();
        vm.stopBroadcast();
        return address(proxy);
    }
}
