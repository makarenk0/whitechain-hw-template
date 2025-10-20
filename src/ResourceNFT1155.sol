// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ResourceNFT1155
 * @notice ERC1155 contract for managing 6 basic resources in Cossack Business game.
 * @dev Only CraftingSearch can mint/burn resources. Direct minting/burning is forbidden.
 */
contract ResourceNFT1155 is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // assign to CraftingSearch
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // assign to CraftingSearch

    /**
     * @notice Resource IDs for the 6 basic resources
     */
    uint256 public constant WOOD = 1;      // Дерево
    uint256 public constant IRON = 2;      // Залізо
    uint256 public constant GOLD = 3;      // Золото
    uint256 public constant LEATHER = 4;   // Шкіра
    uint256 public constant STONE = 5;     // Камінь
    uint256 public constant DIAMOND = 6;   // Алмаз

    constructor(address admin) ERC1155("https://cossack-business.com/api/resource/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @dev Mint batch of resources. Intended to be called only by CraftingSearch.
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, "");
    }

    /// @dev Burn batch of resources. Intended to be called only by CraftingSearch.
    function burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(BURNER_ROLE) {
        _burnBatch(from, ids, amounts);
    }

    /// @inheritdoc ERC1155
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
