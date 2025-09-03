--rps
local ps = game:GetService("Players")
local reps = game:GetService("ReplicatedStorage")
local vu = game:GetService("VirtualUser")
local https = game:GetService("HttpService")

local plr = ps.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")





local plr_gui = plr:WaitForChild("PlayerGui")

local waiting_4_opp_window = plr_gui.WaitingForOpponent["Bottom Middle"].WaitingForOpponent
local opps_left = waiting_4_opp_window.Background["Step1.5"]
local opps_paying = waiting_4_opp_window.Background["Step2"]
local opps_paid = waiting_4_opp_window.Background["Step3"]
local game_confirmed = waiting_4_opp_window.Background["Step3.5"]
local timer = waiting_4_opp_window.Background.Timer.TextLabel
local vs_txt = waiting_4_opp_window.Background.Inside.DisplayName



local ttt_dir = plr_gui.RockPaperScissors

local battle_results = plr_gui.BattleResults["Middle Middle"]

local is_in_game = false



local args = {
    [1] = "RockPaperScissors",
    [2] = 100,
    [3] = {
        ["assetType"] = "GamePass",
        ["assetId"] = "1346081211"
    },
    [4] = true
}

local heckler_args = {
    [1] = "Roblox"
}



--// anti afk //--
plr.Idled:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new(9999, 9999))
end)

--// bought counter //--
local label
local function bought_counter()
    local gui = Instance.new("ScreenGui")
gui.Parent = plr_gui

label = Instance.new("TextLabel")
label.Parent = gui
label.Size = UDim2.new(0, 50, 0, 25)
label.Position = UDim2.new(1, -60, 1, -35) -- bottom-right corner
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "0"
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold
end

bought_counter()

local function onCharacterAdded(char)
    hum = char:WaitForChild("Humanoid")
    bought_counter()
end
plr.CharacterAdded:Connect(onCharacterAdded)
--// hosting mini-game //--

local function host_minigame()
    reps.RemoteCalls.GameSpecific.Tickets.DestroyRoom:InvokeServer()--destroy minigame room
	task.wait()
	reps.RemoteCalls.GameSpecific.DailySpinner.ClaimDailySpinner:InvokeServer()
	task.wait(1)
    reps.RemoteCalls.GameSpecific.Tickets.CreateRoom:InvokeServer(unpack(args))
end

host_minigame()

game_confirmed:GetPropertyChangedSignal("Visible"):Connect(function() --opps joined for free and starting minigame
    if not is_in_game then
        if game_confirmed.Visible then
            is_in_game = true
        end
    end
end)

opps_paid:GetPropertyChangedSignal("Visible"):Connect(function() --opps paid and starting minigame
    if not is_in_game then
        if opps_paid.Visible then
            is_in_game = true
        end
    end
end)

opps_left:GetPropertyChangedSignal("Visible"):Connect(function() --opps refused to pay
    if not is_in_game then
        if opps_left.Visible then
            host_minigame()
        end
    end
end)


timer:GetPropertyChangedSignal("Text"):Connect(function() --opps refused to pay
    if timer.Text == "Time remaining to pay: 1" then --possible heckler name is saved
        heckler_args[1] = string.gsub(string.match(vs_txt.Text, "VS%s+(.+)"), "^%s*(.-)%s*$", "%1")

    elseif timer.Text == "Time remaining to pay: 0" then --heckler gets blacklisted
        reps.RemoteCalls.General.Blacklist:FireServer(unpack(heckler_args))
    end
end)


battle_results.ChildAdded:Connect(function(child)--won pop notif/game ended
    if child.Name == "_tmp" then

        label.Text = tonumber(label.Text)+1

        repeat task.wait()
        until child.Background or not child
        repeat task.wait()
        until child.Background.Close or not child

        is_in_game = false

        for _, conn in ipairs(getconnections(child.Background.Close.MouseButton1Click)) do
            conn:Fire()
        end
        ---------------------
       --[[
        hum:MoveTo(Vector3.new(math.random(70, 72), 21, -math.random(15, 30)))
        move_conn = hum.MoveToFinished:Connect(function()
            move_conn:Disconnect()
        end)
        task.spawn(function() --stop moving to the wheel if ingame
            while task.wait(1) and hum and hum.MoveTo and is_in_game do
                hum:MoveTo(hum.RootPart.Position) -- stops movement
                break
            end
        end)
        ]]
    ---------------------

    http_request({
        Url = "https://discord.com/api/webhooks/1410582628821893183/47TVD29UOceZEcdTGHN_P5HZnKGjz3zZN9dqHNj5PvvDb4eWZMSnS1is5WGErNNi4bE3",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = https:JSONEncode({
            content = plr.Name .. " " .. plr.leaderstats["💸 Earned"].Value
        })
    })

    host_minigame()

    end
end)


task.spawn(function() --refresh hosting pos
    while task.wait(10) do
        if not is_in_game then
            if not opps_paying.Visible and not opps_paid.Visible then
                host_minigame()
            end
        end
    end
end)
