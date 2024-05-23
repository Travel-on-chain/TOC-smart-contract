// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {LECountryNFT} from "../src/LECountryNFT.sol";
import {Script, console} from "forge-std/Script.sol";

struct LEINFO {
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

    function run(address owner) public returns (LECountryNFT, LEINFO memory) {
        LEINFO memory leINFO = LEINFO(DEFUALT_COUNTRIES, DEFUALT_MAX_SUPPLY);

        vm.startBroadcast(owner);
        console.log("Deploying LECountries contract with default values:");
        LECountryNFT leCountryNFT = new LECountryNFT(
            leINFO.countries,
            leINFO.maxSupply
        );
        vm.stopBroadcast();

        return (leCountryNFT, leINFO);
    }

    function run_with(
        address owner,
        LEINFO memory _leInfo
    ) public returns (LECountryNFT, LEINFO memory) {
        LEINFO memory leINFO = _leInfo;

        vm.startBroadcast(owner);
        console.log("Deploying LECountries contract with default values:");
        LECountryNFT leCountryNFT = new LECountryNFT(
            leINFO.countries,
            leINFO.maxSupply
        );
        vm.stopBroadcast();

        return (leCountryNFT, leINFO);
    }
}
