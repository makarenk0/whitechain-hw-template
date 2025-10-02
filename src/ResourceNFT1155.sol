// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ResourceNFT1155
 * @notice ERC1155 for base resources: Wood, Iron, Gold, Leather, Stone, Diamond.
 * @dev Direct mint/burn from external users is forbidden. Only authorized contracts
 *      (CraftingSearch) can mint (search rewards) and burn (craft consumption).
 */
contract ResourceNFT1155 is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // CraftingSearch
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // CraftingSearch

    string public name = "Cossack Resources";
    string public symbol = "CRES";

    // Resource IDs
    uint256 public constant WOOD = 1;
    uint256 public constant IRON = 2;
    uint256 public constant GOLD = 3;
    uint256 public constant LEATHER = 4;
    uint256 public constant STONE = 5;
    uint256 public constant DIAMOND = 6;

    /**
     * @param baseURI Base URI for ERC1155 metadata.
     * @param admin Address that receives DEFAULT_ADMIN_ROLE.
     */
    constructor(string memory baseURI, address admin) ERC1155(baseURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @notice Mint a batch of resources to `to`.
     * @dev Only CraftingSearch should hold MINTER_ROLE.
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, "");
    }

    /**
     * @notice Burn a batch of resources from `from`.
     * @dev Only CraftingSearch should hold BURNER_ROLE.
     */
    function burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(BURNER_ROLE) {
        _burnBatch(from, ids, amounts);
    }
}
