// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IIERC721 {
    function safeMint(address _to,uint256 tokenID) external ;
}
/**
 * @title MarketPlace
 */
contract Marketplace is ReentrancyGuard , Ownable{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public tokenID;
    Counters.Counter public listedID;
    //Storage Variables
    address NFTContractAddress;


    //Struct
    struct stoneDetail{
        address owner;
        address currentOwner;
        uint tokenID;
        uint capAmount;
        string uri;
        uint points; 
        bool isActive;
    }

    //Mapping
    // mapping (address user=> uint) public totalMintPerUser;
    // mapping (address user=> mapping (uint count => uint tokenID)) public getTokenIds;
    mapping (address user=> mapping(Stones stone=>stoneDetail)) public getUserStoneDetail;
    mapping (uint count => stoneDetail) public listStone;
    mapping (address user=> uint) public totalListed;
    mapping (Stones stones=> uint) public stoneCapAmount;



    //ENUM

    enum Stones{ Perl, Nelam, Yaqut, Firoza }

    //Functions


    constructor(address initialOwner,address nftContractAddress)
        Ownable(initialOwner)
    {
        NFTContractAddress = nftContractAddress;
        stoneCapAmount[Stones.Perl] = 100;
        stoneCapAmount[Stones.Nelam] = 200;
        stoneCapAmount[Stones.Yaqut] = 300;
        stoneCapAmount[Stones.Firoza] = 400;
    }

    function setStonePrices(Stones _name,uint _price) public {
        stoneCapAmount[_name] = _price;
    }

    function mintStone(address _to,string memory _uri, Stones _typ) public {
        require(!getUserStoneDetail[_to][_typ].isActive,"This Stone Is Already Active!");
        IIERC721(NFTContractAddress).safeMint(_to,tokenID.current());
        getUserStoneDetail[_to][_typ] = stoneDetail(_to,_to,tokenID.current(),stoneCapAmount[_typ],_uri,0,true);
        tokenID.increment();
        // getTokenIds[_to][totalMintPerUser[_to]] = tokenID.current();
        // totalMintPerUser[_to]++;
    }
    function list_Stone(address _to,Stones _typ) public {
        require(getUserStoneDetail[_to][_typ].capAmount == getUserStoneDetail[_to][_typ].points,"First Fill Stone Cap!");
        ERC721(NFTContractAddress).transferFrom(_to, address(this), getUserStoneDetail[_to][_typ].tokenID);
        listStone[listedID.current()] = stoneDetail(_to,address(this),getUserStoneDetail[_to][_typ].tokenID,getUserStoneDetail[_to][_typ].capAmount,getUserStoneDetail[_to][_typ].uri,getUserStoneDetail[_to][_typ].points,true);
        listedID.increment();
    }
        function buy_Stone(address _to,Stones _typ) public {
        require(listStone[listedID.current()].isActive,"First Fill Stone Cap!");
        ERC721(NFTContractAddress).transferFrom(_to, address(this), getUserStoneDetail[_to][_typ].tokenID);
        listStone[listedID.current()] = stoneDetail(_to,address(this),getUserStoneDetail[_to][_typ].tokenID,getUserStoneDetail[_to][_typ].capAmount,getUserStoneDetail[_to][_typ].uri,getUserStoneDetail[_to][_typ].points,true);
        listedID.increment();
    }
}