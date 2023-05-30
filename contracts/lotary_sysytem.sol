// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LotterySystem is ERC721, Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter public  ticketId;

    address public TheWinnerIs;
    uint256 public winner_user_index;

    uint256 public TicketPrice=100;
    uint256 public PrizeAmount;

    uint256 public counter;

    mapping (uint256 => address) public LotteryNumber;
    mapping (address => uint256) public TicketId;

    constructor() ERC721("LotteryTicket", "LTS") {}

    function UserBuyTicket(address to) public payable nonReentrant {
        ticketId.increment();
        LotteryNumber[counter] = to;
        TicketId[to] = ticketId.current();
        _safeMint(to, ticketId.current());
        PrizeAmount += 100;
        payable(owner()).transfer(TicketPrice);//100 wei transfer to owner wallet
        counter += 1;
    }

    function winner() public payable onlyOwner nonReentrant {

        require(counter > 4,"Minimun 5 User Participate");

        winner_user_index = (uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, counter)))) % counter;

        TheWinnerIs = LotteryNumber[winner_user_index];
        
        payable(TheWinnerIs).transfer(PrizeAmount);

        PrizeAmount = 0;
        counter = 0;
    }
}