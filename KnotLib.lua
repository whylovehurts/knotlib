--[[
    KnotLib v3.2.0 - Apex Modern Edition (Neo-Dark UI)
    UI Library for Roblox (LuaU)
    
    v3.2 Changelog:
      - Reactive Theme System: ALL components update live on theme switch
      - Dropdown Auto-Update: :SetValues() + ValuesFunction (auto-refresh on open)
      - Fixed Destroy Modal (ZIndex 100+, overlay, task.defer)
      - Round toggle button image (ClipsDescendants + UICorner)
      - Color Picker (HSV sliders + hex preview)
      - Player List with avatars & auto-refresh
      - Separator, Notify with types (success/error/warning)
]]

-- ============================================
-- SERVICES
-- ============================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- THEME & DESIGN TOKENS
-- ============================================
local Theme = {
    Background       = Color3.fromRGB(16, 16, 20),
    ToggleBarBg      = Color3.fromRGB(22, 22, 28),
    MainFrameBg      = Color3.fromRGB(20, 20, 26),
    TabsBg           = Color3.fromRGB(22, 22, 28),
    CurrentTabBg     = Color3.fromRGB(18, 18, 24),
    ComponentBg      = Color3.fromRGB(28, 28, 36),
    Hover            = Color3.fromRGB(36, 36, 46),

    Accent           = Color3.fromRGB(99, 102, 241),
    AccentHover      = Color3.fromRGB(129, 140, 248),

    TextPrimary      = Color3.fromRGB(245, 245, 250),
    TextSecondary    = Color3.fromRGB(160, 160, 175),
    TextTertiary     = Color3.fromRGB(110, 110, 125),

    ToggleOn         = Color3.fromRGB(99, 102, 241),
    ToggleOff        = Color3.fromRGB(45, 45, 58),
    SliderFill       = Color3.fromRGB(99, 102, 241),
    SliderBg         = Color3.fromRGB(38, 38, 48),
    DropdownBg       = Color3.fromRGB(24, 24, 32),
    DropdownItem     = Color3.fromRGB(32, 32, 42),
    NotifyBg         = Color3.fromRGB(24, 24, 32),
    InputBg          = Color3.fromRGB(14, 14, 18),
    RimLight         = Color3.fromRGB(255, 255, 255),
    PlayerListBg     = Color3.fromRGB(22, 22, 28),

    TitleFont            = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    ModalFont            = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
    ComponentFont        = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
    ComponentFontRegular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),

    CornerRadius      = UDim.new(0, 10),
    CornerRadiusModal = UDim.new(0, 14),
    CornerRadiusSmall = UDim.new(0, 6),
    CornerRadiusPill  = UDim.new(0, 50),
    TweenSpeed        = 0.20,
    TweenEasing       = Enum.EasingStyle.Quart,
}

-- ============================================
-- UTILITIES
-- ============================================
local function Tween(instance, props, duration, style, direction)
    local info = TweenInfo.new(duration or Theme.TweenSpeed, style or Theme.TweenEasing, direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

local function Create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = radius or Theme.CornerRadius, Parent = parent })
end

local function AddPadding(parent, top, right, bottom, left)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0), PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0), PaddingLeft = UDim.new(0, left or 0), Parent = parent,
    })
end

local function AddListLayout(parent, padding, direction, hAlign, vAlign)
    return Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6), SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top, Parent = parent,
    })
end

local function AddRimLight(parent, color, transparency, thickness)
    return Create("UIStroke", {
        Color = color or Theme.RimLight, Thickness = thickness or 1,
        Transparency = transparency or 0.90, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent,
    })
end

local function AddSafeShadow(parent)
    local ok, shadow = pcall(function() return Instance.new("UIShadow") end)
    if ok and shadow then shadow.Parent = parent; return shadow end
    return Create("UIStroke", { Color = Color3.fromRGB(0,0,0), Thickness = 2, Transparency = 0.5, Parent = parent })
end

local function GetParentGui()
    local s, r = pcall(function() if typeof(gethui) == "function" then return gethui() end end)
    if s and r then return r end
    local s2, r2 = pcall(function() return game:GetService("CoreGui") end)
    if s2 and r2 then return r2 end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function AutoDetectGameName()
    local s, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if s and info and info.Name and info.Name ~= "" then return info.Name end
    return game.Name or "KnotHub"
end

local function MakeDraggable(dragHandle, targetFrame)
    local dragging, dragStart, startPos = false, nil, nil
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = targetFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(targetFrame, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) }, 0.05)
        end
    end)
end

-- ============================================
-- LIBRARY (Singleton)
-- ============================================
local Library = {}
Library.__index = Library
Library.Version = "3.2.0"
Library.Options = {}
Library.Flags = Library.Options
Library.Unloaded = false
Library._windows = {}
Library._connections = {}
Library._contacts = {}
Library._screenGui = nil
Library._notifyHolder = nil
Library._orderCounter = 0
Library._themeCallbacks = {} -- Reactive theme system

function Library:_getOrder() self._orderCounter = self._orderCounter + 1; return self._orderCounter end
function Library:_registerOption(flag, component) if flag and flag ~= "" then self.Options[flag] = component end end
function Library:_addConnection(conn) table.insert(self._connections, conn); return conn end

-- ============================================
-- REACTIVE THEME SYSTEM
-- ============================================
function Library:_onThemeChange(fn)
    table.insert(self._themeCallbacks, fn)
end

function Library:_fireThemeChange()
    for _, fn in ipairs(self._themeCallbacks) do
        pcall(fn)
    end
end

function Library:SetAccent(color)
    Theme.Accent = color
    Theme.ToggleOn = color
    Theme.SliderFill = color
    self:_fireThemeChange()
end

function Library:AddContact(platform, link)
    table.insert(self._contacts, { Platform = platform or "Social", Link = link or "" })
    for _, win in ipairs(self._windows) do if win._refreshCredits then win:_refreshCredits() end end
end

-- Forward declarations
local Window = {}; Window.__index = Window
local Tab = {}; Tab.__index = Tab
local Section = {}; Section.__index = Section

