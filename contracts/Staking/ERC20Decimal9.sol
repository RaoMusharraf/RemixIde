// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FroggiesToken is ERC20, ERC20Burnable {
    using SafeMath for uint256;

    constructor() ERC20("Froggies Token", "FRGST") {
        uint256 initialSupply = 100000000000000000000000; // 1,000,000,000 with 9 decimal places
        _mint(msg.sender, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }
}
