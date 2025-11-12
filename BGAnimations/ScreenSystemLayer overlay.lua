local poidebug_display = false

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

-- POI stuff
if poidebug_display then
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self)
			self:queuecommand("UpdateAll")
		end,

		UpdateAllCommand=function(self)
			local txtCur = self:GetChild("CurPlaylistIndex")
			local txtStart = self:GetChild("StartingPoint")
			local txtSong = self:GetChild("SongIndex")
			local txtLast = self:GetChild("LastGroupMainIndex")
			local txtConf = self:GetChild("GroupMainIndexConfig")

			-- CurPlaylistIndex
			if CurPlaylistIndex then
				txtCur:settext("CurPlaylistIndex == " .. tostring(CurPlaylistIndex))
			else
				txtCur:settext("CurPlaylistIndex == (nil)")
			end

			-- MasterGroupsList[CurPlaylistIndex].StartingPoint
			if MasterGroupsList
			and CurPlaylistIndex
			and MasterGroupsList[CurPlaylistIndex]
			and MasterGroupsList[CurPlaylistIndex].StartingPoint then
				txtStart:settext("MasterGroupsList[CurPlaylistIndex].StartingPoint == " .. tostring(MasterGroupsList[CurPlaylistIndex].StartingPoint))
			else
				txtStart:settext("MasterGroupsList[CurPlaylistIndex].StartingPoint == (nil)")
			end

			-- SongIndex
			if SongIndex then
				txtSong:settext("SongIndex == " .. tostring(SongIndex))
			else
				txtSong:settext("SongIndex == (nil)")
			end

			-- LastGroupMainIndex
			if LastGroupMainIndex then
				txtLast:settext("LastGroupMainIndex == " .. tostring(LastGroupMainIndex))
			else
				txtLast:settext("LastGroupMainIndex == (nil)")
			end

			-- Config Lua Load
			local loaded = tonumber(LoadModule("Config.Load.lua")(
				"GroupMainIndex",
				CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini"
			))
			if loaded then
				txtConf:settext("Config Lua Load: GroupMainIndex == " .. loaded)
			else
				txtConf:settext("Config Lua Load: GroupMainIndex == (nil)")
			end

			-- loop de atualização
			self:sleep(1):queuecommand("UpdateAll")
		end,


		-- drawing
		Def.Quad {
			InitCommand=function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
				self:zoomto(300,160)
				self:diffuse(color("1,0,1,0.6"))
			end
		},
		
		Def.BitmapText{
			Name="CurPlaylistIndex",
			Font="Common Normal",
			InitCommand=function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-10)
				self:align(0.5,0.5)
				self:zoom(0.5)
				self:diffuse(Color.White)
				self:settext("CurPlaylistIndex == ?")
			end
		},

		Def.BitmapText {
			Name="StartingPoint",
			Font="Common Normal",
			InitCommand=function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
				self:align(0.5,0.5)
				self:zoom(0.5)
				self:diffuse(Color.White)
				self:settext("MasterGroupsList[CurPlaylistIndex].StartingPoint == ?")
			end
		},

		Def.BitmapText {
			Name="SongIndex",
			Font="Common Normal",
			InitCommand=function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y+10)
				self:align(0.5,0.5)
				self:zoom(0.5)
				self:diffuse(Color.White)
				self:settext("SongIndex == ?")
			end
		},

		Def.BitmapText {
			Name="LastGroupMainIndex",
			Font="Common Normal",
			InitCommand=function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y+30)
				self:align(0.5,0.5)
				self:zoom(0.5)
				self:diffuse(Color.White)
				self:settext("LastGroupMainIndex == ?")
			end
		},

		Def.BitmapText {
			Name="GroupMainIndexConfig",
			Font="Common Normal",
			InitCommand=function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y+40)
				self:align(0.5,0.5)
				self:zoom(0.5)
				self:diffuse(Color.White)
				self:settext("Config Lua Load: GroupMainIndex == ?")
			end
		},
	}
end

return t