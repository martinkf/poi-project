local Songs = {}
local Targets = {}

local ChartPreview = LoadModule("Config.Load.lua")("ChartPreview","Save/OutFoxPrefs.ini")

local WheelSize = 9
local WheelCenter = math.ceil( WheelSize * 0.5 )
local WheelItem = { Width = 96, Height = 72 }
local WheelSpacing = 87
local WheelRotation = 0 -- zeroing it out. default was 0.15
local curvature = 0 -- zeroing it out. default was 65
local fieldOfView = 0 -- zeroing it out. default was 90

local EntireWheel_SelectingSongX = 0
local EntireWheel_SelectingSongY = 142
local EntireWheel_SelectingChartX = 410
local EntireWheel_SelectingChartY = -153

local arrayOfFilteredCharts
local arrayOfFilteredChartsSingles
local arrayOfFilteredChartsNotSingles

--


-- Not load anything if no group sorts are available (catastrophic event or no songs)
if next(GroupsList) == nil then
	AssembleGroupSorting_POI()
    UpdateGroupSorting()
    
    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible, halting music wheel!")
        return Def.Actor {}
    end
end

LastGroupMainIndex = tonumber(LoadModule("Config.Load.lua")("GroupMainIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
LastGroupSubIndex = tonumber(LoadModule("Config.Load.lua")("GroupSubIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
LastSongIndex = tonumber(LoadModule("Config.Load.lua")("SongIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
--reset LastGroup/Sub/Song if they were deleted since last session to avoid "attempt to index nil" crashes
if GroupsList[LastGroupMainIndex] == nil then
    LastGroupMainIndex = 1
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastGroupMainIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex] == nil then
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastGroupSubIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex].Songs == nil then 
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull underlay / MusicWheel.lua: LastSongIndex no longer present, reset performed")
end


local SongIndex = LastSongIndex > 0 and LastSongIndex or 1
local GroupMainIndex = LastGroupMainIndex > 0 and LastGroupMainIndex or 1
local GroupSubIndex = LastGroupSubIndex > 0 and LastGroupSubIndex or 1

local IsBusy = false

-- Default is to start at All for now
Songs = GroupsList[GroupMainIndex].SubGroups[GroupSubIndex].Songs

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
		self:x(EntireWheel_SelectingSongX)
		self:y(EntireWheel_SelectingSongY)
		self:fov(fieldOfView)
		self:SetDrawByZPosition(true)
		self:vanishpoint(SCREEN_CENTER_X, SCREEN_BOTTOM - 150 + curvature)
		UpdateItemTargets(SongIndex)
	end,

	OnCommand=function(self)
		GAMESTATE:SetCurrentSong(Songs[SongIndex])
		SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
		
		self:easeoutexpo(1):y(EntireWheel_SelectingSongY)
	end,
	
	-- Race condition workaround (yuck)
	MusicWheelStartMessageCommand=function(self) self:sleep(0.01):queuecommand("Confirm") end,
	ConfirmCommand=function(self) MESSAGEMAN:Broadcast("SongChosen") end,

	-- These are to control the functionality of the music wheel
	SongChosenMessageCommand=function(self)			
		self:stoptweening():easeoutexpo(1):x(EntireWheel_SelectingChartX):y(EntireWheel_SelectingChartY)
		:playcommand("Busy")
	end,
	SongUnchosenMessageCommand=function(self)			
		self:stoptweening():easeoutexpo(0.5):x(EntireWheel_SelectingSongX):y(EntireWheel_SelectingSongY)
		:playcommand("NotBusy")
	end,
	
	OpenGroupWheelMessageCommand=function(self) IsBusy = true end,
	CloseGroupWheelMessageCommand=function(self, params)
		if params.Silent == false then
			-- Grab the new list of songs from the selected group
			Songs = GroupsList[GroupIndex].SubGroups[SubGroupIndex].Songs
			-- Reset back to the first song of the list
			SongIndex = 1
			GAMESTATE:SetCurrentSong(Songs[SongIndex])
		end
		-- Update wheel yada yada
		UpdateItemTargets(SongIndex)
		MESSAGEMAN:Broadcast("ForceUpdate")
		self:sleep(0.01):queuecommand("NotBusy")
	end,
	
	BusyCommand=function(self) IsBusy = true end,
	NotBusyCommand=function(self) IsBusy = false end,
	
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
	--[[ scrolling sound is muted
	Def.Sound { Name="Sound 1",
		File=THEME:GetPathS("MusicWheel", "change"),
		IsAction=true,
		ScrollMessageCommand=function(self) self:play() end
	},
	]]--
	Def.Sound { Name="Sound 2",
		File=THEME:GetPathS("Common", "Start"),
		IsAction=true,
		MusicWheelStartMessageCommand=function(self) self:play() end
	},

	-- the background highlight of the song currently being hovered on
	Def.Quad { Name="Highlight",
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y)
			self:zoomto(1272, 86)
			self:align(0.5, 0.5)
			self:diffuse(color("1,1,1,0.6"))
		end,

		CurrentSongChangedMessageCommand=function(self)
			--self:stoptweening():diffusealpha(0):sleep(0.4):easeoutexpo(1):diffuse(color("1,1,1,0.6")) -- no effects for now
		end,

		SongChosenMessageCommand=function(self)
			self:stoptweening():diffuse(color("1,1,1,0.6")):easeoutexpo(1):diffusealpha(0):x(SCREEN_CENTER_X-410)
		end,
		SongUnchosenMessageCommand=function(self)
			self:stoptweening():diffusealpha(0):easeoutexpo(0.5):diffuse(color("1,1,1,0.6")):x(SCREEN_CENTER_X)
		end,
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
			local ypos = SCREEN_CENTER_Y + (i - WheelCenter) * WheelSpacing

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
			self:x(230)
			self:rotationx((SCREEN_CENTER_Y - ypos - displace) * -WheelRotation)
			self:y(ypos + displace)
			--self:z(-math.abs(SCREEN_CENTER_Y - ypos - displace) * 0.25) -- not sure what this does

			-- refresh the children frames
			self:GetChild("IndexIndicator"):playcommand("Refresh")

			self:GetChild("BGFrame"):playcommand("Refresh")
			self:GetChild("Banner"):playcommand("Refresh")

			self:GetChild("OriginLabel"):playcommand("Refresh")
			self:GetChild("BPMLabel"):playcommand("Refresh")
			self:GetChild("GenreLabel"):playcommand("Refresh")
			self:GetChild("CategoryLabel"):playcommand("Refresh")
			self:GetChild("NameLabel"):playcommand("Refresh")
			self:GetChild("ArtistLabel"):playcommand("Refresh")

			self:GetChild("ChartsList"):playcommand("Refresh")
		end,

		Def.Quad { Name="IndexIndicator",
			InitCommand=function(self)
				self:x(-218)
				self:align(0.5,0.5)
				self:diffuse(color("1,1,1,0.8"))
			end,
			RefreshCommand=function(self, param)
				-- alters its height depending on the number of songs in the group
				local totalSongsFromGroup = GetNumberOfSongsFromGroup_POI(GroupsList[GroupIndex].SubGroups[SubGroupIndex].Name)				
				local calculatedHeight = 590 / totalSongsFromGroup
				local usedHeight
				if calculatedHeight < 14 then
					usedHeight = 14
				else 
					usedHeight = calculatedHeight
				end
				self:zoomto(10, usedHeight)

				-- alters its y position depending on the current i
				self:y((Targets[i] - (totalSongsFromGroup + 1) / 2) * calculatedHeight)
				
				-- visibility, since this element technically gets cloned for each visible wheel element
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
				self:x(0)
				self:zoomto(104, 80)
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
				self:visible(i == WheelCenter)
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
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
		},						
		Def.BitmapText { Name="OriginLabel",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:addx(-62):addy(-26)
				self:zoom(0.4)
				--:skewx(-0.1)
				:shadowlength(1)
				self:align(1,0.5)
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
				self:visible(i == WheelCenter)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
		},
		Def.BitmapText { Name="BPMLabel",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:addx(-62):addy(0)
				self:zoom(0.8)
				self:align(1,0.5)
				:maxwidth(1000)
				:diffuse(Color.White)
				:shadowlength(1)
			end,
			
			RefreshCommand=function(self,param)
				self:settext(FetchFromSong(Songs[Targets[i]], "Song Display BPMs"))
				self:diffuse(Color.White)

				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,

			SongChosenMessageCommand=function(self)
				self:visible(i == WheelCenter)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,

		},
		Def.BitmapText { Name="GenreLabel",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:addx(-62):addy(23)
				self:zoom(0.8)
				self:align(1,0.5)
				:maxwidth(1000)
				:diffuse(Color.White)
				:shadowlength(1)
			end,
			
			RefreshCommand=function(self,param)
				self:settext(FetchFromSong(Songs[Targets[i]], "Display-formatted Song Genre"))

				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			SongChosenMessageCommand=function(self)
				self:visible(i == WheelCenter)
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
				self:addx(62):addy(-32)
				self:zoom(0.4)
				:shadowlength(1)
				self:align(0,0.5)
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
				self:visible(i == WheelCenter)
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
				self:addx(62):addy(-11)
				self:zoom(0.6)
				self:align(0,0.5)
				self:maxwidth(832)
				:diffuse(Color.White)
				:shadowlength(1.5)
			end,
			
			RefreshCommand=function(self,param)
				self:settext(Songs[Targets[i]]:GetDisplayFullTitle())
				
				self:diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				if FetchFromSong(Songs[Targets[i]], "Song Category") == "ARCADE" then
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				else
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color")):sleep(0.5):playcommand("LoopToWhiteThenBack")
				end

				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			
			SongChosenMessageCommand=function(self)
				self:visible(i == WheelCenter)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			LoopToWhiteThenBackCommand=function(self)
				self:easeoutexpo(1):diffuse(Color.White)
				self:queuecommand("SpecialColorLoop")
			end,
			SpecialColorLoopCommand=function(self)
				self:easeoutexpo(1):diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				self:queuecommand("LoopToWhiteThenBack")
			end,

		},
		Def.BitmapText { Name="ArtistLabel",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:addx(62):addy(11)
				self:zoom(0.8)
				self:align(0,0.5)
				self:maxwidth(832)
				:diffuse(Color.Black)
				:shadowlength(1)
			end,
			
			RefreshCommand=function(self,param)
				self:settext(Songs[Targets[i]]:GetDisplayArtist())
				
				self:diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				if FetchFromSong(Songs[Targets[i]], "Song Category") == "ARCADE" then
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				else
					self:stoptweening():diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color")):sleep(0.5):playcommand("LoopToWhiteThenBack")
				end

				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,

			SongChosenMessageCommand=function(self)
				self:visible(i == WheelCenter)
			end,
			SongUnchosenMessageCommand=function(self)
				if i > WheelCenter+3 or i < WheelCenter-3 then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			LoopToWhiteThenBackCommand=function(self)
				self:easeoutexpo(1):diffuse(Color.White)
				self:queuecommand("SpecialColorLoop")
			end,
			SpecialColorLoopCommand=function(self)
				self:easeoutexpo(1):diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				self:queuecommand("LoopToWhiteThenBack")
			end,

		},

		Def.ActorFrame { Name="ChartsList",
			InitCommand=function(self)
				self:x(574)
			end,
			RefreshCommand=function(self,param)

				-- updates arrayOfFilteredCharts variables for the children to use
				local currentNameOfPlaylist = GroupsList[GroupIndex].SubGroups[SubGroupIndex].Name
				local currentSongName = Songs[Targets[i]]:GetDisplayMainTitle()

				arrayOfFilteredCharts = GetAllowedCharts_POI(SongUtil.GetPlayableSteps(Songs[Targets[i]]), currentNameOfPlaylist, Targets[i])
				table.sort(arrayOfFilteredCharts, SortCharts)

				arrayOfFilteredChartsSingles = SplitChartArray(arrayOfFilteredCharts, "Singles", currentNameOfPlaylist, currentSongName)
				arrayOfFilteredChartsNotSingles = SplitChartArray(arrayOfFilteredCharts, "Not Singles", currentNameOfPlaylist, currentSongName)

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
				
			end,
			SongChosenMessageCommand=function(self)
				self:visible(false)
			end,
			SongUnchosenMessageCommand=function(self)
				self:playcommand("Refresh")
			end,

			Def.Quad { Name="BackgroundQuadA01",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.4"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 1 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA02",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 2 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA03",
				InitCommand=function(self)
					self:x((03-1) * 40)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 3 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[3])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA04",
				InitCommand=function(self)
					self:x((04-1) * 40)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 4 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[4])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA05",
				InitCommand=function(self)
					self:x((05-1) * 40)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 5 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[5])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA06",
				InitCommand=function(self)
					self:x((06-1) * 40)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 6 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[6])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA07",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 7 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[7])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end
					
				end,
			},
			Def.Quad { Name="BackgroundQuadA08",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 8 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[8])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA09",
				InitCommand=function(self)
					self:x((03-1) * 40)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 9 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[9])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end
					
				end,
			},
			Def.Quad { Name="BackgroundQuadA10",
				InitCommand=function(self)
					self:x((04-1) * 40)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 10 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[10])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadA11",
				InitCommand=function(self)
					self:x((05-1) * 40)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 11 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[11])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end
					
				end,
			},
			Def.Quad { Name="BackgroundQuadA12",
				InitCommand=function(self)
					self:x((06-1) * 40)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsSingles < 12 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsSingles[12])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB01",
				InitCommand=function(self)
					self:x((07-1) * 40 + 4)
					self:y(-20)					
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 1 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[1])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB02",
				InitCommand=function(self)
					self:x((08-1) * 40 + 4)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 2 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[2])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB03",
				InitCommand=function(self)
					self:x((09-1) * 40 + 4)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 3 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[3])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB04",
				InitCommand=function(self)
					self:x((10-1) * 40 + 4)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 4 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[4])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB05",
				InitCommand=function(self)
					self:x((11-1) * 40 + 4)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 5 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[5])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB06",
				InitCommand=function(self)
					self:x((12-1) * 40 + 4)
					self:y(-20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 6 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[6])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB07",
				InitCommand=function(self)
					self:x((07-1) * 40 + 4)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 7 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[7])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB08",
				InitCommand=function(self)
					self:x((08-1) * 40 + 4)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 8 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[8])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB09",
				InitCommand=function(self)
					self:x((09-1) * 40 + 4)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 9 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[9])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB10",
				InitCommand=function(self)
					self:x((10-1) * 40 + 4)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 10 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[10])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB11",
				InitCommand=function(self)
					self:x((11-1) * 40 + 4)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 11 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[11])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},
			Def.Quad { Name="BackgroundQuadB12",
				InitCommand=function(self)
					self:x((12-1) * 40 + 4)
					self:y(20)
					self:zoomto(38, 38)
					self:diffuse(color("0,0,0,0.1"))
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end
					
					-- alters their diffusion color
					if #arrayOfFilteredChartsNotSingles < 12 then
						self:diffuse(color("0,0,0,0.1"))
					else
						local scoreIndex = nil
						local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
						local scoreList = profile:GetHighScoreList(Songs[Targets[i]], arrayOfFilteredChartsNotSingles[12])
						if scoreList then
							local scores = scoreList:GetHighScores()
							if scores and #scores > 0 then
								scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
							end
						end
						self:diffuse(GetColorFromScoreIndex_POI(scoreIndex))
					end

				end,
			},

			Def.BitmapText { Name="ChartMeterA01",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 1 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[1], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[1], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA02",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 2 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[2], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[2], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA03",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((03-1) * 40)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 3 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[3], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[3], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA04",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((04-1) * 40)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 4 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[4], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[4], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA05",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((05-1) * 40)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 5 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[5], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[5], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA06",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((06-1) * 40)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 6 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[6], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[6], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA07",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((01-1) * 40)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 7 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[7], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[7], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA08",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((02-1) * 40)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 8 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[8], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[8], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA09",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((03-1) * 40)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 9 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[9], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[9], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA10",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((04-1) * 40)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 10 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[10], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[10], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA11",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((05-1) * 40)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 11 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[11], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[11], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterA12",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((06-1) * 40)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsSingles >= 12 then
						self:settext(FetchFromChart(arrayOfFilteredChartsSingles[12], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsSingles[12], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB01",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((07-1) * 40 + 4)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 1 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[1], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[1], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB02",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((08-1) * 40 + 4)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 2 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[2], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[2], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB03",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((09-1) * 40 + 4)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 3 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[3], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[3], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB04",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((10-1) * 40 + 4)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 4 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[4], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[4], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB05",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((11-1) * 40 + 4)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 5 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[5], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[5], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB06",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((12-1) * 40 + 4)
					self:y(-20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 6 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[6], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[6], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB07",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((07-1) * 40 + 4)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 7 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[7], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[7], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB08",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((08-1) * 40 + 4)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 8 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[8], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[8], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB09",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((09-1) * 40 + 4)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 9 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[9], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[9], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB10",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((10-1) * 40 + 4)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 10 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[10], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[10], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB11",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((11-1) * 40 + 4)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 11 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[11], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[11], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},
			Def.BitmapText { Name="ChartMeterB12",
				Font="Montserrat numbers 40px",
				InitCommand=function(self)
					self:x((12-1) * 40 + 4)
					self:y(20)
					self:zoom(0.5)
				end,
				RefreshCommand=function(self, param)

					-- hide everything if outside the wheel boundaries
					if i > WheelCenter+3 or i < WheelCenter-3 then
						self:visible(false)
					else
						self:visible(true)
					end

					-- alters their text based on the meter of the chart
					if #arrayOfFilteredChartsNotSingles >= 12 then
						self:settext(FetchFromChart(arrayOfFilteredChartsNotSingles[12], "Chart Meter"))
						-- alters their color based on the stepstype of the chart
						self:diffuse(FetchFromChart(arrayOfFilteredChartsNotSingles[12], "Chart Stepstype Color"))
					else
						self:diffuse(Color.Invisible)
					end

				end,
			},

		},

	}
end


return t