-- ============================================
-- WINDOW CREATION
-- ============================================
function Library:CreateWindow(opts)
    opts = opts or {}
    local size = opts.Size or UDim2.fromOffset(760, 420)
    local minimizeKey = opts.MinimizeKey or Enum.KeyCode.RightShift

    local win = setmetatable({}, Window)
    win._library = self
    win._tabs = {}
    win._selectedTab = nil
    win._visible = true
    win._minimizeKey = minimizeKey
    win._userTabsCount = 0

    local screenGui = Create("ScreenGui", {
        Name = "KnotLib_Modern", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false, Parent = GetParentGui(),
    })
    self._screenGui = screenGui
    win._screenGui = screenGui

    -- Main Shell
    local main = Create("Frame", {
        Name = "Main", BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Size = size, Position = UDim2.new(0.5, -(size.X.Offset / 2), 0.5, -(size.Y.Offset / 2)),
        Parent = screenGui,
    })
    AddCorner(main, Theme.CornerRadius)
    AddRimLight(main, Theme.RimLight, 0.88, 1)
    AddSafeShadow(main)
    win._main = main

    -- Top Header Bar
    local toggleBar = Create("Frame", {
        Name = "ToggleBar", BackgroundColor3 = Theme.ToggleBarBg, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52), Parent = main,
    })
    AddCorner(toggleBar, Theme.CornerRadius)
    AddRimLight(toggleBar, Theme.RimLight, 0.92, 1)
    Create("Frame", { BackgroundColor3 = Theme.ToggleBarBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), Parent = toggleBar })

    -- Status Dot (accent-reactive)
    local statusDot = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 20, 0.5, -4), Parent = toggleBar })
    AddCorner(statusDot, Theme.CornerRadiusPill)
    win._statusDot = statusDot
    self:_onThemeChange(function()
        statusDot.BackgroundColor3 = Theme.Accent
    end)

    -- Auto Detect Game Name
    local gameNameLabel = Create("TextLabel", {
        Name = "GameName", BackgroundTransparency = 1, FontFace = Theme.TitleFont,
        TextColor3 = Theme.TextPrimary, TextScaled = true, Text = "Detecting Game...",
        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0, 520, 0, 36),
        Position = UDim2.new(0, 38, 0, 8), Parent = toggleBar,
    })
    Create("UITextSizeConstraint", { MaxTextSize = 22, MinTextSize = 14, Parent = gameNameLabel })
    win._gameNameLabel = gameNameLabel
    task.spawn(function() gameNameLabel.Text = AutoDetectGameName() end)

    MakeDraggable(toggleBar, main)

    -- Content Area
    local mainFrame = Create("Frame", {
        Name = "MainFrame", BackgroundColor3 = Theme.MainFrameBg, BorderSizePixel = 0,
        Size = UDim2.new(1, -24, 1, -68), Position = UDim2.new(0, 12, 0, 60), Parent = main,
    })
    AddCorner(mainFrame, Theme.CornerRadiusSmall)
    AddRimLight(mainFrame, Theme.RimLight, 0.94, 1)
    win._mainFrame = mainFrame

    -- Sidebar
    local tabsSidebar = Create("Frame", {
        Name = "Sidebar", BackgroundColor3 = Theme.TabsBg, BorderSizePixel = 0,
        Size = UDim2.new(0, 130, 1, -16), Position = UDim2.new(0, 8, 0, 8), Parent = mainFrame,
    })
    AddCorner(tabsSidebar, Theme.CornerRadiusSmall)
    AddRimLight(tabsSidebar, Theme.RimLight, 0.95, 1)
    win._tabsSidebar = tabsSidebar

    -- User Tabs Scrolling List
    local userTabsScroll = Create("ScrollingFrame", {
        Name = "UserTabsList", BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, -12, 1, -80), Position = UDim2.new(0, 6, 0, 6),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextTertiary,
        CanvasSize = UDim2.new(0, 0, 0, 0), Parent = tabsSidebar,
    })
    local userTabsLayout = AddListLayout(userTabsScroll, 4)
    userTabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        userTabsScroll.CanvasSize = UDim2.new(0, 0, 0, userTabsLayout.AbsoluteContentSize.Y + 8)
    end)
    win._userTabsScroll = userTabsScroll

    -- Divider
    Create("Frame", { BackgroundColor3 = Theme.TextTertiary, BackgroundTransparency = 0.8, BorderSizePixel = 0, Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, -70), Parent = tabsSidebar })

    -- Fixed System Tabs
    local fixedTabsContainer = Create("Frame", {
        Name = "FixedTabs", BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 60),
        Position = UDim2.new(0, 6, 1, -64), Parent = tabsSidebar,
    })
    AddListLayout(fixedTabsContainer, 4)

    -- Current Tab Viewport
    local currentTabFrame = Create("Frame", {
        Name = "CurrentTab", BackgroundColor3 = Theme.CurrentTabBg, BorderSizePixel = 0,
        Size = UDim2.new(1, -154, 1, -16), Position = UDim2.new(0, 146, 0, 8),
        ClipsDescendants = true, Parent = mainFrame,
    })
    AddCorner(currentTabFrame, Theme.CornerRadiusSmall)
    AddRimLight(currentTabFrame, Theme.RimLight, 0.94, 1)
    win._currentTabFrame = currentTabFrame

    -- ===== FLOATING PILL TOGGLE BUTTON =====
    local toggleButton = Create("TextButton", {
        Name = "FloatingToggle", BackgroundColor3 = Theme.ToggleBarBg,
        Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 25, 0.5, -23),
        Text = "", AutoButtonColor = false, ZIndex = 100, Parent = screenGui,
    })
    AddCorner(toggleButton, Theme.CornerRadiusPill)
    local toggleBtnRim = AddRimLight(toggleButton, Theme.Accent, 0.2, 2)
    AddSafeShadow(toggleButton)

    local toggleIcon = Create("ImageLabel", {
        BackgroundTransparency = 1, Image = "rbxassetid://15405680763",
        ScaleType = Enum.ScaleType.Fit,
        Size = UDim2.fromOffset(28, 28), Position = UDim2.new(0.5, -14, 0.5, -14),
        Parent = toggleButton,
    })
    AddCorner(toggleIcon, Theme.CornerRadiusPill)
    toggleIcon.ClipsDescendants = true
    win._toggleButton = toggleButton
    MakeDraggable(toggleButton, toggleButton)

    -- Reactive: update floating toggle rim color
    self:_onThemeChange(function()
        toggleBtnRim.Color = Theme.Accent
    end)

    toggleButton.MouseButton1Click:Connect(function() win:ToggleVisibility() end)
    toggleButton.MouseEnter:Connect(function() Tween(toggleButton, { Size = UDim2.fromOffset(50, 50) }, 0.15) end)
    toggleButton.MouseLeave:Connect(function() Tween(toggleButton, { Size = UDim2.fromOffset(46, 46) }, 0.15) end)

    -- ===== CLOSE BUTTON & DESTROY MODAL =====
    local closeBtn = Create("TextButton", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextSecondary,
        TextSize = 18, Text = "X", Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -44, 0.5, -18), ZIndex = 5, Parent = toggleBar,
    })
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, { TextColor3 = Color3.fromRGB(255, 70, 85) }, 0.15) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, { TextColor3 = Theme.TextSecondary }, 0.15) end)

    local overlay = Create("TextButton", {
        Name = "DestroyOverlay", BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
        Visible = false, ZIndex = 90, Parent = main,
    })

    local destroyModal = Create("Frame", {
        Name = "DestroyModal", BackgroundColor3 = Color3.fromRGB(20, 20, 26),
        Size = UDim2.fromOffset(300, 170), Position = UDim2.new(0.5, -150, 0.5, -85),
        Visible = false, ZIndex = 100, Parent = main,
    })
    AddCorner(destroyModal, Theme.CornerRadiusModal)
    AddRimLight(destroyModal, Color3.fromRGB(255, 70, 85), 0.4, 2)
    AddSafeShadow(destroyModal)

    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.TitleFont, TextColor3 = Theme.TextPrimary,
        TextSize = 20, Text = "Close & Destroy UI?", Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 20), ZIndex = 101, Parent = destroyModal,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextSecondary,
        TextSize = 13, Text = "This will unload the hub and remove all connections.",
        Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 20, 0, 50),
        TextWrapped = true, ZIndex = 101, Parent = destroyModal,
    })

    local yesBtn = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(239, 68, 68), FontFace = Theme.ComponentFont,
        TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, Text = "Yes, Destroy",
        Size = UDim2.new(0, 120, 0, 38), Position = UDim2.new(0, 20, 1, -54),
        AutoButtonColor = false, ZIndex = 102, Parent = destroyModal,
    })
    AddCorner(yesBtn, Theme.CornerRadiusSmall)

    local noBtn = Create("TextButton", {
        BackgroundColor3 = Theme.ComponentBg, FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextPrimary, TextSize = 14, Text = "Cancel",
        Size = UDim2.new(0, 120, 0, 38), Position = UDim2.new(1, -140, 1, -54),
        AutoButtonColor = false, ZIndex = 102, Parent = destroyModal,
    })
    AddCorner(noBtn, Theme.CornerRadiusSmall)
    AddRimLight(noBtn, Theme.RimLight, 0.85, 1)

    yesBtn.MouseEnter:Connect(function() Tween(yesBtn, { BackgroundColor3 = Color3.fromRGB(255, 85, 85) }, 0.15) end)
    yesBtn.MouseLeave:Connect(function() Tween(yesBtn, { BackgroundColor3 = Color3.fromRGB(239, 68, 68) }, 0.15) end)
    noBtn.MouseEnter:Connect(function() Tween(noBtn, { BackgroundColor3 = Theme.Hover }, 0.15) end)
    noBtn.MouseLeave:Connect(function() Tween(noBtn, { BackgroundColor3 = Theme.ComponentBg }, 0.15) end)

    local function showModal(v) destroyModal.Visible = v; overlay.Visible = v end
    closeBtn.MouseButton1Click:Connect(function() showModal(not destroyModal.Visible) end)
    overlay.MouseButton1Click:Connect(function() showModal(false) end)
    yesBtn.MouseButton1Click:Connect(function() showModal(false); task.defer(function() self:Destroy() end) end)
    noBtn.MouseButton1Click:Connect(function() showModal(false) end)

    -- Minimize Keybind
    self:_addConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == minimizeKey then win:ToggleVisibility() end
    end))

    -- Notifications Viewport
    if not self._notifyHolder then
        self._notifyHolder = Create("Frame", {
            Name = "NotifyHolder", BackgroundTransparency = 1,
            Size = UDim2.new(0, 300, 1, -20), Position = UDim2.new(1, -310, 0, 10), Parent = screenGui,
        })
        local notifyLayout = AddListLayout(self._notifyHolder, 8)
        notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end

    table.insert(self._windows, win)
    win:_initBuiltInTabs(fixedTabsContainer)
    return win
