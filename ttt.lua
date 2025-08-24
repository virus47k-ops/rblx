local ps = game:GetService("Players")
local reps = game:GetService("ReplicatedStorage")
local vu = game:GetService("VirtualUser")

local plr = ps.LocalPlayer
local plr_gui = plr:WaitForChild("PlayerGui")

local waiting_4_opp_window = plr_gui.WaitingForOpponent["Bottom Middle"].WaitingForOpponent
local opps_left = waiting_4_opp_window.Background["Step1.5"]
local opps_paying = waiting_4_opp_window.Background["Step2"]
local opps_paid = waiting_4_opp_window.Background["Step3"]
local game_confirmed = waiting_4_opp_window.Background["Step3.5"]



local ttt_dir = plr_gui.TicTacToe

local battle_results = plr_gui.BattleResults["Middle Middle"]

local is_in_game = false


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



local gamepasses = {
    [1] = "1345632481",
    [2] = "1398270268",
    [3] = "1397459198",
    [4] = "1397219230",
    [5] = "1395230060",
    [6] = "1400188442",
    [7] = "1397579165",
    [8] = "1398168394",
    [9] = "1397483167",
    [10] = "1398292299",
}

local next_gamepass = 1

local args = {
    [1] = "TicTacToe",
    [2] = 10,
    [3] = {
        ["assetType"] = "GamePass",
        ["assetId"] = "1345632481"
    },
    [4] = true
}

--[[
local args2 = {
    [1] = "TicTacToe",
    [2] = 0,
    [3] = {
        ["assetType"] = "",
        ["assetId"] = ""
    },
    [4] = true
}
    ]]

--// anti afk //--
plr.Idled:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new(9999, 9999))
end)

--// bought counter //--
local gui = Instance.new("ScreenGui")
gui.Parent = plr_gui

local label = Instance.new("TextLabel")
label.Parent = gui
label.Size = UDim2.new(0, 50, 0, 25)
label.Position = UDim2.new(1, -60, 1, -35) -- bottom-right corner
label.BackgroundTransparency = 0.3
label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = "0"
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold

--// hosting mini-game //--

local function host_minigame()
    reps.RemoteCalls.GameSpecific.Tickets.DestroyRoom:InvokeServer()--destroy minigame room
	task.wait()
	reps.RemoteCalls.GameSpecific.DailySpinner.ClaimDailySpinner:InvokeServer()
	task.wait(5)
    reps.RemoteCalls.GameSpecific.Tickets.CreateRoom:InvokeServer(unpack(args))

    next_gamepass = next_gamepass + 1
    if next_gamepass > 10 then
        next_gamepass = 1
    end
    args[3].assetId = gamepasses[next_gamepass]
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

ttt_dir.ChildAdded:Connect(function(ui)--play buttons
    if is_in_game then
        if ui.Name == "Bottom Middle Template" or ui.Name == "Bottom Middle" then

            repeat task.wait()
            until (ui.Name == "Bottom Middle" and ttt_dir["Top Middle"]) or not ui

            if not ui then return end

            local btns = ui.Buttons
            
            math.randomseed(tick()) -- ensure randomness changes for if its bot's 1st move

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
			task.wait(math.random(2))
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
    end
end)
