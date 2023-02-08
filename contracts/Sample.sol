// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HelloWorld {
    event log_string(bytes32 log); // Event
    
    function () public { // Fallback Function
        log_string("Hello World!");
    }
}