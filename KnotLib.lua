--[[
    ██╗  ██╗███╗   ██╗ ██████╗ ████████╗██╗     ██╗██████╗ 
    ██║ ██╔╝████╗  ██║██╔═══██╗╚══██╔══╝██║     ██║██╔══██╗
    █████╔╝ ██╔██╗ ██║██║   ██║   ██║   ██║     ██║██████╔╝
    ██╔═██╗ ██║╚██╗██║██║   ██║   ██║   ██║     ██║██╔══██╗
    ██║  ██╗██║ ╚████║╚██████╔╝   ██║   ███████╗██║██████╔╝
    ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝╚═════╝ 
    
    KnotLib v1.0.0 - UI Library for Roblox (LuaU)
    Based on KnotHub UI Design
    
    Usage:
        local Library = loadstring(...)()
        local Window = Library:CreateWindow({ Title = "Hub", Version = "v1" })
        local Tab = Window:AddTab({ Title = "Main" })
        local Section = Tab:AddSection({ Title = "Farm" })
        Section:AddToggle({ Flag = "AutoFarm", Title = "Auto Farm", Default = false, Callback = function(v) end })
]]

-- ============================================
-- SERVICES
-- ============================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- THEME
-- ============================================
local Theme = {
    -- Cores da UI convertida
    Background       = Color3.fromRGB(37, 31, 37),
    ToggleBarBg      = Color3.fromRGB(63, 54, 62),
    MainFrameBg      = Color3.fromRGB(48, 40, 48),
    ComponentBg      = Color3.fromRGB(48, 40, 48),
    TextPrimary      = Color3.fromRGB(222, 222, 222),
    TextSecondary    = Color3.fromRGB(187, 187, 187),
    TextTertiary     = Color3.fromRGB(122, 122, 122),
    Accent           = Color3.fromRGB(222, 222, 222),
    ToggleOn         = Color3.fromRGB(120, 200, 120),
    ToggleOff        = Color3.fromRGB(80, 70, 80),
    SliderFill       = Color3.fromRGB(160, 140, 170),
    SliderBg         = Color3.fromRGB(60, 52, 60),
    Hover            = Color3.fromRGB(58, 50, 58),
    DropdownBg       = Color3.fromRGB(42, 36, 42),
    DropdownItem     = Color3.fromRGB(50, 43, 50),
    NotifyBg         = Color3.fromRGB(50, 43, 50),
    NotifyBorder     = Color3.fromRGB(70, 60, 70),
    TabSelected      = Color3.fromRGB(58, 50, 58),
    TabUnselected    = Color3.fromRGB(48, 40, 48),
    InputBg          = Color3.fromRGB(32, 27, 32),
    SectionLine      = Color3.fromRGB(60, 52, 60),

    -- Fontes da UI convertida
    TitleFont           = Font.new("rbxasset://fonts/families/Guru.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    VersionFont         = Font.new("rbxasset://fonts/families/Guru.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    ComponentFont       = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
    ComponentFontRegular = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),

    -- Layout
    CornerRadius      = UDim.new(0, 7),
    CornerRadiusSmall = UDim.new(0, 5),
    CornerRadiusTiny  = UDim.new(0, 4),
    TweenSpeed        = 0.25,
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
        Color = color or Theme.SectionLine,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = parent,
    })
end

local function GetParentGui()
    local success, result = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if success and result then return result end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================================
-- LIBRARY (Singleton)
-- ============================================
local Library = {}
Library.__index = Library
Library.Version = "1.0.0"
Library.Options = {}
Library.Flags = Library.Options -- alias
Library.Unloaded = false
Library._windows = {}
Library._connections = {}
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

-- ============================================
-- WINDOW CLASS
-- ============================================
local Window = {}
Window.__index = Window

