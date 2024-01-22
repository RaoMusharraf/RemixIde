// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is ERC20, ERC20Burnable, Pausable, Ownable {
    /** 
        Default Constructor With Initial Supply Arguments
    **/
    constructor(address initialOwner) Ownable(initialOwner) ERC20("USDT Token", "USDT") {
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