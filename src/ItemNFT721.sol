// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ItemNFT721
 * @notice ERC721 contract for unique crafted items in Cossack Business game.
 * @dev Only CraftingSearch can mint items. Only Marketplace can burn items during sales.
 */
contract ItemNFT721 is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // assign to CraftingSearch
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // assign to Marketplace
    uint256 public nextId = 1;

    /**
     * @notice Item types for crafting recipes
     */
    uint256 public constant SABER = 1;        // Шабля козака
    uint256 public constant STAFF = 2;        // Посох старійшини
    uint256 public constant ARMOR = 3;        // Броня характерника
    uint256 public constant BRACELET = 4;     // Бойовий браслет

    constructor(address admin) ERC721("Cossack Items", "CITEM") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Mint a new item to the specified address
     * @param to The address to mint the item to
     * @param itemType The type of item being crafted
     * @return The token ID of the minted item
     */
    function mintTo(
        address to,
        uint256 itemType
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 id = nextId++;
        _safeMint(to, id);
        return id;
    }

    /**
     * @dev Burn an item (only Marketplace can call this during sales)
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
