--[[
    ⚡ BOLT HUB v7.4 — ULTIMATE CATALOG BUILD ⚡
    • Scream and Run tab removed
    • Universal hubs expanded (Shiro, Galaxy, ROXCOM, ZHub, Plenum, 67Hub)
    • Game-specific hubs expanded (Blox Fruits, MM2, Da Hood, Arsenal, Jailbreak, RIVALS)
    • Launch notifications silenced
]]

-- ─── Services ───
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UIS                = game:GetService("UserInputService")
local Lighting           = game:GetService("Lighting")
local TweenService       = game:GetService("TweenService")
local Debris             = game:GetService("Debris")
local StarterGui         = game:GetService("StarterGui")
local TextChatService    = game:GetService("TextChatService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualUser        = game:GetService("VirtualUser")
local VirtualInput       = game:GetService("VirtualInputManager")
local MarketplaceService = game:GetService("MarketplaceService")

local LP     = Players.LocalPlayer
local Mouse  = LP:GetMouse()
local Camera = workspace.CurrentCamera

-- ─── Globals / Fallbacks ───
local genv          = getgenv and getgenv() or _G
local gethui        = gethui or function() return game:GetService("CoreGui") end
local setclipboard  = setclipboard or toclipboard or function() end
local getrawmt      = getrawmetatable or (debug and debug.getmetatable)
local setro         = setreadonly or make_writeable or function() end
local newc          = newcclosure or function(f) return f end
local unpack        = table.unpack or unpack
local identify      = identifyexecutor or function() return "Unknown" end

-- ─── Wipe previous instance if re-executed ───
if genv.BoltHub then pcall(function() genv.BoltHub:Destroy() end) genv.BoltHub = nil end
if genv.BoltIcon then pcall(function() genv.BoltIcon:Destroy() end) genv.BoltIcon = nil end
if genv.BoltNetAdd then pcall(function() genv.BoltNetAdd:Disconnect() end) genv.BoltNetAdd = nil end
if genv.BoltNetTimer then pcall(function() task.cancel(genv.BoltNetTimer) end) genv.BoltNetTimer = nil end

-- ─── Capability Scanner ───
local CAP = {}
local PRUNED = {}
local function cap(name)
    local ok, v = pcall(function()
        local g = genv[name]
        if g ~= nil then return g end
        return _G[name]
    end)
    if ok and v ~= nil and type(v) == "function" then
        CAP[name] = true; return true
    end
    CAP[name] = false; return false
end
local function scanCapabilities()
    for _, n in ipairs({
        "getgenv", "gethui", "getrawmetatable", "setreadonly",
        "newcclosure", "hookfunction", "hookmetamethod",
        "getnamecallmethod", "replicatesignal", "firesignal",
        "cloneref", "setfpscap", "identifyexecutor",
        "isexecutorclosure", "checkcaller", "setclipboard",
        "getconnections", "firetouchinterest", "getgc",
        "getreg", "getloadedmodules", "request", "httpget",
    }) do cap(n) end
end
scanCapabilities()

local function need(...)
    for _, d in ipairs({ ... }) do
        if not CAP[d] then return false, d end
    end
    return true
end

local function registerFeature(name, deps, fn)
    if deps and #deps > 0 then
        local ok, missing = need(unpack(deps))
        if not ok then
            table.insert(PRUNED, { name = name, missing = missing }); return false
        end
    end
    if type(fn) == "function" then pcall(fn) end
    return true
end

local function reportPruned()
    if #PRUNED == 0 then
        print("[BOLT] All features supported. No pruning needed."); return
    end
    local lines = { "[BOLT] PRUNED FEATURES (" .. #PRUNED .. "):" }
    for _, p in ipairs(PRUNED) do
        table.insert(lines, "  · " .. p.name .. " — missing: " .. tostring(p.missing))
    end
    local msg = table.concat(lines, "\n")
    print(msg); pcall(function() warn(msg) end)
end

-- ══════════════════════════════════════════════
--   KEY BYPASS + HUB LOADER
-- ══════════════════════════════════════════════
local KeyBypass = {
    enabled = true,
    dummyKey = "bolt-free-key-bypass-111111111111111111111",
}

local function setupKeyEnvironment()
    if not KeyBypass.enabled then return end
    local k = KeyBypass.dummyKey
    for _, name in ipairs({ "Key", "key", "KEY", "KeySystem", "keysystem", "KeySystemKey" }) do
        pcall(function() genv[name] = k end)
        pcall(function() _G[name] = k end)
        pcall(function() shared[name] = k end)
    end
    if writefile then
        local content = k .. "\nfree\nbolt\nkeyless\n"
        for _, f in ipairs({ "key.txt", "key", "keysystem.txt", "key_system.txt",
            "bloxfruitskey.txt", "mm2key.txt", "dahoodkey.txt", "hubkey.txt", "bolt_key.txt" }) do
            pcall(function() writefile(f, content) end)
        end
    end
end

local function loadHub(url, opts)
    setupKeyEnvironment()
    local ok, res = pcall(function() return loadstring(game:HttpGet(url, opts))() end)
    if not ok then pcall(function() warn("[BOLT] Hub load failed: " .. tostring(res)) end) end
    return ok
end

-- ─── Palette ───
local BG      = Color3.fromRGB(10, 10, 10)
local PANEL   = Color3.fromRGB(14, 14, 15)
local CARD    = Color3.fromRGB(21, 21, 23)
local CARD_H  = Color3.fromRGB(30, 30, 33)
local EDGE    = Color3.fromRGB(30, 30, 34)
local EDGE_H  = Color3.fromRGB(52, 52, 58)
local GOLD    = Color3.fromRGB(255, 200, 40)
local GOLD_H  = Color3.fromRGB(255, 224, 110)
local TX      = Color3.fromRGB(240, 240, 242)
local TX_DIM  = Color3.fromRGB(130, 130, 138)
local TX_MUT  = Color3.fromRGB(76, 76, 82)
local RED     = Color3.fromRGB(255, 90, 90)
local GREEN   = Color3.fromRGB(74, 222, 128)
local BLACK   = Color3.fromRGB(0, 0, 0)

-- ─── UI Utilities ───
local function C(c, p)
    local o = Instance.new(c)
    for k, v in pairs(p) do o[k] = v end
    return o
end
local function Cor(p, r) return C("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = p }) end
local function Stroke(p, c, t, tr)
    return C("UIStroke", { Color = c or EDGE, Thickness = t or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
end
local function Tw(o, t, p)
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
    tw:Play(); return tw
end
local function Pad(p, t, r, b, l)
    return C("UIPadding", { PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0), Parent = p })
end

-- ─── Notifications (silent on launch) ───
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "BOLT", Text = text or "", Duration = dur or 3
        })
    end)
end

-- ─── Char Helpers ───
local function GetChar() return LP.Character end
local function GetHRP(c) c = c or GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum(c) c = c or GetChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function AllPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p) end end
    return t
end
local function SafeNO(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function() if not part.Anchored then part:SetNetworkOwner(LP) end end)
end

-- ══════════════════════════════════════════════
--   FORCE STATS
-- ══════════════════════════════════════════════
local ForceStats = {
    enabled = false, walkSpeed = 100, jumpPower = 100, hipHeight = 2, conn = nil,
}

local function startForceStats()
    if ForceStats.conn then ForceStats.conn:Disconnect() end
    ForceStats.enabled = true
    ForceStats.conn = RunService.Heartbeat:Connect(function()
        local h = GetHum()
        if not h then return end
        if h.WalkSpeed ~= ForceStats.walkSpeed then h.WalkSpeed = ForceStats.walkSpeed end
        if h.JumpPower ~= ForceStats.jumpPower then h.JumpPower = ForceStats.jumpPower end
        if h.HipHeight ~= ForceStats.hipHeight then h.HipHeight = ForceStats.hipHeight end
    end)
end

local function stopForceStats()
    ForceStats.enabled = false
    if ForceStats.conn then ForceStats.conn:Disconnect(); ForceStats.conn = nil end
end

-- ══════════════════════════════════════════════
--   AUTO NETWORK OWNERSHIP
-- ══════════════════════════════════════════════
local AutoNet = { enabled = true, claimedCount = 0 }

local function claimPart(part)
    if not AutoNet.enabled then return false end
    if not part or not part:IsA("BasePart") or part.Anchored then return false end
    local ok = pcall(function() part:SetNetworkOwner(LP) end)
    if ok then AutoNet.claimedCount = AutoNet.claimedCount + 1 end
    return ok
end

local function sweepWorkspace()
    if not AutoNet.enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            pcall(function() obj:SetNetworkOwner(LP) end)
        end
    end
end

local function installAutoNetwork()
    if genv.BoltAutoNet then return end
    genv.BoltAutoNet = true
    task.spawn(sweepWorkspace)
    genv.BoltNetAdd = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and not obj.Anchored then task.defer(function() claimPart(obj) end) end
    end)
    LP.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and not d.Anchored then
                pcall(function() d:SetNetworkOwner(LP) end)
            end
        end
    end)
    genv.BoltNetTimer = task.spawn(function()
        while AutoNet.enabled do task.wait(10); pcall(sweepWorkspace) end
    end)
end

local function disableAutoNetwork()
    AutoNet.enabled = false
    if genv.BoltNetAdd then pcall(function() genv.BoltNetAdd:Disconnect() end) genv.BoltNetAdd = nil end
    if genv.BoltNetTimer then pcall(function() task.cancel(genv.BoltNetTimer) end) genv.BoltNetTimer = nil end
    genv.BoltAutoNet = false
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            pcall(function() obj:SetNetworkOwner(nil) end)
        end
    end
end

local function enableAutoNetwork()
    AutoNet.enabled = true; AutoNet.claimedCount = 0; installAutoNetwork()
end

-- ══════════════════════════════════════════════
--   BOLT SHAPE
-- ══════════════════════════════════════════════
local BOLT_ROWS = {
    {6, 11}, {5, 10}, {4, 9}, {3, 8}, {2, 7},
    {3, 9}, {2, 8}, {1, 7}, {0, 6}, {0, 3}, {0, 1},
}
local function drawBolt(parent, size)
    local rows = #BOLT_ROWS
    local cell = size / rows
    local colW = size / 12
    local Bolt = C("Frame", {
        Size = UDim2.new(0, size, 0, size),
        Position = UDim2.new(0.5, -size/2, 0.5, -size/2),
        BackgroundTransparency = 1, Parent = parent
    })
    for i, r in ipairs(BOLT_ROWS) do
        local c0, c1 = r[1], r[2]
        local w = (c1 - c0 + 1) * colW
        C("Frame", {
            Size = UDim2.new(0, w, 0, cell + 0.6),
            Position = UDim2.new(0, c0 * colW, 0, (i - 1) * cell),
            BackgroundColor3 = BLACK, BorderSizePixel = 0, Parent = Bolt
        })
    end
end

-- ══════════════════════════════════════════════
--   FAKER ENGINE
-- ══════════════════════════════════════════════
local FakeData = {
    gamepasses = {}, products = {}, seen = {}, listeners = {},
    globalOn = false, autoFake = false, hookedMP = false,
}

local function fetchProductInfo(id, isGamepass)
    local infoType = isGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, infoType) end)
    if ok and info and type(info) == "table" then
        return info.Name or ("Unknown " .. (isGamepass and "Gamepass" or "Product")), info.PriceInRobux
    end
    return "Unknown " .. (isGamepass and "Gamepass" or "Product"), nil
end

local function addFakeEntry(tbl, id, name, source, isGamepass)
    id = tonumber(id)
    if not id or id < 1e5 or id > 1e13 then return end
    local key = (isGamepass and "gpass:" or "prod:") .. tostring(id)
    if FakeData.seen[key] then return end
    FakeData.seen[key] = true
    local displayName, price = name, nil
    if not displayName or displayName == "Prompt" or displayName == "Check"
       or displayName == "Info" or displayName == "Remote" then
        displayName, price = fetchProductInfo(id, isGamepass)
    end
    local entry = {
        id = id, name = displayName or ("Unknown " .. (isGamepass and "Gamepass" or "Product")),
        price = price, source = source or "?", isGamepass = isGamepass,
    }
    table.insert(tbl, entry)
    notify("SCAN", (isGamepass and "Gamepass" or "Product") .. " " .. id .. " · " .. entry.name)
    for _, fn in ipairs(FakeData.listeners) do pcall(fn, entry) end
    if FakeData.autoFake then
        task.spawn(function()
            if isGamepass then _G.BoltFakePurchase(id, nil) else _G.BoltFakePurchase(nil, id) end
        end)
    end
