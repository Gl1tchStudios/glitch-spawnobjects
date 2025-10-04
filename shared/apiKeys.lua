local apiKeys = {
    discordWebhook = "https://discord.com/api/webhooks/1051625304063484045/HVZWoEyMmu1k2DZGOJIhCnHoyBMQT4v7e9uqo8ew0LHpo5X_quCrh2p7XkNDkzCU6o0p" 
}

function getApiKey(key)
    return apiKeys[key] or nil
end