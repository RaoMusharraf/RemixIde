// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract Octa is ERC721{
    // user to nft id
    mapping(address => uint256) public nfts_minted_byuser;
    //admin 
    address public admin;
    uint256 public level1End;
    uint256 public level2End;
    uint256 public totalSupply;
    bool public level1Closed;
    bool public level2Closed;
     
    constructor (string memory name, string memory symbol ) ERC721(name,symbol){
        totalSupply=0;
        level1End=600;
        level2End=1200;
        admin = msg.sender;
        level1Closed = false;
        level2Closed = true;
    }
    function MintingNFTS(address to, uint256[] memory ids) public payable {
        // Task requirement No 1
        // Each User can mint only 3 NFTs at one time.
        require(ids.length<=3,"User Can Only Mint 3NFTS");
        //a. Use variable to record each user's nfts. One user cannot mint more than 5 nfts from total supply.
        require(nfts_minted_byuser[to] <5,"One user cannot mint more than 5 nfts from total supply ");
        //Task requirement No 3
        require(totalSupply<12000,"Total Supply Limit Reached");
        require(!level2Closed, "Level 2 is currently closed");
        for (uint256 i=0; i<ids.length; i++) {
            totalSupply++;
            nfts_minted_byuser[to]++;
            emit Transfer(address(0), to, ids[i]);
        }
        //Level 1, level start when NFT count is 0 and closes when NFTs Count 600.
       if (totalSupply == level1End && !level1Closed) {
            level1Closed = true;
            level2Closed = false;
        }
        //Level 2,level start when NFT count 601 and close when NFTs Count 1200.
        else if (totalSupply == level2End) {
            level2Closed = true;
        }
        //Task requirement No 5 : When User Mint NFTs then 100wei amount should be transfered to the Admin account (100wei per nft).
        if (msg.sender == admin) {
            payable(msg.sender).transfer(100 * ids.length);
        }
    }
    //Admin will open level 1 manually.
    function openLevel2() public {
        //Admin cannot open stage 2 until NFT count will be 600.
        require(level1Closed, "Level 1 must be closed before opening Level 2");
        level2Closed = false;
    }
    //Admin can close both levels at any time.
    function closeLevels() public {
        level1Closed = true;
        level2Closed = true;
    }
    // Task requirement No 6 : Make a function in which user can also view IDs of the minted NFTs.
    function getNFTIds(address receiver)public view returns (uint256[] memory){
       uint256[] memory ids = new uint256[](nfts_minted_byuser[receiver]);
         for (uint256 i = 0; i < ids.length; i++) {
            ids[i] = tokenIdByIndex(i);
        }
        return ids;
    }
    function tokenIdByIndex(uint256 index) public view returns (uint256) {
    return totalSupply - index - 1;
    }
    function viewMintedNFTs(address receiver) public view returns (uint256[] memory) {
        return getNFTIds(receiver);
    }
    
    
    
}