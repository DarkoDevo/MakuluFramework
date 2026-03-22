local Tinkr, files, auth, res = ...

if type(Tinkr) ~= "table" or type(files) ~= "table" then
    return
end

if type(Tinkr.Util) ~= "table" or type(Tinkr.Util.Evaluator) ~= "table" then
    return
end

local Evaluator = Tinkr.Util.Evaluator
auth = type(auth) == "table" and auth or {}
res = type(res) == "table" and res or {}

local MakuluFramework = {
    NAME = "Clipper"
}

for _, file in ipairs(files) do
    local code = type(file) == "string" and loadstring(file)
    if type(code) == "function" then
        Evaluator:InjectGlobals(code)
        code(Tinkr, MakuluFramework)
    end
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
    for _, file in ipairs(res.rotation_files or {}) do
        local code = type(file) == "string" and loadstring(file)
        if type(code) == "function" then
            Evaluator:InjectGlobals(code)
            code(Tinkr, MakuluFramework, spec_config)
        end
        file = ''
        code = nil
    end

    local currentSpec = MakuluFramework.getSpecId()
    if not MakuluFramework.loadSpec(currentSpec) then return end

    -- Start the looping
    MakuluFramework.loadAndStartLoop()
end