end

-- ============================================
-- WINDOW METHODS
-- ============================================
function Window:ToggleVisibility()
    self._visible = not self._visible
    if self._visible then
        self._main.Visible = true
        Tween(self._main, { Size = UDim2.fromOffset(760, 420), BackgroundTransparency = 0 }, 0.22)
    else
        Tween(self._main, { Size = UDim2.fromOffset(760, 0), BackgroundTransparency = 1 }, 0.22)
        task.delay(0.22, function() if not self._visible then self._main.Visible = false end end)
    end
end
function Window:Destroy() self._library:Destroy() end
function Window:SelectTab(tab) if type(tab) == "number" then tab = self._tabs[tab] end; if tab then tab:_select() end end

-- ============================================
-- TAB CREATION
-- ============================================
function Window:_createTabElement(title, parentContainer, order)
    local tab = setmetatable({}, Tab)
    tab._window = self; tab._library = self._library; tab._title = title; tab._sections = {}

    local tabButton = Create("TextButton", {
        Name = title, BackgroundColor3 = Theme.TabsBg, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28), FontFace = Theme.ComponentFont, TextColor3 = Theme.TextSecondary,
        TextSize = 13, Text = "   " .. title, TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false, LayoutOrder = order or 1, Parent = parentContainer,
    })
    AddCorner(tabButton, Theme.CornerRadiusSmall)

    local indicator = Create("Frame", {
        BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 2, 0.2, 0), BackgroundTransparency = 1, Parent = tabButton,
    })
    AddCorner(indicator, Theme.CornerRadiusPill)
    tab._indicator = indicator; tab._tabButton = tabButton

    -- Reactive: update indicator accent color when active
    self._library:_onThemeChange(function()
        if self._selectedTab == tab then
            indicator.BackgroundColor3 = Theme.Accent
        end
    end)

    local tabPage = Create("ScrollingFrame", {
        Name = "Page_" .. title, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.TextTertiary,
        CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = self._currentTabFrame,
    })
    local pageLayout = AddListLayout(tabPage, 8)
    AddPadding(tabPage, 12, 12, 12, 12)
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 24)
    end)
    tab._tabPage = tabPage

    tabButton.MouseButton1Click:Connect(function() tab:_select() end)
    tabButton.MouseEnter:Connect(function() if self._selectedTab ~= tab then Tween(tabButton, { BackgroundTransparency = 0.6, BackgroundColor3 = Theme.Hover }, 0.15) end end)
    tabButton.MouseLeave:Connect(function() if self._selectedTab ~= tab then Tween(tabButton, { BackgroundTransparency = 1 }, 0.15) end end)

    table.insert(self._tabs, tab)
    return tab
end

