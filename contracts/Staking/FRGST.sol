// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract Token is ERC20, Ownable,ERC20Burnable {

    // variables
    uint BuyTax;
    uint SellTax; 
    uint ReflectionSellTax;
    uint LPSellTax;
    uint InvestmentSellTax;
    uint ReflectionBuyTax;
    uint LPBuyTax;
    uint InvestmentBuyTax;
    address Reflection;
    address LP;
    address Investment;
    address public constant BURN_ADDRESS = 0x0000000000000000000000000000000000000000;
    // mappings
    mapping(address => bool) public whiteList;
    

    constructor(address _Reflection,address _LP,address _Investment) ERC20("Froggies Token", "FRGST") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
        Reflection = _Reflection;
        LP = _LP;
        Investment = _Investment;
    }

    // ============ WhiteList FUNCTIONS ============
    /* 
        @dev WhiteList take address as a parameter and make this address true in the whiteList.  
    */
    function WhiteList(address _address) public{
        whiteList[_address] = true;
    } 

    // ============ setBuyTax FUNCTIONS ============
    /* 
        @dev setBuyTax take Tax percentage as a parameter and set this percentage to BuyTax variable.  
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
        @dev setSellTax take Tax percentage as a parameter and set this percentage to SellTax variable.  
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

    // ============ setReflectionSellTax FUNCTIONS ============
    /* 
        @dev setReflectionSellTax take Tax percentage as a parameter and set this percentage to ReflectionSellTax variable.  
    */
    function setReflectionSellTax(uint Tax) public onlyOwner{
        ReflectionSellTax = Tax;
    }

    // ============ setLPSellTax FUNCTIONS ============
    /* 
        @dev setLPSellTax take Tax percentage as a parameter and set this percentage to LPSellTax variable.  
    */
    function setLPSellTax(uint Tax) public onlyOwner{
        LPSellTax = Tax;
    }

    // ============ setInvestmentSellTax FUNCTIONS ============
    /* 
        @dev setInvestmentSellTax take Tax percentage as a parameter and set this percentage to InvestmentSellTax variable.  
    */
    function setInvestmentSellTax(uint Tax) public onlyOwner{
        InvestmentSellTax = Tax;
    }

    // ============ setReflectionBuyTax FUNCTIONS ============
    /* 
        @dev setReflectionBuyTax take Tax percentage as a parameter and set this percentage to ReflectionBuyTax variable.  
    */
    function setReflectionBuyTax(uint Tax) public onlyOwner{
        ReflectionBuyTax = Tax;
    }

    // ============ setLPBuyTax FUNCTIONS ============
    /* 
        @dev setLPBuyTax take Tax percentage as a parameter and set this percentage to LPBuyTax variable.  
    */
    function setLPBuyTax(uint Tax) public onlyOwner{
        LPBuyTax = Tax;
    }

    // ============ setInvestmentBuyTax FUNCTIONS ============
    /* 
        @dev setInvestmentBuyTax take Tax percentage as a parameter and set this percentage to InvestmentBuyTax variable.  
    */
    function setInvestmentBuyTax(uint Tax) public onlyOwner{
        InvestmentBuyTax = Tax;
    }
}
