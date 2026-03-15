local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local Unit               = MakuluFramework.Unit
local Cache              = MakuluFramework.Cache

local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid           = IsInRaid

local ipairs             = ipairs
local insert             = table.insert

local PerCombatCache     = Cache:getCombatCacheCell()
local LoopCached         = Cache:getConstCacheCell()

local Group              = {}

function Group:ForEach(func, stop)
    for _, member in ipairs(self.members) do
        if func(member) and stop then return true end
    end
end

function Group:Any(func)
    for _, member in ipairs(self.members) do
        if func(member) then return true end
    end
end

function Group:Find(func)
    for _, member in ipairs(self.members) do
        if func(member) then return member end
    end
    return nil
end

function Group:Highest(func)
    local highest
    local unit
    for _, member in ipairs(self.members) do
        local res = func(member)

        if not highest or res > highest then
            highest = res
            unit = member
        end
    end
    return unit
end

function Group:Lowest(valueFunc, conditionFunc)
    local lowest
    local unit

    for _, member in ipairs(self.members) do
        if not conditionFunc or conditionFunc(member) then
            local res = valueFunc(member)

            if not lowest or res < lowest then
                lowest = res
                unit = member
            end
        end
    end

    return unit
end

function Group:Sum(func)
    local sum = 0
    for _, member in ipairs(self.members) do
        local res = func(member)

        sum = sum + res
    end
    return sum
end

function Group:Max(func)
    local max = -100000
    for _, member in ipairs(self.members) do
        local res = func(member)

        if res > max then
            max = res
        end
    end
    return max
end

function Group:Min(func)
    local min = 100000
    for _, member in ipairs(self.members) do
        local res = func(member)

        if res < min then
            min = res
        end
    end
    return min
end

function Group:Average(func)
    local sum = 0
    local count = 0
    for _, member in ipairs(self.members) do
        local res = func(member)
        if res then
            sum = sum + res
            count = count + 1
        end
    end
    if count > 0 then
        return sum / count
    else
        return 0
    end
end

function Group:Size()
    return #self.members
end

function Group:Count(func)
    local counter = 0
    for _, member in ipairs(self.members) do
        if func(member) then
            counter = counter + 1
        end
    end
    return counter
end

local function partition(arr, left, right, compareFunc)
    local pivot = arr[right]
    local i = left - 1

    for j = left, right - 1 do
        if compareFunc(arr[j], pivot) then
            i = i + 1
            arr[i], arr[j] = arr[j], arr[i]
        end
    end

    arr[i + 1], arr[right] = arr[right], arr[i + 1]
    return i + 1
end

local function quicksort(arr, left, right, compareFunc)
    if left < right then
        local partitionIndex = partition(arr, left, right, compareFunc)
        quicksort(arr, left, partitionIndex - 1, compareFunc)
        quicksort(arr, partitionIndex + 1, right, compareFunc)
    end

    return arr
end

function Group:Sort(func)
    return quicksort(self.members, 1, #self.members, func)
end

function Group:Filter(func)
    local found = {}
    for _, member in ipairs(self.members) do
        if func(member) then
            insert(found, member)
        end
    end
    return Group:FromMultiUnits(found)
end

function Group:Split(func)
    local a = {}
    local b = {}
    for _, member in ipairs(self.members) do
        if func(member) then
            insert(a, member)
        else
            insert(b, member)
        end
    end
    return Group:FromMultiUnits(a), Group:FromMultiUnits(b)
end

function Group:Clone()
    local found = {}
    for _, member in ipairs(self.members) do
        insert(found, member)
    end
    return Group:FromMultiUnits(found)
end

function Group:A6()
    return self.members[1]
end

function Group:FromMultiUnits(members)
    local group = {
        members = members
    }

    setmetatable(group, self)
    self.__index = self

    return group
end

function Group:new(tags)
    local members = {}

    for _, member in ipairs(tags) do
        insert(members, Unit:new(member))
    end

    return Group.FromMultiUnits(self, members)
end

local MultiUnits = {
    cache = Cache:getConstCacheCell()
}

local function get_party_roster()
    return PerCombatCache:GetOrSet("party", function()
        local numGroupMembers = GetNumGroupMembers()
        local prefix = nil
        if IsInRaid() then
            prefix = "raid"
        else
            prefix = "party"
            numGroupMembers = numGroupMembers - 1
        end

        local roster = {
            "player"
        }

        if not prefix or numGroupMembers <= 0 then
            if not prefix and numGroupMembers ~= 0 then
                print("Unknown group type")
            end
            return roster
        end

        for i = 1, numGroupMembers do
            local unit = prefix .. i
            table.insert(roster, unit)
        end
        return roster
    end)
end

function MultiUnits:GetParty()
    return LoopCached:GetOrSet("MUParty", function()
        return Group:new(get_party_roster())
    end)
end

function MultiUnits:GetArena()
    return LoopCached:GetOrSet("MUArena", function()
        local numOpponents = GetNumArenaOpponentSpecs()
        if not numOpponents then return {} end

        local arenas = {}
        for i = 1, numOpponents do
            local new_unit = Unit:new("arena" .. i)
            if new_unit.exists then
                insert(arenas, new_unit)
            end
        end

        return Group:FromMultiUnits(arenas)
    end)
end

function MultiUnits:_getAllEnemies()
    return LoopCached:GetOrSet("_MUEnemies", function()
        local enemiesFound = MakuluFramework.AllTheUnits.enemyUnits()
        return Group:FromMultiUnits(enemiesFound)
    end)
end

function MultiUnits:_getAllEnemyPlayers()
    return LoopCached:GetOrSet("MUEnemyPlayers", function()
        return Group:FromMultiUnits(MakuluFramework.AllTheUnits.enemyPlayers())
    end)
end

function MultiUnits:GetEnemies()
    local inPvp, inArena = MakuluFramework.InPvpInstance()
    if not inPvp then
        return MultiUnits._getAllEnemies(self)
    end

    if inArena then
        return MultiUnits.GetArena(self)
    end

    return MultiUnits._getAllEnemyPlayers(self)
end

function MultiUnits:GetEnemyPlayers()
    return MultiUnits._getAllEnemyPlayers(self)
end

function MultiUnits:GetAllEnemies()
    return MultiUnits._getAllEnemies(self)
end

function MultiUnits:GetTotems()
    return LoopCached:GetOrSet("MUTotems", function()
        return Group:FromMultiUnits(MakuluFramework.AllTheUnits.totems())
    end)
end

function MultiUnits.GetAreatriggers()
    return Group:FromMultiUnits({})
end

local MultiActions = {}

local function reIndexActions()
    MultiActions = {
        party = MultiUnits.GetParty,
        arena = MultiUnits.GetArena,
        enemies = MultiUnits.GetEnemies,
        enemyPlayers = MultiUnits.GetEnemyPlayers,
        allEnemies = MultiUnits.GetAllEnemies,
        totems = MultiUnits.GetTotems,
        areaTriggers = MultiUnits.GetAreatriggers
    }
end

reIndexActions()

local function MultiUnitsKey(multi, key)
    local found = MultiActions[key]
    if found then
        return found(multi)
    end
end

setmetatable(MultiUnits, { __index = MultiUnitsKey })

MakuluFramework.MultiUnits = MultiUnits
MakuluFramework.MultiUnits.group = Group
MakuluFramework.MultiUnits.reIndex = reIndexActions

MakuluFramework.MultiUnits._getPartyRoster = get_party_roster 