function Library:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "KnotHub"
    local version = opts.Version or "v1.0"
    local size = opts.Size or UDim2.fromOffset(661, 346)
    local minimizeKey = opts.MinimizeKey or Enum.KeyCode.RightShift

    local win = setmetatable({}, Window)
    win._library = self
    win._tabs = {}
    win._selectedTab = nil
    win._minimized = false
    win._visible = true
    win._minimizeKey = minimizeKey

    -- ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "KnotLib",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = GetParentGui(),
    })
    self._screenGui = screenGui

    -- Main Frame
    local main = Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Parent = screenGui,
    })
    AddCorner(main, Theme.CornerRadius)
    win._main = main
    win._screenGui = screenGui

    -- ToggleBar (top bar)
    local toggleBar = Create("Frame", {
        Name = "ToggleBar",
        BackgroundColor3 = Theme.ToggleBarBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 31),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = main,
    })
    AddCorner(toggleBar, Theme.CornerRadius)
    win._toggleBar = toggleBar

    -- Bottom cover for ToggleBar rounded corners (so bottom is flat)
    Create("Frame", {
        Name = "ToggleBarCover",
        BackgroundColor3 = Theme.ToggleBarBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        Parent = toggleBar,
    })

    -- Title Label
    local titleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        BackgroundTransparency = 1,
        FontFace = Theme.TitleFont,
        TextColor3 = Theme.TextPrimary,
        TextSize = 25,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        Parent = toggleBar,
    })
    win._titleLabel = titleLabel

    -- Separator line
    local separator = Create("Frame", {
        Name = "Separator",
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        Parent = toggleBar,
    })
    AddCorner(separator, UDim.new(0, 1))
    win._separator = separator

    -- Version Label
    local versionLabel = Create("TextLabel", {
        Name = "VersionLabel",
        BackgroundTransparency = 1,
        FontFace = Theme.VersionFont,
        TextColor3 = Theme.TextTertiary,
        TextSize = 18,
        Text = version,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = toggleBar,
    })
    win._versionLabel = versionLabel

    -- Position separator and version based on title width
    local function updateTitleLayout()
        local textWidth = titleLabel.TextBounds.X
        separator.Position = UDim2.new(0, 12 + textWidth + 10, 0.5, -8)
        versionLabel.Position = UDim2.new(0, 12 + textWidth + 20, 0, 0)
    end
    titleLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateTitleLayout)
    task.defer(updateTitleLayout)

    -- Minimize button
    local minimizeBtn = Create("TextButton", {
        Name = "MinimizeBtn",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 18,
        Text = "−",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -32, 0, 0),
        Parent = toggleBar,
    })
    minimizeBtn.MouseButton1Click:Connect(function()
        win:Minimize()
    end)
    minimizeBtn.MouseEnter:Connect(function()
        Tween(minimizeBtn, { TextColor3 = Theme.TextPrimary }, 0.15)
    end)
    minimizeBtn.MouseLeave:Connect(function()
        Tween(minimizeBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
    end)

    -- MainFrame (content area below ToggleBar)
    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = Theme.MainFrameBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -18, 1, -42),
        Position = UDim2.new(0, 9, 0, 36),
        ClipsDescendants = true,
        Parent = main,
    })
    AddCorner(mainFrame)
    win._mainFrame = mainFrame

    -- Tabs Sidebar
    local tabsSidebar = Create("Frame", {
        Name = "Tabs",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 97, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        ClipsDescendants = true,
        Parent = mainFrame,
    })
    AddCorner(tabsSidebar)
    win._tabsSidebar = tabsSidebar

    -- Tabs list inside sidebar
    local tabsScrollFrame = Create("ScrollingFrame", {
        Name = "TabsList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.TextTertiary,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = tabsSidebar,
    })
    local tabsLayout = AddListLayout(tabsScrollFrame, 4)
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    win._tabsScrollFrame = tabsScrollFrame

    -- CurrentTab content area
    local currentTabFrame = Create("Frame", {
        Name = "CurrentTab",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -115, 1, -12),
        Position = UDim2.new(0, 109, 0, 6),
        ClipsDescendants = true,
        Parent = mainFrame,
    })
    AddCorner(currentTabFrame)
    win._currentTabFrame = currentTabFrame

    -- Drag system
    local dragging = false
    local dragStart, startPos

    self:_addConnection(toggleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    self:_addConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(main, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }, 0.08)
        end
    end))

    -- Minimize keybind
    self:_addConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == minimizeKey then
            win:Minimize()
        end
    end))

    -- Notification holder
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
    return win
end

-- Window methods
function Window:SetTitle(title)
    self._titleLabel.Text = title
end

function Window:SetVersion(version)
    self._versionLabel.Text = version
end

function Window:Destroy()
    self._screenGui:Destroy()
end

function Window:Hide()
    self._visible = false
    Tween(self._main, { Size = UDim2.new(0, self._main.Size.X.Offset, 0, 0) }, 0.3)
    task.delay(0.3, function()
        if not self._visible then
            self._main.Visible = false
        end
    end)
end

function Window:Show()
    self._visible = true
    self._main.Visible = true
    local targetSize = self._screenGui and self._main:GetAttribute("OriginalSize") or UDim2.fromOffset(661, 346)
    Tween(self._main, { Size = targetSize }, 0.3)
end

function Window:Minimize()
    if self._minimized then
        -- Restore
        self._minimized = false
        self._mainFrame.Visible = true
        local targetSize = self._main:GetAttribute("OriginalSize") or UDim2.fromOffset(661, 346)
        Tween(self._main, { Size = targetSize }, 0.3)
    else
        -- Minimize
        self._minimized = true
        self._main:SetAttribute("OriginalSize", self._main.Size)
        Tween(self._main, { Size = UDim2.new(0, self._main.Size.X.Offset, 0, 31) }, 0.3)
        task.delay(0.3, function()
            if self._minimized then
                self._mainFrame.Visible = false
            end
        end)
    end
end

function Window:SelectTab(indexOrTab)
    if type(indexOrTab) == "number" then
        local tab = self._tabs[indexOrTab]
        if tab then tab:_select() end
    else
        indexOrTab:_select()
    end
end

-- ============================================
-- TAB CLASS
-- ============================================
local Tab = {}
Tab.__index = Tab

