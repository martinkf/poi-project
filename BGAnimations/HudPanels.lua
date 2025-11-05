local topPanel_Y = -8
local amountLivesLeft_X = -88
local amountLivesLeft_Y = 40
local credits_Y = SCREEN_TOP + 8
local credits_size = 0.4
local profileNameBG_X = 572
local profileNameBG_Y = 668+53
local profileNameText_X = 522
local profileNameText_Y = 711
local profilePic_X = 600+4
local profilePic_Y = 637+43+4
local modIcons_X = 96
local modIcons_Y = 45

local t = Def.ActorFrame {
	Def.ActorFrame {
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X, -128)
		end,
		OnCommand=function(self)
			self:easeoutexpo(0.5):xy(SCREEN_CENTER_X, 0)
		end,
		OffCommand=function(self) end,
		
		-- Top panel graphic art (small, black)
		Def.Quad {			
			InitCommand=function(self)				
				self:xy(0, topPanel_Y):setsize(1280, 50):diffuse(color("0,0,0,0.9"))
			end
		},
		
		-- game mode / number of credits / current stage indicator
		Def.BitmapText {
			Font="Montserrat semibold 40px",
			InitCommand=function(self)
				self:xy(0,credits_Y):shadowlength(1):zoom(credits_size):queuecommand('Refresh')
			end,
			
			OnCommand=function(self) self:playcommand('Refresh') end,
			CoinInsertedMessageCommand=function(self) self:playcommand('Refresh') end,
			PlayerJoinedMessageCommand=function(self) self:playcommand('Refresh') end,
			ScreenChangedMessageCommand=function(self) self:playcommand('Refresh') end,
			RefreshCreditTextMessageCommand=function(self) self:playcommand('Refresh') end,

			RefreshCommand=function(self)
				local CoinMode = GAMESTATE:GetCoinMode()
				local EventMode = GAMESTATE:IsEventMode()
					
				if EventMode then
					self:visible(true)
					self:stoptweening()
					self:queuecommand("EventModeThenEventModeExplanation")
				elseif CoinMode == "CoinMode_Home" then
					self:visible(true)
					self:stoptweening()
					if
					SCREENMAN:GetTopScreen():GetName() == "ScreenTitleMenu" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenTitleJoin" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenLogo" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenSelectProfile" then
						self:settext("HOME MODE")
					else
					-- like "ScreenSelectMusicFull" for example
					-- like "ScreenGameplay" for example
					-- like "ScreenEvaluationNormal" for example
						self:queuecommand("HomeModeThenNumberOfStages")
					end
				elseif CoinMode == 'CoinMode_Free' then
					self:visible(true)
					self:stoptweening()
					if
					SCREENMAN:GetTopScreen():GetName() == "ScreenTitleMenu" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenTitleJoin" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenLogo" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenSelectProfile" then
						self:settext("FREE PLAY")
					else
					-- like "ScreenSelectMusicFull" for example
					-- like "ScreenGameplay" for example
					-- like "ScreenEvaluationNormal" for example
						self:queuecommand("FreePlayThenNumberOfStages")
					end
				elseif CoinMode == 'CoinMode_Pay' then
					self:visible(true)
					self:stoptweening()
					if
					SCREENMAN:GetTopScreen():GetName() == "ScreenTitleMenu" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenTitleJoin" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenLogo" or
					SCREENMAN:GetTopScreen():GetName() == "ScreenSelectProfile" then
						local numberofcredits = GAMESTATE:GetCoins()
						local suffix = ""
						if numberofcredits == 1 then suffix = " CREDIT" else suffix = " CREDITS" end
						local CreditText = numberofcredits .. suffix
						self:settext(CreditText)
					else
					-- like "ScreenSelectMusicFull" for example
					-- like "ScreenGameplay" for example
					-- like "ScreenEvaluationNormal" for example
						self:queuecommand("PayModeThenNumberOfStages")
					end
				end
			end,

			EventModeThenEventModeExplanationCommand=function(self)
				self:settext("EVENT MODE")
				self:sleep(2):queuecommand("EventModeExplanationThenEventMode")
			end,
			EventModeExplanationThenEventModeCommand=function(self)
				self:settext("UNLIMITED STAGES, NO PROFILE RECORD-KEEPING")
				self:sleep(2):queuecommand("EventModeThenEventModeExplanation")
			end,

			HomeModeThenNumberOfStagesCommand=function(self)
				self:settext("HOME MODE")
				self:sleep(2):queuecommand("NumberOfStagesThenHomeMode")
			end,
			NumberOfStagesThenHomeModeCommand=function(self)
				local stageNumber = 1
				if SCREENMAN:GetTopScreen():GetName() == "ScreenEvaluationNormal" then
					stageNumber = GAMESTATE:GetCurrentStageIndex()
				else
					stageNumber = GAMESTATE:GetCurrentStageIndex() + 1
				end
				stageNumber = string.format("%02d", stageNumber)

				self:settext("STAGE "..stageNumber)
				self:sleep(2):queuecommand("HomeModeThenNumberOfStages")
			end,

			FreePlayThenNumberOfStagesCommand=function(self)
				self:settext("FREE PLAY")
				self:sleep(2):queuecommand("NumberOfStagesThenFreePlay")
			end,
			NumberOfStagesThenFreePlayCommand=function(self)
				local stageNumber = 1
				if SCREENMAN:GetTopScreen():GetName() == "ScreenEvaluationNormal" then
					stageNumber = GAMESTATE:GetCurrentStageIndex()
				else
					stageNumber = GAMESTATE:GetCurrentStageIndex() + 1
				end
				stageNumber = string.format("%02d", stageNumber)

				self:settext("STAGE "..stageNumber)
				self:sleep(2):queuecommand("FreePlayThenNumberOfStages")
			end,

			PayModeThenNumberOfStagesCommand=function(self)
				local numberofcredits = GAMESTATE:GetCoins()
				local suffix = ""
				if numberofcredits == 1 then suffix = " CREDIT" else suffix = " CREDITS" end
				local CreditText = numberofcredits .. suffix
				self:settext(CreditText)
				self:sleep(2):queuecommand("NumberOfStagesThenPayMode")
			end,
			NumberOfStagesThenPayModeCommand=function(self)
				local stageNumber = 1
				if SCREENMAN:GetTopScreen():GetName() == "ScreenEvaluationNormal" then
					stageNumber = GAMESTATE:GetCurrentStageIndex()
				else
					stageNumber = GAMESTATE:GetCurrentStageIndex() + 1
				end
				stageNumber = string.format("%02d", stageNumber)

				self:settext("STAGE "..stageNumber)
				self:sleep(2):queuecommand("PayModeThenNumberOfStages")
			end,
		},
	}
}

