--[[
    ⚡ BOLT HUB ⚡
]]

-- ─── Services ───
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")
local StarterGui        = game:GetService("StarterGui")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInput      = game:GetService("VirtualInputManager")
local MarketplaceService = game:GetService("MarketplaceService")

local LP     = Players.LocalPlayer
local Mouse  = LP:GetMouse()
local Camera = workspace.CurrentCamera

local genv  = getgenv and getgenv() or _G
local gethui = gethui or function() return game:GetService("CoreGui") end
local setclipboard = setclipboard or toclipboard or function() end
local getrawmt = getrawmetatable or (debug and debug.getmetatable)
local setro    = setreadonly or make_writeable or function() end
local newc     = newcclosure or function(f) return f end
local unpack   = table.unpack or unpack
local hasHookMethod = type(hookmetamethod) == "function"
local hasReplicateSignal = type(replicatesignal) == "function"
local hasFireSignal = type(firesignal) == "function"
local hasCloneRef = type(cloneref) == "function"

if genv.BoltHub then pcall(function() genv.BoltHub:Destroy() end) end
if genv.BoltIcon then pcall(function() genv.BoltIcon:Destroy() end) end

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

-- ─── Util ───
local function C(c, p)
    local o = Instance.new(c)
    for k, v in pairs(p) do o[k] = v end
    return o
end
local function Cor(p, r)
    return C("UICorner", {CornerRadius = UDim.new(0, r or 6), Parent = p})
end
local function Stroke(p, c, t, tr)
    return C("UIStroke", {
        Color = c or EDGE, Thickness = t or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p
    })
end
local function Tw(o, t, p)
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
    tw:Play()
    return tw
end
local function Pad(p, t, r, b, l)
    return C("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0), Parent = p
    })
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
    local cols = 12
    local colW = size / cols
    local Bolt = C("Frame", {
        Size = UDim2.new(0, size, 0, size),
        Position = UDim2.new(0.5, -size/2, 0.5, -size/2),
        BackgroundTransparency = 1,
        Parent = parent
    })
    for i, r in ipairs(BOLT_ROWS) do
        local c0, c1 = r[1], r[2]
        local w = (c1 - c0 + 1) * colW
        C("Frame", {
            Size = UDim2.new(0, w, 0, cell + 0.6),
            Position = UDim2.new(0, c0 * colW, 0, (i - 1) * cell),
            BackgroundColor3 = BLACK,
            BorderSizePixel = 0,
            Parent = Bolt
        })
    end
end

-- ─── Char helpers ───
local function GetChar() return LP.Character end
local function GetHRP(c) c = c or GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum(c) c = c or GetChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function AllPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p) end
    end
    return t
end
local function SafeNO(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function() if not part.Anchored then part:SetNetworkOwner(LP) end end)
end

-- ─── Log ───
local LogBuffer = {}
local LogSink = nil
local function notify(title, text, dur)
    local stamp = os.date("%H:%M:%S")
    table.insert(LogBuffer, {stamp = stamp, title = title or "BOLT", text = text or ""})
    if #LogBuffer > 80 then table.remove(LogBuffer, 1) end
    if LogSink then pcall(LogSink) end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "BOLT", Text = text or "", Duration = dur or 3
        })
    end)
end

-- ══════════════════════════════════════════════
--   ═══ THE GOD-TIER FAKER ENGINE ═══
-- ══════════════════════════════════════════════

local FakeData = {
    gamepasses = {},
    products   = {},
    seen       = {},
    listeners  = {},
    globalOn   = false,   -- global fake state (everything returns true)
    autoFake   = false,   -- auto-fake on prompt detection
    hookedMP   = false,   -- marketplace service already hooked?
}

-- Fetch product info from Roblox
local function fetchProductInfo(id, isGamepass)
    local infoType = isGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(id, infoType)
    end)
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

    local displayName = name
    local price
    if not displayName or displayName == "Prompt" or displayName == "Check"
       or displayName == "Info" or displayName == "Remote" then
        displayName, price = fetchProductInfo(id, isGamepass)
    end

    local entry = {
        id = id,
        name = displayName or ("Unknown " .. (isGamepass and "Gamepass" or "Product")),
        price = price,
        source = source or "?",
        isGamepass = isGamepass
    }
    table.insert(tbl, entry)
    notify("SCAN", (isGamepass and "Gamepass" or "Product") .. " " .. id .. " · " .. entry.name)
    for _, fn in ipairs(FakeData.listeners) do pcall(fn, entry) end

    -- Auto-fake if enabled
    if FakeData.autoFake then
        task.spawn(function()
            if isGamepass then
                _G.BoltFakePurchase(id, nil)
            else
                _G.BoltFakePurchase(nil, id)
            end
        end)
    end
end

