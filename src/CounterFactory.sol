// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Counter.sol";

contract CounterFactory {
    function deployCounter(bytes32 salt) public returns (address) {
        return address(new Counter{salt: salt}());
    }

    function predictCounterAddress(bytes32 salt) public view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(type(Counter).creationCode)
        )))));
    }
}
