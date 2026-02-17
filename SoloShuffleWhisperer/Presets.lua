-- Presets.lua
-- Message presets for Solo Shuffle whispering

SSW = SSW or {}

-- =========================================
-- Message 1 (main whisper)
-- =========================================
SSW.MSG1_PRESETS = {
    "GG {name}, nice games!",
    "GG wp {name}! {praise}",
    "Thanks for the games, {name}!",
    "Hey {name}, gg! You played {role} really well!",
    "{name} - {praise}! Great games!",
    "GG {name}! Hope we queue again soon!",
    "Nice {spec}, {name}! GG!",
    "{name}, those were some fun matches! GG!",
}

-- =========================================
-- Message 2 (optional BNet)
-- =========================================
SSW.MSG2_PRESETS = {
    "Add me on BNet if you want!",
    "If you want to queue sometime, add me on BNet.",
    "Have a good one! (BNet if you want)",
    "Feel free to add my BNet: {btag}",
    "You can add me if you'd like: {btag}",
    "BNet: {btag} if you want to play more!",
}

-- =========================================
-- Random praise for {praise} placeholder
-- =========================================
SSW.PRAISE_POOL = {
    "nice plays",
    "well played",
    "great job",
    "awesome work",
    "solid performance",
    "clutch moves",
    "good teamwork",
    "impressive",
    "clean plays",
    "strong showing",
}

function SSW.RandomPraise()
    if not SSW.PRAISE_POOL or #SSW.PRAISE_POOL == 0 then return "good job" end
    local idx = math.random(1, #SSW.PRAISE_POOL)
    return SSW.PRAISE_POOL[idx] or "good job"
end
