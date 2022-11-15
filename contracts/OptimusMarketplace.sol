// File: contracts/OptimusMarketplace.sol
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Optimus MarketPlace
 */

contract OptimusMarketplace is Ownable {

    using SafeERC20 for IERC20;
    uint256 public offerCount;
    mapping(uint256 => _Offer) public offers;

    IERC721 nftCollection;
    address private paymentToken;
    uint256 public feeRate;
    uint256 public feeDecimal;
    address public feeRecipient;

    struct _Offer {
        uint256 offerId;
        uint256 id;
        address user;
        uint256 price;
        bool fulfilled;
        bool cancelled;
        address _paymentToken;
    }

    event Offer(
        uint256 offerId,
        uint256 id,
        address user,
        uint256 price,
        bool fulfilled,
        bool cancelled,
        address _paymentToken
    );

    event OfferFilled(uint256 offerId, uint256 id, address newOwner);
    event OfferCancelled(uint256 offerId, uint256 id, address owner);
    event feeRateUpdated(uint256 feeDecimal, uint256 feeRate);

    constructor(
        address _nftCollection,address _PaymentToken, uint256 feeDecimal_,
        uint256 feeRate_,
        address feeRecipient_
    ) {
        nftCollection = IERC721(_nftCollection);
        paymentToken=_PaymentToken;
        _updateFeeRate(feeDecimal_, feeRate_);
        feeRecipient = feeRecipient_;
    }

    function makeOffer(uint256[] memory _ids, uint256 _price) public {
        require(_price > 0, "Price must be at least 1 wei");
        uint256 _id;
        for (uint256 i = 0; i < _ids.length; i++) {
            _id = _ids[i];
            nftCollection.transferFrom(msg.sender, address(this), _id);
            offerCount++;
            offers[offerCount] = _Offer(
                offerCount,
                _id,
                msg.sender,
                _price,
                false,
                false,
                paymentToken
            );
            emit Offer(
                offerCount,
                _id,
                msg.sender,
                _price,
                false,
                false,
                paymentToken
            );
        }
    }

    function fillOffer(uint256 _offerId) public payable {

        _Offer storage _offer = offers[_offerId];
        uint256 price = _offer.price;

        require(_offer.offerId == _offerId, "The offer must exist");
        require(
            _offer.user != msg.sender,
            "The owner of the offer cannot fill it"
        );
        require(!_offer.fulfilled, "An offer cannot be fulfilled twice");
        require(!_offer.cancelled, "A cancelled offer cannot be fulfilled");
        
        uint256 _feeAmount = _calculateFee(_offerId);
        if (_feeAmount > 0) {
            IERC20(_offer._paymentToken).safeTransferFrom(
                msg.sender,
                feeRecipient,
                _feeAmount
            );
        }

        IERC20(_offer._paymentToken).safeTransferFrom(
            msg.sender,
            _offer.user,
            price - _feeAmount
        );

        nftCollection.transferFrom(address(this), msg.sender, _offer.id);
        _offer.fulfilled = true;
        emit OfferFilled(_offerId, _offer.id, msg.sender);
    }

     function cancelOffer(uint256 _offerId) public {
        _Offer storage _offer = offers[_offerId];
        require(_offer.offerId == _offerId, "The offer must exist");
        require(
            _offer.user == msg.sender,
            "The offer can only be canceled by the owner"
        );
        require(
            _offer.fulfilled == false,
            "A fulfilled offer cannot be cancelled"
        );
        require(
            _offer.cancelled == false,
            "An offer cannot be cancelled twice"
        );
        nftCollection.transferFrom(address(this), msg.sender, _offer.id);
        _offer.cancelled = true;
        emit OfferCancelled(_offerId, _offer.id, msg.sender);
    }

    function _calculateFee(uint256 _offerId) private view returns (uint256) {
        _Offer storage _offer = offers[_offerId];
        if (feeRate == 0) {
            return 0;
        }
        return (feeRate * _offer.price) / 10**(feeDecimal + 2);
    }

    function _updateFeeRate(uint256 feeDecimal_, uint256 feeRate_) public onlyOwner {
        require(
            feeRate_ < 10**(feeDecimal_ + 2),
            "optimusMarketplace: bad fee rate"
        );
        feeDecimal = feeDecimal_;
        feeRate = feeRate_;
        emit feeRateUpdated(feeDecimal_, feeRate_);
    }

    function getAll() public view returns (_Offer[] memory){
        _Offer[] memory ret = new _Offer[](offerCount);
        for (uint i = 1; i <= offerCount; i++) {
            ret[i-1] = offers[i];
        }
        return ret;
    }
}