-- SAFECHECK - GENERATES A GLOBAL VARIABLE GroupsList IF IT DOESN'T EXIST ALREADY
if next(GroupsList) == nil then
	AssembleGroupSorting_POI()
    UpdateGroupSorting_POI()

    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible, halting music wheel!")
        return Def.Actor {}
    end
end

-- SAFECHECK - IF NO SONGS DON'T LOAD ANYTHING
if SONGMAN:GetNumSongs() == 0 then
    return Def.Actor {}
end

-- DECLARING SOME LEVERS AND VARIABLES
local MainWheelSize = 70
local MainWheelCenter = math.ceil( MainWheelSize * 0.5 )
local MainWheelSpacing = 180 + 280
local WheelItem = { Width = 212, Height = 120 }

local ScreenSelectMusic

local IsOptionsList = { PLAYER_1 = false, PLAYER_2 = false }
local IsSelectingGroup = false
local IsBusy = false

local MainTargets = {}

-- DECLARING USEFUL FUNCTIONS
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

function UpdateBanner(self, Banner)
	if Banner == "" then Banner = THEME:GetPathG("Common fallback", "banner") end
	self:Load(Banner):scaletofit(-WheelItem.Width / 2, -WheelItem.Height / 2, WheelItem.Width / 2, WheelItem.Height / 2)
end

-- DECLARING INPUT HANDLER
local function InputHandler(event)
	local pn = event.PlayerNumber
	if not pn then return end
	
	-- Don't want to move when releasing the button
	if event.type == "InputEventType_Release" then
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
				CurPlaylistIndex = CurPlaylistIndex - 1
				if CurPlaylistIndex < 1 then CurPlaylistIndex = #GroupsList end
				UpdateMainItemTargets(CurPlaylistIndex)
				MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
			else
				if CurPlaylistIndex > 1 then
					CurPlaylistIndex = CurPlaylistIndex - 1
					UpdateMainItemTargets(CurPlaylistIndex)
					MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
				end
			end
			
		elseif button == "Right" or button == "MenuRight" or button == "DownRight" then

			local poi_settings_playlist_is_wheel = LoadModule("Config.Load.lua")("POISettingsPlaylistIsWheel", "Save/OutFoxPrefs.ini") or false
			if poi_settings_playlist_is_wheel then
				CurPlaylistIndex = CurPlaylistIndex + 1
				if CurPlaylistIndex > #GroupsList then CurPlaylistIndex = 1 end
				UpdateMainItemTargets(CurPlaylistIndex)
				MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
			else
				if CurPlaylistIndex < #GroupsList then
					CurPlaylistIndex = CurPlaylistIndex + 1
					UpdateMainItemTargets(CurPlaylistIndex)
					MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
				end
			end
			
		elseif button == "Start" or button == "MenuStart" or button == "Center" then
			
			if CurPlaylistIndex == LastGroupMainIndex then
				MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = true })
			else -- this means, if the group was actually changed, instead of just selected the same as previously
				GroupIndex = CurPlaylistIndex
				LastGroupMainIndex = CurPlaylistIndex
				LoadModule("Config.Save.lua")("GroupMainIndex", LastGroupMainIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
				
				SongIndex = GroupsList[CurPlaylistIndex].StartingPoint
				LastSongIndex = GroupsList[CurPlaylistIndex].StartingPoint
				LoadModule("Config.Save.lua")("SongIndex", LastSongIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
				
				MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = false })
			end
			
		elseif button == "UpRight" or button == "UpLeft" or button == "Up" or button == "MenuUp" then
			MESSAGEMAN:Broadcast("RefreshHighlight")
		end
	end
end