-- ═══ THE BLAST — fires every known purchase method simultaneously ═══
local function fakePurchase(gamepassId, productId)
    local firedCount = 0

    -- ═══ GAMEPASS PATH ═══
    if gamepassId then
        gamepassId = tonumber(gamepassId)
        if not gamepassId then return false end

        -- Fire all variants immediately
        local function blast()
            -- Variant 1: replicatesignal with LP instance
            if hasReplicateSignal then
                pcall(function()
                    replicatesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP, gamepassId, true)
                    firedCount = firedCount + 1
                end)
                -- Variant 2: replicatesignal with UserId
                pcall(function()
                    replicatesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP.UserId, gamepassId, true)
                end)
                -- Variant 3: 2-arg form (some executors)
                pcall(function()
                    replicatesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP, gamepassId)
                end)
            end

            -- Variant 4: direct Signal call
            pcall(function()
                MarketplaceService:SignalPromptGamePassPurchaseFinished(LP.UserId, gamepassId, true)
            end)
            pcall(function()
                MarketplaceService:SignalPromptGamePassPurchaseFinished(LP, gamepassId, true)
            end)

            -- Variant 5: firesignal (local)
            if hasFireSignal then
                pcall(function()
                    firesignal(MarketplaceService.PromptGamePassPurchaseFinished, LP, gamepassId, true)
                end)
            end
        end

        blast()
        task.delay(0.05, blast)
        task.delay(0.2, blast)
        task.delay(0.5, blast)
        task.delay(1.0, blast)

        -- Fallback: also hook namecall for local checks
        local mt = getrawmt and getrawmt(game)
        if mt then
            local old = mt.__namecall
            pcall(function() setro(mt, false) end)
            mt.__namecall = newc(function(self, ...)
                local method = getnamecallmethod and getnamecallmethod() or ""
                if method == "UserOwnsGamePassAsync" then
                    local args = {...}
                    if args[2] == gamepassId or args[1] == gamepassId
                       or FakeData.globalOn then
                        return true
                    end
                end
                if method == "PlayerOwnsAsset" and FakeData.globalOn then
                    return true
                end
                return old(self, ...)
            end)
            pcall(function() setro(mt, true) end)
        end

        notify("FAKE", "Blast fired " .. firedCount .. "× for gamepass " .. gamepassId)
        return true
    end

    -- ═══ PRODUCT PATH ═══
    if productId then
        productId = tonumber(productId)
        if not productId then return false end

        local function blast()
            if hasReplicateSignal then
                pcall(function()
                    replicatesignal(MarketplaceService.PromptProductPurchaseFinished, LP.UserId, productId, true)
                    firedCount = firedCount + 1
                end)
                pcall(function()
                    replicatesignal(MarketplaceService.PromptProductPurchaseFinished, LP, productId, true)
                end)
            end

            pcall(function()
                MarketplaceService:SignalPromptProductPurchaseFinished(LP.UserId, productId, true)
            end)

            if hasFireSignal then
                pcall(function()
                    firesignal(MarketplaceService.PromptProductPurchaseFinished, LP.UserId, productId, true)
                end)
            end

            -- Also try PromptPurchaseFinished for the general case
            if hasReplicateSignal then
                pcall(function()
                    replicatesignal(MarketplaceService.PromptPurchaseFinished, LP, productId, true)
                end)
            end
        end

        blast()
        task.delay(0.05, blast)
        task.delay(0.2, blast)
        task.delay(0.5, blast)
        task.delay(1.0, blast)

        notify("FAKE", "Blast fired " .. firedCount .. "× for product " .. productId)
        return true
    end

    return false
end
_G.BoltFakePurchase = fakePurchase

-- ═══ DIRECT MARKETPLACE HOOK ═══
-- Hooks the service itself, not just game metatable. Catches games that
-- call MarketplaceService:UserOwnsGamePassAsync directly.
local function installMarketplaceHooks()
    if FakeData.hookedMP then return end
    FakeData.hookedMP = true

    local mt = getrawmt and getrawmt(MarketplaceService)
    if not mt then
        notify("FAKE", "MarketplaceService MT unavailable")
        return
    end

    local oldIdx = mt.__index
    local oldNC = mt.__namecall
    pcall(function() setro(mt, false) end)

    mt.__index = newc(function(self, key)
        if key == "ProcessReceipt" and FakeData.globalOn then
            return function()
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end
        if oldIdx then return oldIdx(self, key) end
    end)

    mt.__namecall = newc(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        local args = {...}

        -- UserOwnsGamePassAsync: if globalOn OR specific ID captured
        if method == "UserOwnsGamePassAsync" then
            if FakeData.globalOn then return true end
            local id = args[2] or args[1]
            if id then
                for _, e in ipairs(FakeData.gamepasses) do
                    if e.id == id then return true end
                end
            end
        end

        -- PlayerOwnsAsset / OwnsAsset
        if method == "PlayerOwnsAsset" or method == "OwnsAsset" then
            if FakeData.globalOn then return true end
            local id = args[2] or args[1]
            if id then
                for _, e in ipairs(FakeData.gamepasses) do
                    if e.id == id then return true end
                end
                for _, e in ipairs(FakeData.products) do
                    if e.id == id then return true end
                end
            end
        end

        -- GetProductInfo / GetProductInfoAsync: mock owned
        if method == "GetProductInfo" or method == "GetProductInfoAsync" then
            local info = oldNC and oldNC(self, ...) or nil
            if type(info) == "table" then
                local id = args[1]
                local owned = FakeData.globalOn
                if not owned and id then
                    for _, e in ipairs(FakeData.gamepasses) do
                        if e.id == id then owned = true break end
                    end
                    if not owned then
                        for _, e in ipairs(FakeData.products) do
                            if e.id == id then owned = true break end
                        end
                    end
                end
                if owned then
                    info.IsOwned = true
                    info.IsForSale = true
                    info.PriceInRobux = 0
                end
            end
            return info
        end

        return oldNC and oldNC(self, ...) or nil
    end)

    pcall(function() setro(mt, true) end)
    notify("FAKE", "MarketplaceService hooked directly")
end

-- ═══ PROMPT DETECTION + AUTO-FAKE ═══
local function installDetectionHooks()
    if genv.BoltDetectHooks then return end
    genv.BoltDetectHooks = true

    local mt = getrawmt and getrawmt(game)
    if not mt then return end
    local old = mt.__namecall
    pcall(function() setro(mt, false) end)
    mt.__namecall = newc(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        local args = {...}

        if method == "PromptGamePassPurchase" then
            addFakeEntry(FakeData.gamepasses, args[2] or args[1], nil, "Prompt", true)
        elseif method == "PromptProductPurchase" then
            addFakeEntry(FakeData.products, args[2] or args[1], nil, "Prompt", false)
        elseif method == "UserOwnsGamePassAsync" then
            addFakeEntry(FakeData.gamepasses, args[2] or args[1], nil, "Check", true)
        elseif method == "GetProductInfo" then
            -- could be either; assume product
            addFakeEntry(FakeData.products, args[1], nil, "Info", false)
        end

        return old(self, ...)
    end)
    pcall(function() setro(mt, true) end)

    -- Also hook RemoteEvents for games that pass IDs through remotes
    local hooked = {}
    local function hookRemote(r)
        if hooked[r] then return end
        hooked[r] = true
        local rmt = getrawmt and getrawmt(r)
        if not rmt then return end
        local rold = rmt.__namecall
        pcall(function() setro(rmt, false) end)
        rmt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            if method == "FireServer" then
                local args = {...}
                -- Look for numeric args in the 1e5 to 1e13 range
                for _, a in ipairs(args) do
                    if type(a) == "number" and a >= 1e5 and a < 1e13 then
                        local nm = self.Name:lower()
                        if nm:find("pass") or nm:find("gamepass") then
                            addFakeEntry(FakeData.gamepasses, a, nil, "Remote:" .. self.Name, true)
                        elseif nm:find("product") or nm:find("devproduct") then
                            addFakeEntry(FakeData.products, a, nil, "Remote:" .. self.Name, false)
                        end
                    end
                end
            end
            return rold(self, ...)
        end)
        pcall(function() setro(rmt, true) end)
    end
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then hookRemote(r) end
    end

    notify("BOLT", "Prompt Inspector + Remote Scanner active")