function Window:AddTab(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    self._userTabsCount = self._userTabsCount + 1
    local tab = self:_createTabElement(opts.Title or "Tab", self._userTabsScroll, self._userTabsCount)
    if not self._selectedTab then tab:_select() end
    return tab
end

function Window:_initBuiltInTabs(container)
    -- Config Tab
    local configTab = self:_createTabElement("Config", container, 1)
    local cfgSec = configTab:AddSection("Color Palettes & Aesthetics")
    cfgSec:AddLabel("Choose UI Accent Theme")
    cfgSec:AddButton({ Title = "Electric Indigo (Default)", Callback = function()
        self._library:SetAccent(Color3.fromRGB(99, 102, 241))
    end })
    cfgSec:AddButton({ Title = "Cyber Neon (Cyan)", Callback = function()
        self._library:SetAccent(Color3.fromRGB(6, 182, 212))
    end })
    cfgSec:AddButton({ Title = "Crimson Dark (Rose)", Callback = function()
        self._library:SetAccent(Color3.fromRGB(244, 63, 94))
    end })
    cfgSec:AddButton({ Title = "Emerald Green", Callback = function()
        self._library:SetAccent(Color3.fromRGB(16, 185, 129))
    end })
    cfgSec:AddButton({ Title = "Amber Gold", Callback = function()
        self._library:SetAccent(Color3.fromRGB(245, 158, 11))
    end })

    -- Credits Tab
    local creditsTab = self:_createTabElement("Credits", container, 2)
    self._creditsSection = creditsTab:AddSection("Support & Community")
    self._refreshCredits = function()
        for _, ch in ipairs(self._creditsSection._frame:GetChildren()) do
            if ch:IsA("Frame") and ch.Name:sub(1, 8) == "Contact_" then ch:Destroy() end
        end
        for _, contact in ipairs(self._library._contacts) do
            local frame = Create("Frame", {
                Name = "Contact_" .. contact.Platform, BackgroundColor3 = Theme.ComponentBg,
                Size = UDim2.new(1, -4, 0, 42), LayoutOrder = self._library:_getOrder(),
                Parent = self._creditsSection._frame
            })
            AddCorner(frame, Theme.CornerRadiusSmall); AddRimLight(frame, Theme.RimLight, 0.92, 1)
            Create("TextLabel", {
                BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
                TextSize = 14, Text = "  " .. contact.Platform, TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 8, 0, 0), Parent = frame
            })
            local copyBtn = Create("TextButton", {
                BackgroundColor3 = Theme.Accent, FontFace = Theme.ComponentFont,
                TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12, Text = "Copy Link",
                Size = UDim2.fromOffset(80, 28), Position = UDim2.new(1, -90, 0.5, -14),
                AutoButtonColor = false, Parent = frame
            })
            AddCorner(copyBtn, Theme.CornerRadiusSmall)
            -- Reactive: accent on copy buttons
            self._library:_onThemeChange(function()
                if copyBtn and copyBtn.Parent then copyBtn.BackgroundColor3 = Theme.Accent end
            end)
            copyBtn.MouseButton1Click:Connect(function()
                local setclip = setclipboard or toclipboard or function() end
                pcall(setclip, contact.Link)
                copyBtn.Text = "Copied!"; task.delay(1.5, function() if copyBtn and copyBtn.Parent then copyBtn.Text = "Copy Link" end end)
            end)
        end
    end
    self:_refreshCredits()
end

-- ============================================
-- TAB METHODS
-- ============================================
function Tab:_select()
    local win = self._window
    if win._selectedTab and win._selectedTab ~= self then
        local prev = win._selectedTab
        prev._tabPage.Visible = false
        Tween(prev._tabButton, { BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary }, 0.15)
        Tween(prev._indicator, { BackgroundTransparency = 1 }, 0.15)
    end
    win._selectedTab = self
    self._tabPage.Visible = true
    Tween(self._tabButton, { BackgroundTransparency = 0.3, BackgroundColor3 = Theme.ComponentBg, TextColor3 = Theme.TextPrimary }, 0.15)
    Tween(self._indicator, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Accent }, 0.15)
end
function Tab:Show() self._tabPage.Visible = true end
function Tab:Hide() self._tabPage.Visible = false end

-- ============================================
-- SECTION
-- ============================================
function Tab:AddSection(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    local title = opts.Title or ""
    local section = setmetatable({}, Section)
    section._tab = self; section._library = self._library; section._order = self._library:_getOrder()

    local sectionFrame = Create("Frame", {
        Name = "Section_" .. (title ~= "" and title or "Default"), BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = section._order, Parent = self._tabPage,
    })
    section._frame = sectionFrame

    if title ~= "" then
        local titleFrame = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 0, Parent = sectionFrame })
        Create("TextLabel", {
            BackgroundTransparency = 1, FontFace = Theme.TitleFont, TextColor3 = Theme.TextSecondary,
            TextSize = 13, Text = string.upper(title), TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 2, 0, 0), Parent = titleFrame,
        })
    end
    AddListLayout(sectionFrame, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
    table.insert(self._sections, section)
    return section
end

local function CreateCompFrame(parent, height, order)
    local frame = Create("Frame", {
        BackgroundColor3 = Theme.ComponentBg, Size = UDim2.new(1, -2, 0, height or 36),
        LayoutOrder = order or 0, Parent = parent,
    })
    AddCorner(frame, Theme.CornerRadiusSmall); AddRimLight(frame, Theme.RimLight, 0.93, 1)
    return frame
end

-- ============================================
-- COMPONENT: SEPARATOR
-- ============================================
function Section:AddSeparator()
    Create("Frame", {
        BackgroundColor3 = Theme.TextTertiary, BackgroundTransparency = 0.7,
        Size = UDim2.new(1, -20, 0, 1), LayoutOrder = self._library:_getOrder(), Parent = self._frame,
    })
end

-- ============================================
-- COMPONENT: LABEL
-- ============================================
function Section:AddLabel(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    local frame = CreateCompFrame(self._frame, 32, self._library:_getOrder())
    frame.BackgroundTransparency = 0.6
    local label = Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextSecondary,
        TextSize = 13, Text = opts.Title or "Label", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 10, 0, 0), Parent = frame
    })
    local comp = { _label = label, Value = opts.Title }
    function comp:SetText(t) self._label.Text = t; self.Value = t end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- COMPONENT: PARAGRAPH
-- ============================================
function Section:AddParagraph(opts)
    opts = opts or {}
    local frame = CreateCompFrame(self._frame, 0, self._library:_getOrder())
    frame.AutomaticSize = Enum.AutomaticSize.Y
    AddPadding(frame, 8, 10, 8, 10)
    AddListLayout(frame, 3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left)
    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
        TextSize = 15, Text = opts.Title or "Paragraph", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18), TextWrapped = true, LayoutOrder = 1, Parent = frame,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextTertiary,
        TextSize = 14, Text = opts.Content or "", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true, LayoutOrder = 2, Parent = frame,
    })
    return {}
end

