// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing interfaces and utilities from OpenZeppelin Contracts library
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///@title TokenSwap contract for swapping tokens, inheriting from Ownable for access control
/// @author LiberSwap Team
/// @notice Contarct is based on swaping the usd tokens to substrate and vice versa  
contract TokenSwap is Ownable {
    using SafeERC20 for IERC20; // SafeERC20 library usage for safe token transfers

    // State variables
    address public Owner; // Variable to store the owner's address, redundant with Ownable's owner()

    // Events for logging different types of token swaps
    event swapToken(address sender, uint amount);
    event substrateSwapToken(address sender, uint amount);
    event Hold_USDM_Token(address sender, uint amount);

    // Constant addresses for USDT, USDC, DAI, and USDM tokens
    address constant usdt = 0xa5014eA627Ac22A63f2Bf3b46e26d408e72f55c1;
    address constant usdc = 0x9951342D994001468506DF88F71A582867B50dd4;
    address constant dai = 0x77F146ca2943294CC53e6c3B5980B572c961ae23;
    address constant usdm = 0x4b3a514Dd71850277bBa82491f26dACDF089cb68;

    // Mapping to track whitelisted addresses
    mapping(address => bool) public whiteList;
    // Array to store all whitelisted addresses for iteration
    address[] public whilistedAddress;
    // Nested mapping to track amounts of tokens held by users
    mapping (address UserAddress=> mapping (address TokenAddress  => uint)) public userTokenAmount;
    mapping (address UserAddress => uint) public userAmount;
    // mapping (address UserAddress => uint Amount) public userTotalSwapAmount;
    mapping (address UserAddress =>  mapping(string => uint Amount)) public userTotalSwapAmount;

    // Variable to track current holdings in the contract
    uint public currentHoldings;

    // Veriable to track current overColleteralFeeAmount
    uint public overColleteralFeeAmount;

    // Constructor to set the initial owner of the contract
    constructor(address initialOwner) Ownable(initialOwner) {
        Owner = initialOwner;
    }

    /**
     * @dev Adds an address to the whitelist.
     * Only the owner of the contract can call this function.
     * Emits an event once an address is successfully whitelisted.
     * 
     * @param _address The address to be added to the whitelist.
     */
    function WhiteList(address _address) public onlyOwner{
        require(!whiteList[_address],"This Address is already WhiteListed!");
        whilistedAddress.push(_address);
        whiteList[_address] = true;
    }

    /**
     * @dev Allows users to swap tokens by transferring them to the contract or distribute a fee among whitelisted addresses.
     * If the token being swapped is USDM, it is simply collected by the contract.
     * For other tokens, a 0.3% fee is distributed among all whitelisted addresses, and the rest is collected by the contract.
     * 
     * @param _ethToken The address of the ERC20 token to be swapped.
     * @param _amount The amount of the token to be swapped.
     */

    function swapTokens(address _ethToken,uint256 _amount,string memory substrateAddress) public {
        require(IERC20(_ethToken).allowance(msg.sender, address(this)) >= _amount, "Allowance not set");
        require(IERC20(_ethToken).balanceOf(msg.sender) >= _amount, "Insufficient balance");
        if(_ethToken == usdm){
            IERC20(_ethToken).transferFrom(msg.sender, address(this), (_amount));
            currentHoldings += (_amount);
            userAmount[msg.sender] = _amount;
            userTotalSwapAmount[msg.sender][substrateAddress] += _amount;
            userTokenAmount[msg.sender][_ethToken] += _amount;
            emit swapToken(msg.sender,_amount);
        }
        else{
            overColleteralFeeAmount = (_amount*3)/1000;
            uint eachWhilitedAddressFee = overColleteralFeeAmount/whilistedAddress.length;
            for (uint i=0; i<whilistedAddress.length; i++) 
            {
                IERC20(_ethToken).transferFrom(msg.sender, whilistedAddress[i], eachWhilitedAddressFee);
            }
            IERC20(_ethToken).transferFrom(msg.sender, address(this), (_amount-overColleteralFeeAmount));
            currentHoldings += (_amount-overColleteralFeeAmount);
            userAmount[msg.sender] = (_amount-overColleteralFeeAmount);
            userTotalSwapAmount[msg.sender][substrateAddress] += (_amount-overColleteralFeeAmount);
            userTokenAmount[msg.sender][_ethToken] += (_amount-overColleteralFeeAmount);
            emit swapToken(msg.sender,(_amount-overColleteralFeeAmount));
        }
       
    }
    /**
     * @dev Allows users to swap tokens back from the contract or distribute a fee among whitelisted addresses before sending back the tokens.
     * If the token being swapped back is USDM, it is directly transferred to the sender.
     * For other tokens, a 0.3% fee is distributed among all whitelisted addresses before sending the remaining tokens back to the sender.
     * 
     * @param _ethToken The address of the ERC20 token to be swapped back.
     * @param _amount The amount of the token to be swapped back.
     */
    function substrateSwapTokens(address _ethToken,uint256 _amount) public {
        require(IERC20(_ethToken).balanceOf(address(this)) >= _amount, "Insufficient balance");
        if(_ethToken == usdm){
            IERC20(_ethToken).safeTransfer(msg.sender,_amount);
            currentHoldings -= (_amount);
            userAmount[msg.sender] = _amount;
            userTokenAmount[msg.sender][_ethToken] -= _amount;
            emit swapToken(msg.sender,_amount);
        }
        else{

            overColleteralFeeAmount = (_amount*3)/1000;
            uint eachWhilitedAddressFee = overColleteralFeeAmount/whilistedAddress.length;
            for (uint i=0; i<whilistedAddress.length; i++) 
            {
                IERC20(_ethToken).safeTransfer(whilistedAddress[i],eachWhilitedAddressFee);
            }
             IERC20(_ethToken).safeTransfer(msg.sender,(_amount-overColleteralFeeAmount));
            currentHoldings -= (_amount-overColleteralFeeAmount);
            userAmount[msg.sender] = (_amount-overColleteralFeeAmount);
            userTokenAmount[msg.sender][_ethToken] -= (_amount-overColleteralFeeAmount);
            emit substrateSwapToken(msg.sender,(_amount-overColleteralFeeAmount));
        }
    
    }
    /**
     * @param _ethToken The address of the ERC20 token to be swapped back.
     * Only owner can withdaraw the Overcolleteral fee.
     */
    function withdrawBalanceTokens(address _ethToken) public onlyOwner {
        IERC20(_ethToken).safeTransfer(msg.sender, overColleteralFeeAmount);
    }



    /**
     * @dev Removes an address from the whitelist. Only the owner can call this function.
     * @param _address The address to be removed from the whitelist.
     */
    function removeFromWhiteList(address _address) public onlyOwner {
        require(whiteList[_address], "This Address does not exist!");
        whiteList[_address] = false;
    }

    /**
     * @dev Returns the USDT token balance of this contract.
     * @return holdings The amount of USDT tokens held by this contract.
     */
    function holdingOf_USDT(address holder) public view returns (uint holdings) {
        return userTokenAmount[holder][usdt];
        // return IERC20(usdt).balanceOf(holder);
    }

    /**
     * @dev Returns the DAI token balance of this contract.
     * @return holdings The amount of DAI tokens held by this contract.
     */
    function holdingOf_DAI(address holder) public view returns (uint holdings) {
        return userTokenAmount[holder][dai];
        // return IERC20(dai).balanceOf(holder);
    }

    /**
     * @dev Returns the USDC token balance of this contract.
     * @return holdings The amount of USDC tokens held by this contract.
     */
    function holdingOf_USDC(address holder) public view returns (uint holdings) {
        return userTokenAmount[holder][usdc];
        // return IERC20(usdc).balanceOf(holder);
    }

    /**
     * @dev Returns the USDM token balance of this contract.
     * @return holdings The amount of USDM tokens held by this contract.
     */
    function holdingOf_USDM(address holder) public view returns (uint holdings) {
        return userTokenAmount[holder][usdm];
        // return IERC20(usdm).balanceOf(holder);
    }

    /**
     * @dev Returns the balance of a specific ERC20 token held by this contract.
     * @param _ethToken The address of the ERC20 token.
     * @return holdings The amount of the specified tokens held by this contract.
     */
    function holdingOfTokens(address _ethToken) public view returns (uint holdings) {
        return userTokenAmount[msg.sender][_ethToken];
        // return IERC20(_ethToken).balanceOf(address(this));
    }

}