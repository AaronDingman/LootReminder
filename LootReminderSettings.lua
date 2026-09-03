LootReminderSettings = LootReminderSettings or {}

local function UpdatePositionFields(panel)
    if not panel or not panel.xBox or not panel.yBox then return end

    panel.xBox:SetText(string.format("%.0f", LootReminderDB.positionX))
    panel.yBox:SetText(string.format("%.0f", LootReminderDB.positionY))
end

local function SetDefaultFramePosition()
    if not LootReminderReminderFrame then return end

    LootReminderReminderFrame:ClearAllPoints()
    LootReminderReminderFrame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        LootReminderDB.positionX,
        LootReminderDB.positionY
    )
end

local function CreateSettingsButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    return button
end

local function CreatePositionBox(parent, labelText, yOffset)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 16, yOffset)
    label:SetText(labelText)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(90, 24)
    box:SetPoint("TOPLEFT", 90, yOffset + 4)
    box:SetAutoFocus(false)
    box:SetJustifyH("CENTER")
    return box
end

local function ApplyTypedPosition(panel)
    local positionX = tonumber(panel.xBox:GetText())
    local positionY = tonumber(panel.yBox:GetText())
    if not positionX or not positionY then
        print("|cffff0000[Loot Reminder]|r Enter valid numbers for both X and Y.")
        UpdatePositionFields(panel)
        return
    end

    LootReminderDB.positionX = positionX
    LootReminderDB.positionY = positionY
    SetDefaultFramePosition()
    UpdatePositionFields(panel)
end

local function CreateSettingsFrame()
    local panel = CreateFrame("Frame", "LootReminderSettingsFrame", UIParent, "BackdropTemplate")
    panel:SetSize(340, 240)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
        tileSize = 32,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    panel:Hide()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Loot Reminder Settings")

    local instructions = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -12)
    instructions:SetText("Enter the reminder frame coordinates.")

    panel.xBox = CreatePositionBox(panel, "X Position", -72)
    panel.yBox = CreatePositionBox(panel, "Y Position", -104)
    UpdatePositionFields(panel)

    local applyButton = CreateSettingsButton(panel, "Apply Coordinates", 140, 24)
    applyButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -24, -132)
    applyButton:SetScript("OnClick", function()
        ApplyTypedPosition(panel)
    end)
    panel.xBox:SetScript("OnEnterPressed", function()
        ApplyTypedPosition(panel)
    end)
    panel.yBox:SetScript("OnEnterPressed", function()
        ApplyTypedPosition(panel)
    end)

    local testButton = CreateSettingsButton(panel, "Test Notification", 140, 24)
    testButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -132)
    testButton:SetScript("OnClick", function()
        LootReminder.TestReminder()
    end)

    local resetButton = CreateSettingsButton(panel, "Reset Position", 120, 24)
    resetButton:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", 0, -12)
    resetButton:SetScript("OnClick", function()
        LootReminderDB.positionX = 0
        LootReminderDB.positionY = 220
        SetDefaultFramePosition()
        UpdatePositionFields(panel)
    end)

    local closeButton = CreateSettingsButton(panel, "Close", 120, 24)
    closeButton:SetPoint("TOPLEFT", applyButton, "BOTTOMLEFT", 0, -12)
    closeButton:SetScript("OnClick", function()
        panel:Hide()
    end)
end

function LootReminderSettings.Toggle()
    if not LootReminderSettingsFrame then return end

    if LootReminderSettingsFrame:IsShown() then
        LootReminderSettingsFrame:Hide()
    else
        UpdatePositionFields(LootReminderSettingsFrame)
        LootReminderSettingsFrame:Show()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    CreateSettingsFrame()
end)