-- Profile info (clones for every active player)
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	if PROFILEMAN:GetProfile(pn) and (PROFILEMAN:IsPersistentProfile(pn) or PROFILEMAN:ProfileWasLoadedFromMemoryCard(pn)) then
		t[#t+1] = Def.ActorFrame {
			Def.ActorFrame {
				InitCommand=function(self) self:y(-128) end,
				OnCommand=function(self) self:easeoutexpo(0.5):y(0) end,
				OffCommand=function(self) end,
				
				-- profile name (text)
				Def.BitmapText {
					Font="Montserrat semibold 40px",
					Text=PROFILEMAN:GetProfile(pn):GetDisplayName(),
					InitCommand=function(self)
						self:xy(SCREEN_CENTER_X + (pn == PLAYER_2 and profileNameText_X or -profileNameText_X), SCREEN_BOTTOM - profileNameText_Y):zoom(credits_size)
						:maxwidth(112 / self:GetZoom()):skewx(-0.2):shadowlength(1)

						if PROFILEMAN:GetProfile(pn):GetDisplayName() == "" then
							self:settext(THEME:GetString("ProfileStats", "No Profile"))
						end
					end
				},
				
				-- player profile pic
				Def.Sprite {
					Texture=LoadModule("Options.GetProfileData.lua")(pn)["Image"],
					InitCommand=function(self)
						self:scaletocover(0, 0, 64, 64)
						:xy(SCREEN_CENTER_X + (pn == PLAYER_2 and profilePic_X or -profilePic_X), SCREEN_BOTTOM - profilePic_Y)
					end
				},
				
				-- mod icons (horizontal - doesn't show up when ScreenGameplay)
				LoadActor("ModIcons.lua", pn) .. {
					InitCommand=function(self)
						self:xy(pn == PLAYER_2 and modIcons_X * 2 or modIcons_X * -2, modIcons_Y)
						:easeoutexpo(0.5):x(pn == PLAYER_2 and SCREEN_RIGHT - modIcons_X or modIcons_X)
						:queuecommand('Refresh')
					end,
					
					RefreshCommand=function(self)
						if SCREENMAN:GetTopScreen():GetName() == "ScreenGameplay" then
							self:visible(false)
						end
					end,
				},
				
				-- mod icons (vertical - only shows up when ScreenGameplay)
				LoadActor("ModIconsVertical.lua", pn) .. {
					InitCommand=function(self)						
						self:xy(pn == PLAYER_2 and (modIcons_X * 2) or (modIcons_X * -2), modIcons_Y+50)
						:easeoutexpo(0.5):x(pn == PLAYER_2 and (SCREEN_RIGHT - modIcons_X + 69) or (modIcons_X - 69))
						:queuecommand('Refresh')
					end,
					
					RefreshCommand=function(self)
						if SCREENMAN:GetTopScreen():GetName() ~= "ScreenGameplay" then
							self:visible(false)
						end
					end,
				},

				-- instructions panel (only shows up when ScreenSelectMusicFull)
				Def.ActorFrame {
					InitCommand=function(self)
						self:xy(pn == PLAYER_2 and (4+864) or (4),72)
						self:visible(false)
						self:queuecommand('Refresh')
					end,

					RefreshCommand=function(self)
						if SCREENMAN:GetTopScreen():GetName() == "ScreenSelectMusicFull" then
							self:visible(true)
						else
							self:visible(false)
						end
					end,
					
					LoadActor("InstructionsOverlay.lua")
				},
			}
		}
	end
end

return t