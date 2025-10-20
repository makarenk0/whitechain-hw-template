// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ResourceNFT1155} from "./ResourceNFT1155.sol";
import {ItemNFT721} from "./ItemNFT721.sol";

/**
 * @title CraftingSearch
 * @notice Contract for resource searching and item crafting in Cossack Business game.
 * @dev Handles 60-second cooldown for searches and implements crafting recipes.
 */
contract CraftingSearch is AccessControl {
    ResourceNFT1155 public resources;
    ItemNFT721 public items;

    uint256 public constant SEARCH_COOLDOWN = 60; // 60 seconds cooldown
    uint256 public constant SEARCH_RESOURCES_COUNT = 3; // 3 random resources per search

    // Mapping to track last search time for each player
    mapping(address => uint256) public lastSearchTime;

    // Crafting recipes: itemType => (resourceId => amount)
    mapping(uint256 => mapping(uint256 => uint256)) public recipes;

    // Events
    event ResourcesSearched(address indexed player, uint256[] resourceIds, uint256[] amounts);
    event ItemCrafted(address indexed player, uint256 itemType, uint256 tokenId);

    constructor(address admin, ResourceNFT1155 _resources, ItemNFT721 _items) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        resources = _resources;
        items = _items;
        
        _initializeRecipes();
    }

    /**
     * @dev Initialize crafting recipes for all items
     */
    function _initializeRecipes() internal {
        // Шабля козака (ID: 1): 3× Залізо, 1× Дерево, 1× Шкіра
        recipes[1][2] = 3; // Iron
        recipes[1][1] = 1; // Wood
        recipes[1][4] = 1; // Leather

        // Посох старійшини (ID: 2): 2× Дерево, 1× Золото, 1× Алмаз
        recipes[2][1] = 2; // Wood
        recipes[2][3] = 1; // Gold
        recipes[2][6] = 1; // Diamond

        // Броня характерника (ID: 3): 4× Шкіра, 2× Залізо, 1× Золото
        recipes[3][4] = 4; // Leather
        recipes[3][2] = 2; // Iron
        recipes[3][3] = 1; // Gold

        // Бойовий браслет (ID: 4): 4× Залізо, 2× Золото, 2× Алмаз
        recipes[4][2] = 4; // Iron
        recipes[4][3] = 2; // Gold
        recipes[4][6] = 2; // Diamond
    }

    /**
     * @dev Search for resources with 60-second cooldown
     * @notice Generates 3 random resources and mints them to the caller
     */
    function search() external {
        require(
            block.timestamp >= lastSearchTime[msg.sender] + SEARCH_COOLDOWN,
            "CraftingSearch: Search cooldown not expired"
        );

        lastSearchTime[msg.sender] = block.timestamp;

        // Generate 3 random resources
        uint256[] memory resourceIds = new uint256[](SEARCH_RESOURCES_COUNT);
        uint256[] memory amounts = new uint256[](SEARCH_RESOURCES_COUNT);

        for (uint256 i = 0; i < SEARCH_RESOURCES_COUNT; i++) {
            // Generate random resource ID (1-6)
            uint256 randomResource = (uint256(keccak256(abi.encodePacked(
                block.timestamp, 
                block.difficulty, 
                msg.sender, 
                i
            ))) % 6) + 1;
            
            resourceIds[i] = randomResource;
            amounts[i] = 1; // Always 1 resource per search result
        }

        // Mint resources to the player
        resources.mintBatch(msg.sender, resourceIds, amounts);

        emit ResourcesSearched(msg.sender, resourceIds, amounts);
    }

    /**
     * @dev Craft an item using the required resources
     * @param itemType The type of item to craft (1-4)
     */
    function craft(uint256 itemType) external {
        require(
            itemType >= 1 && itemType <= 4,
            "CraftingSearch: Invalid item type"
        );

        // Check if player has required resources
        uint256[] memory requiredResources = new uint256[](6);
        uint256[] memory requiredAmounts = new uint256[](6);
        uint256 resourceCount = 0;

        // Check all 6 resource types for this recipe
        for (uint256 resourceId = 1; resourceId <= 6; resourceId++) {
            uint256 requiredAmount = recipes[itemType][resourceId];
            if (requiredAmount > 0) {
                require(
                    resources.balanceOf(msg.sender, resourceId) >= requiredAmount,
                    "CraftingSearch: Insufficient resources"
                );
                requiredResources[resourceCount] = resourceId;
                requiredAmounts[resourceCount] = requiredAmount;
                resourceCount++;
            }
        }

        // Create arrays with correct size
        uint256[] memory finalResources = new uint256[](resourceCount);
        uint256[] memory finalAmounts = new uint256[](resourceCount);
        
        for (uint256 i = 0; i < resourceCount; i++) {
            finalResources[i] = requiredResources[i];
            finalAmounts[i] = requiredAmounts[i];
        }

        // Burn required resources
        resources.burnBatch(msg.sender, finalResources, finalAmounts);

        // Mint the crafted item
        uint256 tokenId = items.mintTo(msg.sender, itemType);

        emit ItemCrafted(msg.sender, itemType, tokenId);
    }

    /**
     * @dev Get the recipe for a specific item type
     * @param itemType The item type to get recipe for
     * @return resourceIds Array of resource IDs required
     * @return amounts Array of amounts required for each resource
     */
    function getRecipe(uint256 itemType) external view returns (uint256[] memory resourceIds, uint256[] memory amounts) {
        require(
            itemType >= 1 && itemType <= 4,
            "CraftingSearch: Invalid item type"
        );

        uint256[] memory tempResourceIds = new uint256[](6);
        uint256[] memory tempAmounts = new uint256[](6);
        uint256 count = 0;

        for (uint256 resourceId = 1; resourceId <= 6; resourceId++) {
            uint256 amount = recipes[itemType][resourceId];
            if (amount > 0) {
                tempResourceIds[count] = resourceId;
                tempAmounts[count] = amount;
                count++;
            }
        }

        resourceIds = new uint256[](count);
        amounts = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            resourceIds[i] = tempResourceIds[i];
            amounts[i] = tempAmounts[i];
        }
    }
}
