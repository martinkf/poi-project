local t = Def.ActorFrame {
	InitCommand=function(self)
		local Song = GAMESTATE:GetCurrentSong()
		if Song then
			local TitleText = Song:GetDisplayFullTitle()
			if TitleText == "" then TitleText = "Unknown" end

			local AuthorText = Song:GetDisplayArtist()
			if AuthorText == "" then AuthorText = "Unknown" end

			self:GetChild("Title"):settext(TitleText)
			self:GetChild("Artist"):settext(AuthorText)
		else
			self:GetChild("Title"):settext("")
			self:GetChild("Artist"):settext("")
		end
	end,

	RefreshCommand=function(self)
		local Song = GAMESTATE:GetCurrentSong()
		if Song then
			local TitleText = Song:GetDisplayFullTitle()
			if TitleText == "" then TitleText = "Unknown" end

			local AuthorText = Song:GetDisplayArtist()
			if AuthorText == "" then AuthorText = "Unknown" end

			self:GetChild("Title"):settext(TitleText)
			self:GetChild("Artist"):settext(AuthorText)
		else
			self:GetChild("Title"):settext("")
			self:GetChild("Artist"):settext("")
		end
	end,

	Def.Quad {
		InitCommand=function(self)
			self:xy(0,4)
			self:setsize(410,62)
			self:diffuse(0,0,0,0)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(0,0,0,0.4)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(0,0,0,0)
		end,
	},
	Def.Quad { --left diffusor
		InitCommand=function(self)
			self:xy(-280,4)
			self:setsize(150,62)
			self:diffuse(0,0,0,0)
			self:diffuseleftedge(0,0,0,0)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(0,0,0,0.4):diffuseleftedge(0,0,0,0)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(0,0,0,0)
		end,
	},
	Def.Quad { --right diffusor
		InitCommand=function(self)
			self:xy(280,4)
			self:setsize(150,62)
			self:diffuse(0,0,0,0)
			self:diffuserightedge(0,0,0,0)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(0,0,0,0.4):diffuserightedge(0,0,0,0)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(0,0,0,0)
		end,
	},

	Def.BitmapText {
		Font="Montserrat normal 20px",
		Name="Artist",
		InitCommand=function(self)
			self:zoom(1):halign(0.5):valign(0.5)
			:diffuse(Color.Black)
			:xy(0,-15)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(Color.White)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(Color.Black)
		end,
	},

	Def.BitmapText {
		Font="Montserrat semibold 40px",
		Name="Title",
		InitCommand=function(self)
			self:zoom(0.8):halign(0.5):valign(0.5)
			:diffuse(Color.Black)
			:y(15)
		end,
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):diffuse(Color.White)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffuse(Color.Black)
		end,
	},
}

return t