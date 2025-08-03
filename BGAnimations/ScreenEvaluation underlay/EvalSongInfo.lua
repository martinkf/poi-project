local FrameW = 620
local FrameH = 76

local t = Def.ActorFrame {
	InitCommand=function(self)
		local Song = GAMESTATE:GetCurrentSong()
		if Song then
			local TitleText = Song:GetDisplayFullTitle()
			if TitleText == "" then TitleText = "Unknown" end

			local AuthorText = Song:GetDisplayArtist()
			if AuthorText == "" then AuthorText = "Unknown" end

			local BPMRaw = Song:GetDisplayBpms()
			local BPMLow = math.ceil(BPMRaw[1])
			local BPMHigh = math.ceil(BPMRaw[2])
			local BPMDisplay = (BPMLow == BPMHigh and BPMHigh or BPMLow .. "-" .. BPMHigh)
			if Song:IsDisplayBpmRandom() or BPMDisplay == 0 then BPMDisplay = "???" end
							
			local FirstTag = ""
			FirstTag = FetchFromSong(Song, "First Tag")
			local HeartsCost = ""
			if FirstTag == "SHORTCUT" then HeartsCost = 1 
			elseif FirstTag == "ARCADE" then HeartsCost = 2 
			elseif FirstTag == "REMIX" then HeartsCost = 3 
			elseif FirstTag == "FULLSONG" then HeartsCost = 4  
			end
			HeartsCost = "x " .. HeartsCost
			
			self:GetChild("Title"):settext(TitleText)
			self:GetChild("Artist"):settext(AuthorText)
			self:GetChild("Length"):settext(HeartsCost)
			self:GetChild("BPM"):settext(BPMDisplay .. " BPM")
		else
			self:GetChild("Title"):settext("")
			self:GetChild("Artist"):settext("")
			self:GetChild("Length"):settext("")
			self:GetChild("BPM"):settext("")
		end
	end,
	
	RefreshCommand=function(self)
		local Song = GAMESTATE:GetCurrentSong()
		if Song then
			local TitleText = Song:GetDisplayFullTitle()
			if TitleText == "" then TitleText = "Unknown" end

			local AuthorText = Song:GetDisplayArtist()
			if AuthorText == "" then AuthorText = "Unknown" end

			local BPMRaw = Song:GetDisplayBpms()
			local BPMLow = math.ceil(BPMRaw[1])
			local BPMHigh = math.ceil(BPMRaw[2])
			local BPMDisplay = (BPMLow == BPMHigh and BPMHigh or BPMLow .. "-" .. BPMHigh)
			if Song:IsDisplayBpmRandom() or BPMDisplay == 0 then BPMDisplay = "???" end
							
			local FirstTag = ""
			FirstTag = FetchFromSong(Song, "First Tag")
			local HeartsCost = ""
			if FirstTag == "SHORTCUT" then HeartsCost = 1 
			elseif FirstTag == "ARCADE" then HeartsCost = 2 
			elseif FirstTag == "REMIX" then HeartsCost = 3 
			elseif FirstTag == "FULLSONG" then HeartsCost = 4  
			end
			HeartsCost = "x " .. HeartsCost

			self:GetChild("Title"):settext(TitleText)
			self:GetChild("Artist"):settext(AuthorText)
			self:GetChild("Length"):settext(HeartsCost)
			self:GetChild("BPM"):settext(BPMDisplay .. " BPM")
		else
			self:GetChild("Title"):settext("")
			self:GetChild("Artist"):settext("")
			self:GetChild("Length"):settext("")
			self:GetChild("BPM"):settext("")
		end
	end,

	Def.Quad {
		InitCommand=function(self)
			self:xy(0,0)
			:setsize(410,84):diffuse(1,1,1,0.8)
		end
	},
	Def.Quad { --left diffusor
		InitCommand=function(self)
			self:xy(-280,0)
			:setsize(150,84):diffuse(1,1,1,0.8)
			:diffuseleftedge(1,1,1,0)
		end
	},
	Def.Quad { --right diffusor
		InitCommand=function(self)
			self:xy(280,0)
			:setsize(150,84):diffuse(1,1,1,0.8)
			:diffuserightedge(1,1,1,0)
		end
	},

	Def.BitmapText {
		Font="Montserrat normal 20px",
		Name="Artist",
		InitCommand=function(self)
			self:zoom(1):halign(0.5):valign(0.5)			
			:maxwidth(FrameW * 1 / self:GetZoom())
			:diffuse(Color.Black)
			:xy(0,-28)
		end
	},
	
	Def.BitmapText {
		Font="Montserrat semibold 40px",
		Name="Title",
		InitCommand=function(self)
			self:zoom(0.8):halign(0.5):valign(0.5)
			:maxwidth(FrameW * 0.89 / self:GetZoom())
			:diffuse(Color.Black)
			:y(0)
		end
	},
	
	Def.BitmapText {
		Font="Montserrat normal 20px",
		Name="BPM",
		InitCommand=function(self)
			self:zoom(1):halign(0.5):valign(0.5)
			:maxwidth(FrameW * 1 / self:GetZoom())
			:diffuse(Color.Black)
			:xy(0,28)
		end
	},
	
	
	
	
	-- currently disabled since the Hearts system is NYI
	Def.Sprite {
		Texture=THEME:GetPathG("", "UI/Heart"),
		InitCommand=function(self)
			self:xy(FrameW / 2 - 80, 10):zoom(0.3):diffuse(Color.Black)
			:visible(false)
		end,
	},
	
	-- currently disabled since the Hearts system is NYI
	Def.Sprite {
		Texture=THEME:GetPathG("", "UI/Heart"),
		InitCommand=function(self)
			self:xy(FrameW / 2 - 82, 9):zoom(0.3)
			:visible(false)
		end,
	},
	
	-- currently disabled since the Hearts system is NYI
	Def.BitmapText {
		Font="Montserrat normal 20px",
		Name="Length",
		InitCommand=function(self)
			self:zoom(1):halign(1):valign(1)
			:maxwidth(FrameW * 0.2 / self:GetZoom())
			:diffuse(Color.Black)
			:xy(FrameW / 2 - 36, 16)
			:visible(false)
		end
	}		
}


return t