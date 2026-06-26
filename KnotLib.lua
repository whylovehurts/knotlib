--[[
    KnotLib v2.0.0 - Dark Red Theme & QOL Edition
    UI Library for Roblox (LuaU)
    
    Features:
      - Dark Red Aesthetic with Gradients & Shadows
      - Automatic Game Name Detection via MarketplaceService
      - Draggable Floating Toggle Button
      - Built-in Config (Theme Customizer) & Credits (Contact API) Tabs
      - Sidebar Tab Separation (Scrollable User Tabs vs Fixed System Tabs)
      - Close / Destroy Confirmation Modal
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
-- THEME & PALETTES
-- ============================================
local Theme = {
    Background       = Color3.fromRGB(63, 0, 0),
    ToggleBarBg      = Color3.fromRGB(63, 0, 0),
    MainFrameBg      = Color3.fromRGB(50, 0, 0),
    TabsBg           = Color3.fromRGB(62, 0, 0),
    CurrentTabBg     = Color3.fromRGB(62, 0, 0),
    ComponentBg      = Color3.fromRGB(46, 0, 0),
    
    TextPrimary      = Color3.fromRGB(222, 222, 222),
    TextSecondary    = Color3.fromRGB(187, 187, 187),
    TextTertiary     = Color3.fromRGB(150, 150, 150),
    Accent           = Color3.fromRGB(255, 80, 80),
    
    ToggleOn         = Color3.fromRGB(120, 220, 120),
    ToggleOff        = Color3.fromRGB(80, 20, 20),
    SliderFill       = Color3.fromRGB(200, 50, 50),
    SliderBg         = Color3.fromRGB(35, 0, 0),
    Hover            = Color3.fromRGB(80, 10, 10),
    DropdownBg       = Color3.fromRGB(40, 0, 0),
    DropdownItem     = Color3.fromRGB(55, 0, 0),
    NotifyBg         = Color3.fromRGB(50, 0, 0),
    NotifyBorder     = Color3.fromRGB(100, 20, 20),
    TabSelected      = Color3.fromRGB(90, 10, 10),
    TabUnselected    = Color3.fromRGB(46, 0, 0),
    InputBg          = Color3.fromRGB(30, 0, 0),
    SectionLine      = Color3.fromRGB(100, 20, 20),

    TitleFont            = Font.new("rbxasset://fonts/families/Guru.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    ModalFont            = Font.new("rbxasset://fonts/families/Guru.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    ComponentFont        = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    ComponentFontRegular = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),

    CornerRadius      = UDim.new(0, 7),
    CornerRadiusModal = UDim.new(0, 15),
    CornerRadiusSmall = UDim.new(0, 5),
    CornerRadiusTiny  = UDim.new(0, 4),
    TweenSpeed        = 0.22,
    TweenEasing       = Enum.EasingStyle.Quad,
}

-- ============================================
-- UTILITIES
-- ============================================
local function Tween(instance, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or Theme.TweenSpeed,
        style or Theme.TweenEasing,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

local function Create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = radius or Theme.CornerRadius, Parent = parent })
end

local function AddPadding(parent, top, right, bottom, left)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        Parent = parent,
    })
end

local function AddListLayout(parent, padding, direction, hAlign, vAlign)
    return Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        Parent = parent,
    })
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(0, 0, 0),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = parent,
    })
end

-- Safe shadow implementation (falls back to UIStroke if UIShadow is not available in standard client)
local function AddSafeShadow(parent)
    local ok, shadow = pcall(function()
        return Instance.new("UIShadow")
    end)
    if ok and shadow then
        shadow.Parent = parent
        return shadow
    else
        return AddStroke(parent, Color3.fromRGB(15, 0, 0), 2, 0.4)
    end
end

local function AddGradient(parent, c1, c2, rot)
    return Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2)
        }),
        Rotation = rot or 0,
        Parent = parent
    })
end

local function GetParentGui()
    local success, result = pcall(function()
        if typeof(gethui) == "function" then return gethui() end
    end)
    if success and result then return result end

    local success2, result2 = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success2 and result2 then return result2 end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function AutoDetectGameName()
    local s, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if s and info and info.Name and info.Name ~= "" then
        return info.Name
    end
    return game.Name or "KnotHub"
end

local function MakeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(targetFrame, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            }, 0.06)
        end
    end)
end

-- ============================================
-- LIBRARY (Singleton)
-- ============================================
local Library = {}
Library.__index = Library
Library.Version = "2.0.0"
Library.Options = {}
Library.Flags = Library.Options
Library.Unloaded = false
Library._windows = {}
Library._connections = {}
Library._contacts = {}
Library._screenGui = nil
Library._notifyHolder = nil
Library._orderCounter = 0

function Library:_getOrder()
    self._orderCounter = self._orderCounter + 1
    return self._orderCounter
end