end

local function fakePurchase(gamepassId, productId)
    local firedCount = 0
    if gamepassId then
        gamepassId = tonumber(gamepassId); if not gamepassId then return false end
        local function blast()
            if CAP.replicatesignal then
                pcall(function()
                    replicatesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP, gamepassId, true)
                    firedCount = firedCount + 1
                end)
                pcall(function()
                    replicatesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP.UserId, gamepassId, true)
                end)
                pcall(function()
                    replicatesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP, gamepassId)
                end)
            end
            pcall(function() MarketplaceService:SignalPromptGamePassPurchaseFinished(LP.UserId, gamepassId, true) end)
            if CAP.firesignal then
                pcall(function()
                    firesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP, gamepassId, true)
                end)
            end
        end
        blast(); task.delay(0.05, blast); task.delay(0.2, blast)
        task.delay(0.5, blast); task.delay(1.0, blast)
        notify("FAKE", "Blast fired " .. firedCount .. "× for gamepass " .. gamepassId)
        return true
    end
    if productId then
        productId = tonumber(productId); if not productId then return false end
        local function blast()
            if CAP.replicatesignal then
                pcall(function()
                    replicatesignal(MarketplaceService.PromptProductPurchaseFinished, LP.UserId, productId, true)
                    firedCount = firedCount + 1
                end)
                pcall(function()
                    replicatesignal(MarketplaceService.PromptProductPurchaseFinished, LP, productId, true)
                end)
            end
            pcall(function() MarketplaceService:SignalPromptProductPurchaseFinished(LP.UserId, productId, true) end)
            if CAP.firesignal then
                pcall(function()
                    firesignal(MarketplaceService.PromptProductPurchaseFinished, LP.UserId, productId, true)
                end)
            end
            if CAP.replicatesignal then
                pcall(function() replicatesignal(MarketplaceService.PromptPurchaseFinished, LP, productId, true) end)
            end
        end
        blast(); task.delay(0.05, blast); task.delay(0.2, blast)
        task.delay(0.5, blast); task.delay(1.0, blast)
        notify("FAKE", "Blast fired " .. firedCount .. "× for product " .. productId)
        return true
    end
    return false
end
_G.BoltFakePurchase = fakePurchase

local function installMarketplaceHooks()
    if FakeData.hookedMP or not CAP.getrawmetatable then return end
    FakeData.hookedMP = true
    local mt = getrawmt(MarketplaceService); if not mt then return end
    local oldIdx = mt.__index; local oldNC = mt.__namecall
    pcall(function() setro(mt, false) end)
    mt.__index = newc(function(self, key)
        if key == "ProcessReceipt" and FakeData.globalOn then
            return function() return Enum.ProductPurchaseDecision.PurchaseGranted end
        end
        if oldIdx then return oldIdx(self, key) end
    end)
    mt.__namecall = newc(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        local args = { ... }
        if method == "UserOwnsGamePassAsync" then
            if FakeData.globalOn then return true end
            local id = args[2] or args[1]
            if id then for _, e in ipairs(FakeData.gamepasses) do if e.id == id then return true end end end
        end
        if method == "PlayerOwnsAsset" or method == "OwnsAsset" then
            if FakeData.globalOn then return true end
            local id = args[2] or args[1]
            if id then
                for _, e in ipairs(FakeData.gamepasses) do if e.id == id then return true end end
                for _, e in ipairs(FakeData.products) do if e.id == id then return true end end
            end
        end
        return oldNC and oldNC(self, ...) or nil
    end)
    pcall(function() setro(mt, true) end)
end

local function installDetectionHooks()
    if genv.BoltDetectHooks or not CAP.getrawmetatable then return end
    genv.BoltDetectHooks = true
    local mt = getrawmt(game); if not mt then return end
    local old = mt.__namecall
    pcall(function() setro(mt, false) end)
    mt.__namecall = newc(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        local args = { ... }
        if method == "PromptGamePassPurchase" then
            addFakeEntry(FakeData.gamepasses, args[2] or args[1], nil, "Prompt", true)
        elseif method == "PromptProductPurchase" then
            addFakeEntry(FakeData.products, args[2] or args[1], nil, "Prompt", false)
        elseif method == "UserOwnsGamePassAsync" then
            addFakeEntry(FakeData.gamepasses, args[2] or args[1], nil, "Check", true)
        end
        return old(self, ...)
    end)
    pcall(function() setro(mt, true) end)
end

-- ══════════════════════════════════════════════
--   UNIVERSAL AC SHIELD
-- ══════════════════════════════════════════════
local function installUniversalShield()
    if genv.BoltShield then return end
    if not CAP.getrawmetatable or not CAP.newcclosure then
        table.insert(PRUNED, { name = "Universal AC Shield", missing = "getrawmetatable/newcclosure" }); return
    end
    genv.BoltShield = true
    local blockedMethods = { Kick = true, Ban = true, Destroy = true,
        Detected = true, IsBanned = true, CheckBan = true,
        Banned = true, SetSetting = true, SetFlag = true }
    local blockedPrefixes = { "adonis", "ad0nis", "kick", "ban", "detect", "flag" }
    local mt = getrawmt(game); if not mt then return end
    local oldNC = mt.__namecall; local oldIdx = mt.__index; local oldNew = mt.__newindex
    pcall(function() setro(mt, false) end)
    mt.__namecall = newc(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if blockedMethods[method] then return end
        local low = method:lower()
        for _, p in ipairs(blockedPrefixes) do if low:sub(1, #p) == p then return end end
        if method == "UserOwnsGamePassAsync" or method == "PlayerOwnsAsset" then
            if genv.BoltGlobalFake then return true end
        end
        return oldNC(self, ...)
    end)
    mt.__index = newc(function(self, key)
        if key == "ProcessReceipt" and genv.BoltGlobalFake then
            return function() return Enum.ProductPurchaseDecision.PurchaseGranted end
        end
        return oldIdx(self, key)
    end)
    mt.__newindex = newc(function(self, key, value)
        if type(key) == "string" then
            local low = key:lower()
            for _, p in ipairs({ "detected", "flagged", "banned", "cheat" }) do
                if low:find(p, 1, true) then return end
            end
        end
        return oldNew(self, key, value)
    end)
    pcall(function() setro(mt, true) end)
end

local function installDeltaClamp(studsPerFrame)
    if genv.BoltDeltaClamp then genv.BoltDeltaClamp:Disconnect() end
    local last = nil
    genv.BoltDeltaClamp = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        if last then
            local delta = (hrp.Position - last).Magnitude
            if delta > (studsPerFrame or 45) then
                hrp.CFrame = CFrame.new(last) * (hrp.CFrame - hrp.CFrame.Position)
            end
        end
        last = hrp.Position
    end)
end

local function installRemoteGuard()
    if genv.BoltRemoteGuard or not CAP.getrawmetatable then return end
    genv.BoltRemoteGuard = true
    local blacklist = { "kick", "ban", "detect", "flag", "cheat", "exploit" }
    local hooked = {}
    local function sanitize(v)
        if type(v) == "string" then
            local low = v:lower()
            for _, b in ipairs(blacklist) do
                if low:find(b, 1, true) then return "[filtered]" end
            end
        end
        return v
    end
    local function hookRemote(r)
        if hooked[r] then return end
        hooked[r] = true
        local mt = getrawmt(r); if not mt then return end
        local old = mt.__namecall
        pcall(function() setro(mt, false) end)
        mt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            if method == "FireServer" then
                local args = { ... }
                for i = 1, #args do args[i] = sanitize(args[i]) end
                return old(self, unpack(args))
            end
            return old(self, ...)
        end)
        pcall(function() setro(mt, true) end)
    end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") then hookRemote(d) end
    end
end

-- ══════════════════════════════════════════════
--   ACTIONS
-- ══════════════════════════════════════════════
local function Fling(target)
    if not target or not target.Character then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    SafeNO(tHRP)
    for _, d in ipairs(target.Character:GetDescendants()) do
        if d:IsA("Motor6D") and d.Name ~= "RootJoint" then pcall(function() d:Destroy() end) end
    end
    local bv = Instance.new("BodyVelocity", tHRP)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = (tHRP.CFrame.LookVector * 70) + Vector3.new(0, 50, 0)
    bv.P = 1250; Debris:AddItem(bv, 0.4)
    local av = Instance.new("BodyAngularVelocity", tHRP)
    av.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    av.AngularVelocity = Vector3.new(math.random(-60, 60), math.random(-60, 60), math.random(-60, 60))
    av.P = 1250; Debris:AddItem(av, 0.4)
end
local function FlingAll() for _, p in ipairs(AllPlayers()) do pcall(Fling, p) end end

local function Invisible(on)
    local c = GetChar() if not c then return end
    if on then
        if genv.BoltClone then pcall(function() genv.BoltClone:Destroy() end) end
        local clone = c:Clone(); clone.Name = LP.Name; clone.Parent = workspace
        genv.BoltClone = clone
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") then d.Transparency = 1 end
        end
    else
        if genv.BoltClone then pcall(function() genv.BoltClone:Destroy() end) genv.BoltClone = nil end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.Transparency = 0 end
        end
    end
end

local function Freeze(target)
    if not target or target == LP then
        local h = GetHum() if h then h.WalkSpeed = 0 h.JumpPower = 0 end
    else
        local c = target.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 0 h.JumpPower = 0 end
        end
    end
end
local function Thaw(target)
    if not target or target == LP then
        local h = GetHum() if h then h.WalkSpeed = 16 h.JumpPower = 50 end
    else
        local c = target.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 16 h.JumpPower = 50 end
        end
    end
end

local function Fly(on, speed)
    if genv.BoltFly then pcall(function() genv.BoltFly:Disconnect() end) genv.BoltFly = nil end
    if genv.BoltFlyBV then pcall(function() genv.BoltFlyBV:Destroy() end) genv.BoltFlyBV = nil end
    if not on then return end
    genv.BoltFlySpeed = speed or genv.BoltFlySpeed or 80
    local hrp = GetHRP() if not hrp then return end
    SafeNO(hrp)
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    genv.BoltFlyBV = bv
    genv.BoltFly = RunService.RenderStepped:Connect(function()
        if not bv or not bv.Parent then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        bv.Velocity = dir * (genv.BoltFlySpeed or 80)
    end)
end

local function Noclip(on)
    if genv.BoltNoclip then pcall(function() genv.BoltNoclip:Disconnect() end) genv.BoltNoclip = nil end
    if on then
        genv.BoltNoclip = RunService.Stepped:Connect(function()
            local c = GetChar() if not c then return end
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then d.CanCollide = false end
            end
        end)
    end
end

local function Ragdoll()
    local c = GetChar() if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("Motor6D") then
            local a = Instance.new("Attachment", d.Part0)
            local b = Instance.new("Attachment", d.Part1)
            a.CFrame = d.C0; b.CFrame = d.C1
            local s = Instance.new("BallSocketConstraint", d.Part0)
            s.Attachment0 = a; s.Attachment1 = b
            s.LimitsEnabled = true; s.TwistLimitsEnabled = true
            d:Destroy()
        end
    end
end

local function SpinSelf(on)
    if genv.BoltSpin then pcall(function() genv.BoltSpin:Disconnect() end) genv.BoltSpin = nil end
    if on then
        genv.BoltSpin = RunService.Heartbeat:Connect(function(dt)
            local hrp = GetHRP() if not hrp then return end
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(dt * 360), 0)
        end)
    end
end
local function SpinAll(on)
    if genv.BoltSpinAll then pcall(function() genv.BoltSpinAll:Disconnect() end) genv.BoltSpinAll = nil end
    if on then
        genv.BoltSpinAll = RunService.Heartbeat:Connect(function(dt)
            for _, p in ipairs(AllPlayers()) do
                if p.Character then
                    local h = p.Character:FindFirstChild("HumanoidRootPart")
                    if h then pcall(function() h.CFrame = h.CFrame * CFrame.Angles(0, math.rad(dt * 360), 0) end) end
                end
            end
        end)
    end
end

local function SoundSpam(id, dur)
    local hrp = GetHRP() if not hrp then return end
    for i = 1, 15 do
        local s = Instance.new("Sound", hrp)
        s.SoundId = "rbxassetid://" .. tostring(id)
        s.Volume = 10; s.Playing = true
        Debris:AddItem(s, dur or 3)
    end
end

