// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title MagicToken
 * @notice ERC20 token for the Cossack Business game economy.
 * @dev Only Marketplace can mint tokens when items are sold. Direct minting is forbidden.
 */
contract MagicToken is ERC20, AccessControl {
    bytes32 public constant MARKET_ROLE = keccak256("MARKET_ROLE"); // assign to Marketplace

    constructor(address admin) ERC20("Magic Token", "MAGIC") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @dev Mint Magic tokens to the specified address
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MARKET_ROLE) {
        _mint(to, amount);
    }
}
