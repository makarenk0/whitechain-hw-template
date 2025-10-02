// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ItemNFT721} from "./ItemNFT721.sol";
import {MagicToken} from "./MagicToken.sol";

/**
 * @title Marketplace
 * @notice Sells ERC721 items for MagicToken. Upon purchase:
 *         - the item is BURNED (only legal burn path for items),
 *         - seller receives freshly minted MagicToken (only legal mint path).
 * @dev According to the spec, MagicToken is minted exclusively on sale; there is no
 *      direct user mint. Buyer does not pay MAGIC from balance — MAGIC is newly minted.
 */
contract Marketplace is AccessControl {
    struct Listing {
        address seller;
        uint256 price; // price denominated in MAGIC (tokens to mint to seller)
        bool exists;
    }

    ItemNFT721 public items;
    MagicToken public magic;

    mapping(uint256 => Listing) public listings; // tokenId => listing

    event Listed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event Delisted(uint256 indexed tokenId);
    event Purchased(
        uint256 indexed tokenId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );

    constructor(address admin, ItemNFT721 _items, MagicToken _magic) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        items = _items;
        magic = _magic;
    }

    /**
     * @notice List an owned item for sale at `price` MAGIC (to be minted to seller on purchase).
     */
    function list(uint256 tokenId, uint256 price) external {
        require(items.ownerOf(tokenId) == msg.sender, "not owner");
        require(price > 0, "price=0");

        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            exists: true
        });
        emit Listed(tokenId, msg.sender, price);
    }

    /**
     * @notice Remove a listing. Only the original seller can delist.
     */
    function delist(uint256 tokenId) external {
        Listing memory l = listings[tokenId];
        require(l.exists, "no listing");
        require(l.seller == msg.sender, "not seller");
        delete listings[tokenId];
        emit Delisted(tokenId);
    }

    /**
     * @notice Purchase the listed item. The NFT is burned; seller receives freshly minted MAGIC.
     * @dev We re-check item ownership to ensure it wasn't transferred after listing.
     */
    function purchase(uint256 tokenId) external {
        Listing memory l = listings[tokenId];
        require(l.exists, "no listing");
        require(items.ownerOf(tokenId) == l.seller, "owner changed");

        // Burn the item (Marketplace has BURNER_ROLE on ItemNFT721).
        items.burn(tokenId);

        // Mint MAGIC to the seller (Marketplace has MARKET_ROLE on MagicToken).
        magic.mint(l.seller, l.price);

        delete listings[tokenId];
        emit Purchased(tokenId, msg.sender, l.seller, l.price);
    }
}
