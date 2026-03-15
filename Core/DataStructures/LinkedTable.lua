local Tinkr, MakuluFramework = ...

MakuluFramework = MakuluFramework or _G.MakuluFramwork

local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

---@class lookupData
---@field data any # Node data
---@field updated number # Last updated

---@class linkedItem
---@field next linkedItem | nil # Next item in the list
---@field prev linkedItem | nil # Previous item in the list
---@field data lookupData # The stored data

---@class lookupTable
---@field head linkedItem | nil # Head of the list
---@field tail linkedItem | nil # Tail of the list
---@field lookup table<string, linkedItem> # Lookup table for values

---@param item linkedItem | nil
local function draw_optional(item)
    if item == nil then
        return 'nil'
    end

    local expiry = item.data.updated - GetTime()
    return item.data.data.dr .. '. Expiry: ' .. expiry
end

local time = 10
local function getTime()
    time = time + 1
    return time
end

---@param data lookupData
---@param previous linkedItem | nil
---@return linkedItem
local function create_new_cell(data, previous)
    return {
        next = nil,
        prev = previous,
        data = data
    }
end

---@param lookup lookupTable
---@param data any
---@param key string
local function insert_new(lookup, key, data, expiry)
    local new_data = {
        data = data,
        updated = expiry,
        key = key
    }

    local new_linked_cell = create_new_cell(new_data, lookup.tail)

    lookup.lookup[key] = new_linked_cell
    if lookup.head == nil then
        lookup.head = new_linked_cell
    end

    if lookup.tail ~= nil then
        lookup.tail.next = new_linked_cell
    end

    lookup.tail = new_linked_cell
end

---@param lookup lookupTable
---@param min_age number
local function cleanup_old(lookup, min_age)
    local node = lookup.head
    local cleaned = 0

    while true do
        if node == nil then
            return cleaned
        end

        if node.data.updated >= min_age then
            return cleaned
        end

        cleaned = cleaned + 1

        local key = node.data.key
        lookup.lookup[key] = nil

        if node.next then
            node.next.prev = nil
        end
        lookup.head = node.next

        if not lookup.head then
            lookup.tail = nil
        end

        node = node.next
    end
end

---@param lookup lookupTable
---@param key string
local function update_item(lookup, key, data, time)
    local found_item = lookup.lookup[key]
    if found_item == nil then
        return
    end

    found_item.data.updated = getTime()

    -- Short circuit if already at the end
    if not found_item.next then
        return
    end

    if found_item.prev then
        found_item.prev.next = found_item.next
    else
        lookup.head = found_item.next
    end

    found_item.next.prev = found_item.prev

    lookup.tail.next = found_item
    found_item.prev = lookup.tail
    found_item.next = nil
    lookup.tail = found_item
end

---@param lookup lookupTable
local function draw_ll(lookup)
    print('~~~~~~~~~~~~~~~~~~~~')
    print('Head: ' .. draw_optional(lookup.head))
    print('Tail: ' .. draw_optional(lookup.tail))
    print('Lookup size: ' .. tablelength(lookup.lookup))
    print('~~~~~~~~~~~~~~~~~~~~')
    local node = lookup.head

    while true do
        if node == nil then
            break
        end

        print(' - ' .. draw_optional(node))

        node = node.next
    end

    print('~~~~~~~~~~~~~~~~~~~~')
end

---@return lookupTable
local function create_lookup()
    return {
        head = nil,
        tail = nil,
        lookup = {}
    }
end

local LinkedTable = {}

LinkedTable.create_lookup = create_lookup
LinkedTable.draw = draw_ll
LinkedTable.cleanup = cleanup_old
LinkedTable.insert = insert_new
LinkedTable._internal_create = create_new_cell

MakuluFramework.LinkedTable = LinkedTable
