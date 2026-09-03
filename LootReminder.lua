local ADDON_NAME = ...
local frame = CreateFrame("Frame")

LootReminderDB = LootReminderDB or {}

local defaults = {
    bossEnabled = true,
    mythicPlusEnabled = true,
    delay = 3,
    repeatInterval = 5,
    soundEnabled = true,
    chatEnabled = true,
    screenEnabled = true,
}

local state = {
    pending = nil,
    delayTimer = nil,
    timer = nil,
    lastLootOpened = 0,
    inMythicPlus = false,
    mplusCompletionHandled = false,
}

local function InitDB()
    for k, v in pairs(defaults) do
        if LootReminderDB[k] == nil then
            LootReminderDB[k] = v
        end
    end
end

local function StopReminder()
    state.pending = nil

    if state.delayTimer then
        state.delayTimer:Cancel()
        state.delayTimer = nil
    end

    if state.timer then
        state.timer:Cancel()
        state.timer = nil
    end

    if LootReminderReminderFrame then
        LootReminderReminderFrame:Hide()
    end
end

local function ShowReminder(kind, name)
    if not state.pending then return end

    local text = kind == "mythicplus"
        and "LOOT THE MYTHIC+ CHEST!"
        or ("LOOT " .. (name or "THE BOSS") .. "!")

    if LootReminderReminderFrame then
        LootReminderReminderFrame.text:SetText("|cffffcc00" .. text .. "|r")
        LootReminderReminderFrame:Show()
    end

    if LootReminderDB.chatEnabled then
        print("|cffff9900[Loot Reminder]|r " .. text)
    end

    if LootReminderDB.soundEnabled and PlaySound then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

local function StartReminder(kind, name)
    StopReminder()

    state.pending = {
        kind = kind,
        name = name,
        started = GetTime(),
    }

    state.delayTimer = C_Timer.NewTimer(LootReminderDB.delay, function()
    state.delayTimer = nil

    if not state.pending then
        return
    end

    ShowReminder(kind, name)

    state.timer = C_Timer.NewTicker(
        LootReminderDB.repeatInterval,
        function()
        if state.pending then
            ShowReminder(kind, name)
        end
    end
    )
    end)
end

local reminderFrame

local function CreateReminderFrame()
    local f = CreateFrame("Frame", "LootReminderReminderFrame", UIParent)
    f:SetSize(500, 70)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 220)
    f:SetFrameStrata("HIGH")
    f:Hide()

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.65)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.text:SetPoint("TOP", 0, -8)
    f.text:SetJustifyH("CENTER")

    f.stopButton = CreateFrame("Button", nil, f, "BackdropTemplate")
    f.stopButton:SetSize(140, 24)
    f.stopButton:SetPoint("BOTTOM", 0, 8)
    f.stopButton:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f.stopButton:SetBackdropColor(0, 0, 0, 0)
    f.stopButton:SetBackdropBorderColor(1, 0.8, 0, 1)

    local stopButtonText = f.stopButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stopButtonText:SetPoint("CENTER")
    stopButtonText:SetText("Stop Reminders")
    stopButtonText:SetTextColor(1, 0.8, 0)
    f.stopButton:SetScript("OnClick", StopReminder)
    f.stopButton:SetScript("OnEnter", function()
        f.stopButton:SetBackdropBorderColor(1, 1, 0.4, 1)
        stopButtonText:SetTextColor(1, 1, 0.4)
    end)
    f.stopButton:SetScript("OnLeave", function()
        f.stopButton:SetBackdropBorderColor(1, 0.8, 0, 1)
        stopButtonText:SetTextColor(1, 0.8, 0)
    end)

    return f
end

local function IsMythicPlus()
    local _, instanceType, difficultyID = GetInstanceInfo()
    return instanceType == "party" and difficultyID == 8
end

local function IsRaidOrDungeon()
    local _, instanceType = GetInstanceInfo()
    return instanceType == "party" or instanceType == "raid"
end

