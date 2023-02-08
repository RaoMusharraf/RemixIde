// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;
    Counters.Counter public Counter;

    struct Tier {
        address MFGOwner;
        string Company;
        uint size;
        string typ;
        uint model;
        uint MFGdate;
        string MFGaddress;
        string Description;
        uint TIN;
        address buyer;
        bool sold;  
    }
    struct Distribute {
        address MFGOwner;
        address DISOwner;
        uint saleDate;
        uint warranty;
        uint TIN; 
        address buyer;
        bool sold;   
    }
    struct EndUser{
        address DISowner;
        address endUser;
        uint saleDate;
        uint warranty;
        uint warrantyStart;
        uint warrantyEnd;
        uint TIN;
        bool ClaimStatus;
        
    }
    struct Claim{
        address MFGowner;
        address endUser;
        uint claimDate;
        string description;
        uint TIN;  
        bool claim;  
    }

    struct Sign{
        string name;
        string email;
        address _address;
        bool Up;
        bool InOut;
    }
    struct countDetail{
        uint count;
        uint TIN;
    }
    address newOwner;

    mapping (address => mapping(uint=>Tier)) public TierInfo;
    mapping (uint=>Tier) public TotalTire;
    mapping (address => mapping(uint=>Distribute)) public DISTRIBUTORdetail;
    mapping (address => mapping(uint=>EndUser)) public EndUserDetail;
    mapping (address => mapping(uint=>uint))public TINnum;
    mapping (address => mapping(uint=>uint))public DISTINnum;
    mapping (address => mapping(uint=>uint))public ENDTINnum; 
    mapping (address => mapping(uint=>Claim)) public ClaimDetail;
    mapping (address => uint) public ClaimCountEND;
    mapping (address => uint) public ClaimCountMFG;
    mapping (address => Sign) public Signer;
    mapping (address => uint) public count;
    mapping (address => uint) public DIScount;
    mapping (address => uint) public ENDcount;
    constructor() ERC721("MyToken", "MTK") {
        newOwner = msg.sender;
    }

    function SignUp(string memory name,string memory email,address _address) public{
        Signer[_address] = Sign(name,email,_address,true,true);
    }

    function SignIn(address _address) public{
        require(Signer[_address].Up,"Please SignUp First");
        require(!Signer[_address].InOut,"You Already Sign In");
        Signer[_address].InOut = true;
    }

    function SignOut(address _address) public{
        require(Signer[_address].InOut,"You Already Sign Out");
        Signer[_address].InOut = false;
    }

    function safeMint(address to,string memory name,uint size,string memory typ,uint model,uint MFGdate,string memory MFGaddress,string memory description,uint TINnumber) public{
        _tokenIdCounter.increment();
        TierInfo[to][TINnumber] = Tier(to,name,size,typ,model,MFGdate,MFGaddress,description,TINnumber,newOwner,false);
        TotalTire[_tokenIdCounter.current()] = Tier(to,name,size,typ,model,MFGdate,MFGaddress,description,TINnumber,newOwner,false);
        TINnum[to][count[to]] = TINnumber;
        count[to] +=1;
        _safeMint(to,TINnumber);
    }
    function destributor(address to,address DISowner,uint time,uint warranty,uint TIN) public{
        TierInfo[to][TIN].sold = true;
        TierInfo[to][TIN].buyer = DISowner;
        DISTRIBUTORdetail[DISowner][TIN] = Distribute(to,DISowner,time,warranty,TierInfo[to][TIN].TIN,newOwner,false);
        DISTINnum[DISowner][DIScount[DISowner]] = TIN;
        DIScount[DISowner] +=1;
        transferFrom(to, DISowner, TIN);
    }
    function EndUSER(address DISowner,address buyer,uint purchase,uint WarStart,uint WarEnd,uint TIN) public {
        DISTRIBUTORdetail[DISowner][TIN].sold = true;
        DISTRIBUTORdetail[DISowner][TIN].buyer = buyer;
        EndUserDetail[buyer][TIN] = EndUser(DISowner,buyer,purchase,DISTRIBUTORdetail[DISowner][TIN].warranty,WarStart,WarEnd,TIN,false);
        DISTINnum[buyer][ENDcount[buyer]] = TIN;
        ENDcount[buyer] +=1;
        transferFrom(DISowner, buyer, TIN);
    }
    function ClaimTire(address to,uint TIN,uint claimDate,string memory description) public {
        ClaimDetail[to][ClaimCountEND[to]] = Claim(DISTRIBUTORdetail[EndUserDetail[to][TIN].DISowner][TIN].MFGOwner,to,claimDate,description,TIN,true);
        EndUserDetail[to][TIN].ClaimStatus = true;
        ClaimDetail[DISTRIBUTORdetail[EndUserDetail[to][TIN].DISowner][TIN].MFGOwner][ClaimCountMFG[DISTRIBUTORdetail[EndUserDetail[to][TIN].DISowner][TIN].MFGOwner]] = Claim(DISTRIBUTORdetail[EndUserDetail[to][TIN].DISowner][TIN].MFGOwner,to,claimDate,description,TIN,true);
        ClaimCountEND[to] += 1;
        ClaimCountMFG[DISTRIBUTORdetail[EndUserDetail[to][TIN].DISowner][TIN].MFGOwner] += 1;
    }
}