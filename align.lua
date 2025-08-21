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

-- Returns the best column for "r" to play
function getBestMove(board)
    local ROWS, COLS = 6, 7
    local BOT = "r"
    local OPP = "b"
    local MAX_DEPTH = 8 -- depth can be 4 for speed, higher = stronger
    
    -- Check if someone has won
    local function checkWin(b, mark)
        for r = 1, ROWS do
            for c = 1, COLS do
                if c+3 <= COLS and b[r][c] == mark and b[r][c+1] == mark and b[r][c+2] == mark and b[r][c+3] == mark then
                    return true
                end
                if r+3 <= ROWS and b[r][c] == mark and b[r+1][c] == mark and b[r+2][c] == mark and b[r+3][c] == mark then
                    return true
                end
                if r+3 <= ROWS and c+3 <= COLS and b[r][c] == mark and b[r+1][c+1] == mark and b[r+2][c+2] == mark and b[r+3][c+3] == mark then
                    return true
                end
                if r+3 <= ROWS and c-3 >= 1 and b[r][c] == mark and b[r+1][c-1] == mark and b[r+2][c-2] == mark and b[r+3][c-3] == mark then
                    return true
                end
            end
        end
        return false
    end

    -- Score board for BOT
    local function evaluateWindow(window, mark)
        local score = 0
        local oppMark = mark == BOT and OPP or BOT
        local countMark, countEmpty, countOpp = 0, 0, 0
        for _, cell in ipairs(window) do
            if cell == mark then countMark = countMark + 1
            elseif cell == "" then countEmpty = countEmpty + 1
            else countOpp = countOpp + 1 end
        end

        if countMark == 4 then
            score = 1000
        elseif countMark == 3 and countEmpty == 1 then
            score = 10
        elseif countMark == 2 and countEmpty == 2 then
            score = 5
        end

        if countOpp == 3 and countEmpty == 1 then
            score = score - 80 -- block opponent
        end

        return score
    end

    local function scorePosition(b, mark)
        local score = 0
        -- Horizontal
        for r = 1, ROWS do
            for c = 1, COLS-3 do
                local window = {b[r][c], b[r][c+1], b[r][c+2], b[r][c+3]}
                score = score + evaluateWindow(window, mark)
            end
        end
        -- Vertical
        for c = 1, COLS do
            for r = 1, ROWS-3 do
                local window = {b[r][c], b[r+1][c], b[r+2][c], b[r+3][c]}
                score = score + evaluateWindow(window, mark)
            end
        end
        -- Diagonal /
        for r = 1, ROWS-3 do
            for c = 1, COLS-3 do
                local window = {b[r][c], b[r+1][c+1], b[r+2][c+2], b[r+3][c+3]}
                score = score + evaluateWindow(window, mark)
            end
        end
        -- Diagonal \
        for r = 4, ROWS do
            for c = 1, COLS-3 do
                local window = {b[r][c], b[r-1][c+1], b[r-2][c+2], b[r-3][c+3]}
                score = score + evaluateWindow(window, mark)
            end
        end
        return score
    end

    -- Return valid columns
    local function getValidCols(b)
        local valid = {}
        for c = 1, COLS do
            if b[1][c] == "" then
                table.insert(valid, c)
            end
        end
        return valid
    end

    -- Drop piece in column
    local function dropPiece(b, col, mark)
        local newBoard = {}
        for r = 1, ROWS do
            newBoard[r] = {}
            for c = 1, COLS do
                newBoard[r][c] = b[r][c]
            end
        end
        for r = ROWS, 1, -1 do
            if newBoard[r][col] == "" then
                newBoard[r][col] = mark
                break
            end
        end
        return newBoard
    end

    -- Minimax with alpha-beta pruning
    local function minimax(b, depth, alpha, beta, maximizingPlayer)
        local validCols = getValidCols(b)
        local terminal = checkWin(b, BOT) or checkWin(b, OPP) or #validCols == 0
        if depth == 0 or terminal then
            if terminal then
                if checkWin(b, BOT) then return nil, 10000 end
                if checkWin(b, OPP) then return nil, -10000 end
                return nil, 0
            else
                return nil, scorePosition(b, BOT)
            end
        end

        if maximizingPlayer then
            local value = -math.huge
            local bestCol = validCols[1]
            for _, col in ipairs(validCols) do
                local newBoard = dropPiece(b, col, BOT)
                local _, newScore = minimax(newBoard, depth-1, alpha, beta, false)
                if newScore > value then
                    value = newScore
                    bestCol = col
                end
                alpha = math.max(alpha, value)
                if alpha >= beta then break end
            end
            return bestCol, value
        else
            local value = math.huge
            local bestCol = validCols[1]
            for _, col in ipairs(validCols) do
                local newBoard = dropPiece(b, col, OPP)
                local _, newScore = minimax(newBoard, depth-1, alpha, beta, true)
                if newScore < value then
                    value = newScore
                    bestCol = col
                end
                beta = math.min(beta, value)
                if alpha >= beta then break end
            end
            return bestCol, value
        end
    end

    local bestCol, _ = minimax(board, MAX_DEPTH, -math.huge, math.huge, true)
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
