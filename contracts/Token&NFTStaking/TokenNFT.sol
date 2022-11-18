// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC20Stakeable is Ownable,IERC721Receiver{
    using SafeERC20 for IERC20;
    address public ERC721address;
    address public ERC20Address;
    uint public TotalToken;
    uint rate;
    struct Staker {
        uint256 deposited;
        uint256 timestake;
        bool check; 
    }
    struct StakerNFT {
        uint256 userRate;
        uint256 tokenId;
        bool check; 
    }
    mapping (address => Staker) public Details;
    mapping (address => uint) public Reward;
    mapping (address => StakerNFT ) public UserRate;
    /*
    ~~~~~~~~~~~~~~~Constructor function~~~~~~~~~~~~~~~
   1. This function is called when contract is first deployed.
   2. It takes three parameters:
        a. ER721 Token Address (Address of ER721 Token Contract)
        b. Rate Percentage (Percentage value of rate i.e., Interest percentage)
        c. ER720 Token Address (Address of ER720 Token Contract)
    */
    constructor(address _ERC721address, uint256 _ratePersentage, address _ERC20Address) {
        ERC721address = _ERC721address;
        rate = _ratePersentage;
        ERC20Address = _ERC20Address;
    }
    /*
    ~~~~~~~~~~~~~Admin Add Token Function~~~~~~~~~~~~~~~
    1. Owner add tokens into contract with this function
    2. These tokens are used as rewards for staking
    3. Only Owner can call this function
    */
    function AdminAddToken(uint _amount) public onlyOwner{
        TotalToken += _amount;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,_amount);
    }
    /*
    ~~~~~~~~~~~~~Admin WithDraw Token Function~~~~~~~~~~~~~~~
    1. Admin withdraws his/her desired amount of token from contract.
    2. Only Owner can call this function
    */
    function AdminWithDrawToken(uint amount,address _to) public onlyOwner{
        IERC20(ERC20Address).safeTransfer(_to, amount);
    }
    /*
    ~~~~~~~~~~~~~Utilization Function~~~~~~~~~~~~~~~
    1. Owner call this function to check remaining percentage of tokens left in this contract.
    2. Only Owner can call this function
    */
    function Utilization() public view returns(uint256) {
        uint Persentage = (IERC20(ERC20Address).balanceOf(address(this)) * 100)/TotalToken;
        return Persentage;
    }
    /*   ~~~~~~~~~~~~~Deposit Function~~~~~~~~~~~~~~~
    1. This function has one parameter.
    2. This function is used to deposit desired amount of tokens in this contract by user.
    3. If user already deposited some tokens then he/she must has to withdraw all tokens first.
    */
    function Deposit(uint256 _amount) public {
        require(!Details[msg.sender].check,"Please First WithDraw");
        TotalToken += _amount;
        Details[msg.sender] = Staker(_amount,block.timestamp,true);
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) , _amount);
    }
    /*   ~~~~~~~~~~~~~Withdraw Function~~~~~~~~~~~~~~~
    1. This function is used to withdraw tokens.
    2. User will call this function to withdraw all tokens from this contract.
    */
    function Withdraw() public {
        require(Details[msg.sender].check,"Please First Stake");
        if (UserRate[msg.sender].check){
            uint amount = Details[msg.sender].deposited;
            uint newval = calculateIntrest(msg.sender);
            IERC721(ERC721address).safeTransferFrom(address(this), msg.sender,UserRate[msg.sender].tokenId,"");
            IERC20(ERC20Address).transfer(msg.sender, amount + newval);
            delete UserRate[msg.sender];
            delete Details[msg.sender];
        }
        else{
            uint amount = Details[msg.sender].deposited;
            uint newval = calculateIntrest(msg.sender);
            IERC20(ERC20Address).transfer(msg.sender, amount + newval);
            delete Details[msg.sender];
        }    
    }
     /*   ~~~~~~~~~~~~~showReward Function~~~~~~~~~~~~~~~
    1. This function is used to show rewards.
    2. User will call this function to check his/her total generated rewards
    */
    function showReward(address _to) public view returns(uint result)
    {
        if (UserRate[_to].check)
        {
            uint RewardEst = (Details[_to].deposited * UserRate[_to].userRate) * ((block.timestamp - Details[_to].timestake)/60);
            uint TotalReward = RewardEst / 100;
            result = TotalReward + Details[_to].deposited;
            return result/1000000000000000000;

        }
        else
        {
            uint RewardEst = (Details[_to].deposited * rate) * ((block.timestamp - Details[_to].timestake)/60);
            uint TotalReward = RewardEst / 100;
            result = TotalReward + Details[_to].deposited;
            return result/1000000000000000000;
        }
        
    }
    /*   ~~~~~~~~~~~~~CalculateIntrest Function~~~~~~~~~~~~~~~
    1. This function is used to calculate total reward generated.
    2. Function will decide how much reward is generated after every minute by adding PercentageRate of deposited tokens .
    */
    function calculateIntrest(address _to) public view returns(uint256){
        if (UserRate[_to].check)
        {
            uint RewardEst = (Details[_to].deposited * UserRate[_to].userRate) * ((block.timestamp - Details[_to].timestake)/60);
            uint TotalReward = RewardEst / 100;
            return TotalReward;
        }
        else
        {
            uint RewardEst = (Details[_to].deposited * rate) * ((block.timestamp - Details[_to].timestake)/60);
            uint TotalReward = RewardEst / 100;
            return TotalReward;
        }
    }
    /*   ~~~~~~~~~~~~~UpdateERC721 Function~~~~~~~~~~~~~~~
    1. This function is used update address of ERC721 token address.
    2. Only Owner can call this function.
    */
    function UpdateERC721(address _ERC721address) public onlyOwner{
        ERC721address = _ERC721address;
    }
    /*~~~~~~~~~~~~~UpdateERC20 Function~~~~~~~~~~~~~~~
    1. This function is used update address of ERC20 token address.
    2. Only Owner can call this function.
    */
    function UpdateERC20 ( address _ERC20Address) public onlyOwner{
        ERC20Address = _ERC20Address;
    }
    /*~~~~~~~~~~~~~UpdateRatePersentage Function~~~~~~~~~~~~~~~
    1. This function is used update Percentage Rate of rewards.
    2. Only Owner can call this function.
    */
    function UpdateRatePersentage(uint256 _ratePersentage) public onlyOwner{
        rate = _ratePersentage;
    }
    /*~~~~~~~~~~~~~DepositNFT Function~~~~~~~~~~~~~~~
    1. This function is used to deposit new token and boost the current percentage rate
    2. This function takes two parameters i.e., Token Id and New Boosted Percentage Rate
    */
    function DepositNFT(uint256 tokenIds,uint _rate) public {
        require(Details[msg.sender].check,"First Deposit Tokens");
        require(UserRate[msg.sender].check,"Please Unstake your deposited NFT");
        UserRate[msg.sender] = StakerNFT(_rate,tokenIds,true); 
        IERC721(ERC721address).safeTransferFrom(msg.sender,address(this),tokenIds,"");
    }
    /*~~~~~~~~~~~~~WithdrawNFT Function~~~~~~~~~~~~~~~
    1. This function is used to withdraw token
    2. This function takes one parameter
    3. User must have one nft staked before withdrawing.
    */
    function withdrawNFT(uint256 tokenIds) public {
        require(UserRate[msg.sender].check,"Please First Stake NFTs");
        IERC721(ERC721address).safeTransferFrom(address(this), msg.sender,tokenIds,"");
        delete UserRate[msg.sender];
    }
    function onERC721Received(address,address,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}