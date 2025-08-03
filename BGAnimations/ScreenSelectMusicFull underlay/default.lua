setenv("IsBasicMode", false)

-- main elements - displayed when selecting song
local t = Def.ActorFrame {
	-- song preview video (background)
	Def.ActorFrame {
		LoadActor("SongPreview")
	},

	-- the playlist information
	Def.ActorFrame {
		LoadActor("PlaylistInfo")
	},

	-- a background quad for the song wheel
	Def.Quad {
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-252)
			self:zoomto(1272, 608)
			self:align(0.5, 0)
			self:diffuse(color("0,0,0,0.4"))
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-252):zoomto(1272, 608):easeoutexpo(1):xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-286):zoomto(1272, 86)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-286):zoomto(1272, 86):easeoutexpo(0.5):xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-252):zoomto(1272, 608):diffuse(color("0,0,0,0.4"))
		end,
		StepsChosenMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1,0.6"))
		end,
		CurrentChartChangedMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0,0.4"))
		end,
		StepsUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0,0.4"))
		end,
	},

	-- the song wheel
	Def.ActorFrame {
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X-640, SCREEN_CENTER_Y-450)
		end,
		LoadActor("MusicWheel") .. { Name="MusicWheel" }
	},

	-- a group
	Def.ActorFrame {
		InitCommand=function(self) end,
		SongChosenMessageCommand=function(self) self:stoptweening():easeoutexpo(1):y(-294) end,
		SongUnchosenMessageCommand=function(self) self:stoptweening():easeoutexpo(0.5):y(0) end,

		-- song info (static ribbon that displays information about the song that's currently hovered in the song wheel)
		-- this is not used anymore apparently
		Def.ActorFrame {
			InitCommand=function(self)
				self:xy(SCREEN_CENTER_X-510, SCREEN_CENTER_Y-236)
			end,
			--LoadActor("SongInfo") -- disabling it for now
		},
		
	},
	
}

-- a group of elements that come from below when song is confirmed and we're now selecting the chart
t[#t+1] = Def.ActorFrame {
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X, 732+560)
	end,
	SongChosenMessageCommand=function(self)
		self:stoptweening():easeoutexpo(1):y(732)
	end,
	SongUnchosenMessageCommand=function(self)
		self:stoptweening():easeoutexpo(0.5):y(732+560)
	end,
	
	-- quad background: ChartDisplay
	Def.Quad {
		InitCommand=function(self)
			self:xy(0, -568)
			self:zoomto(1272, 86)
			self:align(0.5, 0)
			self:diffuse(color("0,0,0,0.4"))
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1,0.6"))
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0,0.4"))
		end,
		StepsChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(color("0,0,0,0.4"))
		end,
		StepsUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(color("1,1,1,0.6"))
		end,
		CurrentChartChangedMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(color("1,1,1,0.6"))
		end,
	},

	-- ChartDisplay (the interactive list of all current possible playable charts for the selected song)
	Def.ActorFrame {
		InitCommand=function(self)
			self:xy(0,-681)
		end,
		LoadActor("ChartDisplay", 12),
	},
	
	-- chartInfo (selected chart's details)
	LoadActor("ChartInfo"),

	-- quad background: ScoreDisplay
	Def.Quad {
		InitCommand=function(self)
			self:xy(0, SCREEN_CENTER_Y-744)
			self:zoomto(1272, 458)
			self:align(0.5, 0)
			self:diffuse(color("0,0,0,0.4"))
		end,
	},

	-- ScoreDisplay (selected chart's records)
	LoadActor("ScoreDisplay"),

	-- a line to separate the players
	Def.Quad {
		InitCommand=function(self)
			self:xy(0, SCREEN_CENTER_Y-738)
			self:zoomto(3, 447)
			self:align(0.5, 0)
			self:diffuse(color("1,1,1,0.4"))
		end,
	},
	
}
	
-- for each player present, do logic related to ReadyUI
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X + (pn == PLAYER_2 and 900 or -900), 487)
		end,
		StepsChosenMessageCommand=function(self, params)
			if params.Player == pn then
				self:stoptweening():easeoutexpo(0.25):x(SCREEN_CENTER_X + (pn == PLAYER_2 and 234 or -234))
			end
		end,
		CurrentChartChangedMessageCommand=function(self, params)
			if params.Player == pn then
				self:stoptweening():easeoutexpo(0.25):x(SCREEN_CENTER_X + (pn == PLAYER_2 and 900 or -900))
			end
		end,
		StepsUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.25):x(SCREEN_CENTER_X + (pn == PLAYER_2 and 900 or -900))
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.25):x(SCREEN_CENTER_X + (pn == PLAYER_2 and 900 or -900))
		end,

		-- background quad			
		Def.Quad {
			InitCommand=function(self)
				self:xy(0 + (pn == PLAYER_2 and 86 or -86),229)
				self:zoomto(632, 368)
				self:align(0.5,1)
				self:diffuse(color("1,1,1,0.9"))
			end,
		},
		-- READY graphic
		Def.Sprite {
			Texture=THEME:GetPathG("", "UI/Ready" .. ToEnumShortString(pn)),
			InitCommand=function(self)
				self:xy(0 + (pn == PLAYER_2 and 84 or -84),-60)
				self:zoom(3)
			end,
		},
		-- press center step graphic
		LoadActor(THEME:GetPathG("", "PressCenterStep")) .. {
			InitCommand=function(self)
				self:xy(0 + (pn == PLAYER_2 and 96 or -96),80)
			end,
		},
	}
end

return t