function Window:AddTab(opts)
    opts = opts or {}
    local title = opts.Title or "Tab"
    local icon = opts.Icon

    local tab = setmetatable({}, Tab)
    tab._window = self
    tab._library = self._library
    tab._title = title
    tab._sections = {}
    tab._order = #self._tabs + 1

    -- Tab button in sidebar
    local tabButton = Create("TextButton", {
        Name = "Tab_" .. title,
        BackgroundColor3 = Theme.TabUnselected,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 26),
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        AutoButtonColor = false,
        LayoutOrder = tab._order,
        Parent = self._tabsScrollFrame,
    })
    AddCorner(tabButton, Theme.CornerRadiusSmall)
    tab._tabButton = tabButton

    -- Tab page (ScrollingFrame) inside CurrentTab area
    local tabPage = Create("ScrollingFrame", {
        Name = "Page_" .. title,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.TextTertiary,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self._currentTabFrame,
    })
    local pageLayout = AddListLayout(tabPage, 8)
    pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    AddPadding(tabPage, 8, 8, 8, 8)
    tab._tabPage = tabPage
    tab._pageLayout = pageLayout

    -- Tab button interactions
    tabButton.MouseButton1Click:Connect(function()
        tab:_select()
    end)
    tabButton.MouseEnter:Connect(function()
        if self._selectedTab ~= tab then
            Tween(tabButton, { BackgroundTransparency = 0.3 }, 0.15)
        end
    end)
    tabButton.MouseLeave:Connect(function()
        if self._selectedTab ~= tab then
            Tween(tabButton, { BackgroundTransparency = 0.5 }, 0.15)
        end
    end)

    table.insert(self._tabs, tab)

    -- Auto-select first tab
    if #self._tabs == 1 then
        tab:_select()
    end

    return tab
end

function Tab:_select()
    local win = self._window

    -- Deselect previous
    if win._selectedTab and win._selectedTab ~= self then
        local prev = win._selectedTab
        prev._tabPage.Visible = false
        Tween(prev._tabButton, { BackgroundTransparency = 0.5, TextColor3 = Theme.TextSecondary }, 0.2)
    end

    -- Select this tab
    win._selectedTab = self
    self._tabPage.Visible = true
    Tween(self._tabButton, { BackgroundTransparency = 0.15, TextColor3 = Theme.TextPrimary }, 0.2)

    -- Fade in animation
    self._tabPage.GroupTransparency = 1
    -- Use CanvasGroup if available, otherwise just show
    local success = pcall(function()
        -- Simple visibility toggle with opacity tween on children
    end)
end

function Tab:Show()
    self._tabPage.Visible = true
end

function Tab:Hide()
    self._tabPage.Visible = false
end

-- ============================================
-- SECTION CLASS
-- ============================================
local Section = {}
Section.__index = Section

function Tab:AddSection(opts)
    if type(opts) == "string" then
        opts = { Title = opts }
    end
    opts = opts or {}
    local title = opts.Title or "Section"

    local section = setmetatable({}, Section)
    section._tab = self
    section._library = self._library
    section._title = title
    section._order = self._library:_getOrder()

    -- Section container
    local sectionFrame = Create("Frame", {
        Name = "Section_" .. title,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = section._order,
        Parent = self._tabPage,
    })
    section._frame = sectionFrame

    -- Section title
    local titleFrame = Create("Frame", {
        Name = "SectionTitle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        LayoutOrder = 0,
        Parent = sectionFrame,
    })

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextTertiary,
        TextSize = 14,
        Text = string.upper(title),
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        Parent = titleFrame,
    })

    -- Section line
    Create("Frame", {
        Name = "Line",
        BackgroundColor3 = Theme.SectionLine,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 1),
        Position = UDim2.new(0, 4, 1, -1),
        BackgroundTransparency = 0.5,
        Parent = titleFrame,
    })

    -- Content layout
    local contentLayout = AddListLayout(sectionFrame, 5)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    section._contentLayout = contentLayout

    return section
end

-- ============================================
-- COMPONENTS
-- ============================================

-- Helper: create component container
local function CreateComponentFrame(parent, height, order)
    local frame = Create("Frame", {
        Name = "Component",
        BackgroundColor3 = Theme.ComponentBg,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, height or 32),
        LayoutOrder = order or 0,
        Parent = parent,
    })
    AddCorner(frame, Theme.CornerRadiusSmall)
    return frame
end

-- ─────────────────────────────────────
-- ADD LABEL
-- ─────────────────────────────────────
function Section:AddLabel(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    local title = opts.Title or "Label"
    local flag = opts.Flag

    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, 28, order)

    local label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Parent = frame,
    })

    local comp = { _frame = frame, _label = label, Value = title, Type = "Label" }

    function comp:SetText(text)
        self._label.Text = text
        self.Value = text
    end

    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ─────────────────────────────────────
-- ADD PARAGRAPH
-- ─────────────────────────────────────
function Section:AddParagraph(opts)
    opts = opts or {}
    local title = opts.Title or "Paragraph"
    local content = opts.Content or ""
    local flag = opts.Flag

    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, 0, order)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Size = UDim2.new(1, -4, 0, 0)

    AddPadding(frame, 6, 8, 6, 8)

    local innerLayout = AddListLayout(frame, 2)
    innerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local titleLabel = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextPrimary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        LayoutOrder = 1,
        Parent = frame,
    })

    local contentLabel = Create("TextLabel", {
        Name = "Content",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextTertiary,
        TextSize = 14,
        Text = content,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = frame,
    })

    local comp = { _frame = frame, _titleLabel = titleLabel, _contentLabel = contentLabel, Type = "Paragraph" }

    function comp:SetTitle(text)
        self._titleLabel.Text = text
    end

    function comp:SetContent(text)
        self._contentLabel.Text = text
    end

    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ─────────────────────────────────────
