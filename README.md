<div align="center">

# Sell Lemon Tycoon Script

**GUI-based automation script for Sell Lemon Tycoon — auto upgrade, one-time purchases, and manual rebirth.**

[![Tech Stack](https://skillicons.dev/icons?i=lua,github,git,vscode&theme=dark&perline=4)](https://skillicons.dev)

![Roblox](https://img.shields.io/badge/Roblox-Executor-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-Script-000080?style=for-the-badge&logo=lua&logoColor=white)
![Obfuscated](https://img.shields.io/badge/Obfuscated-LuaObfuscator-FF6B35?style=for-the-badge)

[Overview](#overview) · [Features](#features) · [Setup](#setup) · [GUI](#gui) · [Game Structure](#game-structure) · [Update Discipline](#update-discipline) · [Security](#security)

</div>

---

## Overview

Sell Lemon Tycoon Script is a Roblox executor GUI script for Game ID `79268393072444`. It provides automated upgrade loops for Lemon Stand and Lemon Dash, one-time purchase management, manual rebirth, and a clean tabbed UI with toggle controls.

The script validates the Game ID before executing — running it on a different game will safely stop. Purchases are tracked in-memory to prevent duplicate buys. Rebirth is strictly manual (click only, no auto).

This repository is the commit target for future updates. Every feature addition or fix must be committed and pushed to `RivaldiDev/Sell-Lemon-Tycoon-Script`. **Only the obfuscated release file is committed — source code stays local.**

## Features

| Area | What it does |
| --- | --- |
| **Game ID check** | Validates `GameId == 79268393072444` on load. Stops execution if wrong game. |
| **Auto Lemon Stand** | Toggle-based auto upgrade loop (1s interval). Supports 1x / 5x / 25x upgrade amount. |
| **Auto Lemon Dash** | Toggle-based auto upgrade loop (1s interval) for Lemon Dash building. |
| **One-time purchases** | All purchase items (Cash Register, Juicer, Cup Stand, Billboard, etc.) are one-time only — tracked in-memory to prevent double-buy. |
| **Manual Rebirth** | Click-to-activate rebirth button. No auto rebirth — intentional design. |
| **Buy All** | Bulk purchase buttons for all Lemon Stand and Lemon Dash items in one click. |
| **Tabbed GUI** | 3 tabs: Stand, Dash, Rebirth. Clean dark theme with yellow accent. |
| **Draggable window** | Main frame is draggable. Right Shift toggles visibility. |
| **Obfuscated release** | Encrypted via LuaObfuscator API (Virtualize + EncryptStrings + ControlFlow + MBA). |

## Setup

### Prerequisites

- Roblox executor with Lua script support (Synapse X, Fluxus, Delta, etc.)
- Game: **Sell Lemon Tycoon** (Game ID `79268393072444`)

### Usage

1. Join **Sell Lemon Tycoon** in Roblox
2. Open your executor
3. Load `sell-lemon-obfuscated.lua`
4. Execute — GUI appears automatically

### Hotkey

| Key | Action |
| --- | --- |
| `Right Shift` | Toggle GUI visibility |

## GUI

### Tab: 🍋 Stand

- **Auto Upgrade Lemon Stand** — toggle on/off, adjustable amount (1/5/25)
- **One-time purchases**: Cash Register, Juicer, Cup Stand, Billboard, Sugar Mixer, Street Fliers, Ice Maker, BOGO Deals

### Tab: 🏎️ Dash

- **Auto Upgrade Lemon Dash** — toggle on/off
- **Lemon Dash Stand** — buy the main building
- **Other**: Dash Manager
- **Structure**: Dash Floor, Dash Walls
- **Decor**: Dash Windows, Dash Roof, Dash Ceiling Lights, Dash Fence, Metal Brace, Dash Ladders, Dash Office, Dash Garage Door 1/2/3
- **Multiplier**: Higher Fees, Company Vehicle, LemonDash Plus, Dash Exterior Sign, Tips, Express Delivery, Mobile App, Special Deals, Rewards Points, Influencer Collabs, Drone Delivery

### Tab: ♻️ Rebirth

- **REBIRTH NOW** — manual click only (red button)
- **Buy ALL Lemon Stand Items** — bulk purchase
- **Buy ALL Lemon Dash Items** — bulk purchase
- **Info panel** — game ID, player name, feature summary

## Game Structure

```
workspace.Tycoon3
├── Remotes
│   └── Rebirth → InvokeServer()
└── Purchases
    ├── Lemon Stand
    │   ├── Lemon Stand / Lemon Stand / Upgrade → InvokeServer(amount)
    │   └── Buttons
    │       ├── Other: Cash Register
    │       └── Multiplier: Juicer, Cup Stand, Billboard,
    │            Sugar Mixer, Street Fliers, Ice Maker, BOGO Deals
    └── LemonDash
        ├── LemonDash / LemonDash / Upgrade → InvokeServer(amount)
        └── Buttons
            ├── LemonDash (stand purchase)
            ├── Other: Dash Manager
            ├── Structure: Dash Floor, Dash Walls
            ├── Decor: Windows, Roof, Ceiling Lights, Fence,
            │         Metal Brace, Ladders, Office, Garage Door 1/2/3
            └── Multiplier: Higher Fees, Company Vehicle, Plus,
                 Exterior Sign, Tips, Express Delivery, Mobile App,
                 Special Deals, Rewards Points, Influencer Collabs,
                 Drone Delivery
```

### Purchase behavior

| Type | Behavior |
| --- | --- |
| **Upgrade** (Lemon Stand, Lemon Dash) | Repeatable — auto loops every 1s |
| **Purchase** (all buttons) | One-time only — tracked in `state.purchasedItems` |
| **Rebirth** | Manual click — no auto |

## Obfuscation

Release file obfuscated via [LuaObfuscator](https://luaobfuscator.com) API:

| Plugin | Setting |
| --- | --- |
| Virtualize | Enabled |
| EncryptStrings | 100% |
| CachedEncryptStrings | 100% |
| ControlFlowFlattenV1AllBlocks | 100% |
| CallRetAssignment | 100% |
| DummyFunctionArgs | 3–8 |
| EncryptFuncDeclaration | Enabled |
| FuncChopper | Enabled |
| JunkifyAllIfStatements | 80% |
| JunkifyBlockToIf | 80% |
| MakeGlobalsLookups | Enabled |
| MixedBooleanArithmetic | Enabled |
| BasicIntegrity | Enabled |

## Update Discipline

Before every commit:

1. Patch `sell-lemon-gui.lua` (source — local only).
2. Re-obfuscate via LuaObfuscator API.
3. Replace `sell-lemon-obfuscated.lua` in repo.
4. Update `CHANGELOG.md` and this README if behavior changes.
5. Commit and push **only the obfuscated file** to `RivaldiDev/Sell-Lemon-Tycoon-Script`.

Source code (`sell-lemon-gui.lua`) is **never committed** — it stays local only.

## Security

- Obfuscated release prevents casual reading of remote paths and logic.
- Game ID check prevents accidental execution on wrong games.
- No external API calls, no data collection, no network requests from the script itself.
- Source code stays local — only encrypted version is pushed to GitHub.

## Project Status

Active. Current baseline includes Lemon Stand auto-upgrade, Lemon Dash auto-upgrade, one-time purchase management, manual rebirth, bulk buy-all, and tabbed GUI.

## Update History

- **2026-06-06** — Initial release. Lemon Stand + Dash auto upgrade, one-time purchases, manual rebirth, tabbed GUI, LuaObfuscator encryption.
