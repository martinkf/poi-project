-- levers
local line01_y = 10
local line02_y = 36
local line03_y = 57
local line04_y = 78

local t = Def.ActorFrame {

	Def.Quad { Name="BGQuad",
		InitCommand=function(self)
			self:zoomto(408, 91)
			self:align(0,0)
			self:diffuse(color("0,0,0,0.4"))
		end,
	},

	Def.Quad { Name="SeparatorLine",
		InitCommand=function(self)
			self:xy(4,23)
			self:zoomto(400, 2)
			self:align(0,0)
			self:diffuse(color("1,1,1,0.4"))
		end,
	},
	
	Def.ActorFrame { Name="Line-01",
		InitCommand=function(self)
			self:diffusealpha(1)
			self:y(line01_y)
			self:x(38)
		end,

		Def.Sprite {
			Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
			InitCommand=function(self)
				self:zoom(0.07)
				self:y(1)
				self:x(0)
			end,
		},
		Def.Sprite {
			Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
			InitCommand=function(self)
				self:zoom(0.07)
				self:y(1)
				self:x(20)
			end,
		},
		Def.Sprite {
			Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
			InitCommand=function(self)
				self:zoom(0.07)
				self:y(1)
				self:x(40)
			end,
		},
		Def.Sprite {
			Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
			InitCommand=function(self)
				self:zoom(0.07)
				self:y(1)
				self:x(60)
			end,
		},
		Def.Sprite {
			Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
			InitCommand=function(self)
				self:zoom(0.07)
				self:y(1)
				self:x(80)
			end,
		},
		Def.Sprite {
			Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
			InitCommand=function(self)
				self:zoom(0.07)
				self:y(1)
				self:x(100)
			end,
		},
		Def.BitmapText {
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:zoom(0.4)
				self:shadowlength(1)
				self:settext("to open the Modifiers menu")
				self:x(229)
			end,
		},

	},

	Def.ActorFrame { Name="Line-02",
		InitCommand=function(self)
			self:y(line02_y)
		end,

		Def.ActorFrame { Name="Line-02-WhenSelectingSong",
			InitCommand=function(self)
				self:diffusealpha(1)
				self:x(80)
			end,
			SongChosenMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			SongUnchosenMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			OpenGroupWheelMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			CloseGroupWheelMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(20)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(40)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(60)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(80)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(100)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("to change playlists")
					self:x(192)
				end,
			},
		},

		Def.ActorFrame { Name="Line-02-WhenSelectingChart",
			InitCommand=function(self)
				self:diffusealpha(0)
				self:x(70)
			end,
			SongChosenMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			SongUnchosenMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUL"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftUR"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(42)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("or      to go back to selecting song")
					self:x(151)
				end,
			},
		},
	},

	Def.ActorFrame { Name="Line-03",
		InitCommand=function(self)
			self:y(line03_y)
		end,

		Def.ActorFrame { Name="Line-03-WhenSelectingSong",
			InitCommand=function(self)
				self:diffusealpha(1)
				self:x(100)
			end,
			SongChosenMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			SongUnchosenMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			OpenGroupWheelMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			CloseGroupWheelMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "PressCenterStep/CenterStep"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("to confirm song selection")
					self:x(120)
				end,
			},
		},

		Def.ActorFrame { Name="Line-03-WhenSelectingChart",
			InitCommand=function(self)
				self:diffusealpha(0)
				self:x(100)
			end,
			SongChosenMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			SongUnchosenMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "PressCenterStep/CenterStep"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("to confirm chart selection")
					self:x(121)
				end,
			},
		},

		Def.ActorFrame { Name="Line-03-WhenSelectingPlaylist",
			InitCommand=function(self)
				self:diffusealpha(0)
				self:x(94)
			end,
			OpenGroupWheelMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			CloseGroupWheelMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "PressCenterStep/CenterStep"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("to confirm playlist selection")
					self:x(128)
				end,
			},
		},
	},

	Def.ActorFrame { Name="Line-04",
		InitCommand=function(self)
			self:y(line04_y)
		end,

		Def.ActorFrame { Name="Line-04-WhenSelectingSong",
			InitCommand=function(self)
				self:diffusealpha(1)
				self:x(130)
			end,
			SongChosenMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			SongUnchosenMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			OpenGroupWheelMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			CloseGroupWheelMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(42)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("or      to select song")
					self:x(92)
				end,
			},
		},

		Def.ActorFrame { Name="Line-04-WhenSelectingChart",
			InitCommand=function(self)
				self:diffusealpha(0)
				self:x(130)
			end,
			SongChosenMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			SongUnchosenMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(42)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("or      to select chart")
					self:x(93)
				end,
			},
		},

		Def.ActorFrame { Name="Line-04-WhenSelectingPlaylist",
			InitCommand=function(self)
				self:diffusealpha(0)
				self:x(130)
			end,
			OpenGroupWheelMessageCommand=function(self)
				self:diffusealpha(0):stoptweening():sleep(0.5):easeoutexpo(1):diffusealpha(1)
			end,
			CloseGroupWheelMessageCommand=function(self)
				self:diffusealpha(1):stoptweening():easeoutexpo(1):diffusealpha(0)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(0)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
				InitCommand=function(self)
					self:zoom(0.07)
					self:y(1)
					self:x(42)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("or      to select playlist")
					self:x(101)
				end,
			},
		},
	},

}

return t