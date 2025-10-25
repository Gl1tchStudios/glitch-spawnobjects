local function createDatabaseTable()
    local resourceName = GetCurrentResourceName()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `synced_objects` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `model` varchar(100) NOT NULL,
            `posX` decimal(10,5) NOT NULL,
            `posY` decimal(10,5) NOT NULL,
            `posZ` decimal(10,5) NOT NULL,
            `rotX` decimal(10,5) NOT NULL,
            `rotY` decimal(10,5) NOT NULL,
            `rotZ` decimal(10,5) NOT NULL,
            `identifier` varchar(50) DEFAULT NULL,
            `sceneType` varchar(50) DEFAULT NULL,
            `expiryTime` int(11) DEFAULT NULL,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(result)
        if result then
            MySQL.query([[
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'synced_objects' 
                AND COLUMN_NAME = 'expiryTime'
            ]], {}, function(columnResult)
                if columnResult and #columnResult == 0 then
                    MySQL.query('ALTER TABLE synced_objects ADD COLUMN expiryTime INT(11) DEFAULT NULL', {}, function(alterResult)
                        if alterResult then
                            print('^2['..resourceName..']^7 Added expiryTime column to existing table.')
                        else
                            print('^1['..resourceName..']^7 Failed to add expiryTime column.')
                        end
                    end)
                end
            end)
            print('^2['..resourceName..']^7 Database verification ^2complete^7.')
        else
            print('^2['..resourceName..']^7 Database verification ^1failed^7.')
        end
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        createDatabaseTable()
    end
end)