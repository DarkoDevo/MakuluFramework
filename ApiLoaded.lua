local Tinkr, files, auth, res = ...
local Evaluator = Tinkr.Util.Evaluator

if not files then
    print('Error with loading..')
    return
end

local MakuluFramework = {
    NAME = "Clipper"
}

for _, file in ipairs(files) do
    local code = loadstring(file)
    Evaluator:InjectGlobals(code)

    code(Tinkr, MakuluFramework)
    file = ''
    code = nil
end

files = nil

local function loadRotations()
    MakuluFramework.RotationLoader.scan()
end

local function loadSpec()
    local currentSpec = MakuluFramework.getSpecId()

    if not currentSpec then
        return
    end

    if not MakuluFramework.loadSpec(currentSpec) then return end

    -- Start the looping
    MakuluFramework.loadAndStartLoop()
end

if auth.local_loading then
    loadRotations()
    loadSpec()
else
    local spec_config = {}
    for _, file in ipairs(res.rotation_files) do
        local code = loadstring(file)
        Evaluator:InjectGlobals(code)

        code(Tinkr, MakuluFramework, spec_config)
        file = ''
        code = nil
    end

    local currentSpec = MakuluFramework.getSpecId()
    if not MakuluFramework.loadSpec(currentSpec) then return end

    -- Start the looping
    MakuluFramework.loadAndStartLoop()
end