local function Headless()
    local c = GetChar() if not c then return end
    local h = c:FindFirstChild("Head")
    if h then
        local mesh = h:FindFirstChildOfClass("SpecialMesh")
        if mesh then mesh:Destroy() end
        for _, d in ipairs(h:GetChildren()) do if d:IsA("Decal") then d:Destroy() end end
    end
end

local function antiAfk(on)
    if genv.BoltAntiAfk then pcall(function() genv.BoltAntiAfk:Disconnect() end) genv.BoltAntiAfk = nil end
    if not on then return end
    genv.BoltAntiAfk = LP.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

local function lowGfx(on)
    if on then
        genv.BoltGfxStore = {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Smoke") or d:IsA("Fire")
               or d:IsA("Sparkles") or d:IsA("Trail") or d:IsA("Beam") then
                if d.Enabled then
                    table.insert(genv.BoltGfxStore, { obj = d, prop = "Enabled", val = true })
                    d.Enabled = false
                end
            elseif d:IsA("Decal") or d:IsA("Texture") then
                if d.Transparency < 1 then
                    table.insert(genv.BoltGfxStore, { obj = d, prop = "Transparency", val = d.Transparency })
                    d.Transparency = 1
                end
            elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                if d.Enabled then
                    table.insert(genv.BoltGfxStore, { obj = d, prop = "Enabled", val = true })
                    d.Enabled = false
                end
            end
        end
        genv.BoltGfxShadow = Lighting.GlobalShadows
        genv.BoltGfxFog = Lighting.FogEnd
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        if genv.BoltGfxStore then
            for _, e in ipairs(genv.BoltGfxStore) do
                pcall(function() if e.obj and e.obj.Parent then e.obj[e.prop] = e.val end end)
            end
            genv.BoltGfxStore = nil
        end
        Lighting.GlobalShadows = genv.BoltGfxShadow ~= false
        Lighting.FogEnd = genv.BoltGfxFog or 100000
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level10 end)
    end
end

local function loopFullbright(on)
    if genv.BoltFullbright then pcall(function() genv.BoltFullbright:Disconnect() end) genv.BoltFullbright = nil end
    if not on then return end
    genv.BoltFullbright = RunService.RenderStepped:Connect(function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 5
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
    end)
end

local function unlockThirdPerson()
    LP.CameraMaxZoomDistance = 128
    LP.CameraMinZoomDistance = 0.5
end

local function setShiftLock(state)
    if state == nil then state = not LP.DevEnableMouseLock end
    pcall(function() LP.DevEnableMouseLock = state end)
    pcall(function()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end)
end

local function godMode(on)
    if genv.BoltGod then pcall(function() genv.BoltGod:Disconnect() end) genv.BoltGod = nil end
    if not on then return end
    genv.BoltGod = RunService.Heartbeat:Connect(function()
        local h = GetHum() if h then h.Health = h.MaxHealth end
    end)
end

local function healthRegen(on)
    if genv.BoltRegen then pcall(function() genv.BoltRegen:Disconnect() end) genv.BoltRegen = nil end
    if not on then return end
    genv.BoltRegen = RunService.Heartbeat:Connect(function()
        local h = GetHum() if h and h.Health < h.MaxHealth then
            h.Health = math.min(h.MaxHealth, h.Health + 1)
        end
    end)
end

local function autoClicker(on, cps)
    if genv.BoltClick then pcall(function() genv.BoltClick:Disconnect() end) genv.BoltClick = nil end
    if not on then genv.BoltAutoClick = false return end
    genv.BoltCps = cps or genv.BoltCps or 10
    genv.BoltAutoClick = true
    task.spawn(function()
        while genv.BoltAutoClick do
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
            task.wait(1 / (genv.BoltCps or 10))
        end
    end)
end

local function followPlayer(name)
    if genv.BoltFollow then pcall(function() genv.BoltFollow:Disconnect() end) genv.BoltFollow = nil end
    if not name or name == "" then return end
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name:lower() then target = p break end
    end
    if not target then notify("BOLT", "Player not found") return end
    genv.BoltFollow = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP()
        local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if hrp and tHRP then hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, 5) end
    end)
end

local function spectate(name)
    if not name or name == "" then return end
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name:lower() then target = p break end
    end
    if not target then notify("BOLT", "Player not found") return end
    if target.Character then
        Camera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid")
    end
end

local function fpsUnlock()
    if CAP.setfpscap then
        pcall(function() setfpscap(1000) end)
        notify("BOLT", "FPS unlocked")
    else notify("BOLT", "setfpscap not supported") end
end

local function setScale(mult)
    local c = GetChar() if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            if not d:GetAttribute("BoltOrigSize") then d:SetAttribute("BoltOrigSize", d.Size) end
            d.Size = d:GetAttribute("BoltOrigSize") * mult
        end
    end
end

local function resetScale()
    local c = GetChar() if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then
            local orig = d:GetAttribute("BoltOrigSize")
            if orig then d.Size = orig end
        end
    end
end

-- ══════════════════════════════════════════════
--   UI
-- ══════════════════════════════════════════════
local SG = C("ScreenGui", {
    Name = "⚡BOLT HUB", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = gethui()
})
genv.BoltHub = SG

local WIN_W, WIN_H = 1080, 660
local M = C("Frame", {
    Name = "Window", Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = BG, BorderSizePixel = 0, ClipsDescendants = true, Parent = SG
})
Cor(M, 10); Stroke(M, EDGE, 1)

local TOP_H = 38
local Top = C("Frame", {
    Name = "Top", Size = UDim2.new(1, 0, 0, TOP_H),
    BackgroundColor3 = PANEL, BorderSizePixel = 0, Parent = M
})
C("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = EDGE, BorderSizePixel = 0, Parent = Top
})

local LogoTile = C("Frame", {
    Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 14, 0.5, -10),
    BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = Top
})
Cor(LogoTile, 5); drawBolt(LogoTile, 20)

C("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 42, 0, 0),
    BackgroundTransparency = 1, Text = "Bolt Hub v7.4",
    TextColor3 = TX, TextSize = 13, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Top
})

local dragging, dragStart, startPos = false, nil, nil
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = M.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        M.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function WinBtn(glyph, x, cb, danger, hoverColor)
    local b = C("TextButton", {
        Size = UDim2.new(0, 34, 1, 0), Position = UDim2.new(1, x, 0, 0),
        BackgroundColor3 = PANEL, BackgroundTransparency = 1,
        Text = glyph, TextColor3 = TX_DIM, TextSize = 13,
        Font = Enum.Font.Gotham, BorderSizePixel = 0,
        AutoButtonColor = false, Parent = Top
    })
    b.MouseEnter:Connect(function()
        Tw(b, .1, { BackgroundTransparency = 0, BackgroundColor3 = hoverColor or CARD_H })
        Tw(b, .1, { TextColor3 = danger and RED or TX })
    end)
    b.MouseLeave:Connect(function()
        Tw(b, .1, { BackgroundTransparency = 1 }); Tw(b, .1, { TextColor3 = TX_DIM })
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local IconGui = C("ScreenGui", {
    Name = "BoltIcon", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = gethui()
})
genv.BoltIcon = IconGui

local ICON_SIZE = 46
local Icon = C("Frame", {
    Name = "Icon", Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
    Position = UDim2.new(0, 24, 1, -70),
    BackgroundColor3 = GOLD, BorderSizePixel = 0,
    Visible = false, Parent = IconGui
})
Cor(Icon, 10); Stroke(Icon, BLACK, 1, 0.7); drawBolt(Icon, 34)

Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local ds = input.Position
        local sp = Icon.Position
        local moved = false
        local conn, endConn
        conn = UIS.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                local d = i.Position - ds
                if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then moved = true end
                Icon.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        endConn = UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                conn:Disconnect(); endConn:Disconnect()
                if not moved then M.Visible = true Icon.Visible = false end
            end
        end)
    end
end)
Icon.MouseEnter:Connect(function() Tw(Icon, .12, { BackgroundColor3 = GOLD_H }) end)
Icon.MouseLeave:Connect(function() Tw(Icon, .12, { BackgroundColor3 = GOLD }) end)

local function MinimizeToIcon() M.Visible = false; Icon.Visible = true end
local function RestoreFromIcon() M.Visible = true; Icon.Visible = false end

-- ══════════════════════════════════════════════
--   CLEANUP
-- ══════════════════════════════════════════════
local isClosed = false

local function Cleanup()
    if isClosed then return end
    isClosed = true

    if SG then pcall(function() SG.Enabled = false end) end
    if IconGui then pcall(function() IconGui.Enabled = false end) end

    local sgRef, icRef = SG, IconGui
    SG, IconGui = nil, nil
    genv.BoltHub = nil
    genv.BoltIcon = nil

    task.spawn(function()
        if sgRef then
            pcall(function() sgRef.Parent = nil end)
            pcall(function() sgRef:Destroy() end)
        end
        if icRef then
            pcall(function() icRef.Parent = nil end)
            pcall(function() icRef:Destroy() end)
        end

        pcall(function()
            for _, k in ipairs({
                "BoltFly", "BoltNoclip", "BoltSpin", "BoltSpinAll",
                "BoltFullbright", "BoltLagback", "BoltAntiAfk", "BoltGod", "BoltRegen",
                "BoltFollow", "BoltInfJump", "BoltDeltaClamp", "BoltClick",
            }) do
                local v = genv[k]
                if v then
                    pcall(function() v:Disconnect() end)
                    genv[k] = nil
                end
            end
        end)

        if genv.BoltFlyBV then
            pcall(function() genv.BoltFlyBV:Destroy() end)
            genv.BoltFlyBV = nil
        end

        if genv.BoltClone then
            pcall(function() genv.BoltClone:Destroy() end)
            genv.BoltClone = nil
        end

        if genv.BoltFlingAll then genv.BoltFlingAll = false end
        if genv.BoltAutoClick then genv.BoltAutoClick = false end

        if ForceStats.conn then
            pcall(function() ForceStats.conn:Disconnect() end)
            ForceStats.conn = nil
        end
        ForceStats.enabled = false

        pcall(disableAutoNetwork)
    end)
end

-- ─── Window buttons ───
WinBtn("—", -68, function() MinimizeToIcon() end)
WinBtn("×", -34, function() Cleanup() end, true, Color3.fromRGB(120, 30, 30))

-- ══════════════════════════════════════════════
--   SIDEBAR + CENTER + SCANNER PANEL
-- ══════════════════════════════════════════════
local SIDE_W = 200
local Left = C("Frame", {
    Size = UDim2.new(0, SIDE_W, 1, -(TOP_H + 22)),
    Position = UDim2.new(0, 0, 0, TOP_H),
    BackgroundColor3 = PANEL, BorderSizePixel = 0, Parent = M
})
C("Frame", {
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = EDGE, BorderSizePixel = 0, Parent = Left
})
C("TextLabel", {
    Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 18, 0, 18),
    BackgroundTransparency = 1, Text = "TABS",
    TextColor3 = TX_MUT, TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Left
})

local ScSide = C("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 40),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = GOLD, ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Left
})
C("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ScSide })
Pad(ScSide, 4, 8, 10, 8)
local SLay = ScSide:FindFirstChildOfClass("UIListLayout")
SLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScSide.CanvasSize = UDim2.new(0, 0, 0, SLay.AbsoluteContentSize.Y + 20)
end)

local RIGHT_W = 260
local Center = C("Frame", {
    Size = UDim2.new(1, -(SIDE_W + RIGHT_W), 1, -(TOP_H + 22)),
    Position = UDim2.new(0, SIDE_W, 0, TOP_H),
    BackgroundColor3 = BG, BorderSizePixel = 0, Parent = M
})

local Crumb = C("Frame", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = PANEL, BorderSizePixel = 0, Parent = Center
})
C("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = EDGE, BorderSizePixel = 0, Parent = Crumb
})
local CrumbActive = C("Frame", {
    Size = UDim2.new(0, 140, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Parent = Crumb
})
C("TextLabel", {
    Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1, Text = "⚡", TextColor3 = GOLD,
    TextSize = 11, Font = Enum.Font.GothamBold, Parent = CrumbActive
})
local CrumbLabel = C("TextLabel", {
    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 22, 0, 0),
    BackgroundTransparency = 1, Text = "Main",
    TextColor3 = TX, TextSize = 12, Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = CrumbActive
})
C("Frame", {
    Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
    BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = CrumbActive
})

