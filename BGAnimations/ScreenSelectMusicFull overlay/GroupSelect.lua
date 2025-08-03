local MainWheelSize = 70
local MainWheelCenter = math.ceil( MainWheelSize * 0.5 )
local MainWheelSpacing = 180 + 280

local SubWheelSize = 70
local SubWheelCenter = math.ceil( SubWheelSize * 0.5 )
local SubWheelSpacing = 250 + 25

local WheelItem = { Width = 212, Height = 120 }
local WheelRotation = 0.1 - 0.1

local MenuButtonsOnly = PREFSMAN:GetPreference("OnlyDedicatedMenuButtons")

local PlaylistWheel_Y = SCREEN_CENTER_Y - 70
local SublistWheel_Y = SCREEN_CENTER_Y + 170

local curvature = 0


--


function UpdatePlaylistBanner(self, Banner)
	if Banner == "" then Banner = THEME:GetPathG("Common fallback", "banner") end		
	self:Load(Banner):zoom(0.19)
end

function UpdatePlaylistFrame(self, visibility)	
	self:visible(visibility)
end

-- Not load anything if no group sorts are available (catastrophic event or no songs)
if next(GroupsList) == nil then
	AssembleGroupSorting_POI()
    UpdateGroupSorting()
    
    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible, halting music wheel!")
        return Def.Actor {}
    end
end

-- So that we can grab the Cur screen and use it outside an actor
local ScreenSelectMusic

-- Used for quitting the game
local IsHome = GAMESTATE:GetCoinMode() == "CoinMode_Home"
local IsEvent = GAMESTATE:IsEventMode()
local TickCount = 0 -- Used for InputEventType_Repeat

local IsOptionsList = { PLAYER_1 = false, PLAYER_2 = false }
local IsSelectingGroup = false
local IsBusy = false
local IsFocusedMain = false

