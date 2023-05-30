// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Token is ERC20, Ownable, ReentrancyGuard,ERC20Burnable {
    using SafeMath for uint256;

    bool public isSwap;
    address public PancakeSwap;
    // IUniswapV2Router02 public uniswapV2Router;
    // address public uniswapV2Pair;

    event SwapAndLiquify(uint256 half, uint256 newBalance, uint256 otherHalf);
    event SwapTokensForBNB(uint256 tokenAmount, uint256 receivedBNB);

    uint public lpThreshold = 0;
    uint public marketingThreshold = 1000000000000000000 * 10**18;
    uint public lpCurrentAmount;
    uint public marketingCurrentAmount;

    uint24 public poolFee;
    address public WBNB;
    address public constant routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);
    IERC20 public linkToken;
    IERC20 public WBNBToken;

    struct Fees {
        uint lp;
        uint burn;
        uint marketing;
    }

    Fees public buyFees = Fees(1, 1, 1);
    Fees public sellFees = Fees(1, 1, 1);

    uint256 public totalBuyFee = 3;
    uint256 public totalSellFee = 3;

    // mappings
    mapping(address => bool) public whiteList;
    mapping(address => bool) public isPair;

    constructor() ERC20("DbmTK2", "DBTK2") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
        linkToken = IERC20(address(this));
    }

    // function setPancakeSwapPair(address _router) public{
    //     address pancakeRouter = _router; // PancakeSwap router address for BSC
    //     IUniswapV2Router02 _pancakeV2Router = IUniswapV2Router02(pancakeRouter);
    //     IUniswapV2Factory factoryPancake = IUniswapV2Factory(_pancakeV2Router.factory());

    //     address _pancakeV2Pair = factoryPancake.createPair(address(this), _pancakeV2Router.WETH());

    //     uniswapV2Router = _pancakeV2Router;
    //     uniswapV2Pair = _pancakeV2Pair;

    //     isPair[uniswapV2Pair] = true;
    // }

    receive() external payable {}

    // function amountTransfer(address from,address to,uint256 amt) public{
    //     _transfer(from,to,amt);
    // }


    // Adds an address to the whitelist
    function addToWhitelist(address _address) external onlyOwner {
        whiteList[_address] = true;
    }

    // Custom transfer function with buy and sell fees and burn functionality
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(amount > 0, "Transfer amount must be greater than 0");
        if (whiteList[msg.sender] || msg.sender == owner()) {
            return super.transfer(to, amount);
        } else {
            // Buy transaction
            if (isPair[msg.sender]) {
                uint256 lpAmount = amount.mul(buyFees.lp).div(100);
                uint256 marketingAmount = amount.mul(buyFees.marketing).div(100);
                uint256 remainingAmount = amount.sub(lpAmount).sub(marketingAmount);

                if (lpAmount > 0) {
                    handleLPThreshold(lpAmount);
                }
                if (marketingAmount > 0) {
                    handleMarketingThreshold(marketingAmount);
                }
                if (buyFees.burn > 0) {
                    uint256 burnAmount = amount.mul(buyFees.burn).div(100);
                    require(burnAmount <= balanceOf(msg.sender), "Insufficient balance to burn tokens");
                    super.burn(burnAmount);
                    remainingAmount = remainingAmount.sub(burnAmount);
                }
                return super.transfer(to, remainingAmount);
            }
            // Sell transaction
            else if (isPair[to]) {
                uint256 lpAmount = amount.mul(sellFees.lp).div(100);
                uint256 marketingAmount = amount.mul(sellFees.marketing).div(100);
                uint256 remainingAmount = amount.sub(lpAmount).sub(marketingAmount);

                if (lpAmount > 0) {
                    handleLPThreshold(lpAmount);
                }
                if (marketingAmount > 0) {
                    handleMarketingThreshold(marketingAmount);
                }
                if (sellFees.burn > 0) {
                    uint256 burnAmount = amount.mul(sellFees.burn).div(100);
                    require(burnAmount <= balanceOf(msg.sender), "Insufficient balance to burn tokens");
                    super.burn(burnAmount);
                    remainingAmount = remainingAmount.sub(burnAmount);
                }
                return super.transfer(to, remainingAmount);
            }
            // Standard transfer
            else {
                return super.transfer(to, amount);
            }
        }
    }

    function handleLPThreshold(uint256 lpAmount) internal {
        if (lpThreshold != 0 && (lpCurrentAmount.add(lpAmount) >= lpThreshold)) {
            swapAndLiquify(lpThreshold);
            lpCurrentAmount = lpCurrentAmount.add(lpAmount).sub(lpThreshold);
        } else {
            lpCurrentAmount = lpCurrentAmount.add(lpAmount);
        }
    }

    function handleMarketingThreshold(uint256 marketingAmount) internal {
        if (isSwap && marketingThreshold != 0 && (marketingCurrentAmount.add(marketingAmount) >= marketingThreshold)) {
            _swapTokensForBNB(marketingThreshold, address(this));
            marketingCurrentAmount = marketingCurrentAmount.add(marketingAmount).sub(marketingThreshold);
        } else {
            marketingCurrentAmount = marketingCurrentAmount.add(marketingAmount);
            super.transfer(address(this), marketingAmount); // Transfer the marketing amount to the contract
        }
    }

    function _swapTokensForBNB(uint256 amountIn,address recipientAddresss) public returns (uint256 amountOut)
    {
        linkToken.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: WBNB,
                fee: poolFee,
                recipient: recipientAddresss,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapAndLiquify(uint256 toSwapLiquidity) internal {
        uint256 halfTokensToSell = toSwapLiquidity.div(2);
        uint256 otherHalfTokensToAddToLiquidity = toSwapLiquidity.sub(halfTokensToSell);
        _swapTokensForBNB(halfTokensToSell, address(this));
        super.transfer(PancakeSwap,otherHalfTokensToAddToLiquidity);
        // addLiquidity(otherHalfTokensToAddToLiquidity, swappedBNBForLiquify);
    }

    // function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) internal {
    //     _approve(address(this), address(uniswapV2Router), tokenAmount);

    //     uniswapV2Router.addLiquidityETH{value: bnbAmount}(
    //         address(this),
    //         tokenAmount,
    //         0,
    //         0,
    //         owner(),
    //         block.timestamp
    //     );
    // }

    function setBuyTaxes(uint _lp, uint _burn, uint _marketing) external onlyOwner {
        totalBuyFee = _lp + _burn + _marketing;
        require(totalBuyFee <= 10, "Total buy fees cannot be more than 10%");
        buyFees = Fees(_lp, _burn, _marketing);
    }

    function setSellTaxes(uint _lp, uint _burn, uint _marketing) external onlyOwner {
        totalSellFee = _lp + _burn + _marketing;
        require(totalSellFee <= 10, "Total sell fees cannot be more than 10%");
        sellFees = Fees(_lp, _burn, _marketing);
    }

    function setLPThreshold(uint256 amount) public onlyOwner {
        uint256 currentTotalSupply = totalSupply();
        uint256 minLpThreshold = currentTotalSupply.mul(2).div(10000); // 0.02% of the current total token supply
        uint256 maxLpThreshold = currentTotalSupply.mul(5).div(100); // 5% of the current total token supply

        require(amount >= minLpThreshold && amount <= maxLpThreshold, "LP Threshold must be within the allowed range");
        lpThreshold = amount;
    }

    function setMarketingThreshold(uint256 amount) public onlyOwner{
        marketingThreshold = amount;
    }

    //set marketing auto-swap to WBNB
    function setMarketingSwap(bool check) public onlyOwner{
        isSwap = check;
    }

    function withdrawBNB(address payable to, uint256 amount) external onlyOwner nonReentrant {
        require(amount <= address(this).balance, "Not enough BNB in the contract to withdraw");
        WBNBToken.transfer(to,amount);
    }

    function withdrawMarketingTokens(address to, uint256 amount) public onlyOwner nonReentrant {
        require(marketingCurrentAmount >= amount, "Not enough tokens in marketing balance");
        IERC20(address(this)).transfer(to, amount);
        marketingCurrentAmount = marketingCurrentAmount - amount;
    }

    function setAddressFee(address _PancakeSwapAddress,address _WBNBAddress,uint24 _poolFee) public onlyOwner {
        PancakeSwap = _PancakeSwapAddress;
        WBNBToken = IERC20(_WBNBAddress);
        WBNB = _WBNBAddress;
        poolFee = _poolFee;
        isPair[_PancakeSwapAddress] = true;
    }
}