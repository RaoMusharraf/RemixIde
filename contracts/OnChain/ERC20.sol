// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Funding token", "FUND") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}