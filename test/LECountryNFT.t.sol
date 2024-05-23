// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {LECountryNFT} from "../src/LECountryNFT.sol";
import {LECountryNFTDeployer, LECountries} from "../script/LECountryNFT.t.sol";

contract LECountryNFTTest is Test {
    LECountryNFT public leCountryNFT;
    LECountries public leCountries;

    function setUp() public {
        LECountryNFTDeployer deployer = new LECountryNFTDeployer();
        (leCountryNFT, leCountries) = deployer.run();
    }
}