function Library:_registerOption(flag, component)
    if flag and flag ~= "" then
        self.Options[flag] = component
    end
end

function Library:_addConnection(conn)
    table.insert(self._connections, conn)
    return conn
end

function Library:AddContact(platform, link)
    table.insert(self._contacts, { Platform = platform or "Contact", Link = link or "" })
    for _, win in ipairs(self._windows) do
        if win._refreshCredits then
            win:_refreshCredits()
        end
    end
end

-- ============================================
-- FORWARD DECLARATIONS
-- ============================================
local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

-- ============================================
-- WINDOW
-- ============================================
function Library:CreateWindow(opts)
    opts = opts or {}
    local size = opts.Size or UDim2.fromOffset(743, 384)
    local minimizeKey = opts.MinimizeKey or Enum.KeyCode.RightShift

    local win = setmetatable({}, Window)
    win._library = self
    win._tabs = {}
    win._selectedTab = nil
    win._visible = true
    win._minimizeKey = minimizeKey
    win._userTabsCount = 0

    -- ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "KnotLib_DarkRed",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = GetParentGui(),
    })
    self._screenGui = screenGui
    win._screenGui = screenGui

    -- Main Container
    local main = Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = size,
        Position = UDim2.new(0.5, -(size.X.Offset / 2), 0.5, -(size.Y.Offset / 2)),
        Parent = screenGui,
    })
    AddCorner(main, Theme.CornerRadius)
    AddStroke(main, Color3.fromRGB(0, 0, 0), 1)
    AddSafeShadow(main)
    AddGradient(main, Color3.fromRGB(103, 0, 0), Color3.fromRGB(213, 213, 213), 90)
    win._main = main

    -- ToggleBar (Top Bar)
    local toggleBar = Create("Frame", {
        Name = "ToggleBar",
        BackgroundColor3 = Theme.ToggleBarBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 56),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = main,
    })
    AddCorner(toggleBar, Theme.CornerRadius)
    AddStroke(toggleBar, Color3.fromRGB(0, 0, 0), 1)
    AddSafeShadow(toggleBar)
    AddGradient(toggleBar, Color3.fromRGB(27, 0, 0), Color3.fromRGB(255, 255, 255), 90)
    win._toggleBar = toggleBar

    -- Cover bottom corners of ToggleBar
    Create("Frame", {
        Name = "ToggleBarCover",
        BackgroundColor3 = Theme.ToggleBarBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        Parent = toggleBar,
    })

    -- Auto Detect Game Name Label
    local gameNameLabel = Create("TextLabel", {
        Name = "Game Name",
        BackgroundTransparency = 1,
        FontFace = Theme.TitleFont,
        TextColor3 = Theme.TextPrimary,
        TextScaled = true,
        Text = "Auto Detecting Game...",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 526, 0, 42),
        Position = UDim2.new(0, 18, 0, 7),
        Parent = toggleBar,
    })
    Create("UITextSizeConstraint", { MaxTextSize = 38, MinTextSize = 16, Parent = gameNameLabel })
    
    local titleGrad = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.468, Color3.fromRGB(162, 162, 162)),
            ColorSequenceKeypoint.new(0.996, Color3.fromRGB(185, 185, 185)),
            ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))
        }),
        Parent = gameNameLabel
    })
    win._gameNameLabel = gameNameLabel

    task.spawn(function()
        local detected = AutoDetectGameName()
        gameNameLabel.Text = detected
    end)

    -- Make window draggable via ToggleBar
    MakeDraggable(toggleBar, main)

    -- MainFrame (Content Area below ToggleBar)
    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = Theme.MainFrameBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -32, 1, -86),
        Position = UDim2.new(0, 16, 0, 70),
        Parent = main,
    })
    AddCorner(mainFrame, Theme.CornerRadius)
    AddStroke(mainFrame, Color3.fromRGB(0, 0, 0), 1)
    AddSafeShadow(mainFrame)
    win._mainFrame = mainFrame

    -- Tabs Sidebar
    local tabsSidebar = Create("Frame", {
        Name = "Tabs",
        BackgroundColor3 = Theme.TabsBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 110, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        Parent = mainFrame,
    })
    AddCorner(tabsSidebar, Theme.CornerRadius)
    AddStroke(tabsSidebar, Color3.fromRGB(0, 0, 0), 1)
    AddSafeShadow(tabsSidebar)
    win._tabsSidebar = tabsSidebar

    -- User Tabs Container (Scrollable)
    local userTabsScroll = Create("ScrollingFrame", {
        Name = "UserTabsList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 1, -72),
        Position = UDim2.new(0, 4, 0, 6),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.TextSecondary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = tabsSidebar,
    })
    local userTabsLayout = AddListLayout(userTabsScroll, 5)
    userTabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        userTabsScroll.CanvasSize = UDim2.new(0, 0, 0, userTabsLayout.AbsoluteContentSize.Y + 8)
    end)
    win._userTabsScroll = userTabsScroll

    -- Limite Separator
    local limiteSeparator = Create("Frame", {
        Name = "Limite",
        BackgroundColor3 = Color3.fromRGB(63, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 70, 0, 3),
        Position = UDim2.new(0.5, -35, 1, -62),
        Parent = tabsSidebar,
    })
    AddCorner(limiteSeparator, UDim.new(0, 2))
    AddGradient(limiteSeparator, Color3.fromRGB(63, 0, 0), Color3.fromRGB(255, 255, 255), 0)
    AddSafeShadow(limiteSeparator)

    -- Fixed System Tabs (Config & Credits)
    local fixedTabsContainer = Create("Frame", {
        Name = "FixedTabs",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 54),
        Position = UDim2.new(0, 4, 1, -56),
        Parent = tabsSidebar,
    })
    AddListLayout(fixedTabsContainer, 4)

    -- CurrentTab Content Holder
    local currentTabFrame = Create("Frame", {
        Name = "CurrentTab",
        BackgroundColor3 = Theme.CurrentTabBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -130, 1, -16),
        Position = UDim2.new(0, 122, 0, 8),
        ClipsDescendants = true,
        Parent = mainFrame,
    })
    AddCorner(currentTabFrame, Theme.CornerRadius)
    AddStroke(currentTabFrame, Color3.fromRGB(0, 0, 0), 1)
    AddSafeShadow(currentTabFrame)
    win._currentTabFrame = currentTabFrame

    -- ===== FLOATING TOGGLE BUTTON =====
    local toggleButton = Create("ImageButton", {
        Name = "Toggle Button",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Image = "rbxassetid://15405680763",
        Size = UDim2.fromOffset(56, 50),
        Position = UDim2.new(0, 20, 0.5, -25),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        AutoButtonColor = false,
        ZIndex = 100,
        Parent = screenGui,
    })
    AddCorner(toggleButton, UDim.new(0, 60))
    AddStroke(toggleButton, Color3.fromRGB(0, 0, 0), 2)
    AddSafeShadow(toggleButton)
    MakeDraggable(toggleButton, toggleButton)

    toggleButton.MouseButton1Click:Connect(function()
        win:ToggleVisibility()
    end)
    toggleButton.MouseEnter:Connect(function()
        Tween(toggleButton, { Size = UDim2.fromOffset(60, 54) }, 0.15)
    end)
    toggleButton.MouseLeave:Connect(function()
        Tween(toggleButton, { Size = UDim2.fromOffset(56, 50) }, 0.15)
    end)
    win._toggleButton = toggleButton

    -- ===== CLOSE BUTTON & DESTROY MODAL =====
    local closeBtn = Create("ImageButton", {
        Name = "Close (Destroy UI & Toggle)",
        BackgroundTransparency = 1,
        Image = "rbxassetid://10747384394", -- clean close X icon
        ImageColor3 = Color3.fromRGB(200, 200, 200),
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.new(1, -46, 0.5, -18),
        Parent = toggleBar,
    })
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { ImageColor3 = Color3.fromRGB(255, 80, 80) }, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { ImageColor3 = Color3.fromRGB(200, 200, 200) }, 0.15)
    end)

    -- Destroy Modal
    local destroyModal = Create("Frame", {
        Name = "Destroy Modal",
        BackgroundColor3 = Color3.fromRGB(55, 0, 0),
        Size = UDim2.fromOffset(280, 180),
        Position = UDim2.new(0.5, -140, 0.5, -90),
        Visible = false,
        ZIndex = 50,
        Parent = main,
    })
    AddCorner(destroyModal, Theme.CornerRadiusModal)
    AddStroke(destroyModal, Color3.fromRGB(150, 20, 20), 2)
    AddSafeShadow(destroyModal)

    Create("TextLabel", {
        Name = "Question",
        BackgroundTransparency = 1,
        FontFace = Theme.ModalFont,
        TextColor3 = Color3.fromRGB(230, 230, 230),
        TextSize = 28,
        Text = "Are you sure?",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, 15),
        ZIndex = 51,
        Parent = destroyModal,
    })

    local yesBtn = Create("TextButton", {
        Name = "Yes (Destroy)",
        BackgroundColor3 = Color3.fromRGB(180, 40, 40),
        FontFace = Theme.ComponentFont,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        Text = "YES (Destroy)",
        Size = UDim2.new(0, 110, 0, 45),
        Position = UDim2.new(0, 20, 1, -65),
        AutoButtonColor = false,
        ZIndex = 51,
        Parent = destroyModal,
    })
    AddCorner(yesBtn, Theme.CornerRadiusSmall)

    local noBtn = Create("TextButton", {
        Name = "No (Close Modal)",
        BackgroundColor3 = Color3.fromRGB(80, 30, 30),
        FontFace = Theme.ComponentFont,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 18,
        Text = "NO (Cancel)",
        Size = UDim2.new(0, 110, 0, 45),
        Position = UDim2.new(1, -130, 1, -65),
        AutoButtonColor = false,
        ZIndex = 51,
        Parent = destroyModal,
    })
    AddCorner(noBtn, Theme.CornerRadiusSmall)

    closeBtn.MouseButton1Click:Connect(function()
        destroyModal.Visible = not destroyModal.Visible
    end)

    yesBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    noBtn.MouseButton1Click:Connect(function()
        destroyModal.Visible = false
    end)

    -- Keybind Toggle
    self:_addConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == minimizeKey then
            win:ToggleVisibility()
        end
    end))

    -- Notification Holder
    if not self._notifyHolder then
        self._notifyHolder = Create("Frame", {
            Name = "NotifyHolder",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 300, 1, -20),
            Position = UDim2.new(1, -310, 0, 10),
            Parent = screenGui,
        })
        local notifyLayout = AddListLayout(self._notifyHolder, 6)
        notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end

    table.insert(self._windows, win)

    -- ===== CREATE BUILT-IN TABS (Config & Credits) =====
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
        Tween(self._main, { Size = UDim2.fromOffset(743, 384), BackgroundTransparency = 0 }, 0.25)
    else
        Tween(self._main, { Size = UDim2.fromOffset(743, 0), BackgroundTransparency = 1 }, 0.25)
        task.delay(0.25, function()
            if not self._visible then self._main.Visible = false end
        end)
    end
