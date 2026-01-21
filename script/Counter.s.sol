// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {console} from "forge-std/console.sol";  // ← 加这一行

contract CounterScript is Script {
    Counter public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new Counter();
        console.log("Counter deployed to:", address(counter));  // ← 加这一行

        vm.stopBroadcast();
    }
}
