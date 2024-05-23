// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {LECountryNFT} from "../src/LECountryNFT.sol";
import {Script, console} from "forge-std/Script.sol";

struct LECountries {
    string[] countries;
    uint16 maxSupply;
}

contract LECountryNFTDeployer is Script {
    uint16 private constant DEFUALT_MAX_SUPPLY = 10;
    string[] private DEFUALT_COUNTRIES = [
        "Shanghai",
        "Beijing",
        "Sichuan",
        "Zhejiang"
    ];

    function run() public returns (LECountryNFT, LECountries memory) {
        LECountries memory leCountries = LECountries(
            DEFUALT_COUNTRIES,
            DEFUALT_MAX_SUPPLY
        );

        vm.startBroadcast();
        console.log("Deploying LECountries contract with default values:");
        LECountryNFT leCountryNFT = new LECountryNFT(
            leCountries.countries,
            leCountries.maxSupply
        );
        vm.stopBroadcast();

        return (leCountryNFT, leCountries);
    }
}
