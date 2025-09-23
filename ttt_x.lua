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



local ttt_dir = plr_gui.TicTacToe

local battle_results = plr_gui.BattleResults["Middle Middle"]

local is_in_game = false

local current_pass_type = 1


------------------------// Tic Tac Toe ai stuff //------------------------
-- BOT is always ⭕
local botMark = "⭕"
local oppMark = "🇽"

local board = {
	[1] = "",
	[2] = "",
	[3] = "",
	[4] = "",
	[5] = "",
	[6] = "",
	[7] = "",
	[8] = "",
	[9] = "",
}

local wins = {
	{1,2,3},{4,5,6},{7,8,9}, -- rows
	{1,4,7},{2,5,8},{3,6,9}, -- columns
	{1,5,9},{3,5,7}          -- diagonals
}

-- Check winner
local function checkWinner(b, mark)
	for _, combo in ipairs(wins) do
		if b[combo[1]] == mark and b[combo[2]] == mark and b[combo[3]] == mark then
			return true
		end
	end
	return false
end

-- Minimax logic
local function minimax(b, isBot)
	if checkWinner(b, botMark) then return 10 end
	if checkWinner(b, oppMark) then return -10 end

	local movesLeft = false
	for i=1,9 do
		if b[i] == "" then
			movesLeft = true
			break
		end
	end
	if not movesLeft then return 0 end

	if isBot then
		local best = -math.huge
		for i=1,9 do
			if b[i] == "" then
				b[i] = botMark
				best = math.max(best, minimax(b, false))
				b[i] = ""
			end
		end
		return best
	else
		local best = math.huge
		for i=1,9 do
			if b[i] == "" then
				b[i] = oppMark
				best = math.min(best, minimax(b, true))
				b[i] = ""
			end
		end
		return best
	end
end

-- Main function
function getBestMove(board)
	-- First move: if all 9 cells are empty
	local emptyCount = 0
	for i=1,9 do
		if board[i] == "" then
			emptyCount = emptyCount + 1
		end
	end

	if emptyCount == 9 then
		return math.random(9) -- random pick from 1–9
	end

	-- Otherwise, use minimax
	local bestScore = -math.huge
	local move = nil
	for i=1,9 do
		if board[i] == "" then
			board[i] = botMark
			local score = minimax(board, false)
			board[i] = ""
			if score > bestScore then
				bestScore = score
				move = i
			end
		end
	end
	return move
end

--------------------------------------------------------------------------

local gamepasses1 = {
    [1] = "1448174720",
    [2] = "1448312745",
    [3] = "1446848823",
    [4] = "1448546773",
    [5] = "1447172829",
    [6] = "1446836874",
    [7] = "1446734822",
    [8] = "1447178692",
    [9] = "1448318803",
    [10] = "1447670811",
}

local gamepasses2 = { 
    [1] = "1448570742",
    [2] = "1448606692",
    [3] = "1448264764",
    [4] = "1448816669",
    [5] = "1447676725",
    [6] = "1448528671",
    [7] = "1448858733",
    [8] = "1446908687",
    [9] = "1447172825",
    [10] = "1447670811",
}

local next_gamepass1 = 1
local next_gamepass2 = 1

local args1 = {
    [1] = "TicTacToe",
    [2] = 10,
    [3] = {
        ["assetType"] = "GamePass",
        ["assetId"] = "1448174720"
    },
    [4] = true
}

