local Tinkr, MakuluFramework = ...

local projectSupportingSpecs = {}

local function loadFileList(root, project, files)
    for _, file in ipairs(files) do
        local file_location = root .. '/' .. file

        if not FileExists(file_location .. ".lua") then
            print("Cant find file: " .. file_location .. " skipping")
        else
            require(file_location, MakuluFramework, project)
        end
    end
end

local function loadProjectForSpec(specId)
    local foundProject = projectSupportingSpecs[specId]
    if not foundProject then
        print('No project found for spec')
        return
    end

    local storeFiles = foundProject.store.files

    if storeFiles.globals then
        loadFileList(foundProject.root, foundProject.store, storeFiles.globals)
    end

    loadFileList(foundProject.root, foundProject.store, storeFiles[specId])
end

local function parseProject(projectStore, projectRoot)
    if not projectStore.files then
        print('No project.files defined in project root for ' .. projectRoot)
        return
    end

    for key, v in pairs(projectStore.files) do
        if type(key) == "number" then
            projectSupportingSpecs[key] = {
                store = projectStore,
                root = projectRoot
            }
        end
    end
end

local function loadRotationDirectory(directory)
    local rootInfo = directory .. "/init.lua"

    if not FileExists(rootInfo) then
        print('Warning: not init.lua in ' .. rootInfo)
        return
    end

    local projectStore = {}

    rootInfo = directory .. "/init"
    require(rootInfo, MakuluFramework, projectStore)

    parseProject(projectStore, directory)
end

local rotationsDir = 'scripts/Makulu/Rotations'
local function scanForRotationDirs()
    -- print('Scanning rotations')
    local directories = ListDirectories(rotationsDir)

    for _, directory in ipairs(directories) do
        -- print('Found ' .. directory)
        loadRotationDirectory(rotationsDir .. "/" .. directory)
    end
end

local RotationLoader = {
    scan = scanForRotationDirs,
    loadDir = loadRotationDirectory,
    loadSpec = loadProjectForSpec
}

MakuluFramework.RotationLoader = RotationLoader
