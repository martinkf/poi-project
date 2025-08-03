-- levers
local y_position_when_selecting_song = SCREEN_CENTER_Y - 271-45
local y_position_when_selecting_chart = SCREEN_CENTER_Y - 430-45

-- drawing the elements
local t = Def.ActorFrame {}
t[#t+1] = Def.ActorFrame {
    InitCommand = function(self)
        self:y(y_position_when_selecting_song)
    end,

    SongChosenMessageCommand = function(self)
        self:stoptweening():easeoutexpo(1):y(y_position_when_selecting_chart)
    end,

    SongUnchosenMessageCommand = function(self)
        self:stoptweening():easeoutexpo(0.5):y(y_position_when_selecting_song)
    end,
	
	-- background quad
	Def.Quad {
		InitCommand=function(self)
			self:zoomto(1272, 30)
			self:xy(SCREEN_CENTER_X, y_position_when_selecting_song)
			self:diffuse(color("0,0,0,0.4"))
		end,

	},

	-- text
	Def.BitmapText {
		Font="Montserrat semibold 40px",			
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, y_position_when_selecting_song)
			self:zoom(0.4)
			self:shadowlength(1)
			self:settext(GroupsList[GroupIndex].SubGroups[SubGroupIndex].Name):queuecommand('Refresh')
		end,
		
		ScreenChangedMessageCommand=function(self) self:playcommand('Refresh') end,

		CurrentSongChangedMessageCommand=function(self) self:playcommand('Refresh') end,
		
		RefreshCommand=function(self)
			self:settext(GroupsList[GroupIndex].SubGroups[SubGroupIndex].Name)
		end,

	},

}

return t