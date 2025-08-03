return Def.ActorFrame {

    LoadActor("LoadingIcon")..{
        InitCommand=function(self)
            self:GetChild("Text"):settext("SAVE PROFILE DATA...")
        end
    },

    Def.Actor {
        BeginCommand=function(self)
            if SCREENMAN:GetTopScreen():HaveProfileToSave() then self:sleep(1) end
            self:queuecommand("Load")
        end,
        LoadCommand=function() SCREENMAN:GetTopScreen():Continue() end
    }
}
