local FrameW2 = 1600
local FrameH2 = 900
local PreviewDelay = THEME:GetMetric("ScreenSelectMusic", "SampleMusicDelay")
local VHSText_Y = -100
local VHSText_visible = false -- use this lever to enable or disable the VHS text

local t = Def.ActorFrame {
	OnCommand=function(self)
		self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y-100):zoom(0.8)		
	end,
	
	-- noise fx when switching song
	Def.ActorFrame {
		Name="Noise",

		Def.Sprite {
			Texture=THEME:GetPathG("", "Noise"),
			InitCommand=function(self)
				self:zoomto(FrameW2, FrameH2):y(125)
				:texcoordvelocity(24,16)
			end
		},

		Def.ActorFrame {
			InitCommand=function(self)
				self:visible(VHSText_visible)
			end,

			Def.BitmapText {
				Name="NextPrevText",
				Font="VCR OSD Mono 40px",
				Text="",
				InitCommand=function(self)
					self:zoom(2):xy(0,VHSText_Y)
					:shadowlength(4)					
				end,
				ScrollMessageCommand=function(self, params)
					local direction = params.Direction
					if direction == -1 then
						self:stoptweening()
						:settext("PREV")
						:zoom(2.3)
						:easeoutquad(0.2)
						:zoom(2)
					elseif direction == 1 then
						self:stoptweening()
						:settext("NEXT")
						:zoom(2.3)
						:easeoutquad(0.2)
						:zoom(2)
					end					
				end,
			},
		},
	},

	-- fullscreen bga_P
	Def.Sprite {
		InitCommand=function(self) self:Load(nil):queuecommand("Refresh") end,
		CurrentSongChangedMessageCommand=function(self) self:Load(nil):queuecommand("Refresh") end,

		RefreshCommand=function(self)
			self:stoptweening():diffusealpha(0):sleep(PreviewDelay)
			Song = GAMESTATE:GetCurrentSong()
			if Song then
				if GAMESTATE:GetCurrentSong():GetPreviewVidPath() == nil or LoadModule("Config.Load.lua")("ImagePreviewOnly", "Save/OutFoxPrefs.ini") then
					self:queuecommand("LoadBG")
				else
					self:queuecommand("LoadAnimated")
				end
			end
		end,

		LoadBGCommand=function(self)
			local Path = Song:GetBackgroundPath()
			if Path and FILEMAN:DoesFileExist(Path) then
				self:LoadFromCached("Background", Path):zoomto(FrameW2, FrameH2):y(125)
				:linear(PreviewDelay):diffusealpha(1):diffuse(color("#ffffff"))
			else
				self:LoadFromCached("Banner", Song:GetBannerPath()):zoomto(FrameW2, FrameH2):y(125)
				:linear(PreviewDelay):diffusealpha(1):diffuse(color("#ffffff"))
			end
		end,

		LoadAnimatedCommand=function(self)
			local Path = Song:GetPreviewVidPath()
			if Path and FILEMAN:DoesFileExist(Path) then
				self:Load(Path):zoomto(FrameW2, FrameH2):y(125)
				:linear(PreviewDelay):diffusealpha(1):diffuse(color("#ffffff"))
			else
				self:queuecommand("LoadBG")
			end
		end,
	},
	
}


return t