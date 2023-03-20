// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";


contract MyToken {
    constructor(){
    }
    function doSomething(address account) public view returns(bool Result){
        if (Address.isContract(account)) {
            return true;
        } else {
            return false;
        }
    }
    function sendEther(address payable recipient, uint256 amount) public {
        Address.sendValue(recipient, amount);
    }



}