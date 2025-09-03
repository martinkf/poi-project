local Songs = {}
local Targets = {}

local ChartPreview = LoadModule("Config.Load.lua")("ChartPreview","Save/OutFoxPrefs.ini")

local WheelSize = 9
local WheelCenter = math.ceil( WheelSize * 0.5 )
local WheelItem = { Width = 208, Height = 117 }
local WheelSpacing = 214
local WheelRotation = 0 -- zeroing it out. default was 0.15
local curvature = 0 -- zeroing it out. default was 65
local fieldOfView = 0 -- zeroing it out. default was 90

local EntireScreen_SelectingSongY = 502
local EntireScreen_SelectingChartY = 502-720
local SongWheel_Y = 182

local ChartsListVisibility = false

local arrayOfFilteredCharts
local arrayOfFilteredChartsSingles
local arrayOfFilteredChartsNotSingles

local arrayOfFilteredChartsEasyStation
local arrayOfFilteredChartsNormal
local arrayOfFilteredChartsHard
local arrayOfFilteredChartsCrazy
local arrayOfFilteredChartsHalfdouble
local arrayOfFilteredChartsFreestyle
local arrayOfFilteredChartsNightmare


--


-- Not load anything if no group sorts are available (catastrophic event or no songs)
if next(GroupsList) == nil then
	AssembleGroupSorting_POI()
    UpdateGroupSorting_POI()
    
    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible, halting music wheel!")
        return Def.Actor {}
    end
end

