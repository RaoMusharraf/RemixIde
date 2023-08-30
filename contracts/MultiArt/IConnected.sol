// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IConnected {
    /**
     * @dev update Token Id in the minted contract.
     */
    function updateTokenId(address _to,uint _tokenId,address seller) external;
    // function balanceOf(address _owner) external view returns(uint256);
    // function setApprovalForAll(address _owner,bool _check) external;
    // function setApprove(address _to) external;
}