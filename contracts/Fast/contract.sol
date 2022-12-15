// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract Storage {
    using Counters for Counters.Counter;
    Counters.Counter public TotalTender;
    Counters.Counter public TotalVender;

    address public Contract;

    struct Vender {
        uint Token;
        uint Price;
        string Description;
        address owner;
        uint DeleveryTime;
    }
    struct Tender {
        uint TokenId;
        string name;
        uint quantity;
        uint budget;
        uint time;
        uint start;
        string _address;
        string description;
        address owner;
    }
    struct Accept{
        uint tokenId;
        address _address;
        bool check;
    }
    struct Comm{
        address receiver;
        uint price;
        bool done;

    }
    struct Rating {
        uint start;
        uint end;
        uint Total;
    }
    mapping (address => uint) public Size;
    mapping (address => mapping(uint => bool)) public Pending;
    mapping (uint => uint) public SizeVender;
    mapping (uint => Tender ) public Total;
    mapping (uint => mapping(uint => Vender )) public Venders;
    mapping (address => mapping(uint => bool)) public Ch; 
    mapping (address => uint) public Requests;
    mapping (uint => mapping(address => uint)) public Finder;
    mapping (uint => mapping(address => Comm)) public Communication;
    mapping (address => mapping(uint => mapping(address => bool))) public Invite;
    mapping (address => Rating) public RattingDetails;
    mapping (address => uint) public Ratting;
    
    constructor(){
        Contract = address(this);
    }
    function tender(string memory _name,uint _quantity,uint _budget,uint _time,string memory Address,string memory _description) public {
        TotalTender.increment();
        Size[msg.sender] += 1; 
        Total[TotalTender.current()] = Tender(TotalTender.current(),_name,_quantity,_budget,_time,block.timestamp,Address,_description,msg.sender);
    }
    function getTender(address _to) public view returns (Tender[] memory)  {
        Tender[] memory memoryArray = new Tender[](Size[_to]);
        uint counter=0;
        for(uint i = 1; i <= TotalTender.current(); i++) {
            if(_to == Total[i].owner){
                memoryArray[counter] = Total[i];
                counter++;
            }        
        }
        return memoryArray;
    }
    function AllTender() public view returns (Tender[] memory)  {
        Tender[] memory memoryArray = new Tender[](TotalTender.current());
        uint counter=0;
        for(uint i = 1; i <= TotalTender.current(); i++) {
            memoryArray[counter] = Total[i];
            counter++;    
        }
        return memoryArray;
    }
    function CheckTime(uint _token) public view returns (bool)  {
        if(Total[_token].start + (Total[_token].time*60) <= block.timestamp){
            return false;
        }
        else{
            return true;
        }
    }
    function vender(uint _token,uint _price,string memory _description,uint _deleveryTime) public {
        require(!Ch[msg.sender][_token],"You Already Apply for this Request");
        require(Total[_token].owner != msg.sender,"You are Owner of this Tender");
        TotalVender.increment();
        Ch[msg.sender][_token] = true;
        SizeVender[_token] += 1; 
        Requests[msg.sender] += 1; 
        Finder[_token][msg.sender] = TotalVender.current();
        Venders[TotalVender.current()][_token] = Vender(_token,_price,_description,msg.sender,_deleveryTime);
    }
    function AllVender(uint _token) public view returns (Vender[] memory)  {
        Vender[] memory memoryArray = new Vender[](SizeVender[_token]);
        uint counter=0;
        for(uint i = 1; i <= TotalVender.current(); i++) {
            if(_token == Venders[i][_token].Token){
                memoryArray[counter] = Venders[i][_token];
                counter++;
            }        
        }
        return memoryArray;
    }
    function getVender(address _address) public view returns (Vender[] memory)  {
        Vender[] memory memoryArray = new Vender[](Requests[_address]);
        uint counter=0;
        for(uint i = 1; i <=   TotalTender.current(); i++) {
            for(uint j = 1; j <= TotalVender.current(); j++){
                if(_address == Venders[j][i].owner){
                    memoryArray[counter] = Venders[j][i];
                    counter++;
                } 
            } 
        }
        return memoryArray;
    }
    function DeleteVRequest(uint _token) public {
        require(Ch[msg.sender][_token],"You canNot Delete");
        Requests[msg.sender] -= 1;
        SizeVender[_token] -= 1; 
        Ch[msg.sender][_token] = false;
        delete Venders[Finder[_token][msg.sender]][_token];
        Finder[_token][msg.sender];
    }
    function UpdateRequest(uint _token,uint _price,string memory _description,uint _deleveryTime) public {
        Venders[Finder[_token][msg.sender]][_token] = Vender(_token,_price,_description,msg.sender,_deleveryTime);
    }
    function AcceptInvitation(uint _token,address _receiver,address _to,uint _price) public {
        Communication[_token][_to] = Comm(_receiver,_price,true);
        
        Pending[_to][_token] = true;
        Invite[_to][_token][_receiver] = true;
    }
    function Done(address _to,address from,uint tokenId) public payable {
        require(Communication[tokenId][from].receiver == _to,"Please Sellect the correct Recepient");
        require(Communication[tokenId][from].done,"You already payment");
        Communication[tokenId][from].done = false;
        payable(_to).transfer(Communication[tokenId][from].price);
    }
    function ratting() public{

    }
    
}
