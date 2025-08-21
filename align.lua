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
local bit32 = bit32
local ROWS, COLS = 6, 7
local BOT = "r"
local OPP = "b"
local MAX_DEPTH = 24 -- adjust for performance

-- Initialize board structure
local function copyBoard(board)
    local newBoard = { red = {}, blue = {} }
    for c = 1, COLS do
        newBoard.red[c] = board.red[c]
        newBoard.blue[c] = board.blue[c]
    end
    return newBoard
end

-- Drop piece in a column
local function dropPiece(board, col, mark)
    for row = 0, ROWS-1 do
        local mask = 2^row
        if bit32.band(board.red[col] + board.blue[col], mask) == 0 then
            if mark == BOT then
                board.red[col] = board.red[col] + mask
            else
                board.blue[col] = board.blue[col] + mask
            end
            return true
        end
    end
    return false -- column full
end

-- Check if a cell is occupied by a player
local function isCell(board, row, col, mark)
    local mask = 2^(row-1)
    if mark == BOT then
        return bit32.band(board.red[col], mask) ~= 0
    else
        return bit32.band(board.blue[col], mask) ~= 0
    end
end

-- Check for win
local function checkWin(board, mark)
    -- horizontal
    for r = 1, ROWS do
        for c = 1, COLS-3 do
            if isCell(board,r,c,mark) and isCell(board,r,c+1,mark) and isCell(board,r,c+2,mark) and isCell(board,r,c+3,mark) then
                return true
            end
        end
    end
    -- vertical
    for c = 1, COLS do
        for r = 1, ROWS-3 do
            if isCell(board,r,c,mark) and isCell(board,r+1,c,mark) and isCell(board,r+2,c,mark) and isCell(board,r+3,c,mark) then
                return true
            end
        end
    end
    -- diagonal /
    for r = 1, ROWS-3 do
        for c = 1, COLS-3 do
            if isCell(board,r,c,mark) and isCell(board,r+1,c+1,mark) and isCell(board,r+2,c+2,mark) and isCell(board,r+3,c+3,mark) then
                return true
            end
        end
    end
    -- diagonal \
    for r = 4, ROWS do
        for c = 1, COLS-3 do
            if isCell(board,r,c,mark) and isCell(board,r-1,c+1,mark) and isCell(board,r-2,c+2,mark) and isCell(board,r-3,c+3,mark) then
                return true
            end
        end
    end
    return false
end

-- Score position for BOT
local function scorePosition(board)
    local score = 0
    -- simple heuristic: count 2/3 in a row
    local function evalWindow(r,c,dr,dc)
        local countBot, countOpp, countEmpty = 0,0,0
        for i=0,3 do
            local row,col = r+dr*i, c+dc*i
            if row < 1 or row > ROWS or col < 1 or col > COLS then return 0 end
            if isCell(board,row,col,BOT) then countBot=countBot+1
            elseif isCell(board,row,col,OPP) then countOpp=countOpp+1
            else countEmpty=countEmpty+1 end
        end
        local s=0
        if countBot==4 then s=1000
        elseif countBot==3 and countEmpty==1 then s=10
        elseif countBot==2 and countEmpty==2 then s=5 end
        if countOpp==3 and countEmpty==1 then s=s-80 end -- block opponent
        return s
    end

    -- horizontal
    for r=1,ROWS do
        for c=1,COLS-3 do score = score + evalWindow(r,c,0,1) end
    end
    -- vertical
    for r=1,ROWS-3 do
        for c=1,COLS do score = score + evalWindow(r,c,1,0) end
    end
    -- diagonal /
    for r=1,ROWS-3 do
        for c=1,COLS-3 do score = score + evalWindow(r,c,1,1) end
    end
    -- diagonal \
    for r=4,ROWS do
        for c=1,COLS-3 do score = score + evalWindow(r,c,-1,1) end
    end
    return score
end

-- Return valid columns
local function getValidCols(board)
    local valid = {}
    for c=1,COLS do
        if board.red[c] + board.blue[c] < 2^ROWS then
            table.insert(valid,c)
        end
    end
    return valid
end

-- Minimax with alpha-beta
local function minimax(board, depth, alpha, beta, maximizing)
    local validCols = getValidCols(board)
    local terminal = checkWin(board,BOT) or checkWin(board,OPP) or #validCols==0
    if depth==0 or terminal then
        if terminal then
            if checkWin(board,BOT) then return nil, 10000 end
            if checkWin(board,OPP) then return nil, -10000 end
            return nil, 0
        else
            return nil, scorePosition(board)
        end
    end

    if maximizing then
        local value = -math.huge
        local bestCol = validCols[1]
        for _, col in ipairs(validCols) do
            local newBoard = copyBoard(board)
            dropPiece(newBoard,col,BOT)
            local _, newScore = minimax(newBoard,depth-1,alpha,beta,false)
            if newScore > value then
                value = newScore
                bestCol = col
            end
            alpha = math.max(alpha,value)
            if alpha >= beta then break end
        end
        return bestCol, value
    else
        local value = math.huge
        local bestCol = validCols[1]
        for _, col in ipairs(validCols) do
            local newBoard = copyBoard(board)
            dropPiece(newBoard,col,OPP)
            local _, newScore = minimax(newBoard,depth-1,alpha,beta,true)
            if newScore < value then
                value = newScore
                bestCol = col
            end
            beta = math.min(beta,value)
            if alpha >= beta then break end
        end
        return bestCol, value
    end
end

-- Main function
function getBestMove(inputBoard)
    -- convert 2D array input to bit32 column representation
    local board = { red={}, blue={} }
    for c=1,COLS do board.red[c]=0; board.blue[c]=0 end
    for r=1,ROWS do
        for c=1,COLS do
            local val = inputBoard[r][c]
            local mask = 2^(r-1)
            if val=="r" then board.red[c] = board.red[c] + mask
            elseif val=="b" then board.blue[c] = board.blue[c] + mask end
        end
    end

    local bestCol,_ = minimax(board,MAX_DEPTH,-math.huge,math.huge,true)
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