local SearchWrap = C("Frame", {
    Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0, 46),
    BackgroundColor3 = CARD, BorderSizePixel = 0, Parent = Center
})
Cor(SearchWrap, 5)
local SearchStroke = Stroke(SearchWrap, EDGE, 1)
C("TextLabel", {
    Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "🔍", TextColor3 = TX_MUT,
    TextSize = 11, Font = Enum.Font.Gotham, Parent = SearchWrap
})
local SearchBox = C("TextBox", {
    Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 32, 0, 0),
    BackgroundTransparency = 1, Text = "", PlaceholderText = "search actions...",
    TextColor3 = TX, PlaceholderColor3 = TX_MUT, TextSize = 12,
    Font = Enum.Font.Gotham, ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = SearchWrap
})
SearchBox.Focused:Connect(function() Tw(SearchStroke, .15, { Color = GOLD, Transparency = 0.5 }) end)
SearchBox.FocusLost:Connect(function() Tw(SearchStroke, .15, { Color = EDGE, Transparency = 0 }) end)

local Sc = C("ScrollingFrame", {
    Size = UDim2.new(1, -24, 1, -88), Position = UDim2.new(0, 12, 0, 86),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 4, ScrollBarImageColor3 = GOLD, ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Center
})
local CL = C("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Sc })
CL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Sc.CanvasSize = UDim2.new(0, 0, 0, CL.AbsoluteContentSize.Y + 16)
end)

local Right = C("Frame", {
    Size = UDim2.new(0, RIGHT_W, 1, -(TOP_H + 22)),
    Position = UDim2.new(1, -RIGHT_W, 0, TOP_H),
    BackgroundColor3 = PANEL, BorderSizePixel = 0, Parent = M
})
C("Frame", {
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = EDGE, BorderSizePixel = 0, Parent = Right
})
C("TextLabel", {
    Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 18, 0, 18),
    BackgroundTransparency = 1, Text = "SCANNER",
    TextColor3 = TX_MUT, TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Right
})

local ScannerScroll = C("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -60), Position = UDim2.new(0, 10, 0, 40),
    BackgroundColor3 = CARD, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = GOLD, ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Right
})
Cor(ScannerScroll, 5)
local ScanLayout = C("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ScannerScroll })
Pad(ScannerScroll, 8, 8, 8, 8)
ScanLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScannerScroll.CanvasSize = UDim2.new(0, 0, 0, ScanLayout.AbsoluteContentSize.Y + 16)
end)

local function renderScanner()
    for _, c in ipairs(ScannerScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if #FakeData.gamepasses == 0 and #FakeData.products == 0 then
        local empty = C("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = ScannerScroll })
        C("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = "no IDs detected yet\nclick a prompt or deep scan",
            TextColor3 = TX_MUT, TextSize = 10, Font = Enum.Font.Gotham,
            TextWrapped = true, Parent = empty
        })
        return
    end
    if #FakeData.gamepasses > 0 then
        local header = C("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = ScannerScroll })
        C("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = "GAMEPASSES", TextColor3 = GOLD, TextSize = 10,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = header
        })
        for i = #FakeData.gamepasses, 1, -1 do
            local e = FakeData.gamepasses[i]
            local row = C("Frame", {
                Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = CARD_H,
                BorderSizePixel = 0, Parent = ScannerScroll
            })
            Cor(row, 4)
            C("TextLabel", {
                Size = UDim2.new(1, -12, 0, 12), Position = UDim2.new(0, 8, 0, 6),
                BackgroundTransparency = 1, Text = e.name,
                TextColor3 = TX, TextSize = 11, Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = row
            })
            C("TextLabel", {
                Size = UDim2.new(1, -12, 0, 10), Position = UDim2.new(0, 8, 0, 20),
                BackgroundTransparency = 1, Text = "ID: " .. e.id .. (e.price and (" · " .. e.price .. " R$") or ""),
                TextColor3 = TX_MUT, TextSize = 9, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row
            })
            local cp = C("TextButton", {
                Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(1, -92, 0, 13),
                BackgroundColor3 = Color3.fromRGB(32, 32, 36), Text = "copy",
                TextColor3 = TX_DIM, TextSize = 9, Font = Enum.Font.GothamMedium,
                BorderSizePixel = 0, AutoButtonColor = false, Parent = row
            })
            Cor(cp, 3)
            cp.MouseButton1Click:Connect(function()
                setclipboard(tostring(e.id)); notify("BOLT", "Copied " .. e.id)
            end)
            local fk = C("TextButton", {
                Size = UDim2.new(0, 44, 0, 16), Position = UDim2.new(1, -48, 0, 13),
                BackgroundColor3 = GOLD, Text = "fake", TextColor3 = BLACK,
                TextSize = 9, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = row
            })
            Cor(fk, 3)
            fk.MouseButton1Click:Connect(function() fakePurchase(e.id, nil) end)
        end
    end
    if #FakeData.products > 0 then
        local header = C("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = ScannerScroll })
        C("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = "PRODUCTS", TextColor3 = GOLD, TextSize = 10,
            Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = header
        })
        for i = #FakeData.products, 1, -1 do
            local e = FakeData.products[i]
            local row = C("Frame", {
                Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = CARD_H,
                BorderSizePixel = 0, Parent = ScannerScroll
            })
            Cor(row, 4)
            C("TextLabel", {
                Size = UDim2.new(1, -12, 0, 12), Position = UDim2.new(0, 8, 0, 6),
                BackgroundTransparency = 1, Text = e.name,
                TextColor3 = TX, TextSize = 11, Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = row
            })
            C("TextLabel", {
                Size = UDim2.new(1, -12, 0, 10), Position = UDim2.new(0, 8, 0, 20),
                BackgroundTransparency = 1, Text = "ID: " .. e.id .. (e.price and (" · " .. e.price .. " R$") or ""),
                TextColor3 = TX_MUT, TextSize = 9, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row
            })
            local cp = C("TextButton", {
                Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(1, -92, 0, 13),
                BackgroundColor3 = Color3.fromRGB(32, 32, 36), Text = "copy",
                TextColor3 = TX_DIM, TextSize = 9, Font = Enum.Font.GothamMedium,
                BorderSizePixel = 0, AutoButtonColor = false, Parent = row
            })
            Cor(cp, 3)
            cp.MouseButton1Click:Connect(function()
                setclipboard(tostring(e.id)); notify("BOLT", "Copied " .. e.id)
            end)
            local fk = C("TextButton", {
                Size = UDim2.new(0, 44, 0, 16), Position = UDim2.new(1, -48, 0, 13),
                BackgroundColor3 = GOLD, Text = "fake", TextColor3 = BLACK,
                TextSize = 9, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = row
            })
            Cor(fk, 3)
            fk.MouseButton1Click:Connect(function() fakePurchase(nil, e.id) end)
        end
    end
end
table.insert(FakeData.listeners, function() renderScanner() end)

local Stat = C("Frame", {
    Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22),
    BackgroundColor3 = PANEL, BorderSizePixel = 0, Parent = M
})
C("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = EDGE, BorderSizePixel = 0, Parent = Stat
})
local StatusDot = C("Frame", {
    Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 16, 0.5, -3),
    BackgroundColor3 = GREEN, BorderSizePixel = 0, Parent = Stat
})
Cor(StatusDot, 3)
C("TextLabel", {
    Size = UDim2.new(0, 400, 1, 0), Position = UDim2.new(0, 30, 0, 0),
    BackgroundTransparency = 1, Text = "connected as " .. LP.Name,
    TextColor3 = TX_MUT, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Stat
})
local function FootBtn(txt, x, cb)
    local b = C("TextButton", {
        Size = UDim2.new(0, 140, 0, 16), Position = UDim2.new(1, x, 0.5, -8),
        BackgroundColor3 = PANEL, BackgroundTransparency = 1,
        Text = txt, TextColor3 = TX_DIM, TextSize = 10,
        Font = Enum.Font.Gotham, BorderSizePixel = 0,
        AutoButtonColor = false, Parent = Stat
    })
    b.MouseEnter:Connect(function() Tw(b, .1, { TextColor3 = GOLD }) end)
    b.MouseLeave:Connect(function() Tw(b, .1, { TextColor3 = TX_DIM }) end)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
    return b
end
FootBtn("executor: " .. identify() .. "  ", -160, function()
    notify("BOLT", "Executor: " .. identify())
end)

-- ══════════════════════════════════════════════
--   COMPONENTS
-- ══════════════════════════════════════════════
local Tabs, Active = {}, nil

local function SelTab(name)
    for k, v in pairs(Tabs) do
        if k == name then
            v.b.BackgroundColor3 = CARD_H
            v.stroke.Transparency = 0.7
            v.stroke.Color = GOLD
            Tw(v.t, .12, { TextColor3 = TX })
            v.accent.Visible = true
        else
            v.b.BackgroundColor3 = CARD
            v.stroke.Transparency = 1
            v.stroke.Color = EDGE
            Tw(v.t, .12, { TextColor3 = TX_DIM })
            v.accent.Visible = false
        end
    end
    Active = name
    CrumbLabel.Text = name
    for _, c in ipairs(Sc:GetChildren()) do
        if c:GetAttribute("Tab") then c.Visible = (c:GetAttribute("Tab") == name) end
    end
    Sc.CanvasPosition = Vector2.new(0, 0)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = SearchBox.Text:lower()
    for _, c in ipairs(Sc:GetChildren()) do
        if c:GetAttribute("Tab") then
            if q == "" then
                c.Visible = (c:GetAttribute("Tab") == Active)
            else
                local label = c:FindFirstChild("Title") or
                    (c:FindFirstChildOfClass("Frame") and c:FindFirstChildOfClass("Frame"):FindFirstChild("Title"))
                if label then c.Visible = label.Text:lower():find(q, 1, true) ~= nil else c.Visible = false end
            end
        end
    end
end)

local function Tab(name, icon)
    local b = C("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = CARD,
        Text = "", BorderSizePixel = 0, AutoButtonColor = false, Parent = ScSide
    })
    Cor(b, 5)
    local stroke = Stroke(b, EDGE, 1); stroke.Transparency = 1
    local accent = C("Frame", {
        Size = UDim2.new(0, 2, 0, 16), Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = GOLD, BorderSizePixel = 0, Visible = false, Parent = b
    })
    Cor(accent, 1)
    local t = C("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = (icon and icon .. "  " or "") .. name,
        TextColor3 = TX_DIM, TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b
    })
    b.MouseEnter:Connect(function()
        if Active ~= name then Tw(b, .1, { BackgroundColor3 = CARD_H }) end
    end)
    b.MouseLeave:Connect(function()
        if Active ~= name then Tw(b, .1, { BackgroundColor3 = CARD }) end
    end)
    b.MouseButton1Click:Connect(function() SelTab(name) end)
    Tabs[name] = { b = b, t = t, accent = accent, stroke = stroke }
    return name
end

local function Btn(tab, txt, desc, cb)
    local h = desc and 58 or 40
    local b = C("TextButton", {
        Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = CARD,
        Text = "", BorderSizePixel = 0, AutoButtonColor = false, Parent = Sc
    })
    b:SetAttribute("Tab", tab)
    Cor(b, 5)
    local bs = Stroke(b, EDGE, 1); bs.Transparency = 1
    C("TextLabel", {
        Name = "Title", Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 14, 0, desc and 10 or 11),
        BackgroundTransparency = 1, Text = txt, TextColor3 = TX,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b
    })
    if desc then
        C("TextLabel", {
            Size = UDim2.new(1, -40, 0, 14), Position = UDim2.new(0, 14, 0, 30),
            BackgroundTransparency = 1, Text = desc, TextColor3 = TX_DIM,
            TextSize = 10, Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = b
        })
    end
    C("TextLabel", {
        Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -22, 0, 0),
        BackgroundTransparency = 1, Text = "›", TextColor3 = TX_MUT,
        TextSize = 14, Font = Enum.Font.GothamBold, Parent = b
    })
    b.MouseEnter:Connect(function()
        Tw(b, .1, { BackgroundColor3 = CARD_H })
        Tw(bs, .1, { Color = GOLD, Transparency = 0.6 })
    end)
    b.MouseLeave:Connect(function()
        Tw(b, .1, { BackgroundColor3 = CARD })
        Tw(bs, .1, { Color = EDGE, Transparency = 1 })
    end)
    b.MouseButton1Click:Connect(function()
        Tw(b, .07, { BackgroundColor3 = GOLD })
        task.delay(.08, function() Tw(b, .2, { BackgroundColor3 = CARD_H }) end)
        pcall(cb)
    end)
    b.Visible = (tab == Active)
    return b
