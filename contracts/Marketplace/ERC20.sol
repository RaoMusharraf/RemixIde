// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20FT is ERC20 {
    constructor() ERC20("MyToken", "DST") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}


