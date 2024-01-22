// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ThreeDot is Ownable {
    struct Private{
        address erc20;
        uint totalHolding;
        uint Price;
        uint privateValue;
    }    
    struct Seed{
        address erc20;
        uint totalHolding;
        uint Price;
        uint seedValue;
    } 
    address public erc20;
    uint public seedValue;
    uint public PrivateValue;
    bool public isClaimActive;
    mapping (address => Private) public _private;
    mapping (address => Seed) public _seed;  
    /** 
        Default Constructor With Initial Supply Arguments
    **/
    constructor(address initialOwner, address _ERC20,uint _seedValue,uint _PrivateValue) Ownable(initialOwner) {
        
        erc20 = _ERC20;
        seedValue = _seedValue;
        PrivateValue = _PrivateValue;
    }
    function addSeed(address _Holder, uint _amount ) public onlyOwner{
        uint tokenHolding = _amount/seedValue;
        _seed[_Holder] = Seed(erc20,tokenHolding,_amount,seedValue);
    }
    function addPrivate(address _Holder, uint _amount ) public onlyOwner{
        uint tokenHolding = _amount/PrivateValue;
        _private[_Holder] = Private(erc20,tokenHolding,_amount,PrivateValue);
    }
    function getSeed(address _Holder) public view returns (Seed[] memory){
        Seed[] memory ret = new Seed[](1);
        ret[0] = _seed[_Holder];
        return ret;
    }
    function getPrivate(address _Holder) public view returns (Private[] memory){
        Private[] memory ret = new Private[](1);
        ret[0] = _private[_Holder];
        return ret;
    }
    function getSeedandPrivate(address _Holder) public view returns (Seed[] memory,Private[] memory){
        Seed[] memory seed = new Seed[](1);
        Private[] memory pri = new Private[](1);
        seed[0] = _seed[_Holder];
        pri[0] = _private[_Holder];
        return (seed,pri);
    }
    function claim() public {
        isClaimActive = !isClaimActive;
    }
    function setErc20Adddress(address _ERC20,uint _seedValue,uint _PrivateValue) public onlyOwner{
        erc20 = _ERC20;
        seedValue = _seedValue;
        PrivateValue = _PrivateValue;
    }
}