-- ============================================
-- COMPONENT: BUTTON
-- ============================================
function Section:AddButton(opts)
    opts = opts or {}
    local height = opts.Description and 50 or 36
    local frame = CreateCompFrame(self._frame, height, self._library:_getOrder())
    local btn = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = frame })
    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
        TextSize = 14, Text = opts.Title or "Button", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -20, 0, opts.Description and 22 or 36), Position = UDim2.new(0, 12, 0, opts.Description and 4 or 0), Parent = frame
    })
    if opts.Description then
        Create("TextLabel", {
            BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextTertiary,
            TextSize = 12, Text = opts.Description, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 12, 0, 26), Parent = frame
        })
    end
    btn.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Hover }, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.ComponentBg }, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        Tween(frame, { BackgroundColor3 = Theme.Accent }, 0.08)
        task.delay(0.08, function() Tween(frame, { BackgroundColor3 = Theme.ComponentBg }, 0.15) end)
        pcall(opts.Callback or function() end)
    end)
    return { _frame = frame }
end

-- ============================================
-- COMPONENT: TOGGLE (iOS Capsule) - REACTIVE
-- ============================================
function Section:AddToggle(opts)
    opts = opts or {}
    local default = opts.Default or false
    local height = opts.Description and 50 or 36
    local frame = CreateCompFrame(self._frame, height, self._library:_getOrder())
    local btn = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = frame })
    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
        TextSize = 14, Text = opts.Title or "Toggle", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -66, 0, opts.Description and 22 or 36), Position = UDim2.new(0, 12, 0, opts.Description and 4 or 0), Parent = frame
    })
    if opts.Description then
        Create("TextLabel", {
            BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextTertiary,
            TextSize = 12, Text = opts.Description, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -66, 0, 16), Position = UDim2.new(0, 12, 0, 26), Parent = frame
        })
    end
    local toggleBg = Create("Frame", {
        BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff,
        Size = UDim2.fromOffset(40, 22), Position = UDim2.new(1, -52, 0.5, -11), Parent = frame,
    })
    AddCorner(toggleBg, Theme.CornerRadiusPill)
    local circle = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.fromOffset(16, 16),
        Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), Parent = toggleBg,
    })
    AddCorner(circle, Theme.CornerRadiusPill); AddSafeShadow(circle)

    local comp = { Value = default, _cbs = {} }
    function comp:SetValue(v)
        self.Value = v
        Tween(toggleBg, { BackgroundColor3 = v and Theme.ToggleOn or Theme.ToggleOff }, 0.18)
        Tween(circle, { Position = v and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.18)
        pcall(opts.Callback or function() end, v)
        for _, fn in ipairs(self._cbs) do pcall(fn, v) end
    end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end

    -- Reactive: update toggle ON color when theme changes
    Library:_onThemeChange(function()
        if comp.Value then
            toggleBg.BackgroundColor3 = Theme.ToggleOn
        end
    end)

    btn.MouseButton1Click:Connect(function() comp:SetValue(not comp.Value) end)
    btn.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Hover }, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.ComponentBg }, 0.15) end)
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- COMPONENT: SLIDER - REACTIVE
-- ============================================
function Section:AddSlider(opts)
    opts = opts or {}
    local min, max = opts.Min or 0, opts.Max or 100
    local default = math.clamp(opts.Default or min, min, max)
    local rounding = opts.Rounding or 0
    local height = opts.Description and 58 or 46
    local frame = CreateCompFrame(self._frame, height, self._library:_getOrder())

    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
        TextSize = 14, Text = opts.Title or "Slider", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -66, 0, 22), Position = UDim2.new(0, 12, 0, 4), Parent = frame
    })
    local valLabel = Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.Accent,
        TextSize = 13, Text = tostring(default), TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0, 50, 0, 22), Position = UDim2.new(1, -62, 0, 4), Parent = frame
    })
    local track = Create("Frame", { BackgroundColor3 = Theme.SliderBg, Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, opts.Description and 42 or 32), Parent = frame })
    AddCorner(track, Theme.CornerRadiusPill)
    local pct = (default - min) / math.max(max - min, 0.001)
    local fill = Create("Frame", { BackgroundColor3 = Theme.SliderFill, Size = UDim2.new(pct, 0, 1, 0), Parent = track })
    AddCorner(fill, Theme.CornerRadiusPill)
    local knob = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.fromOffset(14, 14), Position = UDim2.new(pct, -7, 0.5, -7), ZIndex = 2, Parent = track })
    AddCorner(knob, Theme.CornerRadiusPill); AddSafeShadow(knob)
    local inputArea = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 10, 0, 24), Position = UDim2.new(0, -5, 0, -9), Text = "", Parent = track })

    -- Reactive: update slider fill and value label color
    Library:_onThemeChange(function()
        fill.BackgroundColor3 = Theme.SliderFill
        valLabel.TextColor3 = Theme.Accent
    end)

    local comp = { Value = default, _cbs = {} }
    local function round(v) if rounding == 0 then return math.floor(v + 0.5) end; local m = 10 ^ rounding; return math.floor(v * m + 0.5) / m end
    local function update(p)
        p = math.clamp(p, 0, 1)
        local val = round(min + (max - min) * p); comp.Value = val; valLabel.Text = tostring(val)
        Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.05); Tween(knob, { Position = UDim2.new(p, -7, 0.5, -7) }, 0.05)
        pcall(opts.Callback or function() end, val); for _, fn in ipairs(comp._cbs) do pcall(fn, val) end
    end
    function comp:SetValue(v) update((math.clamp(v, min, max) - min) / math.max(max - min, 0.001)) end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end

    local sliding = false
    inputArea.MouseButton1Down:Connect(function() sliding = true end)
    Library:_addConnection(UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end))
    Library:_addConnection(UserInputService.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then update((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X) end
    end))
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- COMPONENT: DROPDOWN (Auto-Update + SetValues + ValuesFunction)
-- ============================================
function Section:AddDropdown(opts)
    opts = opts or {}
    local values = opts.Values or {}
    local multi = opts.Multi or false
    local valuesFunction = opts.ValuesFunction -- Optional: function that returns fresh values list
    local frame = CreateCompFrame(self._frame, opts.Description and 50 or 36, self._library:_getOrder())
    frame.ClipsDescendants = false; frame.ZIndex = 5
    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
        TextSize = 14, Text = opts.Title or "Dropdown", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.5, -12, 0, opts.Description and 22 or 36), Position = UDim2.new(0, 12, 0, opts.Description and 4 or 0), ZIndex = 5, Parent = frame
    })
    local dropBtn = Create("TextButton", {
        BackgroundColor3 = Theme.InputBg, Size = UDim2.new(0.45, 0, 0, 26), Position = UDim2.new(0.53, 0, 0, opts.Description and 4 or 5),
        FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextSecondary, TextSize = 13, Text = "  Select...",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false, ZIndex = 6, Parent = frame
    })
    AddCorner(dropBtn, Theme.CornerRadiusSmall); AddRimLight(dropBtn, Theme.RimLight, 0.90, 1)

    local dropList = Create("Frame", {
        BackgroundColor3 = Theme.DropdownBg, Size = UDim2.new(0.45, 0, 0, 0), Position = UDim2.new(0.53, 0, 0, (opts.Description and 4 or 5) + 30),
        ClipsDescendants = true, Visible = false, ZIndex = 20, Parent = frame
    })
    AddCorner(dropList, Theme.CornerRadiusSmall); AddRimLight(dropList, Theme.RimLight, 0.88, 1); AddSafeShadow(dropList)

    local scroll = Create("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 1, -6), Position = UDim2.new(0, 3, 0, 3), ScrollBarThickness = 2, ZIndex = 21, Parent = dropList })
    local layout = AddListLayout(scroll, 3); layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4) end)

    local isOpen, selVal, selMulti = false, nil, {}
    local comp = { Value = nil, _cbs = {} }

    local function getDisp()
        if multi then
            local t = {}; for k, v in pairs(selMulti) do if v then table.insert(t, tostring(k)) end end
            return #t == 0 and "  None" or "  " .. table.concat(t, ", ")
        else
            return selVal and "  " .. tostring(selVal) or "  Select..."
        end
    end
    local function fire()
        comp.Value = multi and selMulti or selVal; dropBtn.Text = getDisp()
        pcall(opts.Callback or function() end, comp.Value)
        for _, fn in ipairs(comp._cbs) do pcall(fn, comp.Value) end
    end

    local function buildItems()
        -- Clear all existing items
        for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end

        for i, val in ipairs(values) do
            local isSelected = multi and selMulti[val] or (selVal == val)
            local item = Create("TextButton", {
                BackgroundColor3 = Theme.DropdownItem, BackgroundTransparency = 0.5, Size = UDim2.new(1, 0, 0, 24),
                FontFace = Theme.ComponentFontRegular, TextColor3 = isSelected and Theme.TextPrimary or Theme.TextSecondary,
                TextSize = 13, Text = "  " .. tostring(val), TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i, ZIndex = 22, Parent = scroll
            })
            AddCorner(item, Theme.CornerRadiusSmall)
            item.MouseButton1Click:Connect(function()
                if multi then
                    selMulti[val] = not selMulti[val]
                    item.TextColor3 = selMulti[val] and Theme.TextPrimary or Theme.TextSecondary
                else
                    selVal = val
                    isOpen = false; dropList.Visible = false
                    Tween(dropList, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.15)
                end
                fire()
            end)
            item.MouseEnter:Connect(function() Tween(item, { BackgroundTransparency = 0.1, TextColor3 = Theme.TextPrimary }, 0.15) end)
            item.MouseLeave:Connect(function()
                local c = (multi and selMulti[val]) and Theme.TextPrimary or (selVal == val and Theme.TextPrimary or Theme.TextSecondary)
                Tween(item, { BackgroundTransparency = 0.5, TextColor3 = c }, 0.15)
            end)
        end
    end
    buildItems()

    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            -- Auto-update: if ValuesFunction is provided, refresh values before opening
            if valuesFunction then
                local s, newVals = pcall(valuesFunction)
                if s and type(newVals) == "table" then
                    values = newVals
                    buildItems()
                end
            end
            dropList.Visible = true
            Tween(dropList, { Size = UDim2.new(0.45, 0, 0, math.min(#values, 5) * 27 + 8) }, 0.2)
        else
            Tween(dropList, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.2)
            task.delay(0.2, function() if not isOpen then dropList.Visible = false end end)
        end
    end)

    function comp:SetValue(v) if multi and type(v) == "table" then selMulti = v else selVal = v end; fire() end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end
    -- Public method to swap values at runtime (auto-update for devs)
    function comp:SetValues(newVals)
        values = newVals or {}
        buildItems()
        dropBtn.Text = getDisp()
    end
    -- Public method to refresh from ValuesFunction
    function comp:Refresh()
        if valuesFunction then
            local s, newVals = pcall(valuesFunction)
            if s and type(newVals) == "table" then values = newVals; buildItems() end
        end
    end

    if opts.Default then comp:SetValue(opts.Default) end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- COMPONENT: TEXTBOX
-- ============================================
function Section:AddTextbox(opts)
    opts = opts or {}
    local frame = CreateCompFrame(self._frame, 36, self._library:_getOrder())
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary, TextSize = 14, Text = opts.Title or "Input", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.5, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), Parent = frame })
    local tb = Create("TextBox", { BackgroundColor3 = Theme.InputBg, Size = UDim2.new(0.45, 0, 0, 26), Position = UDim2.new(0.53, 0, 0.5, -13), FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextPrimary, PlaceholderColor3 = Theme.TextTertiary, TextSize = 13, Text = opts.Default or "", PlaceholderText = opts.Placeholder or "Type...", ClearTextOnFocus = false, Parent = frame })
    AddCorner(tb, Theme.CornerRadiusSmall); AddRimLight(tb, Theme.RimLight, 0.90, 1)
    local comp = { Value = opts.Default or "", _cbs = {} }
    tb.FocusLost:Connect(function() comp.Value = tb.Text; pcall(opts.Callback or function() end, comp.Value); for _, fn in ipairs(comp._cbs) do pcall(fn, comp.Value) end end)
    function comp:SetValue(v) tb.Text = tostring(v); comp.Value = tostring(v) end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- COMPONENT: KEYBIND