end

-- ═══ FAKE ALL DETECTED ═══
local function fakeAllDetected()
    local count = 0
    for _, e in ipairs(FakeData.gamepasses) do
        fakePurchase(e.id, nil)
        count = count + 1
    end
    for _, e in ipairs(FakeData.products) do
        fakePurchase(nil, e.id)
        count = count + 1
    end
    notify("FAKE", "Fake blasted " .. count .. " items")
end

-- ═══ DEEP SCAN ═══
local function deepScanFakes()
    FakeData.gamepasses = {}
    FakeData.products = {}
    FakeData.seen = {}

    local roots = { workspace, ReplicatedStorage, StarterGui, Players, Lighting }
    for _, root in ipairs(roots) do
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
            elseif obj:IsA("ProximityPrompt") then
                local t = (obj.ActionText or "") .. " " .. (obj.ObjectText or "")
                for id in t:gmatch("%d%d%d%d%d+") do
                    addFakeEntry(FakeData.gamepasses, tonumber(id), "Prompt", obj:GetFullName(), true)
                end
            end
        end
    end

    notify("SCAN", "Deep scan · " .. #FakeData.gamepasses .. " gamepasses · " .. #FakeData.products .. " products")
end

-- ══════════════════════════════════════════════
--   ACTIONS — CORE
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
local function FlingAll()
    for _, p in ipairs(AllPlayers()) do pcall(Fling, p) end
end

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

local function Bring(target)
    if not target or not target.Character then return end
    local hrp = GetHRP() if not hrp then return end
    local t = target.Character:FindFirstChild("HumanoidRootPart")
    if t then SafeNO(t) t.CFrame = hrp.CFrame * CFrame.new(0, 0, 3) end
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
        for _, d in ipairs(h:GetChildren()) do
            if d:IsA("Decal") then d:Destroy() end
        end
    end
end

-- ─── PLAYER ───
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
                    table.insert(genv.BoltGfxStore, {obj = d, prop = "Enabled", val = true})
                    d.Enabled = false
                end
            elseif d:IsA("Decal") or d:IsA("Texture") then
                if d.Transparency < 1 then
                    table.insert(genv.BoltGfxStore, {obj = d, prop = "Transparency", val = d.Transparency})
                    d.Transparency = 1
                end
            elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                if d.Enabled then
                    table.insert(genv.BoltGfxStore, {obj = d, prop = "Enabled", val = true})
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
                pcall(function()
                    if e.obj and e.obj.Parent then e.obj[e.prop] = e.val end
                end)
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
    notify("BOLT", "Third-person zoom unlocked")
end

local function setShiftLock(state)
    if state == nil then state = not LP.DevEnableMouseLock end
    pcall(function() LP.DevEnableMouseLock = state end)
    pcall(function()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end)
    notify("BOLT", state and "Shift lock on" or "Shift lock off")
end

local function godMode(on)
    if genv.BoltGod then pcall(function() genv.BoltGod:Disconnect() end) genv.BoltGod = nil end
    if not on then return end
    genv.BoltGod = RunService.Heartbeat:Connect(function()
        local h = GetHum() if h then h.Health = h.MaxHealth end
    end)
    notify("BOLT", "God mode on (client-side)")
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
    notify("BOLT", "Auto clicker @ " .. genv.BoltCps .. " cps")
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
    notify("BOLT", "Following " .. target.Name)
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
        notify("BOLT", "Spectating " .. target.Name)
    end
end

local function fpsUnlock()
    local ok = pcall(function() setfpscap(1000) end)
    notify("BOLT", ok and "FPS unlocked" or "setfpscap not supported")
end

local function setScale(mult)
    local c = GetChar() if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            if not d:GetAttribute("BoltOrigSize") then
                d:SetAttribute("BoltOrigSize", d.Size)
            end
            d.Size = d:GetAttribute("BoltOrigSize") * mult
        end
    end
    notify("BOLT", "Scale ×" .. mult)
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

-- ─── ANTI-CHEAT ───
local function BypassKick()
    local mt = getrawmt and getrawmt(game)
    if not mt then notify("BOLT", "metatable access unavailable") return end
    local old = mt.__namecall
    pcall(function() setro(mt, false) end)
    mt.__namecall = newc(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod()
        if method == "Kick" then return end
        return old(self, ...)
    end)
    pcall(function() setro(mt, true) end)
    notify("BOLT", "Kick protection enabled")
end

local function feServerSideAntiKick()
    if genv.BoltFeKick then notify("BOLT", "Already active") return end
    BypassKick()
    local mt = getrawmt and getrawmt(game)
    if mt then
        local old = mt.__namecall
        pcall(function() setro(mt, false) end)
        mt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod()
            if self == LP and method == "Destroy" then return end
            if method == "Kick" then return end
            return old(self, ...)
        end)
        pcall(function() setro(mt, true) end)
    end
    genv.BoltFeKick = true
    notify("BOLT", "FE Serverside AntiKick active")
end

