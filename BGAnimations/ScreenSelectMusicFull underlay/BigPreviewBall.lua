local isSelectingDifficulty = false

local BigBallGroup_X = 150
local BigBallGroup_Y = 122
local MeterText_OffsetX = -1
local MeterText_OffsetY = -4
local MeterText_Zoom = 0.6

local t = Def.ActorFrame {}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	-- Larger stationary difficulty icons
	t[#t+1] = Def.ActorFrame {
		Name="BigPreviewBallContainer",

	CurrentStepsP1ChangedMessageCommand=function(self) self:playcommand("Refresh") end,
	CurrentStepsP2ChangedMessageCommand=function(self) self:playcommand("Refresh") end,
	SongChosenMessageCommand=function(self) isSelectingDifficulty = true self:playcommand("Refresh") end,
	SongUnchosenMessageCommand=function(self) isSelectingDifficulty = false self:playcommand("Refresh") end,

	RefreshCommand=function(self)
		if isSelectingDifficulty then
			local Chart = GAMESTATE:GetCurrentSteps(pn)
			local ChartMeter = Chart:GetMeter()
			if ChartMeter == 99 then
				ChartMeter = "??"
			else
				ChartMeter = string.format("%02d", ChartMeter)
			end
			self:GetChild("BigPreviewBallContainer_"..pn):GetChild("BigPreviewBall"):diffuse(FetchFromChart(Chart, "Chart Stepstype Color"))
			self:GetChild("BigPreviewBallContainer_"..pn):GetChild("MeterText"):settext(ChartMeter)
			self:GetChild("BigPreviewBallContainer_"..pn):GetChild("Difficulty"):settext(FullModeChartLabel(Chart))
		end
	end,

	Def.ActorFrame {
		Name="BigPreviewBallContainer_"..pn,
		InitCommand=function(self)
			self:zoom(4):xy(pn == PLAYER_1 and -(BigBallGroup_X) or BigBallGroup_X, BigBallGroup_Y)
		end,
		
		Def.Sprite {
			Texture=THEME:GetPathG("", "DifficultyDisplay/Ball"),
			Name="BigPreviewBall"
		},
		
		Def.Sprite {
			Texture=THEME:GetPathG("", "DifficultyDisplay/Trim"),
			Name="PreviewBallTrim"
		},
		
		Def.BitmapText {
			Font="Montserrat extrabold 20px",
			Name="Difficulty",
			InitCommand=function(self)
				self:y(-13):visible(false):zoom(0.4):maxwidth(80):shadowlength(2):skewx(-0.1)
			end
		},
		
		Def.BitmapText {
			Font="Montserrat numbers 40px",
			Name="MeterText",
			InitCommand=function(self)
				self:xy(MeterText_OffsetX, MeterText_OffsetY):zoom(MeterText_Zoom)
			end
		}
	}
}
end


return t