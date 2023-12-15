// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
    address public feeOwner;
    event swapToken(address sender,uint amount);
    event Hold_USDM_Token(address sender,uint amount);

    mapping(address => bool) public whiteList;
    uint public currentHoldings;

    constructor(address initialOwner) Ownable(initialOwner)  {
        feeOwner = initialOwner;
    }

    function WhiteList(address _address) public onlyOwner{
        require(!whiteList[_address],"This Address is already WhiteListed!");
        whiteList[_address] = true;
    }

    function swapTokens(address _ethToken,uint256 _amount) public {
        require(whiteList[msg.sender],"You are Not white Listed, please Whitelist yourself!");
        require(IERC20(_ethToken).allowance(msg.sender, address(this)) >= _amount, "Allowance not set");
        require(IERC20(_ethToken).balanceOf(msg.sender) >= _amount, "Insufficient balance");

        uint FeeAmount = (_amount*3)/1000;

        IERC20(_ethToken).transferFrom(msg.sender, feeOwner, FeeAmount);
        IERC20(_ethToken).transferFrom(msg.sender, address(this), (_amount-FeeAmount));
        currentHoldings += (_amount-FeeAmount);
        emit swapToken(msg.sender,_amount);
        // substrateToken.mint(msg.sender, _amount);
    }

    function removeFromWhiteList(address _address) public onlyOwner{
        require(whiteList[_address],"This Address is not exist!");
        whiteList[_address] = false;
    }

    function HoldYeildTokens(address _USDM,uint256 _amount) public {
        require(whiteList[msg.sender],"You are Not white Listed, please Whitelist yourself!");
        require(IERC20(_USDM).allowance(msg.sender, address(this)) >= _amount, "Allowance not set");
        require(IERC20(_USDM).balanceOf(msg.sender) >= _amount, "Insufficient balance");
        IERC20(_USDM).transferFrom(msg.sender, address(this), _amount);
        emit Hold_USDM_Token(msg.sender,_amount);
        // substrateToken.mint(msg.sender, _amount);
    }
}