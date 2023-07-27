// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract LandRental {
    
struct Offer {
    uint id;
    uint landId;
    address payable renter;
    uint rentalPrice;
    uint rentalDuration;
}
struct Land {
    uint id;
    address payable owner;
    Offer activeOffer;
    bool isRented;
    uint rentedUntil;
}
Land[] public lands;
Offer[] public offers;
event RentalOfferSubmitted(uint offerId);
event RentalOfferAccepted(uint offerId, uint landId);
modifier onlyLandOwner(uint _landId) {
require(msg.sender == lands[_landId].owner, "Only the land owner can execute this operation.");
_;
}
function submitRentalOffer(uint _landId, uint _rentalPrice, uint _rentalDuration) public {
require(_landId < lands.length, "Invalid land ID.");
Offer memory newOffer = Offer({
id: offers.length,
landId: _landId,
renter: msg.sender,
rentalPrice: _rentalPrice,
rentalDuration: _rentalDuration
});
offers.push(newOffer);
emit RentalOfferSubmitted(newOffer.id);
}
function acceptRentalOffer(uint _landId, uint _offerId) public onlyLandOwner(_landId) {
Land storage land = lands[_landId];
Offer storage offer = offers[_offerId];
require(offer.landId == _landId, "Offer is not for this land.");
require(land.isRented == false || land.rentedUntil < block.timestamp, "Land is currently rented.");
land.activeOffer = offer;
land.isRented = true;
land.rentedUntil = block.timestamp + offer.rentalDuration;
emit RentalOfferAccepted(_offerId, _landId);
}
function payRentalFees(uint _landId) public payable {
Land storage land = lands[_landId];
require(msg.value >= land.activeOffer.rentalPrice, "Payment not enough.");
// Transfer payment to landowner
land.owner.transfer(msg.value);
}
function isRentable(uint _landId) public view returns (bool) {
Land storage land = lands[_landId];
return !land.isRented || land.rentedUntil < block.timestamp;
}}