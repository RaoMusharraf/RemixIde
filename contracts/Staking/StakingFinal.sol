// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract TokenStaking is Ownable{
    using SafeERC20 for IERC20;
    address public ERC20Address;
    uint public totalStakedTokens;
    struct Staker {
        uint256 depositTokens;
        uint256 stakeTime;
        uint256 StakeMonth;
        uint256 EarnPersentage;
        bool check; 
    }
    mapping (address => Staker) public Details;
    mapping (address => uint ) public Tokens;

    /*
    ~~~~~~~~~~~~~~~Constructor function~~~~~~~~~~~~~~~
    1. This function is called when contract is first deployed.
    2. It takes three parameters:
        a. ERC20 Token Address (Address of ERC20 Token Contract)
    */
    constructor(address _ERC20Address) {
        ERC20Address = _ERC20Address;
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
    /*
    ~~~~~~~~~~~~~Admin WithDraw Token Function~~~~~~~~~~~~~~~
    1. Admin withdraws his/her desired amount of token from contract.
    2. Only Owner can call this function
    */
    function AdminWithDrawToken(uint amount) public onlyOwner{
        Tokens[msg.sender] -= amount;
        IERC20(ERC20Address).safeTransfer(msg.sender, amount);
    }
    /*   ~~~~~~~~~~~~~Deposit Function~~~~~~~~~~~~~~~
    1. This function has one parameter.
    2. This function is used to deposit desired amount of tokens in this contract by user.
    3. If user already deposited some tokens then he/she must has to withdraw all tokens first.
    */
    function DepositTokens(address to,uint256 _amount,uint256 StakeMonth,uint256 EarnPersentage) public {
        if(Details[to].check){
            require(((Details[to].StakeMonth*30*24*60*60) + Details[to].stakeTime) > block.timestamp,"Your Time Period Complete.");
            require(Details[to].StakeMonth == StakeMonth,"Enter Right StakeMonth");
            require(Details[to].EarnPersentage == EarnPersentage,"Enter Right EarnPersentage");
            Details[to].depositTokens = Details[to].depositTokens + _amount;
            IERC20(ERC20Address).safeTransferFrom(to, address(this) , _amount);         
        }else{
            Details[to] = Staker(_amount,block.timestamp,StakeMonth,EarnPersentage,true);
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
        require(((Details[to].StakeMonth*30*24*60*60) + Details[to].stakeTime) < block.timestamp,"Please Wait");
        uint InterestAmount;
        uint EarnToken;
        uint BurnToken;
        uint AdminFee = (Details[to].depositTokens*25)/1000;
        uint OwnerRemainingTokens = Details[to].depositTokens - AdminFee;
        if(Details[to].StakeMonth == 3){
            InterestAmount =  (Details[to].depositTokens*20)/100;
        }else if(Details[to].StakeMonth == 6){
            InterestAmount =  (Details[to].depositTokens*225)/1000;
        }else if(Details[to].StakeMonth == 12){
            InterestAmount =  (Details[to].depositTokens*25)/100;
        }
        if(Details[to].EarnPersentage == 100){
            IERC20(ERC20Address).transfer(to, OwnerRemainingTokens + InterestAmount);
        }else if(Details[to].EarnPersentage == 75){
            EarnToken = (InterestAmount*75)/100;
            IERC20(ERC20Address).transfer(to, OwnerRemainingTokens + EarnToken);
            BurnToken = (InterestAmount*25)/100;
            IERC20(ERC20Address).transfer(0x000000000000000000000000000000000000dEaD, BurnToken);
        }else if(Details[to].EarnPersentage == 50){
            EarnToken = (InterestAmount*50)/100;
            IERC20(ERC20Address).transfer(to, OwnerRemainingTokens + EarnToken);
            BurnToken = (InterestAmount*50)/100;
            IERC20(ERC20Address).transfer(0x000000000000000000000000000000000000dEaD, BurnToken);
        }
        Details[to].check = false;
        Tokens[to] -= Details[to].depositTokens;
        totalStakedTokens -= Details[to].depositTokens;
        
    }
}