end

function Window:Destroy()
    self._library:Destroy()
end

function Window:SelectTab(tab)
    if type(tab) == "number" then
        tab = self._tabs[tab]
    end
    if tab then tab:_select() end
end

-- ============================================
-- TAB CREATION (User vs System)
-- ============================================
function Window:_createTabElement(title, parentContainer, order)
    local tab = setmetatable({}, Tab)
    tab._window = self
    tab._library = self._library
    tab._title = title
    tab._sections = {}

    -- Sidebar Button
    local tabButton = Create("TextButton", {
        Name = title,
        BackgroundColor3 = Theme.TabUnselected,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24),
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        AutoButtonColor = false,
        LayoutOrder = order or 1,
        Parent = parentContainer,
    })
    AddCorner(tabButton, Theme.CornerRadiusSmall)
    AddSafeShadow(tabButton)
    tab._tabButton = tabButton

    -- Page Container
    local tabPage = Create("ScrollingFrame", {
        Name = "Page_" .. title,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.TextSecondary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self._currentTabFrame,
    })
    local pageLayout = AddListLayout(tabPage, 8)
    AddPadding(tabPage, 10, 10, 10, 10)

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
    end)
    tab._tabPage = tabPage

    tabButton.MouseButton1Click:Connect(function()
        tab:_select()
    end)

    tabButton.MouseEnter:Connect(function()
        if self._selectedTab ~= tab then
            Tween(tabButton, { BackgroundTransparency = 0.2 }, 0.15)
        end
    end)
    tabButton.MouseLeave:Connect(function()
        if self._selectedTab ~= tab then
            Tween(tabButton, { BackgroundTransparency = 0.5 }, 0.15)
        end
    end)

    table.insert(self._tabs, tab)
    return tab
