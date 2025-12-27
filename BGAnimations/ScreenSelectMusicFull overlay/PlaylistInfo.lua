--levers
local CurPlaylistBannerBgQuad_y = -52

local t = Def.ActorFrame {
    InitCommand = function(self)
        self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y - 288)
    end,

	Def.Quad { Name="CurSublistBgQuad",
		InitCommand=function(self)
			self:y(110-6+6-15)
			self:zoomto(1272, 21)
			self:align(0.5,0)
			self:diffuse(color("0,0,0,0.4"))
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffusealpha(0)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(0.4)
		end,
		ScreenChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		OpenGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(1):diffusealpha(0)
		end,
		CloseGroupWheelMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(0.4)
		end,
	},

	Def.BitmapText { Name="CurSublistText",
		Font="Montserrat semibold 40px",
		InitCommand=function(self)
			self:y(110-6)
			self:zoom(0.4)
			self:shadowlength(1)
			self:settext(PlaylistsArray[LastPlaylistIndex].Sublists[LastSublistIndex].SublistName)
			self:queuecommand('Refresh')
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffusealpha(0)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(1)
		end,
		ScreenChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		OpenGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(1):diffusealpha(0)
		end,
		CloseGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(1)
			if params.Silent == false then
				self:playcommand('Refresh')
			end
		end,
		PrevSublistMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		NextSublistMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		RefreshCommand=function(self)
			self:settext(PlaylistsArray[LastPlaylistIndex].Sublists[LastSublistIndex].SublistName)
		end
	},

	Def.Quad { Name="CurPlaylistBannerBgQuad",
		InitCommand=function(self)
			self:y(CurPlaylistBannerBgQuad_y)
			self:zoomto(448, 143)
			self:align(0.5,0)
			self:diffuse(color("0,0,0,0.4"))
		end,
		OpenGroupWheelMessageCommand=function(self)
			self:zoomto(448, 146)
		end,
		CloseGroupWheelMessageCommand=function(self)
			self:zoomto(448, 143)
		end,
	},

	Def.Banner { Name="CurPlaylistBanner",
		InitCommand=function(self)
			self:y(CurPlaylistBannerBgQuad_y + 72)
			self:Load(PlaylistsArray[LastPlaylistIndex].Banner)

			local texWidth, texHeight = 1920, 1080 -- your banner’s actual resolution
			local desiredWidth, desiredHeight = 443, 138

			-- scale proportionally so the banner fills the width
			local zoom = desiredWidth / texWidth
			self:zoom(zoom)

			-- compute how much vertical portion we need for 72px after scaling
			local visiblePortion = (desiredHeight / texHeight) / zoom
			local cropMargin = (1 - visiblePortion) / 2

			-- crop evenly from top and bottom (keep the center)
			self:croptop(cropMargin)
			self:cropbottom(cropMargin)
			
			self:queuecommand('Refresh')
		end,
		OnCommand=function(self)
			self:playcommand("Refresh")
		end,
		ScreenChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		OpenGroupWheelMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(0)
		end,
		CloseGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(1):diffusealpha(1)

			if params.Silent == false then
				self:playcommand('Refresh')
			end
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffusealpha(0)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(1)
		end,
		RefreshCommand=function(self)
			self:Load(PlaylistsArray[LastPlaylistIndex].Banner)
		end,
	},

	Def.Banner { Name="CurSelectedSongBanner",
		InitCommand=function(self)
			self:playcommand("Refresh")
		end,
		OnCommand=function(self)
			self:playcommand("Refresh")
		end,
		ScreenChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		OpenGroupWheelMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(0)
		end,
		CloseGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(1):diffusealpha(1)

			if params.Silent == false then
				self:playcommand('Refresh')
			end
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffusealpha(1)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(0)
		end,
		RefreshCommand=function(self)
			self:diffusealpha(0)
			self:y(CurPlaylistBannerBgQuad_y + 72)
			self:Load(GAMESTATE:GetCurrentSong():GetBannerPath())

			local texWidth, texHeight = 640, 480 -- your banner’s actual resolution
			local desiredWidth, desiredHeight = 443, 138

			-- scale proportionally so the banner fills the width
			local zoom = desiredWidth / texWidth
			self:zoom(zoom)

			-- compute how much vertical portion we need for 72px after scaling
			local visiblePortion = (desiredHeight / texHeight) / zoom
			local cropMargin = (1 - visiblePortion) / 2

			-- crop evenly from top and bottom (keep the center)
			self:croptop(cropMargin)
			self:cropbottom(cropMargin)
		end,
	},

}

return t