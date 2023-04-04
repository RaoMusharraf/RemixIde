// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract TokenStaking is Ownable {
    using SafeERC20 for IERC20;
    address public ERC20Address;
    address ownerAddress;
    uint256 public totalStakedTokens;
    bool Check;
    uint256 Tax;
    uint256 penalty;
    struct Staker {
        uint256 depositTokens;
        uint256 stakeTime;
        uint256 StakeMonth;
        uint256 EarnPersentage;
        bool check;
    }
    mapping(address => Staker) public Details;
    mapping(address => uint256) public InterestAmount;
    mapping(uint256 => uint256) public APY;
    mapping(uint256 => uint256) public APYPer;
    mapping(address => uint256) public Tokens;
    mapping(address => uint256) public RewardAmount;
    mapping(address => uint256) public BurnAmount;

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
    function AdminAddToken(uint256 _amount) public onlyOwner {
        Tokens[msg.sender] += _amount;
        IERC20(ERC20Address).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    /*   ~~~~~~~~~~~~~Deposit Function~~~~~~~~~~~~~~~
    1. This function has some parameters.
    2. This function is used to deposit desired amount of tokens in this contract by user.
    3. If user already deposited some tokens then he/she must has to withdraw all tokens first.
    */
    function DepositTokens(
        address to,
        uint256 _payment,
        uint256 StakeMonth,
        uint256 EarnPersentage
    ) public {
        require(Tokens[ownerAddress] > 0, "Please Wait !!!");
        uint256 _amount = _payment * 1000000000;
        if (Details[to].check) {
            require(((Details[to].StakeMonth * 30 * 24 * 60 * 60) + Details[to].stakeTime) >block.timestamp,"Your Time Period Complete.");
            require(
                Details[to].StakeMonth == StakeMonth,
                "Enter Right StakeMonth"
            );
            require(
                Details[to].EarnPersentage == EarnPersentage,
                "Enter Right EarnPersentage"
            );
            Details[to].depositTokens = Details[to].depositTokens + _amount;
            if (Details[to].StakeMonth == APY[1]) {
                InterestAmount[to] += (_amount * APYPer[1]) / 1000;
            } else if (Details[to].StakeMonth == APY[2]) {
                InterestAmount[to] += (_amount * APYPer[2]) / 1000;
            } else if (Details[to].StakeMonth == APY[3]) {
                InterestAmount[to] += (_amount * APYPer[3]) / 1000;
            }
            IERC20(ERC20Address).safeTransferFrom(to, address(this), _amount);
        } else {
            require(
                StakeMonth == APY[1] ||
                    StakeMonth == APY[2] ||
                    StakeMonth == APY[3],
                "Enter Right StakeMonth"
            );
            require(
                EarnPersentage == 100 ||
                    EarnPersentage == 75 ||
                    EarnPersentage == 50,
                "Enter Right EarnPersentage"
            );
            uint256 AdminFee = (_amount * Tax) / 1000;
            Details[to] = Staker(
                _amount - AdminFee,
                block.timestamp,
                StakeMonth,
                EarnPersentage,
                true
            );
            if (Details[to].StakeMonth == APY[1]) {
                InterestAmount[to] = ((_amount - AdminFee) * APYPer[1]) / 1000;
            } else if (Details[to].StakeMonth == APY[2]) {
                InterestAmount[to] = ((_amount - AdminFee) * APYPer[2]) / 1000;
            } else if (Details[to].StakeMonth == APY[3]) {
                InterestAmount[to] = ((_amount - AdminFee) * APYPer[3]) / 1000;
            }
            IERC20(ERC20Address).safeTransferFrom(to, address(this), _amount);
        }
        Tokens[to] += _amount;
        totalStakedTokens += _amount;
    }

    /*   ~~~~~~~~~~~~~Withdraw Function~~~~~~~~~~~~~~~
    1. This function is used to withdraw tokens.
    2. User will call this function to withdraw all tokens from this contract.
    */
    function WithdrawTokens(address to) public {
        require(Details[to].check, "First Stake Tokens");
        uint256 EarnToken;
        uint256 BurnToken;
        if (
            ((Details[to].StakeMonth * 30 * 24 * 60 * 60) + Details[to].stakeTime) < block.timestamp) {
            if (Details[to].EarnPersentage == 100) {
                IERC20(ERC20Address).transfer(
                    to,
                    Details[to].depositTokens +
                        (InterestAmount[to] - RewardAmount[to])
                );
            } else if (Details[to].EarnPersentage == 75) {
                EarnToken =
                    ((InterestAmount[to] - RewardAmount[to]) * 75) /
                    100;
                IERC20(ERC20Address).transfer(
                    to,
                    Details[to].depositTokens + EarnToken
                );
                BurnToken =
                    ((InterestAmount[to] - RewardAmount[to]) * 25) /
                    100;
                BurnAmount[to] = BurnToken;
                IERC20(ERC20Address).transfer(
                    0x000000000000000000000000000000000000dEaD,
                    BurnToken
                );
            } else if (Details[to].EarnPersentage == 50) {
                EarnToken =
                    ((InterestAmount[to] - RewardAmount[to]) * 50) /
                    100;
                IERC20(ERC20Address).transfer(
                    to,
                    Details[to].depositTokens + EarnToken
                );
                BurnToken =
                    ((InterestAmount[to] - RewardAmount[to]) * 50) /
                    100;
                BurnAmount[to] = BurnToken;
                IERC20(ERC20Address).transfer(
                    0x000000000000000000000000000000000000dEaD,
                    BurnToken
                );
            }
        } else {
            uint256 InterestAmountperday;
            uint256 Total;
            uint256 PenaltyResult;
            uint256 Stakdays = (block.timestamp - Details[to].stakeTime) / (24 * 60 * 60);
            InterestAmountperday =
                InterestAmount[to] /
                (Details[to].StakeMonth * 30);

            //Transfer reward to user 100%
            if (Details[to].EarnPersentage == 100) {
                EarnToken = (InterestAmountperday * Stakdays);
                Total =
                    Details[to].depositTokens +
                    (EarnToken - RewardAmount[to]);
                PenaltyResult = (Total * penalty) / 1000;
                IERC20(ERC20Address).transfer(to, (Total - PenaltyResult));
            }
            //Transfer reward to user 75% and Burn 25%
            else if (Details[to].EarnPersentage == 75) {
                EarnToken =
                    (((InterestAmountperday * Stakdays) - RewardAmount[to]) *
                        75) /
                    100;
                Total = Details[to].depositTokens + EarnToken;
                PenaltyResult = (Total * penalty) / 1000;
                IERC20(ERC20Address).transfer(to, (Total - PenaltyResult));
                BurnToken =
                    (((InterestAmountperday * Stakdays) - RewardAmount[to]) *
                        25) /
                    100;
                BurnAmount[to] = BurnToken;
                IERC20(ERC20Address).transfer(
                    0x000000000000000000000000000000000000dEaD,
                    BurnToken
                );
            }
            //Transfer reward to user 50% and Burn 50%
            else if (Details[to].EarnPersentage == 50) {
                EarnToken =
                    (((InterestAmountperday * Stakdays) - RewardAmount[to]) *
                        50) /
                    100;
                Total = Details[to].depositTokens + EarnToken;
                PenaltyResult = (Total * penalty) / 1000;
                IERC20(ERC20Address).transfer(to, (Total - PenaltyResult));
                BurnToken =
                    (((InterestAmountperday * Stakdays) - RewardAmount[to]) *
                        50) /
                    100;
                BurnAmount[to] = BurnToken;
                IERC20(ERC20Address).transfer(
                    0x000000000000000000000000000000000000dEaD,
                    BurnToken
                );
            }
        }
        Details[to].check = false;
        delete RewardAmount[to];
        delete InterestAmount[to];
        Tokens[to] -= Details[to].depositTokens;
        totalStakedTokens -= Details[to].depositTokens;
    }

    /*   ~~~~~~~~~~~~~Claim Function~~~~~~~~~~~~~~~
    1. This function is used to claim reward tokens.
    2. User will call this function to claim all rewards from this contract.
    */
    function ClaimRewards(address to) public {
        require(
            ((Details[to].StakeMonth * 30 * 24 * 60 * 60) + Details[to].stakeTime) >
                block.timestamp,
            "Your Stake Time Complete, Please Call Withdraw Function !"
        );
        uint256 Stakdays = (block.timestamp - Details[to].stakeTime) / (24 * 60 * 60);
        uint256 InterestAmountperday = InterestAmount[to] /
            (Details[to].StakeMonth * 30);
        uint256 EarnToken = InterestAmountperday * Stakdays;
        require(EarnToken > 0, "Reward must be greater than zero.");
        RewardAmount[to] += EarnToken - RewardAmount[to];

        IERC20(ERC20Address).transfer(to, EarnToken);
    }
    function viewBurnRewards(address to) public view returns (uint256 reward) {
        if(Details[to].EarnPersentage == 100){
            return 0;
        }
        else{
            return (InterestAmount[to]*(100-Details[to].EarnPersentage))/100;
        }
    }

    function viewRewards(address to) public view returns (uint256 reward) {
        if (
            ((Details[to].StakeMonth * 30 * 24 * 60 * 60) + Details[to].stakeTime) <
            block.timestamp
        ) {
            return (InterestAmount[to]);
        } else {
            uint256 Stakdays = (block.timestamp - Details[to].stakeTime) / (24 * 60 * 60);
            uint256 InterestAmountperday = InterestAmount[to] /
                (Details[to].StakeMonth * 30);
            uint256 EarnToken = (InterestAmountperday * Stakdays) -
                RewardAmount[to];
            return (EarnToken);
        }
    }

    /*   ~~~~~~~~~~~~~ SetAPY Function~~~~~~~~~~~~~~~
    1. This function is used to set Months.
    */
    function SetAPY(
        uint256 Month1,
        uint256 Month2,
        uint256 Month3
    ) public onlyOwner {
        APY[1] = Month1;
        APY[2] = Month2;
        APY[3] = Month3;
    }

    /*   ~~~~~~~~~~~~~ SetAPY Function~~~~~~~~~~~~~~~
    1. This function is used to set Months.
    */
    function SetRewardPersentage(
        uint256 Month1Per,
        uint256 Month2Per,
        uint256 Month3Per
    ) public onlyOwner {
        APYPer[1] = Month1Per;
        APYPer[2] = Month2Per;
        APYPer[3] = Month3Per;
    }

    /*   ~~~~~~~~~~~~~ SetTex Function~~~~~~~~~~~~~~~
    1. This function is used to set Tax fee and Penalty charges.
    */
    function setTexAndPenalty(uint256 taxFee, uint256 _penalty) public {
        Tax = taxFee;
        penalty = _penalty;
    }

    function getTaxPenalty() public view returns (uint256 tax, uint256 pen) {
        return (Tax, penalty);
    }
}