end

function Window:AddTab(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    local title = opts.Title or "Tab"
    
    self._userTabsCount = self._userTabsCount + 1
    local tab = self:_createTabElement(title, self._userTabsScroll, self._userTabsCount)

    if not self._selectedTab then
        tab:_select()
    end
    return tab
end

function Window:_initBuiltInTabs(container)
    -- Config Tab
    local configTab = self:_createTabElement("Config", container, 1)
    local cfgSec = configTab:AddSection("Theme & UI Customization")
    
    cfgSec:AddLabel("Select Preset Theme")
    cfgSec:AddButton({
        Title = "Dark Red (Default)",
        Callback = function()
            self._main.BackgroundColor3 = Color3.fromRGB(63, 0, 0)
            self._toggleBar.BackgroundColor3 = Color3.fromRGB(63, 0, 0)
            self._mainFrame.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
            self._tabsSidebar.BackgroundColor3 = Color3.fromRGB(62, 0, 0)
            self._currentTabFrame.BackgroundColor3 = Color3.fromRGB(62, 0, 0)
        end
    })
    cfgSec:AddButton({
        Title = "Midnight Purple",
        Callback = function()
            self._main.BackgroundColor3 = Color3.fromRGB(45, 20, 60)
            self._toggleBar.BackgroundColor3 = Color3.fromRGB(45, 20, 60)
            self._mainFrame.BackgroundColor3 = Color3.fromRGB(35, 15, 48)
            self._tabsSidebar.BackgroundColor3 = Color3.fromRGB(40, 18, 55)
            self._currentTabFrame.BackgroundColor3 = Color3.fromRGB(40, 18, 55)
        end
    })
    cfgSec:AddButton({
        Title = "Obsidian Dark",
        Callback = function()
            self._main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            self._toggleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            self._mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            self._tabsSidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            self._currentTabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        end
    })

    -- Credits Tab
    local creditsTab = self:_createTabElement("Credits", container, 2)
    self._creditsSection = creditsTab:AddSection("Developers & Contact")
    
    self._refreshCredits = function()
        -- Clear old items
        for _, child in ipairs(self._creditsSection._frame:GetChildren()) do
            if child:IsA("Frame") and child.Name:sub(1, 8) == "Contact_" then
                child:Destroy()
            end
        end
        -- Render contacts
        for i, contact in ipairs(self._library._contacts) do
            local order = self._library:_getOrder()
            local frame = Create("Frame", {
                Name = "Contact_" .. contact.Platform,
                BackgroundColor3 = Theme.ComponentBg,
                BackgroundTransparency = 0.4,
                Size = UDim2.new(1, -4, 0, 38),
                LayoutOrder = order,
                Parent = self._creditsSection._frame
            })
            AddCorner(frame, Theme.CornerRadiusSmall)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = Theme.ComponentFont,
                TextColor3 = Theme.TextPrimary,
                TextSize = 16,
                Text = "  " .. contact.Platform,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(0.6, 0, 1, 0),
                Parent = frame
            })

            local copyBtn = Create("TextButton", {
                BackgroundColor3 = Color3.fromRGB(80, 20, 20),
                FontFace = Theme.ComponentFontRegular,
                TextColor3 = Color3.fromRGB(240, 240, 240),
                TextSize = 13,
                Text = "Copy Link",
                Size = UDim2.new(0, 80, 0, 26),
                Position = UDim2.new(1, -88, 0.5, -13),
                AutoButtonColor = false,
                Parent = frame
            })
            AddCorner(copyBtn, Theme.CornerRadiusTiny)

            copyBtn.MouseButton1Click:Connect(function()
                local setclip = setclipboard or toclipboard or function() end
                pcall(setclip, contact.Link)
                copyBtn.Text = "Copied!"
                task.delay(1.5, function()
                    if copyBtn then copyBtn.Text = "Copy Link" end
                end)
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
        Tween(prev._tabButton, { BackgroundTransparency = 0.5, TextColor3 = Theme.TextSecondary }, 0.18)
    end
    win._selectedTab = self
    self._tabPage.Visible = true
    Tween(self._tabButton, { BackgroundTransparency = 0.1, TextColor3 = Theme.TextPrimary }, 0.18)
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
    section._tab = self
    section._library = self._library
    section._order = self._library:_getOrder()

    local sectionFrame = Create("Frame", {
        Name = "Section_" .. (title ~= "" and title or "Default"),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = section._order,
        Parent = self._tabPage,
    })
    section._frame = sectionFrame

    if title ~= "" then
        local titleFrame = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            LayoutOrder = 0,
            Parent = sectionFrame,
        })
        Create("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFont,
            TextColor3 = Theme.Accent,
            TextSize = 15,
            Text = string.upper(title),
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            Parent = titleFrame,
        })
        Create("Frame", {
            BackgroundColor3 = Theme.SectionLine,
            Size = UDim2.new(1, -8, 0, 1),
            Position = UDim2.new(0, 4, 1, -1),
            BackgroundTransparency = 0.4,
            Parent = titleFrame,
        })
    end

    local contentLayout = AddListLayout(sectionFrame, 6)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    table.insert(self._sections, section)
    return section
