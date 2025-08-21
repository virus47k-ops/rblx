local ps = game:GetService("Players")
local reps = game:GetService("ReplicatedStorage")
local vu = game:GetService("VirtualUser")
local https = game:GetService("HttpService")

local plr = ps.LocalPlayer
local plr_gui = plr:WaitForChild("PlayerGui")

local waiting_4_opp_window = plr_gui.WaitingForOpponent["Bottom Middle"].WaitingForOpponent
local opps_left = waiting_4_opp_window.Background["Step1.5"]
local opps_paying = waiting_4_opp_window.Background["Step2"]
local opps_paid = waiting_4_opp_window.Background["Step3"]
local game_confirmed = waiting_4_opp_window.Background["Step3.5"]

local align_dir = plr_gui.Align
local arenas_fldr = Workspace.ArenasREAL

local balls_container --where the balls are added container

local battle_results = plr_gui.BattleResults["Middle Middle"]

local is_in_game = false



------------------------// Align ai stuff //------------------------
-- BOT is always red

local CENTER_COL = 3 -- 0-indexed
local MAX_SCORE = 1e9

-- Heuristic evaluation: counts potential 2s, 3s, and center control
local function evaluatePosition(playerBB, oppBB, mask)
    local score = 0

    -- Center control
    for r = 0, ROWS-1 do
        local bit = colBit(CENTER_COL, r)
        if not isZero64(band64(playerBB, bit)) then score = score + 3 end
        if not isZero64(band64(oppBB, bit)) then score = score - 3 end
    end

    -- Simple 2-in-a-row and 3-in-a-row heuristics (horizontal + vertical)
    local directions = {1, COL_HEIGHT, COL_HEIGHT+1, COL_HEIGHT-1}
    for _, shift in ipairs(directions) do
        local m = band64(playerBB, rshift64(playerBB, shift))
        if not isZero64(m) then score = score + 2 end
        local m2 = band64(m, rshift64(m, shift))
        if not isZero64(m2) then score = score + 4 end
    end

    for _, shift in ipairs(directions) do
        local m = band64(oppBB, rshift64(oppBB, shift))
        if not isZero64(m) then score = score - 2 end
        local m2 = band64(m, rshift64(m, shift))
        if not isZero64(m2) then score = score - 4 end
    end

    return score
end

-- Negamax with alpha-beta and simple heuristic
local function negamaxAI(playerBB, oppBB, mask, depth, alpha, beta)
    if timeExceeded() then return 0 end
    if isWinningPosition(oppBB) then return -MAX_SCORE end
    if depth == 0 then return evaluatePosition(playerBB, oppBB, mask) end

    local best = -math.huge
    for _, col in ipairs(MOVE_ORDER) do
        if not isColumnFull(mask, col) then
            local newPlayer, newMask, _ = makeMoveFor(playerBB, mask, col)
            if isWinningPosition(newPlayer) then return MAX_SCORE end
            local val = -negamaxAI(oppBB, newPlayer, newMask, depth-1, -beta, -alpha)
            if val > best then best = val end
            if val > alpha then alpha = val end
            if alpha >= beta then break end
        end
    end
    return best
end

-- Iterative deepening to respect AI_TIME_LIMIT
local function findBestMoveAI(playerBB, oppBB, mask)
    startTime = os.clock()
    TT = {}

    local bestMove, bestScore = nil, -math.huge

    for depth = 1, AI_MAX_DEPTH do
        if timeExceeded() then break end
        local localBest, localMove = -math.huge, MOVE_ORDER[1]

        for _, col in ipairs(MOVE_ORDER) do
            if not isColumnFull(mask, col) then
                local newPlayer, newMask, _ = makeMoveFor(playerBB, mask, col)
                if isWinningPosition(newPlayer) then return col, MAX_SCORE end
                local score = -negamaxAI(oppBB, newPlayer, newMask, depth-1, -MAX_SCORE, MAX_SCORE)
                if score > localBest then
                    localBest, localMove = score, col
                end
                if timeExceeded() then break end
            end
        end

        if not timeExceeded() then
            bestMove, bestScore = localMove, localBest
        end
    end

    return bestMove, bestScore
end

