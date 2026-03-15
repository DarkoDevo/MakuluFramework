if not MakuluFramework then
    MakuluFramework = {
        NAME = "Makulu"
    }

    MakuluFramwork = MakuluFramework
end


-- Compatibility shim to ensure _G.debugprofilestop exists (Classic/MoP)
do
    local _dps = _G.debugprofilestop
    if type(_dps) ~= "function" then
        local gtp = _G.GetTimePreciseSec
        if type(gtp) == "function" then
            _dps = function() return gtp() * 1000 end
        else
            _dps = function() return _G.GetTime() * 1000 end
        end
        _G.debugprofilestop = _dps
    end
end
