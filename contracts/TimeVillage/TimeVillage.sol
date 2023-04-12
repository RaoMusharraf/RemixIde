// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TimeVillageToken is ERC20, ERC20Burnable, Pausable, Ownable,ReentrancyGuard {

    using SafeERC20 for IERC20;
    bool public IsClaim;
    address AddminAddress;

    struct userRecord{
        uint Type;
        uint amount;
        uint tokens;
        bool claim;
    }
    struct roundDetail{
        uint roundTokenMax;
        uint soldToken;
        uint roundTokenPrice;
    }

    mapping (address => mapping(uint => userRecord)) public Record;
    mapping (uint => roundDetail) public Round;


    constructor(address ownerAddress) ERC20("Time Village Token", "TVT") {
        _mint(msg.sender, 2500000000 * 10 ** decimals());
        AddminAddress = ownerAddress;

    }

    //ADMIN START

    function setIsClaim(bool _check) public onlyOwner {
        IsClaim = _check;
    }
    function AdminAddToken(uint _amount) public onlyOwner{
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this) ,_amount);
    }
    function setRound(uint Type,uint maxToken,uint price) public onlyOwner{
        require(Type > 0 && Type < 4 , "Type Must Be (1,2,3)");
        Round[Type] = roundDetail(maxToken,0,price);
    }
    // END

    function buyTokens(address from,uint256 Type , uint256 amount) public payable nonReentrant {
        uint Tokens = generateToken(Type,amount);
        require(Type > 0 && Type < 4 , "Type Must Be (1,2,3)");
        require(!Record[from][Type].claim,"Cannot Enter In This Type");
        require((Round[Type].roundTokenMax - Round[Type].soldToken) >= Tokens,"Full");
        Round[Type].soldToken += Tokens;
        Record[from][Type] = userRecord(Type,Record[from][Type].amount + amount,Record[from][Type].tokens + Tokens,false);
        payable(AddminAddress).transfer(amount);    
    }
    function claim(address from,uint Type) public nonReentrant {
        require(Type > 0 && Type < 4 , "Type Must Be (1,2,3)");
        require(IsClaim,"Wait Please");  
        Record[from][Type].claim = true;
        IERC20(address(this)).safeTransfer(from, Record[from][Type].tokens);
    }
    function generateToken(uint Type,uint amount) public view returns(uint Tokens){
        require(Type > 0 && Type < 4 , "Type Must Be (1,2,3)");
        return (amount / Round[Type].roundTokenPrice);
    }


    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}