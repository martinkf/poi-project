local t = Def.ActorFrame {

    Def.Quad {
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
            self:setsize(1280,720)
            self:diffuse(color("1,0,1"))
        end
    },

}

return t