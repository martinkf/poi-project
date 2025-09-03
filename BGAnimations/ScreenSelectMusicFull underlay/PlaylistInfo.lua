-- levers
local y_position_when_selecting_song = SCREEN_CENTER_Y - 288
local y_position_when_selecting_chart = SCREEN_CENTER_Y - 288-596

-- drawing the elements
local t = Def.ActorFrame {
    InitCommand = function(self)
        self:xy(SCREEN_CENTER_X, y_position_when_selecting_song)
    end,

    SongChosenMessageCommand = function(self)
        self:stoptweening():easeoutexpo(1):y(y_position_when_selecting_chart)
    end,

    SongUnchosenMessageCommand = function(self)
        self:stoptweening():easeoutexpo(0.5):y(y_position_when_selecting_song)
    end,
	
	Def.Quad { Name="InstructionsRowBgQuad",
		InitCommand=function(self)
			self:y(-52)
			self:zoomto(448, 22)
			self:align(0.5,0)
			self:diffuse(color("0,0,0,0.4"))
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):y(-52+596)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):y(-52)
		end,
	},
	Def.Quad { Name="CurPlaylistBannerBgQuad",
		InitCommand=function(self)
			self:y(-30)
			self:zoomto(186, 105)
			self:align(0.5,0)
			self:diffuse(color("0,0,0,0.4"))
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):y(-30+596)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):y(-30)
		end,
	},
	Def.Quad { Name="CurPlaylistTextBgQuad",
		InitCommand=function(self)
			self:addy(26)
			self:zoomto(1272, 22)
			self:align(0.5,0)
			self:diffuse(color("0,0,0,0.4"))
			self:diffusealpha(0) --disabling
		end,
	},


	Def.ActorFrame { Name="InstructionsRowTexts",
		InitCommand=function(self)
			self:addy(-41)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):y(-41+596)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):y(-41)
		end,

		Def.ActorFrame { Name="InstructionsRowTexts-SelectingSong",
			InitCommand=function(self)
				self:visible(true)
			end,
			SongChosenMessageCommand=function(self)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				self:visible(true)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-134):y(1)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-114):y(1)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-94):y(1)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-74):y(1)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-54):y(1)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-34):y(1)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("to change playlists")
					self:x(58)
				end,
			},
		},
		Def.ActorFrame { Name="InstructionsRowTexts-SelectingChart",
			InitCommand=function(self)
				self:visible(false)
			end,
			SongChosenMessageCommand=function(self)
				self:visible(true)
			end,
			SongUnchosenMessageCommand=function(self)
				self:visible(false)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-141):y(1)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-99):y(1)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("or      to go back to selecting song")
					self:x(10)
				end,
			},
		},
	},

	Def.BitmapText { Name="CurPlaylistText",
		Font="Montserrat semibold 40px",
		InitCommand=function(self)
			self:addy(36)
			self:zoom(0.4)
			self:shadowlength(1)
			self:settext(GroupsList[GroupIndex].Name)
			self:queuecommand('Refresh')
			self:diffusealpha(0) --disabling
		end,
		ScreenChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:playcommand('Refresh')
		end,
		CloseGroupWheelMessageCommand=function(self, params)
			if params.Silent == false then
				self:playcommand('Refresh')
			end
		end,
		RefreshCommand=function(self)
			self:settext(GroupsList[GroupIndex].Name)
			--self:settext("QEQEQE to change playlists")
		end
	},

	Def.Banner { Name="CurPlaylistBanner",
		InitCommand=function(self)
			self:y(22)
			self:zoom(0.09)
			self:Load(GroupsList[GroupIndex].Banner)
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
		CloseGroupWheelMessageCommand=function(self, params)
			if params.Silent == false then
				self:playcommand('Refresh')
			end
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):y(22+596):diffusealpha(0)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):y(22):diffusealpha(1)
		end,
		RefreshCommand=function(self)			
			self:Load(GroupsList[GroupIndex].Banner)
		end,
	},

	

}

return t