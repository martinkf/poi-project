local SongInfo_SongChangedDelay = 0.5

local t = Def.ActorFrame {
	InitCommand=function(self)
		self:zoom(0.8)
	end,
	CurrentSongChangedMessageCommand=function(self) self:playcommand("Refresh") end,

	LoadActor("../ScreenEvaluation underlay/EvalSongInfo.lua") .. {
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():diffusealpha(0):sleep(SongInfo_SongChangedDelay):easeoutexpo(1):diffusealpha(1)
		end,
	}
}

return t