local function HandleEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if success ~= 1 then return end
    if not LootReminderDB.bossEnabled then return end

    if IsMythicPlus() then return end

    StartReminder("boss", encounterName)
end

local function HandleMPlusCompletion()
    if not LootReminderDB.mythicPlusEnabled then return end
    if not IsMythicPlus() and not state.inMythicPlus then return end
    if state.mplusCompletionHandled then return end

    state.mplusCompletionHandled = true
    StartReminder("mythicplus", nil)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_CLOSED")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED_REWARDS")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("CHALLENGE_MODE_START")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitDB()
        CreateReminderFrame()
        print("|cff00ff00[Loot Reminder]|r loaded. Type |cffffff00/lr|r for settings.")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        state.inMythicPlus = IsMythicPlus()
        state.mplusCompletionHandled = false
        if not IsRaidOrDungeon() then
            StopReminder()
        end
        return
    end

    if event == "CHALLENGE_MODE_START" then
        state.inMythicPlus = true
        state.mplusCompletionHandled = false
        return
    end

    if event == "ENCOUNTER_END" then
        HandleEncounterEnd(...)
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED_REWARDS" then
        HandleMPlusCompletion()
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" then
        C_Timer.After(1, HandleMPlusCompletion)
        return
    end

    if event == "LOOT_OPENED" then
        state.lastLootOpened = GetTime()
        if state.pending then
            StopReminder()
        end
        return
    end

    if event == "LOOT_CLOSED" then
        return
    end
end)

SLASH_LOOTREMINDER1 = "/lr"
SlashCmdList.LOOTREMINDER = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")

    if msg == "boss" then
        LootReminderDB.bossEnabled = not LootReminderDB.bossEnabled
        print("Boss reminders: " .. (LootReminderDB.bossEnabled and "ON" or "OFF"))
    elseif msg == "mplus" or msg == "mythicplus" then
        LootReminderDB.mythicPlusEnabled = not LootReminderDB.mythicPlusEnabled
        print("Mythic+ reminders: " .. (LootReminderDB.mythicPlusEnabled and "ON" or "OFF"))
    elseif msg == "sound" then
        LootReminderDB.soundEnabled = not LootReminderDB.soundEnabled
        print("Sound: " .. (LootReminderDB.soundEnabled and "ON" or "OFF"))
    elseif msg == "chat" then
        LootReminderDB.chatEnabled = not LootReminderDB.chatEnabled
        print("Chat reminders: " .. (LootReminderDB.chatEnabled and "ON" or "OFF"))
    elseif msg == "screen" then
        LootReminderDB.screenEnabled = not LootReminderDB.screenEnabled
        print("Screen reminder: " .. (LootReminderDB.screenEnabled and "ON" or "OFF"))
    elseif msg == "test" then
        StartReminder("boss", "THE BOSS")
    elseif msg == "stop" then
        StopReminder()
    elseif msg == "reset" then
        LootReminderDB = {}
        InitDB()
        print("Loot Reminder settings reset.")
    else
        print("|cff00ff00Loot Reminder|r commands:")
        print("  /lr boss       - toggle boss reminders")
        print("  /lr mplus      - toggle Mythic+ reminders")
        print("  /lr sound      - toggle reminder sound")
        print("  /lr chat       - toggle chat message")
        print("  /lr screen     - toggle screen reminder")
        print("  /lr test       - test reminder")
        print("  /lr stop       - stop current reminder")
        print("  /lr reset      - reset settings")
    end
end

local originalShowReminder = ShowReminder
ShowReminder = function(kind, name)
    if LootReminderDB.screenEnabled then
        originalShowReminder(kind, name)
    else
        if LootReminderDB.chatEnabled then
            local text = kind == "mythicplus"
                and "LOOT THE MYTHIC+ CHEST!"
                or ("LOOT " .. (name or "THE BOSS") .. "!")
            print("|cffff9900[Loot Reminder]|r " .. text)
        end
        if LootReminderDB.soundEnabled and PlaySound then
            PlaySound(SOUNDKIT.RAID_WARNING, "Master")
        end
    end
end
