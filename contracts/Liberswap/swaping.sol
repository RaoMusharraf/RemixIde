// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
    using SafeERC20 for IERC20;
    address public feeOwner;
    event swapToken(address sender,uint amount);
    event swapSubstrateToken(address sender,uint amount);
    event Hold_USDM_Token(address sender,uint amount);
    // address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant usdt =  0x1059dc58FeE94Fd0caF8A5c9a9b936843F0c5329;
    address constant usdc = 0x07B25CC8082ABc65C70b9e5f00b7f3b8FcF6814B;
    address constant dai = 0x2DF4FAecE2eA8b8FB5eFa8e022eDec520c2f0FA4;
    address constant usdm = 0xe9A05AFaC6e76749462f6537Fed148F34A92c0f7;
    // address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address constant usdm = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;

    mapping(address => bool) public whiteList;
    address[] public whilistedAddress;
    mapping (address => uint) public userAmount;
    uint public currentHoldings;

    constructor(address initialOwner) Ownable(initialOwner)  {
        feeOwner = initialOwner;
    }

    function WhiteList(address _address) public onlyOwner{
        require(!whiteList[_address],"This Address is already WhiteListed!");
        whilistedAddress.push(_address);
        whiteList[_address] = true;
    }

    function swapTokens(address _ethToken,uint256 _amount) public {
        require(_ethToken == usdm || _ethToken == usdc || _ethToken == dai || _ethToken == usdt,"Accept only (USDM,DIA,USDT,USDC) Tokens");
        require(IERC20(_ethToken).allowance(msg.sender, address(this)) >= _amount, "Allowance not set");
        require(IERC20(_ethToken).balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        if(_ethToken == usdm){
            IERC20(_ethToken).transferFrom(msg.sender, address(this), (_amount));
            currentHoldings += (_amount);
            userAmount[msg.sender] = _amount;
            emit swapToken(msg.sender,_amount);
        }
        else{
            uint FeeAmount = (_amount*3)/1000;
            uint eachWhilitedAddressFee = FeeAmount/whilistedAddress.length;
            for (uint i=0; i<whilistedAddress.length; i++) 
            {
                IERC20(_ethToken).transferFrom(msg.sender, whilistedAddress[i], eachWhilitedAddressFee);
            }
            IERC20(_ethToken).transferFrom(msg.sender, address(this), (_amount-FeeAmount));
            currentHoldings += (_amount-FeeAmount);
            userAmount[msg.sender] = (_amount-FeeAmount);
            emit swapToken(msg.sender,(_amount-FeeAmount));
        }
        // substrateToken.mint(msg.sender, _amount);
    }
    function withdrawBalanceTokens(address _ethToken,uint256 _amount) public onlyOwner{
        IERC20(_ethToken).safeTransfer(msg.sender,_amount);
        emit swapSubstrateToken(msg.sender,_amount);
    }

    function removeFromWhiteList(address _address) public onlyOwner{
        require(whiteList[_address],"This Address is not exist!");
        whiteList[_address] = false;
    }
 
    function holdingOfTokens(address _ethToken) public view returns (uint holdings){
        return IERC20(_ethToken).balanceOf(address(this));
    }
    // function holdingOfOwnTokens(address ownTokenAddress,address _ethToken) public view returns (uint holdings){
    //     return IERC20(_ethToken).balanceOf(ownTokenAddress);
    // }
}