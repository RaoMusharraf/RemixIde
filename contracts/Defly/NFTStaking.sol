// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IIERC721.sol";

contract TokenStaking is Ownable,IERC721Receiver{

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public category1;
    Counters.Counter public category2;
    Counters.Counter public category3;
    Counters.Counter public category4;
    address public ERC721address;
    address public ERC20Address;
    uint256 public TotalRemaningToken;
    struct Detail{
        uint tokens;
        uint day;
        uint StartTime;
        uint NFT;
        bool DepositToken;
    }
    mapping (address => Detail) public Staker;
    // ============ Constructor ============
    /* 
        @dev get _ERC721address and _ERC20Address
        @param _ERC721address address of the minting NFT contract
        @param _ERC20Address address of the minting Token contract
    */
    constructor(address _ERC721address, address _ERC20Address) {
        ERC721address = _ERC721address;
        ERC20Address = _ERC20Address;
    }
    // ============ Deposit FUNCTIONS ============
    /* 
        @dev get token id  of NFT and Days for Stake 
        @param TokenId id of NFT 
    */
    function deposit(uint TokenId,uint Days) public {
        require (!Staker[msg.sender].DepositToken,"You Already Deposit NFT");
        if(Days == 15){
            category1.increment();
            require(category1.current() <=1000,"15 Days Category is Full !!!");
            Staker[msg.sender] = Detail(5000,Days,block.timestamp,TokenId,true);
            IERC721(ERC721address).safeTransferFrom(msg.sender,address(this),TokenId,"");
        }
        else if(Days == 30){
            category2.increment();
            require(category2.current() <=750,"30 Days Category is Full !!!");
            Staker[msg.sender] = Detail(7500,Days,block.timestamp,TokenId,true);
            IERC721(ERC721address).safeTransferFrom(msg.sender,address(this),TokenId,"");
        }
        else if(Days == 60){
            category3.increment();
            require(category3.current() <=500,"60 Days Category is Full !!!");
            Staker[msg.sender] = Detail(12500,Days,block.timestamp,TokenId,true);
            IERC721(ERC721address).safeTransferFrom(msg.sender,address(this),TokenId,"");
        }
        else if(Days == 90){
            category4.increment();
            require(category4.current() <=250,"90 Days Category is Full !!!");
            Staker[msg.sender] = Detail(17500,Days,block.timestamp,TokenId,true);
            IERC721(ERC721address).safeTransferFrom(msg.sender,address(this),TokenId,"");
        }
        else{
            revert("Sellect Days 15,30,60,90 !!!");
        }    
    }
    // ============ Withdraw FUNCTIONS ============
    /* 
        @dev get address and move NFTs and reward to the given address  
        @param _to address of the staker 
    */
    function withdraw (address _to) public {
        require (Staker[_to].DepositToken,"Please First Deposit NFT !!!");
        uint Time = ((block.timestamp - Staker[_to].StartTime)/(24*60*60));
        if(Time < Staker[_to].day){
            uint TokenDays = Time*(Staker[_to].tokens/Staker[_to].day);
            uint fine = (2*TokenDays)/100;
            IERC20(ERC20Address).safeTransfer(_to, TokenDays - fine);
            IERC20(ERC20Address).safeTransfer(0x000000000000000000000000000000000000dEaD, fine);
            IERC721(ERC721address).safeTransferFrom(address(this), _to,Staker[_to].NFT,"");
            TotalRemaningToken -= TokenDays;
            Staker[_to].DepositToken = false;
        }
        else{
            IERC20(ERC20Address).safeTransfer(_to, Staker[_to].tokens);
            IERC721(ERC721address).safeTransferFrom(address(this), _to,Staker[_to].NFT,"");
            TotalRemaningToken -= Staker[_to].tokens;
            Staker[_to].DepositToken = false;
        } 
        if(Staker[_to].day == 15){
            category1.decrement();
        }
        else if(Staker[_to].day == 30){
            category2.decrement();   
        }
        else if(Staker[_to].day == 60){
            category3.decrement();   
        }
        else if(Staker[_to].day == 90){
            category4.decrement();   
        }  
    }
    
    // ============= Admin Add Token Function ==============
    /*
        @dev Owner add tokens into contract with this function
        @param These tokens are used as rewards for staking
        @param Only Owner can call this function
    */
    function AdminAddToken(uint _amount) public onlyOwner{
        TotalRemaningToken += _amount;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,_amount);
    }
    function onERC721Received(address,address,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}