// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";



contract Token is ERC20, Ownable,ERC20Burnable {

    // variables
    uint BuyTax;
    uint SellTax; 
    address public Wallet;
    address public PancakeSwap;
    address public constant routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant WETH = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

    uint24 public constant poolFee = 500;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);


    struct Cap{
        uint SellTax;
        uint BuyTax;
        uint XAmount;
        uint currentAmount;
    }
    // mappings
    mapping(address => bool) public whiteList;
    mapping(uint => Cap) public Taxs;

    IERC20 public linkToken;
    // IERC20 public WETHToken;

    constructor() ERC20("Froggies Token", "FRGST") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
        linkToken = IERC20(address(this));
        // WETHToken = IERC20(_WETHToken);
        Wallet = address(this);
    }
    // ============ WhiteList FUNCTIONS ============
    /* 
        @dev WhiteList take address as a parameter and make this address true in the whiteList.  
    */
    function WhiteList(address _address) public{
        whiteList[_address] = true;
    } 
    function setPancakeSwapAddress(address _address) public{
        PancakeSwap = _address;
    }

    // ============ swapExactInputSingle FUNCTIONS ============
    /* 
        @dev swapExactInputSingle this function take amount of token that you want to swap.  
    */
    function swapExactInputSingle(uint256 amountIn,address recipientAddresss) public returns (uint256 amountOut)
    {
        linkToken.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: WETH,
                fee: poolFee,
                recipient: recipientAddresss,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
    }

    // ============ transfer FUNCTIONS ============
    /* 
        @dev transfer take two parameter address of receiver and amount that you want to send.  
    */

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if(whiteList[msg.sender]){
            return super.transfer(to, amount);        
        }else{
            if(msg.sender == PancakeSwap){
                uint ReflectionAmount = ((amount*Taxs[1].BuyTax)/100);
                uint LPAmount = ((amount*Taxs[2].BuyTax)/100);
                uint InvestmentAmount = ((amount*Taxs[3].BuyTax)/100);
                uint MarkettingAmount = ((amount*Taxs[4].BuyTax)/100);
                if((Taxs[2].currentAmount + LPAmount) >= Taxs[2].XAmount) {
                    swapExactInputSingle(Taxs[2].XAmount,PancakeSwap);
                    Taxs[2].currentAmount = (Taxs[2].currentAmount + LPAmount) -  Taxs[2].XAmount;
                }else{
                    Taxs[2].currentAmount += LPAmount;
                }
                if((Taxs[3].currentAmount + InvestmentAmount) >= Taxs[3].XAmount) {
                    swapExactInputSingle(Taxs[3].XAmount,address(this));
                    Taxs[3].currentAmount = (Taxs[3].currentAmount + InvestmentAmount) -  Taxs[3].XAmount;
                }else{
                    Taxs[3].currentAmount += InvestmentAmount;
                }
                if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
                    swapExactInputSingle(Taxs[4].XAmount,address(this));
                    Taxs[4].currentAmount = (Taxs[4].currentAmount + MarkettingAmount) -  Taxs[4].XAmount;
                }else{
                    Taxs[4].currentAmount += MarkettingAmount;
                }  
                transfer(Wallet,ReflectionAmount);
                transfer(Wallet,LPAmount);
                transfer(Wallet,InvestmentAmount);
                transfer(Wallet,MarkettingAmount);
                return super.transfer(to, (amount-(ReflectionAmount+LPAmount+InvestmentAmount+MarkettingAmount)));
            }else if(to == PancakeSwap)
            {
                uint ReflectionAmount = ((amount*Taxs[1].SellTax)/100);
                uint LPAmount = ((amount*Taxs[2].SellTax)/100);
                uint InvestmentAmount = ((amount*Taxs[3].SellTax)/100);
                uint MarkettingAmount = ((amount*Taxs[4].SellTax)/100);
                if((Taxs[2].currentAmount + LPAmount) >= Taxs[2].XAmount) {
                    swapExactInputSingle(Taxs[2].XAmount,PancakeSwap);
                    Taxs[2].currentAmount = (Taxs[2].currentAmount + LPAmount) -  Taxs[2].XAmount;
                }else{
                    Taxs[2].currentAmount += LPAmount;
                }
                if((Taxs[3].currentAmount + InvestmentAmount) >= Taxs[3].XAmount) {
                    swapExactInputSingle(Taxs[3].XAmount,address(this));
                    Taxs[3].currentAmount = (Taxs[3].currentAmount + InvestmentAmount) -  Taxs[3].XAmount;
                }else{
                    Taxs[3].currentAmount += InvestmentAmount;
                }
                if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
                    swapExactInputSingle(Taxs[4].XAmount,address(this));
                    Taxs[4].currentAmount = (Taxs[4].currentAmount + MarkettingAmount) -  Taxs[4].XAmount;
                }else{
                    Taxs[4].currentAmount += MarkettingAmount;
                }  
                transfer(Wallet,ReflectionAmount);
                transfer(Wallet,LPAmount);
                transfer(Wallet,InvestmentAmount);
                transfer(Wallet,MarkettingAmount);
                return super.transfer(to, (amount-(ReflectionAmount+LPAmount+InvestmentAmount+MarkettingAmount)));
            }
            else{
                return super.transfer(to, amount);
            }
        }  
    }
    // ============ transferFrom FUNCTIONS ============
    /* 
        @dev transfer take three parameter address of sender and receiver and amount that you want to send.  
    */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if(whiteList[msg.sender]){
            return super.transferFrom(from, to, amount);      
        }else{
            if(from == PancakeSwap){
                uint ReflectionAmount = ((amount*Taxs[1].BuyTax)/100);
                uint LPAmount = ((amount*Taxs[2].BuyTax)/100);
                uint InvestmentAmount = ((amount*Taxs[3].BuyTax)/100);
                uint MarkettingAmount = ((amount*Taxs[4].BuyTax)/100);
                if((Taxs[2].currentAmount  + LPAmount) >= Taxs[2].XAmount) {
                    swapExactInputSingle(Taxs[2].XAmount,PancakeSwap);
                    Taxs[2].currentAmount = (Taxs[2].currentAmount  + LPAmount) -  Taxs[2].XAmount;
                }else{
                    Taxs[2].currentAmount  += LPAmount;
                }
                if((Taxs[3].currentAmount + InvestmentAmount) >= Taxs[3].XAmount) {
                    swapExactInputSingle(Taxs[3].XAmount,address(this));
                    Taxs[3].currentAmount = (Taxs[3].currentAmount + InvestmentAmount) -  Taxs[3].XAmount;
                }else{
                    Taxs[3].currentAmount += InvestmentAmount;
                }
                if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
                    swapExactInputSingle(Taxs[4].XAmount,address(this));
                    Taxs[4].currentAmount = (Taxs[4].currentAmount + MarkettingAmount) -  Taxs[4].XAmount;
                }else{
                    Taxs[4].currentAmount += MarkettingAmount;
                }  
                transfer(Wallet,ReflectionAmount);
                transfer(Wallet,LPAmount);
                transfer(Wallet,InvestmentAmount);
                transfer(Wallet,MarkettingAmount);  
                return super.transferFrom(from, to, amount-(ReflectionAmount+LPAmount+InvestmentAmount+MarkettingAmount));
            }else if(to == PancakeSwap)
            {
                uint ReflectionAmount = ((amount*Taxs[1].SellTax)/100);
                uint LPAmount = ((amount*Taxs[2].SellTax)/100);
                uint InvestmentAmount = ((amount*Taxs[3].SellTax)/100);
                uint MarkettingAmount = ((amount*Taxs[4].SellTax)/100);
                // if((Taxs[1].currentAmount + ReflectionAmount) >= Taxs[1].XAmount) {
                //     swapExactInputSingle(Taxs[1].XAmount);
                //     Taxs[1].currentAmount = (Taxs[1].currentAmount + ReflectionAmount) -  Taxs[1].XAmount;
                // }else{
                //     Taxs[1].currentAmount += ReflectionAmount;
                // }
                if((Taxs[2].currentAmount  + LPAmount) >= Taxs[2].XAmount) {
                    swapExactInputSingle(Taxs[2].XAmount,PancakeSwap);
                    Taxs[2].currentAmount = (Taxs[2].currentAmount  + LPAmount) -  Taxs[2].XAmount;
                }else{
                    Taxs[2].currentAmount  += LPAmount;
                }
                if((Taxs[3].currentAmount  + InvestmentAmount) >= Taxs[3].XAmount) {
                    swapExactInputSingle(Taxs[3].XAmount,address(this));
                    Taxs[3].currentAmount = (Taxs[3].currentAmount  + InvestmentAmount) -  Taxs[3].XAmount;
                }else{
                    Taxs[3].currentAmount  += InvestmentAmount;
                }
                if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
                    swapExactInputSingle(Taxs[4].XAmount,address(this));
                    Taxs[4].currentAmount = (Taxs[4].currentAmount + MarkettingAmount) -  Taxs[4].XAmount;
                }else{
                    Taxs[4].currentAmount += MarkettingAmount;
                } 
                transfer(Wallet,ReflectionAmount);
                transfer(Wallet,LPAmount);
                transfer(Wallet,InvestmentAmount);
                transfer(Wallet,MarkettingAmount);
                return super.transferFrom(from, to, amount-(ReflectionAmount+LPAmount+InvestmentAmount+MarkettingAmount));
            }
            else{
                return super.transferFrom(from, to, amount);
            }
        }  
    }
    // ============ setReflectionSellTax FUNCTIONS ============
    /* 
        @dev setReflectionSellTax take Tax percentage as a parameter and set this percentage to ReflectionSellTax variable.  
    */
    function setReflectionSellTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[1].SellTax = Tax;
    }

    // ============ setLPSellTax FUNCTIONS ============
    /* 
        @dev setLPSellTax take Tax percentage as a parameter and set this percentage to LPSellTax variable.  
    */
    function setLPSellTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[2].SellTax = Tax;
    }

    // ============ setInvestmentSellTax FUNCTIONS ============
    /* 
        @dev setInvestmentSellTax take Tax percentage as a parameter and set this percentage to InvestmentSellTax variable.  
    */
    function setInvestmentSellTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[3].SellTax = Tax;
    }
    // ============ setMarkettingSellTax FUNCTIONS ============
    /* 
        @dev setMarkettingSellTax take Tax percentage as a parameter and set this percentage to MarkettingSellTax variable.  
    */
    function setMarkettingSellTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[4].SellTax = Tax;
    }

    // ============ setReflectionBuyTax FUNCTIONS ============
    /* 
        @dev setReflectionBuyTax take Tax percentage as a parameter and set this percentage to ReflectionBuyTax variable.  
    */
    function setReflectionBuyTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[1].BuyTax = Tax;
    }

    // ============ setLPBuyTax FUNCTIONS ============
    /* 
        @dev setLPBuyTax take Tax percentage as a parameter and set this percentage to LPBuyTax variable.  
    */
    function setLPBuyTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[2].BuyTax = Tax;
    }

    // ============ setInvestmentBuyTax FUNCTIONS ============
    /* 
        @dev setInvestmentBuyTax take Tax percentage as a parameter and set this percentage to InvestmentBuyTax variable.  
    */
    function setInvestmentBuyTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[3].BuyTax = Tax;
    }
    // ============ setMarkettingBuyTax FUNCTIONS ============
    /* 
        @dev setMarkettingBuyTax take Tax percentage as a parameter and set this percentage to MarkettingBuyTax variable.  
    */
    function setMarkettingBuyTax(uint Tax) public onlyOwner{
        require(Tax >= 0 && Tax <=15,"Tax Amount must be 0 to 15");
        Taxs[4].BuyTax = Tax;
    }
    // ============ setLPXAmount FUNCTIONS ============
    /* 
        @dev setLPXAmount take Amount percentage as a parameter and set this percentage to LPXAmount variable.  
    */
    function setLPXAmount(uint Amount) public onlyOwner{
        Taxs[2].XAmount = Amount;
    }

    // ============ setInvestmentXAmount FUNCTIONS ============
    /* 
        @dev setInvestmentXAmount take Amount percentage as a parameter and set this percentage to InvestmentXAmount variable.  
    */
    function setInvestmentXAmount(uint Amount) public onlyOwner{
        Taxs[3].XAmount = Amount;
    }
    // ============ setMarkettingXAmount FUNCTIONS ============
    /* 
        @dev setMarkettingXAmount take Amount percentage as a parameter and set this percentage to MarkettingXAmount variable.  
    */
    function setMarkettingXAmount(uint Amount) public onlyOwner{
        Taxs[4].XAmount = Amount;
    }

    // function WithdrawWETH(uint amount) public onlyOwner{
    //     WETHToken.transfer(msg.sender,amount);
    // }

    function setTaxData(uint SaleT,uint BuyT,uint amount,uint Typ) public {
        require(Typ >0 && Typ < 5,"Typ Must Be (1,2,3,4)");
        Taxs[Typ] = Cap(SaleT,BuyT,amount,0);
    }
}
