-- SAFECHECK - GENERATES A GLOBAL VARIABLE GroupsList IF IT DOESN'T EXIST ALREADY
if next(GroupsList) == nil then
    Trace("Running AssembleGroupSorting_POI from ScreenSelectProfile underlay.lua now")
    AssembleGroupSorting_POI()

    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible!")
        return Def.Actor {}
    end

end

local t = Def.ActorFrame {
    LoadActor("HudPanels")
}

return t