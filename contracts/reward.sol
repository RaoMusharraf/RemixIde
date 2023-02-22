// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeflyGame is Ownable{

    using SafeERC20 for IERC20;
    address public ERC20Address;
    uint256 public TotalRemaningToken;

    uint256 amount = 1000000000000000000;
    
    mapping (address => uint) public Staker;

    // ============ Constructor ============
    /* 
        @dev get _ERC721address and _ERC20Address
        @param _ERC721address address of the minting NFT contract
        @param _ERC20Address address of the minting Token contract
    */
    // constructor(address _ERC20Address) {
    //     ERC20Address = _ERC20Address;
    // }

    // ============ Reward FUNCTIONS ============
    /* 
        @dev Reward user defly tokens  
        @param _to address of the user and points 
    */
    function reward (address _to,uint points) public payable{
        uint rewardRec = points/10;
        IERC20(ERC20Address).safeTransfer(_to, rewardRec);
        TotalRemaningToken -= rewardRec;
        Staker[_to] = rewardRec;  
    }
    
    // ============= Admin Add Token Function ==============
    /*
        @dev Owner add tokens into contract with this function
        @param These tokens are used as rewards for gane
        @param Only Owner can call this function
    */
    function AdminAddToken(uint _amount) public onlyOwner{
        TotalRemaningToken += _amount;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,_amount);
    }
    function getReturn (uint value) public pure returns(bytes32,uint){
        bytes32 price;
        return(price,value);
    }
}