local function adonisBypass()
    if genv.BoltAdonis then notify("BOLT", "Already active") return end
    local blocked = {
        ["Kick"]=true,["Ban"]=true,["Detected"]=true,["IsBanned"]=true,
        ["CheckBan"]=true,["Detect"]=true,["Banned"]=true,["SetSetting"]=true,
    }
    local pfx = { "adonis", "ad0nis", "noob", "kick", "ban", "detect" }
    local mt = getrawmt and getrawmt(game)
    if not mt then notify("BOLT", "metatable access unavailable") return end
    local old = mt.__namecall
    pcall(function() setro(mt, false) end)
    mt.__namecall = newc(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if blocked[method] then return end
        local low = method:lower()
        for _, p in ipairs(pfx) do
            if low:sub(1, #p) == p then return end
        end
        return old(self, ...)
    end)
    pcall(function() setro(mt, true) end)
    genv.BoltAdonis = true
    notify("BOLT", "Adonis/NewIndex bypass active")
end

local function stopLagback(on)
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
end

-- ─── DEBUG ───
local function openConsole()
    StarterGui:SetCore("DevConsoleVisible", true)
    notify("BOLT", "Console opened")
end

local function dumpInstance(inst)
    if not inst then return end
    local lines = { inst:GetFullName() }
    local function rec(o, depth)
        if depth > 4 then return end
        for _, c in ipairs(o:GetChildren()) do
            table.insert(lines, string.rep("  ", depth) .. c.ClassName .. " — " .. c.Name)
            rec(c, depth + 1)
        end
    end
    rec(inst, 1)
    setclipboard(table.concat(lines, "\n"))
    notify("BOLT", "Dumped " .. #lines .. " lines")
end

local function remoteLogger(on)
    if genv.BoltRemoteLog then pcall(function() genv.BoltRemoteLog:Disconnect() end) genv.BoltRemoteLog = nil end
    if not on then return end
    local hooked = {}
    local function hookRemote(r)
        if hooked[r] then return end
        hooked[r] = true
        local mt = getrawmt and getrawmt(r)
        if not mt then return end
        local old = mt.__namecall
        pcall(function() setro(mt, false) end)
        mt.__namecall = newc(function(self, ...)
            local method = getnamecallmethod and getnamecallmethod()
            if method == "FireServer" then
                notify("REMOTE", self.Name .. " :: " .. tostring(select(1, ...)))
            end
            return old(self, ...)
        end)
        pcall(function() setro(mt, true) end)
    end
    local function scan(root)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then hookRemote(d) end
        end
    end
    scan(ReplicatedStorage)
    genv.BoltRemoteLog = true
    notify("BOLT", "Remote logger active")
end

-- ══════════════════════════════════════════════
--   UI
-- ══════════════════════════════════════════════
local SG = C("ScreenGui", {
    Name = "⚡BOLT HUB", ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = gethui()
})
genv.BoltHub = SG

local WIN_W, WIN_H = 1080, 660
local M = C("Frame", {
    Name = "Window",
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = BG, BorderSizePixel = 0,
    ClipsDescendants = true, Visible = true, Parent = SG
})
Cor(M, 10)
Stroke(M, EDGE, 1)

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
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(0, 14, 0.5, -10),
    BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = Top
})
Cor(LogoTile, 5)
drawBolt(LogoTile, 20)

C("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 42, 0, 0),
    BackgroundTransparency = 1, Text = "Bolt Hub",
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
        Tw(b, .1, {BackgroundTransparency = 0, BackgroundColor3 = hoverColor or CARD_H})
        Tw(b, .1, {TextColor3 = danger and RED or TX})
    end)
    b.MouseLeave:Connect(function()
        Tw(b, .1, {BackgroundTransparency = 1}); Tw(b, .1, {TextColor3 = TX_DIM})
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
Cor(Icon, 10)
Stroke(Icon, BLACK, 1, 0.7)
drawBolt(Icon, 34)

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
Icon.MouseEnter:Connect(function() Tw(Icon, .12, {BackgroundColor3 = GOLD_H}) end)
Icon.MouseLeave:Connect(function() Tw(Icon, .12, {BackgroundColor3 = GOLD}) end)

local function MinimizeToIcon() M.Visible = false; Icon.Visible = true end
local function RestoreFromIcon() M.Visible = true; Icon.Visible = false end

local maximized = false
local preMaxSize, preMaxPos = nil, nil
WinBtn("—", -102, function() MinimizeToIcon() end)
WinBtn("□", -68, function()
    maximized = not maximized
    if maximized then
        preMaxSize = M.Size
        preMaxPos = M.Position
        Tw(M, .22, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)})
    else
        Tw(M, .22, {
            Size = preMaxSize or UDim2.new(0, WIN_W, 0, WIN_H),
            Position = preMaxPos or UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        })
    end
end)
WinBtn("×", -34, function() SG:Destroy(); IconGui:Destroy() end, true, Color3.fromRGB(120, 30, 30))

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
    ScrollBarThickness = 3, ScrollBarImageColor3 = GOLD,
    ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Left
})
C("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ScSide})
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
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = PANEL, BorderSizePixel = 0, Parent = Center
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
SearchBox.Focused:Connect(function() Tw(SearchStroke, .15, {Color = GOLD, Transparency = 0.5}) end)
SearchBox.FocusLost:Connect(function() Tw(SearchStroke, .15, {Color = EDGE, Transparency = 0}) end)

local Sc = C("ScrollingFrame", {
    Size = UDim2.new(1, -24, 1, -88), Position = UDim2.new(0, 12, 0, 86),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 4, ScrollBarImageColor3 = GOLD,
    ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Center
})
local CL = C("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Sc})
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
    Size = UDim2.new(1, -20, 0, 220), Position = UDim2.new(0, 10, 0, 40),
    BackgroundColor3 = CARD, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = GOLD,
    ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Right
})
Cor(ScannerScroll, 5)
local ScanLayout = C("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ScannerScroll})
Pad(ScannerScroll, 8, 8, 8, 8)
ScanLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScannerScroll.CanvasSize = UDim2.new(0, 0, 0, ScanLayout.AbsoluteContentSize.Y + 16)
end)