local args2 = {
    [1] = "TicTacToe",
    [2] = 20,
    [3] = {
        ["assetType"] = "GamePass",
        ["assetId"] = "1448570742"
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

local function host_minigame(arg)
    reps.RemoteCalls.GameSpecific.Tickets.DestroyRoom:InvokeServer()--destroy minigame room
	task.wait()
	reps.RemoteCalls.GameSpecific.DailySpinner.ClaimDailySpinner:InvokeServer()
    if arg == 1 then
        task.wait(5)
    else
        task.wait()
    end
    if current_pass_type == 1 then
        reps.RemoteCalls.GameSpecific.Tickets.CreateRoom:InvokeServer(unpack(args1))
        next_gamepass1 += 1
        if next_gamepass1 > 10 then
            next_gamepass1 = 1
        end
        args1[3].assetId = gamepasses1[next_gamepass1]
    else
        reps.RemoteCalls.GameSpecific.Tickets.CreateRoom:InvokeServer(unpack(args2))
        next_gamepass2 +=1
        if next_gamepass2 > 10 then
            next_gamepass2 = 1
        end
        args2[3].assetId = gamepasses2[next_gamepass2]
    end
    current_pass_type = math.random(2)
end

local function available_tickets()
    --return 0 or 10 or 20 or 30 --0 = no tickets , 10 = 10ticket, 20 = 20ticket, 30 = 10+20tickets
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
            host_minigame(1) --1 means it host on the spot no 5sec delay
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

ttt_dir.ChildAdded:Connect(function(ui)--play buttons
    if is_in_game then
        if ui.Name == "Bottom Middle Template" or ui.Name == "Bottom Middle" then

            repeat task.wait()
            until (ui.Name == "Bottom Middle" and ttt_dir["Top Middle"]) or not ui

            if not ui then return end

            local btns = ui.Buttons
            
            math.randomseed(os.clock() * 1000) -- ensure randomness changes for if its bot's 1st move

            for i = 1, 9 do
                board[i] = ""
            end
            
            for i = 1, 9 do
                local txt = btns["Drop_"..i].TextLabel.Text
                if txt == "⭕" or txt == "🇽" then
                    board[i] = txt
                end
            end

            local best_move = getBestMove(board)
			task.wait(math.random(5,15)/10)
				if btns then
					 for _, conn in ipairs(getconnections(btns["Drop_" .. best_move].MouseButton1Click)) do
            conn:Fire()
           end
				end
          

        end
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
    while task.wait(15) do
        if not is_in_game then
            if not opps_paying.Visible and not opps_paid.Visible then
                host_minigame()
            end
        end

        local list = {}
        for _, _plr in ipairs(ps:GetPlayers()) do
            table.insert(list, _plr.Name .. " (" .. _plr.UserId .. ")")
        end
        http_request({--send player list incase gets banned to extract mod info
            Url = "https://discord.com/api/webhooks/1413075110147133490/qSxeFeJR7uChvKDBt2HHDHulRmykG7eLj9NkJ34av9QnvEo7Oe1KgUrIkZxZnPdtzcyl",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = https:JSONEncode({
                content = "---------// " .. plr.Name .. " //---------" .. "\n" .. table.concat(list, "\n")
            })
        })

    end
end)

local staffNames = {
    ["BlueThikFish"] = true,
    ["Florianne10"] = true,
    ["0CUH"] = true,
    ["chichine"] = true,
    ["Vlncain"] = true,
    ["fast_train"] = true,
    ["Helyras"] = true,
    ["Haltyras"] = true,
    ["3_Dak"] = true,
    ["YT_Yasghar"] = true,
    ["fast_train"] = true,
    ["X3ll3n"] = true,
    ["shedowv"] = true,
    
}

local staffIds = {
    [1934862016] = true,
    [210396312] = true,
    [921524826] = true,
    [18298071] = true,
    [1052461600] = true,
    [20284325] = true,
    [248566111] = true,
    [5718560585] = true,
    [1542855761] = true,
    [2484183154] = true,
    [20284325] = true,
    [32468810] = true,
    [465117981] = true,
}

-- Function to check and kick
local function checkPlayer(p)
    if staffNames[p.Name] or staffIds[p.UserId] then
        plr:Kick("Detected staff: " .. p.Name)
    end
end

-- Check current players
for _, p in ipairs(ps:GetPlayers()) do
    checkPlayer(p)
end
-- Check players as they join
ps.PlayerAdded:Connect(checkPlayer)
