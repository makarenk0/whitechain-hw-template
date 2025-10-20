// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {ResourceNFT1155} from "../src/ResourceNFT1155.sol";
import {ItemNFT721} from "../src/ItemNFT721.sol";
import {MagicToken} from "../src/MagicToken.sol";
import {CraftingSearch} from "../src/CraftingSearch.sol";
import {Marketplace} from "../src/Marketplace.sol";

contract CossackBusinessTest is Test {
    ResourceNFT1155 res;
    ItemNFT721 items;
    MagicToken magic;
    CraftingSearch cs;
    Marketplace mkt;

    address admin = address(0xA11CE);
    address player1 = address(0x1);
    address player2 = address(0x2);

    function setUp() public {
        res = new ResourceNFT1155(admin);
        items = new ItemNFT721(admin);
        magic = new MagicToken(admin);
        cs = new CraftingSearch(admin, res, items);
        mkt = new Marketplace(admin, items, magic);

        // wire roles (mirrors Deploy.s.sol)
        vm.startPrank(admin);
        res.grantRole(res.MINTER_ROLE(), address(cs));
        res.grantRole(res.BURNER_ROLE(), address(cs));
        items.grantRole(items.MINTER_ROLE(), address(cs));
        items.grantRole(items.BURNER_ROLE(), address(mkt));
        magic.grantRole(magic.MARKET_ROLE(), address(mkt));
        vm.stopPrank();
    }

    // ============ DEPLOYMENT TESTS ============

    function test_deployed_and_roles_wired() public {
        // contracts deployed
        assertTrue(address(res) != address(0));
        assertTrue(address(items) != address(0));
        assertTrue(address(magic) != address(0));
        assertTrue(address(cs) != address(0));
        assertTrue(address(mkt) != address(0));

        // core roles wired
        assertTrue(res.hasRole(res.MINTER_ROLE(), address(cs)));
        assertTrue(res.hasRole(res.BURNER_ROLE(), address(cs)));
        assertTrue(items.hasRole(items.MINTER_ROLE(), address(cs)));
        assertTrue(items.hasRole(items.BURNER_ROLE(), address(mkt)));
        assertTrue(magic.hasRole(magic.MARKET_ROLE(), address(mkt)));
    }

    // ============ RESOURCE NFT TESTS ============

    function test_resource_constants() public {
        assertEq(res.WOOD(), 1);
        assertEq(res.IRON(), 2);
        assertEq(res.GOLD(), 3);
        assertEq(res.LEATHER(), 4);
        assertEq(res.STONE(), 5);
        assertEq(res.DIAMOND(), 6);
    }

    function test_resource_mint_batch() public {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = res.WOOD();
        ids[1] = res.IRON();
        amounts[0] = 5;
        amounts[1] = 3;

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        assertEq(res.balanceOf(player1, res.WOOD()), 5);
        assertEq(res.balanceOf(player1, res.IRON()), 3);
    }

    function test_resource_burn_batch() public {
        // First mint some resources
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = res.WOOD();
        ids[1] = res.IRON();
        amounts[0] = 5;
        amounts[1] = 3;

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        // Then burn some
        uint256[] memory burnIds = new uint256[](2);
        uint256[] memory burnAmounts = new uint256[](2);
        burnIds[0] = res.WOOD();
        burnIds[1] = res.IRON();
        burnAmounts[0] = 2;
        burnAmounts[1] = 1;

        vm.prank(address(cs));
        res.burnBatch(player1, burnIds, burnAmounts);

        assertEq(res.balanceOf(player1, res.WOOD()), 3);
        assertEq(res.balanceOf(player1, res.IRON()), 2);
    }

    function test_resource_only_minter_can_mint() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = res.WOOD();
        amounts[0] = 1;

        vm.expectRevert();
        vm.prank(player1);
        res.mintBatch(player1, ids, amounts);
    }

    function test_resource_only_burner_can_burn() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = res.WOOD();
        amounts[0] = 1;

        vm.expectRevert();
        vm.prank(player1);
        res.burnBatch(player1, ids, amounts);
    }

    // ============ ITEM NFT TESTS ============

    function test_item_constants() public {
        assertEq(items.SABER(), 1);
        assertEq(items.STAFF(), 2);
        assertEq(items.ARMOR(), 3);
        assertEq(items.BRACELET(), 4);
    }

    function test_item_mint() public {
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        assertEq(tokenId, 1);
        assertEq(items.ownerOf(tokenId), player1);
        assertEq(items.nextId(), 2);
    }

    function test_item_burn() public {
        // First mint an item
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Then burn it
        vm.prank(address(mkt));
        items.burn(tokenId);

        vm.expectRevert();
        items.ownerOf(tokenId);
    }

    function test_item_only_minter_can_mint() public {
        vm.expectRevert();
        vm.prank(player1);
        items.mintTo(player1, 1); // SABER
    }

    function test_item_only_burner_can_burn() public {
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        vm.expectRevert();
        vm.prank(player1);
        items.burn(tokenId);
    }

    // ============ MAGIC TOKEN TESTS ============

    function test_magic_mint() public {
        vm.prank(address(mkt));
        magic.mint(player1, 1000);

        assertEq(magic.balanceOf(player1), 1000);
    }

    function test_magic_only_market_can_mint() public {
        vm.expectRevert();
        vm.prank(player1);
        magic.mint(player1, 1000);
    }

    // ============ CRAFTING SEARCH TESTS ============

    function test_search_cooldown() public {
        // Reset the search time for this test
        vm.warp(block.timestamp + 1000); // Move far into the future
        
        // First search should work
        vm.prank(player1);
        cs.search();

        // Second search immediately should fail
        vm.expectRevert("CraftingSearch: Search cooldown not expired");
        vm.prank(player1);
        cs.search();

        // After 60 seconds should work
        vm.warp(block.timestamp + 61); // Add 1 extra second
        vm.prank(player1);
        cs.search();
    }

    function test_search_generates_3_resources() public {
        // Skip cooldown for this test
        vm.warp(block.timestamp + 61);
        vm.prank(player1);
        cs.search();

        // Check that player has exactly 3 resources
        uint256 totalResources = 0;
        for (uint256 i = 1; i <= 6; i++) {
            totalResources += res.balanceOf(player1, i);
        }
        assertEq(totalResources, 3);
    }

    function test_craft_saber() public {
        // Give player required resources
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        ids[0] = res.IRON();
        ids[1] = res.WOOD();
        ids[2] = res.LEATHER();
        amounts[0] = 3;
        amounts[1] = 1;
        amounts[2] = 1;

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        // Craft the saber
        vm.prank(player1);
        cs.craft(1); // SABER

        // Check that resources were burned
        assertEq(res.balanceOf(player1, res.IRON()), 0);
        assertEq(res.balanceOf(player1, res.WOOD()), 0);
        assertEq(res.balanceOf(player1, res.LEATHER()), 0);

        // Check that item was minted
        assertEq(items.ownerOf(1), player1);
    }

    function test_craft_staff() public {
        // Give player required resources
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        ids[0] = res.WOOD();
        ids[1] = res.GOLD();
        ids[2] = res.DIAMOND();
        amounts[0] = 2;
        amounts[1] = 1;
        amounts[2] = 1;

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        // Craft the staff
        vm.prank(player1);
        cs.craft(2); // STAFF

        // Check that resources were burned
        assertEq(res.balanceOf(player1, res.WOOD()), 0);
        assertEq(res.balanceOf(player1, res.GOLD()), 0);
        assertEq(res.balanceOf(player1, res.DIAMOND()), 0);

        // Check that item was minted
        assertEq(items.ownerOf(1), player1);
    }

    function test_craft_armor() public {
        // Give player required resources
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        ids[0] = res.LEATHER();
        ids[1] = res.IRON();
        ids[2] = res.GOLD();
        amounts[0] = 4;
        amounts[1] = 2;
        amounts[2] = 1;

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        // Craft the armor
        vm.prank(player1);
        cs.craft(3); // ARMOR

        // Check that resources were burned
        assertEq(res.balanceOf(player1, res.LEATHER()), 0);
        assertEq(res.balanceOf(player1, res.IRON()), 0);
        assertEq(res.balanceOf(player1, res.GOLD()), 0);

        // Check that item was minted
        assertEq(items.ownerOf(1), player1);
    }

    function test_craft_bracelet() public {
        // Give player required resources
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        ids[0] = res.IRON();
        ids[1] = res.GOLD();
        ids[2] = res.DIAMOND();
        amounts[0] = 4;
        amounts[1] = 2;
        amounts[2] = 2;

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        // Craft the bracelet
        vm.prank(player1);
        cs.craft(4); // BRACELET

        // Check that resources were burned
        assertEq(res.balanceOf(player1, res.IRON()), 0);
        assertEq(res.balanceOf(player1, res.GOLD()), 0);
        assertEq(res.balanceOf(player1, res.DIAMOND()), 0);

        // Check that item was minted
        assertEq(items.ownerOf(1), player1);
    }

    function test_craft_insufficient_resources() public {
        // Give player insufficient resources
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = res.IRON();
        amounts[0] = 2; // Need 3 for saber

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        // Try to craft saber
        vm.expectRevert("CraftingSearch: Insufficient resources");
        vm.prank(player1);
        cs.craft(1); // SABER
    }

    function test_craft_invalid_item_type() public {
        vm.expectRevert("CraftingSearch: Invalid item type");
        vm.prank(player1);
        cs.craft(5); // Invalid item type
    }

    function test_get_recipe() public {
        (uint256[] memory resourceIds, uint256[] memory amounts) = cs.getRecipe(1); // SABER
        
        assertEq(resourceIds.length, 3);
        assertEq(amounts.length, 3);
        
        // Check that the recipe contains the right resources
        bool foundIron = false;
        bool foundWood = false;
        bool foundLeather = false;
        
        for (uint256 i = 0; i < resourceIds.length; i++) {
            if (resourceIds[i] == res.IRON() && amounts[i] == 3) foundIron = true;
            if (resourceIds[i] == res.WOOD() && amounts[i] == 1) foundWood = true;
            if (resourceIds[i] == res.LEATHER() && amounts[i] == 1) foundLeather = true;
        }
        
        assertTrue(foundIron);
        assertTrue(foundWood);
        assertTrue(foundLeather);
    }

    function test_get_recipe_invalid_item() public {
        vm.expectRevert("CraftingSearch: Invalid item type");
        cs.getRecipe(5);
    }

    // ============ MARKETPLACE TESTS ============

    function test_list_item() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Approve marketplace to transfer the item
        vm.prank(player1);
        items.approve(address(mkt), tokenId);

        // List the item
        vm.prank(player1);
        mkt.list(tokenId, 100);

        // Check that item is now owned by marketplace
        assertEq(items.ownerOf(tokenId), address(mkt));
        
        // Check listing details
        (address seller, uint256 price, bool active) = mkt.getListing(tokenId);
        assertEq(seller, player1);
        assertEq(price, 100);
        assertTrue(active);
    }

    function test_list_item_not_owner() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Try to list from different player
        vm.expectRevert("Marketplace: Not the owner of this item");
        vm.prank(player2);
        mkt.list(tokenId, 100);
    }

    function test_list_item_already_listed() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Approve marketplace
        vm.prank(player1);
        items.approve(address(mkt), tokenId);

        // List the item
        vm.prank(player1);
        mkt.list(tokenId, 100);

        // Try to list again (should fail because item is already listed)
        // But since item is now owned by marketplace, it will fail with "Not the owner"
        vm.expectRevert("Marketplace: Not the owner of this item");
        vm.prank(player1);
        mkt.list(tokenId, 200);
    }

    function test_list_item_zero_price() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Try to list with zero price
        vm.expectRevert("Marketplace: Price must be greater than 0");
        vm.prank(player1);
        mkt.list(tokenId, 0);
    }

    function test_delist_item() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Approve marketplace
        vm.prank(player1);
        items.approve(address(mkt), tokenId);

        // List the item
        vm.prank(player1);
        mkt.list(tokenId, 100);

        // Delist the item
        vm.prank(player1);
        mkt.delist(tokenId);

        // Check that item is back with player1
        assertEq(items.ownerOf(tokenId), player1);
        
        // Check listing is inactive
        (address seller, uint256 price, bool active) = mkt.getListing(tokenId);
        assertEq(seller, player1);
        assertEq(price, 100);
        assertFalse(active);
    }

    function test_delist_item_not_seller() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Approve marketplace
        vm.prank(player1);
        items.approve(address(mkt), tokenId);

        // List the item
        vm.prank(player1);
        mkt.list(tokenId, 100);

        // Try to delist from different player
        vm.expectRevert("Marketplace: Not the seller");
        vm.prank(player2);
        mkt.delist(tokenId);
    }

    function test_delist_item_not_listed() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Try to delist without listing
        vm.expectRevert("Marketplace: Item not listed");
        vm.prank(player1);
        mkt.delist(tokenId);
    }

    function test_purchase_item() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Approve marketplace
        vm.prank(player1);
        items.approve(address(mkt), tokenId);

        // List the item
        vm.prank(player1);
        mkt.list(tokenId, 100);

        // Purchase the item
        vm.prank(player2);
        mkt.purchase(tokenId);

        // Check that item was burned (no longer exists)
        vm.expectRevert();
        items.ownerOf(tokenId);

        // Check that seller received Magic tokens
        assertEq(magic.balanceOf(player1), 100);
    }

    function test_purchase_item_not_for_sale() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Try to purchase without listing
        vm.expectRevert("Marketplace: Item not for sale");
        vm.prank(player2);
        mkt.purchase(tokenId);
    }

    function test_purchase_own_item() public {
        // First mint an item to player1
        vm.prank(address(cs));
        uint256 tokenId = items.mintTo(player1, 1); // SABER

        // Approve marketplace
        vm.prank(player1);
        items.approve(address(mkt), tokenId);

        // List the item
        vm.prank(player1);
        mkt.list(tokenId, 100);

        // Try to purchase own item
        vm.expectRevert("Marketplace: Cannot buy your own item");
        vm.prank(player1);
        mkt.purchase(tokenId);
    }

    // ============ INTEGRATION TESTS ============

    function test_full_game_flow() public {
        // 1. Player searches for resources (skip cooldown)
        vm.warp(block.timestamp + 61);
        vm.prank(player1);
        cs.search();

        // 2. Give player enough resources to craft a saber
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amounts = new uint256[](3);
        ids[0] = res.IRON();
        ids[1] = res.WOOD();
        ids[2] = res.LEATHER();
        amounts[0] = 3;
        amounts[1] = 1;
        amounts[2] = 1;

        vm.prank(address(cs));
        res.mintBatch(player1, ids, amounts);

        // 3. Player crafts a saber
        vm.prank(player1);
        cs.craft(1); // SABER

        uint256 tokenId = 1;
        assertEq(items.ownerOf(tokenId), player1);

        // 4. Approve marketplace and list the item for sale
        vm.prank(player1);
        items.approve(address(mkt), tokenId);
        vm.prank(player1);
        mkt.list(tokenId, 500);

        // 5. Another player purchases the item
        vm.prank(player2);
        mkt.purchase(tokenId);

        // 6. Check that seller received Magic tokens
        assertEq(magic.balanceOf(player1), 500);
        
        // 7. Check that item was burned
        vm.expectRevert();
        items.ownerOf(tokenId);
    }

    function test_multiple_crafts_and_sales() public {
        // Craft multiple items
        for (uint256 i = 0; i < 3; i++) {
            // Give resources
            uint256[] memory ids = new uint256[](3);
            uint256[] memory amounts = new uint256[](3);
            ids[0] = res.IRON();
            ids[1] = res.WOOD();
            ids[2] = res.LEATHER();
            amounts[0] = 3;
            amounts[1] = 1;
            amounts[2] = 1;

            vm.prank(address(cs));
            res.mintBatch(player1, ids, amounts);

            // Craft saber
            vm.prank(player1);
            cs.craft(1); // SABER

            // Approve and list for sale
            vm.prank(player1);
            items.approve(address(mkt), i + 1);
            vm.prank(player1);
            mkt.list(i + 1, 100 * (i + 1));
        }

        // Purchase all items
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(player2);
            mkt.purchase(i + 1);
        }

        // Check total Magic tokens received
        assertEq(magic.balanceOf(player1), 600); // 100 + 200 + 300
    }
}
