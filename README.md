# ⚔️ Whitechain “Cossack Business” — Foundry Template

**Solidity 0.8.24** · **Foundry (forge)** · Minimal template (no metadata)  
**Target:** Whitechain Testnet (deploy + later verify)

This repo is a starter you can extend to complete the **WhiteBIT/NaUKMA assignment**.  
It compiles, deploys, and includes a passing smoke test. You will implement the game logic incrementally.

## 🔰 Assignment Summary

### 🪵 Resources (ERC1155)

- 6 base NFTs: **Wood**, **Iron**, **Gold**, **Leather**, **Stone**, **Diamond**

### 🛡️ Items (ERC721) — Craftable from Resources

| Item               | Recipe                      | Optional |
| ------------------ | --------------------------- | -------- |
| Cossack Sabre      | 3×Iron + 1×Wood + 1×Leather | No       |
| Elder Staff        | 2×Wood + 1×Gold + 1×Diamond | No       |
| Charakternyk Armor | 4×Leather + 2×Iron + 1×Gold | Yes      |
| Battle Bracelet    | 4×Iron + 2×Gold + 2×Diamond | Yes      |

## 🔄 Creation & Destruction Rules

- NFTs (ERC1155 & ERC721) **must not** be minted/burned directly — only via **Crafting/Search** and **Marketplace**
- ERC721 items are **burned only** on **Marketplace purchase**
- **MagicToken (ERC20)** is minted **only** by Marketplace on successful sale

## 🧪 Game Mechanics

### 🔍 Search

- Player can **search** every **60 seconds**
- Receives **3 random resources** (ERC1155)

### 🧰 Craft

- Consumes resources (burns ERC1155)
- Mints item (ERC721 with unique ID)

### 🛒 Marketplace

- Sell items (ERC721) for MagicToken
- On purchase:
  - Item is **burned**
  - Seller receives freshly **minted MagicToken**

## 📦 Deliverables

- Solidity **0.8.24**, deployed & verified on **Whitechain Testnet**
- 100% test coverage
- Deployment via **Foundry** (or Hardhat)
- NatSpec comments
- README with deployed addresses and run instructions
- Submit PR link to **Distedu**

## 🗂 Project Structure

```
.
├── foundry.toml
├── .env.example
├── remappings.txt
├── src/
│   ├── ResourceNFT1155.sol       # ERC1155 resources (roles only)
│   ├── ItemNFT721.sol            # ERC721 items (role-gated mint, add BURNER_ROLE)
│   ├── MagicToken.sol            # ERC20 MAGIC (Marketplace-only mint)
│   ├── CraftingSearch.sol        # implement search() & craft()
│   └── Marketplace.sol           # implement listing/purchase()
├── script/
│   └── Deploy.s.sol              # minimal deploy + role wiring
└── test/
    └── Template.t.sol            # smoke test (passing)
```

---

## 🧩 Implementation Guide

### `CraftingSearch.sol`

- `search()`:
  - Enforce 60s cooldown per `msg.sender`
  - Select 3 random resource IDs `[1..6]`
  - Call `ResourceNFT1155.mintBatch(msg.sender, ids, amounts)`
- `craft(itemType)`:
  - Store recipes (`mapping itemType => (resourceIds, amounts)`)
  - Burn resources via `ResourceNFT1155.burnBatch(...)`
  - Mint item via `ItemNFT721.mintTo(...)`

### `Marketplace.sol`

- Store listings: `tokenId => (seller, price)`
- `list(tokenId, price)`:
  - Require `msg.sender` is owner
  - Require `price > 0`
- `delist(tokenId)`:
  - Only seller can delist
- `purchase(tokenId)`:
  - Validate listing & ownership
  - Burn item
  - Mint `MAGIC` to seller

**Burn Pattern Options:**

1. Add `burn(uint256)` in `ItemNFT721` (role-gated) and grant Marketplace the role
2. Transfer to Marketplace, then burn as owner

> Template hints at **Option #1**

### `ItemNFT721.sol`

Add burn role:

```solidity
bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
    _burn(tokenId);
}
```

Grant `BURNER_ROLE` to Marketplace in deploy script.

### `ResourceNFT1155.sol`

- Uses `MINTER_ROLE` and `BURNER_ROLE`
- Only `CraftingSearch` can mint/burn

### `MagicToken.sol`

- `MARKET_ROLE` exists
- Only `Marketplace` can mint on successful purchase

## ⚙️ Setup Instructions

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone repo
git clone https://github.com/pyaremenko/whitechain-hw-template.git crypto-hw
cd crypto-hw

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2


# Environment
cp .env.example .env
```

`.env.example`

```ini
WHITECHAIN_RPC_URL=https://rpc-testnet.whitechain.io
PRIVATE_KEY=0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
```

## 🛠 Build & Test

```bash
forge clean
forge build -vv
forge test -vv
```

## 🚀 Deploy to Whitechain Testnet

```bash
# Dry run
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $WHITECHAIN_RPC_URL \
  --private-key $PRIVATE_KEY

# Broadcast
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $WHITECHAIN_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast -vvv
```

## ✅ Next Steps

- Implement `search()` and `craft()` in `CraftingSearch.sol`
- Implement `Marketplace` listing and purchase logic
- Add NatSpec comments
- Write full test suite (100% coverage):
  - Cooldown logic
  - Randomness shape
  - ERC1155 mint/burn
  - Recipe validation
  - ERC721 mint/burn
  - Marketplace edge cases
  - Reentrancy checks
- Deploy to Whitechain Testnet
- Verify contracts
- Update README with deployed addresses and run instructions
