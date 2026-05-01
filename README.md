<img src="banner.png">

[![Static Badge](https://img.shields.io/badge/GitHub-Down--s/gRust-black?logo=github)](https://github.com/Down-s/gRust)
[![Static Badge](https://img.shields.io/badge/Steam%20Addon-3636622724-blue?logo=steam)](https://steamcommunity.com/sharedfiles/filedetails/?id=3636622724)
[![Static Badge](https://img.shields.io/badge/Steam%20Map-3636630095-blue?logo=steam)](https://steamcommunity.com/sharedfiles/filedetails/?id=3636630095)

# gRust - Rust in Garry's Mod

A complete Garry's Mod gamemode that recreates the Rust survival experience.

## Requirements

To run this gamemode, you need:
- **ULib** - User administration library
- **ULX** - Administration mod for ULib

Both are required for the permission system and admin commands to function properly.

## Installation

1. Download the gamemode from the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3636622724)
2. Subscribe to the recommended map: [rust_highland](https://steamcommunity.com/sharedfiles/filedetails/?id=3636630095)
3. Subscribe to [ULib](https://steamcommunity.com/sharedfiles/filedetails/?id=131759821) and [ULX](https://steamcommunity.com/sharedfiles/filedetails/?id=133075060)
4. Start a new game and select the "Rust" gamemode

## Chat Commands

Use these commands in-game with the `!` prefix:

### Admin Commands (require admin/superadmin)
- `!grust help` - Display all available commands
- `!multiplier get` - View current multipliers
- `!multiplier <type> <value>` - Set multiplier (gather, resources, recycler, loot, all)
- `!mult <type> <value>` - Shortcut for multiplier command
- `!giveitem <item_id> [amount]` - Give yourself items
- `!give <item_id> [amount]` - Shortcut for giveitem
- `!save` - Save current gamemode state
- `!load` - Load saved gamemode state
- `!wipe all` - Wipe all data except config, then restart
- `!wipe config` - Wipe config only, then restart
- `!perm get` - View current permissions
- `!perm set <key> <level>` - Set permission level (public, user, moderator, admin, superadmin)

### Permission System

The gamemode uses a permission system that integrates with ULX:
- **superadmin** - Full access to all commands
- **admin** - Default access level for all commands
- **moderator** - Reserved for future use
- **user** - Limited access
- **public** - No access

Permissions can be configured with `!perm set <key> <level>`

## Repository

For the latest version and to report issues:
> https://github.com/Down-s/gRust
