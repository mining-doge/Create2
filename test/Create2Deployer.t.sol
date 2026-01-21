// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Create2Deployer} from "../src/Create2Deployer.sol";
import {Counter} from "../src/Counter.sol";

contract Create2DeployerTest is Test {
    Create2Deployer public deployer;

    function setUp() public {
        deployer = new Create2Deployer();
    }

    function test_Deploy() public {
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 salt = keccak256("test-salt");

        bytes32 bytecodeHash = deployer.computeBytecodeHash(bytecode);
        address predicted = deployer.predictAddress(salt, bytecodeHash);

        address deployed = deployer.deploy(bytecode, salt);

        assertEq(deployed, predicted, "Deployed address should match predicted address");
        assertTrue(deployed.code.length > 0, "Contract should be deployed");

        // Verify it's actually a Counter
        Counter counter = Counter(deployed);
        counter.setNumber(42);
        assertEq(counter.number(), 42);
    }

    function test_RevertIf_EmptyBytecode() public {
        bytes memory bytecode = "";
        bytes32 salt = keccak256("test-salt-empty");

        vm.expectRevert("Create2Deployer: bytecode cannot be empty");
        deployer.deploy(bytecode, salt);
    }

    function test_RevertIf_AlreadyDeployed() public {
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 salt = keccak256("test-salt-duplicate");

        deployer.deploy(bytecode, salt);

        vm.expectRevert("Create2Deployer: deployment failed");
        deployer.deploy(bytecode, salt);
    }

    function test_PredictAddress() public view {
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 salt = keccak256("test-salt-predict");
        bytes32 bytecodeHash = keccak256(bytecode);

        address predicted = deployer.predictAddress(salt, bytecodeHash);

        // Standard CREATE2 address calculation
        address expected = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(deployer),
            salt,
            bytecodeHash
        )))));

        assertEq(predicted, expected);
    }

    function test_ComputeBytecodeHash() public view {
        bytes memory bytecode = type(Counter).creationCode;
        bytes32 expectedHash = keccak256(bytecode);
        bytes32 actualHash = deployer.computeBytecodeHash(bytecode);
        assertEq(actualHash, expectedHash);
    }

    function test_DeployWithConstructorArguments() public {
        // Since Counter doesn't have constructor arguments, let's just use it anyway
        // or imagine a contract that does.
        // For this example, we can just use Counter and append some dummy data if we wanted to,
        // but that would change the bytecode.

        bytes memory bytecode = abi.encodePacked(type(Counter).creationCode);
        bytes32 salt = keccak256("test-salt-constructor");

        address deployed = deployer.deploy(bytecode, salt);
        assertTrue(deployed != address(0));
    }
}