-- ADD BUTTON
-- ─────────────────────────────────────
function Section:AddButton(opts)
    opts = opts or {}
    local title = opts.Title or "Button"
    local description = opts.Description or nil
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local height = description and 44 or 32
    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, height, order)

    local btn = Create("TextButton", {
        Name = "Button",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -12, 0, description and 18 or 32),
        Position = UDim2.new(0, 8, 0, description and 4 or 0),
        Parent = frame,
    })

    if description then
        Create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFontRegular,
            TextColor3 = Theme.TextTertiary,
            TextSize = 12,
            Text = description,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -12, 0, 16),
            Position = UDim2.new(0, 8, 0, 24),
            Parent = frame,
        })
    end

    -- Hover effects
    btn.MouseEnter:Connect(function()
        Tween(frame, { BackgroundTransparency = 0.3 }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(frame, { BackgroundTransparency = 0.5 }, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        -- Press animation
        Tween(frame, { BackgroundTransparency = 0.1 }, 0.08)
        task.delay(0.08, function()
            Tween(frame, { BackgroundTransparency = 0.5 }, 0.15)
        end)
        pcall(callback)
    end)

    local comp = { _frame = frame, _btn = btn, Type = "Button" }
    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ─────────────────────────────────────
-- ADD TOGGLE
-- ─────────────────────────────────────
function Section:AddToggle(opts)
    opts = opts or {}
    local title = opts.Title or "Toggle"
    local description = opts.Description or nil
    local default = opts.Default or false
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local height = description and 44 or 32
    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, height, order)

    local btn = Create("TextButton", {
        Name = "ToggleBtn",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = frame,
    })

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 0, description and 18 or 32),
        Position = UDim2.new(0, 8, 0, description and 4 or 0),
        Parent = frame,
    })

    if description then
        Create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFontRegular,
            TextColor3 = Theme.TextTertiary,
            TextSize = 12,
            Text = description,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -60, 0, 16),
            Position = UDim2.new(0, 8, 0, 24),
            Parent = frame,
        })
    end

    -- Toggle indicator
    local toggleBg = Create("Frame", {
        Name = "ToggleBg",
        BackgroundColor3 = default and Theme.ToggleOn or Theme.ToggleOff,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -44, 0.5, -9),
        Parent = frame,
    })
    AddCorner(toggleBg, UDim.new(0, 9))

    local toggleCircle = Create("Frame", {
        Name = "Circle",
        BackgroundColor3 = Theme.TextPrimary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 14, 0, 14),
        Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        Parent = toggleBg,
    })
    AddCorner(toggleCircle, UDim.new(0, 7))

    local comp = { _frame = frame, _toggleBg = toggleBg, _toggleCircle = toggleCircle, Value = default, Type = "Toggle", _changedCallbacks = {} }

    function comp:SetValue(val)
        self.Value = val
        Tween(self._toggleBg, { BackgroundColor3 = val and Theme.ToggleOn or Theme.ToggleOff }, 0.2)
        Tween(self._toggleCircle, { Position = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }, 0.2)
        pcall(callback, val)
        for _, cb in ipairs(self._changedCallbacks) do
            pcall(cb, val)
        end
    end

    function comp:GetValue()
        return self.Value
    end

    function comp:OnChanged(fn)
        table.insert(self._changedCallbacks, fn)
    end

    -- Click handler
    btn.MouseButton1Click:Connect(function()
        comp:SetValue(not comp.Value)
    end)

    -- Hover
    btn.MouseEnter:Connect(function()
        Tween(frame, { BackgroundTransparency = 0.35 }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(frame, { BackgroundTransparency = 0.5 }, 0.15)
    end)

    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ─────────────────────────────────────
-- ADD SLIDER
-- ─────────────────────────────────────
function Section:AddSlider(opts)
    opts = opts or {}
    local title = opts.Title or "Slider"
    local description = opts.Description or nil
    local min = opts.Min or 0
    local max = opts.Max or 100
    local default = opts.Default or min
    local rounding = opts.Rounding or 0
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local height = description and 58 or 48
    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, height, order)

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -60, 0, 18),
        Position = UDim2.new(0, 8, 0, 4),
        Parent = frame,
    })

    local valueLabel = Create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        Text = tostring(default),
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0, 50, 0, 18),
        Position = UDim2.new(1, -58, 0, 4),
        Parent = frame,
    })

    if description then
        Create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFontRegular,
            TextColor3 = Theme.TextTertiary,
            TextSize = 12,
            Text = description,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -16, 0, 14),
            Position = UDim2.new(0, 8, 0, 22),
            Parent = frame,
        })
    end

    -- Slider track
    local sliderY = description and 42 or 28
    local sliderTrack = Create("Frame", {
        Name = "Track",
        BackgroundColor3 = Theme.SliderBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -16, 0, 6),
        Position = UDim2.new(0, 8, 0, sliderY),
        Parent = frame,
    })
    AddCorner(sliderTrack, UDim.new(0, 3))

    local fillPercent = math.clamp((default - min) / (max - min), 0, 1)

    local sliderFill = Create("Frame", {
        Name = "Fill",
        BackgroundColor3 = Theme.SliderFill,
        BorderSizePixel = 0,
        Size = UDim2.new(fillPercent, 0, 1, 0),
        Parent = sliderTrack,
    })
    AddCorner(sliderFill, UDim.new(0, 3))

    local sliderKnob = Create("Frame", {
        Name = "Knob",
        BackgroundColor3 = Theme.TextPrimary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(fillPercent, -6, 0.5, -6),
        ZIndex = 2,
        Parent = sliderTrack,
    })
    AddCorner(sliderKnob, UDim.new(0, 6))

    -- Slider input area
    local sliderInput = Create("TextButton", {
        Name = "SliderInput",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 10, 0, 20),
        Position = UDim2.new(0, -5, 0, -7),
        Text = "",
        ZIndex = 3,
        Parent = sliderTrack,
    })

    local comp = { _frame = frame, _fill = sliderFill, _knob = sliderKnob, _valueLabel = valueLabel, Value = default, Type = "Slider", _changedCallbacks = {} }

    local function roundValue(val)
        if rounding == 0 then
            return math.floor(val + 0.5)
        else
            local mult = 10 ^ rounding
            return math.floor(val * mult + 0.5) / mult
        end
    end

    local function updateSlider(percent)
        percent = math.clamp(percent, 0, 1)
        local rawVal = min + (max - min) * percent
        local val = roundValue(rawVal)
        comp.Value = val
        valueLabel.Text = tostring(val)
        Tween(sliderFill, { Size = UDim2.new(percent, 0, 1, 0) }, 0.05)
        Tween(sliderKnob, { Position = UDim2.new(percent, -6, 0.5, -6) }, 0.05)
        pcall(callback, val)
        for _, cb in ipairs(comp._changedCallbacks) do
            pcall(cb, val)
        end
    end

    function comp:SetValue(val)
        val = math.clamp(val, min, max)
        local percent = (val - min) / (max - min)
        updateSlider(percent)
    end

    function comp:GetValue()
        return self.Value
    end

    function comp:OnChanged(fn)
        table.insert(self._changedCallbacks, fn)
    end

    -- Drag handling
    local sliding = false
    sliderInput.MouseButton1Down:Connect(function()
        sliding = true
    end)

    Library:_addConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end))

    Library:_addConnection(UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackPos = sliderTrack.AbsolutePosition.X
            local trackSize = sliderTrack.AbsoluteSize.X
            local mouseX = input.Position.X
            local percent = math.clamp((mouseX - trackPos) / trackSize, 0, 1)
            updateSlider(percent)
        end
    end))

    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ─────────────────────────────────────
