// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Base64} from "./Base64.sol";

contract ERC20Stakeable is Ownable, ERC721URIStorage{

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    using SafeERC20 for IERC20;
    address public owenerERC20;
    address public ERC20Address;
    uint Month1 = 2592000;
    uint public totalOwnerToken;

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

    mapping (address => Staker) public Details;
    mapping (address => uint) public Reward;
    mapping (address => uint ) public OwnerTokens;
    mapping (uint => uint) public percentage;
    mapping (address => uint) public TokenId;

    /*
    ~~~~~~~~~~~~~~~Constructor function~~~~~~~~~~~~~~~
   1. This function is called when contract is first deployed.
   2. It takes three parameters:
        a. ER721 Token Address (Address of ER721 Token Contract)
        b. Rate Percentage (Percentage value of rate i.e., Interest percentage)
        c. ER720 Token Address (Address of ER720 Token Contract)
    */
    constructor (address _ERC20Address,uint256 percentage3,uint256 percentage6,uint256 percentage1y) ERC721("Octa NFT", "OCTA") {
        ERC20Address = _ERC20Address;
        percentage[1]=percentage3;
        percentage[2]=percentage6;
        percentage[3]=percentage1y;
        owenerERC20 = msg.sender;
    }

    /*
    ~~~~~~~~~~~~~Admin Add Token Function~~~~~~~~~~~~~~~
    1. Owner add tokens into contract with this function
    2. These tokens are used as rewards for staking
    3. Only Owner can call this function
    */
    function AdminAddToken(uint _amount) public onlyOwner{
        require(msg.sender==owenerERC20,"Only Owner can transfer");
        _amount = _amount*1000000000000000000;
        OwnerTokens[msg.sender] +=_amount;
        totalOwnerToken += _amount;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) ,_amount);
    }

    /*
    ~~~~~~~~~~~~~Admin WithDraw Token Function~~~~~~~~~~~~~~~
    1. Admin withdraws his/her desired amount of token from contract.
    2. Only Owner can call this function
    */
    function AdminWithDrawToken(uint amount) public onlyOwner{
        amount = amount*1000000000000000000;
        OwnerTokens[msg.sender] -= amount;
        totalOwnerToken -= amount;
        IERC20(ERC20Address).safeTransfer(msg.sender, amount);
    }
    
    /*
    ~~~~~~~~~~~~~Utilization Function~~~~~~~~~~~~~~~
    1. Owner call this function to check remaining percentage of tokens left in this contract.
    2. Only Owner can call this function
    */
    function Utilization() public view onlyOwner returns(uint256) {
        uint Persentage = (OwnerTokens[msg.sender] * 100)/totalOwnerToken;
        return Persentage;
    }

    /*   ~~~~~~~~~~~~~Deposit Function~~~~~~~~~~~~~~~
    1. This function has one parameter.
    2. This function is used to deposit desired amount of tokens in this contract by user.
    3. If user already deposited some tokens then he/she must has to withdraw all tokens first.
    */
    function Deposit(uint256 _amount,uint256 MaturityTime) public {
        require(!Details[msg.sender].check,"Please First WithDraw");
        _amount = _amount*1000000000000000000;
        uint Percentage;
        if(MaturityTime == 3){
            Percentage = percentage[1];
        }else if(MaturityTime == 6){
            Percentage = percentage[2];
        }else if(MaturityTime == 12){
            Percentage = percentage[3];
        }else{
            return;
        }
        Details[msg.sender] = Staker(_amount,MaturityTime,Percentage,ERC20Address,address(this),name(),symbol(),showReward(_amount,Percentage),block.timestamp,true);
        string memory tokenURI = formatTokenURI(_amount,MaturityTime,Percentage,ERC20Address,address(this),name(),symbol(),showReward(_amount,Percentage));
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        TokenId[msg.sender] = newItemId;
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this) , _amount);

    }

    /*   ~~~~~~~~~~~~~Withdraw Function~~~~~~~~~~~~~~~
    1. This function is used to withdraw tokens.
    2. User will call this function to withdraw all tokens from this contract.
    */
    function Withdraw() public {
        require(Details[msg.sender].check,"Please First Stake");
        require(block.timestamp-Details[msg.sender].timestake == Month1*Details[msg.sender].MaturityTime,"Your Time period is not complete");
        IERC20(ERC20Address).transfer(msg.sender,Details[msg.sender].TotalClaim);
        OwnerTokens[owenerERC20] -= Details[msg.sender].TotalClaim - Details[msg.sender].deposited;
        _burn(TokenId[msg.sender]);
        delete TokenId[msg.sender];
        delete Details[msg.sender];
    }

    /*~~~~~~~~~~~~~showReward Function~~~~~~~~~~~~~~~
    1. This function is show total claim amount
    2. User can call it
    */
    function showReward(uint256 _Amount,uint256 _Persentage) public pure returns(uint result)
    {
        uint RewardEst = (_Amount * _Persentage);
        uint TotalReward = RewardEst / 100;
        result = TotalReward + _Amount;
        return result;
    }

    /*~~~~~~~~~~~~~UpdateERC20 Function~~~~~~~~~~~~~~~
    1. This function is used to update address of ERC20 token address.
    2. Only Owner can call this function.
    */
    function UpdateERC20 ( address _ERC20Address) public onlyOwner{
        ERC20Address = _ERC20Address;
    }

    /*~~~~~~~~~~~~~formatTokenURI Function~~~~~~~~~~~~~~~
    1. This function is used to make an encoded URI of the given Json File.
    */
    function formatTokenURI(uint256 _amount,uint256 _maturity,uint256 _percentage,address _ERC20ContractAddress,address _NFTContractAddress,string memory _ContractName,string memory _ContractSymbol,uint256 _TotalClaim)public pure returns (string memory)
    {
        string memory amt=Strings.toString(_amount);
        string memory mat=Strings.toString(_maturity);
        string memory per=Strings.toString(_percentage);
        string memory tkn=Strings.toHexString(uint160(_ERC20ContractAddress), 20);
        string memory nft=Strings.toHexString(uint160(_NFTContractAddress), 20);
        string memory tot=Strings.toString(_TotalClaim);
        string memory name=_ContractName;
        string memory sym=_ContractSymbol;
        string memory url=string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "My Contract", "description": "This is deposit and withdraw contract", "attributes": [{ "trait_type": "deposited","value": "',amt,'"},{"trait_type": "maturity","value": "',mat,'"},{"trait_type": "percentage","value": "',per,'"},{ "trait_type": "ERC20ContractAddress","value": "',tkn,'"},{"trait_type": "NFTContractAddress","value": "',nft,'"},{"trait_type": "ContractName","value": "',name,'"},{ "trait_type": "ContractSymbol","value": "',sym,'"},{"trait_type": "TotalClaim","value": "',tot,'"}]}'
                            )
                        )
                    )
                )
            );
        return url;
    }
}