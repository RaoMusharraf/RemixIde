// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
  
contract LearningStrings {

    // function convertStrinToBytes(string memory data) public pure returns(bytes memory byteToString){
    //     bytes memory b = bytes(data);
    //     return b;
    // }
    // function convertByteToString(bytes memory data) public pure returns(string memory stringToByte){
    //     string memory b = string(data);
    //     return b;
    // }

   function getLength(string memory s) public pure returns (uint256 length) 
   {
        bytes memory b = bytes(s);
        return (b.length);
    }
}