local t = Def.ActorFrame {
	InitCommand=function(self)
		if LoadModule("Config.Load.lua")("AutogenBasicMode", "Save/OutFoxPrefs.ini") == true then
			AssembleBasicMode()
		else
			Trace("No Basic Mode song list needed!")
		end
		
		AssembleGroupSorting_POI()
	end,	
}

-- SCREENMAN:SystemMessage display
t[#t+1] = Def.ActorFrame {
	Def.Quad {
		InitCommand=function (self)
			self:zoomtowidth(SCREEN_WIDTH):zoomtoheight(30):horizalign(left):vertalign(top):y(SCREEN_TOP):diffuse(color("0,0,0,0"))
		end,
		OnCommand=function (self)
			self:finishtweening():diffusealpha(0.85)
		end,
		OffCommand=function (self)
			self:sleep(3):linear(0.5):diffusealpha(0)
		end
	},
	
	Def.BitmapText{
		Font="Common Normal",
		Name="Text",
		InitCommand=function (self)
			self:maxwidth(750):horizalign(left):vertalign(top):y(SCREEN_TOP+10):x(SCREEN_LEFT+10):shadowlength(1):diffusealpha(0)
		end,
		OnCommand=function (self)
			self:finishtweening():diffusealpha(1):zoom(0.5)
		end,
		OffCommand=function (self)
			self:sleep(3):linear(0.5):diffusealpha(0)
		end
	},
	
	SystemMessageMessageCommand = function(self, params)
		self:GetChild("Text"):settext(params.Message)
		self:playcommand("On")
		if params.NoAnimate then
			self:finishtweening()
		end
		self:playcommand("Off")
	end,
	
	HideSystemMessageMessageCommand = function (self)
		self:finishtweening()
	end
}

return t