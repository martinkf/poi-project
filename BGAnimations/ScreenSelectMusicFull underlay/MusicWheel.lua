-- SAFECHECK - GENERATES A GLOBAL VARIABLE GroupsList IF IT DOESN'T EXIST ALREADY
if next(GroupsList) == nil then
	Trace("Running AssembleGroupSorting_POI from MusicWheel.lua now")
	AssembleGroupSorting_POI()
	Trace("Running UpdateGroupSorting_POI from MusicWheel.lua now")
    UpdateGroupSorting_POI()

    if next(GroupsList) == nil then
        Warn("Groups list is currently inaccessible!")
        return Def.Actor {}
    end
end

-- DECLARING SOME LEVERS AND VARIABLES
local SongWheel_y = 182

local WheelSize = 11
local WheelSizeHelper = 5
local WheelCenter = math.ceil( WheelSize * 0.5 )
local WheelItem = { Width = 208, Height = 117 }

local curvature = 196
local fieldOfView = 169
local radius = 14630
local theta_step = 0.0147
local focalLength = 5000
local verticalCurve = 0
local maxVisibleAngle = math.pi * 0.6

local indexIndicator_baseX = 640
local indexIndicator_y = 94
local indexIndicator_range = 186

local IsBusy = false

-- DECLARING MORE VARIABLES - WE WANT THE MUSICWHEEL TO ALWAYS START AT PIU NX ARCADE STATION AT WITCH DOCTOR #1 IN STAGE 1
if GAMESTATE:GetCurrentStageIndex() == 0 then --this means this is stage 1, we just came from the select profile screen
	LastGroupMainIndex = 5
	LastSongIndex = 2
