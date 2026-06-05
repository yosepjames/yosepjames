# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Mythic Pets Empire** is a production-ready Roblox pet simulator game written in Lua. It uses [Rojo](https://rojo.space) to sync source files into Roblox Studio.

## Development Workflow

```bash
# Start the Rojo sync server (then connect via the Roblox Studio Rojo plugin)
rojo serve
```

There is no automated test suite. All testing is manual: connect Studio to the Rojo dev server, run the game in Play mode, and exercise gameplay flows directly.

## Architecture

### Server Boot Order

`RemoteSetup.server.lua` **must** run before `Main.server.lua`. It creates the `Remotes` folder and all `RemoteEvent`/`RemoteFunction` instances inside `ReplicatedStorage`. `Main.server.lua` waits for this folder via `WaitForChild("Remotes")` before proceeding.

`Main.server.lua` then requires all eight services, calls `Service.Init(DataService, ...)` with dependency injection, and starts two infinite `task.spawn` loops: the coin-generation tick and the territory-bonus tick.

### Service Layer (Server-Side)

All game logic lives in `src/ServerScriptService/Services/`. Every service is a plain Lua module table with an `Init` function — no OOP classes. `DataService` is the only service passed into others as a dependency; services never `require` each other directly.

| Service | Responsibility |
|---|---|
| `DataService` | DataStore persistence (`MythicPets_v2` key), in-memory session data, `Get`/`Adjust` helpers |
| `PetService` | Egg rolls, shiny logic, fusion (3→1), equip/unequip/sell, coin tick |
| `TerritoryService` | Zone capture (proximity + timer), bonus tick, `TerritoryUpdated` broadcast |
| `EconomyService` | Trading Post: create/cancel/buy listings (5% tax) |
| `RebirthService` | Prestige: cost scaling (`× 1.8` per level), `+25%` coin multiplier |
| `DailySpinService` | 24-hour cooldown wheel, weighted prize selection, luck token grant |
| `QuestService` | 3 random daily quests (UTC midnight reset), advance/claim |
| `BossService` | 30-min spawn cycle, shared damage accumulation, proportional reward payout |

### Client Architecture

Each UI screen has one `*.client.lua` controller in `src/StarterGui/<Screen>/`. Controllers are self-contained: they fire/invoke Remotes and update their own UI. There is no shared client-side state manager — inter-screen coordination happens via the server or by listening to the same RemoteEvents.

`PlayerController.client.lua` handles character stats (WalkSpeed/JumpPower) and continuously polls player position to detect territory zone entry/exit, firing `EnterZone`/`LeaveZone` events to the server.

`PetFollowController.client.lua` listens to `EquippedUpdated` and animates pet visuals (orbit + glow) on the client only.

### Data Model

Each player's session data shape (stored in DataStore and held in memory by `DataService`):

```lua
{
  coins, gems, pets = {}, equipped = {}, rebirth = 0,
  rebirthMultiplier = 1, luckTokens = 0, activeLuckUntil = 0,
  questsToday = {}, lastQuestReset = 0, stats = { eggsOpened, territoriesCaptured, bossesDefeated }
}
```

`DataService` deep-copies defaults and merges saved data over them so new fields added to the schema are automatically populated for existing players.

### Networking Convention

All game-state mutations are **server-authoritative**. Clients fire events or invoke functions on `ReplicatedStorage.Remotes`; the server validates, mutates `DataService` session data, and pushes updates back via `FireClient`. Clients never write state directly.

`RemoteFunction` (invoked with `InvokeServer`) is used when the client needs a return value (e.g., `OpenEgg`, `GetInventory`, `Rebirth`). `RemoteEvent` (fired with `FireServer`) is used for one-way notifications where no response is needed (e.g., `AttackBoss`, `EquipPet`).

## Balance Tuning

All numeric game constants are centralized in `src/ReplicatedStorage/GameConfig.lua`. No other file should contain hardcoded balance values. Key constants:

- `COIN_TICK_INTERVAL` (10 s) — frequency of passive coin generation
- `SHINY_BASE_CHANCE` (1-in-100) / `SHINY_LUCK_CHANCE` (1-in-20) — shiny pet roll odds
- `REBIRTH_BASE_COST` / `REBIRTH_COST_SCALE` — prestige cost curve
- `TERRITORY_TICK_INTERVAL`, `BOSS_DAMAGE_TICK`, `DAILY_SPIN_COOLDOWN`
- `RARITY_SELL_VALUES`, `RARITY_ORDER` — shared by multiple services

## Rojo Project Structure

`default.project.json` maps every `src/` Lua file to its Roblox class tree location. When adding a new script:
- `*.server.lua` → `Script` in `ServerScriptService`
- `*.client.lua` → `LocalScript` in `StarterPlayerScripts` or `StarterGui`
- Plain `*.lua` → `ModuleScript` in `ReplicatedStorage/Modules` or `ServerScriptService/Services`

## Studio Setup Requirements

Before the game is playable in Roblox Studio, the following manual steps are required (code cannot fulfill these):

- Place `Part` objects named `Territory_meadow_isle`, `Territory_crystal_caverns`, `Territory_volcano_peak` in Workspace at coordinates defined in `TerritoryData.lua`
- Add gem-bundle Developer Products via Creator Dashboard and wire `MarketplaceService.ProcessReceipt` → `DataService.AdjustGems`
- Enable `DataStoreService` in Game Settings → Security
- Replace placeholder pet ball Parts with real pet models from the toolbox
