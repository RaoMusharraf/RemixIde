// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IConnected {
    function nftDetail(address _to,uint _tokenId) external view returns(bool onList);
}

contract Dispatch is ERC721, ERC721Pausable, Ownable {
    uint256 public  _nextTokenId;
    uint256 public URICount;
    mapping(address user => mapping(uint counter => Token)) public tokenDetail;
    mapping(address user => uint) public count;
    mapping(address user => mapping(uint id => bool)) isActive;
    mapping(address user => uint rewardPoints) public TotalRewardPoints;
    mapping (uint id => Admin) public URI;

    //Struct
    struct Token {
        uint tokenId;
        string uri;
        uint capAmount;
        uint points;
    }
    struct getTokenInfo{
        Token tokenDetail;
        address approvedAddress;
        bool onList;
    }
    struct Admin {
        string uri;
        uint capAmount;
        uint Count;
    }

    constructor(address initialOwner)
        ERC721("Dispatch AI", "DPAI")
        Ownable(initialOwner)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function bulkEnterData (string[] memory _uri,uint[] memory capAmount,uint leng) public onlyOwner{
        for (uint i = 0 ; i < leng; i++) 
        {
            URICount++;
            URI[URICount] = Admin(_uri[i],capAmount[i],URICount);
        }
    }

    function EnterData (string memory _uri,uint capAmount) public onlyOwner{
        URICount++;
        URI[URICount] = Admin(_uri,capAmount,URICount);
    }


    function safeMint(address to,uint id) public {
        require(!isActive[to][id],"You have Already Mint this Stone!");
        require(URI[id].capAmount <= TotalRewardPoints[to],"Insufficient Balance!");
        _nextTokenId++;
        _safeMint(to, _nextTokenId);
        tokenDetail[to][count[to]+1] = Token(_nextTokenId,URI[id].uri,URI[id].capAmount,URI[id].capAmount);
        TotalRewardPoints[to] -= URI[id].capAmount;
        isActive[to][id] = true;
        count[to]++;
    }

    function getTokenDetail(address to,address marketplaceContractAddress) public view returns (getTokenInfo[] memory TokensDetail) {
        getTokenInfo[] memory myArray = new getTokenInfo[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            (bool onList, address approvedAddress) = approvedDetail(marketplaceContractAddress, address(this), tokenDetail[to][i + 1].tokenId);
            myArray[i] = getTokenInfo(
            {
                tokenDetail:tokenDetail[to][i + 1],
                approvedAddress:approvedAddress,
                onList:onList
            }
            );
        }
        return myArray;
    }
    function getToken_w_r_t_Rewards(address to,address marketplaceContractAddress) public view returns (getTokenInfo[] memory TokensDetail) {
        uint increment = 0;
        while (increment < count[to]) 
        {
            if (tokenDetail[to][increment + 1].capAmount < TotalRewardPoints[to]) {
                increment++;
            }
        }
        getTokenInfo[] memory myArray = new getTokenInfo[](increment);
        for (uint256 i = 0; i < count[to]; i++) {
            if (tokenDetail[to][i + 1].capAmount < TotalRewardPoints[to]) {
                (bool onList, address approvedAddress) = approvedDetail(marketplaceContractAddress, address(this), tokenDetail[to][i + 1].tokenId);
                myArray[i] = getTokenInfo(
                {
                    tokenDetail:tokenDetail[to][i + 1],
                    approvedAddress:approvedAddress,
                    onList:onList
                }
                );
            }
        }
        return myArray;
    }

    function getToken(address to,uint _tokenId) public view returns (Token[] memory token) {
        Token[] memory myArray =  new Token[](1);
        for(uint i=0 ; i < count[to] ; i++){
            if(tokenDetail[to][i + 1].tokenId == _tokenId){
                myArray[0] = tokenDetail[to][i + 1];
                break;
            }
        }
        return myArray;
    }
    function gainReward (address to, uint gram) external {
        uint rewardPoints = gram/100;
        TotalRewardPoints[to] += rewardPoints;
    }

    function updateTokenId(address _to,uint _tokenId,address _seller,address marketplaceAddress) external {
        tokenDetail[_to][count[_to] + 1].tokenId = _tokenId;
        getTokenInfo[] memory myArray =  getTokenDetail(_seller,marketplaceAddress);
        for(uint i=0 ; i < myArray.length ; i++){
            if(myArray[i].tokenDetail.tokenId == _tokenId){
                tokenDetail[_seller][i+1] = tokenDetail[_seller][count[_seller]];
                count[_seller]--;
            }
        }
        count[_to]++;
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function allTokenURIs() public view returns (Admin[] memory) {
        Admin[] memory myArray = new Admin[](URICount);
        for (uint i = 1; i <= URICount ; i++) 
        {
            myArray[i-1] = URI[i];
        }
        return(myArray);
    }


    function approvedDetail(address marketplaceContractAddress,address to,uint256 tokenId) private view returns (bool,address) {
        bool onList = IConnected(marketplaceContractAddress).nftDetail(to,tokenId);
        return (onList,super.getApproved(tokenId));
    }
}