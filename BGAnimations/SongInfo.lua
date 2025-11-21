-- DECLARING LOCAL VARIABLES
local FrameW = 620

-- OPERATIONS
local t = Def.ActorFrame {
	InitCommand=function(self)
		self:playcommand("Refresh")
	end,
	
	CurrentSongChangedMessageCommand=function(self)
		-- refreshes elements, obviously
		self:playcommand("Refresh")

		-- quick animation when selecting song
		self:stoptweening():diffusealpha(0):sleep(0.125):easeoutexpo(0.125):diffusealpha(1)
	end,

	RefreshCommand=function(self)
		local Song = GAMESTATE:GetCurrentSong()
		if Song then
			TitleText = Song:GetDisplayFullTitle()
			if TitleText == "" then TitleText = "Unknown" end
			self:GetChild("Title"):settext(TitleText)

			AuthorText = Song:GetDisplayArtist()
			if AuthorText == "" then AuthorText = "Unknown" end
			self:GetChild("Artist"):settext(AuthorText)

			local BPMRaw = Song:GetDisplayBpms()
			local BPMLow = math.ceil(BPMRaw[1])
			local BPMHigh = math.ceil(BPMRaw[2])
			BPMDisplay = (BPMLow == BPMHigh and BPMHigh or BPMLow .. "-" .. BPMHigh)
			if Song:IsDisplayBpmRandom() or BPMDisplay == 0 then BPMDisplay = "???" end
			self:GetChild("BPM"):settext(BPMDisplay .. " BPM")
		else
			self:GetChild("Title"):settext("")
			self:GetChild("Artist"):settext("")
			self:GetChild("BPM"):settext("")
		end
	end,


	-- drawing!
	-- static BGs
	Def.Quad { Name="CenterBG",
		InitCommand=function(self)
			self:xy(0,0):setsize(1272,50):diffuse(0,0,0,0)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(0,0,0,0.4)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(0,0,0,0)
		end,
	},
	Def.BitmapText { Name="TitleBPMSeparator",
		Font="Montserrat normal 20px",
		InitCommand=function(self)
			self:y(12)
			self:zoom(0.8)
			self:align(0.5,0.5)
			self:diffuse(Color.Black)
			self:settext("·")
			self:visible(false) -- disabling this element
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(Color.White):shadowlength(1)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(Color.Black):shadowlength(0)
		end,
	},

	-- dynamic elements
	Def.BitmapText { Name="Title",
		Font="Montserrat semibold 40px",
		InitCommand=function(self)
			self:y(-12)
			self:zoom(0.6)
			self:align(0.5,0.5)
			self:maxwidth(FrameW * 0.89 / self:GetZoom())
			self:diffuse(Color.Black)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(Color.White):shadowlength(2)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(Color.Black):shadowlength(0)
		end,
	},

	Def.BitmapText { Name="Artist",
		Font="Montserrat normal 20px",
		InitCommand=function(self)
			self:x(-14)
			self:y(12)
			self:zoom(0.8)
			self:align(1,0.5)
			self:maxwidth(FrameW * 1 / self:GetZoom())
			self:diffuse(Color.Black)
			self:visible(false) -- disabling this element
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(Color.White):shadowlength(1)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(Color.Black):shadowlength(0)
		end,
	},
	
	Def.BitmapText { Name="BPM",
		Font="Montserrat normal 20px",
		InitCommand=function(self)
			self:x(14)
			self:y(12)
			self:zoom(0.8)
			self:align(0,0.5)
			self:maxwidth(FrameW * 1 / self:GetZoom())
			self:diffuse(Color.Black)
			self:visible(false) -- disabling this element
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(Color.White):shadowlength(1)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(Color.Black):shadowlength(0)
		end,
	},

	Def.BitmapText { Name="ArtistAndBPMBlinker",
		Font="Montserrat normal 20px",
		InitCommand=function(self)
			self:x(0)
			self:y(12)
			self:zoom(0.8)
			self:align(0.5,0.5)
			self:maxwidth(FrameW * 1 / self:GetZoom())
			self:diffuse(Color.Black)
			self:queuecommand("BlinkStepOne")
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(Color.White):shadowlength(1)
			self:queuecommand("BlinkStepOne")
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(Color.Black):shadowlength(0)
			self:queuecommand("BlinkStepOne")
		end,
		CurrentSongChangedMessageCommand=function(self)
			self:stoptweening():queuecommand("BlinkStepOne")
		end,
		BlinkStepOneCommand=function(self)
			self:easeoutexpo(0.5):diffusealpha(1)
			self:settext(AuthorText)
			self:sleep(1):easeoutexpo(0.5):diffusealpha(0)
			self:queuecommand("BlinkStepTwo")
		end,
		BlinkStepTwoCommand=function(self)
			self:easeoutexpo(0.5):diffusealpha(1)
			self:settext(BPMDisplay .. " BPM")
			self:sleep(1):easeoutexpo(0.5):diffusealpha(0)
			self:queuecommand("BlinkStepOne")
		end,

	},

}

return t