fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'extraction_shooter'
author 'Cloud10Dev'
description 'Extraction shooter — party, matchmaking, routing buckets, AI peds, ox_inventory stash'
version '1.4.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_utils.lua',
    'server/sv_party.lua',
    'server/sv_matchmaking.lua',
    'server/sv_instance.lua',
    'server/sv_extraction.lua',
    'server/sv_ai.lua',
    'server/sv_debug.lua'
}

client_scripts {
    'client/cl_utils.lua',
    'client/cl_party.lua',
    'client/cl_nui.lua',
    'client/cl_extraction.lua',
    'client/cl_ai.lua',
    'client/cl_death.lua',
    'client/cl_stash_npc.lua',
    'client/cl_debug.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependencies {
    'ox_inventory',
    'oxmysql'
}
