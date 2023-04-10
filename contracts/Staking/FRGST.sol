// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {

    // variables
    uint BuyTax;
    uint SellTax; 
    // mappings
    mapping(address => bool) public whiteList;

    constructor() ERC20("Froggies Token", "FRGST") {
        _mint(msg.sender, 100_000_000_000_000_000 * 10 ** decimals());
    }

    // ============ WhiteList FUNCTIONS ============
    /* 
        @dev WhiteList take address as a perameter and make this address true in the whiteList.  
    */
    function WhiteList(address _address) public{
        whiteList[_address] = true;
    } 

    // ============ setBuyTax FUNCTIONS ============
    /* 
        @dev setBuyTax take Tax percentage as a perameter and set this percentage to BuyTax variable.  
    */
    function setBuyTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        BuyTax = Tax;
    } 

    // ============ getBuyTax FUNCTIONS ============
    /* 
        @dev getBuyTax return BuyTax percentage .  
    */
    function getBuyTax() public view returns(uint _BuyTax){
        return BuyTax;
    }

    // ============ setSellTax FUNCTIONS ============
    /* 
        @dev setSellTax take Tax percentage as a perameter and set this percentage to SellTax variable.  
    */
    function setSellTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        SellTax = Tax;
    }

    // ============ getSellTax FUNCTIONS ============
    /* 
        @dev getSellTax return SellTax percentage .  
    */
    function getSellTax() public view returns(uint _SellTax){
        return SellTax;
    }
}
