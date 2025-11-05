-- levers
local SongIsChosen = false
local levelQuads_Y = 0
local levelQuads_X = 34
local chartDesc_X = 70
local chartDesc_Y = -1
local chartOrigin_X = chartDesc_X
local chartOrigin_Y = -19
local chartArtist_X = chartDesc_X
local chartArtist_Y = 17

--

local t = Def.ActorFrame {}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self) self:y(0):queuecommand("Refresh") end,
		
		SongChosenMessageCommand=function(self) SongIsChosen = true self:playcommand("Refresh") end,
		SongUnchosenMessageCommand=function(self) SongIsChosen = false end,
		CurrentChartChangedMessageCommand=function(self) if SongIsChosen then self:playcommand("Refresh") end end,

		RefreshCommand=function(self, params)
			if GAMESTATE:GetCurrentSong() and GAMESTATE:GetCurrentSteps(pn) then
				local Chart = GAMESTATE:GetCurrentSteps(pn)
				
				self:GetChild("ChartOrigin"):settext("Originally from "..FetchFromChart(Chart,"Chart Origin"))
				self:GetChild("ChartName"):settext("Originally called · "..FetchFromChart(Chart,"Chart POI Name").." ·")
				--self:GetChild("ChartName"):diffuse(FetchFromChart(Chart, "Chart Stepstype Color"))
				self:GetChild("ChartAuthor"):settext("By "..FetchFromChart(Chart, "Chart Author"))
				
				self:GetChild("LevelBGQuad"):diffuse(FetchFromChart(Chart, "Chart Stepstype Color"))
				self:GetChild("LevelText"):settext(FetchFromChart(Chart, "Chart Level"))
			else
				-- I don't really think this case is ever gonna get displayed on screen so commenting it out
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
				self:diffuse(color("0,0,0,0.4"))
			end,
			SongChosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(1):diffuse(color("1,1,1,0.6"))
			end,
			SongUnchosenMessageCommand=function(self)
				self:stoptweening():easeoutexpo(0.5):diffuse(color("0,0,0,0.4"))
			end,
		},

		-- this quad represents the background of the big "Level Number" indicator for the chart
		Def.Quad {
			InitCommand=function(self)
				self:x(levelQuads_X * (pn == PLAYER_2 and 1 or -1))
				self:y(levelQuads_Y)
				self:zoomto(57, 57)
				self:diffuse(color("0,0,0,0.4"))
			end,
		},
		Def.Quad {
			Name="LevelBGQuad",
			InitCommand=function(self)
				self:x(levelQuads_X * (pn == PLAYER_2 and 1 or -1))
				self:y(levelQuads_Y)
				self:zoomto(53, 53)
				self:diffuse(FetchFromChart(GAMESTATE:GetCurrentSteps(pn), "Chart Stepstype Color"))
			end,
		},

		Def.BitmapText {
			Name="LevelText",
			Font="Montserrat numbers 40px",
			InitCommand=function(self)
				self:x((levelQuads_X+1) * (pn == PLAYER_2 and 1 or -1))
				self:y(levelQuads_Y)
				self:zoom(0.9)
			end,
		},
				
		Def.BitmapText {
			Font="Montserrat normal 20px",
			Name="ChartOrigin",
			InitCommand=function(self)
				self:x(chartOrigin_X * (pn == PLAYER_2 and 1 or -1))
				self:y(chartOrigin_Y)
				self:zoom(0.7)
				self:diffuse(color("0,0,0"))
				self:halign(pn == PLAYER_2 and 0 or 1)
				self:maxwidth(540)
			end
		},

		Def.BitmapText {
			Font="Montserrat normal 20px",
			Name="ChartName",
			InitCommand=function(self)
				self:x(chartDesc_X * (pn == PLAYER_2 and 1 or -1))
				self:y(chartDesc_Y)
				self:zoom(0.7)
				self:diffuse(color("0,0,0"))
				self:halign(pn == PLAYER_2 and 0 or 1)
				self:valign(0.5)
				self:maxwidth(540)
			end
		},
		
		Def.BitmapText {
			Font="Montserrat normal 20px",
			Name="ChartAuthor",
			InitCommand=function(self)
				self:x(chartArtist_X * (pn == PLAYER_2 and 1 or -1))
				self:y(chartArtist_Y)
				self:zoom(0.7)
				self:diffuse(color("0,0,0"))
				self:halign(pn == PLAYER_2 and 0 or 1)
				self:maxwidth(540)
			end
		}
	}
end


return t