-- ADD DROPDOWN
-- ─────────────────────────────────────
function Section:AddDropdown(opts)
    opts = opts or {}
    local title = opts.Title or "Dropdown"
    local description = opts.Description or nil
    local values = opts.Values or {}
    local multi = opts.Multi or false
    local default = opts.Default
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local height = description and 48 or 32
    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, height, order)
    frame.ClipsDescendants = false
    frame.ZIndex = 5

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.5, -8, 0, description and 18 or 32),
        Position = UDim2.new(0, 8, 0, description and 4 or 0),
        ZIndex = 5,
        Parent = frame,
    })

    if description then
        Create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFontRegular,
            TextColor3 = Theme.TextTertiary,
            TextSize = 12,
            Text = description,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 8, 0, 24),
            ZIndex = 5,
            Parent = frame,
        })
    end

    -- Selected display / button
    local dropBtn = Create("TextButton", {
        Name = "DropBtn",
        BackgroundColor3 = Theme.InputBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0.45, 0, 0, 22),
        Position = UDim2.new(0.53, 0, 0, description and 4 or 5),
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextSecondary,
        TextSize = 13,
        Text = "Select...",
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        ZIndex = 6,
        Parent = frame,
    })
    AddCorner(dropBtn, Theme.CornerRadiusTiny)

    -- Arrow
    Create("TextLabel", {
        Name = "Arrow",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextTertiary,
        TextSize = 12,
        Text = "▼",
        Size = UDim2.new(0, 18, 1, 0),
        Position = UDim2.new(1, -18, 0, 0),
        ZIndex = 7,
        Parent = dropBtn,
    })

    -- Dropdown list (expandable)
    local dropList = Create("Frame", {
        Name = "DropList",
        BackgroundColor3 = Theme.DropdownBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0.45, 0, 0, 0),
        Position = UDim2.new(0.53, 0, 0, (description and 4 or 5) + 24),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 10,
        Parent = frame,
    })
    AddCorner(dropList, Theme.CornerRadiusTiny)

    local dropScroll = Create("ScrollingFrame", {
        Name = "DropScroll",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.TextTertiary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 11,
        Parent = dropList,
    })
    local dropLayout = AddListLayout(dropScroll, 2)
    dropLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local isOpen = false
    local selectedValue = nil
    local selectedMulti = {} -- for multi select

    local comp = {
        _frame = frame, _dropBtn = dropBtn, _dropList = dropList, _dropScroll = dropScroll,
        Value = nil, Type = "Dropdown", _changedCallbacks = {}, _values = values, _multi = multi,
        _items = {},
    }

    local function getDisplayText()
        if multi then
            local selected = {}
            for val, state in pairs(selectedMulti) do
                if state then table.insert(selected, val) end
            end
            if #selected == 0 then return "None" end
            return table.concat(selected, ", ")
        else
            return selectedValue or "Select..."
        end
    end

    local function updateDisplay()
        dropBtn.Text = "  " .. getDisplayText()
    end

    local function fireCallback()
        if multi then
            local copy = {}
            for k, v in pairs(selectedMulti) do copy[k] = v end
            comp.Value = copy
            pcall(callback, copy)
            for _, cb in ipairs(comp._changedCallbacks) do pcall(cb, copy) end
        else
            comp.Value = selectedValue
            pcall(callback, selectedValue)
            for _, cb in ipairs(comp._changedCallbacks) do pcall(cb, selectedValue) end
        end
    end

    local function buildItems()
        for _, item in ipairs(comp._items) do
            item:Destroy()
        end
        comp._items = {}

        for i, val in ipairs(comp._values) do
            local itemBtn = Create("TextButton", {
                Name = "Item_" .. val,
                BackgroundColor3 = Theme.DropdownItem,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 22),
                FontFace = Theme.ComponentFontRegular,
                TextColor3 = Theme.TextSecondary,
                TextSize = 13,
                Text = "  " .. val,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                LayoutOrder = i,
                ZIndex = 12,
                Parent = dropScroll,
            })
            AddCorner(itemBtn, UDim.new(0, 3))

            itemBtn.MouseEnter:Connect(function()
                Tween(itemBtn, { BackgroundTransparency = 0.1 }, 0.1)
            end)
            itemBtn.MouseLeave:Connect(function()
                Tween(itemBtn, { BackgroundTransparency = 0.3 }, 0.1)
            end)

            itemBtn.MouseButton1Click:Connect(function()
                if multi then
                    selectedMulti[val] = not selectedMulti[val]
                    if selectedMulti[val] then
                        itemBtn.TextColor3 = Theme.TextPrimary
                    else
                        itemBtn.TextColor3 = Theme.TextSecondary
                    end
                else
                    selectedValue = val
                    updateDisplay()
                    fireCallback()
                    -- Close dropdown
                    isOpen = false
                    Tween(dropList, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.2)
                    task.delay(0.2, function()
                        if not isOpen then dropList.Visible = false end
                    end)
                end
                updateDisplay()
                if multi then fireCallback() end
            end)

            table.insert(comp._items, itemBtn)
        end
    end

    buildItems()

    -- Toggle dropdown
    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            dropList.Visible = true
            local itemCount = math.min(#comp._values, 6)
            local targetHeight = itemCount * 24 + 6
            Tween(dropList, { Size = UDim2.new(0.45, 0, 0, targetHeight) }, 0.25)
        else
            Tween(dropList, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.2)
            task.delay(0.2, function()
                if not isOpen then dropList.Visible = false end
            end)
        end
    end)

    -- Set default
    if default then
        if multi then
            if type(default) == "table" then
                for _, v in ipairs(default) do
                    selectedMulti[v] = true
                end
            end
        else
            if type(default) == "number" and values[default] then
                selectedValue = values[default]
            else
                selectedValue = default
            end
        end
        updateDisplay()
        comp.Value = multi and selectedMulti or selectedValue
    end

    function comp:SetValue(val)
        if multi then
            if type(val) == "table" then
                for k, v in pairs(val) do
                    selectedMulti[k] = v
                end
                updateDisplay()
                fireCallback()
            end
        else
            selectedValue = val
            updateDisplay()
            fireCallback()
        end
    end

    function comp:GetValue()
        return self.Value
    end

    function comp:SetValues(newValues)
        comp._values = newValues
        buildItems()
        if not multi then
            if not table.find(newValues, selectedValue) then
                selectedValue = newValues[1]
                updateDisplay()
            end
        end
    end

    function comp:OnChanged(fn)
        table.insert(self._changedCallbacks, fn)
    end

    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ─────────────────────────────────────
