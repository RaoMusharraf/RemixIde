// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeflyToken is ERC20 {
    constructor() ERC20("Defly Ball", "DEFLY") {
        _mint(msg.sender, 100000000000000000000000);
    }
    function Users(uint256 amount) public{
        _mint(msg.sender, amount);
    }
    function decimals() public pure override returns (uint8) {
        return 9;
    }
}