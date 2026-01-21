// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Create2Deployer} from "../src/Create2Deployer.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounterWithCreate2 is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 Create2Deployer（如果尚未部署）
        Create2Deployer deployer = new Create2Deployer();
        console.log("Create2Deployer deployed at:", address(deployer));

        // 2. 准备 Counter 的字节码和 salt
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("my.counter.salt.v1"));

        // 3. 预测地址
        bytes32 bytecodeHash = deployer.computeBytecodeHash(bytecode);
        address predictedAddress = deployer.predictAddress(salt, bytecodeHash);
        console.log("Predicted Counter address:", predictedAddress);

        // 4. 使用 Create2Deployer 部署 Counter
        address deployedAddress = deployer.deploy(bytecode, salt);
        console.log("Actual Counter deployed at:", deployedAddress);

        // 5. 验证
        require(predictedAddress == deployedAddress, "Address mismatch!");

        Counter(deployedAddress).setNumber(1);
        console.log("Counter initialized with number:", Counter(deployedAddress).number());

        vm.stopBroadcast();
    }
}
