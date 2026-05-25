# Mythic Pets Empire 🐾

A complete, production-ready Roblox pet simulator with:
- **30 pets** across 6 rarities (Common → Mythic)
- **4 eggs** (Basic, Magic, Legendary, Mythic)
- **Pet fusion** (3 identical → 1 evolved pet)
- **Territory Wars** (3 islands to capture for coin bonuses)
- **Trading Post** (player-driven marketplace with tax)
- **DataStore persistence** (safe save/load with server-close backup)
- **Animated pet followers** (orbit the player with glow effects)

---

## Quick Start (Rojo)

```bash
# Install Rojo CLI: https://rojo.space
rojo serve
# Connect from Roblox Studio plugin
```

---

## File Map

```
src/
├── ServerScriptService/
│   ├── RemoteSetup.server.lua     ← Creates all Remotes first
│   ├── Main.server.lua            ← Entry point, starts ticks
│   └── Services/
│       ├── DataService.lua        ← DataStore, session data, coins/gems
│       ├── PetService.lua         ← Egg opening, fusion, sell, equip
│       ├── TerritoryService.lua   ← Capture logic, bonus ticks
│       └── EconomyService.lua     ← Trading Post buy/sell/cancel
│
├── StarterPlayer/StarterPlayerScripts/
│   ├── PlayerController.client.lua      ← Stats, territory proximity
│   └── PetFollowController.client.lua   ← Orbiting pet visuals
│
├── StarterGui/
│   ├── MainHud/MainHudController.client.lua      ← Coins, gems, slots, toasts
│   ├── EggShop/EggShopController.client.lua      ← Egg shop UI
│   ├── Inventory/InventoryController.client.lua  ← Pets grid, fuse, sell
│   └── TradingPost/TradingController.client.lua  ← Marketplace UI
│
└── ReplicatedStorage/
    ├── GameConfig.lua       ← All tunable constants
    └── Modules/
        ├── PetData.lua      ← 30 pet definitions
        ├── EggData.lua      ← 4 egg definitions + weighted roll
        ├── TerritoryData.lua← 3 territory definitions
        ├── GameState.lua    ← Phase enum
        └── Signal.lua       ← Lightweight event utility
```

---

## Pets (30 total)

| Rarity    | Coins/Min  | Examples                                 |
|-----------|-----------|------------------------------------------|
| Common    | 5–9       | Tabby Cat, Puppy, Cotton Bunny           |
| Uncommon  | 14–24     | Silver Cat, Golden Pup, Arctic Fox       |
| Rare      | 35–55     | Shadow Cat, Baby Phoenix, Thunder Fox    |
| Epic      | 90–130    | Void Cat, Titan Wolf, Storm Dragon       |
| Legendary | 220–350   | Celestial Cat, Nebula Wolf, Eternal Dragon|
| Mythic    | 700–1000  | Cosmic Emperor, Void Sovereign, Mythic Dragon |

**Fusion:** Select 3 identical pets in Inventory → Fuse → get next rarity.

---

## Eggs

| Egg           | Cost        | Best Possible  |
|---------------|-------------|----------------|
| Basic Egg     | 100 coins   | Rare           |
| Magic Egg     | 500 coins   | Epic           |
| Legendary Egg | 2,000 coins | Mythic         |
| Mythic Egg    | 80 gems     | Mythic (high%) |

---

## Territories

| Island         | Bonus  | Capture Time |
|----------------|--------|--------------|
| Meadow Isle    | +10%   | 20 seconds   |
| Crystal Caverns| +25%   | 45 seconds   |
| Volcano Peak   | +50%   | 90 seconds   |

---

## Monetization (Robux)

- **Mythic Egg** costs 80 gems. Gems are the Robux-purchased currency.
- Add a `MarketplaceService:PromptProductPurchase` flow for gem bundles:
  - 10 gems = 25 Robux
  - 50 gems = 99 Robux
  - 200 gems = 349 Robux

---

## Studio Setup Checklist

- [ ] Place 3 `Part` objects in Workspace named `Territory_meadow_isle`,
      `Territory_crystal_caverns`, `Territory_volcano_peak` at the positions
      defined in `TerritoryData.lua`
- [ ] Add spawn locations and a lobby area
- [ ] Replace egg-open animation placeholder with a proper tween in Studio
- [ ] Add gem purchase Developer Products via Creator Dashboard
- [ ] Wire `MarketplaceService.ProcessReceipt` to `DataService.AdjustGems`
- [ ] Replace placeholder pet ball visuals with real Pet Models from the toolbox
- [ ] Set `DataStoreService` enabled in Game Settings → Security

---

## Tuning

All numbers live in `GameConfig.lua`. No other file needs touching for balance:
- `COIN_TICK_INTERVAL` — how often pets generate coins
- `RARITY_SELL_VALUES` — sell prices per rarity
- `TERRITORY_TICK_INTERVAL` — territory bonus frequency
- `MAX_EQUIPPED_PETS` — slots per player
