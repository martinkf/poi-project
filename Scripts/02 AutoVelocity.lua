function AutoVelocity()
    local t = {
        Name = "AutoVelocity",
        LayoutType = "ShowAllInRow",
        SelectType = "SelectMultiple",
        GoToFirstOnStart = false,
        OneChoiceForAllPlayers = false,
        ExportOnChange = false,
        Choices = {"+20", "-20"},
        -- We'll do our own load/save functions below
        LoadSelections = function(self, list, pn) end,
        SaveSelections = function(self, list, pn) end,
        NotifyOfSelection = function(self, pn, choice)
            local AV = LoadModule("Config.Load.lua")("AutoVelocity", CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
            
            if not AV then
                AV = 260
            elseif choice == 1 then
                AV = AV + 20
            elseif choice == 2 then
                AV = AV - 20
            end
            
            -- Clamp values
            if AV < 80 then AV = 80 end
            if AV > 980 then AV = 980 end
            
            LoadModule("Config.Save.lua")("AutoVelocity", tostring(AV), CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
            return true
        end
    }
    setmetatable( t, t )
    return t
end