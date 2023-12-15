// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YieldToken is ERC20, ERC20Burnable, Pausable, Ownable {
    /** 
        Default Constructor With Initial Supply Arguments
    **/
    constructor(address owner) ERC20("USDT Token", "USDT") Ownable(owner) {
        _mint(msg.sender, 1000000000 * 10**decimals());
    }

    /** 
        Pause Token Function Controlled by Owner Only
    **/
    function pause() public onlyOwner {
        _pause();
    }

    /** 
        Unpause Token Function Controlled by Owner Only
    **/
    function unpause() public onlyOwner {
        _unpause();
    }

}