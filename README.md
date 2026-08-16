# extraction_shooter (fixed)

Updated build with:
- fixed `config.lua` vector usage (`vector3` vs `vector4`)
- restored `Config.Events`
- added routing buckets for match instancing
- added stash NPC and `/teststash`
- changed owned stash open flow to `openInventory('stash', { id, owner })`
- added stash registration on join/resource start

## Important
This build requires:
- ox_inventory
- oxmysql
- OneSync enabled, because routing buckets require OneSync support. See FiveM docs for routing buckets and session isolation.[web:50][web:56]

## Commands
- `/party`
- `/teststash`
- `debug_match_info` (server console)

## Notes
If stash still does not open, check F8 for `openInventory result: false`. That indicates ox_inventory rejected the open request, commonly due to another inventory already being open or stack-specific state rules.[web:19][web:6]