-- ============================================
function Section:AddKeybind(opts)
    opts = opts or {}
    local frame = CreateCompFrame(self._frame, 36, self._library:_getOrder())
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary, TextSize = 14, Text = opts.Title or "Keybind", TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.6, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), Parent = frame })
    local defaultKey = opts.Default or Enum.KeyCode.RightShift
    local keyBtn = Create("TextButton", { BackgroundColor3 = Theme.InputBg, Size = UDim2.new(0.35, 0, 0, 26), Position = UDim2.new(0.63, 0, 0.5, -13), FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextSecondary, TextSize = 12, Text = tostring(defaultKey):gsub("Enum.KeyCode.", ""), Parent = frame })
    AddCorner(keyBtn, Theme.CornerRadiusSmall); AddRimLight(keyBtn, Theme.RimLight, 0.90, 1)
    local comp = { Value = defaultKey, _binding = false, _cbs = {} }
    keyBtn.MouseButton1Click:Connect(function() comp._binding = true; keyBtn.Text = "..." end)
    Library:_addConnection(UserInputService.InputBegan:Connect(function(inp)
        if comp._binding and inp.UserInputType == Enum.UserInputType.Keyboard then
            comp.Value = inp.KeyCode; keyBtn.Text = tostring(inp.KeyCode):gsub("Enum.KeyCode.", ""); comp._binding = false
            pcall(opts.Callback or function() end, inp.KeyCode); for _, fn in ipairs(comp._cbs) do pcall(fn, inp.KeyCode) end
        end
    end))
    function comp:SetValue(k) self.Value = k; keyBtn.Text = tostring(k):gsub("Enum.KeyCode.", "") end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- COMPONENT: COLOR PICKER (HSV Sliders)
