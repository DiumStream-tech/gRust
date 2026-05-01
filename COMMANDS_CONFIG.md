CENTRALIZED COMMANDS SYSTEM - CONFIGURATION GUIDE

All gRust commands are now centralized in gamemode/core/commands/commands_sv.lua
Permission system is located in gamemode/core/commands/permissions_sv.lua

PERMISSION LEVELS (lowest to highest):
- public: Anyone
- user: Players
- moderator: Moderators
- admin: Admins
- superadmin: SuperAdmins

AVAILABLE COMMANDS & DEFAULT PERMISSIONS:

1. grust_giveitem <item_id> [amount] (default: admin)
   Give yourself items from F1 menu

2. grust_setmultiplier <type> <value> (default: admin)
   Types: gather, resources, recycler, loot, all
   Example: grust_setmultiplier gather 2

3. grust_getmultiplier (default: admin)
   View current multiplier settings

4. grust_wipe [bpWipe] [scheduled] (default: admin)
   Wipe server and restart
   bpWipe: 1 to wipe blueprints too, 0 for world only
   scheduled: 1 if scheduled wipe, 0 for manual

5. grust_save [filename] (default: admin)
   Manually save the world
   Default filename: manualsave.dat

6. grust_load [filename] (default: admin)
   Load a saved world
   Default filename: manualsave.dat

7. grust_reloadconfig (console only, superadmin)
   Reload configuration files

8. grust_setpermission <key> <level> (superadmin only)
   Set permission level for commands
   Keys: give, wipe, save, load, multiplier, config
   Example: grust_setpermission give user

9. grust_getpermissions (superadmin only)
   View current permission settings

EXAMPLE CONFIGURATIONS:

Allow all players to spawn items:
grust_setpermission give public

Allow moderators to wipe:
grust_setpermission wipe moderator

Allow admins to change multipliers:
grust_setpermission multiplier admin

ULX INTEGRATION (Automatic):
- SuperAdmin group gets superadmin level
- Admin group gets admin level
- Moderator group gets moderator level
- Or use standard gmod admin system (IsSuperAdmin, IsAdmin)

PERMISSION HIERARCHY:
The system checks in this order:
1. ULX user group (if ulx exists)
2. Standard gmod admin flags
3. Defaults to user level
