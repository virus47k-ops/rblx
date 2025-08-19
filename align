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
local arenas_fldr = workspace.ArenasREAL

local balls_container --where the balls are added container


--[[
for i = 11, 76 do
    ball_poses[i] = .Position
end
]]

local battle_results = plr_gui.BattleResults["Middle Middle"]

local is_in_game = false


------------------------// Align ai stuff //------------------------
-- BOT is always red
local botMark = "r"
local oppMark = "b"
local ROWS, COLS = 6, 7

-- Check if a move is valid
local function isValidMove(board, col)
    return board[col][ROWS] == ""
end

-- Get the next empty row in a column
local function getNextRow(board, col)
    for r = 1, ROWS do
        if board[col][r] == "" then
            return r
        end
    end
    return nil
end

-- Drop a piece
local function makeMove(board, col, mark)
    local row = getNextRow(board, col)
    if row then
        board[col][row] = mark
        return row
    end
    return nil
end

-- Undo a move
local function undoMove(board, col)
    for r = ROWS, 1, -1 do
        if board[col][r] ~= "" then
            board[col][r] = ""
            break
        end
    end
end

-- Check for a win
local function checkWinner(board, mark)
    -- horizontal
    for r = 1, ROWS do
        for c = 1, COLS-3 do
            if board[c][r]==mark and board[c+1][r]==mark and board[c+2][r]==mark and board[c+3][r]==mark then
                return true
            end
        end
    end
    -- vertical
    for c = 1, COLS do
        for r = 1, ROWS-3 do
            if board[c][r]==mark and board[c][r+1]==mark and board[c][r+2]==mark and board[c][r+3]==mark then
                return true
            end
        end
    end
    -- diagonal /
    for r = 1, ROWS-3 do
        for c = 1, COLS-3 do
            if board[c][r]==mark and board[c+1][r+1]==mark and board[c+2][r+2]==mark and board[c+3][r+3]==mark then
                return true
            end
        end
    end
    -- diagonal \
    for r = 4, ROWS do
        for c = 1, COLS-3 do
            if board[c][r]==mark and board[c+1][r-1]==mark and board[c+2][r-2]==mark and board[c+3][r-3]==mark then
                return true
            end
        end
    end
    return false
end

-- Check if the board is full
local function isBoardFull(board)
    for c = 1, COLS do
        if isValidMove(board, c) then return false end
    end
    return true
end

-- Minimax with alpha-beta pruning (search until terminal state)
local function minimax(board, maximizingPlayer, alpha, beta)
    if checkWinner(board, botMark) then return nil, 1000000 end
    if checkWinner(board, oppMark) then return nil, -1000000 end
    if isBoardFull(board) then return nil, 0 end

    local validCols = {}
    for c = 1, COLS do
        if isValidMove(board, c) then table.insert(validCols, c) end
    end

    local bestCol = validCols[1]
    if maximizingPlayer then
        local value = -math.huge
        for _, col in ipairs(validCols) do
            makeMove(board, col, botMark)
            local _, score = minimax(board, false, alpha, beta)
            undoMove(board, col)
            if score > value then
                value = score
                bestCol = col
            end
            alpha = math.max(alpha, value)
            if alpha >= beta then break end
        end
        return bestCol, value
    else
        local value = math.huge
        for _, col in ipairs(validCols) do
            makeMove(board, col, oppMark)
            local _, score = minimax(board, true, alpha, beta)
            undoMove(board, col)
            if score < value then
                value = score
                bestCol = col
            end
            beta = math.min(beta, value)
            if alpha >= beta then break end
        end
        return bestCol, value
    end
end

-- Main function to get the best move
function getBestMove(board)
    local col, _ = minimax(board, true, -math.huge, math.huge)
    return col
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
                    if _arena.ArenaTemplate then
                        if _arena.ArenaTemplate.Red.Character.Nametag.Frame.Nickname.Text == "@" .. plr.Name then
                            balls_container = _arena.ArenaTemplate.Important.Balls
                        end
                    end
                end
            end

            local btns = ui.Buttons

            local board = {}
            for col = 1, 7 do
                board[col] = {}
                for row = 1, 6 do
                    board[col][row] = ""
                end
            end
            
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

        label.Text = tonumber(label.Text)+1

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