-- ============================================
function Section:AddColorPicker(opts)
    opts = opts or {}
    local default = opts.Default or Color3.fromRGB(99, 102, 241)
    local frame = CreateCompFrame(self._frame, 36, self._library:_getOrder())
    frame.ClipsDescendants = false

    Create("TextLabel", {
        BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
        TextSize = 14, Text = opts.Title or "Color Picker", TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 12, 0, 0), Parent = frame
    })
    local swatch = Create("TextButton", {
        BackgroundColor3 = default, Size = UDim2.fromOffset(28, 22),
        Position = UDim2.new(1, -40, 0.5, -11), AutoButtonColor = false, Text = "", Parent = frame,
    })
    AddCorner(swatch, Theme.CornerRadiusSmall); AddRimLight(swatch, Theme.RimLight, 0.8, 1)

    local pickerFrame = Create("Frame", {
        BackgroundColor3 = Theme.DropdownBg, Size = UDim2.fromOffset(200, 170),
        Position = UDim2.new(1, -200, 0, 40), Visible = false, ZIndex = 30, Parent = frame,
    })
    AddCorner(pickerFrame, Theme.CornerRadiusSmall); AddRimLight(pickerFrame, Theme.RimLight, 0.85, 1); AddSafeShadow(pickerFrame)

    -- Hue
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextSecondary, TextSize = 11, Text = "HUE", Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(0, 8, 0, 8), ZIndex = 31, Parent = pickerFrame })
    local hueTrack = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255,0,0), Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 10, 0, 26), ZIndex = 31, Parent = pickerFrame })
    AddCorner(hueTrack, Theme.CornerRadiusPill)
    Create("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)) }), Parent = hueTrack })
    local hueKnob = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.fromOffset(6, 18), Position = UDim2.new(0, -3, 0.5, -9), ZIndex = 32, Parent = hueTrack })
    AddCorner(hueKnob, Theme.CornerRadiusPill)
    local hueInput = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 10, 0, 24), Position = UDim2.new(0, -5, 0, -5), Text = "", ZIndex = 33, Parent = hueTrack })

    -- Saturation
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextSecondary, TextSize = 11, Text = "SAT", Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(0, 8, 0, 48), ZIndex = 31, Parent = pickerFrame })
    local satTrack = Create("Frame", { BackgroundColor3 = Color3.fromRGB(60,60,60), Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 10, 0, 66), ZIndex = 31, Parent = pickerFrame })
    AddCorner(satTrack, Theme.CornerRadiusPill)
    local satKnob = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.fromOffset(6, 18), Position = UDim2.new(1, -3, 0.5, -9), ZIndex = 32, Parent = satTrack })
    AddCorner(satKnob, Theme.CornerRadiusPill)
    local satInput = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 10, 0, 24), Position = UDim2.new(0, -5, 0, -5), Text = "", ZIndex = 33, Parent = satTrack })

    -- Value (Brightness)
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextSecondary, TextSize = 11, Text = "VAL", Size = UDim2.new(0, 40, 0, 16), Position = UDim2.new(0, 8, 0, 88), ZIndex = 31, Parent = pickerFrame })
    local valTrack = Create("Frame", { BackgroundColor3 = Color3.fromRGB(60,60,60), Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 10, 0, 106), ZIndex = 31, Parent = pickerFrame })
    AddCorner(valTrack, Theme.CornerRadiusPill)
    local valKnob = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.fromOffset(6, 18), Position = UDim2.new(1, -3, 0.5, -9), ZIndex = 32, Parent = valTrack })
    AddCorner(valKnob, Theme.CornerRadiusPill)
    local valInput = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 10, 0, 24), Position = UDim2.new(0, -5, 0, -5), Text = "", ZIndex = 33, Parent = valTrack })

    local hexLabel = Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextSecondary, TextSize = 12, Text = "#FFFFFF", Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 128), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = pickerFrame })
    local previewBox = Create("Frame", { BackgroundColor3 = default, Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -50, 0, 130), ZIndex = 31, Parent = pickerFrame })
    AddCorner(previewBox, Theme.CornerRadiusSmall)

    local h, s, v = Color3.toHSV(default)
    local pickerOpen = false
    local comp = { Value = default, _cbs = {} }

    local function refreshColor()
        local c = Color3.fromHSV(h, s, v); comp.Value = c
        swatch.BackgroundColor3 = c; previewBox.BackgroundColor3 = c
        hexLabel.Text = string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
        local satGrad = satTrack:FindFirstChildOfClass("UIGradient")
        if not satGrad then satGrad = Create("UIGradient", { Parent = satTrack }) end
        satGrad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
        local valGrad = valTrack:FindFirstChildOfClass("UIGradient")
        if not valGrad then valGrad = Create("UIGradient", { Parent = valTrack }) end
        valGrad.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromHSV(h, s, 1))
        pcall(opts.Callback or function() end, c)
        for _, fn in ipairs(comp._cbs) do pcall(fn, c) end
    end

    hueKnob.Position = UDim2.new(h, -3, 0.5, -9)
    satKnob.Position = UDim2.new(s, -3, 0.5, -9)
    valKnob.Position = UDim2.new(v, -3, 0.5, -9)
    refreshColor()

    swatch.MouseButton1Click:Connect(function() pickerOpen = not pickerOpen; pickerFrame.Visible = pickerOpen end)

    local draggingH, draggingS, draggingV = false, false, false
    hueInput.MouseButton1Down:Connect(function() draggingH = true end)
    satInput.MouseButton1Down:Connect(function() draggingS = true end)
    valInput.MouseButton1Down:Connect(function() draggingV = true end)
    Library:_addConnection(UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingH = false; draggingS = false; draggingV = false end end))
    Library:_addConnection(UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if draggingH then h = math.clamp((inp.Position.X - hueTrack.AbsolutePosition.X) / hueTrack.AbsoluteSize.X, 0, 1); hueKnob.Position = UDim2.new(h, -3, 0.5, -9); refreshColor()
        elseif draggingS then s = math.clamp((inp.Position.X - satTrack.AbsolutePosition.X) / satTrack.AbsoluteSize.X, 0, 1); satKnob.Position = UDim2.new(s, -3, 0.5, -9); refreshColor()
        elseif draggingV then v = math.clamp((inp.Position.X - valTrack.AbsolutePosition.X) / valTrack.AbsoluteSize.X, 0, 1); valKnob.Position = UDim2.new(v, -3, 0.5, -9); refreshColor() end
    end))

    function comp:SetValue(color) h, s, v = Color3.toHSV(color); hueKnob.Position = UDim2.new(h, -3, 0.5, -9); satKnob.Position = UDim2.new(s, -3, 0.5, -9); valKnob.Position = UDim2.new(v, -3, 0.5, -9); refreshColor() end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- COMPONENT: PLAYER LIST (Auto-Update with Avatars)
