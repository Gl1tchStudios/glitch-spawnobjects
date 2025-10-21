Config = {}

Config.Debug = true -- Set to true to enable debug mode, which will draw markers for spawned objects.

Config.permissionSystem = "ace" -- Options: "ace", "discord", "steam", "license", "everyone"
Config.acePermission = "command.spawnobject" -- ACE permission required (only used when permissionSystem = "ace")
Config.allowedDiscordAccess = {"Owner", "Admin Team"} -- List of roles that are allowed access to commands (only used when permissionSystem = "discord") (Note: You need to implement your own Discord role checking logic)
Config.allowedSteamIDs = {"steam:123456789", "steam:987654321"} -- List of allowed Steam IDs (only used when permissionSystem = "steam")
Config.allowedLicenses = {"license:abc123", "license:def456"} -- List of allowed licenses (only used when permissionSystem = "license")

Config.commands = {
    spawnObject = "spawnobject", -- Command to spawn a new synced object
    syncedObjects = "syncedobjects" -- Command to view all synced objects
}

Config.ignoreSceneType = {"christmas"} -- List of scene types to exclude from being loaded by this script.
Config.itemsPerPage = 20 -- Amount of objects shown per page via /syncedobjects
Config.renderDistance = 150.0 -- The distance threshold (in units) at which objects will be rendered. Modify this value to adjust the render distance.
Config.maxDuration = 10080 -- Maximum duration in minutes for temporary objects (default: 10080 = 7 days)

Config.enablePredefinedProps = true -- Set to true to use a pre-defined list of props, false to only allow manual input
Config.predefinedPropsUrl = "https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/ObjectList.ini" -- URL to fetch object list from (Don't change unless you have a custom list)
Config.predefinedProps = {} -- This will be populated dynamically from the URL (Don't change unless you know what you're doing)

-- Discord logging is available, set up API key within shared/apiKeys.lua if you wish to use it.