end

local function CreateCompFrame(parent, height, order)
    local frame = Create("Frame", {
        BackgroundColor3 = Theme.ComponentBg,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -4, 0, height or 32),
        LayoutOrder = order or 0,
        Parent = parent,
    })
    AddCorner(frame, Theme.CornerRadiusSmall)
    return frame
end

-- ============================================
-- COMPONENTS (Label, Paragraph, Button, Toggle, Slider, Dropdown, Textbox, Keybind)
-- ============================================
function Section:AddLabel(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    local order = self._library:_getOrder()
    local frame = CreateCompFrame(self._frame, 28, order)

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = opts.Title or "Label",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Parent = frame,
    })
    local comp = { _label = label, Value = opts.Title }
    function comp:SetText(t) self._label.Text = t; self.Value = t end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

function Section:AddParagraph(opts)
    opts = opts or {}
    local order = self._library:_getOrder()
    local frame = CreateCompFrame(self._frame, 0, order)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    AddPadding(frame, 8, 10, 8, 10)
    AddListLayout(frame, 3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextPrimary,
        TextSize = 15,
        Text = opts.Title or "Paragraph",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18),
        TextWrapped = true,
        LayoutOrder = 1,
        Parent = frame,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextTertiary,
        TextSize = 14,
        Text = opts.Content or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = frame,
    })
    return {}
