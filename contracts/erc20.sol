// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeflyToken is ERC20 {
    constructor() ERC20("Yield Token", "USDM") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}