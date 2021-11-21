// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Market is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private itemsCounter;
    Counters.Counter private itemsSold;

    address payable private  owner;

    uint256 private listingFee = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 tokenId;
        uint256 itenId;
        address nftContract;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event OnMarketItemCreated (
        uint256 indexed tokenId,
        uint256 indexed itemId,
        address indexed nftContract,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingFee() public view returns(uint256) {
        return listingFee;
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(
            price > 0, 
            "Free items aren't allowed"
            ); // prevent free items
        require(
            msg.value == listingFee, 
            string(abi.encodePacked("The listing fee is: ", listingFee)
            )); // ensure listing fee payment

        itemsCounter.increment();

        uint256 itemId = itemsCounter.current();
        
        idToMarketItem[itemId] = MarketItem(
            tokenId, 
            itemId,
            nftContract,
            payable(msg.sender), // seller (creator) address
            payable(address(0)), // owner (handler) address
            price,
            false // sold?
        );
    }

    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        
        require(
            msg.value == price, 
            string(abi.encodePacked("The required price to complete the purchase is: ", price)
            )); // ensure market price payment

        // The sale operation is broken down into 
        //  reentrance-safe steps that ensure no
        //  there are no exploitation gaps
        // ------------------------------- 
        // 1 - Execute sale operation
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        // 2 - Execute sale profit
        idToMarketItem[itemId].seller.transfer(msg.value);
        // 3 - Actually transfer the purchase
        ERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        
        itemsSold.increment();
        // Pay market sales commision
        payable(owner).transfer(listingFee);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 currentTotal = itemsCounter.current();
        uint256 unsoldCount = currentTotal - itemsSold.current();

        MarketItem[] memory items = new MarketItem[](unsoldCount);
        for (uint i = 1; i <= currentTotal; i++) {
            if (!idToMarketItem[i].sold) {
                items[unsoldCount - 1] = idToMarketItem[i];
                unsoldCount -= 1;
            }
        }
        
        return items;
    }

    function fetchMarketPurchases() public view returns(MarketItem[] memory) {
       uint256 currentTotal = itemsCounter.current(); 
       uint256 soldCount = itemsSold.current();
       
       MarketItem[] memory items = new MarketItem[](soldCount);
       for(uint i = 1; i <= currentTotal; i++) {
           if (idToMarketItem[i].owner == msg.sender) {
               items[soldCount - 1] = idToMarketItem[i];
               soldCount -= 1;
           }
       }

       return items;
    }
}