-- ADD TEXTBOX
-- ─────────────────────────────────────
function Section:AddTextbox(opts)
    opts = opts or {}
    local title = opts.Title or "Input"
    local placeholder = opts.Placeholder or "Type here..."
    local default = opts.Default or ""
    local numeric = opts.Numeric or false
    local finished = opts.Finished or false
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, 32, order)

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.5, -8, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Parent = frame,
    })

    local textBox = Create("TextBox", {
        Name = "Input",
        BackgroundColor3 = Theme.InputBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0.45, 0, 0, 22),
        Position = UDim2.new(0.53, 0, 0.5, -11),
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextPrimary,
        PlaceholderColor3 = Theme.TextTertiary,
        TextSize = 13,
        Text = default,
        PlaceholderText = placeholder,
        ClearTextOnFocus = false,
        Parent = frame,
    })
    AddCorner(textBox, Theme.CornerRadiusTiny)
    AddPadding(textBox, 0, 6, 0, 6)

    local comp = { _frame = frame, _textBox = textBox, Value = default, Type = "Input", _changedCallbacks = {} }

    local function onTextChanged()
        local text = textBox.Text
        if numeric then
            text = text:gsub("[^%d%.%-]", "")
            if text ~= textBox.Text then textBox.Text = text end
        end
        comp.Value = text
    end

    if finished then
        textBox.FocusLost:Connect(function(enterPressed)
            onTextChanged()
            pcall(callback, comp.Value)
            for _, cb in ipairs(comp._changedCallbacks) do pcall(cb, comp.Value) end
        end)
    else
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            onTextChanged()
            pcall(callback, comp.Value)
            for _, cb in ipairs(comp._changedCallbacks) do pcall(cb, comp.Value) end
        end)
    end

    function comp:SetValue(val)
        self._textBox.Text = tostring(val)
        self.Value = tostring(val)
    end

    function comp:GetValue()
        return self.Value
    end

    function comp:OnChanged(fn)
        table.insert(self._changedCallbacks, fn)
    end

    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ─────────────────────────────────────
