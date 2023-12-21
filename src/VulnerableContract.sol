// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Test, console2} from "forge-std/Test.sol";
contract VulnerableContract is ReentrancyGuard{

    uint256 public total_amount = 0;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public keys;
    mapping(address => bool) public isGenKey;
    bool public breakReentrancy = false;
    constructor() payable {
        total_amount += msg.value;
        balances[msg.sender] += msg.value;
    }
    function isContract (address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    function keysAndBalancesAndIsGenKey(address user) external view returns (uint256, uint256, bool) {
        return (keys[user], balances[user], isGenKey[user]);
    }
    function _random() external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number))) % 100;
    }
    function genKey() external payable nonReentrant {
        require(!isContract(msg.sender), "Contract not allowed!"); // 需透過 constructor 使用
        require(msg.value == 0.001 ether, " 0.001 ether required");
        require(!isGenKey[msg.sender], "Already gen key");
        uint256 random = this._random();
        console2.log(random);
        uint256 priviledge;
        if (random < 10) {
            priviledge = 1;
        } else if (random < 30) {
            priviledge = 2;
        } else if (random < 60) {
            priviledge = 3;
        } else if (random < 90) {
            priviledge = 4;
        } else {
            priviledge = 5;
        }
        keys[msg.sender] = priviledge;
        balances[msg.sender] += msg.value;
        total_amount += msg.value;
        isGenKey[msg.sender] = true;
    }
    function claimDeposit(address user) external {
        require(keys[user] == 5, "Not enough priviledge"); // 需透過 genKey 先取得 priviledge
        // 需透過 self destruct 使用來 breach reentrancy
        if (address(this).balance > total_amount || breakReentrancy) {
            breakReentrancy = true;
        }
        require(breakReentrancy == true, "need to break reentrancy");
        require(msg.sender == user, "Not your balance");
        user.call{value: 0.001 ether}("");
        balances[user] = 0;
    }
    receive() external payable {
        revert("Attacked receive");
    }
    fallback() external payable {
        revert("Attacked fallback");
    }
}