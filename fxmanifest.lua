fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'Slurpy in collaboration with Glitch Studios'
description 'FiveM resource for spawning and managing persistent objects across your server'
version '1.0.0'

client_script {
    'client/main.lua',
	"client/gizmo.lua",
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/apiKeys.lua',
    'server/functions/database.lua',
    'server/functions/discordLogs.lua',
    'server/functions/versionCheck.lua',
    'server/main.lua',
}

shared_script {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

files {
	'locales/*.json',
	'client/dataview.lua',
}