// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4; 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract TokenStaking is Ownable{
    using SafeERC20 for IERC20;
    address public ERC20Address;
    address ownerAddress;
    uint public totalStakedTokens;
    uint Tax;
    uint penalty;
    struct Staker {
        uint256 depositTokens;
        uint256 stakeTime;
        uint256 StakeMonth;
        uint256 EarnPersentage;
        bool check; 
    }
    mapping (address => Staker) public Details;
    mapping(uint => uint) public APY;
    mapping(uint => uint) public APYPer;
    mapping (address => uint ) public Tokens;

    /*
    ~~~~~~~~~~~~~~~Constructor function~~~~~~~~~~~~~~~
    1. This function is called when contract is first deployed.
    2. It takes three parameters:
        a. ERC20 Token Address (Address of ERC20 Token Contract)
    */
    constructor(address _ERC20Address) {
        ERC20Address = _ERC20Address;
        ownerAddress = msg.sender;
    }
    /*
    ~~~~~~~~~~~~~Admin Add Token Function~~~~~~~~~~~~~~~
    1. Owner add tokens into contract with this function
    2. These tokens are used as rewards for staking
    3. Only Owner can call this function
    */
    function AdminAddToken(uint _amount) public onlyOwner{
        Tokens[msg.sender] +=_amount;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,_amount);
    }
    /*   ~~~~~~~~~~~~~Deposit Function~~~~~~~~~~~~~~~
    1. This function has some parameters.
    2. This function is used to deposit desired amount of tokens in this contract by user.
    3. If user already deposited some tokens then he/she must has to withdraw all tokens first.
    */
    function DepositTokens(address to,uint256 _amount,uint256 StakeMonth,uint256 EarnPersentage) public {
        require(Tokens[ownerAddress] > 0,"Please Wait !!!");
        if(Details[to].check){
            require(((Details[to].StakeMonth*30*24*60*60) + Details[to].stakeTime) > block.timestamp,"Your Time Period Complete.");
            require(Details[to].StakeMonth == StakeMonth,"Enter Right StakeMonth");
            require(Details[to].EarnPersentage == EarnPersentage,"Enter Right EarnPersentage");
            Details[to].depositTokens = Details[to].depositTokens + _amount;
            IERC20(ERC20Address).safeTransferFrom(to, address(this) , _amount);         
        }else {
            require(StakeMonth == APY[1] || StakeMonth == APY[2] || StakeMonth == APY[3],"Enter Right StakeMonth");
            require(EarnPersentage == 100 || EarnPersentage == 75 || EarnPersentage == 50,"Enter Right EarnPersentage");
            uint AdminFee = (_amount*Tax)/1000;
            Details[to] = Staker(_amount-AdminFee,block.timestamp,StakeMonth,EarnPersentage,true);
            IERC20(ERC20Address).safeTransferFrom(to, address(this) , _amount);        
        }
        Tokens[to] += _amount;
        totalStakedTokens += _amount;
    }
    /*   ~~~~~~~~~~~~~Withdraw Function~~~~~~~~~~~~~~~
    1. This function is used to withdraw tokens.
    2. User will call this function to withdraw all tokens from this contract.
    */
    function WithdrawTokens(address to) public {
        require(Details[to].check,"First Stake Tokens");
        uint InterestAmount;
        uint EarnToken;
        uint BurnToken;
        if(((Details[to].StakeMonth*30*24*60*60) + Details[to].stakeTime) < block.timestamp){
            if(Details[to].StakeMonth == APY[1]){
                InterestAmount =  (Details[to].depositTokens*APYPer[1])/1000;
            }else if(Details[to].StakeMonth == APY[2]){
                InterestAmount =  (Details[to].depositTokens*APYPer[2])/1000;
            }else if(Details[to].StakeMonth == APY[3]){
                InterestAmount =  (Details[to].depositTokens*APYPer[3])/1000;
            }
            if(Details[to].EarnPersentage == 100){
                IERC20(ERC20Address).transfer(to, Details[to].depositTokens + InterestAmount);
            }else if(Details[to].EarnPersentage == 75){
                EarnToken = (InterestAmount*75)/100;
                IERC20(ERC20Address).transfer(to, Details[to].depositTokens + EarnToken);
                BurnToken = (InterestAmount*25)/100;
                IERC20(ERC20Address).transfer(0x000000000000000000000000000000000000dEaD, BurnToken);
            }else if(Details[to].EarnPersentage == 50){
                EarnToken = (InterestAmount*50)/100;
                IERC20(ERC20Address).transfer(to, Details[to].depositTokens + EarnToken);
                BurnToken = (InterestAmount*50)/100;
                IERC20(ERC20Address).transfer(0x000000000000000000000000000000000000dEaD, BurnToken);
            }
        }else{
            uint InterestAmountperday;
            uint Total;
            uint PenaltyResult;
            uint Stakdays = (block.timestamp - Details[to].stakeTime)/24*60*60; 
            if(Details[to].StakeMonth == APY[1]){
                InterestAmount =  (Details[to].depositTokens*APYPer[1])/1000 ;
                InterestAmountperday = InterestAmount/(Details[to].StakeMonth*30);
            }else if(Details[to].StakeMonth == APY[2]){
                InterestAmount =  (Details[to].depositTokens*APYPer[2])/1000;
                InterestAmountperday = InterestAmount/(Details[to].StakeMonth*30);
            }else if(Details[to].StakeMonth == APY[3]){
                InterestAmount =  (Details[to].depositTokens*APYPer[3])/1000;
                InterestAmountperday = InterestAmount/(Details[to].StakeMonth*30);
            }
            if(Details[to].EarnPersentage == 100){
                EarnToken = (InterestAmountperday*Stakdays);
                Total = Details[to].depositTokens + EarnToken;
                PenaltyResult = (Total*penalty)/1000;
                IERC20(ERC20Address).transfer(to,(Total - PenaltyResult));
            }else if(Details[to].EarnPersentage == 75){
                EarnToken = ((InterestAmountperday*Stakdays)*75)/100;
                Total = Details[to].depositTokens + EarnToken;
                PenaltyResult = (Total*penalty)/1000;
                IERC20(ERC20Address).transfer(to,(Total - PenaltyResult));
                BurnToken = ((InterestAmountperday*Stakdays)*25)/100;
                IERC20(ERC20Address).transfer(0x000000000000000000000000000000000000dEaD, BurnToken);
            }else if(Details[to].EarnPersentage == 50){
                EarnToken = ((InterestAmountperday*Stakdays)*50)/100;
                Total = Details[to].depositTokens + EarnToken;
                PenaltyResult = (Total*penalty)/1000;
                IERC20(ERC20Address).transfer(to,(Total - PenaltyResult));
                BurnToken = ((InterestAmountperday*Stakdays)*50)/100;
                IERC20(ERC20Address).transfer(0x000000000000000000000000000000000000dEaD, BurnToken);
            }
        } 
        Details[to].check = false;
        Tokens[to] -= Details[to].depositTokens;
        totalStakedTokens -= Details[to].depositTokens;    
    }
    /*   ~~~~~~~~~~~~~ SetAPY Function~~~~~~~~~~~~~~~
    1. This function is used to set Months.
    */
    function SetAPY(uint Month1,uint Month2,uint Month3) public onlyOwner{
        APY[1] = Month1;
        APY[2] = Month2;
        APY[3] = Month3;
    }
    /*   ~~~~~~~~~~~~~ SetAPY Function~~~~~~~~~~~~~~~
    1. This function is used to set Months.
    */
    function SetRewardPersentage(uint Month1Per,uint Month2Per,uint Month3Per) public onlyOwner{
        APYPer[1] = Month1Per;
        APYPer[2] = Month2Per;
        APYPer[3] = Month3Per;
    }
    /*   ~~~~~~~~~~~~~ SetTex Function~~~~~~~~~~~~~~~
    1. This function is used to set Tax fee and Penalty charges.
    */
    function setTexAndPenalty(uint taxFee,uint _penalty) public{
        Tax = taxFee;
        penalty = _penalty;
    }
}