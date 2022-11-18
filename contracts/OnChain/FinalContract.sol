// SPDX-License-Identifier: MIT
// Creator: Octaloop
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IIERC20.sol";

contract EncodeGenerate {
    function encode(bytes memory data) public pure returns (string memory) {}

    function GetImageUrl(string memory deposited, string memory MaturityTime, string memory Persentage, string memory ERC20ContractAddress, string memory NFTContractAddress, string memory ContractName, string memory ContractSymbol, string memory TotalClaim) public pure returns (string memory) {}

    function GetUrl( string memory deposited, string memory MaturityTime, string memory Persentage, string memory ERC20ContractAddress, string memory NFTContractAddress, string memory ContractName, string memory ContractSymbol, string memory TotalClaim, string memory iUrl) public pure returns (string memory) {}
}


contract ERC20Stakeable is Ownable, ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    using SafeERC20 for IERC20;
    address public owenerERC20;
    address public ERC20Address;
    EncodeGenerate encoder;
    uint public TotalToken;
    struct Staker {
        uint256 deposited;
        uint256 MaturityTime;
        uint256 Persentage;
        address ERC20ContractAddress;
        address NFTContractAddress;
        string ContractName;
        string ContractSymbol;
        uint256 TotalClaim;
        uint256 timestake;
        bool check; 
    }
    struct C_Staker {
        string deposited;
        string MaturityTime;
        string Persentage;
        string ERC20ContractAddress;
        string NFTContractAddress;
        string ContractName;
        string ContractSymbol;
        string TotalClaim;
    }
    mapping (address => Staker) public Details;
    mapping (address => C_Staker) public C_Details;
    mapping (address => uint ) public OwnerTokens;
    mapping (uint => uint) public percentage;
    mapping (address => uint) public TokenId;

    constructor (address _ERC20Address,uint256 percentage3,uint256 percentage6,uint256 percentage1y, address _encoder) ERC721("Octa NFT", "OCTA") {
        ERC20Address = _ERC20Address;
        percentage[1]=percentage3;
        percentage[2]=percentage6;
        percentage[3]=percentage1y;
        owenerERC20 = msg.sender;
        encoder=EncodeGenerate(_encoder);
    }

    function AdminAddToken(uint _amount) public onlyOwner{
        TotalToken += _amount;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,_amount);
    }

    function AdminWithDrawToken(uint amount,address _to) public onlyOwner{
        IERC20(ERC20Address).safeTransfer(_to, amount);
    }
    
    function Utilization() public view returns(uint256) {
        return (IERC20(ERC20Address).balanceOf(address(this)) * 100)/TotalToken;
    }

    function Deposit(uint256 _amount,uint256 MaturityTime) public {
        require(!Details[msg.sender].check,"Please First WithDraw");
        uint Percentage;
        if(MaturityTime == 3){
            Percentage = percentage[1];
        } if(MaturityTime == 6){
            Percentage = percentage[2];
        } if(MaturityTime == 12){
            Percentage = percentage[3];
        }
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) , _amount);
        TotalToken += _amount;
        Details[msg.sender] = Staker(_amount,MaturityTime,Percentage,ERC20Address,address(this),IIERC20(ERC20Address).name(),IIERC20(ERC20Address).symbol(),showReward(_amount,Percentage),block.timestamp,true);
        C_Details[msg.sender] = C_Staker(Strings.toString(_amount),Strings.toString(MaturityTime),Strings.toString(Percentage),Strings.toHexString(uint160(ERC20Address)),Strings.toHexString(uint160(address(this))),IIERC20(ERC20Address).name(),IIERC20(ERC20Address).symbol(),Strings.toString(showReward(_amount,Percentage)));
        string memory iUrl = encoder.GetImageUrl(C_Details[msg.sender].deposited,C_Details[msg.sender].MaturityTime,C_Details[msg.sender].Persentage,C_Details[msg.sender].ERC20ContractAddress,C_Details[msg.sender].NFTContractAddress,C_Details[msg.sender].ContractName,C_Details[msg.sender].ContractSymbol,C_Details[msg.sender].TotalClaim);
        string memory tokenURI = encoder.GetUrl(C_Details[msg.sender].deposited,C_Details[msg.sender].MaturityTime,C_Details[msg.sender].Persentage,C_Details[msg.sender].ERC20ContractAddress,C_Details[msg.sender].NFTContractAddress,C_Details[msg.sender].ContractName,C_Details[msg.sender].ContractSymbol,C_Details[msg.sender].TotalClaim,iUrl);
        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
        _setTokenURI(_tokenIds.current(), tokenURI);
        TokenId[msg.sender] = _tokenIds.current();
    }

    function Withdraw() public {
        require(Details[msg.sender].check,"Please First Stake");
        require(block.timestamp-Details[msg.sender].timestake == 2592000*Details[msg.sender].MaturityTime,"Your Time period is not complete");
        IERC20(ERC20Address).transfer(msg.sender,Details[msg.sender].TotalClaim);
        OwnerTokens[owenerERC20] -= Details[msg.sender].TotalClaim - Details[msg.sender].deposited;
        _burn(TokenId[msg.sender]);
        delete TokenId[msg.sender];
        delete Details[msg.sender];
    }
    
    function showReward(uint256 _Amount,uint256 _Persentage) public pure returns(uint result)
    {
        return (_Amount * _Persentage) / 100 + _Amount;
    }

    function UpdateERC20 ( address _ERC20Address) public onlyOwner{
        ERC20Address = _ERC20Address;
    }

}