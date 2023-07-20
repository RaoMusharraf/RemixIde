// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20FT is ERC20, Ownable {
    constructor() ERC20("MyToken", "DST") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}