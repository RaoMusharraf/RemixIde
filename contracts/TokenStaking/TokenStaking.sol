// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract ERC20Stakeable is Ownable{
    using SafeERC20 for IERC20;
    address public ERC721address;
    address public owenerERC20;
    address public ERC20Address;
    uint public rewardrate ;
    uint public unstaketimeval;
    uint public totalOwnerToken;
    uint rate;
    struct Staker {
        uint256 deposited;
        uint256 timestake;
        bool check; 
    }
    mapping (address => Staker) public Details;
    mapping (address => uint) public Reward;
    mapping (address => uint ) public OwnerTokens;

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
        owenerERC20 = msg.sender;
    }
    /*
    ~~~~~~~~~~~~~Admin Add Token Function~~~~~~~~~~~~~~~
    1. Owner add tokens into contract with this function
    2. These tokens are used as rewards for staking
    3. Only Owner can call this function
    */
    function AdminAddToken(uint _amount) public onlyOwner{
        require(msg.sender==owenerERC20,"Only Owner can transfer");
        OwnerTokens[msg.sender] +=_amount;
        totalOwnerToken += _amount;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,_amount);
    }
    /*
    ~~~~~~~~~~~~~Admin WithDraw Token Function~~~~~~~~~~~~~~~
    1. Admin withdraws his/her desired amount of token from contract.
    2. Only Owner can call this function
    */
    function AdminWithDrawToken(uint amount) public onlyOwner{
        OwnerTokens[msg.sender] -= amount;
        totalOwnerToken -= amount;
        IERC20(ERC20Address).safeTransfer(msg.sender, amount);
    }
    /*
    ~~~~~~~~~~~~~Utilization Function~~~~~~~~~~~~~~~
    1. Owner call this function to check remaining percentage of tokens left in this contract.
    2. Only Owner can call this function
    */
    function Utilization() public view onlyOwner returns(uint256) {
        uint Persentage = (OwnerTokens[msg.sender] * 100)/totalOwnerToken;
        return Persentage;
    }
    /*   ~~~~~~~~~~~~~Deposit Function~~~~~~~~~~~~~~~
    1. This function has one parameter.
    2. This function is used to deposit desired amount of tokens in this contract by user.
    3. If user already deposited some tokens then he/she must has to withdraw all tokens first.
    */
    function Deposit(uint256 _amount) public {
        require(!Details[msg.sender].check,"Please First WithDraw");
        Details[msg.sender] = Staker(_amount,block.timestamp,true);
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) , _amount);
    }
    /*   ~~~~~~~~~~~~~Withdraw Function~~~~~~~~~~~~~~~
    1. This function is used to withdraw tokens.
    2. User will call this function to withdraw all tokens from this contract.
    */
    function Withdraw() public {
        require(Details[msg.sender].check,"Please First Stake");
        uint amount = Details[msg.sender].deposited;
        uint newval = calculateIntrest();
        IERC20(ERC20Address).transfer(msg.sender, amount + newval);
        OwnerTokens[owenerERC20] -= newval;
        delete Details[msg.sender];
    }

    function showReward() public view returns(uint result)
    {
        uint RewardEst = (Details[msg.sender].deposited * rate) * (block.timestamp - Details[msg.sender].timestake);
        uint TotalReward = RewardEst / 6000;
        result = TotalReward + Details[msg.sender].deposited;
        return result;
    }
    /*   ~~~~~~~~~~~~~CalculateIntrest Function~~~~~~~~~~~~~~~
    1. This function is used to calculate total reward generated.
    2. Function will decide how much reward is generated after every minute by adding PercentageRate of deposited tokens .
    */
    function calculateIntrest() public view returns(uint256){
        uint RewardEst = (Details[msg.sender].deposited * rate) * (block.timestamp - Details[msg.sender].timestake);
        uint TotalReward = RewardEst / 6000;
        return TotalReward;
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
    function depositNFT(uint256 tokenIds) public {
        require(msg.sender != ERC721address, "Invalid address");
        IERC721(ERC721address).safeTransferFrom(msg.sender,address(this),tokenIds,"");
    }

    function withdrawNFT(uint256 tokenIds) public {
        IERC721(ERC721address).safeTransferFrom(address(this), msg.sender,tokenIds,"");
    }
}