LastGroupMainIndex = tonumber(LoadModule("Config.Load.lua")("GroupMainIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 0
LastGroupSubIndex = tonumber(LoadModule("Config.Load.lua")("GroupSubIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 0
LastSongIndex = tonumber(LoadModule("Config.Load.lua")("SongIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 0
--reset LastGroup/Sub/Song if they were deleted since last session to avoid "attempt to index nil" crashes
if GroupsList[LastGroupMainIndex] == nil then
    LastGroupMainIndex = 1
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull overlay / GroupSelect.lua: LastGroupMainIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex] == nil then
    LastGroupSubIndex = 1
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull overlay / GroupSelect.lua: LastGroupSubIndex no longer present, reset performed")
end
if GroupsList[LastGroupMainIndex].SubGroups[LastGroupSubIndex].Songs == nil then 
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull overlay / GroupSelect.lua: LastSongIndex no longer, reset performed")
end

-- Create the variables necessary for both wheels
local CurMainIndex = LastGroupMainIndex > 0 and LastGroupMainIndex or 1
local CurSubIndex = LastGroupSubIndex > 0 and LastGroupSubIndex or 1
local MainTargets = {}
local SubTargets = {}

-- This is to determine where are the original groups located
-- TODO: Not hardcode this
local OrigGroupIndex = 2

local function BlockScreenInput(State)
    --SCREENMAN:set_input_redirected(PLAYER_1, State)
    --SCREENMAN:set_input_redirected(PLAYER_2, State)
end

-- If no songs don't load anything
if SONGMAN:GetNumSongs() == 0 then
    return Def.Actor {}
else

	-- Update Group item targets
	local function UpdateMainItemTargets(val)
		for i = 1, MainWheelSize do
			MainTargets[i] = val + i - MainWheelCenter

			local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
			if poi_settings_playlist_is_wheel then
				while MainTargets[i] > #GroupsList do MainTargets[i] = MainTargets[i] - #GroupsList end
				while MainTargets[i] < 1 do MainTargets[i] = MainTargets[i] + #GroupsList end
			else
				-- literally do nothing
			end

		end
	end

	local function UpdateSubItemTargets(val)
		for i = 1, SubWheelSize do
			SubTargets[i] = val + i - SubWheelCenter

			local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
			if poi_settings_playlist_is_wheel then
				while SubTargets[i] > #GroupsList[CurMainIndex].SubGroups do SubTargets[i] = SubTargets[i] - #GroupsList[CurMainIndex].SubGroups end
				while SubTargets[i] < 1 do SubTargets[i] = SubTargets[i] + #GroupsList[CurMainIndex].SubGroups end
			else
				-- literally do nothing
			end
			
		end
	end

	-- Manages banner on sprite
	function UpdateBanner(self, Banner)
		if Banner == "" then Banner = THEME:GetPathG("Common fallback", "banner") end
		self:Load(Banner):scaletofit(-WheelItem.Width / 2, -WheelItem.Height / 2, WheelItem.Width / 2, WheelItem.Height / 2)
	end

	local function InputHandler(event)
		local pn = event.PlayerNumber
		if not pn then return end
		
		-- Don't want to move when releasing the button
		if event.type == "InputEventType_Release" then 
			TickCount = 0 
			MESSAGEMAN:Broadcast("ExitTickDown")
			return
		end
		
		local button = event.GameButton
		
		-- To avoid control from a player that has not joined, filter the inputs out
		if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
		if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end
		
		if IsSelectingGroup then
			if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
				if IsFocusedMain then

					local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
					if poi_settings_playlist_is_wheel then
						CurMainIndex = CurMainIndex - 1
						if CurMainIndex < 1 then CurMainIndex = #GroupsList end
						UpdateMainItemTargets(CurMainIndex)
						CurSubIndex = 1
						UpdateSubItemTargets(CurSubIndex)
						MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
						MESSAGEMAN:Broadcast("RefreshSub")
					else
						if CurMainIndex > 1 then
							CurMainIndex = CurMainIndex - 1
							UpdateMainItemTargets(CurMainIndex)
							CurSubIndex = 1
							UpdateSubItemTargets(CurSubIndex)
							MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
							MESSAGEMAN:Broadcast("RefreshSub")
						end
					end
					
				else
					
					local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
					if poi_settings_playlist_is_wheel then
						CurSubIndex = CurSubIndex - 1
						if CurSubIndex < 1 then CurSubIndex = #GroupsList[CurMainIndex].SubGroups end
						UpdateSubItemTargets(CurSubIndex)
						MESSAGEMAN:Broadcast("ScrollSub", { Direction = -1 })
					else
						if CurSubIndex > 1 then
							CurSubIndex = CurSubIndex - 1
							UpdateSubItemTargets(CurSubIndex)
							MESSAGEMAN:Broadcast("ScrollSub", { Direction = -1 })
						end
					end

				end
				
			elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
				if IsFocusedMain then

					local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
					if poi_settings_playlist_is_wheel then
						CurMainIndex = CurMainIndex + 1
						if CurMainIndex > #GroupsList then CurMainIndex = 1 end
						UpdateMainItemTargets(CurMainIndex)
						CurSubIndex = 1
						UpdateSubItemTargets(CurSubIndex)
						MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
						MESSAGEMAN:Broadcast("RefreshSub")
					else
						if CurMainIndex < #GroupsList then
							CurMainIndex = CurMainIndex + 1
							UpdateMainItemTargets(CurMainIndex)
							CurSubIndex = 1
							UpdateSubItemTargets(CurSubIndex)
							MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
							MESSAGEMAN:Broadcast("RefreshSub")
						end
					end
					
				else

					local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
					if poi_settings_playlist_is_wheel then
						CurSubIndex = CurSubIndex + 1
						if CurSubIndex > #GroupsList[CurMainIndex].SubGroups then CurSubIndex = 1 end
						UpdateSubItemTargets(CurSubIndex)
						MESSAGEMAN:Broadcast("ScrollSub", { Direction = 1 })
					else
						if CurSubIndex < #GroupsList[CurMainIndex].SubGroups then
							CurSubIndex = CurSubIndex + 1
							UpdateSubItemTargets(CurSubIndex)
							MESSAGEMAN:Broadcast("ScrollSub", { Direction = 1 })
						end
					end

				end
			elseif button == "Start" or button == "MenuStart" or button == "Center" then
				if IsFocusedMain then 
					IsFocusedMain = false
					if CurSubIndex > #GroupsList[CurMainIndex].SubGroups then CurSubIndex = 1 end
					UpdateSubItemTargets(CurSubIndex)
					MESSAGEMAN:Broadcast("RefreshHighlight") 
				else
					if CurMainIndex == LastGroupMainIndex and CurSubIndex == LastGroupSubIndex then
						MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = true })
					else
						GroupIndex = CurMainIndex
						SubGroupIndex = CurSubIndex
						
						-- Save this for later
						LastGroupMainIndex = CurMainIndex
						LastGroupSubIndex = CurSubIndex
						
						LoadModule("Config.Save.lua")("GroupMainIndex", LastGroupMainIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
						LoadModule("Config.Save.lua")("GroupSubIndex", LastGroupSubIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
						
						MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = false })
					end
				end
				
			elseif button == "UpRight" or button == "UpLeft" or button == "Up" or button == "MenuUp" then
				if not IsFocusedMain then 
					IsFocusedMain = true
					MESSAGEMAN:Broadcast("RefreshHighlight")
				elseif IsHome or IsEvent then 
					MESSAGEMAN:Broadcast("ExitPressed")
				end
			end

			if IsHome or IsEvent then
				if event.type == "InputEventType_Repeat" then
					if button == "UpLeft" or button == "UpRight" or button == "Up" then
						TickCount = TickCount + 1
						MESSAGEMAN:Broadcast("ExitTickUp")
						if TickCount == 15 then
							BlockScreenInput(false)
							SCREENMAN:GetTopScreen():Cancel()
						end
					end
				end
			end
		end
	end

	local t = Def.ActorFrame {
		InitCommand=function(self)
			self:fov(90):SetDrawByZPosition(true)
			:vanishpoint(SCREEN_CENTER_X, SCREEN_CENTER_Y + 40):diffusealpha(0)
			UpdateMainItemTargets(CurMainIndex)
			UpdateSubItemTargets(CurSubIndex)
		end,

		OnCommand=function(self)
			BlockScreenInput(false)
			ScreenSelectMusic = SCREENMAN:GetTopScreen()
			ScreenSelectMusic:AddInputCallback(InputHandler)
		end,
		
		OffCommand=function(self) BlockScreenInput(false) end,
		
		SongChosenMessageCommand=function(self) self:queuecommand("Busy") end,
		SongUnchosenMessageCommand=function(self) self:sleep(0.01):queuecommand("NotBusy") end,
		
		OptionsListOpenedMessageCommand=function(self, params) IsOptionsList[params.Player] = true end,
		OptionsListClosedMessageCommand=function(self, params) IsOptionsList[params.Player] = false end,

		CodeMessageCommand=function(self, params)
			if params.Name == "GroupSelectPad1" or params.Name == "GroupSelectPad2" or 
			params.Name == "GroupSelectButton1" or params.Name == "GroupSelectButton2" then
				if not IsBusy and not IsOptionsList[PLAYER_1] and not IsOptionsList[PLAYER_2] then
					-- Prevent the song list from moving when transitioning
					BlockScreenInput(true)
					MESSAGEMAN:Broadcast("OpenGroupWheel")
					self:stoptweening():sleep(0.01):queuecommand("OpenGroup"):easeoutexpo(1):diffusealpha(1)
				end
			end
		end,
		
		BusyCommand=function(self) IsBusy = true end,
		NotBusyCommand=function(self) IsBusy = false end,
		
		OpenGroupCommand=function(self) IsSelectingGroup = true end,
		CloseGroupCommand=function(self) IsSelectingGroup = false end,
		
		CloseGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(0.25):diffusealpha(0)
			
			BlockScreenInput(false)
			IsSelectingGroup = false
			
			if params.Silent == false then
				-- The built in wheel needs to be told the group has been changed
				ScreenSelectMusic:PostScreenMessage("SM_SongChanged", 0 )
				MESSAGEMAN:Broadcast("StartSelectingSong")
			end
		end,

		Def.Sound {
			File=THEME:GetPathS("MusicWheel", "change"),
			IsAction=true,
			ScrollMainMessageCommand=function(self) self:play() end,
			ScrollSubMessageCommand=function(self, params) if params.Direction ~= 0 then self:play() end end
		},

		Def.Sound {
			File=THEME:GetPathS("Common", "Start"),
			IsAction=true,
			CloseGroupWheelMessageCommand=function(self) self:play() end
		},
	}

	-- The Wheel: originally made by Luizsan
	-- First wheel will be responsible for the main sort options
	for i = 1, MainWheelSize do
		t[#t+1] = Def.ActorFrame{
			OnCommand=function(self)
				-- Update sort text
				self:GetChild("Text"):settext(GroupsList[MainTargets[i]].Name)				
				
				-- Set initial position, Direction = 0 means it won't tween
				self:playcommand("ScrollMain", {Direction = 0})
				
				-- updates playlist banner pic and its frame			
				self:GetChild("PlaylistBanner"):visible(true)
				self:GetChild("PlaylistFrame"):visible(true)
				UpdatePlaylistBanner(self:GetChild("PlaylistBanner"), GroupsList[MainTargets[i]].Banner)
				UpdatePlaylistFrame(self:GetChild("PlaylistFrame"), true)
			end,

			ScrollMainMessageCommand=function(self, params)
				self:stoptweening()

				-- Calculate position
				local xpos = SCREEN_CENTER_X + (i - MainWheelCenter) * MainWheelSpacing

				-- Calculate displacement based on input
				local displace = -params.Direction * MainWheelSpacing

				-- Only tween if a direction was specified
				local tween = params and params.Direction and math.abs(params.Direction) > 0
								
				-- Adjust and wrap actor index
				i = i - params.Direction
				
				local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
				if poi_settings_playlist_is_wheel then
					while i > MainWheelSize do i = i - MainWheelSize end
					while i < 1 do i = i + MainWheelSize end
				else
					-- literally do nothing
				end

				-- If it's an edge item, update text. Edge items should never tween
				if i == 2 or i == MainWheelSize - 1 then
					self:GetChild("Text"):settext(GroupsList[MainTargets[i]].Name)
				elseif tween then
					self:easeoutexpo(0.4)
				end
				
				-- Animate!
				self:xy(xpos + displace, PlaylistWheel_Y)
			end,
			
			Def.Banner {
				Name="PlaylistBanner",
				OnCommand=function(self) self:playcommand("Refresh") end,
				RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
			
				RefreshCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha((IsFocusedMain or i == MainWheelCenter) and 1 or 0.09)
				end,
			},
			
			Def.Sprite {
				Name="PlaylistFrame",
				Texture=THEME:GetPathG("", "MusicWheel/GroupFrame"),
				InitCommand=function(self)
					self:zoom(1.75):visible(false)
				end,
				OnCommand=function(self) self:playcommand("Refresh") end,
				RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
			
				RefreshCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha((IsFocusedMain or i == MainWheelCenter) and 1 or 0.09)
				end,
			},
			
			Def.BitmapText {
				Name="Text",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:zoom(0.75):skewx(-0.1):diffusetopedge(0.95,0.95,0.95,0.8):shadowlength(1.5)
					:maxwidth(MainWheelSpacing / self:GetZoom())
					:diffusealpha(0) -- disabling it
				end,
				
				OnCommand=function(self) self:playcommand("Refresh") end,
				RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
				
				RefreshCommand=function(self)
					--self:finishtweening():easeoutexpo(0.4):diffusealpha((IsFocusedMain or i == MainWheelCenter) and 1 or 0.2)
					self:finishtweening():easeoutexpo(0.4):diffusealpha((IsFocusedMain or i == MainWheelCenter) and 0 or 0)  -- disabling it
				end,
			}
		}
	end

	-- Second wheel will be responsible for the sub groups
	for i = 1, SubWheelSize do
		t[#t+1] = Def.ActorFrame{
			OnCommand=function(self)
				-- Clear all banners before redrawing them
				self:GetChild("Banner"):visible(false)
				UpdateBanner(self:GetChild("Banner"), GroupsList[CurMainIndex].SubGroups[SubTargets[i]].Banner)
				self:GetChild("GroupInfo"):playcommand("Refresh")
				self:GetChild(""):GetChild("Index"):playcommand("Refresh")
				
				-- Proceed as original code
				if CurMainIndex == OrigGroupIndex then
					self:GetChild("Banner"):visible(true)
					UpdateBanner(self:GetChild("Banner"), GroupsList[CurMainIndex].SubGroups[SubTargets[i]].Banner)
				else
					self:GetChild("Banner"):visible(false)
				end
				
				self:GetChild("GroupInfo"):playcommand("Refresh")
				self:GetChild(""):GetChild("Index"):playcommand("Refresh")
				
				-- Ensure the wheel is highlighted or not at the beginning
				self:diffusealpha(IsFocusedMain and 0.2 or 1)
				
				-- Set initial position, Direction = 0 means it won't tween
				self:playcommand("ScrollSub", {Direction = 0})
			end,
			
			-- This is so that whenever the main wheel scrolls all the bottom items can update as well.
			RefreshSubMessageCommand=function(self, params)
				-- Clear all banners before redrawing them
				self:GetChild("Banner"):visible(false)
				UpdateBanner(self:GetChild("Banner"), GroupsList[CurMainIndex].SubGroups[SubTargets[i]].Banner)
				self:GetChild("GroupInfo"):playcommand("Refresh")
				self:GetChild(""):GetChild("Index"):playcommand("Refresh")
				
				-- Proceed as original code
				self:playcommand("On") 
			end,
			
			RefreshHighlightMessageCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha(IsFocusedMain and 0.09 or 1)
			end,

			ScrollSubMessageCommand=function(self, params)
				self:stoptweening()
				
				-- Calculate position
				local xpos = SCREEN_CENTER_X + (i - SubWheelCenter) * SubWheelSpacing

				-- Calculate displacement based on input
				local displace = -params.Direction * SubWheelSpacing

				-- Only tween if a direction was specified
				local tween = params and params.Direction and math.abs(params.Direction) > 0
				
				-- Adjust and wrap actor index
				i = i - params.Direction
				
				local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
				if poi_settings_playlist_is_wheel then
					while i > SubWheelSize do i = i - SubWheelSize end
					while i < 1 do i = i + SubWheelSize end
				else
					-- literally do nothing
				end

				-- Clear all banners before redrawing them
				self:GetChild("Banner"):visible(false)
				UpdateBanner(self:GetChild("Banner"), GroupsList[CurMainIndex].SubGroups[SubTargets[i]].Banner)
				self:GetChild("GroupInfo"):playcommand("Refresh")
				self:GetChild(""):GetChild("Index"):playcommand("Refresh")
				
				-- Proceed as original code
				-- updates sublist banners
				self:GetChild("Banner"):visible(true)
				UpdateBanner(self:GetChild("Banner"), GroupsList[CurMainIndex].SubGroups[SubTargets[i]].Banner)
				
				-- Update edge items with new info, they should also never tween
				if i == 2 or i == SubWheelSize - 1 then
					self:GetChild("Banner"):visible(false)					
					self:GetChild("GroupInfo"):playcommand("Refresh")
					self:GetChild(""):GetChild("Index"):playcommand("Refresh")
				elseif tween then
					self:easeoutexpo(0.4)
				end
				
				self:GetChild("Highlight"):playcommand("Refresh")

				-- Animate!
				self:xy(xpos + displace, SublistWheel_Y)
				self:rotationy((SCREEN_CENTER_X - xpos - displace) * -WheelRotation)				
				self:z(-math.abs(SCREEN_CENTER_X - xpos - displace) * curvature)
				end,
			
			Def.Sprite {
				Name="Highlight",
				Texture=THEME:GetPathG("", "MusicWheel/FrameHighlight"),
				RefreshCommand=function(self)
					--self:stoptweening():easeoutexpo(0.4):diffusealpha(i == SubWheelCenter and 1 or 0)
					self:stoptweening():easeoutexpo(0.4):diffusealpha(0) -- disabling
				end
			},
			
			Def.Sprite {
				Texture=THEME:GetPathG("", "MusicWheel/GradientBanner"),
				InitCommand=function(self) self:scaletoclipped(WheelItem.Width, WheelItem.Height):diffusealpha(0) end -- disabling
			},
			
			Def.Banner {
				Name="Banner",
			},

			Def.Sprite {
				Texture=THEME:GetPathG("", "MusicWheel/GroupFrame"),
				InitCommand=function(self) self:diffusealpha(0) end -- disabling
			},
			
			Def.ActorFrame {
				Def.Quad {
					InitCommand=function(self)
						self:zoomto(60, 18):addy(-50)
						:diffuse(0,0,0,0.6)
						:fadeleft(0.3):faderight(0.3):diffusealpha(0) -- disabled
					end
				},

				Def.BitmapText {
					Name="Index",
					Font="Montserrat semibold 40px",
					InitCommand=function(self)
						self:addy(-50):zoom(0.4):skewx(-0.1):diffusetopedge(0.95,0.95,0.95,0.8):shadowlength(1.5):diffusealpha(0) -- disabled
					end,
					RefreshCommand=function(self, params) self:settext(SubTargets[i]) end
				}
			},
			
			Def.BitmapText {
				Name="GroupInfo",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:y(CurMainIndex == OrigGroupIndex and 64 or -54):zoom(0.5):skewx(-0.1):diffusetopedge(0.95,0.95,0.95,0.8):shadowlength(1.5)
					:maxwidth(420):vertalign(0):wrapwidthpixels(420):vertspacing(-16)
					:diffusealpha(0) -- disabling
				end,
				RefreshCommand=function(self, params) 
					self:settext(GroupsList[CurMainIndex].SubGroups[SubTargets[i]].Name) 
					:y(CurMainIndex == OrigGroupIndex and 64 or -54)
				end
			}
		}
	end

	-- Permanent labels
	t[#t+1] = Def.ActorFrame {
		Def.Quad {
			InitCommand=function(self)
				self:zoomto(1080, 24)
				:diffuse(color("#1d1d1d")):diffusebottomedge(color("#7b7b7b"))
				:xy(SCREEN_CENTER_X, PlaylistWheel_Y - 134)
			end,
			
			OnCommand=function(self) self:playcommand("Refresh") end,
			RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
			
			RefreshCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha(IsFocusedMain and 1 or 0.09)
			end,
		},
		
		Def.BitmapText {
			Font="Montserrat semibold 20px",
			Name="PlaylistLabel",
			Text="Playlists",
			InitCommand=function(self)
				self:diffusealpha(1)
				:xy(SCREEN_CENTER_X, PlaylistWheel_Y - 134)
			end,
			RefreshHighlightMessageCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha((IsFocusedMain or i == MainWheelCenter) and 1 or 0.09)
			end,
		},
		
		Def.Quad {
			InitCommand=function(self)
				self:zoomto(1080, 24)
				:diffuse(color("#1d1d1d")):diffusebottomedge(color("#7b7b7b"))
				:xy(SCREEN_CENTER_X, SublistWheel_Y - 106)
			end,
			
			OnCommand=function(self) self:playcommand("Refresh") end,
			RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
			
			RefreshCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha(IsFocusedMain and 0.09 or 1)
			end,
		},
		Def.BitmapText {
			Font="Montserrat semibold 20px",
			Name="SublistLabel",
			Text="Sublists",
			InitCommand=function(self)
				self:diffusealpha(1)
				:xy(SCREEN_CENTER_X, SublistWheel_Y - 106)
			end,
			RefreshHighlightMessageCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha(IsFocusedMain and 0.09 or 1)
			end,
		},
	}


	return t

end