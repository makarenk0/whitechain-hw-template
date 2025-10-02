// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ItemNFT721
 * @notice ERC721 for crafted unique items (e.g., Cossack Sabre, Elder Staff, etc.).
 * @dev Minting is only allowed for CraftingSearch (MINTER_ROLE).
 *      Burning is only allowed for Marketplace (BURNER_ROLE).
 *      Direct user mint/burn is forbidden.
 */
contract ItemNFT721 is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // CraftingSearch
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // Marketplace

    uint256 public nextId = 1;

    constructor(address admin) ERC721("Cossack Items", "CITEM") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @notice Mint a new item to `to` with tokenURI `tokenURI_`.
     * @dev Only CraftingSearch should have MINTER_ROLE.
     */
    function mintTo(
        address to,
        string calldata tokenURI_
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 id = nextId++;
        _safeMint(to, id);
        _setTokenURI(id, tokenURI_);
        return id;
    }

    /**
     * @notice Burn an item by `tokenId`.
     * @dev Only Marketplace should have BURNER_ROLE. Ownership is checked inside ERC721.
     *      Since Marketplace has the role, it can burn regardless of msg.sender ownership.
     */
    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }
}
