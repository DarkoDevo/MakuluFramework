local Tinkr = ...

local framework_files = {
    'Framework/ExternalLibs/LibStub/LibStub',
    'Framework/ExternalLibs/DrList/DrList',
    'Framework/ExternalLibs/DrList/Spells',

    'Framework/Core/DataStructures/LinkedTable',
    'Framework/Core/DataStructures/KDTree',

    'Framework/UI',

    'Framework/Core/Commands',
    'Framework/Core/Frame',
    'Framework/Core/Events',
    'Framework/Core/DrTracker',

    'Framework/Core/ExternRotationLoader',
    'Framework/Core/RotationLoader',
    'Framework/Core/EventLoop',

    'Framework/Utils',
    'Framework/Cache',
    'Framework/Lists',
    'Framework/Unit',
    'Framework/ConstUnits',
    'Framework/Spell',
    'Framework/MultiUnits',
    'Framework/Root',

    'Framework/UnitPvp',

    'Framework/Events/UnitCdTracker',
    'Framework/Events/ChatWindow',

    'Framework/Modules/Chat',
    'Framework/Modules/MakuluFakeCast',
    'Framework/Modules/MakuluSmartPause',
    'Framework/Modules/Hekili',

    
}

local MakuluFramework = {
    loaded = false,
}

local majorVersion = nil

local function getGameVersion()
    if majorVersion then return majorVersion end

    local version = GetBuildInfo()
    local major = strsplit('.', version)

    majorVersion = major
    return major
end

local function loadFile(file)
    local name = 'scripts/Makulu/' .. file

    require(name, MakuluFramework)
end

local function checkExtensions(file, recusrive)
    local extendedName = file .. '.tinkr'
    local exists = FileExists('scripts/Makulu/' .. extendedName .. '.lua')

    if exists then
        loadFile(extendedName)
    end

    if recusrive then return end

    local version = getGameVersion()
    if version ~= "4" then return end

    extendedName = file .. '.cata'
    exists = FileExists('scripts/Makulu/' .. extendedName .. '.lua')

    if exists then
        loadFile(extendedName)
    end

    checkExtensions(extendedName, true)
end

local function loadRotations()
    MakuluFramework.RotationLoader.scan()
end

local function loadSpec()
    local currentSpec = MakuluFramework.getSpecId()

    if not currentSpec then
        print('Cant find current spec trying again in 1 second')
        C_Timer.After(1, loadSpec)
        return
    end

    if not MakuluFramework.loadSpec(currentSpec) then return end

    -- Start the looping
    MakuluFramework.loadAndStartLoop()
end

local function init()
    getGameVersion()
    for _, file in ipairs(framework_files) do
        loadFile(file)
        checkExtensions(file)
    end

    loadRotations()
    loadSpec()
end

init()
