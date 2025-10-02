// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ResourceNFT1155} from "./ResourceNFT1155.sol";
import {ItemNFT721} from "./ItemNFT721.sol";

/**
 * @title CraftingSearch (Template)
 * @notice Minimal wiring only. No randomness, no recipes. You will implement logic.
 *
 * TODO:
 * - Implement `search()` with a 60s cooldown that mints 3 random resources via ResourceNFT1155.
 * - Define recipe storage and implement `craft()`:
 *   * burn resources in ResourceNFT1155
 *   * mint item in ItemNFT721
 */
contract CraftingSearch is AccessControl {
    ResourceNFT1155 public resources;
    ItemNFT721 public items;

    // Optional constant for your cooldown if you need it later
    uint256 public constant SEARCH_COOLDOWN = 60;

    constructor(address admin, ResourceNFT1155 _resources, ItemNFT721 _items) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        resources = _resources;
        items = _items;
    }

    /// @notice TODO: implement resource search (cooldown + mintBatch on ResourceNFT1155).
    function search() external pure {
        revert("TODO: implement search()");
    }

    /// @notice TODO: implement crafting according to recipes (burnBatch + mintTo).
    function craft(uint256 /*itemType*/) external pure {
        revert("TODO: implement craft()");
    }
}