end

local function Tog(tab, txt, desc, cb)
    local state = false
    local b = C("TextButton", {
        Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = CARD,
        Text = "", BorderSizePixel = 0, AutoButtonColor = false, Parent = Sc
    })
    b:SetAttribute("Tab", tab)
    Cor(b, 5)
    local bs = Stroke(b, EDGE, 1); bs.Transparency = 1
    C("TextLabel", {
        Name = "Title", Size = UDim2.new(1, -70, 0, 18),
        Position = UDim2.new(0, 14, 0, 10),
        BackgroundTransparency = 1, Text = txt, TextColor3 = TX,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b
    })
    if desc then
        C("TextLabel", {
            Size = UDim2.new(1, -70, 0, 14), Position = UDim2.new(0, 14, 0, 28),
            BackgroundTransparency = 1, Text = desc, TextColor3 = TX_DIM,
            TextSize = 10, Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = b
        })
    end
    local tg = C("Frame", {
        Size = UDim2.new(0, 34, 0, 18), Position = UDim2.new(1, -48, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(52, 52, 58), BorderSizePixel = 0, Parent = b
    })
    Cor(tg, 9)
    local kn = C("Frame", {
        Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(220, 220, 220), BorderSizePixel = 0, Parent = tg
    })
    Cor(kn, 7)
    b.MouseEnter:Connect(function()
        Tw(b, .1, { BackgroundColor3 = CARD_H })
        Tw(bs, .1, { Color = EDGE_H, Transparency = 0.6 })
    end)
    b.MouseLeave:Connect(function()
        Tw(b, .1, { BackgroundColor3 = CARD })
        Tw(bs, .1, { Color = EDGE, Transparency = 1 })
    end)
    b.MouseButton1Click:Connect(function()
        state = not state
        Tw(tg, .15, { BackgroundColor3 = state and GOLD or Color3.fromRGB(52, 52, 58) })
        Tw(kn, .15, { Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) })
        pcall(cb, state)
    end)
    b.Visible = (tab == Active)
    return b
end

local function Inp(tab, txt, desc, placeholder, cb)
    local h = desc and 72 or 58
    local b = C("Frame", {
        Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = CARD,
        BorderSizePixel = 0, Parent = Sc
    })
    b:SetAttribute("Tab", tab)
    Cor(b, 5); Stroke(b, EDGE, 1).Transparency = 1
    C("TextLabel", {
        Name = "Title", Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1, Text = txt, TextColor3 = TX,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b
    })
    if desc then
        C("TextLabel", {
            Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 14, 0, 26),
            BackgroundTransparency = 1, Text = desc, TextColor3 = TX_DIM,
            TextSize = 10, Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = b
        })
    end
    local boxY = h - 34
    local box = C("TextBox", {
        Size = UDim2.new(1, -86, 0, 24), Position = UDim2.new(0, 14, 0, boxY),
        BackgroundColor3 = Color3.fromRGB(28, 28, 28), Text = "",
        PlaceholderText = placeholder or "", TextColor3 = TX,
        PlaceholderColor3 = TX_MUT, TextSize = 11, Font = Enum.Font.Gotham,
        BorderSizePixel = 0, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b
    })
    Cor(box, 4); Pad(box, 0, 10, 0, 10)
    local go = C("TextButton", {
        Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -74, 0, boxY),
        BackgroundColor3 = GOLD, Text = "GO", TextColor3 = BLACK,
        TextSize = 11, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
        AutoButtonColor = false, Parent = b
    })
    Cor(go, 4)
    go.MouseEnter:Connect(function() Tw(go, .1, { BackgroundColor3 = GOLD_H }) end)
    go.MouseLeave:Connect(function() Tw(go, .1, { BackgroundColor3 = GOLD }) end)
    go.MouseButton1Click:Connect(function() pcall(cb, box.Text) end)
    b.Visible = (tab == Active)
    return b
end

local function Sec(tab, txt)
    local f = C("Frame", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = Sc
    })
    f:SetAttribute("Tab", tab)
    C("TextLabel", {
        Name = "Title", Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 4, 0, 8),
        BackgroundTransparency = 1, Text = string.upper(txt),
        TextColor3 = GOLD, TextSize = 9, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f
    })
    f.Visible = (tab == Active)
    return f
end

-- ══════════════════════════════════════════════
--   TABS
-- ══════════════════════════════════════════════
local tDiscord  = Tab("Discords",   "💬")
local tDebug    = Tab("Debuggers",  "🐞")
local tAdmins   = Tab("Admins",     "🛡")
local tGUIs     = Tab("GUIs",       "🖥")
local tMain     = Tab("Main",       "⚡")
local tPlayer   = Tab("Player",     "👤")
local tVR       = Tab("VR",         "🥽")
local tFakers   = Tab("Fakers",     "🎭")
local tGames    = Tab("Games",      "🎮")
local tCombat   = Tab("Combat",     "🎯")
local tChat     = Tab("Chat",       "💬")
local tBypass   = Tab("Bypass AC",  "🔓")
local tSettings = Tab("Settings",   "⚙")

-- ═══ DISCORDS ═══
Sec(tDiscord, "Community")
Btn(tDiscord, "Copy Bolt Discord", "discord.gg/Ehte2SFpfu", function()
    setclipboard("https://discord.gg/Ehte2SFpfu"); notify("BOLT", "Copied Discord")
end)

