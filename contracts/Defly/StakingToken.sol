// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IIERC721.sol";

contract TokenStaking{
    using Counters for Counters.Counter;
    Counters.Counter public counter;
    using SafeERC20 for IERC20;
    address public ERC721address;
    address public ERC20Address;
    struct Detail{
        uint tokens;
        uint day;
        uint StartTime;
        uint NFT;
        bool DepositToken;
    }
    mapping (address => Detail) public Staker;
    mapping (uint => string) public URI;
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
    function deposit(uint Tokens,uint Days) public {
        require (!Staker[msg.sender].DepositToken,"You Already Deposit Tokens");
        if(Days == 15){
            require(Tokens >=250 && Tokens <= 999,"Tokens Out Of Range !!!");
            Staker[msg.sender] = Detail(Tokens,Days,block.timestamp,1,true);
            IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,Tokens);
        }
        else if(Days == 30){
            require(Tokens >=1000 && Tokens <= 2499,"Tokens Out Of Range !!!");
            Staker[msg.sender] = Detail(Tokens,Days,block.timestamp,2,true);
            IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,Tokens);
        }
        else if(Days == 60){
            require(Tokens >=2500 && Tokens <= 4999,"Tokens Out Of Range !!!");
            Staker[msg.sender] = Detail(Tokens,Days,block.timestamp,3,true);
            IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,Tokens);
        }
        else if(Days == 90){
            require(Tokens >=5000 ,"Tokens Out Of Range !!!");
            Staker[msg.sender] = Detail(Tokens,Days,block.timestamp,4,true);
            IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,Tokens);
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
        require (Staker[_to].DepositToken,"Please First Deposit Tokens !!!");
        uint Time = ((block.timestamp - Staker[_to].StartTime)/(24*60*60));
        if(Time < Staker[_to].day){
            uint fine = (2*Staker[_to].tokens)/100;
            IERC20(ERC20Address).safeTransfer(_to, Staker[_to].tokens - fine);
            IERC20(ERC20Address).safeTransfer(0x000000000000000000000000000000000000dEaD, fine);
            Staker[_to].DepositToken = false;
        }
        else{
            IERC20(ERC20Address).safeTransfer(_to, Staker[_to].tokens);
            Staker[_to].DepositToken = false;
            for(uint i=1; i <= Staker[_to].NFT; i++){
                IIERC721(ERC721address).safeMint(_to,URI[i],0,3);
            }
        }   
    }
    // ============ SetURI ============
    /* 
        @dev get uri and save according to the category of Staking.
        @param _uri get the url of the Pinata || IPFS of NFTs
    */
    function setURI(string memory _uri) public{
        counter.increment();
        require(counter.current() < 5,"Stack Full");
        URI[counter.current()]=_uri;
    }
}