-- Grab from .ini what the last Group and SongIndex were
LastGroupMainIndex = tonumber(LoadModule("Config.Load.lua")("GroupMainIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
LastSongIndex = tonumber(LoadModule("Config.Load.lua")("SongIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1

-- Reset LastGroup/Song if they were deleted since last session to avoid "attempt to index nil" crashes
if GroupsList[LastGroupMainIndex] == nil then
    LastGroupMainIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastGroupMainIndex no longer present, reset performed")
elseif GroupsList[LastGroupMainIndex].Songs[LastSongIndex] == nil then
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastSongIndex no longer present, reset performed")
end

-- Initializes local variables
local SongIndex = LastSongIndex > 0 and LastSongIndex or 1
local GroupMainIndex = LastGroupMainIndex > 0 and LastGroupMainIndex or 1
local IsBusy = false

-- Default is to start at All for now
Songs = GroupsList[GroupMainIndex].Songs

-- Default is to initialize this variable here I guess
GroupIndex = 1

-- Update Songs item targets
local function UpdateItemTargets(val)
    for i = 1, WheelSize do
        Targets[i] = val + i - WheelCenter

		local poi_settings_songlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsSonglistIsWheel", "Save/OutFoxPrefs.ini") or false
		if poi_settings_songlist_is_wheel then
			while Targets[i] > #Songs do Targets[i] = Targets[i] - #Songs end
        	while Targets[i] < 1 do Targets[i] = Targets[i] + #Songs end
		else
			-- literally do nothing
		end
		
    end
end

local function InputHandler(event)
	local pn = event.PlayerNumber
    if not pn then return end
    
    -- Don't want to move when releasing the button
    if event.type == "InputEventType_Release" then return end

    local button = event.GameButton
    
    -- If an unjoined player attempts to join and has enough credits, join them
    if (button == "Center" or (not IsGame("pump") and button == "Start")) and 
        not GAMESTATE:IsSideJoined(pn) and GAMESTATE:GetCoins() >= GAMESTATE:GetCoinsNeededToJoin() then
        GAMESTATE:JoinPlayer(pn)
        -- The command above does not deduct credits so we'll do it ourselves
        GAMESTATE:InsertCoin(-(GAMESTATE:GetCoinsNeededToJoin()))
        MESSAGEMAN:Broadcast("PlayerJoined", { Player = pn })
    end

    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

    if not IsBusy then
        if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
			
			local poi_settings_songlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsSonglistIsWheel", "Save/OutFoxPrefs.ini") or false
			if poi_settings_songlist_is_wheel then
				SongIndex = SongIndex - 1
				if SongIndex < 1 then SongIndex = #Songs end
				GAMESTATE:SetCurrentSong(Songs[SongIndex])
				UpdateItemTargets(SongIndex)
				MESSAGEMAN:Broadcast("Scroll", { Direction = -1 })
			else
				if SongIndex > 1 then
					SongIndex = SongIndex - 1
					GAMESTATE:SetCurrentSong(Songs[SongIndex])
					UpdateItemTargets(SongIndex)
					MESSAGEMAN:Broadcast("Scroll", { Direction = -1 })
				end
			end

        elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
			
			local poi_settings_songlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsSonglistIsWheel", "Save/OutFoxPrefs.ini") or false
			if poi_settings_songlist_is_wheel then
				SongIndex = SongIndex + 1
				if SongIndex > #Songs then SongIndex = 1 end
				GAMESTATE:SetCurrentSong(Songs[SongIndex])
				UpdateItemTargets(SongIndex)
				MESSAGEMAN:Broadcast("Scroll", { Direction = 1 })
			else
				if SongIndex < #Songs then
					SongIndex = SongIndex + 1
					GAMESTATE:SetCurrentSong(Songs[SongIndex])
					UpdateItemTargets(SongIndex)
					MESSAGEMAN:Broadcast("Scroll", { Direction = 1 })
				end
			end
            
        elseif button == "Start" or button == "MenuStart" or button == "Center" then
            -- Save this for later
            LastSongIndex = SongIndex
            LoadModule("Config.Save.lua")("SongIndex", LastSongIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
            
            MESSAGEMAN:Broadcast("MusicWheelStart")

        elseif button == "Back" then
            SCREENMAN:GetTopScreen():Cancel()
        end
    end

	MESSAGEMAN:Broadcast("UpdateMusic")
end

-- Manages banner on sprite
local function UpdateBanner(self, Song)
    self:LoadFromSongBanner(Song):scaletoclipped(WheelItem.Width, WheelItem.Height)
end


--


function GetCurrentSongIndex()
    return SongIndex
end

local t = Def.ActorFrame {
	InitCommand=function(self)
		self:y(EntireScreen_SelectingSongY)
		self:fov(fieldOfView)
		self:SetDrawByZPosition(true)
		self:vanishpoint(SCREEN_CENTER_X, SCREEN_BOTTOM - 150 + curvature)
		UpdateItemTargets(SongIndex)
	end,

	OnCommand=function(self)
		GAMESTATE:SetCurrentSong(Songs[SongIndex])
		SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
	end,
	BusyCommand=function(self) IsBusy = true end,
	NotBusyCommand=function(self) IsBusy = false end,
	
	-- Race condition workaround (yuck)
	MusicWheelStartMessageCommand=function(self) self:sleep(0.01):queuecommand("Confirm") end,
	ConfirmCommand=function(self) MESSAGEMAN:Broadcast("SongChosen") end,

	-- everything goes up and down when selecting songs or selecting charts!
	SongChosenMessageCommand=function(self)
		self:stoptweening():easeoutexpo(1):y(EntireScreen_SelectingChartY)
		:playcommand("Busy")
	end,
	SongUnchosenMessageCommand=function(self)			
		self:stoptweening():easeoutexpo(0.5):y(EntireScreen_SelectingSongY)
		:playcommand("NotBusy")
	end,

	-- logic related to the GroupSelect overlay
	OpenGroupWheelMessageCommand=function(self) IsBusy = true end,
	CloseGroupWheelMessageCommand=function(self, params)
		if params.Silent == false then
			-- Grab the new list of songs from the selected group
			Songs = GroupsList[GroupIndex].Songs
			-- Reset back to the first song of the list
			SongIndex = 1
			GAMESTATE:SetCurrentSong(Songs[SongIndex])
		end
		-- Update wheel yada yada
		UpdateItemTargets(SongIndex)
		MESSAGEMAN:Broadcast("ForceUpdate")
		self:sleep(0.01):queuecommand("NotBusy")
	end,
	

	-- drawing: sounds
	-- Play song preview (thanks Luizsan)
	Def.Actor { Name="Song Preview Player",
		CurrentSongChangedMessageCommand=function(self)
			SOUND:StopMusic()
			self:stoptweening():sleep(0.25):queuecommand("PlayMusic")
		end,
		
		PlayMusicCommand=function(self)
			local Song = GAMESTATE:GetCurrentSong()
			if Song then
				if ChartPreview then
					local StepList = Song:GetAllSteps()
					local FirstStep = StepList[1]
					local Duration = FirstStep:GetChartLength()
					SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(), 
					(Duration - Song:GetSampleStart()), 0, 1, false, false, false, Song:GetTimingData())
				else
					SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(), 
					Song:GetSampleLength(), 0, 1, false, false, false, Song:GetTimingData())
				end
			end
		end
	},
	
	Def.Sound { Name="Sound 1",
		File=THEME:GetPathS("", "StartCommandWindow"),
		IsAction=true,
		CurrentSongChangedMessageCommand=function(self) self:queuecommand("Refresh") end,
		RefreshCommand=function(self) self:play() end
	},
	
	Def.Sound { Name="Sound 2",
		File=THEME:GetPathS("Common", "Start"),
		IsAction=true,
		MusicWheelStartMessageCommand=function(self) self:play() end
	},


	-- drawing: visual elements	
	Def.Quad { Name="Highlight", -- the background highlight of the song currently being hovered on
		InitCommand=function(self)
			self:x(SCREEN_CENTER_X)
			self:y(SongWheel_Y-82)
			self:zoomto(1280, 158)
			self:align(0.5, 0)
			self:diffuse(color("1,1,1,0.6"))
		end,
		SongChosenMessageCommand=function(self)
			self:visible(false)
		end,
		SongUnchosenMessageCommand=function(self)
			self:visible(true)
		end,
	},

	Def.ActorFrame { -- instructions for Song Selection and Modifiers menu opening
		SongChosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(1):y(0+720)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):y(0)
		end,
		Def.Quad {
			Name="InstructionsRowBgQuad",
			InitCommand=function(self)
				self:x(SCREEN_CENTER_X)
				self:y(SongWheel_Y+80)
				self:zoomto(1272, 42)
				self:align(0.5,0)
				self:diffuse(color("0,0,0,0.4"))
			end,
		},
		Def.ActorFrame { Name="SongSelectInstructionsRowTexts",
			InitCommand=function(self)
				self:x(SCREEN_CENTER_X)
				self:y(SongWheel_Y+90)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-82)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-40)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("or      to select song")
					self:x(10)
				end,
			},
		},
		Def.ActorFrame { Name="OptionListInstructionsRowTexts",
			InitCommand=function(self)
				self:x(SCREEN_CENTER_X)
				self:y(SongWheel_Y+110)
			end,
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-159)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-139)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-119)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-99)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDL"),
				InitCommand=function(self)
					self:zoom(0.07):x(-79)
				end,
			},
			Def.Sprite {
				Texture=THEME:GetPathG("", "CornerArrows/ShiftDR"),
				InitCommand=function(self)
					self:zoom(0.07):x(-59)
				end,
			},
			Def.BitmapText {
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.4)
					self:shadowlength(1)
					self:settext("to open the Modifiers menu")
					self:x(70)
				end,
			},
		},
	},
}

