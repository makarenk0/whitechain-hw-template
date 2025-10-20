// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ItemNFT721} from "./ItemNFT721.sol";
import {MagicToken} from "./MagicToken.sol";

/**
 * @title Marketplace
 * @notice Contract for trading items in the Cossack Business game.
 * @dev Players can list items for sale and purchase them with Magic tokens.
 */
contract Marketplace is AccessControl {
    ItemNFT721 public items;
    MagicToken public magic;

    // Listing structure
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    // Mapping from tokenId to listing
    mapping(uint256 => Listing) public listings;

    // Events
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemDelisted(uint256 indexed tokenId, address indexed seller);
    event ItemPurchased(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    constructor(address admin, ItemNFT721 _items, MagicToken _magic) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        items = _items;
        magic = _magic;
    }

    /**
     * @dev List an item for sale
     * @param tokenId The ID of the item to list
     * @param price The price in Magic tokens
     */
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Marketplace: Price must be greater than 0");
        require(items.ownerOf(tokenId) == msg.sender, "Marketplace: Not the owner of this item");
        require(!listings[tokenId].active, "Marketplace: Item already listed");

        // Transfer item to marketplace (marketplace becomes the owner)
        items.transferFrom(msg.sender, address(this), tokenId);

        // Create listing
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });

        emit ItemListed(tokenId, msg.sender, price);
    }

    /**
     * @dev Remove an item from sale
     * @param tokenId The ID of the item to delist
     */
    function delist(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.active, "Marketplace: Item not listed");
        require(listing.seller == msg.sender, "Marketplace: Not the seller");

        // Mark listing as inactive
        listing.active = false;

        // Transfer item back to seller
        items.transferFrom(address(this), msg.sender, tokenId);

        emit ItemDelisted(tokenId, msg.sender);
    }

    /**
     * @dev Purchase an item
     * @param tokenId The ID of the item to purchase
     */
    function purchase(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.active, "Marketplace: Item not for sale");
        require(msg.sender != listing.seller, "Marketplace: Cannot buy your own item");

        // Mark listing as inactive
        listing.active = false;

        // Burn the item (as per specification)
        items.burn(tokenId);

        // Mint Magic tokens to the seller
        magic.mint(listing.seller, listing.price);

        emit ItemPurchased(tokenId, msg.sender, listing.seller, listing.price);
    }

    /**
     * @dev Get listing information
     * @param tokenId The ID of the item
     * @return seller The seller's address
     * @return price The price in Magic tokens
     * @return active Whether the listing is active
     */
    function getListing(uint256 tokenId) external view returns (address seller, uint256 price, bool active) {
        Listing memory listing = listings[tokenId];
        return (listing.seller, listing.price, listing.active);
    }
}
