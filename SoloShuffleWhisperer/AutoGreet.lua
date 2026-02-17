-- AutoGreet.lua
-- Auto-greeting on joining group (accessibility feature)

SSW = SSW or {}
SSW.AutoGreet = SSW.AutoGreet or {}

local GREETINGS = {
    "hi",
    "yo",
    "o/",
    "hey",
    "gl",
}

local lastGreetedAt = 0
local GREET_COOLDOWN = 120 -- Don't spam greetings within 2 minutes

function SSW.AutoGreet.SendGreeting()
    if not SSW_Config or not SSW_Config.autoGreetEnabled then return end
    
    local now = SSW.Now()
    if (now - lastGreetedAt) < GREET_COOLDOWN then return end
    
    if not IsInGroup() then return end
    
    local greeting = GREETINGS[math.random(1, #GREETINGS)]
    SendChatMessage(greeting, "PARTY")
    lastGreetedAt = now
    
    SSW.Print("Auto-greeting sent: " .. greeting)
end

-- Watch for group join
local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_JOINED")
f:SetScript("OnEvent", function(self, event)
    if event == "GROUP_JOINED" then
        C_Timer.After(1.5, function()
            SSW.AutoGreet.SendGreeting()
        end)
    end
end)