C("TextLabel", {
    Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 18, 0, 270),
    BackgroundTransparency = 1, Text = "ACTIVITY",
    TextColor3 = TX_MUT, TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Right
})
local LogScroll = C("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -320), Position = UDim2.new(0, 10, 0, 292),
    BackgroundColor3 = CARD, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = GOLD,
    ScrollBarImageTransparency = 0.5,
    CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Right
})
Cor(LogScroll, 5)
local LogLayout = C("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = LogScroll})
Pad(LogScroll, 10, 10, 10, 10)
LogLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, LogLayout.AbsoluteContentSize.Y + 16)
    LogScroll.CanvasPosition = Vector2.new(0, LogLayout.AbsoluteContentSize.Y)
end)

local function renderLog()
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _, entry in ipairs(LogBuffer) do
        local row = C("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Parent = LogScroll
        })
        C("TextLabel", {
            Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
            Text = entry.stamp .. "  ·  " .. entry.title,
            TextColor3 = GOLD, TextSize = 10, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row
        })
        C("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 12),
            BackgroundTransparency = 1, Text = entry.text,
            TextColor3 = TX_DIM, TextSize = 10, Font = Enum.Font.Gotham,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = row
        })
    end
end
LogSink = renderLog

local function renderScanner()
    for _, c in ipairs(ScannerScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
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
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, Parent = row
            })
            local cp = C("TextButton", {
                Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(1, -92, 0, 13),
                BackgroundColor3 = Color3.fromRGB(32, 32, 36),
                Text = "copy", TextColor3 = TX_DIM, TextSize = 9,
                Font = Enum.Font.GothamMedium, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = row
            })
            Cor(cp, 3)
            cp.MouseButton1Click:Connect(function()
                setclipboard(tostring(e.id)); notify("BOLT", "Copied " .. e.id)
            end)
            local fk = C("TextButton", {
                Size = UDim2.new(0, 44, 0, 16), Position = UDim2.new(1, -48, 0, 13),
                BackgroundColor3 = GOLD, Text = "fake", TextColor3 = BLACK, TextSize = 9,
                Font = Enum.Font.GothamBold, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = row
            })
            Cor(fk, 3)
            fk.MouseButton1Click:Connect(function()
                fakePurchase(e.id, nil)
            end)
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
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, Parent = row
            })
            local cp = C("TextButton", {
                Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(1, -92, 0, 13),
                BackgroundColor3 = Color3.fromRGB(32, 32, 36),
                Text = "copy", TextColor3 = TX_DIM, TextSize = 9,
                Font = Enum.Font.GothamMedium, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = row
            })
            Cor(cp, 3)
            cp.MouseButton1Click:Connect(function()
                setclipboard(tostring(e.id)); notify("BOLT", "Copied " .. e.id)
            end)
            local fk = C("TextButton", {
                Size = UDim2.new(0, 44, 0, 16), Position = UDim2.new(1, -48, 0, 13),
                BackgroundColor3 = GOLD, Text = "fake", TextColor3 = BLACK, TextSize = 9,
                Font = Enum.Font.GothamBold, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = row
            })
            Cor(fk, 3)
            fk.MouseButton1Click:Connect(function()
                fakePurchase(nil, e.id)
            end)
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
        Size = UDim2.new(0, 120, 0, 16), Position = UDim2.new(1, x, 0.5, -8),
        BackgroundColor3 = PANEL, BackgroundTransparency = 1,
        Text = txt, TextColor3 = TX_DIM, TextSize = 10,
        Font = Enum.Font.Gotham, BorderSizePixel = 0,
        AutoButtonColor = false, Parent = Stat
    })
    b.MouseEnter:Connect(function() Tw(b, .1, {TextColor3 = GOLD}) end)
    b.MouseLeave:Connect(function() Tw(b, .1, {TextColor3 = TX_DIM}) end)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
    return b
end
FootBtn("copy discord  ·", -124, function()
    setclipboard("https://discord.gg/Ehte2SFpfu"); notify("BOLT", "Discord copied")
end)
FootBtn("v5.0.0  ", -14, function() end)

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
            Tw(v.t, .12, {TextColor3 = TX})
            v.accent.Visible = true
        else
            v.b.BackgroundColor3 = CARD
            v.stroke.Transparency = 1
            v.stroke.Color = EDGE
            Tw(v.t, .12, {TextColor3 = TX_DIM})
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
                if label then c.Visible = label.Text:lower():find(q, 1, true) ~= nil
                else c.Visible = false end
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
        if Active ~= name then Tw(b, .1, {BackgroundColor3 = CARD_H}) end
    end)
    b.MouseLeave:Connect(function()
        if Active ~= name then Tw(b, .1, {BackgroundColor3 = CARD}) end
    end)
    b.MouseButton1Click:Connect(function() SelTab(name) end)
    Tabs[name] = {b = b, t = t, accent = accent, stroke = stroke}
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
        Tw(b, .1, {BackgroundColor3 = CARD_H})
        Tw(bs, .1, {Color = GOLD, Transparency = 0.6})
    end)
    b.MouseLeave:Connect(function()
        Tw(b, .1, {BackgroundColor3 = CARD})
        Tw(bs, .1, {Color = EDGE, Transparency = 1})
    end)
    b.MouseButton1Click:Connect(function()
        Tw(b, .07, {BackgroundColor3 = GOLD})
        task.delay(.08, function() Tw(b, .2, {BackgroundColor3 = CARD_H}) end)
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
        Tw(b, .1, {BackgroundColor3 = CARD_H})
        Tw(bs, .1, {Color = EDGE_H, Transparency = 0.6})
    end)
    b.MouseLeave:Connect(function()
        Tw(b, .1, {BackgroundColor3 = CARD})
        Tw(bs, .1, {Color = EDGE, Transparency = 1})
    end)
    b.MouseButton1Click:Connect(function()
        state = not state
        Tw(tg, .15, {BackgroundColor3 = state and GOLD or Color3.fromRGB(52, 52, 58)})
        Tw(kn, .15, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
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
    Cor(b, 5)
    Stroke(b, EDGE, 1).Transparency = 1
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
    Cor(box, 4)
    Pad(box, 0, 10, 0, 10)
    local go = C("TextButton", {
        Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -74, 0, boxY),
        BackgroundColor3 = GOLD, Text = "GO", TextColor3 = BLACK,
        TextSize = 11, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
        AutoButtonColor = false, Parent = b
    })
    Cor(go, 4)
    go.MouseEnter:Connect(function() Tw(go, .1, {BackgroundColor3 = GOLD_H}) end)
    go.MouseLeave:Connect(function() Tw(go, .1, {BackgroundColor3 = GOLD}) end)
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
local tNetwork  = Tab("Network",    "🌐")
local tGames    = Tab("Games",      "🎮")
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
Btn(tDebug, "Open Dev Console", "F9-equivalent", openConsole)
Btn(tDebug, "Dump Workspace", "Clipboard: full hierarchy", function() dumpInstance(workspace) end)
Btn(tDebug, "Dump ReplicatedStorage", "Clipboard: full hierarchy", function() dumpInstance(ReplicatedStorage) end)
Btn(tDebug, "Dump LocalPlayer", "Clipboard: your instance tree", function() dumpInstance(LP) end)

Sec(tDebug, "Remotes")
Tog(tDebug, "Remote Logger", "Log every FireServer call", function(on) remoteLogger(on) end)
Btn(tDebug, "Cobalt Remote Spy", "Official GitLab release", function()
    loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))()
