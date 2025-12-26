-- SAFECHECK - GENERATES A GLOBAL VARIABLE PlaylistsArray IF IT DOESN'T EXIST ALREADY
if next(PlaylistsArray) == nil then
	Trace("Running AssembleGroupSorting_POI from GroupSelect.lua now")
	AssembleGroupSorting_POI()
	Trace("Running UpdateGroupSorting_POI from GroupSelect.lua now")
    UpdateGroupSorting_POI()

    if next(PlaylistsArray) == nil then
        Warn("Groups list (PlaylistsArray) is currently inaccessible!")
        return Def.Actor {}
    end
end

-- SAFECHECK - IF NO SONGS DON'T LOAD ANYTHING
if SONGMAN:GetNumSongs() == 0 then
    return Def.Actor {}
end

-- DECLARING SOME LEVERS AND VARIABLES
local WheelSize = 31
local WheelCenter = math.ceil( WheelSize * 0.5 )
local WheelSpacing = 112
local WheelSpacingMain = 224
local WheelItem = { Width = 222, Height = 124 }

local ScreenSelectMusic

local IsOptionsList = { PLAYER_1 = false, PLAYER_2 = false }
local IsSelectingGroup = false
local IsBusy = false

local Targets = {}

-- DECLARING USEFUL FUNCTIONS
local function UpdateMainItemTargets(val)
	for i = 1, WheelSize do
		Targets[i] = val + i - WheelCenter
	end
end

local function UpdateBanner(self, Banner)
	if Banner == "" then Banner = THEME:GetPathG("Common fallback", "banner") end
	self:Load(Banner):scaletofit(-WheelItem.Width / 2, -WheelItem.Height / 2, WheelItem.Width / 2, WheelItem.Height / 2)
end

