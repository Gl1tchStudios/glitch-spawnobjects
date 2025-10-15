local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, "version", 0)
local versionURL = "https://raw.githubusercontent.com/Gl1tchStudios/glitch-versions/main/"..resourceName..".json"

CreateThread(function()
    Wait(3000)

    PerformHttpRequest(versionURL, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 and resultData then
            local success, json = pcall(function()
                return json.decode(resultData)
            end)

            if success and json and json.version then
                local latestVersion = tostring(json.version):gsub("%s+", "")
                if latestVersion ~= currentVersion then
                    print(string.rep("-", 60))
                    print(("^1[WARNING]^0 You are not running the latest version of ^3%s^0!"):format(resourceName))
                    print(("^1[WARNING]^0 Please update! (Latest: ^2v%s^0 | Yours: ^1v%s^0)"):format(latestVersion, currentVersion))
                    print("^3Changelog:^0")
                    if json.changelog and type(json.changelog) == "table" then
                        for i, change in ipairs(json.changelog) do
                            print("  • " .. tostring(change))
                        end
                    else
                        print("  • No changelog provided")
                    end
                    print("^3Discord:^0")
                    print("  • Patch notes and support are available on Discord.")
                    print("  • " .. (json.discord or "No link provided"))
                    print(string.rep("-", 60))
                else
                    print(("^2[%s]^0 is up to date! (v%s)"):format(resourceName, currentVersion))
                end
            else
                print("^1[ERROR]^0 Failed to parse version JSON.")
            end
        else
            print(("^1[ERROR]^0 Failed to fetch version info for %s (HTTP %s)"):format(resourceName, errorCode))
        end
    end)
end)