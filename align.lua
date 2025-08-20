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
-- Roblox Connect4 AI: OpeningBook + Minimax

local ROWS, COLS = 6, 7
local BOT = "r"
local OPP = "b"

-- Load OpeningBook from GitHub raw JSON
local OpeningBook = {}
do
    local url = "https://raw.githubusercontent.com/virus47k-ops/rblx/refs/heads/main/align_ob"
    local success, response = pcall(function()
        return https:GetAsync(url)
    end)
    if success then
        OpeningBook = https:JSONDecode(response)
        print("OpeningBook loaded! Total positions:", #OpeningBook)
    else
        --warn("Failed to load OpeningBook:", response)
    end
end

-- Flatten board to string
local function flattenBoard(board)
    local s = ""
    for col = 1, COLS do
        for row = 1, ROWS do
            s = s .. (board[col][row] ~= "" and board[col][row] or ".")
        end
    end
    return s
end

-- Check win for a player
local function checkWin(board, player)
    -- Horizontal
    for r = 1, ROWS do
        for c = 1, COLS-3 do
            if board[c][r]==player and board[c+1][r]==player and board[c+2][r]==player and board[c+3][r]==player then
                return true
            end
        end
    end
    -- Vertical
    for c = 1, COLS do
        for r = 1, ROWS-3 do
            if board[c][r]==player and board[c][r+1]==player and board[c][r+2]==player and board[c][r+3]==player then
                return true
            end
        end
    end
    -- Diagonal /
    for c = 1, COLS-3 do
        for r = 4, ROWS do
            if board[c][r]==player and board[c+1][r-1]==player and board[c+2][r-2]==player and board[c+3][r-3]==player then
                return true
            end
        end
    end
    -- Diagonal \
    for c = 1, COLS-3 do
        for r = 1, ROWS-3 do
            if board[c][r]==player and board[c+1][r+1]==player and board[c+2][r+2]==player and board[c+3][r+3]==player then
                return true
            end
        end
    end
    return false
end

-- Minimax with alpha-beta
local function minimax(board, depth, alpha, beta, maximizing)
    if checkWin(board, BOT) then return 1000, nil end
    if checkWin(board, OPP) then return -1000, nil end
    -- Check draw
    local full = true
    for c = 1, COLS do
        if board[c][ROWS]=="" then full=false break end
    end
    if full or depth==0 then return 0, nil end

    local bestCol = nil
    if maximizing then
        local maxEval = -math.huge
        for c = 1, COLS do
            for r = 1, ROWS do
                if board[c][r]=="" then
                    board[c][r] = BOT
                    local eval,_ = minimax(board, depth-1, alpha, beta, false)
                    board[c][r] = ""
                    if eval > maxEval then
                        maxEval = eval
                        bestCol = c
                    end
                    alpha = math.max(alpha, eval)
                    if beta <= alpha then break end
                    break
                end
            end
        end
        return maxEval, bestCol
    else
        local minEval = math.huge
        for c = 1, COLS do
            for r = 1, ROWS do
                if board[c][r]=="" then
                    board[c][r] = OPP
                    local eval,_ = minimax(board, depth-1, alpha, beta, true)
                    board[c][r] = ""
                    if eval < minEval then
                        minEval = eval
                        bestCol = c
                    end
                    beta = math.min(beta, eval)
                    if beta <= alpha then break end
                    break
                end
            end
        end
        return minEval, bestCol
    end
end

-- Find next move from OpeningBook
local function findNextMoveInBook(flatBoard)
    for key,_ in pairs(OpeningBook) do
        if string.sub(key,1,#flatBoard) == flatBoard then
            -- find first empty in the next move
            for i = 1, COLS*ROWS do
                if flatBoard:sub(i,i) == "." and key:sub(i,i) ~= "." then
                    local col = math.ceil(i/ROWS)
                    return col
                end
            end
        end
    end
    return nil
end

-- Main bot function
function getBestMove(board)
    local flat = flattenBoard(board)
    -- Try OpeningBook first
    local move = findNextMoveInBook(flat)
    if move then return move end
    -- fallback: minimax depth 5 (adjustable)
    local _, bestCol = minimax(board, 5, -math.huge, math.huge, true)
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
				{ "","","","","","" }, -- column 1 
				{ "","","","","","" }, -- column 2 
				{ "","","","","","" }, -- column 3 
				{ "","","","","","" }, -- column 4 
				{ "","","","","","" }, -- column 5 
				{ "","","","","","" }, -- column 6 
				{ "","","","","","" }, -- column 7 
			}

			for _, child in pairs(balls_container:GetChildren()) do --fills the board with the current board status
				--the child name would look like this for example "_12" where 1 is the col number
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
