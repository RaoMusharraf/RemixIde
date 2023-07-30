// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TransferBNB is Ownable {

    address Owner;

    constructor(address _owner){
        Owner = _owner;
    }
    // ============ ownerDeposit FUNCTIONS ============
    /* 
        @param _owner,_price are the parameter of the function _owner is the owner address and _price is the deposit amount
        @dev ownerDeposit Owner wants to deposit their amount in the contract; 
    */
    function ownerDeposit(address _owner,uint256 _price) payable external {
        require(Owner == _owner,"You are Not Owner!");
        require(_price > 0,"Price Must be greater/equal to 1 !");
       
    }
    // ============ ownerWithdraw FUNCTIONS ============
    /* 
        @param _owner,_price are the parameter of the function _owner is the owner address and _price is the deposit amount
        @dev ownerDeposit Owner wants to withdraw their amount from the contract; 
    */
    function ownerWithdraw(address _owner,uint _price) payable external {
        require(Owner == _owner,"You are Not Owner!");
        payable(Owner).transfer(_price);
    }
    // ============ ownerDeposit FUNCTIONS ============
    /* 
        @param _owner is the parameter of the function _owner is the owner address.
        @dev checkBalance owner wants to see their Contract amount.
        @returns balance return the total amount of the Owner that are in the contract.
    */
    function checkBalance(address _owner) external view returns(uint balance) {
        require(Owner == _owner,"You are Not Owner!");
        return address(this).balance;
    }
    // ============ userDeposit FUNCTIONS ============
    /* 
        @param _price are the parameter of the function _price is the deposit amount
        @dev userDeposit user wants to deposit their amount in the contract; 
    */
    function userDeposit(uint _price) payable external {
        require(_price > 0,"Price Must be greater/equal to 1 !");
    }
    // ============ userWithdraw FUNCTIONS ============
    /* 
        @param _user,_price are the parameter of the function _user is the user address and _price is the withdraw amount.
        @dev userDeposit user wants to withdraw their amount from the contract; 
    */  
    function userWithdraw(address _user,uint _price)  payable external {
        payable(_user).transfer(_price);
    }
}