end)
Btn(tDebug, "Dark Dex v4", "BetterDecompiler built in", function()
    loadstring(game:HttpGet("https://github.com/OfficiallyMelon/BetterDecompiler/raw/main/dex_betterdecompiler.lua"))()
end)

-- ═══ ADMINS ═══
Sec(tAdmins, "Admin Scripts")
Btn(tAdmins, "Infinite Yield", "400+ commands", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)
Btn(tAdmins, "Nameless Admin", "Full admin suite", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"))()
end)

-- ═══ GUIS ═══
Sec(tGUIs, "Trolling / FE")
Btn(tGUIs, "TROLLING GUI", "Cause mass destruction", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/FE%20Trolling%20GUI.luau"))()
end)
Btn(tGUIs, "FE Trolling Player R6/R15", "3LD4D0", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/3LD4D0/FE-TROLLING-PLAYER-R6-R15/6eff8792afed57458d5114478b453a6f6bce5799/Fe%20trolling%20Player%20R6%20AND%20R15"))()
end)
Btn(tGUIs, "ROXCOM Troll GUI v3", "Keyless", function()
    loadstring(game:HttpGet("https://scriptverse.net/scripts/roxcom-troll-gui-v3"))()
end)
Btn(tGUIs, "FE Object Control Panel", "Become parts, auras, AI", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/All-Roblox-Scripts/fe-object-control/main/source.lua"))()
end)
Btn(tGUIs, "FE Prime Hub", "Green baseplate support", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ilikeices/script/refs/heads/main/primehubgreenbaseplatesupport.luau"))()
end)
Btn(tGUIs, "FE Ragdoll Engine", "Push Aura & Auto Ragdoll", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingLua/Hubs/main/Ragdoll%20Engine.lua"))()
end)
Btn(tGUIs, "FE Ender", "Fling + teleport", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ilikeices/script/refs/heads/main/ender.luau"))()
end)
Btn(tGUIs, "FE Headless", "Enable/disable headless", function()
    loadstring(game:HttpGet("https://gist.githubusercontent.com/TreeByte403/ae2620103048e56de7d0004e2df385d2/raw/ee3ac096491e5bc4bf99429ba80388b1cb75161e/FeHeadless.lua"))()
end)

-- ═══ MAIN ═══
Sec(tMain, "Character")
Tog(tMain, "Invisible (Clone)", "R6 / R15", function(on) Invisible(on) end)
Tog(tMain, "Fly", "WASD + Space / Shift", function(on) Fly(on) end)
Tog(tMain, "Noclip", "Disable collision", function(on) Noclip(on) end)
Tog(tMain, "Spin Self", "Rotate your character", function(on) SpinSelf(on) end)
Tog(tMain, "Spin All", "Rotate every other player", function(on) SpinAll(on) end)
Tog(tMain, "Gravity Flip", "Restores on off", function(on)
    if on then
        if not genv.BoltGrav then
            genv.BoltGravOrig = workspace.Gravity
            workspace.Gravity = -math.abs(workspace.Gravity)
            genv.BoltGrav = true
        end
    else
        if genv.BoltGrav then
            workspace.Gravity = genv.BoltGravOrig or 196.2
            genv.BoltGrav = false
        end
    end
end)

Sec(tMain, "Speed / Jump")
Inp(tMain, "Set WalkSpeed", "Numeric value", "16", function(v)
    local n = tonumber(v); if not n then return end
    local h = GetHum(); if h then h.WalkSpeed = n end
    notify("BOLT", "WalkSpeed = " .. n)
end)
Inp(tMain, "Set JumpPower", "Numeric value", "50", function(v)
    local n = tonumber(v); if not n then return end
    local h = GetHum(); if h then h.JumpPower = n end
    notify("BOLT", "JumpPower = " .. n)
end)
Inp(tMain, "Set Fly Speed", "Applies next Fly toggle", "80", function(v)
    local n = tonumber(v); if n then genv.BoltFlySpeed = n notify("BOLT", "Fly Speed = " .. n) end
end)
Inp(tMain, "Set Hip Height", "Applies immediately", "2", function(v)
    local n = tonumber(v); if not n then return end
    local h = GetHum(); if h then h.HipHeight = n end
    notify("BOLT", "HipHeight = " .. n)
end)
Btn(tMain, "Speed 100", "Preset", function()
    local h = GetHum(); if h then h.WalkSpeed = 100 end
end)
Btn(tMain, "Speed 250", "Preset", function()
    local h = GetHum(); if h then h.WalkSpeed = 250 end
end)

