// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// Importing OpenZeppelin's standard interfaces and utilities for ERC20 tokens and contract ownership management
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A smart contract for Vasting
/// @notice This contract allows the owner to create seeds for token holders and manage their claims
/// @dev Utilizes OpenZeppelin's contracts for ERC20 interactions and ownership management
/// @author 3 Dot Link Team
contract ThreeDot is Ownable {
    // Using the SafeERC20 library for safer ERC20 token interactions
    using SafeERC20 for IERC20;

    // Structure to store information about each RoundType
    struct Round {
        address erc20;         // The ERC20 token address associated with the round
        uint totalHolding;     // Total amount of tokens held in the round
        uint claimTokens;      // User can claim these tokens 
        uint usdAmount;        // The price associated with the round (not actively used in the contract)
        uint tokenPrice;       // tokenPrice of each round
        uint withdrawTime;     // The last time the holder made a withdrawal
        bool isActive;         // Boolean to indicate whether Holder is currently active
    }
    // Structure to store information about Rounds
    struct RoundDetail {
       uint startDate;        // Start date of the round
        uint endDate;          // End date of the round
        uint TotalDays;        // Total days of the round duration
        bool isClaimActive;    // Indicates whether claim feature is active for the round
    }
    // Structure to store information about Claiming Tokens during TGE
    struct TGE{
        uint claimTokens;       // Tokens available for claim 95% of total Holding during Token Generation Event (TGE) 
        uint TGE;               // Token Generation Event(TGE) HOLD 5% Tokens
    }

    // State variables
    address public erc20;        // The address of the ERC20(3DOT) token used in this contract
    uint public seedValue;       // Value assigned to each seed round
    uint public privateValue;    // Value assigned to each private round


    /// Maps RoundType and round number to holder's round information
    mapping (uint => mapping(uint =>  mapping (address =>  Round))) public Rounds;
    /// Maps round number to its details
    mapping (uint => RoundDetail) public roundDetail;
    /// Maps round number and type to its TGE details
    mapping (uint => mapping(uint => TGE)) public initialTokens;

    /// @notice Constructor to set initial values for the contract
    /// @param initialOwner The address of the initial owner of the contract
    /// @param _ERC20 The ERC20 token address associated with the contract
    /// @param _seedValue The initial value assigned to each seed round
    /// @param _privateValue The initial value assigned to each private round
    constructor(address initialOwner, address _ERC20, uint _seedValue, uint _privateValue) Ownable(initialOwner) {
        erc20 = _ERC20;
        seedValue = _seedValue;
        privateValue = _privateValue;
    }

    /// @notice Function to add a seedRound to a holder
    /// @dev Can only be called by the contract owner
    /// @param _Holder The address of the holder receiving the seed
    /// @param _amount The amount of tokens associated with the seed
    /// @param _round Owner will add rounds of seed 
    function addSeed(address _Holder, uint _amount,uint _round) public onlyOwner {
        require(!roundDetail[_round].isClaimActive,"Please add in next round!");
        require(_Holder != address(0), "Put valid address!");
        require(_amount > 0, "Amount must be greater than zero!");
        uint tokenHolding = (_amount / seedValue)*1e18; 
        uint claimToken = (tokenHolding*95)/100;
        initialTokens[_round][1] = TGE((initialTokens[_round][1].claimTokens + claimToken),(initialTokens[_round][1].TGE + (tokenHolding - claimToken)));
        IERC20(erc20).transferFrom(msg.sender, address(this),  claimToken);
        Rounds[1][_round][_Holder] = Round(erc20, (Rounds[1][_round][_Holder].totalHolding + (tokenHolding)),(Rounds[1][_round][_Holder].claimTokens + claimToken), (Rounds[1][_round][_Holder].usdAmount + _amount), seedValue, 0,true);
    }
    /// @notice Function to add a priateRound to a holder
    /// @dev Can only be called by the contract owner
    /// @param _Holder The address of the holder receiving the private
    /// @param _amount The amount of tokens associated with the private
    /// @param _round Owner will add rounds of private 
    function addPrivate(address _Holder, uint _amount,uint _round) public onlyOwner {
        require(!roundDetail[_round].isClaimActive,"Please add in next round!");
        require(_Holder != address(0), "Put valid address!");
        require(_amount > 0, "Amount must be greater than zero!");
        uint tokenHolding = (_amount / privateValue)*1e18;
        uint  claimToken = (tokenHolding*95)/100;
        initialTokens[_round][2] = TGE((initialTokens[_round][2].claimTokens+claimToken),(initialTokens[_round][2].TGE + (tokenHolding- claimToken)));
        IERC20(erc20).transferFrom(msg.sender, address(this),  claimToken);
        Rounds[2][_round][_Holder] = Round(erc20,(Rounds[2][_round][_Holder].totalHolding + (tokenHolding)), (Rounds[2][_round][_Holder].claimTokens + claimToken), (Rounds[2][_round][_Holder].usdAmount + _amount), privateValue, 0,true);
    }
    
    /*
        ========== Vesting Rounds ==========
       
        There are two types of rounds in vesting, select any number in roundType
       
        Round Type 
            1.Seed Round  
                Rounds
                1,2,3.... 

            2.Private Round
                Rounds
                1,2,3....
    */

    /// @notice Function to get the seed information of a specific holder
    /// @param _Holder The address of the holder
    /// @return An array containing the seed , private and private2 information of the requested holder
    /// @param _roundType number of the rounds(1 = seed and 2 = private) to get the round Holders details
    function getRound(address _Holder,uint _roundType) public view returns (Round[] memory,Round[] memory) {
        Round[] memory seed = new Round[](1);
        Round[] memory _private = new Round[](1);
        seed[0] = Rounds[1][_roundType][_Holder];
        _private[0] = Rounds[2][_roundType][_Holder];
        return (seed,_private); 
    }
    

    /// @notice Function to activate the claim feature
    /// @dev Can only be called by the contract owner
    /// @param startDate The start date for the claim period
    /// @param endDate The end date for the claim period
    /// @param roundTyp number of the round(1 = seed or 2 = private) to Activate claim
    function claimActive(uint startDate, uint endDate,uint roundTyp) public onlyOwner {
        require(startDate < endDate,"Please put valid time duration!");
        require(!roundDetail[roundTyp].isClaimActive, "Claim is Already Active!");
        uint TotalDays = (endDate - startDate) / 86400;
        roundDetail[roundTyp] = RoundDetail(startDate,endDate,TotalDays,true);
    }

    /// @notice Function for holders to claim their tokens
    /// @dev Claims are based on the duration since the last claim
    /// @param _Holder The address of the holder making the claim
    /// @param roundTyp number of the round(1 = seed or 2 = private) to their claim reward
    /// @param Typ number of the rounds of the selectedType to their claim reward
    function ClaimToken(address _Holder,uint roundTyp,uint Typ) public {
        require(msg.sender == _Holder,"You are not Eligible for claim!");
        require(roundDetail[roundTyp].isClaimActive, "Claim is not Active so far!");
        require(Rounds[Typ][roundTyp][_Holder].isActive , "You are not Registered!");
        uint userClaimTokens;
        uint withdrawSec;
        (userClaimTokens,withdrawSec) = checkClaimReward(_Holder,roundTyp,Typ);
        withdrawSec = withdrawSec / 86400;
        Rounds[Typ][roundTyp][_Holder].withdrawTime += withdrawSec*	86400;
        require(userClaimTokens > 0, "Time is remaining for claim please wait!");
        require(userClaimTokens <= Rounds[Typ][roundTyp][_Holder].claimTokens, "You has Insufficient tokens!");
        IERC20(erc20).safeTransfer(_Holder, userClaimTokens);
    }

    /// @notice Function for holders to check their tokens
    /// @param _Holder The address of the holder checking the claim
    /// @param roundTyp number of the round to check their claim reward
    function checkClaimReward(address _Holder,uint roundTyp,uint Typ) public  view returns(uint userClaimTokens,uint calSec) {
        uint withdrawSec = block.timestamp - (roundDetail[roundTyp].startDate + Rounds[Typ][roundTyp][_Holder].withdrawTime);
        uint DailyClaimTokens = (Rounds[Typ][roundTyp][_Holder].claimTokens) / roundDetail[roundTyp].TotalDays;
        uint userTokens = DailyClaimTokens * (withdrawSec / 86400);
        return (userTokens,withdrawSec);
    }
    /// @notice Function to pause seed roundType
    /// @dev Can only be called by the contract owner
    /// @param _Holder The address of the holder 
    /// @param roundTyp The seed roundtype pause the specific roundtype and inActive the specific round of holder
    function pauseSeed(address _Holder,uint roundTyp) public onlyOwner{
        require(roundDetail[roundTyp].isClaimActive,"Please add in next round!");
        Rounds[1][roundTyp][_Holder].isActive = false;
    }

    /// @notice Function to pause private roundType
    /// @dev Can only be called by the contract owner
    /// @param _Holder The address of the holder 
    /// @param roundTyp The seed roundtype pause the specific roundtype and inActive the specific round of holder
    function pausePrivate(address _Holder,uint roundTyp) public onlyOwner{
        require(roundDetail[roundTyp].isClaimActive,"Please add in next round!");
        Rounds[2][roundTyp][_Holder].isActive = false;
    }

    /// @notice Function to set a new seed value
    /// @dev Can only be called by the contract owner
    /// @param _seedValue The new seed value
    function setSeedPrice(uint _seedValue) public onlyOwner {
        seedValue = _seedValue;
    }

    /// @notice Function to set a new privateValue value
    /// @dev Can only be called by the contract owner
    /// @param _privateValue The new privateValue value
    function setPrivatePrice(uint _privateValue) public onlyOwner {
        privateValue = _privateValue;
    }

    /// @notice Function to set a new ERC20 Address
    /// @dev Can only be called by the contract owner
    /// @param _erc20 The address of the ERC20 token that is being vested in this contract
    function setErc20Address(address _erc20) public onlyOwner {
        erc20 = _erc20 ;
    }

}