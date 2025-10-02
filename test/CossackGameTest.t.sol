// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ResourceNFT1155.sol";
import "../src/ItemNFT721.sol";
import "../src/MagicToken.sol";
import "../src/CraftingSearch.sol";
import "../src/Marketplace.sol";

/**
 * @title CossackGameTest
 * @notice Integration-style tests for the Whitechain "Cossack Business" assignment.
 */
contract CossackGameTest is Test {
    ResourceNFT1155 resource;
    ItemNFT721 items;
    MagicToken magic;
    CraftingSearch crafting;
    Marketplace market;

    address admin = address(0xABCD);
    address player = address(0xBEEF);
    address buyer = address(0xCAFE);

    function setUp() public {
        vm.startPrank(admin);

        resource = new ResourceNFT1155("ipfs://base/", admin);
        items = new ItemNFT721(admin);
        magic = new MagicToken(admin);
        crafting = new CraftingSearch(admin, resource, items);
        market = new Marketplace(admin, items, magic);

        // role wiring
        resource.grantRole(resource.MINTER_ROLE(), address(crafting));
        resource.grantRole(resource.BURNER_ROLE(), address(crafting));

        items.grantRole(items.MINTER_ROLE(), address(crafting));
        items.grantRole(items.BURNER_ROLE(), address(market));

        magic.grantRole(magic.MARKET_ROLE(), address(market));

        // add recipe for Cossack Sabre (type=1)
        uint256;
        uint256;
        ids[0] = resource.IRON;
        amts[0] = 3;
        ids[1] = resource.WOOD;
        amts[1] = 1;
        ids[2] = resource.LEATHER;
        amts[2] = 1;

        crafting.setRecipe(1, ids, amts, "ipfs://sabre.json");

        vm.stopPrank();

        // give player some ether to avoid gas issues
        vm.deal(player, 10 ether);
        vm.deal(buyer, 10 ether);
    }

    function testSearchAndCraftFlow() public {
        vm.startPrank(player);

        // simulate a search (will mint 3 random resources)
        crafting.search();
        // NOTE: because randomness is pseudo, we can't assert exact ids
        // but we can check balances increased
        assertGt(
            resource.balanceOf(player, 1),
            0,
            "player got some Wood/other"
        );

        vm.warp(block.timestamp + 61); // skip cooldown
        crafting.search();
        assertGt(
            resource.balanceOf(player, 2),
            0,
            "player got some Iron maybe"
        );

        // mint directly some required resources to ensure crafting works
        uint256;
        uint256;
        ids[0] = resource.IRON;
        amts[0] = 3;
        ids[1] = resource.WOOD;
        amts[1] = 1;
        ids[2] = resource.LEATHER;
        amts[2] = 1;
        vm.startPrank(admin);
        resource.mintBatch(player, ids, amts);
        vm.stopPrank();

        // craft sabre
        vm.startPrank(player);
        crafting.craft(1);
        uint256 balance = items.balanceOf(player);
        assertEq(balance, 1, "player owns crafted item");
        vm.stopPrank();
    }

    function testMarketplaceFlow() public {
        // precondition: craft sabre for player
        vm.startPrank(admin);
        uint256;
        uint256;
        ids[0] = resource.IRON;
        amts[0] = 3;
        ids[1] = resource.WOOD;
        amts[1] = 1;
        ids[2] = resource.LEATHER;
        amts[2] = 1;
        resource.mintBatch(player, ids, amts);
        vm.stopPrank();

        vm.startPrank(player);
        crafting.craft(1);
        uint256 tokenId = 1;
        // list on marketplace
        market.list(tokenId, 100 ether);
        vm.stopPrank();

        // buyer purchases
        vm.startPrank(buyer);
        market.purchase(tokenId);
        vm.stopPrank();

        // item should be burned
        assertEq(items.balanceOf(player), 0, "item burned");
        // seller should get MAGIC minted
        assertEq(
            magic.balanceOf(player),
            100 ether,
            "seller received MagicToken"
        );
    }
}