Sec(tMain, "Fling")
Tog(tMain, "Fling All (Loop)", "Continuous fling", function(on)
    if on then
        genv.BoltFlingAll = true
        task.spawn(function()
            while genv.BoltFlingAll do FlingAll() task.wait(.15) end
        end)
    else genv.BoltFlingAll = false end
end)
Btn(tMain, "Fling Once", "One-shot fling on all", FlingAll)
Btn(tMain, "Fling Random", "Fling a random player", function()
    local ps = AllPlayers(); if #ps > 0 then Fling(ps[math.random(#ps)]) end
end)
Btn(tMain, "Fling Mouse Target", "Fling the player under your cursor", function()
    local t = Mouse.Target
    if t then
        local m = t:FindFirstAncestorOfClass("Model")
        if m then
            local plr = Players:GetPlayerFromCharacter(m)
            if plr then Fling(plr) end
        end
    end
end)

Sec(tMain, "Player Control")
Btn(tMain, "Ragdoll Self", "Break joints", Ragdoll)
Btn(tMain, "TP All to Me", "Teleport everyone to your position", function()
    local hrp = GetHRP(); if not hrp then return end
    for _, p in ipairs(AllPlayers()) do
        if p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart")
            if t then
                pcall(function() t.CFrame = hrp.CFrame * CFrame.new(math.random(-12,12), 0, math.random(-12,12)) end)
            end
        end
    end
end)
Btn(tMain, "Freeze All", "WalkSpeed / JumpPower = 0", function()
    for _, p in ipairs(AllPlayers()) do pcall(Freeze, p) end
end)
Btn(tMain, "Thaw All", "Restore stats", function()
    for _, p in ipairs(AllPlayers()) do pcall(Thaw, p) end
end)
Btn(tMain, "Bring Random", "Bring one random player", function()
    local ps = AllPlayers(); if #ps > 0 then Bring(ps[math.random(#ps)]) end
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
Inp(tVR, "VR Fly Speed", "Studs / sec", "80", function(v)
    local n = tonumber(v); if n then genv.BoltFlySpeed = n notify("BOLT", "VR Fly = " .. n) end
end)

Sec(tVR, "Tuning")
Btn(tVR, "Hand Scale 1.5", "Bigger hands", function()
    pcall(function() LP.VRScale = 1.5 end)
    notify("BOLT", "VR hand scale 1.5")
end)
Btn(tVR, "Hand Scale 1.0", "Normal hands", function()
    pcall(function() LP.VRScale = 1.0 end)
    notify("BOLT", "VR hand scale 1.0")
end)
Btn(tVR, "Hand Scale 0.5", "Smaller hands", function()
    pcall(function() LP.VRScale = 0.5 end)
    notify("BOLT", "VR hand scale 0.5")
end)

-- ═══ FAKERS — GOD TIER ═══
Sec(tFakers, "Global Mode")
Tog(tFakers, "Global Fake (Everything Owned)", "Every gamepass/product query returns true", function(on)
    FakeData.globalOn = on
    installMarketplaceHooks()
    notify("FAKE", on and "GLOBAL MODE ON — everything reads as owned" or "Global mode off")
end)
Tog(tFakers, "Auto-Fake on Detect", "Immediately blast when a prompt is captured", function(on)
    FakeData.autoFake = on
    notify("FAKE", on and "Auto-Fake enabled" or "Auto-Fake disabled")
end)

Sec(tFakers, "Scanner")
Btn(tFakers, "Deep Scan Game", "Find all gamepasses + products", deepScanFakes)
Btn(tFakers, "Refresh Scanner", "Re-render the scanner panel", renderScanner)
Btn(tFakers, "Fake ALL Detected", "Blast every captured ID at once", fakeAllDetected)
Btn(tFakers, "Clear Scan Results", "Wipe detected IDs", function()
    FakeData.gamepasses = {}; FakeData.products = {}; FakeData.seen = {}
    renderScanner(); notify("SCAN", "Results cleared")
end)

Sec(tFakers, "Manual Fake")
Inp(tFakers, "Fake Gamepass by ID", "Enter gamepass ID", "gamepass id...", function(id)
    fakePurchase(id, nil)
end)
Inp(tFakers, "Fake Product by ID", "Enter product ID", "product id...", function(id)
    fakePurchase(nil, id)
end)

Sec(tFakers, "Engine Info")
Btn(tFakers, "Check Executor Support", "replicatesignal / firesignal / hookmetamethod", function()
    notify("SUPPORT", "replicatesignal → " .. tostring(hasReplicateSignal))
    notify("SUPPORT", "firesignal       → " .. tostring(hasFireSignal))
    notify("SUPPORT", "hookmetamethod   → " .. tostring(hasHookMethod))
    notify("SUPPORT", "cloneref         → " .. tostring(hasCloneRef))
end)
Btn(tFakers, "Reinstall Hooks", "Force reinstall MP + detection hooks", function()
    FakeData.hookedMP = false
    genv.BoltDetectHooks = false
    installMarketplaceHooks()
    installDetectionHooks()
    notify("FAKE", "Hooks reinstalled")
end)

-- ═══ NETWORK ═══
Sec(tNetwork, "Ownership")
Btn(tNetwork, "Claim All Parts", "Set network ownership", function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then SafeNO(obj) end
    end
    notify("BOLT", "Ownership claimed")
end)
Btn(tNetwork, "Release All Parts", "Return to server", function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            pcall(function() obj:SetNetworkOwner(nil) end)
        end
    end
    notify("BOLT", "Ownership released")
end)

-- ═══ GAMES ═══
Sec(tGames, "Popular Games")
Btn(tGames, "MM2", "Auto Kill, Kill All, Auto Farm", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/as6cd0/SP_Hub/refs/heads/main/Loader"))()
end)
Btn(tGames, "Ragdoll Engine", "Kill Fling & FE Size", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/TestingLua/Hubs/main/Ragdoll%20Engine.lua"))()
end)
Btn(tGames, "Brookhaven RP", "FE Troll, Kill All, Teleport", function()
    loadstring(game:HttpGet("https://github.com/bruton-dev/Scripts/raw/refs/heads/main/Hug.lua"))()
end)
Btn(tGames, "Blox Fruits", "Auto Farm, Kill Aura, ESP", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Blox-Fruits/main/SPHub"))()
end)
Btn(tGames, "Da Hood", "Kill All, Fling All, Auto Farm", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Da-Hood/main/SPHub"))()
end)
Btn(tGames, "Arsenal", "Aimbot, ESP, Silent Aim", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Arsenal/main/SPHub"))()
end)
Btn(tGames, "Jailbreak", "Auto Rob, Kill All, ESP", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Jailbreak/main/SPHub"))()
end)
Btn(tGames, "Prison Life", "Kill All, Gun Mods, Teleports", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Prison-Life/main/SPHub"))()
end)
Btn(tGames, "Natural Disaster Survival", "Survive All, Teleports", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/NDS/main/SPHub"))()
end)
Btn(tGames, "Tower of Hell", "Skip Stages, Fly, Noclip", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/TOH/main/SPHub"))()
end)
Btn(tGames, "Pet Sim X / 99", "Auto Farm, Dupe, Coins", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Pet-Sim/main/SPHub"))()
end)
Btn(tGames, "Bedwars", "Kill All, Auto Win, Fly", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Bedwars/main/SPHub"))()
end)
Btn(tGames, "Doors", "ESP, Auto Win, Skip", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Doors/main/SPHub"))()
end)
Btn(tGames, "Rainbow Friends", "Kill All, ESP, Teleport", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Rainbow-Friends/main/SPHub"))()
end)
Btn(tGames, "Blade Ball", "Auto Parry, Kill All", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/Blade-Ball/main/SPHub"))()
end)
Btn(tGames, "RIVALS", "Aimbot, ESP, Silent Aim", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SP-Hub/RIVALS/main/SPHub"))()
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

local function ExploiterChat()
    if genv.BoltExploitChat then return end
    genv.BoltExploitChat = LP.Chatted:Connect(function(msg)
        if msg:sub(1, 6):lower() == "/bolt " then SendChat("[BOLT] " .. msg:sub(7)) end
    end)
    notify("BOLT", "Exploiter chat on — use /bolt <msg>")
end

Sec(tChat, "Exploiter Chat")
Btn(tChat, "Enable Exploiter Chat", "Use /bolt <message>", ExploiterChat)
Btn(tChat, "Say [BOLT]", "Preset message", function() SendChat("[BOLT] I am here") end)
Inp(tChat, "Custom Chat", "Prefixes [BOLT]", "type message...", function(msg)
    if msg ~= "" then SendChat("[BOLT] " .. msg) end
end)

-- ═══ BYPASS AC ═══
Sec(tBypass, "Anti-Cheat")
Btn(tBypass, "Anti Kick", "Basic Kick namecall block", BypassKick)
Btn(tBypass, "FE Serverside AntiKick", "Layered: Kick + Destroy + remote guard", feServerSideAntiKick)
Btn(tBypass, "Adonis / NewIndex Bypass", "Block admin detection methods", adonisBypass)
Tog(tBypass, "Stop Lagback", "Snap-back position protection", function(on) stopLagback(on) end)
Btn(tBypass, "Universal AC Bypass", "External script", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BaconCheats/Leaked/refs/heads/main/AntiCheatBypass.lua"))()
end)

-- ═══ SETTINGS ═══
Sec(tSettings, "Window")
Btn(tSettings, "Cycle Opacity", "0% → 15% → 30% → 0%", function()
    local cur = M.BackgroundTransparency or 0
    local next_ = (math.floor(cur * 100) + 15) % 45
    Tw(M, .15, {BackgroundTransparency = next_ / 100})
    notify("BOLT", "Opacity: " .. next_ .. "%")
end)

Sec(tSettings, "Reset")
Btn(tSettings, "Stop All Loops", "Kill Fly, Noclip, Spin, etc.", function()
    if genv.BoltFly then genv.BoltFly:Disconnect() genv.BoltFly = nil end
    if genv.BoltFlyBV then genv.BoltFlyBV:Destroy() genv.BoltFlyBV = nil end
    if genv.BoltNoclip then genv.BoltNoclip:Disconnect() genv.BoltNoclip = nil end
    if genv.BoltSpin then genv.BoltSpin:Disconnect() genv.BoltSpin = nil end
    if genv.BoltSpinAll then genv.BoltSpinAll:Disconnect() genv.BoltSpinAll = nil end
    if genv.BoltFullbright then genv.BoltFullbright:Disconnect() genv.BoltFullbright = nil end
    if genv.BoltLagback then genv.BoltLagback:Disconnect() genv.BoltLagback = nil end
    if genv.BoltAntiAfk then genv.BoltAntiAfk:Disconnect() genv.BoltAntiAfk = nil end
    if genv.BoltGod then genv.BoltGod:Disconnect() genv.BoltGod = nil end
    if genv.BoltRegen then genv.BoltRegen:Disconnect() genv.BoltRegen = nil end
    if genv.BoltFollow then genv.BoltFollow:Disconnect() genv.BoltFollow = nil end
    if genv.BoltInfJump then genv.BoltInfJump:Disconnect() genv.BoltInfJump = nil end
    genv.BoltFlingAll = false
    genv.BoltAutoClick = false
    notify("BOLT", "All loops stopped")
end)

Btn(tSettings, "Reset Lighting", "Restore default", function()
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 100000
    notify("BOLT", "Lighting reset")
end)

Sec(tSettings, "Session")
Btn(tSettings, "Restart Hub", "Destroy and reload", function()
    if genv.BoltHub then genv.BoltHub:Destroy() end
    if genv.BoltIcon then genv.BoltIcon:Destroy() end
    notify("BOLT", "Hub destroyed — re-execute to reload")
end)
Btn(tSettings, "Unload Hub", "Close UI completely", function()
    SG:Destroy(); IconGui:Destroy()
end)

-- ══════════════════════════════════════════════
--   INIT
-- ══════════════════════════════════════════════
SelTab(tMain)
renderScanner()
installDetectionHooks()
installMarketplaceHooks()

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if M.Visible then MinimizeToIcon() else RestoreFromIcon() end
    end
end)

task.defer(function()
    task.wait(1)
    notify("BOLT", "replicatesignal: " .. tostring(hasReplicateSignal))
    notify("BOLT", "firesignal: " .. tostring(hasFireSignal))
end)

notify("BOLT", "Bolt Hub loaded · welcome, " .. LP.Name)
