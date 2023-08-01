// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import BEP-20 interface for Binance Smart Chain
import "./IBEP20.sol";
import "./IERC20.sol";

contract ERC20andBEP20TokenTransfer {
    
    address public owner;
    address public bep20TokenAddress; // Address of the BEP-20 token contract
    address public erc20TokenAddress; // Address of the ERC-20 token contract

    constructor(address _bep20TokenAddress,address _erc20TokenAddress) {
        owner = msg.sender;
        bep20TokenAddress = _bep20TokenAddress;
        erc20TokenAddress = _erc20TokenAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    // Function to allow the contract to receive BEP-20 tokens from the owner
    function depositTokensBEP20(uint256 _amount) public onlyOwner {
        IERC20(bep20TokenAddress).safeTransferFrom(msg.sender,address(this),_amount);
        IBEP20 bep20TokenContract = IBEP20(bep20TokenAddress);
        require(bep20TokenContract.balanceOf(owner) >= _amount, "Insufficient balance");
        require(bep20TokenContract.transfer(address(this), _amount), "Transfer failed");
    }
    // Function to allow the contract to receive BEP-20 tokens from the user
    function depositTokensBEP20User(address _user,uint256 _amount) public {
        IBEP20 bep20TokenContract = IBEP20(bep20TokenAddress);
        require(bep20TokenContract.balanceOf(_user) >= _amount, "Insufficient balance");
        require(bep20TokenContract.transfer(address(this), _amount), "Transfer failed");
    }

    // Function to allow users to withdraw their deposited BEP-20 tokens
    function withdrawTokensBEP20(uint256 _amount) public {
        IBEP20 bep20TokenContract = IBEP20(bep20TokenAddress);
        address contractAddress = address(this);
        require(bep20TokenContract.balanceOf(contractAddress) >= _amount, "Insufficient contract balance");
        require(bep20TokenContract.transfer(msg.sender, _amount), "Transfer failed");
    }
    // Function to allow the contract to receive ERC-20 tokens from the owner
    function depositTokensERC20(uint256 _amount) public onlyOwner {
        IERC20 erc20TokenContract = IERC20(erc20TokenAddress);
        require(erc20TokenContract.balanceOf(owner) >= _amount, "Insufficient balance");
        require(erc20TokenContract.transfer(address(this), _amount), "Transfer failed");
    }
    // Function to allow the contract to receive ERC-20 tokens from the owner
    function depositTokensERC20User(address _user,uint256 _amount) public{
        IERC20 erc20TokenContract = IERC20(erc20TokenAddress);
        require(erc20TokenContract.balanceOf(_user) >= _amount, "Insufficient balance");
        require(erc20TokenContract.transfer(address(this), _amount), "Transfer failed");
    }
    // Function to allow users/owner to withdraw their deposited ERC-20 tokens
    function withdrawTokensERC20(uint256 _amount) public {
        IERC20 erc20TokenContract = IERC20(erc20TokenAddress);
        address contractAddress = address(this);
        require(erc20TokenContract.balanceOf(contractAddress) >= _amount, "Insufficient contract balance");
        require(erc20TokenContract.transfer(msg.sender, _amount), "Transfer failed");
    }

    // Function to check the contract's ERC-20 token balance
    function getContractBalanceERC20() public view returns (uint256) {
        IERC20 erc20TokenContract = IERC20(erc20TokenAddress);
        address contractAddress = address(this);
        return erc20TokenContract.balanceOf(contractAddress);
    }
    // Function to check the contract's BEP-20 token balance
    function getContractBalanceBEP20() public view returns (uint256) {
        IBEP20 bep20TokenContract = IBEP20(bep20TokenAddress);
        address contractAddress = address(this);
        return bep20TokenContract.balanceOf(contractAddress);
    }
}
