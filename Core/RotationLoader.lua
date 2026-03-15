local Tinkr, MakuluFramework = ...

local loadedRotations = {}

local registerRotation = function(info)
    if loadedRotations[info.spec] then
        print('Warning: rotation already loaded for this spec')
        return
    end

    loadedRotations[info.spec] = info
end

local loadForSpec = function(specId)
    MakuluFramework.callback = nil

    if not loadedRotations[specId] then
        MakuluFramework.RotationLoader.loadSpec(specId)

        if not loadedRotations[specId] then
            print('Warning: no rotation found for your current spec. ID: ' .. specId)
            return nil
        end
    end

    local rotationForSpec = loadedRotations[specId]

    if not rotationForSpec.callback then
        print('Warning: rotation has no callback setup?')
        return nil
    end

    MakuluFramework.callback = rotationForSpec.callback;
    MakuluFramework.draw = rotationForSpec.draw;
    return true
end

MakuluFramework.registerRotation = registerRotation;
MakuluFramework.loadSpec = loadForSpec;
