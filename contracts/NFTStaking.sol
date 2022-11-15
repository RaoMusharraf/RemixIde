// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// @title Moon Rabbits NFT Staking 
// @author OctaLoop

contract MoonRabbitsStaking is Ownable, ReentrancyGuard {

    //NFT Contract
    IERC721 public NFTCollection;

    //Token Contract
    IERC20 public rewardToken;

    // Index of staking
    uint256 public index = 0;

    using SafeERC20 for IERC20;
    uint256 private totalTokens;

    struct Staker {
        uint256 index;
        address user;
        uint256 tokenId;
        uint256 pool;
        uint256 timestamp;
    }

    mapping(uint256 => Staker) public stakes;
    mapping(address => uint256[]) public staking_details;
    mapping(address => uint256[]) public unstaking_details;

    constructor(address _RewardToken,address _NFTCollection) {
        rewardToken = IERC20(_RewardToken);
        NFTCollection = IERC721(_NFTCollection);
    }

    event Stake(address indexed owner, uint256 id, uint256 pool, uint256 time);
    event UnStake(address indexed owner, uint256 id, uint256 pool, uint256 time, uint256 rewardTokens);

    /**
     * Calculate reward for the user's pool
     * @param _pool Pool of NFT
     */
    function calculateRewardPool(uint256 _pool) private pure returns(uint256)  {
        if(_pool==7) {
            return 1000;
        } else if(_pool==14) {
            return 3000;
        } else if(_pool==30) {
            return 5000;
        } else {
            return 10000;
        }
    }

    /**
     * Create a new staking for a specific user
     * @param _tokenId Token Id of NFT to stake
     * @param _pool Pool of NFT
     */
    function stakeNFT(uint256 _tokenId, uint256 _pool) public {
        require(NFTCollection.ownerOf(_tokenId) == msg.sender,"Can't stake nft you don't own!");
        stakes[index] = Staker(index,msg.sender,_tokenId, _pool, block.timestamp);
        staking_details[msg.sender].push(index);
        NFTCollection.transferFrom(msg.sender, address(this), _tokenId);
        index++;
        emit Stake(msg.sender, _tokenId, _pool, block.timestamp);
    }

    /**
     * Unstake the NFT and rewards user if pool is completed
     * @param _tokenId Token Id of NFT to stake
     * @param _pool Pool of NFT
     */
    function unStakeNFT(uint256 _index,uint256 _tokenId, uint256 _pool) public {
        require((block.timestamp - stakes[_index].timestamp) / 60 / 60 / 24 >= _pool,"Staking pool not ended yet!!!!");
        require(stakes[_index].user == msg.sender,"You are not owner of this NFT staking");
        delete stakes[_index];
        unstaking_details[msg.sender].push(_index);
        NFTCollection.transferFrom( address(this), msg.sender, _tokenId);
        uint256 reward =  calculateRewardPool(_pool);
        rewardToken.transfer( msg.sender, reward);
        emit UnStake(msg.sender, _tokenId, _pool,  block.timestamp, reward);
    }

    /**
     * Get user's staking list
     * @param _user Address of the user
     */
    function userStakingList(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory list = staking_details[_user];
        return list;
    }

    /**
     * Check if nft index is already unstaked
      * @param _tempIndex of the nft
      * @param _user of the user
     */
    function checkIfAlreadyUnstaked(uint256 _tempIndex,address _user) public view returns(bool) {
        for (uint j=0; j < unstaking_details[_user].length; j++) {
            if(unstaking_details[_user][j]==_tempIndex){
                    return true;
            }
        }  
        return false;
    }
}