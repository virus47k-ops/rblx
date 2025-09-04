--temp
local ps = game:GetService("Players")
local https = game:GetService("HttpService")

local plr = ps.LocalPlayer


for _, p in ipairs(ps:GetPlayers()) do
    if p.Name == "jajo_dex" or p.UserId == 3490921700 or p.Name == "Florianne10" or p.UserId == 210396312 then
        LocalPlayer:Kick("Detected staff already in server")
    end
end

ps.PlayerAdded:Connect(function(p)
    if p.Name == "jajo_dex" or p.UserId == 3490921700 or p.Name == "Florianne10" or p.UserId == 210396312 then
        LocalPlayer:Kick("Detected staff joined")
    end
end)


ps.PlayerRemoving:Connect(function(p)
    if p == LocalPlayer then
        local list = {}
        for _, _plr in ipairs(game:GetService("Players"):GetPlayers()) do
            table.insert(list, _plr.Name .. " (" .. _plr.UserId .. ")")
        end

        http_request({
            Url = "https://discord.com/api/webhooks/1413075110147133490/qSxeFeJR7uChvKDBt2HHDHulRmykG7eLj9NkJ34av9QnvEo7Oe1KgUrIkZxZnPdtzcyl",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            https:JSONEncode({
            content = "---------// " .. plr.Name .. " //---------" .. "\n" .. table.concat(list, "\n")
        })
    })
    end
end)
