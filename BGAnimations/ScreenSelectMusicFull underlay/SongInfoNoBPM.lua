local t = Def.ActorFrame {
	InitCommand=function(self)
		self:zoom(0.8)
	end,
	CurrentSongChangedMessageCommand=function(self) self:playcommand("Refresh") end,

	LoadActor("../ScreenEvaluation underlay/EvalSongInfoNoBPM.lua") .. {
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
		end,
	},
}

return t