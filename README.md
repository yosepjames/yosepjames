# Roblox Game Fundamental

A clean, production-ready Roblox game template covering all the fundamentals.

## Features

| Area | What's included |
|---|---|
| **Game loop** | Lobby → Starting → Round → Intermission → repeat |
| **Player data** | DataStore persistence with safe pcall wrapping and server-close saving |
| **Networking** | Typed RemoteEvents & RemoteFunctions set up before any script runs |
| **HUD** | Timer, state banner, coin counter, tween-out notifications |
| **Configuration** | Single `GameConfig` module adjusts timing, speeds, and rewards |
| **Utilities** | Lightweight `Signal` module for decoupled internal events |

## Project layout

```
src/
├── ServerScriptService/
│   ├── RemoteSetup.server.lua    — creates all Remotes before other scripts run
│   ├── DataManager.server.lua    — DataStore load/save, coin adjustments
│   └── RoundManager.server.lua   — full game-loop state machine
│
├── StarterPlayer/StarterPlayerScripts/
│   └── PlayerController.client.lua — applies character stats, caches player data
│
├── StarterGui/MainGui/
│   └── UIController.client.lua   — HUD (timer, banner, coins, notifications)
│
└── ReplicatedStorage/
    ├── GameConfig.lua             — shared constants (durations, speeds, rewards)
    └── Modules/
        ├── GameState.lua          — enum for game phases
        └── Signal.lua             — bindable-free event utility
```

## Setup (Rojo)

1. Install [Rojo](https://rojo.space/) and the Roblox Studio plugin.
2. `rojo serve` in this directory.
3. Click **Connect** in Studio.

All files sync automatically via `default.project.json`.

## Customising

- **Map spawns** – replace the placeholder `CFrame.new(...)` values in `RoundManager` with actual `SpawnLocation` parts from your map.
- **Win condition** – the default is last-player-standing; swap the `#alivePlayers == 1` check for any other condition.
- **More game states** – add entries to `GameState.lua` and handle them in `RoundManager` and `UIController`.
- **Tools / abilities** – give players a `Tool` in `StarterPack` or via server script when `IN_ROUND` fires.