end

function Section:AddButton(opts)
    opts = opts or {}
    local height = opts.Description and 46 or 34
    local frame = CreateCompFrame(self._frame, height, self._library:_getOrder())

    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = frame,
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextPrimary,
        TextSize = 15,
        Text = opts.Title or "Button",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -16, 0, opts.Description and 20 or 34),
        Position = UDim2.new(0, 10, 0, opts.Description and 4 or 0),
        Parent = frame,
    })

    if opts.Description then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFontRegular,
            TextColor3 = Theme.TextTertiary,
            TextSize = 12,
            Text = opts.Description,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 10, 0, 24),
            Parent = frame,
        })
    end

    btn.MouseEnter:Connect(function() Tween(frame, { BackgroundTransparency = 0.25 }, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(frame, { BackgroundTransparency = 0.5 }, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        Tween(frame, { BackgroundTransparency = 0.1 }, 0.08)
        task.delay(0.08, function() Tween(frame, { BackgroundTransparency = 0.5 }, 0.15) end)
        pcall(opts.Callback or function() end)
    end)
    return { _frame = frame }
end

function Section:AddToggle(opts)
    opts = opts or {}
    local default = opts.Default or false
    local height = opts.Description and 46 or 34
    local frame = CreateCompFrame(self._frame, height, self._library:_getOrder())

    local btn = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = frame })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = opts.Title or "Toggle",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 0, opts.Description and 20 or 34),
        Position = UDim2.new(0, 10, 0, opts.Description and 4 or 0),
        Parent = frame,
    })

    if opts.Description then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFontRegular,
            TextColor3 = Theme.TextTertiary,
            TextSize = 12,
            Text = opts.Description,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -60, 0, 16),
            Position = UDim2.new(0, 10, 0, 24),
            Parent = frame,
        })
    end

    local toggleBg = Create("Frame", {
        BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff,
        Size = UDim2.fromOffset(36, 18),
        Position = UDim2.new(1, -44, 0.5, -9),
        Parent = frame,
    })
    AddCorner(toggleBg, UDim.new(0, 9))

    local circle = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(14, 14),
        Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        Parent = toggleBg,
    })
    AddCorner(circle, UDim.new(0, 7))

    local comp = { Value = default, _cbs = {} }
    function comp:SetValue(v)
        self.Value = v
        Tween(toggleBg, { BackgroundColor3 = v and Theme.ToggleOn or Theme.ToggleOff }, 0.18)
        Tween(circle, { Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }, 0.18)
        pcall(opts.Callback or function() end, v)
        for _, fn in ipairs(self._cbs) do pcall(fn, v) end
    end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end

    btn.MouseButton1Click:Connect(function() comp:SetValue(not comp.Value) end)
    btn.MouseEnter:Connect(function() Tween(frame, { BackgroundTransparency = 0.3 }, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(frame, { BackgroundTransparency = 0.5 }, 0.15) end)

    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

function Section:AddSlider(opts)
    opts = opts or {}
    local min, max = opts.Min or 0, opts.Max or 100
    local default = math.clamp(opts.Default or min, min, max)
    local rounding = opts.Rounding or 0
    local height = opts.Description and 58 or 46
    local frame = CreateCompFrame(self._frame, height, self._library:_getOrder())

    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = opts.Title or "Slider",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 10, 0, 4),
        Parent = frame,
    })
    local valLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        Text = tostring(default),
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -60, 0, 4),
        Parent = frame,
    })

    local track = Create("Frame", {
        BackgroundColor3 = Theme.SliderBg,
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 0, opts.Description and 42 or 30),
        Parent = frame,
    })
    AddCorner(track, UDim.new(0, 3))

    local pct = (default - min) / math.max(max - min, 0.001)
    local fill = Create("Frame", { BackgroundColor3 = Theme.SliderFill, Size = UDim2.new(pct, 0, 1, 0), Parent = track })
    AddCorner(fill, UDim.new(0, 3))

    local knob = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(pct, -6, 0.5, -6),
        ZIndex = 2,
        Parent = track,
    })
    AddCorner(knob, UDim.new(0, 6))

    local inputArea = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 10, 0, 24), Position = UDim2.new(0, -5, 0, -9), Text = "", Parent = track })

    local comp = { Value = default, _cbs = {} }
    local function round(v)
        if rounding == 0 then return math.floor(v + 0.5) end
        local m = 10 ^ rounding
        return math.floor(v * m + 0.5) / m
    end

    local function update(p)
        p = math.clamp(p, 0, 1)
        local val = round(min + (max - min) * p)
        comp.Value = val
        valLabel.Text = tostring(val)
        Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.05)
        Tween(knob, { Position = UDim2.new(p, -6, 0.5, -6) }, 0.05)
        pcall(opts.Callback or function() end, val)
        for _, fn in ipairs(comp._cbs) do pcall(fn, val) end
    end

    function comp:SetValue(v) update((math.clamp(v, min, max) - min) / math.max(max - min, 0.001)) end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end

    local sliding = false
    inputArea.MouseButton1Down:Connect(function() sliding = true end)
    Library:_addConnection(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end))
    Library:_addConnection(UserInputService.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
            update((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
        end
    end))

    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

function Section:AddDropdown(opts)
    opts = opts or {}
    local values = opts.Values or {}
    local multi = opts.Multi or false
    local frame = CreateCompFrame(self._frame, opts.Description and 48 or 34, self._library:_getOrder())
    frame.ClipsDescendants = false
    frame.ZIndex = 5

    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = opts.Title or "Dropdown",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.5, -10, 0, opts.Description and 20 or 34),
        Position = UDim2.new(0, 10, 0, opts.Description and 4 or 0),
        ZIndex = 5,
        Parent = frame,
    })

    local dropBtn = Create("TextButton", {
        BackgroundColor3 = Theme.InputBg,
        Size = UDim2.new(0.45, 0, 0, 24),
        Position = UDim2.new(0.53, 0, 0, opts.Description and 4 or 5),
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextSecondary,
        TextSize = 13,
        Text = "  Select...",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        ZIndex = 6,
        Parent = frame,
    })
    AddCorner(dropBtn, Theme.CornerRadiusTiny)

    local dropList = Create("Frame", {
        BackgroundColor3 = Theme.DropdownBg,
        Size = UDim2.new(0.45, 0, 0, 0),
        Position = UDim2.new(0.53, 0, 0, (opts.Description and 4 or 5) + 26),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 20,
        Parent = frame,
    })
    AddCorner(dropList, Theme.CornerRadiusTiny)

    local scroll = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.TextSecondary,
        ZIndex = 21,
        Parent = dropList,
    })
    local layout = AddListLayout(scroll, 2)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
    end)

    local isOpen, selVal, selMulti = false, nil, {}
    local comp = { Value = nil, _cbs = {} }

    local function getDisp()
        if multi then
            local t = {}
            for k, v in pairs(selMulti) do if v then table.insert(t, tostring(k)) end end
            return #t == 0 and "  None" or "  " .. table.concat(t, ", ")
        else
            return selVal and "  " .. tostring(selVal) or "  Select..."
        end
    end

    local function fire()
        comp.Value = multi and selMulti or selVal
        dropBtn.Text = getDisp()
        pcall(opts.Callback or function() end, comp.Value)
        for _, fn in ipairs(comp._cbs) do pcall(fn, comp.Value) end
    end

    local function build()
        for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        for i, val in ipairs(values) do
            local item = Create("TextButton", {
                BackgroundColor3 = Theme.DropdownItem,
                BackgroundTransparency = 0.3,
                Size = UDim2.new(1, -4, 0, 22),
                FontFace = Theme.ComponentFontRegular,
                TextColor3 = Theme.TextSecondary,
                TextSize = 13,
                Text = "  " .. tostring(val),
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i,
                ZIndex = 22,
                Parent = scroll,
            })
            AddCorner(item, UDim.new(0, 3))
            item.MouseButton1Click:Connect(function()
                if multi then
                    selMulti[val] = not selMulti[val]
                    item.TextColor3 = selMulti[val] and Theme.TextPrimary or Theme.TextSecondary
                else
                    selVal = val
                    isOpen = false
                    dropList.Visible = false
                    Tween(dropList, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.15)
                end
                fire()
            end)
        end
    end
    build()

    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            dropList.Visible = true
            Tween(dropList, { Size = UDim2.new(0.45, 0, 0, math.min(#values, 5) * 24 + 6) }, 0.2)
        else
            Tween(dropList, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.2)
            task.delay(0.2, function() if not isOpen then dropList.Visible = false end end)
        end
    end)

    function comp:SetValue(v)
        if multi and type(v) == "table" then selMulti = v else selVal = v end
        fire()
    end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end

    if opts.Default then comp:SetValue(opts.Default) end
    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

function Section:AddTextbox(opts)
    opts = opts or {}
    local frame = CreateCompFrame(self._frame, 34, self._library:_getOrder())
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = opts.Title or "Input",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.5, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Parent = frame,
    })

    local tb = Create("TextBox", {
        BackgroundColor3 = Theme.InputBg,
        Size = UDim2.new(0.45, 0, 0, 24),
        Position = UDim2.new(0.53, 0, 0.5, -12),
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextPrimary,
        PlaceholderColor3 = Theme.TextTertiary,
        TextSize = 13,
        Text = opts.Default or "",
        PlaceholderText = opts.Placeholder or "Type...",
        Parent = frame,
    })
    AddCorner(tb, Theme.CornerRadiusTiny)

    local comp = { Value = opts.Default or "", _cbs = {} }
    tb.FocusLost:Connect(function()
        comp.Value = tb.Text
        pcall(opts.Callback or function() end, comp.Value)
        for _, fn in ipairs(comp._cbs) do pcall(fn, comp.Value) end
    end)

    function comp:SetValue(v) tb.Text = tostring(v); comp.Value = tostring(v) end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end

    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

function Section:AddKeybind(opts)
    opts = opts or {}
    local frame = CreateCompFrame(self._frame, 34, self._library:_getOrder())
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = opts.Title or "Keybind",
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.6, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Parent = frame,
    })

    local defaultKey = opts.Default or Enum.KeyCode.RightShift
    local keyBtn = Create("TextButton", {
        BackgroundColor3 = Theme.InputBg,
        Size = UDim2.new(0.35, 0, 0, 24),
        Position = UDim2.new(0.63, 0, 0.5, -12),
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        Text = tostring(defaultKey):gsub("Enum.KeyCode.", ""),
        Parent = frame,
    })
    AddCorner(keyBtn, Theme.CornerRadiusTiny)

    local comp = { Value = defaultKey, _binding = false, _cbs = {} }
    keyBtn.MouseButton1Click:Connect(function()
        comp._binding = true
        keyBtn.Text = "..."
    end)

    Library:_addConnection(UserInputService.InputBegan:Connect(function(inp, proc)
        if comp._binding and inp.UserInputType == Enum.UserInputType.Keyboard then
            comp.Value = inp.KeyCode
            keyBtn.Text = tostring(inp.KeyCode):gsub("Enum.KeyCode.", "")
            comp._binding = false
            pcall(opts.Callback or function() end, inp.KeyCode)
            for _, fn in ipairs(comp._cbs) do pcall(fn, inp.KeyCode) end
        end
    end))

    function comp:SetValue(k) self.Value = k; keyBtn.Text = tostring(k):gsub("Enum.KeyCode.", "") end
    function comp:GetValue() return self.Value end
    function comp:OnChanged(fn) table.insert(self._cbs, fn) end

    if opts.Flag then Library:_registerOption(opts.Flag, comp) end
    return comp
