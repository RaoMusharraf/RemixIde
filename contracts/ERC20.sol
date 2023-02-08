// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetanexusWorld is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Metanexus World", "MTX") {
        _mint(msg.sender, 3000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    function BurnToken(uint amount) public onlyOwner{
        transfer(0x000000000000000000000000000000000000dEaD, amount);
    }
}