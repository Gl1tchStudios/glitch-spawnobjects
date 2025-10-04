local apiKeys = {
    discordWebhook = "https://discord.com/api/webhooks/" 
}

function getApiKey(key)
    return apiKeys[key] or nil
end