-- ═══ DEBUGGERS ═══
Sec(tDebug, "Exploration")
Btn(tDebug, "Open Dev Console", "F9-equivalent", function()
    StarterGui:SetCore("DevConsoleVisible", true); notify("BOLT", "Console opened")
end)
Btn(tDebug, "Dump Workspace", "Clipboard: full hierarchy", function()
    local lines = { workspace:GetFullName() }
    local function rec(o, depth)
        if depth > 4 then return end
        for _, c in ipairs(o:GetChildren()) do
            table.insert(lines, string.rep("  ", depth) .. c.ClassName .. " — " .. c.Name)
            rec(c, depth + 1)
        end
    end
    rec(workspace, 1); setclipboard(table.concat(lines, "\n"))
    notify("BOLT", "Dumped " .. #lines .. " lines")
end)
Btn(tDebug, "Dump ReplicatedStorage", "Clipboard: full hierarchy", function()
    local lines = { ReplicatedStorage:GetFullName() }
    local function rec(o, depth)
        if depth > 4 then return end
        for _, c in ipairs(o:GetChildren()) do
            table.insert(lines, string.rep("  ", depth) .. c.ClassName .. " — " .. c.Name)
            rec(c, depth + 1)
        end
    end
    rec(ReplicatedStorage, 1); setclipboard(table.concat(lines, "\n"))
    notify("BOLT", "Dumped " .. #lines .. " lines")
end)

Sec(tDebug, "Remotes")
Btn(tDebug, "Sigma-Spy Remote Spy", "Full remote spy with parser", function()
    loadHub("https://raw.githubusercontent.com/Knuxy92/Sigma-Spy/main/SigmaSpy.lua")
end)
Btn(tDebug, "Dex++ Explorer", "Modern Dex, keyless", function()
    loadHub("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua")
end)

-- ═══ ADMINS ═══
Sec(tAdmins, "Admin Scripts")
Btn(tAdmins, "Infinite Yield", "400+ commands", function()
    loadHub("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
end)
Btn(tAdmins, "Nameless Admin", "Full admin suite", function()
    loadHub("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua")
end)

-- ═══ GUIs ═══
Sec(tGUIs, "Trolling / FE")
Btn(tGUIs, "TROLLING GUI", "Cause mass destruction", function()
    loadHub("https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/FE%20Trolling%20GUI.luau")
end)
Btn(tGUIs, "FE Trolling Player R6/R15", "3LD4D0", function()
    loadHub("https://raw.githubusercontent.com/3LD4D0/FE-TROLLING-PLAYER-R6-R15/6eff8792afed57458d5114478b453a6f6bce5799/Fe%20trolling%20Player%20R6%20AND%20R15")
end)
Btn(tGUIs, "ROXCOM Troll GUI v3", "Keyless", function()
    loadHub("https://scriptverse.net/scripts/roxcom-troll-gui-v3")
end)
Btn(tGUIs, "FE Object Control Panel", "Become parts, auras, AI", function()
    loadHub("https://raw.githubusercontent.com/All-Roblox-Scripts/fe-object-control/main/source.lua")
end)
Btn(tGUIs, "FE Prime Hub", "Green baseplate support", function()
    loadHub("https://raw.githubusercontent.com/ilikeices/script/refs/heads/main/primehubgreenbaseplatesupport.luau")
end)
Btn(tGUIs, "FE Ragdoll Engine", "Push Aura & Auto Ragdoll", function()
    loadHub("https://raw.githubusercontent.com/TestingLua/Hubs/main/Ragdoll%20Engine.lua")
end)
Btn(tGUIs, "FE Ender", "Fling + teleport", function()
    loadHub("https://raw.githubusercontent.com/ilikeices/script/refs/heads/main/ender.luau")
end)
Btn(tGUIs, "FE Headless", "Enable/disable headless", function()
    loadHub("https://gist.githubusercontent.com/TreeByte403/ae2620103048e56de7d0004e2df385d2/raw/ee3ac096491e5bc4bf99429ba80388b1cb75161e/FeHeadless.lua")
end)

-- ═══ MAIN ═══
Sec(tMain, "Character")
Tog(tMain, "Invisible (Clone)", "R6 / R15", function(on) Invisible(on) end)
Tog(tMain, "Fly", "WASD + Space / Shift", function(on) Fly(on) end)
Tog(tMain, "Noclip", "Disable collision", function(on) Noclip(on) end)
Tog(tMain, "Spin Self", "Rotate your character", function(on) SpinSelf(on) end)
Tog(tMain, "Spin All", "Rotate every other player", function(on) SpinAll(on) end)

Sec(tMain, "Speed / Jump")
Inp(tMain, "Set WalkSpeed", "Numeric value", "16", function(v)
    local n = tonumber(v); if not n then return end
    local h = GetHum(); if h then h.WalkSpeed = n end
    ForceStats.walkSpeed = n
    notify("BOLT", "WalkSpeed = " .. n)
end)
Inp(tMain, "Set JumpPower", "Numeric value", "50", function(v)
    local n = tonumber(v); if not n then return end
    local h = GetHum(); if h then h.JumpPower = n end
    ForceStats.jumpPower = n
    notify("BOLT", "JumpPower = " .. n)
end)
Inp(tMain, "Set Fly Speed", "Applies next Fly toggle", "80", function(v)
    local n = tonumber(v); if n then genv.BoltFlySpeed = n notify("BOLT", "Fly Speed = " .. n) end
end)

Sec(tMain, "Force Stats (Anti-Reset)")
Tog(tMain, "Force Stats", "Re-applies WS / JP / HH every frame", function(on)
    if on then startForceStats() else stopForceStats() end
end)
Inp(tMain, "Force WalkSpeed", "Value used while Force Stats on", "100", function(v)
    local n = tonumber(v); if n then ForceStats.walkSpeed = n notify("FORCE", "WS → " .. n) end
end)
Inp(tMain, "Force JumpPower", "Value used while Force Stats on", "100", function(v)
    local n = tonumber(v); if n then ForceStats.jumpPower = n notify("FORCE", "JP → " .. n) end
end)
Inp(tMain, "Force HipHeight", "Value used while Force Stats on", "2", function(v)
    local n = tonumber(v); if n then ForceStats.hipHeight = n notify("FORCE", "HH → " .. n) end
end)

Sec(tMain, "Fling")
Tog(tMain, "Fling All (Loop)", "Continuous fling", function(on)
    if on then
        genv.BoltFlingAll = true
        task.spawn(function() while genv.BoltFlingAll do FlingAll() task.wait(.15) end end)
    else genv.BoltFlingAll = false end
end)
Btn(tMain, "Fling Once", "One-shot fling on all", FlingAll)
Btn(tMain, "Fling Random", "Fling a random player", function()
    local ps = AllPlayers(); if #ps > 0 then Fling(ps[math.random(#ps)]) end
end)

Sec(tMain, "Player Control")
Btn(tMain, "Ragdoll Self", "Break joints", Ragdoll)
Btn(tMain, "TP All to Me", "Teleport everyone to your position", function()
    local hrp = GetHRP(); if not hrp then return end
    for _, p in ipairs(AllPlayers()) do
        if p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart")
            if t then pcall(function() t.CFrame = hrp.CFrame * CFrame.new(math.random(-12,12), 0, math.random(-12,12)) end) end
        end
    end
end)
Btn(tMain, "Freeze All", "WalkSpeed / JumpPower = 0", function()
    for _, p in ipairs(AllPlayers()) do pcall(Freeze, p) end
end)
Btn(tMain, "Thaw All", "Restore stats", function()
    for _, p in ipairs(AllPlayers()) do pcall(Thaw, p) end
end)

Sec(tMain, "Sound Spam")
Btn(tMain, "Sound Spam", "Default spam sound", function() SoundSpam(5801261657, 3) end)
Btn(tMain, "Sound Spam Bass", "Bass boosted", function() SoundSpam(1838623382, 3) end)
Btn(tMain, "Sound Spam Airhorn", "Airhorn", function() SoundSpam(6042053625, 3) end)

Sec(tMain, "Character Edits")
Btn(tMain, "Big Head", "Enlarge head", function()
    local c = GetChar(); if not c then return end
    local h = c:FindFirstChild("Head"); if h then h.Size = Vector3.new(4,4,4) end
end)
Btn(tMain, "Headless", "Remove head mesh / decals", Headless)
Btn(tMain, "Reset Char", "Kill yourself", function()
    local h = GetHum(); if h then h.Health = 0 end
end)

-- ═══ PLAYER ═══
Sec(tPlayer, "Comfort")
Tog(tPlayer, "Anti-AFK", "Prevent idle kick", function(on) antiAfk(on) end)
Tog(tPlayer, "Anti Lag / Low GFX", "Strip particles + decals + lights", function(on) lowGfx(on) end)
Tog(tPlayer, "Loop Full Bright", "Constant lighting refresh", function(on) loopFullbright(on) end)

Sec(tPlayer, "Camera")
Btn(tPlayer, "Unlock Third Person", "Expand zoom range 0.5–128", unlockThirdPerson)
Btn(tPlayer, "Toggle Shift Lock", "Enable / disable", function() setShiftLock(nil) end)

Sec(tPlayer, "Survival")
Tog(tPlayer, "God Mode", "Client-side — visual only", function(on) godMode(on) end)
Tog(tPlayer, "Health Regen", "+1 HP per frame", function(on) healthRegen(on) end)

Sec(tPlayer, "Stats")
Inp(tPlayer, "Set WalkSpeed", "Applies now", "16", function(v)
    local n = tonumber(v); if n then local h = GetHum(); if h then h.WalkSpeed = n end end
end)
Inp(tPlayer, "Set JumpPower", "Applies now", "50", function(v)
    local n = tonumber(v); if n then local h = GetHum(); if h then h.JumpPower = n end end
end)
Tog(tPlayer, "Infinite Jump", "Jump any time", function(on)
    if genv.BoltInfJump then pcall(function() genv.BoltInfJump:Disconnect() end) genv.BoltInfJump = nil end
    if on then
        genv.BoltInfJump = UIS.JumpRequest:Connect(function()
            local h = GetHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)

Sec(tPlayer, "Interaction")
Tog(tPlayer, "Auto Clicker", "Left-click spam", function(on)
    if on then autoClicker(true, genv.BoltCps or 10) else autoClicker(false) end
end)
Inp(tPlayer, "Set CPS", "Clicks per second", "10", function(v)
    local n = tonumber(v); if n then genv.BoltCps = n notify("BOLT", "CPS = " .. n) end
end)

Sec(tPlayer, "Targets")
Inp(tPlayer, "Follow Player", "Type name (partial ok)", "username...", function(v) followPlayer(v) end)
Inp(tPlayer, "Spectate Player", "Type name (partial ok)", "username...", function(v) spectate(v) end)
Btn(tPlayer, "Stop Following", "Detach follow loop", function()
    if genv.BoltFollow then genv.BoltFollow:Disconnect() genv.BoltFollow = nil end
    notify("BOLT", "Follow stopped")
end)

Sec(tPlayer, "Misc")
Btn(tPlayer, "FPS Unlock", "setfpscap(1000)", fpsUnlock)
Btn(tPlayer, "Scale ×1.5", "Bigger character", function() setScale(1.5) end)
Btn(tPlayer, "Scale ×0.5", "Smaller character", function() setScale(0.5) end)
Btn(tPlayer, "Reset Scale", "Back to normal", resetScale)

-- ═══ VR ═══
Sec(tVR, "Movement")
Tog(tVR, "VR Fly", "Fly with WASD", function(on) Fly(on) end)
Tog(tVR, "VR Noclip", "No collision", function(on) Noclip(on) end)

-- ═══ FAKERS ═══
Sec(tFakers, "Global Mode")
Tog(tFakers, "Global Fake", "Every query returns true", function(on)
    FakeData.globalOn = on
    genv.BoltGlobalFake = on
    installMarketplaceHooks()
    notify("FAKE", on and "GLOBAL MODE ON" or "Global mode off")
end)
Tog(tFakers, "Auto-Fake on Detect", "Blast when prompt captured", function(on)
    FakeData.autoFake = on
    notify("FAKE", on and "Auto-Fake enabled" or "Auto-Fake disabled")
end)

Sec(tFakers, "Scanner")
Btn(tFakers, "Deep Scan Game", "Find all gamepasses + products", function()
    FakeData.gamepasses = {}; FakeData.products = {}; FakeData.seen = {}
    for _, root in ipairs({ workspace, ReplicatedStorage, StarterGui, Players, Lighting }) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("StringValue") then
                local v = tonumber(obj.Value)
                if v and v >= 1e5 and v < 1e13 then
                    local n = obj.Name:lower()
                    if n:find("pass") or n:find("gamepass") then
                        addFakeEntry(FakeData.gamepasses, v, obj.Name, obj:GetFullName(), true)
                    elseif n:find("product") or n:find("devproduct") then
                        addFakeEntry(FakeData.products, v, obj.Name, obj:GetFullName(), false)
                    end
                end
            end
        end
    end
    notify("SCAN", "Deep scan · " .. #FakeData.gamepasses .. " gamepasses · " .. #FakeData.products .. " products")
end)
Btn(tFakers, "Fake ALL Detected", "Blast every captured ID at once", function()
    local count = 0
    for _, e in ipairs(FakeData.gamepasses) do fakePurchase(e.id, nil); count = count + 1 end
    for _, e in ipairs(FakeData.products) do fakePurchase(nil, e.id); count = count + 1 end
    notify("FAKE", "Fake blasted " .. count .. " items")
end)

Sec(tFakers, "Manual Fake")
Inp(tFakers, "Fake Gamepass by ID", "Enter gamepass ID", "gamepass id...", function(id) fakePurchase(id, nil) end)
Inp(tFakers, "Fake Product by ID", "Enter product ID", "product id...", function(id) fakePurchase(nil, id) end)

-- ═══ GAMES — ULTIMATE CATALOG (KEYLESS) ═══
Sec(tGames, "Universal Keyless Hubs")
Btn(tGames, "Shiro Hub (Universal)", "Keyless · multi-game", function()
    loadHub("https://raw.githubusercontent.com/shironaxgi/Universal/refs/heads/main/shiro.lua")
end)
Btn(tGames, "Galaxy's Hub (Library)", "Keyless · custom UI library", function()
    loadHub("https://raw.githubusercontent.com/Galaxy-BloxYT/Galaxy-s-Hub-lib-default-loading-UI/refs/heads/main/UI")
end)
Btn(tGames, "ROXCOM Hub (Universal)", "Keyless · troll + utility", function()
    loadHub("https://raw.githubusercontent.com/yasinklausss1/roxcom-hub/refs/heads/main/roxcom-hub.lua", true)
end)
Btn(tGames, "ZHub (Universal)", "Keyless · ESP + fly", function()
    loadHub("https://raw.githubusercontent.com/ZHubTeam/zhubteam.github.io/main/zhub-script.lua")
end)
Btn(tGames, "Plenum Hub", "Keyless · simple all-in-one", function()
    loadHub("https://raw.githubusercontent.com/GamerScripterYT/Plenum-Hub/main/loader")
end)
Btn(tGames, "67Hub Universal", "Keyless · 350+ scripts", function()
    loadHub("https://raw.githubusercontent.com/GearV4isBack/25Bullets/refs/heads/main/67Hub.lua")
end)
Btn(tGames, "Vidas Hub Universal", "Keyless · local player functions", function()
    loadHub("https://pastebin.com/raw/1K0n4K7q")
end)
Btn(tGames, "CanHub V2", "Keyless · 200+ games", function()
    loadHub("https://raw.githubusercontent.com/CanHub/Roblox/main/CanHubV2.lua")
end)
Btn(tGames, "XenoHub", "Keyless · 700+ games", function()
    loadHub("https://raw.githubusercontent.com/sskintbgs/xeno-script/refs/heads/main/main.lua")
end)
Btn(tGames, "YARHM", "Keyless · MM2 / Forsaken / Fisch", function()
    loadHub("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
end)

Sec(tGames, "Blox Fruits")
Btn(tGames, "Moonlight Hub", "Keyless · auto farm / fast attack / V4", function()
    loadHub("https://raw.githubusercontent.com/Dev-Moonlight/Moonlight/refs/heads/main/Main")
end)
Btn(tGames, "Redz Hub (Update 30)", "Keyless · auto bounty / fruit sniper", function()
    loadHub("https://raw.githubusercontent.com/bloxfruitsnokey/Redz/refs/heads/main/Redz/update30.luau")
end)
Btn(tGames, "Axonic Blox Fruits", "Keyless · Xeno supported", function()
    loadHub("https://raw.githubusercontent.com/Kenniel123/BloxFruits/refs/heads/main/BloxFruits")
end)
Btn(tGames, "Bear Hub", "Keyless · auto farm / fast attack / sea events", function()
    loadHub("https://raw.githubusercontent.com/Huylovemy/Bearhudz/refs/heads/main/Bearhud.lua")
end)
Btn(tGames, "TheScripter + Quantum Onyx", "Keyless · auto sea / ESP / trails", function()
    loadHub("https://gist.githubusercontent.com/sheshiidriz-netizen/b880b0c514479292c62a95457031709a/raw")
end)

Sec(tGames, "Murder Mystery 2 (MM2)")
Btn(tGames, "Axonic MM2", "Keyless · Role ESP / freemium", function()
    loadHub("https://raw.githubusercontent.com/Kenniel123/Axonic-MM2/refs/heads/main/Axonic%20MM2")
end)
Btn(tGames, "AvoEz Hub", "Keyless · new MM2 script", function()
    loadHub("https://raw.githubusercontent.com/y7ktn49dwr-spec/mm22/refs/heads/main/AvoEzHub")
end)
Btn(tGames, "Forge Hub", "Keyless · Kill All, ESP", function()
    loadHub("https://raw.githubusercontent.com/ScriptBLOXmm2/ForgeHubWaguri/refs/heads/main/keyless")
end)
Btn(tGames, "RBLXHub MM2", "Keyless · Kill Aura, Auto Shoot", function()
    loadHub("https://raw.githubusercontent.com/bugxiefun/roblox-scripts/refs/heads/main/rblxhub_mm2")
end)
Btn(tGames, "Role Chams", "Keyless · Murderer and Sheriff ESP", function()
    loadHub("https://raw.githubusercontent.com/imshrak/rolechams/refs/heads/main/main")
end)
Btn(tGames, "klaya21n MM2", "Keyless · ScriptVerse featured", function()
    loadHub("https://raw.githubusercontent.com/klaya21n/script/refs/heads/main/mm2%20new")
end)
Btn(tGames, "FoxName MM2", "Keyless · classic MM2", function()
    loadHub("https://raw.githubusercontent.com/xv3gasx/Murder-Mystery-2/refs/heads/main/Release.lua")
end)

Sec(tGames, "Da Hood")
Btn(tGames, "DP Hub", "Keyless · Auto Ammo / Tracers / ESP", function()
    loadHub("https://raw.githubusercontent.com/COOLXPLO/DP-HUB-coolxplo/refs/heads/main/DaHoods.lua")
end)
Btn(tGames, "Oxide Hub", "Keyless · visual / teleport / rage", function()
    loadHub("https://raw.githubusercontent.com/xulfo/Oxide-Loader/main/Main.lua")
end)
Btn(tGames, "Swagmode", "Keyless · admin / exploit hub", function()
    loadHub("https://raw.githubusercontent.com/I4MMO/Cracks/refs/heads/main/Swagmode.lua")
end)
Btn(tGames, "Hood Customs Silent Aim", "Keyless · undetected with FOV", function()
    loadHub("https://raw.githubusercontent.com/AustinScripts189/HC/refs/heads/main/main.lua")
end)

Sec(tGames, "Arsenal")
Btn(tGames, "Unbound Hub", "Keyless · Aimbot, Kill All, INF Ammo", function()
    loadHub("https://raw.githubusercontent.com/samerop/unbound-hub/main/unbound-hub.lua")
end)
Btn(tGames, "Soluna Arsenal", "Keyless · combat features", function()
    loadHub("https://raw.githubusercontent.com/BaconCheats/Scripts/refs/heads/main/PromptJoin.lua")
end)
Btn(tGames, "Luigi Hub", "Keyless · Aimbot & Silent Aim", function()
    loadHub("https://raw.githubusercontent.com/Luigi4k85/Arsenal-v5.3/refs/heads/main/Arsenal%20v5.3")
end)
Btn(tGames, "CatHook Desync", "Keyless · desync", function()
    loadHub("https://raw.githubusercontent.com/ZfpsGT1030/Arsenal/refs/heads/main/Desync.lua")
end)

Sec(tGames, "Jailbreak")
Btn(tGames, "Veloxide V2", "Keyless · Fast Vehicle, Silent Aim, Arrest Aura", function()
    loadHub("https://raw.githubusercontent.com/veloxides/Jailbreak/refs/heads/main/VeloxideLoader")
end)
Btn(tGames, "Jailbreak V2 (AverageAftermath)", "Keyless · aimbot, ESP, speed", function()
    loadHub("https://raw.githubusercontent.com/AverageAftermath/JailbreakFun/refs/heads/main/Main")
end)
Btn(tGames, "Auto Rob / Arrest (Austin)", "Keyless · universal farm", function()
    loadHub("https://raw.githubusercontent.com/AustinScripts189/jb/refs/heads/main/rob.lua")
end)

Sec(tGames, "RIVALS")
Btn(tGames, "KORAX RIVALS", "Keyless · Silent Aim & ESP", function()
    loadHub("https://raw.githubusercontent.com/imshrak/rivals/refs/heads/main/main")
end)
Btn(tGames, "JN HH RIVALS", "Keyless · Skin Changer / ESP / Charms", function()
    loadHub("https://raw.githubusercontent.com/JNHHGaming/Rivals8/refs/heads/main/JN%20HH%20Gaming", true)
end)
Btn(tGames, "EvolveX RIVALS", "Keyless · Aimbot, ESP, Triggerbot", function()
    loadHub("https://raw.githubusercontent.com/BrandTinsmith/meomjdye/refs/heads/main/EvolveX.lua")
end)
Btn(tGames, "Saint Hub RIVALS", "Keyless · ESP, Silent Aim", function()
    loadHub("https://raw.githubusercontent.com/tokyotokyo-dev/rivals/refs/heads/main/rivalsaimwh.lua", true)
end)
Btn(tGames, "Z3US RIVALS", "Keyless · dedicated RIVALS hub", function()
    loadHub("https://raw.githubusercontent.com/blackowl1231/ZYPHERION/refs/heads/main/main.lua")
end)

Sec(tGames, "Grow a Garden 2 (GAG2)")
Btn(tGames, "TheScripter Hub", "Keyless · auto farm", function()
    loadHub("https://gist.githubusercontent.com/sheshiidriz-netizen/7f0b503228048741ce05670e897e082d/raw")
end)
Btn(tGames, "Dark Spawner", "Keyless · spawn pets/seeds", function()
    loadHub("https://raw.githubusercontent.com/f2playelias-lab/cool/refs/heads/main/GagFreeScript")
end)
Btn(tGames, "RBLXScript T.Net", "Keyless · auto harvest/plant", function()
    loadHub("https://raw.githubusercontent.com/rblxshop/Rblxscripts/refs/heads/main/gag2new.lua")
end)
Btn(tGames, "Gravity Hub", "Keyless · mobile + PC", function()
    loadHub("https://raw.githubusercontent.com/Dev-gravityHub/GrowAGarden2/refs/heads/main/Main.lua")
end)

Sec(tGames, "Natural Disaster Survival (NDS)")
Btn(tGames, "Emote Fling OP", "Keyless · god mode, fling", function()
    loadHub("https://pastebin.com/raw/8XCgheRD")
end)
Btn(tGames, "OP Troll GUI", "Keyless · fling + map change", function()
    loadHub("https://pastebin.com/raw/Gk5jFVRK")
end)
Btn(tGames, "Object Control & Flight", "Keyless · manipulate parts + fly", function()
    loadHub("https://raw.githubusercontent.com/CREEP-fmg/MAINSCRIPTS/refs/heads/main/MANIPULATORNOKEY.TXT")
end)
Btn(tGames, "Touch Fling", "Keyless · fling by touching", function()
    loadHub("https://raw.githubusercontent.com/SCRIPTHUB-dev-god/exploit/refs/heads/main/fling/the-touch-fling.luau", true)
end)
Btn(tGames, "NDS Script 1.1", "Keyless · lightweight survival", function()
    loadHub("https://pastebin.com/raw/xYZXg53h", true)
end)

Sec(tGames, "Battlegrounds / FPS / Action")
Btn(tGames, "Phantom Forces (Legit)", "Keyless · silent aim + ESP", function()
    loadHub("https://raw.githubusercontent.com/jsdhaijs/autofatrm/refs/heads/main/pfmain", true)
end)
Btn(tGames, "Phantom Forces (AimReaper)", "Keyless · aimbot + ESP", function()
    loadHub("https://rawscripts.net/raw/Phantom-Forces-AimReaper-Keyless-Phantom-forces-OP-Aimbot-37523")
end)
Btn(tGames, "Defusal", "Keyless · Aimbot, ESP, Gun Mods", function()
    loadHub("https://raw.githubusercontent.com/TCOAAL/Defusal/refs/heads/main/FPS")
end)
Btn(tGames, "Valinc Syndicate", "Keyless · FE features", function()
    loadHub("https://raw.githubusercontent.com/wildhornets/defeat-valinc/refs/heads/master/vd/play.lua")
end)
Btn(tGames, "Bad Business", "Keyless · aimbot, ESP, unlock all", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Bad-Business/main/SPHub")
end)
Btn(tGames, "Criminality", "Keyless · silent aim, ESP, farm", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Criminality/main/SPHub")
end)
Btn(tGames, "Combat Warriors", "Keyless · kill aura, auto parry", function()
    loadHub("https://raw.githubusercontent.com/decryp1/Combat-Warriors-script/refs/heads/main/HerkleHubSolara%26Xeno")
end)
Btn(tGames, "Apocalypse Rising 2", "Keyless · ESP, silent aim", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Apocalypse-Rising-2/main/SPHub")
end)

Sec(tGames, "Ride a Pet")
Btn(tGames, "Egg ESP + Teleport", "Keyless · open source · distance labels", function()
    loadHub("https://raw.githubusercontent.com/darkduy/lua/refs/heads/main/ride-a-pet.lua")
end)
Btn(tGames, "XyronHub", "Keyless · auto farm, auto luck, ESP", function()
    loadHub("https://raw.githubusercontent.com/vikrantsudo/XyronHub/refs/heads/main/RideAPet")
end)
Btn(tGames, "Crystal Hub", "Keyless · auto steal best egg, auto hatch", function()
    loadHub("https://raw.githubusercontent.com/scriptmm2/Ride-A-Pet/refs/heads/main/luau")
end)
Btn(tGames, "ARC Hub", "Keyless · auto farm, hatch, rebirth", function()
    loadHub("https://pastefy.app/GQ8Mr9MM/raw")
end)

Sec(tGames, "MONOCHROME (Horror)")
Btn(tGames, "ESP + Key Grabber", "Keyless · ESP everything, code decipher", function()
    loadHub("https://raw.githubusercontent.com/Sledny/Im-up-to-no-good/refs/heads/main/monochrome_game.lua")
end)
Btn(tGames, "Auto Complete + Keys", "Keyless · ESP, get all keys, input code", function()
    loadHub("https://raw.githubusercontent.com/EvolWareOfc/EvolWare/refs/heads/main/Games/Loader.lua")
end)
Btn(tGames, "Auto Solve + Fullbright", "Keyless · auto solve, ESP, fullbright", function()
    loadHub("https://raw.githubusercontent.com/Bac0nHck/Scripts/refs/heads/main/MONOCHROME.lua")
end)

Sec(tGames, "Jujutsu Shenanigans (JJS)")
Btn(tGames, "Jujutsuer V2", "Keyless · kill aura, auto black flash", function()
    loadHub("https://raw.githubusercontent.com/tricksyfishys/jujutsuer/refs/heads/main/main.lua")
end)
Btn(tGames, "Namelesss Hub", "Keyless · lock on, animation spoof, flight", function()
    loadHub("https://raw.githubusercontent.com/NeziaReal/jjs/refs/heads/main/main.lua")
end)
Btn(tGames, "Kill All Gojo 0.2", "Keyless · instant elimination, auto attack", function()
    loadHub("https://pastebin.com/raw/F3MX83hV", true)
end)
Btn(tGames, "Minosr", "Keyless · stretches reach, reverse red", function()
    loadHub("https://raw.githubusercontent.com/Dragonfly5101/Minosr/refs/heads/main/obfuscated.lua")
end)

Sec(tGames, "More Horror")
Btn(tGames, "FEAR", "Keyless · universal FE Kill GUI", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/FE-Kill/main/SPHub")
end)
Btn(tGames, "Pressure", "Keyless · auto quirk, ESP, kill aura", function()
    loadHub("https://raw.githubusercontent.com/DrakeCongressman/Kraken-Update-KAIZEN/main/Kraken-Update-KAIZEN.lua")
end)
Btn(tGames, "3008 (Localplayer)", "Keyless · bring items, god mode", function()
    loadHub("https://raw.githubusercontent.com/saninarchawee-prog/Scp-3008/refs/heads/main/lua")
end)
Btn(tGames, "Specter", "Keyless · ESP, auto win", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Specter/main/SPHub")
end)
Btn(tGames, "Evade", "Keyless · auto dodge, ESP", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Evade/main/SPHub")
end)
Btn(tGames, "Apeirophobia", "Keyless · auto win, ESP", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Apeirophobia/main/SPHub")
end)
Btn(tGames, "Cheese Escape", "Keyless · simple horror", function()
    loadHub("https://rscripts.net/raw/cheese-escape-horror-keyless_1763313774636_TNRiKy9YZF.txt")
end)
Btn(tGames, "Amber Alert", "Keyless · auto farm, speed hack", function()
    loadHub("https://gist.githubusercontent.com/BlockyCoder/7cbb90bf3511e2daa8ea259c8f91af33/raw/687c269796584d890d21fe14136a06518a9b0b2b/Amber%2520Alert%2520%255BUPD%255D%2520%255BHORROR%255D")
end)

Sec(tGames, "Runaways")
Btn(tGames, "Auto Farm + Kill Aura", "Keyless · silent aim, loot ESP, god mode", function()
    loadHub("https://raw.githubusercontent.com/Bac0nHck/Scripts/refs/heads/main/RUNAWAYS.lua")
end)
Btn(tGames, "Ouroboros", "Keyless · auto pawn, auto escape, loot ESP", function()
    loadHub("https://raw.githubusercontent.com/joustingmatch/Ouroboros/main/loader.lua")
end)
Btn(tGames, "StarCrow Hub", "Keyless · auto win, break safes, vehicle fly", function()
    loadHub("https://raw.githubusercontent.com/NoahTyrant/StarCrow/refs/heads/main/Runaways")
end)

Sec(tGames, "World // Zero")
Btn(tGames, "Auto Farm (NukeVsCity)", "Keyless · largest free version", function()
    loadHub("https://raw.githubusercontent.com/NukeVsCity/Scripts2025/refs/heads/main/worldzerofarm")
end)
Btn(tGames, "Anya Hub", "Keyless · protected but clean", function()
    loadHub("https://raw.githubusercontent.com/zakbari045-cmyk/anyahub/refs/heads/main/wz")
end)

Sec(tGames, "Steal a Brainrot")
Btn(tGames, "Evil Hub Duels", "Keyless · steal speed / aimbot / anti-fling", function()
    loadHub("https://pastefy.app/V0blGtti/raw")
end)
Btn(tGames, "K2 Duels", "Keyless · working keyless duels", function()
    loadHub("https://xenoscripts.com/script/k2-duels-steal-a-brainrot-script-working-and-keyless")
end)
Btn(tGames, "KURD HUB", "Keyless · mobile friendly, good steal", function()
    loadHub("https://raw.githubusercontent.com/dontasklol/Stealabrainrot/refs/heads/main/Kurd%20hub")
end)
Btn(tGames, "Dark Hub SAB", "Keyless · infinite jump, anti stun", function()
    loadHub("https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua")
end)
Btn(tGames, "SAB PIE Loader V2", "Keyless · duel, map helper, automation", function()
    loadHub("https://raw.githubusercontent.com/UniversalScriptHub/SABLOADERV3/refs/heads/main/PIETeamloaderscript.Lua")
end)

Sec(tGames, "Forsaken")
Btn(tGames, "Forsaken Plus", "Keyless · invincible / autogen / ESP", function()
    loadHub("https://naikoexploit.vercel.app/ForsakenPlus")
end)
Btn(tGames, "Cursedsaken", "Keyless · aimbot + speed", function()
    loadHub("https://raw.githubusercontent.com/zxcursedsocute/Forsaken-Script/refs/heads/main/lua")
end)
Btn(tGames, "RINGTA HUB", "Keyless · dedicated Forsaken", function()
    loadHub("https://raw.githubusercontent.com/34f3f/forsaken.github.io/refs/heads/main/ringtabublik.lua")
end)
Btn(tGames, "Auto Block", "Keyless · infinite stamina", function()
    loadHub("https://raw.githubusercontent.com/LolnotaKid/project/refs/heads/main/AutoBLOCKKKWAHV1")
end)
Btn(tGames, "Nolsaken", "Keyless · alternative hub", function()
    loadHub("https://raw.githubusercontent.com/Potato5466794/Nolsaken/refs/heads/main/NOL/Nolsaken.luau")
end)

Sec(tGames, "Blue Lock Rivals")
Btn(tGames, "Auto Get Ball / Steal", "Keyless · auto dribble + goals", function()
    loadHub("https://raw.githubusercontent.com/TheDarkoneMarcillisePex/Other-Scripts/refs/heads/main/Blue%20Lock%20Rivals%20GUI")
end)
Btn(tGames, "Nova Hub", "Keyless · shot changer + free cosmetics", function()
    loadHub("https://raw.githubusercontent.com/Dreamyzone/Nova-Hub-Blue-Lock-Rivals/refs/heads/main/Shot-Modifier-FREE-COSMETICS-WORKS-WITH-ALL-STYLES-Op")
end)
Btn(tGames, "Hiori Awakening", "Keyless · infinite awakening + styles", function()
    loadHub("https://pastefy.app/ObKHeapN/raw")
end)
Btn(tGames, "Flying Ball", "Keyless · steer the ball in the air", function()
    loadHub("https://raw.githubusercontent.com/Iliankytb/Iliankytb/main/BLRFlyingBall")
end)

Sec(tGames, "99 Nights in the Forest")
Btn(tGames, "Ringta Hub", "Keyless · kill aura / auto craft", function()
    loadHub("https://raw.githubusercontent.com/wehibuy/ringta/main/ringta.lua")
end)
Btn(tGames, "ToastyXD Hub", "Keyless · auto attack + instant reload", function()
    loadHub("https://raw.githubusercontent.com/nouralddin-abdullah/99-night/refs/heads/main/main-en.lua")
end)
Btn(tGames, "Fast Hub", "Keyless · player ESP + food ESP", function()
    loadHub("https://xenoscripts.com/script/fast-hub-script-99-nights-player-esp-food-esp-chair")
end)
Btn(tGames, "Bliqe Auto Farm", "Keyless · auto farm", function()
    loadHub("https://raw.githubusercontent.com/Bliqe/Upload/refs/heads/main/Games/RAR/47425677550.lua")
end)

Sec(tGames, "Dead Rails")
Btn(tGames, "Ringta Dead Rails", "Keyless · auto farm / bring items", function()
    loadHub("https://raw.githubusercontent.com/erewe23/deadrailsring.github.io/refs/heads/main/ringta.lua")
end)
Btn(tGames, "CashRails", "Keyless · auto bond farm", function()
    loadHub("https://raw.githubusercontent.com/cashaura/DeadRails/refs/heads/main/cashrails.lua")
end)
Btn(tGames, "QIWIK Hub", "Keyless · melee aura, gun aura, air weld", function()
    loadHub("https://raw.githubusercontent.com/Qiwikox12/stubrawl/refs/heads/main/DeadRails.txt")
end)
Btn(tGames, "Vexon Hub", "Keyless · freeze mobs, instakill", function()
    loadHub("https://xenoscripts.com/script/vexon-hub-script-freeze-mobs-instakill-mobs-transparent-buildings")
end)

Sec(tGames, "Fisch")
Btn(tGames, "MUR4 Keyless", "Keyless · auto reel / cast / shake", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Fisch/main/SPHub")
end)
Btn(tGames, "Instant Auto Fish", "Keyless · auto sell OP", function()
    loadHub("https://xenoscripts.com/script/instant-auto-fish-auto-sell-op-keyless-fisch-script")
end)

Sec(tGames, "Other Popular")
Btn(tGames, "Prison Life", "Keyless · kill all, gun mods", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Prison-Life/main/SPHub")
end)
Btn(tGames, "Tower of Hell", "Keyless · skip stages, fly", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/TOH/main/SPHub")
end)
Btn(tGames, "Bedwars", "Keyless · kill all, auto win", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Bedwars/main/SPHub")
end)
Btn(tGames, "Doors", "Keyless · ESP, auto win", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Doors/main/SPHub")
end)
Btn(tGames, "Blade Ball (SP-Hub)", "Keyless · auto parry", function()
    loadHub("https://raw.githubusercontent.com/SP-Hub/Blade-Ball/main/SPHub")
end)
Btn(tGames, "Blade Ball (Soluna Hub)", "Keyless · auto parry + prediction", function()
    loadHub("https://xenoscripts.com/script/soluna-hub-script-auto-parry-prediction-system-max-parry-angle")
end)
Btn(tGames, "Blade Ball (Bobit)", "Keyless · auto parry + auto spam", function()
    loadHub("https://bypass.tools/tr/scripts/rscripts/bobit-autoparry-keyless-auto-spam-auto-ability-upd-blade-ball-script")
end)

-- ═══ COMBAT ═══
Sec(tCombat, "Aimbot / ESP")
Btn(tCombat, "Sp3arParvus", "Keyless · aim-lock + ESP, open source", function()
    loadHub("https://raw.githubusercontent.com/JakeHukari/Sp3arParvus/refs/heads/main/Sp3arParvus.lua", true)
end)
Btn(tCombat, "VibeCode V2", "Keyless · silent aim + trigger bot", function()
    loadHub("https://raw.githubusercontent.com/g8553037-lgtm/VibeCodeV2/refs/heads/main/vibecode.lua")
end)
Btn(tCombat, "Universal ESP (ayzz7)", "Keyless · box / chams / health", function()
    loadHub("https://pastefy.app/VKpXX0pO/raw")
end)

-- ═══ CHAT ═══
local function SendChat(msg)
    if not msg or msg == "" then return end
    local sent = pcall(function()
        local ch = TextChatService:FindFirstChild("TextChannels")
        if ch then
            local g = ch:FindFirstChild("RBXGeneral")
            if g then g:SendAsync(msg) return true end
        end
        return false
    end)
    if sent then return end
    pcall(function()
        local evt = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if evt then
            local r = evt:FindFirstChild("SayMessageRequest")
            if r then r:FireServer(msg, "All") end
        end
    end)
end

Sec(tChat, "Exploiter Chat")
Btn(tChat, "Enable /bolt prefix", "Type /bolt <msg>", function()
    if genv.BoltExploitChat then return end
    genv.BoltExploitChat = LP.Chatted:Connect(function(msg)
        if msg:sub(1, 6):lower() == "/bolt " then SendChat("[BOLT] " .. msg:sub(7)) end
    end)
    notify("BOLT", "Exploiter chat on")
end)
Inp(tChat, "Custom Chat", "Prefixes [BOLT]", "type message...", function(msg)
    if msg ~= "" then SendChat("[BOLT] " .. msg) end
end)

-- ═══ BYPASS AC (auto-active) ═══
Sec(tBypass, "Status — All Active")
C("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Parent = Sc,
}).LayoutOrder = 0
local function StatusRow(tab, label, state)
    local b = C("Frame", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = CARD,
        BorderSizePixel = 0, Parent = Sc
    })
    b:SetAttribute("Tab", tab)
    Cor(b, 5)
    local dot = C("Frame", {
        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 14, 0.5, -3),
        BackgroundColor3 = GREEN, BorderSizePixel = 0, Parent = b
    })
    Cor(dot, 3)
    C("TextLabel", {
        Name = "Title", Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = TX, TextSize = 11, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b
    })
    b.Visible = (tab == Active)
end
StatusRow(tBypass, "Universal Shield — active", true)
StatusRow(tBypass, "Delta Clamp (45 studs/frame) — active", true)
StatusRow(tBypass, "Remote Guard — active", true)

Btn(tBypass, "Reinstall All Protections", "Shield + Clamp + Guard — one click", function()
    installUniversalShield()
    installDeltaClamp(45)
    installRemoteGuard()
    notify("BYPASS", "All protections reinstalled")
end)

Sec(tBypass, "Key Bypass")
Tog(tBypass, "Key Environment Active", "Pre-sets key globals + files", function(on)
    KeyBypass.enabled = on
    if on then setupKeyEnvironment() end
    notify("KEY", on and "Key environment active" or "Key environment disabled")
end)
Btn(tBypass, "Re-inject Key Globals", "Force re-set all keys", function()
    setupKeyEnvironment(); notify("KEY", "Key globals re-injected")
end)

Sec(tBypass, "Lagback")
Tog(tBypass, "Stop Lagback", "Snap-back position protection", function(on)
    if genv.BoltLagback then pcall(function() genv.BoltLagback:Disconnect() end) genv.BoltLagback = nil end
    if not on then genv.BoltLastCF = nil return end
    genv.BoltLastCF = nil
    genv.BoltLagback = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP() if not hrp then return end
        if genv.BoltLastCF then
            local diff = (hrp.Position - genv.BoltLastCF.Position).Magnitude
            if diff > 45 then hrp.CFrame = genv.BoltLastCF
            else genv.BoltLastCF = hrp.CFrame end
        else genv.BoltLastCF = hrp.CFrame end
    end)
    notify("BOLT", "Lagback protection on")
end)

-- ═══ SETTINGS ═══
Sec(tSettings, "Network (Auto)")
Tog(tSettings, "Auto Network Ownership", "Claims unanchored parts automatically", function(on)
    if on then enableAutoNetwork() else disableAutoNetwork() end
end)
Btn(tSettings, "Force Sweep Now", "Claim all unanchored parts this instant", sweepWorkspace)
Btn(tSettings, "Release All Ownership", "Hand everything back to the server", function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            pcall(function() obj:SetNetworkOwner(nil) end)
        end
    end
    notify("NET", "All parts released to server")
end)

Sec(tSettings, "Scanner")
Btn(tSettings, "Re-run Capability Scan", "Print pruned features", function()
    PRUNED = {}; scanCapabilities(); reportPruned()
    notify("BOLT", "Capability scan complete")
end)
Btn(tSettings, "Show Pruned Count", "How many features were removed", function()
    notify("BOLT", #PRUNED .. " features pruned")
end)

Sec(tSettings, "Reset")
Btn(tSettings, "Stop All Loops", "Kill Fly, Noclip, Spin, etc.", function()
    Cleanup()
end)
Btn(tSettings, "Unload Hub", "Close UI completely", function() Cleanup() end)

-- ══════════════════════════════════════════════
--   INIT (launch notifications silenced)
-- ══════════════════════════════════════════════
SelTab(tMain)
renderScanner()

registerFeature("Detection Hooks", { "getrawmetatable" }, installDetectionHooks)
registerFeature("Marketplace Hooks", { "getrawmetatable" }, installMarketplaceHooks)

-- AUTO-BYPASS: fire silently on load, no questions asked
task.defer(function()
    pcall(installUniversalShield)
    pcall(installDeltaClamp, 45)
    pcall(installRemoteGuard)
end)

installAutoNetwork()

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if M.Visible then MinimizeToIcon() else RestoreFromIcon() end
    end
end)

reportPruned()
-- Launch notifications removed — no "Bolt Hub loaded" popup
