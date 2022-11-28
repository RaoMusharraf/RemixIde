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

    struct Vender {
        uint Token;
        uint Price;
        string Description;
        address owner;
    }
    struct Tender {
        uint TokenId;
        string name;
        uint quantity;
        uint budget;
        uint time;
        uint start;
        string description;
        address owner;
    }
    mapping (address => uint) public Size;
    mapping (address => uint) public SizeVender;
    mapping(uint => Tender ) public Total;
    mapping(uint => Vender ) public Venders;
    mapping (address => mapping(uint => bool)) public Ch; 
    
    constructor(){
    }
    function tender(string memory _name,uint _quantity,uint _budget,uint _time,string memory _description) public {
        TotalTender.increment();
        Size[msg.sender] += 1; 
        Total[TotalTender.current()] = Tender(TotalTender.current(),_name,_quantity,_budget,_time,block.timestamp,_description,msg.sender);
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
    function vender(uint _token,uint _price,string memory _description) public {
        require(!Ch[msg.sender][_token],"You Already Apply for this Request");
        Ch[msg.sender][_token] = true;
        SizeVender[msg.sender] += 1; 
        Venders[_token] = Vender(_token,_price,_description,msg.sender);
    }
}
