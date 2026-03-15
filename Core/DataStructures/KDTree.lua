local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

KDNode                   = {}
KDNode.__index           = KDNode

function KDNode:new(point, left, right)
    local node = {
        point = point,
        left = left or nil,
        right = right or nil
    }
    setmetatable(node, KDNode)
    return node
end

local unpack = unpack

local function indicesTables(len)
    local a = {}
    local b = {}
    for i = 1, len do
        table.insert(a, i)
        table.insert(b, i)
    end
    return a, b
end

local function build_kd_tree(points, start, stop, depth, pre_sort)
    if not start then
        start = 1
        stop = #points

        local a_list, b_list = indicesTables(stop)

        table.sort(a_list, function(a, b) return points[a][1] < points[b][1] end)
        table.sort(b_list, function(a, b) return points[a][2] < points[b][2] end)
        pre_sort = {
            a_list,
            b_list
        }
    end

    local size = (stop - start) + 1
    depth = depth or 0

    if size < 1 or depth > 20 then
        return nil
    end

    local axis = (depth % 2) + 1
    local median = start + math.floor(size / 2)
    local indices = pre_sort[axis]

    return KDNode:new(
        points[indices[median]],
        build_kd_tree(points, start, median - 1, depth + 1, pre_sort),
        build_kd_tree(points, median + 1, stop, depth + 1, pre_sort)
    )
end

local FastDistance2D = FastDistance2D

local function range_search(node, query_point, range_dist, depth, points_in_range, axis)
    if not node then
        return points_in_range
    end

    depth = depth or 0
    points_in_range = points_in_range or {}
    axis = axis or 1

    -- Calculate the Euclidean distance between the node point and the query point
    local distance = FastDistance2D(node.point[1], node.point[2], query_point[1], query_point[2])

    if distance <= range_dist then
        points_in_range[#points_in_range + 1] = node.point
    end

    local new_axis = (axis == 1 and 2) or 1

    if query_point[axis] - range_dist <= node.point[axis] then
        points_in_range = range_search(node.left, query_point, range_dist, depth + 1, points_in_range, new_axis)
    end

    if query_point[axis] + range_dist >= node.point[axis] then
        points_in_range = range_search(node.right, query_point, range_dist, depth + 1, points_in_range, new_axis)
    end

    return points_in_range
end

local KDTree = {}

KDTree.build = build_kd_tree
KDTree.search = range_search

MakuluFramework.KDTree = KDTree

-- local function generate_random_points(num_points, x_max, y_max)
--     local points = {}
--     for i = 1, num_points do
--         local x = math.random() * x_max
--         local y = math.random() * y_max
--         table.insert(points, { x, y })
--     end
--     return points
-- end

-- -- Define points
-- points = {
--     { 2, 3 }, { 5, 4 }, { 9, 6 }, { 4, 7 }, { 8, 1 }, { 5, 6 }, { 7, 2 }
-- }

-- points = generate_random_points(300, 10, 10)

-- -- Create an index array
-- indices = {}
-- for i = 1, #points do
--     indices[i] = i
-- end

-- -- Build KD Tree
-- kd_tree = build_kd_tree(points, indices)

-- -- Define query point and range
-- query_point = { 5, 5 }
-- range_dist = 4.5

-- print('Starting search')
-- -- Perform range search
-- result = range_search(kd_tree, query_point, range_dist)

-- print('Found ' .. #result .. ' items within range. Out of ' .. #points)
-- local time  = _G.debugprofilestop

-- local start = time()
-- for i = 1, 5 do
--     local result = range_search(kd_tree, query_point, range_dist)
-- end

-- local timeTaken = time() - start

-- print('Done search loop. Took: ' .. timeTaken)

-- Print results
-- for _, point in ipairs(result) do
--     local dx = point[1] - query_point[1]
--     local dy = point[2] - query_point[2]
--     local dist = math.sqrt(dx * dx + dy * dy)
--     print("(" .. point[1] .. ", " .. point[2] .. ") abs distance of: " .. dist)
-- end

-- print('-------------')
-- print('Full list')
-- print('-------------')
-- for _, point in ipairs(points) do
--     local dx = point[1] - query_point[1]
--     local dy = point[2] - query_point[2]
--     local dist = math.sqrt(dx * dx + dy * dy)
--     print("(" .. point[1] .. ", " .. point[2] .. ") abs distance of: " .. dist)
-- end
