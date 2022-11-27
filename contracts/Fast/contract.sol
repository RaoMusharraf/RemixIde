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

    struct Tender {
        string name;
        uint quantity;
        uint budget;
        uint time;
        uint start;
        string description;
        address Owner;
    }
    // mapping(address => mapping(uint => Tender)) public Requester;
    mapping (address => uint) public Size;
    mapping(uint => Tender ) public Total;
    constructor(){
    }
    function tender(string memory _name,uint _quantity,uint _budget,uint _time,string memory _description) public {
        TotalTender.increment();
        //Requester[msg.sender][TotalTender.current()] = Tender(_name,_quantity,_budget,_time,block.timestamp,_description);
        Size[msg.sender] += 1; 
        Total[TotalTender.current()] = Tender(_name,_quantity,_budget,_time,block.timestamp,_description,msg.sender);
    }
    function getTender(address _to) public view returns (Tender[] memory)  {
        Tender[] memory memoryArray = new Tender[](Size[_to]);
        uint counter=0;
        for(uint i = 1; i <= TotalTender.current(); i++) {
            if(_to == Total[i].Owner){
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
}