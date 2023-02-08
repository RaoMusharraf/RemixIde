// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IIERC721.sol";

contract NFTstaking is Ownable,IERC721Receiver{

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
        address mint721;
        uint tokens;
        uint day;
        uint StartTime;
        uint NFT;
        uint count ;
        bool DepositToken;
    }
    struct ERCCount{
        uint tokenId;
        address mintContract;
    }
    uint256 amount = 1000000000000000000;
    mapping (address => mapping(address => mapping(uint => Detail))) public Staker;
    // mapping (address => mapping(uint256 => mapping(uint256 => address))) public ERCDetail;
    mapping (address => mapping(uint => ERCCount)) public ERCDetail;
    mapping (address => mapping(uint => uint)) public Count;
    mapping (address => uint) public countDeposit;
    // ============ Constructor ============
    /* 
        @dev get _ERC721address and _ERC20Address
        @param _ERC721address address of the minting NFT contract
        @param _ERC20Address address of the minting Token contract
    */
    constructor(address _ERC20Address) {
        // ERC721address = _ERC721address;
        ERC20Address = _ERC20Address;
    }
    // ============ Deposit FUNCTIONS ============
    /* 
        @dev get token id  of NFT and Days for Stake 
        @param TokenId id of NFT 
    */
    function deposit(uint TokenId,uint Days,address _to,address _mintAddress) public {
        require (!Staker[_to][_mintAddress][TokenId].DepositToken,"You Already Deposit NFT");
        if(Days == 15){
            category1.increment();
            require(category1.current() <=1000,"15 Days Category is Full !!!");
            if(Staker[_to][_mintAddress][TokenId].NFT == 0 ){
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(5000*amount),Days,block.timestamp,TokenId,countDeposit[_to],true);
                ERCDetail[_to][countDeposit[_to]] = ERCCount(TokenId,_mintAddress);
                Count[_mintAddress][TokenId] = countDeposit[_to] ;
                countDeposit[_to] += 1;
            }else{
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(5000*amount),Days,block.timestamp,TokenId,Staker[_to][_mintAddress][TokenId].count,true);
            }
            IERC721(_mintAddress).safeTransferFrom(_to,address(this),TokenId,"");
        }
        else if(Days == 30){
            category2.increment();
            require(category2.current() <=750,"30 Days Category is Full !!!");
            if(Staker[_to][_mintAddress][TokenId].NFT == 0 ){
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(7500*amount),Days,block.timestamp,TokenId,countDeposit[_to],true);
                ERCDetail[_to][countDeposit[_to]] = ERCCount(TokenId,_mintAddress);
                Count[_mintAddress][TokenId] = countDeposit[_to] ;
                countDeposit[_to] += 1;
            }else{
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(7500*amount),Days,block.timestamp,TokenId,Staker[_to][_mintAddress][TokenId].count,true);
            }
            IERC721(_mintAddress).safeTransferFrom(_to,address(this),TokenId,"");
        }
        else if(Days == 60){
            category3.increment();
            require(category3.current() <=500,"60 Days Category is Full !!!");
            if(Staker[_to][_mintAddress][TokenId].NFT == 0 ){
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(12500*amount),Days,block.timestamp,TokenId,countDeposit[_to],true);
                ERCDetail[_to][countDeposit[_to]] = ERCCount(TokenId,_mintAddress);
                Count[_mintAddress][TokenId] = countDeposit[_to] ;
                countDeposit[_to] += 1;
            }else{
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(12500*amount),Days,block.timestamp,TokenId,Staker[_to][_mintAddress][TokenId].count,true);
            }
            IERC721(_mintAddress).safeTransferFrom(_to,address(this),TokenId,"");
        }
        else if(Days == 90){
            category4.increment();
            require(category4.current() <=250,"90 Days Category is Full !!!");
            if(Staker[_to][_mintAddress][TokenId].NFT == 0 ){
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(17500*amount),Days,block.timestamp,TokenId,countDeposit[_to],true);
                ERCDetail[_to][countDeposit[_to]] = ERCCount(TokenId,_mintAddress);
                Count[_mintAddress][TokenId] = countDeposit[_to] ;
                countDeposit[_to] += 1;
            }else{
                Staker[_to][_mintAddress][TokenId] = Detail(_mintAddress,(17500*amount),Days,block.timestamp,TokenId,Staker[_to][_mintAddress][TokenId].count,true);
            }
            IERC721(_mintAddress).safeTransferFrom(_to,address(this),TokenId,"");
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
    function withdraw (uint TokenId,address _to,address _mintAddress) public {
        require (Staker[_to][_mintAddress][TokenId].DepositToken,"Please First Deposit NFT !!!");
        uint Time = ((block.timestamp - Staker[_to][_mintAddress][TokenId].StartTime)/(24*60*60));
        if(Time < Staker[_to][_mintAddress][TokenId].day){
            uint TokenDays = Time*(Staker[_to][_mintAddress][TokenId].tokens/Staker[_to][_mintAddress][TokenId].day);
            uint fine = (2*TokenDays)/100;
            IERC20(ERC20Address).safeTransfer(_to, TokenDays - fine);
            IERC20(ERC20Address).safeTransfer(0x000000000000000000000000000000000000dEaD, fine);
            IERC721(_mintAddress).safeTransferFrom(address(this), _to,Staker[_to][_mintAddress][TokenId].NFT,"");
            TotalRemaningToken -= TokenDays;  
            Staker[_to][_mintAddress][TokenId].DepositToken = false;       
        }
        else{
            IERC20(ERC20Address).safeTransfer(_to, Staker[_to][_mintAddress][TokenId].tokens);
            IERC721(_mintAddress).safeTransferFrom(address(this), _to,Staker[_to][_mintAddress][TokenId].NFT,"");
            TotalRemaningToken -= Staker[_to][_mintAddress][TokenId].tokens;
            Staker[_to][_mintAddress][TokenId].DepositToken = false;  
        } 
        if(Staker[_to][_mintAddress][TokenId].day == 15){
            category1.decrement();
        }
        else if(Staker[_to][_mintAddress][TokenId].day == 30){
            category2.decrement();   
        }
        else if(Staker[_to][_mintAddress][TokenId].day == 60){
            category3.decrement();   
        }
        else if(Staker[_to][_mintAddress][TokenId].day == 90){
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