end

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================
function Library:Notify(opts)
    opts = opts or {}
    if not self._notifyHolder then return end
    
    local notify = Create("Frame", {
        BackgroundColor3 = Theme.NotifyBg,
        Size = UDim2.fromOffset(280, 65),
        BackgroundTransparency = 1,
        Parent = self._notifyHolder,
    })
    AddCorner(notify, Theme.CornerRadiusSmall)
    AddStroke(notify, Theme.NotifyBorder, 1)

    Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 4, 1, -10), Position = UDim2.new(0, 5, 0, 5), Parent = notify })
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFont, TextColor3 = Theme.TextPrimary, TextSize = 15, Text = opts.Title or "Notice", Size = UDim2.new(1, -25, 0, 20), Position = UDim2.new(0, 16, 0, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = notify })
    Create("TextLabel", { BackgroundTransparency = 1, FontFace = Theme.ComponentFontRegular, TextColor3 = Theme.TextSecondary, TextSize = 13, Text = opts.Content or "", Size = UDim2.new(1, -25, 0, 30), Position = UDim2.new(0, 16, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = notify })

    Tween(notify, { BackgroundTransparency = 0 }, 0.25)
    task.delay(opts.Duration or 4, function()
        Tween(notify, { BackgroundTransparency = 1 }, 0.3)
        task.delay(0.35, function() pcall(function() notify:Destroy() end) end)
    end)
end

function Library:Destroy()
    self.Unloaded = true
    for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    self._connections = {}
    if self._screenGui then pcall(function() self._screenGui:Destroy() end) end
end

-- ============================================
-- TAB SHORTCUT METHODS
-- ============================================
function Tab:_defSec()
    if not self._defaultSec then self._defaultSec = self:AddSection("") end
    return self._defaultSec
end
function Tab:AddLabel(o) return self:_defSec():AddLabel(o) end
function Tab:AddParagraph(o) return self:_defSec():AddParagraph(o) end
function Tab:AddButton(o) return self:_defSec():AddButton(o) end
function Tab:AddToggle(f, o)
    local s = self:_defSec()
    if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddToggle(o) end
    return s:AddToggle(f)
end
function Tab:AddSlider(f, o)
    local s = self:_defSec()
    if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddSlider(o) end
    return s:AddSlider(f)
end
function Tab:AddDropdown(f, o)
    local s = self:_defSec()
    if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddDropdown(o) end
    return s:AddDropdown(f)
end
function Tab:AddTextbox(f, o)
    local s = self:_defSec()
    if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddTextbox(o) end
    return s:AddTextbox(f)
end
function Tab:AddKeybind(f, o)
    local s = self:_defSec()
    if type(f) == "string" and type(o) == "table" then o.Flag = f; return s:AddKeybind(o) end
    return s:AddKeybind(f)
end

return Library
