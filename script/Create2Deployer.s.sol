// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Create2Deployer} from "../src/Create2Deployer.sol";

contract Create2DeployerScript is Script {
    Create2Deployer public deployer;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        deployer = new Create2Deployer();

        vm.stopBroadcast();
    }
}
