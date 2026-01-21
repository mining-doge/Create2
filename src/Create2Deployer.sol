// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ────────────────────────────────────────────────
// 扩展后的通用 CREATE2 工厂合约（类似 Arachnid 的 deterministic deployment proxy）
// ────────────────────────────────────────────────
// 这个合约可以部署任意字节码的合约，使用 CREATE2 确保跨链地址确定性。
// 要让这个工厂合约本身在多链上地址相同：
// 1. 准备一个新 EOA 地址（私钥相同），在每个目标链上都打入足够 gas。
// 2. 确保该 EOA 的 nonce 为 0（即从未发过交易）。
// 3. 从该 EOA 部署这个工厂合约（字节码完全相同，包括 pragma 版本）。
//    - 部署地址 = keccak256(rlp.encode([sender, nonce])) 的后 20 字节。
//    - 因为 sender 和 nonce=0 相同，所以多链地址相同。
// 4. 部署后，用工厂来部署其他合约（salt + bytecode 相同 → 地址相同）。
contract Create2Deployer {
    event Deployed(address indexed deployedAddress, bytes32 indexed salt);

    /**
     * @notice 使用 CREATE2 部署任意字节码的合约
     * @param bytecode 合约的 creation bytecode（包含 constructor 参数，如果有）
     * @param salt 任意 32 字节值，用于控制地址
     * @return deployedAddress 部署出来的合约地址
     * @dev 如果地址已存在，会 revert（除非 bytecode 匹配现有合约）。
     *      使用内联 assembly 实现，因为标准 'new' 不支持任意 bytecode。
     */
    function deploy(bytes memory bytecode, bytes32 salt) public returns (address deployedAddress) {
        // 检查 bytecode 非空
        require(bytecode.length != 0, "Create2Deployer: bytecode cannot be empty");

        // 使用 CREATE2 部署（assembly 方式）
        assembly {
            deployedAddress := create2(
                0,                       // value: 不转账 ETH
                add(bytecode, 0x20),     // bytecode 偏移（跳过 length 前缀）
                mload(bytecode),         // bytecode 长度
                salt                     // salt
            )
        }
        

        // 检查部署成功
        require(deployedAddress != address(0), "Create2Deployer: deployment failed");

        emit Deployed(deployedAddress, salt);
    }

    /**
     * @notice 预测某个 salt + bytecode 下合约将会被部署到的地址
     * @param salt 相同的 salt 值
     * @param bytecodeHash keccak256(bytecode) – bytecode 的哈希（因为实际部署用的是 hash）
     * @return 预测的合约地址
     * @dev 公式：keccak256(0xff ++ factory地址 ++ salt ++ keccak256(bytecode)) 的后 20 字节
     */
    function predictAddress(bytes32 salt, bytes32 bytecodeHash) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),       // 工厂合约自己的地址（deployer）
                salt,
                bytecodeHash         // keccak256(bytecode)
            )
        );

        // 取 hash 的后 20 字节作为地址
        return address(uint160(uint256(hash)));
    }

    /**
     * @notice 辅助函数：计算任意 bytecode 的哈希（供 predictAddress 用）
     * @param bytecode 合约的 creation bytecode
     * @return bytecodeHash keccak256(bytecode)
     */
    function computeBytecodeHash(bytes memory bytecode) public pure returns (bytes32) {
        return keccak256(bytecode);
    }

    // ────────────────────────────────────────────────
    // 示例：如何用这个工厂部署 Counter（或其他合约）
    // ────────────────────────────────────────────────
    // 在脚本或测试中：
    // bytes memory bytecode = type(Counter).creationCode;  // 无参数
    // // 或带参数：abi.encodePacked(type(Counter).creationCode, abi.encode(param1, param2));
    // bytes32 salt = keccak256("my-salt-v1");
    // address predicted = factory.predictAddress(salt, factory.computeBytecodeHash(bytecode));
    // address deployed = factory.deploy(bytecode, salt);
    // assert(predicted == deployed);
}