else --this means a song has been played and we're back to the select song screen
	LastGroupMainIndex = tonumber(LoadModule("Config.Load.lua")("GroupMainIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
	LastSongIndex = tonumber(LoadModule("Config.Load.lua")("SongIndex", CheckIfUserOrMachineProfile(string.sub(GAMESTATE:GetMasterPlayerNumber(),-1)-1).."/OutFoxPrefs.ini")) or 1
end
CurPlaylistIndex = LastGroupMainIndex
GroupIndex = LastGroupMainIndex
local GroupMainIndex = LastGroupMainIndex
SongIndex = LastSongIndex

-- DECLARING MORE VARIABLES - DEFAULT IS TO START AT ALL FOR NOW
Targets = {}
Songs = GroupsList[GroupMainIndex].Songs

-- DECLARING USEFUL FUNCTIONS
local function UpdateItemTargets(val)
    for i = 1, WheelSize do
        Targets[i] = val + i - WheelCenter
		while Targets[i] > #Songs do Targets[i] = Targets[i] - #Songs end
		while Targets[i] < 1 do Targets[i] = Targets[i] + #Songs end
    end
end

function MusicWheelGoesTo(input_index)
	-- Clamp or wrap around index to valid range
	if not Songs or #Songs == 0 then return end
	
	-- wrap around behavior
		while input_index > #Songs do input_index = input_index - #Songs end
		while input_index < 1 do input_index = input_index + #Songs end
	
	-- Apply the new index logically
	SongIndex = input_index
	LastSongIndex = SongIndex

	-- Update current song (no animation)
	local song = Songs[SongIndex]
	if song then
		GAMESTATE:SetCurrentSong(song)
		MESSAGEMAN:Broadcast("CurrentSongChanged")
	end

	-- Update mapping and visuals instantly
	UpdateItemTargets(SongIndex)
	MESSAGEMAN:Broadcast("ForceUpdate", { Duration = 0 })
end

local function UpdateBanner(self, Song)
    self:LoadFromSongBanner(Song):scaletoclipped(WheelItem.Width, WheelItem.Height)
end

local function UpdateBannerTwo(self, Song)
    self:LoadFromSongBanner(Song):zoomtoheight_POI(WheelItem.Height)
end

function GetCurrentSongIndex()
    return SongIndex
end

-- DECLARING INPUT HANDLER
local function InputHandler(event)
	local pn = event.PlayerNumber
	if not pn then return end

	if event.type == "InputEventType_Release" then
		HeldButton = nil
		HoldStartTime = nil
		return
	end

	local button = event.GameButton

	if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
	if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

	-- Detectar se o botão está sendo segurado
	if button == "Left" or button == "MenuLeft" or button == "DownLeft"
	or button == "Right" or button == "MenuRight" or button == "DownRight" then
		if not HoldStartTime or HeldButton ~= button then
			HoldStartTime = GetTimeSinceStart()
			HeldButton = button
		end
	end

	if not IsBusy then
		-- duração base e limites
		local base_duration = 0.20
		local min_duration = 0.0
		local scroll_duration = base_duration

		-- cálculo da aceleração
		if HoldStartTime then
			local held_time = GetTimeSinceStart() - HoldStartTime
			if held_time >= 2 then
				-- velocidade máxima
				scroll_duration = min_duration
			end
		end

		-- === Lógica de Scroll padrão ===
		if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
			if IsBusy then return end
			SongIndex = SongIndex - 1
			if SongIndex < 1 then SongIndex = #Songs end
			
			GAMESTATE:SetCurrentSong(Songs[SongIndex])
			MESSAGEMAN:Broadcast("Scroll", { Direction = -1, OffsetFrom = 0, OffsetTo = -1, Duration = scroll_duration })
			IsBusy = true

		elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
			if IsBusy then return end
			SongIndex = SongIndex + 1
			if SongIndex > #Songs then SongIndex = 1 end
			
			GAMESTATE:SetCurrentSong(Songs[SongIndex])
			MESSAGEMAN:Broadcast("Scroll", { Direction = 1, OffsetFrom = 0, OffsetTo = 1, Duration = scroll_duration })
			IsBusy = true

		elseif button == "Start" or button == "MenuStart" or button == "Center" then
			LastSongIndex = SongIndex
			LoadModule("Config.Save.lua")("SongIndex", LastSongIndex, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")
			MESSAGEMAN:Broadcast("MusicWheelStart")

		elseif button == "Back" then
			SCREENMAN:GetTopScreen():Cancel()
		end
	end

	MESSAGEMAN:Broadcast("UpdateMusic")
end

-- OPERATIONS
local t = Def.ActorFrame {
	InitCommand=function(self)
		self:fov(fieldOfView)
		self:SetDrawByZPosition(false)
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

	-- busy when choosing charts instead of songs
	SongChosenMessageCommand=function(self)
		self:stoptweening():easeoutexpo(1):playcommand("Busy")
	end,
	SongUnchosenMessageCommand=function(self)
		self:stoptweening():easeoutexpo(0.5):playcommand("NotBusy")
	end,

	-- logic related to the GroupSelect overlay
	OpenGroupWheelMessageCommand=function(self) IsBusy = true end,
	CloseGroupWheelMessageCommand=function(self, params)
		if params.Silent == false then
			-- Grab the new list of songs from the selected group
			Songs = GroupsList[GroupIndex].Songs

			-- Fetches what the "StartingPoint" of this playlist should be
			local thisStartingPoint = tonumber(GroupsList[GroupIndex].StartingPoint)
						
			-- Sets the song in GAMESTATE so everything else can work when ForceUpdate
			GAMESTATE:SetCurrentSong(Songs[thisStartingPoint])
		end

		-- Update wheel yada yada
		UpdateItemTargets(SongIndex)
		MESSAGEMAN:Broadcast("ForceUpdate")
		self:sleep(0.01):queuecommand("NotBusy")
	end,

	-- Root: recebe o Scroll, agenda finalização (swap lógico Targets -> agora que a animação terminou)
	ScrollMessageCommand=function(self,param)
		-- se não tiver duration, finaliza imediatamente
		local dur = (param and param.Duration) or 0
		-- se já houver uma finalização pendente, cancela a anterior e agenda a nova
		self:stoptweening()
		if dur > 0 then
			-- aguarda o tempo da animação, depois finaliza
			self:sleep(dur):queuecommand("FinalizeScroll")
		else
			self:queuecommand("FinalizeScroll")
		end
	end,

	FinalizeScrollCommand=function(self)
		-- Agora que a animação visual terminou: atualizar mapeamento lógico dos slots
		UpdateItemTargets(SongIndex)
		-- Forçar cada slot a recarregar banners e posicionar com Offset 0 (jump final)
		MESSAGEMAN:Broadcast("ForceUpdate", { Duration = 0 })
		-- liberar input
		IsBusy = false
	end,


	-- drawing: sounds
	Def.Actor { Name="Song Preview Player",
		CurrentSongChangedMessageCommand=function(self)
			SOUND:StopMusic()
			self:stoptweening():sleep(0.25):queuecommand("PlayMusic")
		end,
		
		PlayMusicCommand=function(self)
			local Song = GAMESTATE:GetCurrentSong()
			if Song then
				SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(),
				Song:GetSampleLength(), 0, 1, false, false, false, Song:GetTimingData())
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


	-- drawing: index indicators
	Def.Quad { Name="IndexIndicator",
		InitCommand=function(self)
			self:y(indexIndicator_y)
			self:align(0.5,0.5)
			self:diffuse(color("0,0,0,0.4"))

			self:zoomto(26, 12)
			self:x(indexIndicator_baseX)
			self:playcommand("Refresh")
		end,
		ForceUpdateMessageCommand=function(self)
			self:playcommand("Refresh")
		end,
		RefreshCommand=function(self, param)
			-- alters its width depending on the number of songs in the group
			local totalSongsFromGroup = #GroupsList[GroupIndex].AllowedSongs
			local calculatedWidth = indexIndicator_range / totalSongsFromGroup
			local usedWidth
			if calculatedWidth < 26 then
				usedWidth = 26
			else
				usedWidth = calculatedWidth
			end
			self:zoomto(usedWidth, 12)

			-- alters its x position depending on the current songindex
			self:x(indexIndicator_baseX + ((SongIndex - (totalSongsFromGroup + 1) / 2) * calculatedWidth))
		end,
	},

	Def.BitmapText { Name="IndexIndicatorText",
		Font="Montserrat semibold 40px",
		InitCommand=function(self)
			self:y(indexIndicator_y)
			self:zoom(0.3)
			self:align(0.5,0.5)
			self:diffuse(color("1,1,1,0.8"))

			self:settext("???")
			self:x(indexIndicator_baseX)
			self:playcommand("Refresh")
		end,
		
		ForceUpdateMessageCommand=function(self)
			self:playcommand("Refresh")
		end,

		RefreshCommand=function(self,param)
			-- alters some necessary variables depending on the number of songs in the group
			local totalSongsFromGroup = #GroupsList[GroupIndex].AllowedSongs
			local calculatedWidth = indexIndicator_range / totalSongsFromGroup

			-- alters its text depending on the current songindex
			self:settext(SongIndex)

			-- alters its color depending on the song's origin debut version
			self:diffuse(FetchFromSong(Songs[SongIndex], "Song Origin Color"))

			-- alters its x position depending on the current songindex
			self:x(indexIndicator_baseX + ((SongIndex - (totalSongsFromGroup + 1) / 2) * calculatedWidth))
		end,
	},

}

for i = 1, WheelSize do
    local slot = i  -- capture the slot index (important!)
    t[#t+1] = Def.ActorFrame {
        OnCommand=function(self)
            -- Load banner for this slot (use Targets[slot])
            UpdateBanner(self:GetChild("MusicWheelPicture"):GetChild("BannerBG"), Songs[Targets[slot]])
            UpdateBannerTwo(self:GetChild("MusicWheelPicture"):GetChild("BannerTop"), Songs[Targets[slot]])

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("Scroll", {Direction = 0})
        end,
        
        ForceUpdateMessageCommand=function(self)
            -- Load banner for this slot
            UpdateBanner(self:GetChild("MusicWheelPicture"):GetChild("BannerBG"), Songs[Targets[slot]])
            UpdateBannerTwo(self:GetChild("MusicWheelPicture"):GetChild("BannerTop"), Songs[Targets[slot]])

            -- Set initial position, Direction = 0 means it won't tween
            self:playcommand("Scroll", {Direction = 0})
        end,
        
        ScrollMessageCommand=function(self,param)
			self:stoptweening()

			-- parâmetros que já existem no topo; mantive nomes compatíveis
			local dur = (param and param.Duration) or 0
			local offsetFrom = (param and param.OffsetFrom) or 0
			local offsetTo = (param and param.OffsetTo) or 0

			local idx = slot
			-- calcula ângulo relativo aplicando offset visual
			local angle_from = (idx - WheelCenter - offsetFrom) * theta_step
			local angle_to   = (idx - WheelCenter - offsetTo)   * theta_step

			-- função helper que retorna geometria para um ângulo
			local function geom(angle)
				local x_on_cyl = radius * math.sin(angle)
				local z_on_cyl = radius * (1 - math.cos(angle))
				local scale = 1 / (1 + (z_on_cyl / focalLength))
				if scale < 0.15 then scale = 0.15 end
				local rotY = -math.deg(angle)
				local y_off = -math.cos(angle) * verticalCurve
				local visible = math.abs(angle) <= maxVisibleAngle
				return { x = SCREEN_CENTER_X + x_on_cyl, y = SongWheel_y + y_off, z = -z_on_cyl, zoom = scale, rotY = rotY, visible = visible }
			end

			local g_from = geom(angle_from)
			local g_to   = geom(angle_to)

			-- mantemos o banner atual visível DURANTE a animação; quando root finalizar, UpdateItemTargets irá trocar as fontes
			UpdateBanner(self:GetChild("MusicWheelPicture"):GetChild("BannerBG"), Songs[Targets[slot]])
			UpdateBannerTwo(self:GetChild("MusicWheelPicture"):GetChild("BannerTop"), Songs[Targets[slot]])

			-- aplica estado inicial para que a animação seja visível
			self:x(g_from.x):y(g_from.y):z(g_from.z):zoom(g_from.zoom):rotationy(g_from.rotY)
			self:visible(g_from.visible)

			-- sem duração: pula direto pro final
			if dur <= 0 then
				self:x(g_to.x):y(g_to.y):z(g_to.z):zoom(g_to.zoom):rotationy(g_to.rotY)
				self:visible(g_to.visible)

				-- atualiza textos/children imediatamente
				self:GetChild("BGFrame"):playcommand("Refresh")
				self:GetChild("SpecialFrame"):playcommand("Refresh")
				self:GetChild("OriginLabel"):playcommand("Refresh")
				self:GetChild("NameLabel"):playcommand("Refresh")
				self:GetChild("ArtistLabel"):playcommand("Refresh")
				return
			end

			-- realiza tween à geometria final
			self:decelerate(dur)
				:x(g_to.x):y(g_to.y):z(g_to.z):zoom(g_to.zoom):rotationy(g_to.rotY)

			-- depois do tween atualiza filhos (sleep ligeiramente maior para garantir estado final)
			self:sleep(dur + 0.001):queuecommand("RefreshAfterTween")
		end,

		RefreshAfterTweenCommand=function(self)
			self:GetChild("BGFrame"):playcommand("Refresh")
			self:GetChild("SpecialFrame"):playcommand("Refresh")
			self:GetChild("OriginLabel"):playcommand("Refresh")
			self:GetChild("NameLabel"):playcommand("Refresh")
			self:GetChild("ArtistLabel"):playcommand("Refresh")
		end,


		-- drawing!
		Def.Quad { Name="BGFrame",
			InitCommand=function(self)
				self:y(-10)
				self:zoomto(211, 140)
				self:diffuse(color("0,0,0,0.4"))
			end,
			RefreshCommand=function(self, param)
				if i >  WheelCenter+WheelSizeHelper or i <  WheelCenter-WheelSizeHelper then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
		},
		Def.ActorFrame { Name="MusicWheelPicture",
			RefreshCommand=function(self, param)
				--donothing
			end,
			Def.Banner { Name="BannerBG",
				RefreshCommand=function(self, param)
					--donothing
				end,
			},
			Def.Quad { Name="BannerFilter",
				InitCommand=function(self)
					self:y(-0.1)
					self:zoomto(WheelItem.Width, WheelItem.Height)
					self:diffuse(color("0,0,0,0.8"))
				end,
				RefreshCommand=function(self, param)
					--donothing
				end,
			},
			Def.Banner { Name="BannerTop",
				RefreshCommand=function(self, param)
					--donothing
				end,
			},
		},
		Def.ActorFrame { Name="SpecialFrame",
			InitCommand=function(self)
				self:playcommand("Refresh")
			end,
			RefreshCommand=function(self, param)
				self:GetChild("SpecialFrame-filter"):playcommand("Refresh")
				self:GetChild("SpecialFrame-text"):playcommand("Refresh")
				self:queuecommand("StartBlink")
			end,
			StartBlinkCommand=function(self, param)
				self:stoptweening():easeoutexpo(0.5):diffusealpha(1)
				self:sleep(0.5):queuecommand("ContinueBlink")
			end,
			ContinueBlinkCommand=function(self, param)
				self:stoptweening():easeoutexpo(0.5):diffusealpha(0)
				self:sleep(0.5):queuecommand("StartBlink")
			end,
			Def.Quad { Name="SpecialFrame-filter",
				InitCommand=function(self)
					self:y(-0.1)
					self:zoomto(WheelItem.Width, WheelItem.Height)
					self:diffuse(color("0,0,0,0.8"))
					self:playcommand("Refresh")
				end,
				RefreshCommand=function(self, param)
					local value = FetchFromSong(Songs[Targets[i]], "Song Category Color for quads")
					if type(value) == "string" then
						value = color(value)
					end
					if value then
						self:diffuse(value)
					end
				end,
			},
			Def.BitmapText { Name="SpecialFrame-text",
				Font="Montserrat semibold 40px",
				InitCommand=function(self)
					self:addx(0):addy(-4)
					self:zoom(0.8)
					self:shadowlength(3)
					self:align(0.5,0.5)
					self:skewx(-0.3)
					self:playcommand("Refresh")
				end,
				RefreshCommand=function(self, param)
					local value = FetchFromSong(Songs[Targets[i]], "Display-formatted Song Category")
					if value then
						self:settext(value)
					end
					local value2 = FetchFromSong(Songs[Targets[i]], "Song Category Color")
					if type(value2) == "string" then
						value2 = color(value)
					end
					if value2 then
						self:diffuse(value2)
					end
				end,
			},
		},
		Def.BitmapText { Name="OriginLabel",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:addx(0):addy(-70)
				self:zoom(0.4)
				self:shadowlength(1)
				self:align(0.5,0.5)
			end,
			
			RefreshCommand=function(self,param)
				self:diffuse(FetchFromSong(Songs[Targets[i]], "Song Origin Color"))
				self:settext(Songs[Targets[i]]:GetOrigin())

				if i >  WheelCenter+WheelSizeHelper or i <  WheelCenter-WheelSizeHelper then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
		},
		Def.BitmapText { Name="NameLabel",
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:y(SongWheel_y+32)
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
				self:y(SongWheel_y+42)
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
			
			LoopToWhiteThenBackCommand=function(self)
				self:easeoutexpo(0.5):diffuse(Color.White)
				self:queuecommand("SpecialColorLoop")
			end,
			SpecialColorLoopCommand=function(self)
				self:easeoutexpo(0.5):diffuse(FetchFromSong(Songs[Targets[i]], "Song Category Color"))
				self:queuecommand("LoopToWhiteThenBack")
			end,

		},
	
	}

end

return t