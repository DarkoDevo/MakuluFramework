local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellTexture = C_Spell.GetSpellTexture

local function spellIdPrint(spellId, size)
    local icon = GetSpellTexture(spellId)
    size = size or 0

    return "|T" .. icon .. ":" .. size .. "|t"
end

local function specIdPrint(specId, size)
    local _, _, _, icon = GetSpecializationInfoByID(specId)
    size = size or 0

    return "|T" .. icon .. ":" .. size .. "|t"
end

local colors = {
    red = "|cFFFF0000",
    green = "|cFF00FF00",
    blue = "|cFF0000FF",
    yellow = "|cFFFFFF00",
    cyan = "|cFF00FFFF",
    magenta = "|cFFFF00FF",
    orange = "|cFFFF8000",
    purple = "|cFF800080",
    white = "|cFFFFFFFF",
    black = "|cFF000000",
    gray = "|cFF808080",
    lightgray = "|cFFC0C0C0",
    darkred = "|cFF8B0000",
    darkgreen = "|cFF006400",
    darkblue = "|cFF00008B",
    gold = "|cFFFFD700",
    silver = "|cFFC0C0C0",
    copper = "|cFFB87333",
    pink = "|cFFFFC0CB",
    brown = "|cFFA52A2A",
    teal = "|cFF008080",
    class = {
        warrior = "|cFFC79C6E",
        paladin = "|cFFF58CBA",
        hunter = "|cFFABD473",
        rogue = "|cFFFFF569",
        priest = "|cFFFFFFFF",
        dk = "|cFFC41F3B",
        shaman = "|cFF0070DE",
        mage = "|cFF69CCF0",
        warlock = "|cFF9482C9",
        monk = "|cFF00FF96",
        druid = "|cFFFF7D0A",
        dh = "|cFFA330C9",
        evoker = "|cFF33937F"
    }
}

-- Function to reset color to default
colors.reset = "|r"

MakuluFramework.Chat = {
    SpellDraw = spellIdPrint,
    SpecDraw = specIdPrint,
    colour = colors
}
