local Tinkr, MakuluFramework = ...

local Spell                  = MakuluFramework.Spell
local ConstUnits             = MakuluFramework.ConstUnits
local MultiUnits             = MakuluFramework.MultiUnits

local player                 = ConstUnits.player
local target                 = ConstUnits.target

local spellLookup            = {}

local melee                  = nil


local function isMelee()
    if melee ~= nil then return melee end
    melee = player.isMelee
    return melee
end

local function generate_spell(id)
    local info = C_Spell.GetSpellInfo(id)
    local targeted = not info or info.maxRange ~= 0 or info.minRange ~= 0

    local newSpell = Spell:new(id, { targeted })

    newSpell:Callback(function(spell, unit)
        if not targeted and isMelee() then
            if not MultiUnits.enemies:Any(function(enemy)
                    return enemy.inMelee
                end) then
                return
            end
        end

        unit = unit or target
        return spell:Cast(targeted and unit)
    end)

    spellLookup[id] = newSpell

    return newSpell
end

local function get_spell(id)
    local found = spellLookup[id]
    if found then return found end

    return generate_spell(id)
end

local function jitter_position(position)
    position.x = position.x + math.random(0, 1) - 0.5
    position.y = position.y + math.random(0, 1) - 0.5
end

local function try_others(spell)
    return MultiUnits.enemies:ForEach(function(enemy)
        if not enemy.inCombat then return end
        if spell(enemy) then
            return true
        end
    end, true)
end

local loaded = false
local recommended = nil

local SpellIsTargeting = SpellIsTargeting
local Click = Click

local function hekili(retry)
    if not loaded then
        local loading, finished = IsAddOnLoaded("Hekili")
        if loading == true and finished == true then
            loaded = true
            recommended = Hekili_GetRecommendedAbility
        else
            return
        end
    end

    for i = 1, 3, 1 do
        local id = recommended("Primary", i)
        if id ~= nil then
            local spell = get_spell(id)
            local casted, reason = spell()
            if not casted then
                if try_others(spell) then
                    return
                end
            end

            if SpellIsTargeting() then
                if target then
                    local position = target:Position()
                    jitter_position(position)
                    Click(position.x, position.y, position.z)
                    return
                end
            end
        end
    end
end

local function callback()
    if player.mounted then return end
    if not target.exists or not target.canAttack or target.dead then return end

    return hekili()
end

MakuluFramework.Hekili = hekili
MakuluFramework.HekiliCallback = callback
