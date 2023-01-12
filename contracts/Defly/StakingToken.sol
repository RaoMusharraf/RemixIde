// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IIERC721.sol";

contract TokenStaking{

    using SafeERC20 for IERC20;
    address public ERC721address;
    address public ERC20Address;
    string[] uri;
    struct Detail{
        uint tokens;
        uint day;
        uint StartTime;
        uint NFT;
        bool DepositToken;
    }
    mapping (address => Detail) public Staker;
    constructor(address _ERC721address, address _ERC20Address) {
        ERC721address = _ERC721address;
        ERC20Address = _ERC20Address;
    }
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
    function withdraw () public payable{
        require (Staker[msg.sender].DepositToken,"Please First Deposit Tokens !!!");
        uint Time = ((block.timestamp - Staker[msg.sender].StartTime)/(24*60*60));
        if(Time > Staker[msg.sender].day){
            uint fine = (2*Staker[msg.sender].tokens)/100;
            IERC20(ERC20Address).safeTransfer(msg.sender, Staker[msg.sender].tokens - fine);
            IERC20(ERC20Address).safeTransfer(0x000000000000000000000000000000000000dEaD, fine);
            Staker[msg.sender].DepositToken = false;
        }
        else{
            IERC20(ERC20Address).safeTransfer(msg.sender, Staker[msg.sender].tokens);
            Staker[msg.sender].DepositToken = false;
            for(uint i=0; i < Staker[msg.sender].NFT; i++){
                IIERC721(ERC721address).safeMint(msg.sender,"uri[i]");
            }
            // IIERC721(ERC721address).safeMint(msg.sender,"Hello");
            // Staker[msg.sender].NFT = true;
        }   
    }
}