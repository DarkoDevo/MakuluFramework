local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramework

CacheSection = {}
CacheSection.__index = CacheSection

local rawget, rawset = rawget, rawset
local setmetatable = setmetatable
local GetTime = GetTime

local dirty = "dirty"
local dataKey = "data"
local timeout = "timeout"

local cacheStats = {
    cacheHits = 0,
    cacheMisses = 0
}

local cacheIndex = function(self, key)
    local property = rawget(self, key)
    if property ~= nil then
        return property
    end

    return CacheSection[key]
end

function CacheSection:new()
    local cacheSection = {
        dirty = false,
        data = {},
    }

    setmetatable(cacheSection, { __index = cacheIndex })
    self.__index = self

    return cacheSection
end

function CacheSection:newWeak()
    local weakData = {}
    setmetatable(weakData, { __mode = "v" })

    local cacheSection = {
        dirty = false,
        data = weakData,
    }

    setmetatable(cacheSection, self)
    self.__index = self

    return cacheSection
end

function CacheSection:Get(key)
    if rawget(self, dirty) then
        return nil
    end

    return rawget(self, dataKey)[key]
end

function CacheSection:GetOrSetTimeout(key, callback, delay)
    local now = GetTime()

    local data = rawget(self, dataKey)
    local found = data[key]
    if found ~= nil and found.expiry > now then
        cacheStats.cacheHits = cacheStats.cacheHits + 1
        return found.result
    end

    local value = callback()

    data[key] = {
        result = value,
        expiry = now + (delay / 1000)
    }
    cacheStats.cacheMisses = cacheStats.cacheMisses + 1

    return value
end

function CacheSection:GetOrSet(key, callback)
    if rawget(self, dirty) then
        local value            = callback()
        cacheStats.cacheMisses = cacheStats.cacheMisses + 1

        local newData = {
          [key] = value
        }

        rawset(self, dataKey, newData)
        rawset(self, dirty, false)
        return value
    end

    local data = rawget(self, dataKey)
    local found = data[key]
    if found ~= nil then
        cacheStats.cacheHits = cacheStats.cacheHits + 1
        return found
    end

    local value = callback()
    data[key] = value
    cacheStats.cacheMisses = cacheStats.cacheMisses + 1

    return value
end

CacheContext = {
    cacheIdx = 0,
    cache = {},

    constCacheIdx = 0,
    constCache = {},     -- These are cache items which aren't cleared between calls

    perCombatIdx = 0,    -- These again are const but we just only dirty the cache when out of combat
    perCombatCache = {}, -- These are only reset when we're out of combat

    weakCache = CacheSection:newWeak(),

    getCell = function(self)
        local toReturn = self.cache[self.cacheIdx]
        if toReturn ~= nil then
            toReturn.dirty = true
            self.cacheIdx = self.cacheIdx + 1
            return toReturn
        end

        local newCacheObject = CacheSection:new()
        self.cache[self.cacheIdx] = newCacheObject
        self.cacheIdx = self.cacheIdx + 1

        return newCacheObject
    end,

    getConstCacheCell = function(self)
        local newCacheObject = CacheSection:new()
        self.constCache[self.constCacheIdx] = newCacheObject
        self.constCacheIdx = self.constCacheIdx + 1

        return newCacheObject
    end,

    registerSelfAsConst = function(self, newCell)
        self.constCache[self.constCacheIdx] = newCell
        self.constCacheIdx = self.constCacheIdx + 1
    end,

    getCombatCacheCell = function(self)
        local newCacheObject = CacheSection:new()
        self.perCombatCache[self.perCombatIdx] = newCacheObject
        self.perCombatIdx = self.perCombatIdx + 1

        return newCacheObject
    end,

    resetCache = function(self, inCombat)
        self:dirtyAllConstCells()
        self.cacheIdx = 0
        cacheStats.cacheHits = 0
        cacheStats.cacheMisses = 0

        if not inCombat then
            self:dirtyAllCombatCells()
        end
    end,

    dirtyAllCells = function(self)
        for i = 0, self.cacheIdx - 1 do
            self.cache[i].dirty = true
        end
    end,

    dirtyAllConstCells = function(self)
        for i = 0, self.constCacheIdx - 1 do
            self.constCache[i].dirty = true
        end
    end,

    dirtyAllCombatCells = function(self)
        for i = 0, self.perCombatIdx - 1 do
            self.perCombatCache[i].dirty = true
        end
    end,

    printStats = function(self)
        print('Cache stats')
        print('Temp cells: ' .. self.cacheIdx)
        print('Const cells: ' .. self.constCacheIdx)
        print('Cache Hits : ' .. cacheStats.cacheHits)
        print('Cache Misses: ' .. cacheStats.cacheMisses)
    end
}

local LazyCells = CacheContext:getConstCacheCell()

local lazy = function(key, callback)
    return function() return LazyCells:GetOrSet(key, callback) end
end

MakuluFramework.Cache = CacheContext
MakuluFramework.Lazy = lazy