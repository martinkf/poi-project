local MainWheelSize = 70
local MainWheelCenter = math.ceil( MainWheelSize * 0.5 )
local MainWheelSpacing = 180 + 280
local WheelItem = { Width = 212, Height = 120 }

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

-- So that we can grab the Cur screen and use it outside an actor
local ScreenSelectMusic

-- Used for quitting the game
local IsHome = GAMESTATE:GetCoinMode() == "CoinMode_Home"
local IsEvent = GAMESTATE:IsEventMode()
local TickCount = 0 -- Used for InputEventType_Repeat

local IsOptionsList = { PLAYER_1 = false, PLAYER_2 = false }
local IsSelectingGroup = false
local IsBusy = false

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
if GroupsList[LastGroupMainIndex].Songs == nil then
    LastSongIndex = 1
    Warn("ScreenSelectMusicFull overlay / GroupSelect.lua: LastSongIndex no longer present, reset performed")
end

-- Create the variables necessary for both wheels
local CurMainIndex = LastGroupMainIndex > 0 and LastGroupMainIndex or 1
local CurSubIndex = LastGroupSubIndex > 0 and LastGroupSubIndex or 1
local MainTargets = {}

-- This is to determine where are the original groups located
-- TODO: Not hardcode this
local OrigGroupIndex = 2

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

				local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
				if poi_settings_playlist_is_wheel then
					CurMainIndex = CurMainIndex - 1
					if CurMainIndex < 1 then CurMainIndex = #GroupsList end
					UpdateMainItemTargets(CurMainIndex)
					MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
					MESSAGEMAN:Broadcast("RefreshSub")
				else
					if CurMainIndex > 1 then
						CurMainIndex = CurMainIndex - 1
						UpdateMainItemTargets(CurMainIndex)
						MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
						MESSAGEMAN:Broadcast("RefreshSub")
					end
				end
				
			elseif button == "Right" or button == "MenuRight" or button == "DownRight" then

				local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
				if poi_settings_playlist_is_wheel then
					CurMainIndex = CurMainIndex + 1
					if CurMainIndex > #GroupsList then CurMainIndex = 1 end
					UpdateMainItemTargets(CurMainIndex)
					MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
					MESSAGEMAN:Broadcast("RefreshSub")
				else
					if CurMainIndex < #GroupsList then
						CurMainIndex = CurMainIndex + 1
						UpdateMainItemTargets(CurMainIndex)
						MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
						MESSAGEMAN:Broadcast("RefreshSub")
					end
				end
				
			elseif button == "Start" or button == "MenuStart" or button == "Center" then
				
				if CurMainIndex == LastGroupMainIndex then
					MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = true })
				else
					GroupIndex = CurMainIndex
					
					-- Save this for later
					LastGroupMainIndex = CurMainIndex
					
					LoadModule("Config.Save.lua")("GroupMainIndex", LastGroupMainIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
					
					MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = false })
				end
				
			elseif button == "UpRight" or button == "UpLeft" or button == "Up" or button == "MenuUp" then				
				MESSAGEMAN:Broadcast("RefreshHighlight")
			end
		end
	end

	local t = Def.ActorFrame {
		InitCommand=function(self)
			self:fov(90):SetDrawByZPosition(true)
			:vanishpoint(SCREEN_CENTER_X, SCREEN_CENTER_Y + 40):diffusealpha(0)
			UpdateMainItemTargets(CurMainIndex)
		end,

		OnCommand=function(self)
			ScreenSelectMusic = SCREENMAN:GetTopScreen()
			ScreenSelectMusic:AddInputCallback(InputHandler)
		end,
		
		SongChosenMessageCommand=function(self) self:queuecommand("Busy") end,
		SongUnchosenMessageCommand=function(self) self:sleep(0.01):queuecommand("NotBusy") end,
		
		OptionsListOpenedMessageCommand=function(self, params) IsOptionsList[params.Player] = true end,
		OptionsListClosedMessageCommand=function(self, params) IsOptionsList[params.Player] = false end,

		CodeMessageCommand=function(self, params)
			if params.Name == "GroupSelectCombo" then
				if not IsBusy and not IsOptionsList[PLAYER_1] and not IsOptionsList[PLAYER_2] then
					MESSAGEMAN:Broadcast("OpenGroupWheel")
					self:stoptweening():sleep(0.01):queuecommand("OpenGroup"):easeoutexpo(1):diffusealpha(1)
				end
			elseif params.Name == "GroupSelectPrev" then
				if not IsBusy and not IsOptionsList[PLAYER_1] and not IsOptionsList[PLAYER_2] then

					-- WIP

					MESSAGEMAN:Broadcast("OpenGroupWheel")
					self:stoptweening():sleep(0.01):queuecommand("OpenGroup"):easeoutexpo(1):diffusealpha(1)
				end
			elseif params.Name == "GroupSelectNext" then
				if not IsBusy and not IsOptionsList[PLAYER_1] and not IsOptionsList[PLAYER_2] then

					-- WIP

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
		},

		Def.Sound {
			File=THEME:GetPathS("Common", "Start"),
			IsAction=true,
			CloseGroupWheelMessageCommand=function(self)
				--self:play()
			end
		},
	}

	-- The Wheel: originally made by Luizsan
	for i = 1, MainWheelSize do
		t[#t+1] = Def.ActorFrame{
			OnCommand=function(self)
				-- Set initial position, Direction = 0 means it won't tween
				self:playcommand("ScrollMain", {Direction = 0})
				
				-- updates playlist banner pic								
				if GroupsList[MainTargets[i]].Banner == "" then
					GroupsList[MainTargets[i]].Banner = THEME:GetPathG("Common fallback", "banner")
				end
				self:GetChild("PlaylistBanner"):visible(true)
				self:GetChild("PlaylistBanner"):Load(GroupsList[MainTargets[i]].Banner):zoom(0.166)
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
					--donothing
				elseif tween then
					self:easeoutexpo(0.4)
				end
				
				-- Animate!
				self:xy(xpos + displace, SCREEN_CENTER_Y)
			end,
			
			Def.Banner {
				Name="PlaylistBanner",
				OnCommand=function(self) self:playcommand("Refresh") end,
				RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
			
				RefreshCommand=function(self)
				self:finishtweening():easeoutexpo(0.4):diffusealpha(1)
				end,
			},
		}
	end

	return t

end