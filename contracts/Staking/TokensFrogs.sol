// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./ISwap.sol";


contract Token is ERC20, Ownable,ERC20Burnable {

    // variables
    uint BuyTax;
    uint SellTax; 
    address public Wallet;
    address public PancakeSwap;
    address public WETH ;
    address public swapAddress;
    uint24 public constant poolFee = 500;
    address thisContract = 0xE0f08C6Ec444F1cbF88fD406805e0bF0E31b6261;

    struct Cap{
        uint SellTax;
        uint BuyTax;
        uint XAmount;
        uint currentAmount;
    }
    // mappings
    mapping(address => bool) public whiteList;
    mapping(uint => Cap) public Taxs;

    // IERC20 public linkToken;
    // // IERC20 public WETHToken;

    constructor() ERC20("Froggies Token", "FRGST") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
        
        // linkToken = IERC20(address(this));
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
    function setWETHAddress(address _address) public{
        WETH = _address;
    }
    function setPancakeSwapAddress(address _address) public{
        PancakeSwap = _address;
    }
    function setSwapAddress(address _swapAddress) public{
        swapAddress = _swapAddress;
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
                    ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[2].XAmount,address(this),WETH,PancakeSwap);
                    Taxs[2].currentAmount = (Taxs[2].currentAmount + LPAmount) -  Taxs[2].XAmount;
                }else{
                    Taxs[2].currentAmount += LPAmount;
                }
                if((Taxs[3].currentAmount + InvestmentAmount) >= Taxs[3].XAmount) {
                    ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[3].XAmount,address(this),WETH,PancakeSwap);
                    Taxs[3].currentAmount = (Taxs[3].currentAmount + InvestmentAmount) -  Taxs[3].XAmount;
                }else{
                    Taxs[3].currentAmount += InvestmentAmount;
                }
                if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
                    ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[4].XAmount,address(this),WETH,PancakeSwap);
                    Taxs[4].currentAmount = (Taxs[4].currentAmount + MarkettingAmount) -  Taxs[4].XAmount;
                }else{
                    Taxs[4].currentAmount += MarkettingAmount;
                }  
                transfer(Wallet,ReflectionAmount);
                transfer(Wallet,LPAmount);
                transfer(Wallet,InvestmentAmount);
                transfer(Wallet,MarkettingAmount);
                return super.transfer(to, (amount-(ReflectionAmount+LPAmount+InvestmentAmount+MarkettingAmount)));
            }else 
            if(to == PancakeSwap)
            {
                uint ReflectionAmount = ((amount*Taxs[1].SellTax)/100);
                uint LPAmount = ((amount*Taxs[2].SellTax)/100);
                uint InvestmentAmount = ((amount*Taxs[3].SellTax)/100);
                uint MarkettingAmount = ((amount*Taxs[4].SellTax)/100);
                if((Taxs[2].currentAmount + LPAmount) >= Taxs[2].XAmount) {
                    ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[2].XAmount,address(this),WETH,PancakeSwap);
                    Taxs[2].currentAmount = (Taxs[2].currentAmount + LPAmount) -  Taxs[2].XAmount;
                }else{
                    Taxs[2].currentAmount += LPAmount;
                }
                if((Taxs[3].currentAmount + InvestmentAmount) >= Taxs[3].XAmount) {
                    ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[3].XAmount,address(this),WETH,PancakeSwap);
                    Taxs[3].currentAmount = (Taxs[3].currentAmount + InvestmentAmount) -  Taxs[3].XAmount;
                }else{
                    Taxs[3].currentAmount += InvestmentAmount;
                }
                if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
                    ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[4].XAmount,address(this),WETH,PancakeSwap);
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
    // // ============ transferFrom FUNCTIONS ============
    // /* 
    //     @dev transfer take three parameter address of sender and receiver and amount that you want to send.  
    // */
    // function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
    //     if(whiteList[msg.sender]){
    //         return super.transferFrom(from, to, amount);      
    //     }else{
    //         if(from == PancakeSwap){
    //             uint ReflectionAmount = ((amount*Taxs[1].BuyTax)/100);
    //             uint LPAmount = ((amount*Taxs[2].BuyTax)/100);
    //             uint InvestmentAmount = ((amount*Taxs[3].BuyTax)/100);
    //             uint MarkettingAmount = ((amount*Taxs[4].BuyTax)/100);
    //             if((Taxs[2].currentAmount  + LPAmount) >= Taxs[2].XAmount) {
    //                 ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[2].XAmount,address(this),WETH,PancakeSwap);
    //                 Taxs[2].currentAmount = (Taxs[2].currentAmount  + LPAmount) -  Taxs[2].XAmount;
    //             }else{
    //                 Taxs[2].currentAmount  += LPAmount;
    //             }
    //             if((Taxs[3].currentAmount + InvestmentAmount) >= Taxs[3].XAmount) {
    //                 ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[3].XAmount,address(this),WETH,PancakeSwap);
    //                 Taxs[3].currentAmount = (Taxs[3].currentAmount + InvestmentAmount) -  Taxs[3].XAmount;
    //             }else{
    //                 Taxs[3].currentAmount += InvestmentAmount;
    //             }
    //             if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
    //                 ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[4].XAmount,address(this),WETH,PancakeSwap);
    //                 Taxs[4].currentAmount = (Taxs[4].currentAmount + MarkettingAmount) -  Taxs[4].XAmount;
    //             }else{
    //                 Taxs[4].currentAmount += MarkettingAmount;
    //             }  
    //             transfer(Wallet,ReflectionAmount);
    //             transfer(Wallet,LPAmount);
    //             transfer(Wallet,InvestmentAmount);
    //             transfer(Wallet,MarkettingAmount);  
    //             return super.transferFrom(from, to, amount-(ReflectionAmount+LPAmount+InvestmentAmount+MarkettingAmount));
    //         }else if(to == PancakeSwap)
    //         {
    //             uint ReflectionAmount = ((amount*Taxs[1].SellTax)/100);
    //             uint LPAmount = ((amount*Taxs[2].SellTax)/100);
    //             uint InvestmentAmount = ((amount*Taxs[3].SellTax)/100);
    //             uint MarkettingAmount = ((amount*Taxs[4].SellTax)/100);
    //             if((Taxs[2].currentAmount  + LPAmount) >= Taxs[2].XAmount) {
    //                 ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[2].XAmount,address(this),WETH,PancakeSwap);
    //                 Taxs[2].currentAmount = (Taxs[2].currentAmount  + LPAmount) -  Taxs[2].XAmount;
    //             }else{
    //                 Taxs[2].currentAmount  += LPAmount;
    //             }
    //             if((Taxs[3].currentAmount  + InvestmentAmount) >= Taxs[3].XAmount) {
    //                 ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[3].XAmount,address(this),WETH,PancakeSwap);
    //                 Taxs[3].currentAmount = (Taxs[3].currentAmount  + InvestmentAmount) -  Taxs[3].XAmount;
    //             }else{
    //                 Taxs[3].currentAmount  += InvestmentAmount;
    //             }
    //             if((Taxs[4].currentAmount + MarkettingAmount) >= Taxs[4].XAmount) {
    //                 ISwap(swapAddress).swapExactInputSingle(poolFee,Taxs[4].XAmount,address(this),WETH,PancakeSwap);
    //                 Taxs[4].currentAmount = (Taxs[4].currentAmount + MarkettingAmount) -  Taxs[4].XAmount;
    //             }else{
    //                 Taxs[4].currentAmount += MarkettingAmount;
    //             } 
    //             transfer(Wallet,ReflectionAmount);
    //             transfer(Wallet,LPAmount);
    //             transfer(Wallet,InvestmentAmount);
    //             transfer(Wallet,MarkettingAmount);
    //             return super.transferFrom(from, to, amount-(ReflectionAmount+LPAmount+InvestmentAmount+MarkettingAmount));
    //         }
    //         else{
    //             return super.transferFrom(from, to, amount);
    //         }
    //     }  
    // }
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