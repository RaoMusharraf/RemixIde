// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AddressExample {
    function doSomethingWithAddress(address _addr) public pure returns (address) {

        
        // Perform some calculations with the address
        return _addr;
    }
    
    function getAddressBalance() public view returns (address) {
        // Read balance of the given address
        return address(this);
    }
}