Config = {}

-- ════════════════════════════════════════════════════════════════════════════════════
-- GENERAL SETTINGS
-- ════════════════════════════════════════════════════════════════════════════════════

-- Enable debug mode to draw markers for spawned objects and show debug information
Config.Debug = false

-- ════════════════════════════════════════════════════════════════════════════════════
-- PERMISSION SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════════

-- Permission system type
-- Options: "ace", "discord", "steam", "license", "everyone"
Config.permissionSystem = "ace"

-- ACE Permission (only used when permissionSystem = "ace")
Config.acePermission = "command.spawnobject"

-- Discord Roles (only used when permissionSystem = "discord")
-- Note: You need to implement your own Discord role checking logic
Config.allowedDiscordAccess = {
    "Owner",
    "Admin Team"
}

-- Steam IDs (only used when permissionSystem = "steam")
Config.allowedSteamIDs = {
    "steam:123456789",
    "steam:987654321"
}

-- License IDs (only used when permissionSystem = "license")
Config.allowedLicenses = {
    "license:abc123",
    "license:def456"
}

-- ════════════════════════════════════════════════════════════════════════════════════
-- COMMANDS
-- ════════════════════════════════════════════════════════════════════════════════════

Config.commands = {
    spawnObject = "spawnobject",      -- Command to spawn a new synced object
    syncedObjects = "syncedobjects"   -- Command to view all synced objects
}

-- ════════════════════════════════════════════════════════════════════════════════════
-- OBJECT MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════════════

-- Scene types to exclude from being loaded by this script
Config.ignoreSceneType = {
    "christmas"
}

-- Number of objects shown per page via /syncedobjects command
Config.itemsPerPage = 20

-- Distance threshold (in units) at which objects will be rendered
Config.renderDistance = 150.0

-- Maximum duration in minutes for temporary objects (default: 10080 = 7 days)
Config.maxDuration = 10080

-- ════════════════════════════════════════════════════════════════════════════════════
-- PREDEFINED PROPS CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════════════

-- Enable predefined props list (set to false to only allow manual input)
Config.enablePredefinedProps = false

-- Props Source Configuration
-- Options: 
--   "url"    - Load props from GitHub URL (thousands of objects, requires internet, slower loading)
--   "custom" - Load props from customPredefinedProps list below (recommended - faster, curated)
--   "both"   - Load props from both sources (comprehensive but slower)
Config.propsSource = "custom"

-- URL to fetch object list from (Don't change unless you have a custom list)
Config.predefinedPropsUrl = "https://raw.githubusercontent.com/DurtyFree/gta-v-data-dumps/master/ObjectList.ini"

-- This will be populated dynamically from the URL and/or custom list
Config.predefinedProps = {}

-- ════════════════════════════════════════════════════════════════════════════════════
-- CUSTOM PREDEFINED PROPS LIST
-- ════════════════════════════════════════════════════════════════════════════════════
-- Add your own predefined objects here when using propsSource = "custom" or "both"
-- This allows server owners to create their own curated list of commonly used objects
-- ════════════════════════════════════════════════════════════════════════════════════

Config.customPredefinedProps = {
    -- Work Barriers & Cones
    "prop_barrier_work05",
    "prop_barrier_work06a",
    "prop_cone_roadwork02",
    "prop_roadcone02a",
    "prop_mp_cone_01",
    "prop_mp_cone_02",
    "prop_mp_cone_03",
    "prop_mp_cone_04",
    "prop_barrier_wat_03a",
    "prop_barrier_wat_03b",
    "prop_mp_barrier_01",
    "prop_mp_barrier_02a",
    "prop_mp_barrier_02b",
    
    -- Tool Chests
    "prop_toolchest_01",
    "prop_toolchest_02",
    "prop_toolchest_03",
    "prop_toolchest_04",
    "prop_toolchest_05",
    
    -- Gazebos
    "prop_gazebo_02",
    "prop_gazebo_03",
    
    -- Chairs
    "prop_chair_01a",
    "prop_chair_01b",
    "prop_chair_02",
    "prop_chair_03",
    "prop_chair_04a",
    "prop_chair_05",
    "prop_chair_06",
    "prop_chair_07",
    "prop_chair_08",
    "prop_chair_09",
    "prop_chair_10",
    
    -- Tables
    "prop_table_01",
    "prop_table_02",
    "prop_table_03_chr",
    "prop_table_04_chr",
    "prop_table_05_chr",
    "prop_table_06_chr",
    "prop_picnictable_02",
    "prop_picnictable_01",
    
    -- Benches
    "prop_bench_01a",
    "prop_bench_01b",
    "prop_bench_01c",
    "prop_bench_02",
    "prop_bench_03",
    "prop_bench_04",
    "prop_bench_05",
    "prop_bench_06",
    "prop_bench_07",
    "prop_bench_08",
    "prop_bench_09",
    "prop_bench_10",
    "prop_bench_11"
}

-- ════════════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE OPTIMIZATION
-- ════════════════════════════════════════════════════════════════════════════════════

-- Number of props to send per chunk (lower = more requests but smaller data size)
Config.propsChunkSize = 1000

-- Automatically preload props in background when player joins (recommended)
Config.preloadProps = true

-- ════════════════════════════════════════════════════════════════════════════════════
-- DISCORD LOGGING
-- ════════════════════════════════════════════════════════════════════════════════════
-- Discord logging is available, set up API key within shared/apiKeys.lua if you wish to use it.
-- ════════════════════════════════════════════════════════════════════════════════════