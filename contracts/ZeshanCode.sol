// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract OctaERC721 is ERC721Enumerable, Ownable {

    uint256 public constant Max_Mint_Per_Transaction = 5;
    uint256 public constant Max_Supply = 12000;
    uint256 public constant Mint_Price = 100 wei;
    

    uint256 public level1Start;
    uint256 public level2Start;
    uint256 public level2End;
    bool public level1Closed;
    bool public level2Closed;

    constructor() ERC721("Octa ERC721", "OCTA") {
    
    }

    function mint(uint256 number_Of_Tokens) public payable {
        require(totalSupply() < Max_Supply, "All tokens have been minted");
        require(number_Of_Tokens <= Max_Mint_Per_Transaction, "Tokens per transaction over the max limit");
        require(totalSupply() + number_Of_Tokens <= Max_Supply, "Token supply is exceeding the max limit");


        if (totalSupply() >= level1Start && totalSupply() < level2Start) {
            require(!level1Closed, "Level 1 closed");
        } else if (totalSupply() >= level2Start && totalSupply() < level2End) {
            require(!level2Closed, "Level 2 closed");
        }

        for (uint256 i = 0; i < number_Of_Tokens; i++) {
            uint256 tokenId = totalSupply();
            require(tokenId < Max_Supply, "Exceeds maximum token supply");

            _safeMint(msg.sender, tokenId);
        }

        if (totalSupply() == level1Start) {
            level1Closed = true;
        } else if (totalSupply() == level2Start) {
            level2Closed = true;
        }

        uint256 feeAmount = number_Of_Tokens* Mint_Price;
        payable(owner()).transfer(feeAmount);
    }

    function openLevel1(uint256 Start) public onlyOwner {
        require(level1Start == 0, "Level 1 already opened");
        require(Start < Max_Supply, "Invalid level 1 start");
        require(level2Start == 0 || Start < level2Start, "Invalid level 1 start");
        level1Start = Start;
    }

    function closeLevel1() public onlyOwner {
        require(level1Start > 0, "Level 1 not opened");
        level1Closed = true;
    }

    function openLevel2(uint256 Start) public onlyOwner {
        require(level1Closed, "Level 1 not closed");
        require(level2Start == 0, "Level 2 already opened");
        require(Start < Max_Supply, "Invalid level 2 start");
        require(Start > level1Start && Start < Max_Supply, "Invalid level 2 start");
        level2Start = Start;
        level2End = level2Start + 600;
    }

    function closeLevel2() public onlyOwner {
        require(level2Start > 0, "Level 2 not opened");
        level2Closed = true;
    }
}
