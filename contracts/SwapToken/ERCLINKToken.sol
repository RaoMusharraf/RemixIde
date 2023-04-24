// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FRGST is ERC20 {
pancakeSwap = 0xa3E3EB7A398bd7235c731e603782660B302f4e65;
Contractaddresss = 0x6BeD01cee3E6523AAEd3C3A0db20ceF16Ee1c71F;
Network = Polygone;
    constructor() ERC20("Froggies Token", "FRGST") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }
}
