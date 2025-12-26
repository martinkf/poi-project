-- SAFECHECK - GENERATES A GLOBAL VARIABLE PlaylistsArray IF IT DOESN'T EXIST ALREADY
if next(PlaylistsArray) == nil then
    Trace("Running AssembleGroupSorting_POI from ScreenSelectProfile underlay.lua now")
    AssembleGroupSorting_POI()

    if next(PlaylistsArray) == nil then
        Warn("Groups list (PlaylistsArray) is currently inaccessible!")
        return Def.Actor {}
    end

end

local t = Def.ActorFrame {
    LoadActor("HudPanels")
}

return t