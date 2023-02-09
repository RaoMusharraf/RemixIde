// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IIERC721.sol";
import "./IIERC20.sol";

contract TokenStaking is Ownable{
    // using Counters for Counters.Counter;
    // Counters.Counter public counter;
    using SafeERC20 for IERC20;
    uint256 _amount = 1000000000000000000 ;

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
    mapping (uint => mapping(uint => string)) public URITier;
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
    // function approve(uint Tokens) public{
    //     IIERC20(ERC20Address).approve(msg.sender,Tokens);
    // }
    function deposit(uint Tokens,uint Days) public {
        require (!Staker[msg.sender].DepositToken,"You Already Deposit Tokens");
        if(Days == 15){
            require(Tokens >= (250*_amount) && Tokens <= (999 * _amount),"Tokens Out Of Range !!!");
            Staker[msg.sender] = Detail(Tokens,Days,block.timestamp,1,true);
            IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,Tokens);
        }
        else if(Days == 30){
            require(Tokens >= (1000* _amount) && Tokens <= (2499 *_amount),"Tokens Out Of Range !!!");
            Staker[msg.sender] = Detail(Tokens,Days,block.timestamp,2,true);
            IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,Tokens);
        }
        else if(Days == 60){
            require(Tokens >=(2500*_amount) && Tokens <= (4999 * _amount),"Tokens Out Of Range !!!");
            Staker[msg.sender] = Detail(Tokens,Days,block.timestamp,3,true);
            IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,Tokens);
        }
        else if(Days == 90){
            require(Tokens >=(5000*_amount) ,"Tokens Out Of Range !!!");
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
            delete Staker[_to];
        }
        else{
            IERC20(ERC20Address).safeTransfer(_to, Staker[_to].tokens);
            for(uint i=1; i <= Staker[_to].NFT; i++){
                IIERC721(ERC721address).safeMint(_to,URITier[Staker[_to].NFT][i],0,3);
            }
            delete Staker[_to];
        }   
    }
    // ============ SetTierURIs ============
    /* 
        @dev get uri and save according to the category of Staking.
        @param _uri get the url of the Pinata || IPFS of NFTs
    */
    function setTier1(string memory _uri) public onlyOwner{
        URITier[1][1]=_uri;
    }
    function setTier2(string memory _uri1,string memory _uri2) public onlyOwner{
        URITier[2][1] =_uri1;
        URITier[2][2] =_uri2;
    }
    function setTier3(string memory _uri1,string memory _uri2,string memory _uri3) public onlyOwner{
        URITier[3][1] =_uri1;
        URITier[3][2] =_uri2;
        URITier[3][3] =_uri3;
    }
    function setTier4(string memory _uri1,string memory _uri2,string memory _uri3,string memory _uri4) public onlyOwner{
        URITier[4][1] =_uri1;
        URITier[4][2] =_uri2;
        URITier[4][3] =_uri3;
        URITier[4][4] =_uri4;
    }
    // ============ CheckTierURI ============
    /* 
        @dev get uri and save according to the category of Staking.
        @param Tier get the url of the Pinata || IPFS of NFTs 1,2,3,4 Respectively.
    */
    function CheckTierURI(uint Tier) view public returns(string[] memory){
        string[] memory memoryArray = new string[](Tier);
        uint counter=0;
        for(uint i = 1; i <= Tier; i++) {
            memoryArray[counter] = URITier[Tier][i];
            counter++;    
        }
        return memoryArray;
    }
}