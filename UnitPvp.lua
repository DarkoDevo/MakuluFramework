local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local MF                 = MakuluFramework

local Unit               = MakuluFramework.Unit
local Cache              = MakuluFramework.Cache

local function get_potential_attack_list(unit)
    if Unit.IsFriendly(unit) then
        return MF.MultiUnits.arena
    end
    return MF.MultiUnits.party
end

function Unit:AttackingInfo()
    return self.cache:GetOrSet("UnitAttackingInfo", function()
        if not Unit.Exists(self) then return end

        local attackingInfo = {
            target = nil,
            canHitTarget = true,
            cds = 0,
            melee = 0,
            caster = 0,
            ranged = 0,
            threat = 1
        }

        if Unit.IsHealer(self) then return attackingInfo end

        local attackers_target = Unit.Target(self)
        if attackers_target and Unit.Exists(attackers_target) then
            attackingInfo.target = attackers_target
        end

        if Unit.InCC(self) then
            attackingInfo.canHitTarget = false
        end

        attackingInfo.melee = Unit.IsMelee(self)
        attackingInfo.caster = Unit.IsCaster(self)
        attackingInfo.ranged = Unit.IsRanged(self)
        attackingInfo.cds = Unit.Cds(self)

        return attackingInfo
    end)
end

function Unit:AttackersV69()
    if not Unit.Exists(self) then return 0, 0, 0, 0, 0 end

    local attacker_list = get_potential_attack_list(self)

    local attackers = 0
    local casters = 0
    local melee = 0
    local ranged = 0
    local cds = 0

    attacker_list:ForEach(function(attacker)
        if not Unit.Exists(attacker) then return end
        if Unit.IsHealer(attacker) then return end

        local attackingInfo = attacker:AttackingInfo()
        if not attackingInfo.target or not Unit.Exists(attackingInfo.target) then return end
        if not Unit.IsUnit(attackingInfo.target, self) then return end

        if not attackingInfo.canHitTarget then return end

        attackers = attackers + 1
        if attackingInfo.caster then casters = casters + 1 end
        if attackingInfo.melee then melee = melee + 1 end
        if attackingInfo.ranged then ranged = ranged + 1 end
        if attackingInfo.cds then cds = cds + 1 end
    end)

    return attackers, casters, melee, ranged, cds
end