-- ADD KEYBIND
-- ─────────────────────────────────────
function Section:AddKeybind(opts)
    opts = opts or {}
    local title = opts.Title or "Keybind"
    local default = opts.Default or Enum.KeyCode.RightShift
    local mode = opts.Mode or "Toggle" -- Always, Toggle, Hold
    local callback = opts.Callback or function() end
    local changedCallback = opts.ChangedCallback or nil
    local flag = opts.Flag

    -- Resolve default if string
    if type(default) == "string" then
        if default == "MB1" then
            default = Enum.UserInputType.MouseButton1
        elseif default == "MB2" then
            default = Enum.UserInputType.MouseButton2
        else
            pcall(function() default = Enum.KeyCode[default] end)
        end
    end

    local order = self._library:_getOrder()
    local frame = CreateComponentFrame(self._frame, 32, order)

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.6, -8, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Parent = frame,
    })

    local keyBtn = Create("TextButton", {
        Name = "KeyBtn",
        BackgroundColor3 = Theme.InputBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0.35, 0, 0, 22),
        Position = UDim2.new(0.63, 0, 0.5, -11),
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        Text = tostring(default):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", ""),
        AutoButtonColor = false,
        Parent = frame,
    })
    AddCorner(keyBtn, Theme.CornerRadiusTiny)

    local comp = {
        _frame = frame, _keyBtn = keyBtn,
        Value = default, Type = "Keybind",
        _mode = mode, _state = false, _binding = false,
        _changedCallbacks = {}, _clickCallbacks = {},
    }

    local function getKeyName(key)
        local name = tostring(key)
        name = name:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
        return name
    end

    -- Click to rebind
    keyBtn.MouseButton1Click:Connect(function()
        comp._binding = true
        keyBtn.Text = "..."
    end)

    Library:_addConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if comp._binding then
            local key
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                key = Enum.UserInputType.MouseButton1
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                key = Enum.UserInputType.MouseButton2
            end

            if key then
                comp.Value = key
                keyBtn.Text = getKeyName(key)
                comp._binding = false
                if changedCallback then pcall(changedCallback, key) end
                for _, cb in ipairs(comp._changedCallbacks) do pcall(cb, key) end
            end
            return
        end

        if processed then return end

        local isMatch = false
        if typeof(comp.Value) == "EnumItem" then
            if comp.Value.EnumType == Enum.KeyCode and input.KeyCode == comp.Value then
                isMatch = true
            elseif comp.Value.EnumType == Enum.UserInputType and input.UserInputType == comp.Value then
                isMatch = true
            end
        end

        if isMatch then
            if comp._mode == "Toggle" then
                comp._state = not comp._state
                pcall(callback, comp._state)
                for _, cb in ipairs(comp._clickCallbacks) do pcall(cb) end
            elseif comp._mode == "Hold" then
                comp._state = true
                pcall(callback, true)
            elseif comp._mode == "Always" then
                comp._state = true
                pcall(callback, true)
                for _, cb in ipairs(comp._clickCallbacks) do pcall(cb) end
            end
        end
    end))

    Library:_addConnection(UserInputService.InputEnded:Connect(function(input)
        if comp._mode == "Hold" then
            local isMatch = false
            if typeof(comp.Value) == "EnumItem" then
                if comp.Value.EnumType == Enum.KeyCode and input.KeyCode == comp.Value then
                    isMatch = true
                elseif comp.Value.EnumType == Enum.UserInputType and input.UserInputType == comp.Value then
                    isMatch = true
                end
            end
            if isMatch then
                comp._state = false
                pcall(callback, false)
            end
        end
    end))

    function comp:SetValue(key, newMode)
        if type(key) == "string" then
            if key == "MB1" then
                key = Enum.UserInputType.MouseButton1
            elseif key == "MB2" then
                key = Enum.UserInputType.MouseButton2
            else
                pcall(function() key = Enum.KeyCode[key] end)
            end
        end
        self.Value = key
        self._keyBtn.Text = getKeyName(key)
        if newMode then self._mode = newMode end
    end

    function comp:GetState()
        return self._state
    end

    function comp:OnClick(fn)
        table.insert(self._clickCallbacks, fn)
    end

    function comp:OnChanged(fn)
        table.insert(self._changedCallbacks, fn)
    end

    -- Hover
    keyBtn.MouseEnter:Connect(function()
        Tween(keyBtn, { BackgroundColor3 = Theme.Hover }, 0.15)
    end)
    keyBtn.MouseLeave:Connect(function()
        Tween(keyBtn, { BackgroundColor3 = Theme.InputBg }, 0.15)
    end)

    if flag then self._library:_registerOption(flag, comp) end
    return comp
