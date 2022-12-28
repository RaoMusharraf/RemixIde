// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    using Counters for Counters.Counter;
    Counters.Counter public TotalTender;
    Counters.Counter public TotalVender;
    using Strings for uint256;
    address public Contract;

    struct Sign{
        string name;
        string email;
        address _address;
        bool Up;
        bool InOut;
    }

    struct Vender {
        uint256 Token;
        uint256 Price;
        string Description;
        address owner;
        uint256 DeleveryTime;
        uint256 Delivered;
        string rating;
    }

    struct Tender {
        uint256 TokenId;
        string name;
        uint256 quantity;
        uint256 budget;
        uint256 time;
        uint256 start;
        string _address;
        string description;
        address owner;
    }

    struct Accept {
        uint256 tokenId;
        address _address;
        bool check;
    }

    struct Comm {
        address receiver;
        uint256 price;
        bool done;
    }

    struct Days {
        uint256 Delivered;
        uint256 Total;
        uint256 tender;
    }

    mapping(address => uint256) public Size;
    mapping(address => mapping(uint256 => bool)) public Pending;
    mapping(uint256 => uint256) public SizeVender;
    mapping(uint256 => Tender) public Total;
    mapping(uint256 => mapping(uint256 => Vender)) public Venders;
    mapping(address => mapping(uint256 => bool)) public Ch;
    mapping(address => uint256) public Requests;
    mapping(address => Days) public DaysDetails;
    mapping(uint256 => mapping(address => uint256)) public Finder;
    mapping(uint256 => mapping(address => Comm)) public Communication;
    mapping(address => mapping(uint256 => mapping(address => bool))) public Invite;
    mapping(address => mapping(uint256 => uint256)) public RattingDetails;
    mapping(address => uint256) public accceptedReq;
    mapping(address => Sign) public Signer;

    constructor() {
        Contract = address(this);
    }

    function SignUp(string memory name,string memory email,address _address) public{
        Signer[_address] = Sign(name,email,_address,true,false);
    }

    function SignIn(address _address) public{
        require(Signer[_address].Up,"Please SignUp First");
        require(!Signer[_address].InOut,"You Already Sign In");
        Signer[_address].InOut = true;
    }

    function SignOut(address _address) public{
        require(Signer[_address].InOut,"Please You Already Sign Out");
        Signer[_address].InOut = false;
    }

    function tender(string memory _name,uint256 _quantity,uint256 _budget,uint256 _time,string memory Address,string memory _description) public {
        TotalTender.increment();
        Size[msg.sender] += 1;
        Total[TotalTender.current()] = Tender(TotalTender.current(),_name,_quantity,_budget,block.timestamp + (_time * 60),block.timestamp,Address,_description,msg.sender);
    }

    function getTender(address _to) public view returns (Tender[] memory) {
        Tender[] memory memoryArray = new Tender[](Size[_to]);
        uint256 counter = 0;
        for (uint256 i = 1; i <= TotalTender.current(); i++) {
            if (_to == Total[i].owner) {
                memoryArray[counter] = Total[i];
                counter++;
            }
        }
        return memoryArray;
    }

    function AllTender() public view returns (Tender[] memory) {
        Tender[] memory memoryArray = new Tender[](TotalTender.current());
        uint256 counter = 0;
        for (uint256 i = 1; i <= TotalTender.current(); i++) {
            memoryArray[counter] = Total[i];
            counter++;
        }
        return memoryArray;
    }

    function CheckTime(uint256 _token) public view returns (bool) {
        if (Total[_token].time <= block.timestamp) {
            return false;
        } else {
            return true;
        }
    }

    function vender(uint256 _token,uint256 _price,string memory _description,uint256 _delevered) public {
        require(CheckTime(_token), "Time Out");
        require(!Ch[msg.sender][_token], "You Already Apply for this Request");
        require(Total[_token].owner != msg.sender,"You are Owner of this Tender");
        TotalVender.increment();
        Ch[msg.sender][_token] = true;
        SizeVender[_token] += 1;
        Requests[msg.sender] += 1;
        Finder[_token][msg.sender] = TotalVender.current();
        Venders[TotalVender.current()][_token] = Vender(_token,_price,_description,msg.sender,0, _delevered * 60,RatAge(msg.sender));
    }

    function AllVender(uint256 _token) public view returns (Vender[] memory) {
        Vender[] memory memoryArray = new Vender[](SizeVender[_token]);
        uint256 counter = 0;
        for (uint256 i = 1; i <= TotalVender.current(); i++) {
            if (_token == Venders[i][_token].Token) {
                memoryArray[counter] = Venders[i][_token];
                counter++;
            }
        }
        return memoryArray;
    }

    function getVender(address _address) public view returns (Vender[] memory) {
        Vender[] memory memoryArray = new Vender[](Requests[_address]);
        uint256 counter = 0;
        for (uint256 i = 1; i <= TotalTender.current(); i++) {
            for (uint256 j = 1; j <= TotalVender.current(); j++) {
                if (_address == Venders[j][i].owner) {
                    memoryArray[counter] = Venders[j][i];
                    counter++;
                }
            }
        }
        return memoryArray;
    }

    function DeleteVRequest(uint256 _token) public {
        require(Ch[msg.sender][_token], "You canNot Delete");
        Requests[msg.sender] -= 1;
        SizeVender[_token] -= 1;
        Ch[msg.sender][_token] = false;
        delete Venders[Finder[_token][msg.sender]][_token];
        Finder[_token][msg.sender];
    }

    function AcceptInvitation(uint256 _token,address _receiver,address _to,uint256 _price) public {
        Communication[_token][_to] = Comm(_receiver, _price, true);
        RattingDetails[_receiver][_token] = block.timestamp;
        Pending[_to][_token] = true;
        Venders[Finder[_token][_receiver]][_token].DeleveryTime = block.timestamp + (Venders[Finder[_token][_receiver]][_token].Delivered);
        Invite[_to][_token][_receiver] = true;
    }

    function Done(address _to, address from, uint256 tokenId) public payable {
        require(Communication[tokenId][from].receiver == _to,"Please Sellect the correct Recepient");
        require(Communication[tokenId][from].done, "You already payment");
        DaysDetails[_to].Total += Venders[Finder[tokenId][_to]][tokenId].Delivered / 60;
        DaysDetails[_to].Delivered += (block.timestamp - RattingDetails[_to][tokenId]) / 60;
        DaysDetails[_to].tender += 1;
        accceptedReq[_to] += 1;
        Communication[tokenId][from].done = false;
        payable(_to).transfer(Communication[tokenId][from].price);
    }

    function RatAge(address _to) public view returns (string memory result) {
        uint256 factor = 10**1;
        if(DaysDetails[_to].Delivered > 0) {
            uint256 rating = (((DaysDetails[_to].Total * 60) / DaysDetails[_to].Delivered) + ((accceptedReq[_to] * 40) / Requests[_to]));
            uint256 numerator = (rating * 5);
            uint256 quotient = numerator / 100;
            uint256 remainder = ((numerator * factor) / 100) % factor;
            return string(abi.encodePacked(quotient.toString(),".",remainder.toString()));
        }
        else{
            uint256 rating = (20 + Requests[_to]);
            uint256 numerator = (rating * 5);
            uint256 quotient = numerator / 100;
            uint256 remainder = ((numerator * factor) / 100) % factor;
            return string(abi.encodePacked(quotient.toString(),".",remainder.toString()));
        }
    }
}