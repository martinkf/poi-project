setenv("IsBasicMode", false)

--

local t = Def.ActorFrame {}

-- the SongPreview is being played as a full-screen background at all times
t[#t+1] = Def.ActorFrame {
	LoadActor("SongPreview.lua"),
}

t[#t+1] = Def.ActorFrame {
	InitCommand=function(self)
		self:diffusealpha(1)
	end,
	OpenGroupWheelMessageCommand=function(self)
		self:stoptweening():easeoutexpo(0.5):diffusealpha(0)
	end,
	CloseGroupWheelMessageCommand=function(self, params)
		self:stoptweening():easeoutexpo(1):diffusealpha(1)
	end,

	-- MusicWheel
	Def.ActorFrame {
		InitCommand=function(self)
			self:diffusealpha(1)
			self:x(SCREEN_CENTER_X)
			self:y(445)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.25):diffusealpha(0)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():sleep(0.25):easeoutexpo(0.5):diffusealpha(1)
		end,

		Def.ActorMultiVertex{
			InitCommand=function(self)
				self:y(268)
				self:SetDrawState{Mode="DrawMode_Fan"}
				self:SetVertices((function()
					local verts = {}
					local num_points = 64
					local w, h = 750, 124 -- half of your desired zoomto dimensions
					for i=0, num_points do
						local theta = (i / num_points) * math.pi * 2
						local x = math.cos(theta) * w
						local y = math.sin(theta) * h
						table.insert(verts, {{x,y,0}, color("1,1,1,0.6")})
					end
					return verts
				end)())
			end,
			CurrentSongChangedMessageCommand=function(self)
				self:stoptweening():diffusealpha(0):sleep(0.125):easeoutexpo(0.125):diffusealpha(1)
			end,
		},

		LoadActor("MusicWheel.lua") .. { Name="MusicWheel" },
	},

	-- SongInfo (static ribbon that displays information about the song that's currently hovered in the song wheel)
	Def.ActorFrame {
		InitCommand=function(self)
			self:x(126)
			self:y(326)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):y(326-426)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):y(326)
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(0):sleep(0.125):easeoutexpo(0.125):diffusealpha(1)
		end,

		LoadActor("SongInfoNoBPM.lua")
	},

	-- ChartDisplay (the interactive list of all current possible playable charts for the selected song)
	Def.ActorFrame {
			InitCommand=function(self)
			self:x(SCREEN_CENTER_X)
			self:y(526)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):y(526-423)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):y(526)
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(0):sleep(0.125):easeoutexpo(0.125):diffusealpha(1)
		end,

		Def.Quad {
			InitCommand=function(self)
				self:y(118)
				self:zoomto(1272, 76)
				self:align(0.5, 0)
				self:diffuse(color("0,0,0,0"))
			end,
			SongChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1,0.6"))
			end,
			SongUnchosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0,0"))
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

		LoadActor("ChartDisplay.lua", 12),

	},

}

-- a group of elements that come from below when song is confirmed and we're now selecting the chart
t[#t+1] = Def.ActorFrame {
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X, 331+419)
	end,
	SongChosenMessageCommand=function(self)
		self:stoptweening():easeoutexpo(1):y(331)
	end,
	SongUnchosenMessageCommand=function(self)
		self:stoptweening():easeoutexpo(0.5):y(331+419)
	end,

	-- chartInfo (selected chart's details)
	LoadActor("ChartInfo.lua"),

	-- ScoreDisplay (selected chart's records)
	Def.ActorFrame {
		InitCommand=function(self)
			self:xy(0,33)
		end,

		LoadActor("ScoreDisplay.lua"),
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