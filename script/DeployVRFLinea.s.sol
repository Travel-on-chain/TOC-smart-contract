// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {TravelVRFLinea} from "../src/TravelVRFLinea.sol";

// Deploy
// forge create --rpc-url https://rpc.sepolia.linea.build \
// --constructor-args "[args]" \
// --private-key [privateKey] \
// src/TravelVRFLinea.sol:TravelVRFLinea

// Verify
// forge verify-contract --constructor-args abi.encode("[args]") \
// --etherscan-api-key [apiKey] \
// --verifier-url https://api-sepolia.lineascan.build/api \
// src/TravelVRFLinea.sol:TravelVRFLinea --watch

contract DeployTravelVRFLinea is Script {
    function run(
        address _owner,
        address _VRFGateway
    ) public returns (TravelVRFLinea) {
        console.log("Deploying TravelVRFLinea");
        console.log("VRFGateway: ", _VRFGateway);
        vm.startBroadcast(_owner);
        TravelVRFLinea travelVRFLinea = new TravelVRFLinea(_VRFGateway);
        vm.stopBroadcast();
        return travelVRFLinea;
    }
}