local function UpdateBannerBig(self, Banner)
	if Banner == "" then Banner = THEME:GetPathG("Common fallback", "banner") end
	self:Load(Banner):scaletofit(-WheelItem.Width , -WheelItem.Height, WheelItem.Width, WheelItem.Height)
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
			
			if CurPlaylistIndex > 1 then
				CurPlaylistIndex = CurPlaylistIndex - 1
				UpdateMainItemTargets(CurPlaylistIndex)
				MESSAGEMAN:Broadcast("ScrollMain", { Direction = -1 })
			end
			
		elseif button == "Right" or button == "MenuRight" or button == "DownRight" then

			if CurPlaylistIndex < #PlaylistsArray then
				CurPlaylistIndex = CurPlaylistIndex + 1
				UpdateMainItemTargets(CurPlaylistIndex)
				MESSAGEMAN:Broadcast("ScrollMain", { Direction = 1 })
			end
			
		elseif button == "Start" or button == "MenuStart" or button == "Center" then
			
			if CurPlaylistIndex == LastPlaylistIndex then
				MESSAGEMAN:Broadcast("CloseGroupWheel", { Silent = true })
			else -- this means, if the group was actually changed, instead of just selected the same as previously
				PlaylistIndex = CurPlaylistIndex
				LastPlaylistIndex = CurPlaylistIndex
				LoadModule("Config.Save.lua")("PlaylistIndex", LastPlaylistIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
				
				local temporaryStartingSublist = PlaylistsArray[CurPlaylistIndex].StartingSublist
				SublistIndex = temporaryStartingSublist
				LastSublistIndex = SublistIndex
				CurSublistIndex = SublistIndex
				LoadModule("Config.Save.lua")("SublistIndex", LastSublistIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")

				SongIndex = PlaylistsArray[CurPlaylistIndex].Sublists[CurSublistIndex].StartingSong
				LastSongIndex = PlaylistsArray[CurPlaylistIndex].Sublists[CurSublistIndex].StartingSong
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

for i = 1, WheelSize do
	local slot = i
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self)
			self:y(-159)
		end,

		OnCommand=function(self)
			-- Set initial position, Direction = 0 means it won't tween
			self:playcommand("ScrollMain", {Direction = 0})
			
			-- updates playlist banner pic
			if slot == WheelCenter then
				UpdateBannerBig(self:GetChild("PlaylistBanner"),PlaylistsArray[Targets[slot]].Banner)
			else
				UpdateBanner(self:GetChild("PlaylistBanner"),PlaylistsArray[Targets[slot]].Banner)
			end
		end,

		OpenGroupWheelMessageCommand=function(self)
			self:stoptweening():easeoutexpo(0.5):diffusealpha(1)
		end,
		CloseGroupWheelMessageCommand=function(self, params)
			self:stoptweening():easeoutexpo(1):diffusealpha(0)
		end,

		ScrollMainMessageCommand=function(self, params)
			self:stoptweening()

			-- Calculate position
			local xpos = SCREEN_CENTER_X + (slot - WheelCenter) * WheelSpacing

			-- Calculate displacement based on input
			local displace = -params.Direction * WheelSpacing

			-- Only tween if a direction was specified
			local tween = params and params.Direction and math.abs(params.Direction) > 0
							
			-- Adjust and wrap actor index
			slot = slot - params.Direction
			
			-- If it's an edge item, update text. Edge items should never tween
			if slot == 2 or slot == WheelSize - 1 then
				--donothing
			elseif tween then
				self:easeoutexpo(1)
			end
			
			-- i wanna see all elements
			self:diffusealpha(1)

			-- centered element needs to be big and adjust Y accordingly
			local ypos
			if slot == WheelCenter then
				UpdateBannerBig(self:GetChild("PlaylistBanner"),PlaylistsArray[Targets[slot]].Banner)
				ypos = -159
			else
				UpdateBanner(self:GetChild("PlaylistBanner"),PlaylistsArray[Targets[slot]].Banner)
				ypos = -76
			end
			
			-- corrects offsets			
			local offsetIndex = slot - WheelCenter
			if offsetIndex ~= 0 then
				local absIndex = math.abs(offsetIndex)
				local extra = 0

				for step = 1, absIndex do
					if step == 1 then
						extra = extra + WheelSpacingMain -- spacing between center and neighbours
					else
						extra = extra + WheelSpacing -- spacing between small items
					end
				end

				if offsetIndex < 0 then
					xpos = xpos - extra
				else
					xpos = xpos + extra
				end
			end

			-- Animate!
			self:x(xpos + displace)
			self:y(ypos)
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

t[#t+1] = Def.ActorFrame {

	Def.BitmapText { Name="PlaylistName",
		Font="Montserrat semibold 40px",
		InitCommand=function(self)
			self:x(SCREEN_CENTER_X)
			self:y(20)
			self:zoom(1.2)
			self:shadowlength(2)
			self:skewx(-0)
			self:settext(PlaylistsArray[CurPlaylistIndex].PlaylistName)
			self:diffusealpha(0)
			self:queuecommand('Refresh')
		end,
		ScrollMainMessageCommand=function(self)
			self:queuecommand('Refresh')
		end,
		RefreshCommand=function(self)
			-- updates the text to match the CurPlaylist
			self:settext(PlaylistsArray[CurPlaylistIndex].PlaylistName)

			-- quick animation when scrolling through playlists
			self:stoptweening():diffusealpha(0):sleep(0.25):easeoutexpo(0.5):diffusealpha(1)
		end
	},

	Def.BitmapText { Name="PlaylistDescription",
		Font="Montserrat normal 20px",
		InitCommand=function(self)
			self:x(SCREEN_CENTER_X)
			self:y(70)
			self:zoom(1)
			self:shadowlength(1)
			self:align(0.5,0)
			self:maxwidth(1262)
			self:settext(PlaylistsArray[CurPlaylistIndex].Description)
			self:queuecommand('Refresh')
		end,
		ScrollMainMessageCommand=function(self)
			self:queuecommand('Refresh')
		end,
		RefreshCommand=function(self)
			-- updates the text to match the CurPlaylist
			self:settext(PlaylistsArray[CurPlaylistIndex].Description)
			
			-- quick animation when scrolling through playlists
			self:stoptweening():diffusealpha(0):sleep(0.25):easeoutexpo(0.5):diffusealpha(1)
		end
	},
	
}

return t