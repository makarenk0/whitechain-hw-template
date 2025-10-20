### For deploy used
- Foundry

### Compile
```bash
forge build
```

### Deploy into Whitechain Testnet
```bash
# Dry run
forge script script/Deploy.s.sol \
  --rpc-url $WHITECHAIN_RPC_URL \
  --private-key $PRIVATE_KEY --legacy

# Broadcast
forge script script/Deploy.s.sol \
  --rpc-url $WHITECHAIN_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast -vvv --legacy

## Contract addressess

- **ResourceNFT1155**: `0xf4297f17B8117C8d87A1FA1753B8714D17DC352A`
- **ItemNFT721**: `0x7da3FDE242e4cd1ebe9fE72e2cB9E0E67FB683CB`
- **MagicToken**: `0x94C918A0a988E34C57f62739D191AF8b24297528`
- **CraftingSearch**: `0xfb9261fA13a8A0ef7e496FE9FD642ECafb44EFb8`
- **Marketplace**: `0x65cFD21A33F8147C558Edf4A0C5b30bCf424be04`
- **Admin**: `0xFD8883254085519Aa74F466021c77429a25F14A2`