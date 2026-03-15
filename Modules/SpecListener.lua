local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local AtoL             = MakuluFramework.AtoL

local UnitTokenFromGUID = UnitTokenFromGUID
local C_Timer = C_Timer
local GetNumArenaOpponentSpecs = GetNumArenaOpponentSpecs
local GetArenaOpponentSpec = GetArenaOpponentSpec
local UnitGUID = UnitGUID
local UnitIsDead = UnitIsDead
local NotifyInspect = NotifyInspect
local GetInspectSpecialization = GetInspectSpecialization

local guidCache = {}
local specStorage = {}

local arenasLoaded = false

local function onInspectReadyEvent(_,guid)
    local unit = guidCache[guid] or UnitTokenFromGUID(guid)
    if not unit then return end
    local id = GetInspectSpecialization(unit)

    specStorage[guid] = id
end

MakuluFramework.Events.register("INSPECT_READY", onInspectReadyEvent)
local debounceTimer = nil

local function updateGroupRosterInner()
    debounceTimer = nil
    guidCache = {}
    specStorage = {}
    if InCombatLockdown() then return end 
    if UnitIsDead("player") then return end -- You can't inspect while dead, so don't even try
    if InspectFrame and InspectFrame:IsShown() then return end -- Don't mess with the UI's inspections

    return MakuluFramework.MultiUnits.party:ForEach(function(unit)
        if unit.isMe then return end

        guidCache[unit.guid] = unit.id
        NotifyInspect(unit.id)
    end)
end

local function updateGroupRoster()
    if debounceTimer then return end
    debounceTimer = C_Timer.After(0.5, updateGroupRosterInner)
end

local function onEnterWorld()
    specStorage = {}
    arenasLoaded = false
    updateGroupRoster()
end

local function onArenaUpdated()
    arenasLoaded = true
    for i = 1, GetNumArenaOpponentSpecs() do
        local specID = GetArenaOpponentSpec(i)
        if specID and specID > 0 then
            local name = "arena" .. i
            local guid = UnitGUID(name)
            if guid then
                guidCache[guid] = "arena" .. i
                specStorage[guid] = specID
            end

            specStorage[name] = specID
        end
    end
end

MakuluFramework.Events.register("GROUP_ROSTER_UPDATE", updateGroupRoster)
MakuluFramework.Events.register("ARENA_PREP_OPPONENT_SPECIALIZATIONS", onArenaUpdated)
MakuluFramework.Events.register("ARENA_OPPONENT_UPDATE", onArenaUpdated)
MakuluFramework.Events.register("PLAYER_ENTERING_WORLD", onEnterWorld)

local SpecInfo = {}
local found

local function TryGetSpec(unit)
    found = specStorage[unit.guid] or specStorage[unit.id]
    if found then return found end

    if IsActiveBattlefieldArena() and not arenasLoaded then
        onArenaUpdated()
        return TryGetSpec(unit)
    end

    return nil
end

SpecInfo.TryGetSpec = TryGetSpec

local healerIds = AtoL({
    105,  -- rdru
    1468, -- pres
    270,  -- mw
    65,   -- hpala
    256,  -- disc
    257,  -- hpri
    264   -- Rsham
})

local tankIds = AtoL({
    250, --bdk
    581, --vdh lessgooo
    268, --brewmaster
    66,  --prot pala
    73,  -- prot warr
    104, -- Guardian
})

local meleeIds = AtoL({
    250, --bdk
    251, --fdk
    252, --uhdk
    577, --havoc
    581, --vdh lessgooo
    255, --survival
    268, --brewmaster
    269, --ww
    66,  --prot pala
    103,  --feral
    70,  -- ret
    259, -- assa
    260, -- outlaw
    261, --sub
    263, -- enha
    71,  -- arms
    72,  -- fury
    73,  -- prot warr
})

local casterIds = AtoL({
    102,  -- balance
    1467, -- devo
    1473, -- aug
    62,   -- Arcane
    63,   -- fire
    64,   -- frost
    258,  -- spri
    262,  -- ele
    265,  -- affli
    266,  -- demo
    267,  -- destro
})

local rangedIds = AtoL({
    102,  -- balance
    1467, -- devo
    1473, -- aug
    62,   -- Arcane
    63,   -- fire
    64,   -- frost
    258,  -- spri
    262,  -- ele
    265,  -- affli
    266,  -- demo
    267,  -- destro
    253,  -- bm
    254,  -- mm
})

local tags = {
    Tank = tankIds,
    Healer = healerIds,
    Melee = meleeIds,
    Caster = casterIds,
    Ranged = rangedIds,
}

for tag, ids in pairs(tags) do
    SpecInfo["is" .. tag] = function(spec)
        return ids[spec]
    end
end

MakuluFramework.Specs = SpecInfo