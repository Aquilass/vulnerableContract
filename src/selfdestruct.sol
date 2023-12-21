// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Selfdestruct {
    address payable public owner;
    constructor() payable {
        owner = payable(msg.sender);
    }
    function destroy(address payable _to) public {
        require(msg.sender == owner);
        selfdestruct(_to);
    }
}