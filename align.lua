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

local align_dir = plr_gui.Align
local arenas_fldr = Workspace.ArenasREAL

local balls_container --where the balls are added container

local battle_results = plr_gui.BattleResults["Middle Middle"]

local is_in_game = false



------------------------// Align ai stuff //------------------------
-- BOT is always red
local ROWS = 6
local COLS = 7
local BOT = "r"
local OPP = "b"
local MAX_DEPTH = 7 -- reduce depth for performance

-- convert board table to two 32-bit bitboards
local function boardToBitboards(board)
	local botBoard = 0
	local maskBoard = 0
	local bit = 1

	for r = 1, ROWS do
		for c = 1, COLS do
			local cell = board[c][r]
			if cell ~= "" then
				maskBoard = bit32.bor(maskBoard, bit)
				if cell == BOT then
					botBoard = bit32.bor(botBoard, bit)
				end
			end
			bit = bit32.lshift(bit,1)
		end
	end
	return botBoard, maskBoard
end

-- check if column is playable
local function canPlay(maskBoard, col)
	for r = 1, ROWS do
		local bit = bit32.lshift(1, (col-1)*ROWS + (r-1))
		if bit32.band(maskBoard, bit) == 0 then
			return true
		end
	end
	return false
end

-- play a move, return new bitboards
local function playMove(botBoard, maskBoard, col, isBotTurn)
	local bit = bit32.lshift(1, (col-1)*ROWS) -- bottom row bit
	while bit32.band(maskBoard, bit) ~= 0 do
		bit = bit32.lshift(bit,1)
	end
	maskBoard = bit32.bor(maskBoard, bit)
	if isBotTurn then
		botBoard = bit32.bor(botBoard, bit)
	end
	return botBoard, maskBoard
end

-- check win using bitwise shifts
local function isWinning(bitboard)
	local directions = {1, ROWS, ROWS+1, ROWS-1} -- horizontal, vertical, diag1, diag2
	for _, dir in ipairs(directions) do
		local b = bit32.band(bitboard, bit32.rshift(bitboard, dir))
		if bit32.band(b, bit32.rshift(b, 2*dir)) ~= 0 then
			return true
		end
	end
	return false
end

-- simple evaluation
local function evaluate(botBoard, maskBoard)
	if isWinning(botBoard) then return 100000 end
	if isWinning(bit32.bxor(maskBoard, botBoard)) then return -100000 end
	return 0
end

-- negamax with alpha-beta pruning
local function negamax(botBoard, maskBoard, depth, alpha, beta, isBotTurn)
	local score = evaluate(botBoard, maskBoard)
	if math.abs(score) >= 100000 or depth == 0 then
		return score
	end

	local bestScore = -math.huge
	for _, col in ipairs({4,3,5,2,6,1,7}) do -- center-first ordering
		if canPlay(maskBoard, col) then
			local newBot, newMask = playMove(botBoard, maskBoard, col, isBotTurn)
			local val = -negamax(newBot, newMask, depth-1, -beta, -alpha, not isBotTurn)
			if val > bestScore then
				bestScore = val
			end
			alpha = math.max(alpha, val)
			if alpha >= beta then
				break
			end
		end
	end
	return bestScore
end

-- main function
function getBestMove(board)
	local botBoard, maskBoard = boardToBitboards(board)
	local bestCol = 4
	local bestScore = -math.huge

	for _, col in ipairs({4,3,5,2,6,1,7}) do
		if canPlay(maskBoard, col) then
			local newBot, newMask = playMove(botBoard, maskBoard, col, true)
			local score = -negamax(newBot, newMask, MAX_DEPTH-1, -math.huge, math.huge, false)
			if score > bestScore then
				bestScore = score
				bestCol = col
			end
		end
	end
	return bestCol
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
			label.Text =1
			if not balls_container then
				label.Text =2
				for _, _arena in pairs(arenas_fldr:GetChildren()) do
					local ArenaTemplate = _arena:FindFirstChild("ArenaTemplate")
					if ArenaTemplate then
						label.Text =3
						if ArenaTemplate:FindFirstChild("Red"):FindFirstChild("Character"):FindFirstChild("Nametag"):FindFirstChild("Frame"):FindFirstChild("Nickname").Text == "@" .. plr.Name then
							label.Text =4
							balls_container = ArenaTemplate:FindFirstChild("Important"):FindFirstChild("Balls")
							break
						end
					end
				end
			end

			local btns = ui.Buttons

			local board = {
				{ "","","","","","" }, -- column 1 
				{ "","","","","","" }, -- column 2 
				{ "","","","","","" }, -- column 3 
				{ "","","","","","" }, -- column 4 
				{ "","","","","","" }, -- column 5 
				{ "","","","","","" }, -- column 6 
				{ "","","","","","" }, -- column 7 
			}

			for _, child in pairs(balls_container:GetChildren()) do --fills the board with the current board status
				local col = tonumber(string.sub(child.Name, 2, 2))
				local row = tonumber(string.sub(child.Name, 3, 3))

				if col and row then
					if child.Color == Color3.fromRGB(255, 102, 102) then
						board[col][row] = "r"
					else
						board[col][row] = "b"
					end

				end
			end

			local best_move = getBestMove(board)

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
