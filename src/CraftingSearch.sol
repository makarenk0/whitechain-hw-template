// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ResourceNFT1155} from "./ResourceNFT1155.sol";
import {ItemNFT721} from "./ItemNFT721.sol";

/**
 * @title CraftingSearch
 * @notice Search mechanics (cooldown 60s) and crafting based on recipes.
 * @dev Search mints ERC1155 resources. Craft burns resources and mints ERC721 items.
 *      Pseudo-randomness here is for demo/testnet only (NOT secure for production).
 *
 * Recipes (examples):
 * 1. Cossack Sabre: 3×Iron, 1×Wood, 1×Leather
 * 2. Elder Staff:   2×Wood, 1×Gold, 1×Diamond
 * 3. Charakternyk Armor (optional): 4×Leather, 2×Iron, 1×Gold
 * 4. Battle Bracelet (optional):     4×Iron, 2×Gold, 2×Diamond
 */
contract CraftingSearch is AccessControl {
    ResourceNFT1155 public resources;
    ItemNFT721 public items;

    uint256 public constant SEARCH_COOLDOWN = 60; // seconds
    mapping(address => uint256) public lastSearchAt;

    struct Recipe {
        uint256[] resIds;
        uint256[] amounts;
        string tokenURI; // item metadata URI
        bool exists;
    }

    // itemType => recipe (e.g., 1 sabre, 2 staff, 3 armor, 4 bracelet)
    mapping(uint256 => Recipe) public recipes;

    event Searched(address indexed player, uint256[] ids, uint256[] amounts);
    event Crafted(address indexed player, uint256 itemType, uint256 newItemId);

    constructor(address admin, ResourceNFT1155 _res, ItemNFT721 _items) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        resources = _res;
        items = _items;
    }

    /**
     * @notice Admin sets a crafting recipe for a given `itemType`.
     */
    function setRecipe(
        uint256 itemType,
        uint256[] calldata resIds,
        uint256[] calldata amounts,
        string calldata tokenURI_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            resIds.length == amounts.length && resIds.length > 0,
            "bad recipe"
        );
        recipes[itemType] = Recipe({
            resIds: resIds,
            amounts: amounts,
            tokenURI: tokenURI_,
            exists: true
        });
    }

    /**
     * @notice Search once per 60 seconds. Mints 3 random (demo) resources to the caller.
     * @dev Pseudo-random using block timestamp & sender — DO NOT use in production.
     */
    function search() external {
        require(
            block.timestamp - lastSearchAt[msg.sender] >= SEARCH_COOLDOWN,
            "cooldown"
        );
        lastSearchAt[msg.sender] = block.timestamp;

        uint256;
        uint256;

        for (uint256 i = 0; i < 3; i++) {
            // 1..6 inclusive map to resource IDs
            uint256 roll = (uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, i))
            ) % 6) + 1;
            ids[i] = roll;
            amts[i] = 1;
        }

        resources.mintBatch(msg.sender, ids, amts);
        emit Searched(msg.sender, ids, amts);
    }

    /**
     * @notice Craft an item of type `itemType`. Burns resources and mints a new ERC721 item.
     */
    function craft(uint256 itemType) external {
        Recipe memory r = recipes[itemType];
        require(r.exists, "no recipe");
        resources.burnBatch(msg.sender, r.resIds, r.amounts);
        uint256 newId = items.mintTo(msg.sender, r.tokenURI);
        emit Crafted(msg.sender, itemType, newId);
    }
}