-- OPERATIONS
local t = Def.ActorFrame {
	InitCommand=function(self)
		self:fov(90)
		self:SetDrawByZPosition(true)
		self:vanishpoint(SCREEN_CENTER_X, SCREEN_CENTER_Y + 40)
		self:diffusealpha(0)

		UpdateMainItemTargets(CurPlaylistIndex)
	end,

	OnCommand=function(self)
		ScreenSelectMusic = SCREENMAN:GetTopScreen()
		ScreenSelectMusic:AddInputCallback(InputHandler)
	end,
	
	SongChosenMessageCommand=function(self)
		self:queuecommand("Busy")
	end,
	SongUnchosenMessageCommand=function(self)
		self:sleep(0.01):queuecommand("NotBusy")
	end,
	
	OptionsListOpenedMessageCommand=function(self, params)
		IsOptionsList[params.Player] = true
	end,
	OptionsListClosedMessageCommand=function(self, params)
		IsOptionsList[params.Player] = false
	end,

	CodeMessageCommand=function(self, params)
		if params.Name == "GroupSelectCombo" then
			if not IsBusy and not IsOptionsList[PLAYER_1] and not IsOptionsList[PLAYER_2] then
				MESSAGEMAN:Broadcast("OpenGroupWheel")
				self:stoptweening():sleep(0.01):queuecommand("OpenGroup"):easeoutexpo(1):diffusealpha(1)
			end
		end
	end,
	
	BusyCommand=function(self)
		IsBusy = true
	end,
	NotBusyCommand=function(self)
		IsBusy = false
	end,
	
	OpenGroupCommand=function(self)
		IsSelectingGroup = true
	end,
	CloseGroupCommand=function(self)
		IsSelectingGroup = false
	end,

	OpenGroupWheelMessageCommand=function(self)
		self:stoptweening():easeoutexpo(0.5):diffusealpha(1)
	end,
	CloseGroupWheelMessageCommand=function(self, params)
		self:stoptweening():easeoutexpo(1):diffusealpha(0)

		IsSelectingGroup = false
	end,

	-- sounds
	Def.Sound {
		File=THEME:GetPathS("MusicWheel", "change"),
		IsAction=true,
		ScrollMainMessageCommand=function(self)
			self:play()
		end,
	},
	Def.Sound {
		File=THEME:GetPathS("", "OpenCommandWindow"),
		OpenGroupWheelMessageCommand=function(self)
			if IsSelectingGroup == false then self:play() end
		end,
	},
	Def.Sound {
		File=THEME:GetPathS("", "CloseCommandWindow"),
		IsAction=true,
		CloseGroupWheelMessageCommand=function(self, params)
			if params.Silent == false then
				self:play()
			end
		end,
	},

	-- entire background
	Def.Quad {
		InitCommand=function(self)
			self:CenterX()
			self:y(-140)
			self:zoomto(1272, 550)
			self:align(0.5,0)
			self:diffuse(Color.Black)
			self:diffusealpha(0.4)
		end,
	},
}

-- The Wheel: originally made by Luizsan
for i = 1, MainWheelSize do
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self)
			self:y(-159)
		end,

		OnCommand=function(self)
			-- Set initial position, Direction = 0 means it won't tween
			self:playcommand("ScrollMain", {Direction = 0})
			
			-- updates playlist banner pic								
			if GroupsList[MainTargets[i]].Banner == "" then
				GroupsList[MainTargets[i]].Banner = THEME:GetPathG("Common fallback", "banner")
			end
			self:GetChild("PlaylistBanner"):visible(true)
			self:GetChild("PlaylistBanner"):Load(GroupsList[MainTargets[i]].Banner):zoom(0.23)
		end,

		OpenGroupWheelMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(1)

			if i ~= MainWheelCenter then self:diffusealpha(0) end
		end,
		CloseGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(1):diffusealpha(0)
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
				self:easeoutexpo(1)
			end

			-- this wheel only displays the center item
			if i == MainWheelCenter then self:diffusealpha(1)
			else self:diffusealpha(0) end
			
			-- Animate!
			self:x(xpos + displace)
		end,
		
		Def.Banner {
			Name="PlaylistBanner",
			OnCommand=function(self) self:playcommand("Refresh") end,
			RefreshHighlightMessageCommand=function(self) self:playcommand("Refresh") end,
		
			RefreshCommand=function(self)
			self:finishtweening():easeoutexpo(0.4):diffusealpha(1)
			end,
		},

		Def.BitmapText { Name="PlaylistName",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:y(170)
				self:zoom(1.2)
				self:shadowlength(2)
				self:skewx(-0)
				self:settext(GroupsList[CurPlaylistIndex].Name)
				self:queuecommand('Refresh')
			end,
			ScrollMainMessageCommand=function(self)
				self:queuecommand('Refresh')
			end,
			RefreshCommand=function(self)
				self:settext(GroupsList[CurPlaylistIndex].Name)
			end
		},

		Def.BitmapText { Name="PlaylistDescription",
			Font="Montserrat normal 20px",
			InitCommand=function(self)
				self:y(220)
				self:zoom(1)
				self:shadowlength(1)
				self:align(0.5,0)
				self:maxwidth(1262)
				self:settext(GroupsList[CurPlaylistIndex].Description)
				self:queuecommand('Refresh')
			end,
			ScrollMainMessageCommand=function(self)
				self:queuecommand('Refresh')
			end,
			RefreshCommand=function(self)
				self:settext(GroupsList[CurPlaylistIndex].Description)
			end
		},
	}
end

return t