end

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================
function Library:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notification"
    local content = opts.Content or ""
    local subContent = opts.SubContent or nil
    local duration = opts.Duration or 5

    if not self._notifyHolder then return end

    local notifyHeight = subContent and 72 or 58

    local notifyFrame = Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.NotifyBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 280, 0, notifyHeight),
        BackgroundTransparency = 1,
        Parent = self._notifyHolder,
    })
    AddCorner(notifyFrame, Theme.CornerRadiusSmall)
    AddStroke(notifyFrame, Theme.NotifyBorder, 1, 0.3)

    -- Accent bar on left
    Create("Frame", {
        Name = "AccentBar",
        BackgroundColor3 = Theme.SliderFill,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        Parent = notifyFrame,
    })

    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFont,
        TextColor3 = Theme.TextPrimary,
        TextSize = 15,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 14, 0, 4),
        Parent = notifyFrame,
    })

    Create("TextLabel", {
        Name = "Content",
        BackgroundTransparency = 1,
        FontFace = Theme.ComponentFontRegular,
        TextColor3 = Theme.TextSecondary,
        TextSize = 13,
        Text = content,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 14, 0, 24),
        Parent = notifyFrame,
    })

    if subContent then
        Create("TextLabel", {
            Name = "SubContent",
            BackgroundTransparency = 1,
            FontFace = Theme.ComponentFontRegular,
            TextColor3 = Theme.TextTertiary,
            TextSize = 12,
            Text = subContent,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 14, 0, 44),
            Parent = notifyFrame,
        })
    end

    -- Progress bar
    local progressBg = Create("Frame", {
        Name = "ProgressBg",
        BackgroundColor3 = Theme.SliderBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -14, 0, 2),
        Position = UDim2.new(0, 7, 1, -5),
        Parent = notifyFrame,
    })
    AddCorner(progressBg, UDim.new(0, 1))

    local progressFill = Create("Frame", {
        Name = "ProgressFill",
        BackgroundColor3 = Theme.SliderFill,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = progressBg,
    })
    AddCorner(progressFill, UDim.new(0, 1))

    -- Animate in
    Tween(notifyFrame, { BackgroundTransparency = 0 }, 0.3)

    -- Animate progress bar
    if duration then
        Tween(progressFill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

        -- Animate out after duration
        task.delay(duration, function()
            Tween(notifyFrame, { BackgroundTransparency = 1 }, 0.4)
            task.delay(0.5, function()
                notifyFrame:Destroy()
            end)
        end)
    end
end

-- ============================================
-- LIBRARY CLEANUP
-- ============================================
function Library:Destroy()
    self.Unloaded = true
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
    for _, w in ipairs(self._windows) do
        pcall(function() w:Destroy() end)
    end
    self._windows = {}
    if self._screenGui then
        pcall(function() self._screenGui:Destroy() end)
    end
end

-- ============================================
-- TAB DIRECT COMPONENT ACCESS (convenience)
-- For cases like Tab:AddToggle without Section
-- ============================================
function Tab:AddLabel(opts)
    local section = self:_getDefaultSection()
    return section:AddLabel(opts)
end

function Tab:AddParagraph(opts)
    local section = self:_getDefaultSection()
    return section:AddParagraph(opts)
end

function Tab:AddButton(opts)
    local section = self:_getDefaultSection()
    return section:AddButton(opts)
end

function Tab:AddToggle(flagOrOpts, opts2)
    local section = self:_getDefaultSection()
    -- Support Fluent-style: Tab:AddToggle("Flag", {opts})
    if type(flagOrOpts) == "string" and type(opts2) == "table" then
        opts2.Flag = flagOrOpts
        return section:AddToggle(opts2)
    end
    return section:AddToggle(flagOrOpts)
end

function Tab:AddSlider(flagOrOpts, opts2)
    local section = self:_getDefaultSection()
    if type(flagOrOpts) == "string" and type(opts2) == "table" then
        opts2.Flag = flagOrOpts
        return section:AddSlider(opts2)
    end
    return section:AddSlider(flagOrOpts)
end

function Tab:AddDropdown(flagOrOpts, opts2)
    local section = self:_getDefaultSection()
    if type(flagOrOpts) == "string" and type(opts2) == "table" then
        opts2.Flag = flagOrOpts
        return section:AddDropdown(opts2)
    end
    return section:AddDropdown(flagOrOpts)
end

function Tab:AddTextbox(flagOrOpts, opts2)
    local section = self:_getDefaultSection()
    if type(flagOrOpts) == "string" and type(opts2) == "table" then
        opts2.Flag = flagOrOpts
        return section:AddTextbox(opts2)
    end
    return section:AddTextbox(flagOrOpts)
end

function Tab:AddKeybind(flagOrOpts, opts2)
    local section = self:_getDefaultSection()
    if type(flagOrOpts) == "string" and type(opts2) == "table" then
        opts2.Flag = flagOrOpts
        return section:AddKeybind(opts2)
    end
    return section:AddKeybind(flagOrOpts)
end

function Tab:_getDefaultSection()
    if not self._defaultSection then
        self._defaultSection = self:AddSection({ Title = "" })
        -- Hide the title for default section
        local titleFrame = self._defaultSection._frame:FindFirstChild("SectionTitle")
        if titleFrame then titleFrame.Visible = false; titleFrame.Size = UDim2.new(0, 0, 0, 0) end
    end
    return self._defaultSection
end

return Library