-- Robust getBestMove for Roblox board
function getBestMove(board)
    local playerBB, oppBB, mask = make64(0,0), make64(0,0), make64(0,0)

    for r = 1, ROWS do
        for c = 1, COLUMNS do
            local cell = board[r][c]
            if cell ~= "" then
                local bit = colBit(c-1, ROWS-r)
                mask = bor64(mask, bit)
                if cell == "r" then playerBB = bor64(playerBB, bit)
                elseif cell == "b" then oppBB = bor64(oppBB, bit) end
            end
        end
    end

    local bestCol, _ = findBestMoveAI(playerBB, oppBB, mask)
    if bestCol then return bestCol + 1 else return nil end
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
--[[
local args = {
    [1] = "Align",
    [2] = 10,
    [3] = {
        ["assetType"] = "GamePass",
        ["assetId"] = "1345632481"
    },
    [4] = true
}
    ]]

local args = {
	[1] = "Align",
	[2] = 0,
	[3] = {
		["assetType"] = "",
		["assetId"] = ""
	},
	[4] = true
}


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
	reps.RemoteCalls.GameSpecific.Tickets.CreateRoom:InvokeServer(unpack(args))

	next_gamepass += 1
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

align_dir.ChildAdded:Connect(function(ui)--play buttons
	if is_in_game then
		if ui.Name == "Bottom Middle Template" or ui.Name == "Bottom Middle" then

			repeat task.wait()
			until (ui.Name == "Bottom Middle" and align_dir["Top Middle"]) or not ui

			if not ui then return end
			if not balls_container then
				for _, _arena in pairs(arenas_fldr:GetChildren()) do
					local ArenaTemplate = _arena:FindFirstChild("ArenaTemplate")
					if not ArenaTemplate then continue end
					local Red = ArenaTemplate:FindFirstChild("Red")
					if not Red then continue end
					local char = Red:FindFirstChild("Character")
					if not char then continue end
					local nametag = char:FindFirstChild("Nametag")
					if not nametag then continue end
					local frame = nametag:FindFirstChild("Frame")
					if not frame then continue end
					local nickname = frame:FindFirstChild("Nickname")
					if not nickname then continue end
					if nickname.Text == plr.Name then
						local important = ArenaTemplate:FindFirstChild("Important")
						if not important then continue end
						balls_container = important:FindFirstChild("Balls")
						break
					end
				end
			end

			local btns = ui.Buttons

			local board = {
				{ "","","","","","","" }, -- row 1 
				{ "","","","","","","" }, -- row 2 
				{ "","","","","","","" }, -- row 3 
				{ "","","","","","","" }, -- row 4 
				{ "","","","b","","","" }, -- row 5 
				{ "","","","r","","","" }, -- row 6 
			}

			for _, child in pairs(balls_container:GetChildren()) do --fills the board with the current board status
				--the child name would look like this for example "_12" where 1 is the col number
				local col = tonumber(string.sub(child.Name, 2, 2))
				local row = tonumber(string.sub(child.Name, 3, 3))

				if col and row then
					if child.Color == Color3.fromRGB(255, 102, 102) then
						board[row][col] = "r"
					else
						board[row][col] = "b"
					end

				end
			end

			local best_move = getBestMove(board)
			print(best_move)

			for _, conn in ipairs(getconnections(btns["Drop_" .. best_move].MouseButton1Click)) do
				conn:Fire()
			end

		end
	end
end)


battle_results.ChildAdded:Connect(function(child)--won pop notif/game ended
	if child.Name == "_tmp" then

		--label.Text = tonumber(label.Text)+1

		repeat task.wait()
		until child.Background or not child
		repeat task.wait()
		until child.Background.Close or not child

		is_in_game = false
		balls_container = nil


		for _, conn in ipairs(getconnections(child.Background.Close.MouseButton1Click)) do
			conn:Fire()
		end
		host_minigame()
	end
end)


task.spawn(function() --refresh hosting pos
	while task.wait(10) do
		if not is_in_game then
			if not opps_paying.Visible and not opps_paid.Visible then
				reps.RemoteCalls.GameSpecific.DailySpinner.ClaimDailySpinner:InvokeServer()
				host_minigame()
			end
		end
	end
end)