-- The Wheel: originally made by Luizsan
for i = 1, WheelSize do
	t[#t+1] = Def.ActorFrame {
		OnCommand=function(self)
			-- Load banner
			UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])

			-- Set initial position, Direction = 0 means it won't tween
			self:playcommand("Scroll", {Direction = 0})
		end,
		
		ForceUpdateMessageCommand=function(self)
			-- Load banner
			UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])
			
			--SCREENMAN:SystemMessage(GroupsList[GroupIndex].Name)

			-- Set initial position, Direction = 0 means it won't tween
			self:playcommand("Scroll", {Direction = 0})
		end,
		
		ScrollMessageCommand=function(self,param)
			self:stoptweening()

			-- Calculate position
			local xpos = SCREEN_CENTER_X + (i - WheelCenter) * WheelSpacing

			-- Calculate displacement based on input
			local displace = -param.Direction * WheelSpacing
			
			-- Adjust and wrap actor index
			i = i - param.Direction
			while i > WheelSize do i = i - WheelSize end
			while i < 1 do i = i + WheelSize end

			-- If it's an edge item, load a new banner.
			if i == 1 or i == WheelSize then
				UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])
			end

			-- calculate visibility based on whether settings uses a wheel or a strip
			local poi_settings_songlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsSonglistIsWheel", "Save/OutFoxPrefs.ini") or false
			if poi_settings_songlist_is_wheel then
				-- literally do nothing
			else
				if Targets[i] > 0 and Targets[i] <= #Songs then
					self:visible(true)
				else
					self:visible(false)
				end
			end

			-- Animate!
			self:y(SongWheel_Y)
			self:rotationy((SCREEN_CENTER_X - xpos - displace) * -WheelRotation)
			self:x(xpos + displace)
			--self:z(-math.abs(SCREEN_CENTER_Y - xpos - displace) * 0.25) -- not sure what this does

			-- refresh the children frames
			self:GetChild("IndexIndicator"):playcommand("Refresh")
			self:GetChild("IndexIndicatorText"):playcommand("Refresh")

			self:GetChild("BGFrame"):playcommand("Refresh")
			self:GetChild("Banner"):playcommand("Refresh")

			self:GetChild("OriginLabel"):playcommand("Refresh")
			self:GetChild("CategoryLabel"):playcommand("Refresh")
			self:GetChild("NameLabel"):playcommand("Refresh")
			self:GetChild("ArtistLabel"):playcommand("Refresh")
			
			self:GetChild("ChartsList"):playcommand("Refresh")

			self:GetChild("DifficultyLabels"):playcommand("Refresh")
		end,
		

		Def.Quad { Name="IndexIndicator",
			InitCommand=function(self)
				self:y(68)
				self:align(0.5,0.5)
				self:diffuse(color("0,0,0,0.4"))
			end,
			RefreshCommand=function(self, param)
				-- alters its width depending on the number of songs in the group
				local totalSongsFromGroup = #GroupsList[GroupIndex].AllowedSongs
				local calculatedWidth = 1252 / totalSongsFromGroup
				local usedWidth
				if calculatedWidth < 30 then
					usedWidth = 30
				else 
					usedWidth = calculatedWidth
				end
				self:zoomto(usedWidth, 12)

				-- alters its x position depending on the current i
				self:x((Targets[i] - (totalSongsFromGroup + 1) / 2) * calculatedWidth)
				
				-- visibility, since this element technically gets cloned for each wheel element
				if i == WheelCenter then
					self:visible(true)
				else
					self:visible(false)
				end
			end,
			SongChosenMessageCommand=function(self)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				self:playcommand("Refresh")
			end,
		},
		Def.BitmapText { Name="IndexIndicatorText",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:addx(0):addy(68)
				self:zoom(0.3)
				self:align(0.5,0.5)
				self:diffuse(color("1,1,1,0.8"))
			end,
			
			RefreshCommand=function(self,param)
				-- alters some necessary variables depending on the number of songs in the group
				local totalSongsFromGroup = #GroupsList[GroupIndex].AllowedSongs
				local calculatedWidth = 1252 / totalSongsFromGroup

				-- alters its text depending on the current i
				self:settext(Targets[i])

				-- alters its x position depending on the current i
				self:x((Targets[i] - (totalSongsFromGroup + 1) / 2) * calculatedWidth)
				
				-- visibility, since this element technically gets cloned for each wheel element
				if i == WheelCenter then
					self:visible(true)
				else
					self:visible(false)
				end
			end,
			SongChosenMessageCommand=function(self)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				self:playcommand("Refresh")
			end,
		},

		Def.Quad { Name="BGFrame",
			InitCommand=function(self)
				self:y(-10)
				self:zoomto(211, 140)
				self:diffuse(color("0,0,0,0.4"))
			end,
			RefreshCommand=function(self, param)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			SongChosenMessageCommand=function(self)
				--self:visible(i == WheelCenter)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
		},
		Def.Banner { Name="Banner",
			RefreshCommand=function(self, param)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			SongChosenMessageCommand=function(self)
				if i == WheelCenter then
					self:visible(true)
				else
					self:visible(false)
				end
				self:stoptweening():easeoutexpo(0.5):y(220):zoomto(179, 98)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
				self:stoptweening():easeoutexpo(0.5):y(0):zoomto(208, 117)
			end,
		},						
		Def.BitmapText { Name="OriginLabel",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:addx(0):addy(-70)
				self:zoom(0.4)				
				:shadowlength(1)
				self:align(0.5,0.5)
			end,
			
			RefreshCommand=function(self,param)
				self:diffuse(FetchFromSong(Songs[Targets[i]], "Song Origin Color"))
				self:settext(Songs[Targets[i]]:GetOrigin())

				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			SongChosenMessageCommand=function(self)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
		},
		Def.BitmapText { Name="CategoryLabel",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:addx(0):addy(0)
				self:zoom(0.4)
				:shadowlength(1)
				self:align(0.5,0.5)
				self:maxwidth(832)
			end,
			
			RefreshCommand=function(self,param)
				self:settext(FetchFromSong(Songs[Targets[i]], "Display-formatted Song Category"))
				self:diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))

				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			SongChosenMessageCommand=function(self)
				--self:visible(i == WheelCenter)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
		},
		Def.BitmapText { Name="NameLabel",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:y(SongWheel_Y+32)
				self:zoom(0.6)
				self:align(0.5,0.5)
				self:maxwidth(832)
				self:diffuse(Color.White)
				self:shadowlength(1.5)
				self:visible(false) --disabling
			end,
			
			RefreshCommand=function(self,param)
				self:settext(Songs[Targets[i]]:GetDisplayFullTitle())
				
				self:diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				if FetchFromSong(Songs[Targets[i]], "Song Category") == "ARCADE" then
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				else
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color")):sleep(0.5):playcommand("LoopToWhiteThenBack")
				end

				if i > WheelCenter+0 or i < WheelCenter-0 then
					self:visible(false)
				else
					self:visible(true)
				end
				self:visible(false) --disabling
			end,
			
			SongChosenMessageCommand=function(self)
				self:visible(i == WheelCenter)
				self:visible(false) --disabling
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+0 or i < WheelCenter-0 then
					self:visible(false)
				else
					self:visible(true)
				end
				self:visible(false) --disabling
			end,
			LoopToWhiteThenBackCommand=function(self)
				self:easeoutexpo(0.5):diffuse(Color.White)
				self:queuecommand("SpecialColorLoop")
			end,
			SpecialColorLoopCommand=function(self)
				self:easeoutexpo(0.5):diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				self:queuecommand("LoopToWhiteThenBack")
			end,

		},
		Def.BitmapText { Name="ArtistLabel",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:y(SongWheel_Y+42)
				self:zoom(0.8)
				self:align(0.5,0.5)
				self:maxwidth(832)
				self:diffuse(Color.Black)
				self:shadowlength(1)
				self:visible(false) --disabling
			end,
			
			RefreshCommand=function(self,param)
				self:settext(Songs[Targets[i]]:GetDisplayArtist())
				
				self:diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				if FetchFromSong(Songs[Targets[i]], "Song Category") == "ARCADE" then
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				else
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color")):sleep(0.5):playcommand("LoopToWhiteThenBack")
				end

				if i > WheelCenter+0 or i < WheelCenter-0 then
					self:visible(false)
				else
					self:visible(true)
				end
				self:visible(false) --disabling
			end,

			SongChosenMessageCommand=function(self)
				self:visible(i == WheelCenter)
				self:visible(false) --disabling
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+0 or i < WheelCenter-0 then
					self:visible(false)
				else
					self:visible(true)
				end
				self:visible(false) --disabling
			end,
			LoopToWhiteThenBackCommand=function(self)
				self:easeoutexpo(0.5):diffuse(Color.White)
				self:queuecommand("SpecialColorLoop")
			end,
			SpecialColorLoopCommand=function(self)
				self:easeoutexpo(0.5):diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				self:queuecommand("LoopToWhiteThenBack")
			end,

		},

		Def.ActorFrame { Name="ChartsList",
			InitCommand=function(self)
				self:xy(-60,-477)
			end,
			RefreshCommand=function(self,param)

				-- updates arrayOfFilteredCharts variables for the children to use
				local currentNameOfPlaylist = GroupsList[GroupIndex].Name
				local currentSongName = Songs[Targets[i]]:GetDisplayMainTitle()

				arrayOfFilteredCharts = GetAllowedCharts_POI(SongUtil.GetPlayableSteps(Songs[Targets[i]]), currentNameOfPlaylist, Targets[i])
				table.sort(arrayOfFilteredCharts, SortCharts)
				
				arrayOfFilteredChartsSingles = SplitChartArray(arrayOfFilteredCharts, "Singles", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsNotSingles = SplitChartArray(arrayOfFilteredCharts, "Not Singles", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsEasyStation = SplitChartArray(arrayOfFilteredCharts, "Easy Station", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsNormal = SplitChartArray(arrayOfFilteredCharts, "Normal", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsHard = SplitChartArray(arrayOfFilteredCharts, "Hard", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsCrazy = SplitChartArray(arrayOfFilteredCharts, "Crazy", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsHalfdouble = SplitChartArray(arrayOfFilteredCharts, "Half-Double", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsFreestyle = SplitChartArray(arrayOfFilteredCharts, "Freestyle", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsNightmare = SplitChartArray(arrayOfFilteredCharts, "Nightmare", currentNameOfPlaylist, currentSongName)

				-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

				-- runs the refresh command in ALL of this ActorFrame's children elements
				for _, child in ipairs(self:GetChildren()) do
					child:playcommand("Refresh", param)
				end
				
				-- global toggle for developers
				self:visible(ChartsListVisibility)
			end,
			SongChosenMessageCommand=function(self)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				self:playcommand("Refresh")
			end,

			Def.ActorFrame {
				Name="ChartItem-EasyStation01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(0)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsEasyStation < 1 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsEasyStation[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsEasyStation[1], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-EasyStation02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(0)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsEasyStation < 2 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsEasyStation[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsEasyStation[2], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Normal01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(01*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsNormal < 1 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNormal[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsNormal[1], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Normal02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(01*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsNormal < 2 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNormal[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsNormal[2], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Hard01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(02*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsHard < 1 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsHard[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsHard[1], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Hard02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(02*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsHard < 2 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsHard[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsHard[2], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Crazy01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(03*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsCrazy < 1 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsCrazy[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsCrazy[1], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Crazy02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(03*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsCrazy < 2 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsCrazy[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsCrazy[2], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Crazy03",
				InitCommand=function(self)
					self:x((03-1) * 40)
					self:y(03*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsCrazy < 3 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsCrazy[3])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsCrazy[3], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Crazy04",
				InitCommand=function(self)
					self:x((04-1) * 40)
					self:y(03*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsCrazy < 4 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsCrazy[4])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsCrazy[4], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-HalfDouble01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(04*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsHalfdouble < 1 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsHalfdouble[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsHalfdouble[1], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-HalfDouble02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(04*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsHalfdouble < 2 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsHalfdouble[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsHalfdouble[2], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Freestyle01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(05*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsFreestyle < 1 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsFreestyle[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsFreestyle[1], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Freestyle02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(05*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsFreestyle < 2 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsFreestyle[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsFreestyle[2], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Nightmare01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(06*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsNightmare < 1 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNightmare[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsNightmare[1], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
			Def.ActorFrame {
				Name="ChartItem-Nightmare02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(06*60)
				end,

				RefreshCommand=function(self, param)
					local quad = self:GetChild("Quad")
					local text = self:GetChild("Text")

					-- boundary visibility
					if i > WheelCenter+3 or i < WheelCenter-3 then
						quad:visible(false)
						text:visible(false)
						return
					else
						quad:visible(true)
						text:visible(true)
					end

					-- quad diffusion
					if #arrayOfFilteredChartsNightmare < 2 then
						quad:diffuse(color("0,0,0,0"))
						text:diffuse(Color.Invisible)
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNightmare[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						quad:diffuse(GetColorFromScoreIndex_POI(scoreIndex))

						text:settext(FetchFromChart(arrayOfFilteredChartsNightmare[2], "Chart Meter"))
						text:diffuse(Color.White)
					end
				end,

				Def.Quad {
					Name="Quad",
					InitCommand=function(self)
						self:zoomto(38, 38)
						self:diffuse(color("0,0,0,0.2"))
					end,
				},

				Def.BitmapText {
					Name="Text",
					Font="Montserrat numbers 40px",
					InitCommand=function(self)
						self:zoom(0.5)
					end,
				},
			},
		},

		Def.ActorFrame { Name="DifficultyLabels",
			InitCommand=function(self)
				self:xy(0, -552)
			end,

			RefreshCommand=function(self, param)
				-- visibility, since this element technically gets cloned for each wheel element
				if i == WheelCenter then
					self:visible(true)
				else
					self:visible(false)
				end

				-- populates some useful local variables
				local currentPlaylist = GroupsList[GroupIndex].Name

				-- availability: Easy Station
				if currentPlaylist == "Pump It Up Zero" then
					self:GetChild("DifficultyLabel-EasyStation"):visible(true)
					self:GetChild("DifficultyText-EasyStation"):visible(true)
				else
					self:GetChild("DifficultyLabel-EasyStation"):visible(false)
					self:GetChild("DifficultyText-EasyStation"):visible(false)
				end
				-- availability: Crazy
				if currentPlaylist == "Pump It Up The 1st Dance Floor"
				or currentPlaylist == "Pump It Up The 2nd Dance Floor" then
					self:GetChild("DifficultyLabel-Crazy"):visible(false)
					self:GetChild("DifficultyText-Crazy"):visible(false)
				else
					self:GetChild("DifficultyLabel-Crazy"):visible(true)
					self:GetChild("DifficultyText-Crazy"):visible(true)
				end
				-- availability: Half-Double
				if currentPlaylist == "Pump It Up The Rebirth"
				or currentPlaylist == "Pump It Up The Premiere 2"
				or currentPlaylist == "Pump It Up The Premiere 3"
				or currentPlaylist == "Pump It Up The Prex 3" then
					self:GetChild("DifficultyLabel-HalfDouble"):visible(true)
					self:GetChild("DifficultyText-HalfDouble"):visible(true)
				else
					self:GetChild("DifficultyLabel-HalfDouble"):visible(false)
					self:GetChild("DifficultyText-HalfDouble"):visible(false)
				end
				-- availability: Nightmare
				if currentPlaylist == "Pump It Up Extra"
				or currentPlaylist == "Pump It Up The Prex 3"
				or currentPlaylist == "Pump It Up Exceed"
				or currentPlaylist == "Pump It Up Exceed 2"
				or currentPlaylist == "Pump It Up Zero" then
					self:GetChild("DifficultyLabel-Nightmare"):visible(true)
					self:GetChild("DifficultyText-Nightmare"):visible(true)
				else
					self:GetChild("DifficultyLabel-Nightmare"):visible(false)
					self:GetChild("DifficultyText-Nightmare"):visible(false)
				end

				-- coloring: Easy Station
				if #arrayOfFilteredChartsEasyStation < 1 then
					self:GetChild("DifficultyText-EasyStation"):diffuse(color("#aaaaaa"))
					self:GetChild("DifficultyText-EasyStation"):diffusealpha(0.4)
				else
					self:GetChild("DifficultyText-EasyStation"):diffuse(color("#ff77aa"))
					self:GetChild("DifficultyText-EasyStation"):diffusealpha(1)
				end
				-- coloring: Normal
				if #arrayOfFilteredChartsNormal < 1 then
					self:GetChild("DifficultyText-Normal"):diffuse(color("#aaaaaa"))
					self:GetChild("DifficultyText-Normal"):diffusealpha(0.4)
				else
					self:GetChild("DifficultyText-Normal"):diffuse(color("#ffbb33"))
					self:GetChild("DifficultyText-Normal"):diffusealpha(1)
				end
				-- coloring: Hard
				if #arrayOfFilteredChartsHard < 1 then
					self:GetChild("DifficultyText-Hard"):diffuse(color("#aaaaaa"))
					self:GetChild("DifficultyText-Hard"):diffusealpha(0.4)
				else
					self:GetChild("DifficultyText-Hard"):diffuse(color("#ff9900"))
					self:GetChild("DifficultyText-Hard"):diffusealpha(1)
				end
				-- coloring: Crazy
				if #arrayOfFilteredChartsCrazy < 1 then
					self:GetChild("DifficultyText-Crazy"):diffuse(color("#aaaaaa"))
					self:GetChild("DifficultyText-Crazy"):diffusealpha(0.4)
				else
					self:GetChild("DifficultyText-Crazy"):diffuse(color("#ff6600"))
					self:GetChild("DifficultyText-Crazy"):diffusealpha(1)
				end
				-- coloring: Half-Double
				if #arrayOfFilteredChartsHalfdouble < 1 then
					self:GetChild("DifficultyText-HalfDouble"):diffuse(color("#aaaaaa"))
					self:GetChild("DifficultyText-HalfDouble"):diffusealpha(0.4)
				else
					self:GetChild("DifficultyText-HalfDouble"):diffuse(color("#99ccee"))
					self:GetChild("DifficultyText-HalfDouble"):diffusealpha(1)
				end
				-- coloring: Freestyle
				if #arrayOfFilteredChartsFreestyle < 1 then
					self:GetChild("DifficultyText-FreeStyle"):diffuse(color("#aaaaaa"))
					self:GetChild("DifficultyText-FreeStyle"):diffusealpha(0.4)
				else
					self:GetChild("DifficultyText-FreeStyle"):diffuse(color("#00ee66"))
					self:GetChild("DifficultyText-FreeStyle"):diffusealpha(1)
				end
				-- coloring: Nightmare
				if #arrayOfFilteredChartsNightmare < 1 then
					self:GetChild("DifficultyText-Nightmare"):diffuse(color("#aaaaaa"))
					self:GetChild("DifficultyText-Nightmare"):diffusealpha(0.4)
				else
					self:GetChild("DifficultyText-Nightmare"):diffuse(color("#00cc55"))
					self:GetChild("DifficultyText-Nightmare"):diffusealpha(1)
				end

				-- renaming: Normal > Easy
				if currentPlaylist == "Pump It Up The 1st Dance Floor"
				or currentPlaylist == "Pump It Up The 2nd Dance Floor"
				or currentPlaylist == "Pump It Up The O.B.G. The 3rd Dance Floor"
				or currentPlaylist == "Pump It Up The Rebirth"
				or currentPlaylist == "Pump It Up The Premiere 2" then
					self:GetChild("DifficultyText-Normal"):settext("EASY")
				else
					self:GetChild("DifficultyText-Normal"):settext("NORMAL")
				end

				-- renaming: Crazy > Extra Expert
				if currentPlaylist == "Pump It Up Extra" then
					self:GetChild("DifficultyText-Crazy"):settext("EXTRA EXPERT")
				else
					self:GetChild("DifficultyText-Crazy"):settext("CRAZY")
				end

				-- renaming: Freestyle > Double
				-- renaming: Freestyle > Full-Double
				if currentPlaylist == "Pump It Up The 1st Dance Floor"
				or currentPlaylist == "Pump It Up The 2nd Dance Floor"
				or currentPlaylist == "Pump It Up The O.B.G. The 3rd Dance Floor"
				or currentPlaylist == "Pump It Up The O.B.G. The Season Evolution Dance Floor"
				or currentPlaylist == "Pump It Up Perfect Collection"
				or currentPlaylist == "Pump It Up Extra"
				or currentPlaylist == "Pump It Up The Premiere"
				or currentPlaylist == "Pump It Up The Prex"
				or currentPlaylist == "Pump It Up The Prex 2" then
					self:GetChild("DifficultyText-FreeStyle"):settext("DOUBLE")
				elseif currentPlaylist == "Pump It Up The Rebirth"
				or currentPlaylist == "Pump It Up The Premiere 2"
				or currentPlaylist == "Pump It Up The Premiere 3" then
					self:GetChild("DifficultyText-FreeStyle"):settext("FULL-DOUBLE")
				else
					self:GetChild("DifficultyText-FreeStyle"):settext("FREESTYLE")
				end

				-- renaming: Nightmare > Extra Expert Double
				if currentPlaylist == "Pump It Up Extra" then
					self:GetChild("DifficultyText-Nightmare"):settext("EXTRA EXPERT DOUBLE")
				else
					self:GetChild("DifficultyText-Nightmare"):settext("NIGHTMARE")
				end

				-- global toggle for developers
				self:visible(ChartsListVisibility)
			end,
			RefreshVisibilityCommand=function(self, param)
				-- visibility, since this element technically gets cloned for each wheel element
				if i == WheelCenter then
					self:visible(true)
				else
					self:visible(false)
				end

				-- global toggle for developers
				self:visible(ChartsListVisibility)
			end,
			SongChosenMessageCommand=function(self)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				self:playcommand("RefreshVisibility")
			end,

			Def.Quad { Name="DifficultyLabel-EasyStation",
				InitCommand=function(self)
					self:y(36)
					self:zoomto(1272, 20)
					self:align(0.5, 0)
					self:diffuse(color("0,0,0,0.2"))
				end,
			},
			Def.BitmapText { Name="DifficultyText-EasyStation",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y(45)
					self:zoom(0.4)
					self:shadowlength(1)
					self:align(0.5,0.5)
					self:settext("EASY STATION")
					self:diffuse(color("#ff77aa"))
				end,
			},
			Def.Quad { Name="DifficultyLabel-Normal",
				InitCommand=function(self)
					self:y((1*60)+36)
					self:zoomto(1272, 20)
					self:align(0.5, 0)
					self:diffuse(color("0,0,0,0.2"))
				end,
			},
			Def.BitmapText { Name="DifficultyText-Normal",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y((1*60)+45)
					self:zoom(0.4)
					self:shadowlength(1)
					self:align(0.5,0.5)
					self:settext("NORMAL")
					self:diffuse(color("#ffbb33"))
				end,
			},
			Def.Quad { Name="DifficultyLabel-Hard",
				InitCommand=function(self)
					self:y((2*60)+36)
					self:zoomto(1272, 20)
					self:align(0.5, 0)
					self:diffuse(color("0,0,0,0.2"))
				end,
			},
			Def.BitmapText { Name="DifficultyText-Hard",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y((2*60)+45)
					self:zoom(0.4)
					self:shadowlength(1)
					self:align(0.5,0.5)
					self:settext("HARD")
					self:diffuse(color("#ff9900"))
				end,
			},
			Def.Quad { Name="DifficultyLabel-Crazy",
				InitCommand=function(self)
					self:y((3*60)+36)
					self:zoomto(1272, 20)
					self:align(0.5, 0)
					self:diffuse(color("0,0,0,0.2"))
				end,
			},
			Def.BitmapText { Name="DifficultyText-Crazy",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y((3*60)+45)
					self:zoom(0.4)
					self:shadowlength(1)
					self:align(0.5,0.5)
					self:settext("CRAZY")
					self:diffuse(color("#ff6600"))
				end,
			},
			Def.Quad { Name="DifficultyLabel-HalfDouble",
				InitCommand=function(self)
					self:y((4*60)+36)
					self:zoomto(1272, 20)
					self:align(0.5, 0)
					self:diffuse(color("0,0,0,0.2"))
				end,
			},
			Def.BitmapText { Name="DifficultyText-HalfDouble",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y((4*60)+45)
					self:zoom(0.4)
					self:shadowlength(1)
					self:align(0.5,0.5)
					self:settext("HALF-DOUBLE")
					self:diffuse(color("#99ccee"))
				end,
			},
			Def.Quad { Name="DifficultyLabel-FreeStyle",
				InitCommand=function(self)
					self:y((5*60)+36)
					self:zoomto(1272, 20)
					self:align(0.5, 0)
					self:diffuse(color("0,0,0,0.2"))
				end,
			},
			Def.BitmapText { Name="DifficultyText-FreeStyle",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y((5*60)+45)
					self:zoom(0.4)
					self:shadowlength(1)
					self:align(0.5,0.5)
					self:settext("FREESTYLE")
					self:diffuse(color("#00ee66"))
				end,
			},
			Def.Quad { Name="DifficultyLabel-Nightmare",
				InitCommand=function(self)
					self:y((6*60)+36)
					self:zoomto(1272, 20)
					self:align(0.5, 0)
					self:diffuse(color("0,0,0,0.2"))
				end,
			},
			Def.BitmapText { Name="DifficultyText-Nightmare",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y((6*60)+45)
					self:zoom(0.4)
					self:shadowlength(1)
					self:align(0.5,0.5)
					self:settext("NIGHTMARE")
					self:diffuse(color("#00cc55"))
				end,
			},
		},

	}
end


return t