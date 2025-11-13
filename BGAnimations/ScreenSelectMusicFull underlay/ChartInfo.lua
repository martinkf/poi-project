-- DECLARING SOME LEVERS AND VARIABLES
local SongIsChosen = false
local levelQuads_Y = 0
local levelQuads_X = 34
local chartDesc_X = 70
local chartDesc_Y = -1
local chartOrigin_X = chartDesc_X
local chartOrigin_Y = -19
local chartArtist_X = chartDesc_X
local chartArtist_Y = 17

-- OPERATIONS
local t = Def.ActorFrame {}
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self)
			self:y(0)
			self:queuecommand("Refresh")
		end,
		
		SongChosenMessageCommand=function(self)
			SongIsChosen = true
			self:playcommand("Refresh")
		end,

		SongUnchosenMessageCommand=function(self)
			SongIsChosen = false
		end,

		CurrentChartChangedMessageCommand=function(self)
			if SongIsChosen then
				self:playcommand("Refresh")
			end
		end,

		RefreshCommand=function(self, params)
			if GAMESTATE:GetCurrentSong() and GAMESTATE:GetCurrentSteps(pn) then
				local Chart = GAMESTATE:GetCurrentSteps(pn)
				
				self:GetChild("ChartOrigin"):settext("Originally from "..FetchFromChart(Chart,"Chart Origin"))
				self:GetChild("ChartName"):settext("Originally called · "..FetchFromChart(Chart,"Chart POI Name").." ·")
				self:GetChild("ChartAuthor"):settext("By "..FetchFromChart(Chart, "Chart Author"))
				self:GetChild("LevelBGQuad"):diffuse(FetchFromChart(Chart, "Chart Stepstype Color"))
				self:GetChild("LevelText"):settext(FetchFromChart(Chart, "Chart Level"))
			else
				--self:GetChild("ChartOrigin"):settext("")
				--self:GetChild("ChartName"):settext("")				
				--self:GetChild("ChartAuthor"):settext("")
				--self:GetChild("LevelBGQuad"):diffuse(Color.Invisible)
				--self:GetChild("LevelText"):settext("")
			end
		end,
				
		-- DRAWING

		-- background of the entire module
		Def.Quad {
			InitCommand=function(self)
				self:x(320 * (pn == PLAYER_2 and 1 or -1))
				self:y(levelQuads_Y)
				self:zoomto(632, 60)
				self:diffuse(color("1,1,1,0.6"))
			end,
			SongChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1,0.6"))
			end,
			StepsChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(1):diffuse(color("0,0,0,0.4"))
			end,
			CurrentChartChangedMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("1,1,1,0.6"))
			end,
		},

		-- these are for the square representation of the level of the chart
		Def.Quad {
			InitCommand=function(self)
				self:x(levelQuads_X * (pn == PLAYER_2 and 1 or -1))
				self:y(levelQuads_Y)
				self:zoomto(57, 57)
				self:diffuse(color("0,0,0,0.4"))
			end,
		},
		Def.Quad { Name="LevelBGQuad",
			InitCommand=function(self)
				self:x(levelQuads_X * (pn == PLAYER_2 and 1 or -1))
				self:y(levelQuads_Y)
				self:zoomto(53, 53)
				self:diffuse(FetchFromChart(GAMESTATE:GetCurrentSteps(pn), "Chart Stepstype Color"))
			end,
		},
		Def.BitmapText { Name="LevelText",
			Font="Montserrat numbers 40px",
			InitCommand=function(self)
				self:x((levelQuads_X+1) * (pn == PLAYER_2 and 1 or -1))
				self:y(levelQuads_Y)
				self:zoom(0.9)
			end,
		},
		
		-- textual information
		Def.BitmapText { Name="ChartOrigin",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:x(chartOrigin_X * (pn == PLAYER_2 and 1 or -1))
				self:y(chartOrigin_Y)
				self:zoom(0.7)
				self:halign(pn == PLAYER_2 and 0 or 1)
				self:maxwidth(540)

				self:diffuse(color("0,0,0"))
				self:shadowlength(0)
			end,
			SongChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0")):shadowlength(0)
			end,
			StepsChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1")):shadowlength(1)
			end,
			CurrentChartChangedMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0")):shadowlength(0)
			end,
		},
		Def.BitmapText { Name="ChartName",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:x(chartDesc_X * (pn == PLAYER_2 and 1 or -1))
				self:y(chartDesc_Y)
				self:zoom(0.7)				
				self:halign(pn == PLAYER_2 and 0 or 1)
				self:valign(0.5)
				self:maxwidth(540)

				self:diffuse(color("0,0,0"))
				self:shadowlength(0)
			end,
			SongChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0")):shadowlength(0)
			end,
			StepsChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1")):shadowlength(1)
			end,
			CurrentChartChangedMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0")):shadowlength(0)
			end,
		},
		Def.BitmapText { Name="ChartAuthor",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:x(chartArtist_X * (pn == PLAYER_2 and 1 or -1))
				self:y(chartArtist_Y)
				self:zoom(0.7)				
				self:halign(pn == PLAYER_2 and 0 or 1)
				self:maxwidth(540)

				self:diffuse(color("0,0,0"))
				self:shadowlength(0)
			end,
			SongChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0")):shadowlength(0)
			end,
			StepsChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1")):shadowlength(1)
			end,
			CurrentChartChangedMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0")):shadowlength(0)
			end,
		},
	}

end

return t