-- ============================================
function Section:AddPlayerList(opts)
    opts = opts or {}
    local frame = CreateCompFrame(self._frame, 0, self._library:_getOrder())
    frame.AutomaticSize = Enum.AutomaticSize.Y; frame.ClipsDescendants = true
    AddPadding(frame, 6, 6, 6, 6)

    if opts.Title then
        Create("TextLabel", {
            BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary,
            TextSize = 14, Text = opts.Title, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = frame,
        })
    end

    local listScroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, math.min((opts.MaxVisible or 5) * 36, 180)),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TextTertiary, CanvasSize = UDim2.new(0, 0, 0, 0),
        LayoutOrder = 1, Parent = frame,
    })
    local listLayout = AddListLayout(listScroll, 3)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
    end)

    local comp = { Value = {}, _cbs = {}, _items = {} }

    local function renderPlayer(player, order)
        local item = Create("TextButton", {
            Name = "Player_" .. player.Name, BackgroundColor3 = Theme.PlayerListBg,
            BackgroundTransparency = 0.3, Size = UDim2.new(1, -4, 0, 32), LayoutOrder = order,
            Text = "", AutoButtonColor = false, Parent = listScroll,
        })
        AddCorner(item, Theme.CornerRadiusSmall)
        local avatarFrame = Create("ImageLabel", {
            BackgroundColor3 = Theme.ComponentBg, Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(0, 6, 0.5, -12), Image = "", Parent = item,
        })
        AddCorner(avatarFrame, Theme.CornerRadiusPill)
        avatarFrame.ClipsDescendants = true
        task.spawn(function()
            local s, thumb = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
            if s and thumb then avatarFrame.Image = thumb end
        end)
        Create("TextLabel", {
            BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextPrimary,
            TextSize = 13, Text = player.DisplayName .. " (@" .. player.Name .. ")",
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 36, 0, 0), Parent = item,
        })
        item.MouseButton1Click:Connect(function()
            pcall(opts.Callback or function() end, player)
            for _, fn in ipairs(comp._cbs) do pcall(fn, player) end
        end)
        item.MouseEnter:Connect(function() Tween(item, { BackgroundTransparency = 0 }, 0.15) end)
        item.MouseLeave:Connect(function() Tween(item, { BackgroundTransparency = 0.3 }, 0.15) end)
        comp._items[player.UserId] = item
    end

    local function refresh()
        for _, item in pairs(comp._items) do pcall(function() item:Destroy() end) end
        comp._items = {}; comp.Value = {}
        for i, player in ipairs(Players:GetPlayers()) do
            table.insert(comp.Value, player); renderPlayer(player, i)
        end
    end
    refresh()

    Library:_addConnection(Players.PlayerAdded:Connect(function() task.wait(0.5); refresh() end))
    Library:_addConnection(Players.PlayerRemoving:Connect(function() task.wait(0.5); refresh() end))

    function comp:Refresh() refresh() end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- NOTIFICATION SYSTEM (with types: success, error, warning)
-- ============================================
function Library:Notify(opts)
    opts = opts or {}
    if not self._notifyHolder then return end
    local notify = Create("Frame", { BackgroundColor3 = Theme.NotifyBg, Size = UDim2.fromOffset(290, 68), BackgroundTransparency = 1, Parent = self._notifyHolder })
    AddCorner(notify, Theme.CornerRadiusSmall); AddRimLight(notify, Theme.Accent, 0.5, 1); AddSafeShadow(notify)
    local barColor = Theme.Accent
    if opts.Type == "success" then barColor = Color3.fromRGB(34, 197, 94)
    elseif opts.Type == "error" then barColor = Color3.fromRGB(239, 68, 68)
    elseif opts.Type == "warning" then barColor = Color3.fromRGB(234, 179, 8) end
    Create("Frame", { BackgroundColor3 = barColor, Size = UDim2.new(0, 3, 0.7, 0), Position = UDim2.new(0, 8, 0.15, 0), Parent = notify })
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.TitleFont, TextColor3 = Theme.TextPrimary, TextSize = 14, Text = opts.Title or "Notice", Size = UDim2.new(1, -28, 0, 20), Position = UDim2.new(0, 18, 0, 8), TextXAlignment = Enum.TextXAlignment.Left, Parent = notify })
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextSecondary, TextSize = 12, Text = opts.Content or "", Size = UDim2.new(1, -28, 0, 32), Position = UDim2.new(0, 18, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = notify })
    Tween(notify, { BackgroundTransparency = 0 }, 0.22)
    task.delay(opts.Duration or 4, function()
        Tween(notify, { BackgroundTransparency = 1 }, 0.25); task.delay(0.3, function() pcall(function() notify:Destroy() end) end)
    end)
end

-- ============================================
-- DESTROY
-- ============================================
function Library:Destroy()
    self.Unloaded = true
    for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    self._connections = {}; self._themeCallbacks = {}
    if self._screenGui then pcall(function() self._screenGui:Destroy() end) end
end

-- ============================================
-- TAB SHORTCUT METHODS
-- ============================================
function Tab:_defSec() if not self._defaultSec then self._defaultSec = self:AddSection("") end; return self._defaultSec end
function Tab:AddLabel(o) return self:_defSec():AddLabel(o) end
function Tab:AddParagraph(o) return self:_defSec():AddParagraph(o) end
function Tab:AddButton(o) return self:_defSec():AddButton(o) end
function Tab:AddSeparator() return self:_defSec():AddSeparator() end
function Tab:AddColorPicker(o) return self:_defSec():AddColorPicker(o) end
function Tab:AddPlayerList(o) return self:_defSec():AddPlayerList(o) end
function Tab:AddToggle(f, o) local s = self:_defSec(); if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddToggle(o) end; return s:AddToggle(f) end
function Tab:AddSlider(f, o) local s = self:_defSec(); if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddSlider(o) end; return s:AddSlider(f) end
function Tab:AddDropdown(f, o) local s = self:_defSec(); if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddDropdown(o) end; return s:AddDropdown(f) end
function Tab:AddTextbox(f, o) local s = self:_defSec(); if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddTextbox(o) end; return s:AddTextbox(f) end
function Tab:AddKeybind(f, o) local s = self:_defSec(); if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddKeybind(o) end; return s:AddKeybind(f) end

return Library
