local Tinkr, MakuluFramework = ...

local spec = nil

MakuluFramework.getSpec = function()
    if spec then return spec end

    spec = GetPrimaryTalentTree()
    return spec
end

MakuluFramework.getSpecId = function()
    local _, _, class = UnitClass("player")
    local res, name = GetTalentTabInfo(MakuluFramework.getSpec())

    return res
end
