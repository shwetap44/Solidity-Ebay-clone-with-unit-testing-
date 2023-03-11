// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ebay {

    struct Auction {
        uint autionId;
        address payable seller;
        string name;
        string description;
        uint min;
        uint bestOfferId;
        uint[] offerIds;
    }

    struct Offer {
        uint offerId;
        uint auctionId;
        address payable buyer;
        uint price;
    }

    mapping(uint => Auction) public auctions;
    mapping(uint => Offer) private offers;
    mapping(address => uint[]) private auctionList;
    mapping(address => uint[]) private offerList;

    uint private newAutionId = 1;
    uint private newOfferId = 1;

    function createAuction(string calldata _name, string calldata _description, uint _min) external {

        require(_min > 0, "Minimum must be greater than 0");
        uint[] memory offerIds = new uint[](0);

        auctions[newAutionId] = Auction(newAutionId, payable(msg.sender), _name, _description, _min, 0, offerIds);
        auctionList[msg.sender].push(newAutionId);
        newAutionId++;
    }

    function createOffer(uint _auctionId) external payable auctionExists(_auctionId){

        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(msg.value >= auction.min && msg.value > bestOffer.price, "msg. value must be grater than the minimum and the best offer");
        auction.bestOfferId = newOfferId;
        auction.offerIds.push(newOfferId);

        offers[newOfferId] = Offer(newOfferId, _auctionId, payable(msg.sender), msg.value);
        offerList[msg.sender].push(newOfferId);
        newOfferId++;
    }

    function transaction(uint _auctionId) external auctionExists(_auctionId){

        Auction storage auction = auctions[_auctionId];
        Offer storage bestOffer = offers[auction.bestOfferId];

        for(uint i=0; i<auction.offerIds.length; i++){
            uint offerId = auction.offerIds[i];

            if(offerId != auction.bestOfferId){
                Offer storage offer = offers[offerId];
                offer.buyer.transfer(offer.price); // contract -> another participant with no best offer
            }
        }
        auction.seller.transfer(bestOffer.price); // contract -> seller account
    }

    function getAuctions() external view returns(Auction[] memory){

        Auction[] memory _auctions = new Auction[](newAutionId-1);

        for(uint i=1; i<newAutionId; i++){
            _auctions[i-1] = auctions[i];
        }
        return _auctions;
    }

    function getUserAuctions(address _user) external view returns(Auction[] memory) {
        uint[] storage userAuctionsIds = auctionList[_user];
        Auction[] memory userAuctions = new Auction[](userAuctionsIds.length);

        for(uint i=0; i < userAuctionsIds.length; i++) {
            userAuctions[i] = auctions[userAuctionsIds[i]];
        }
        return userAuctions;
    }

    function getUserOffers(address _user) external view returns(Offer[] memory) {
        uint[] memory _userOfferIds = offerList[_user];
        Offer[] memory _offers = new Offer[](_userOfferIds.length);

        for(uint i=0; i < _userOfferIds.length; i++) {
            _offers[i] = offers[_userOfferIds[i]];
        }
        return _offers;
    }

    modifier auctionExists(uint _auctionId){
        require(_auctionId > 0 && _auctionId < newAutionId, "Auction does not exists ");
        _;
    }
}