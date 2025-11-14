-- LEVERS AND VARIABLES
local choices = {
	{ name="Modo Completo", go="ScreenSelectMusicFull" },
	{ name="Modo Básico",   go="ScreenSelectMusicBasic" }
}
local index = 1

-- INPUT HANDLER
local function InputHandler(event)
	local pn = event.PlayerNumber
    if not pn then return end

    -- Don't want to move when releasing the button
    if event.type == "InputEventType_Release" then return end

    local button = event.button
    if button == "Start" or button == "Center" then
        --MESSAGEMAN:Broadcast("StartButton")
        SCREENMAN:GetTopScreen():SetNextScreenName(choices[index].go)
		SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")

    elseif button == "Up" or button == "MenuUp" or button == "MenuLeft" or button == "DownLeft" then
        index = index - 1
		if index < 1 then index = #choices end
		MESSAGEMAN:Broadcast("UpdateGameModeCursor")

    elseif button == "Down" or button == "MenuDown" or button == "MenuRight" or button == "DownRight" then
        index = index + 1
		if index > #choices then index = 1 end
		MESSAGEMAN:Broadcast("UpdateGameModeCursor")

    elseif button == "Back" then
        SCREENMAN:GetTopScreen():SetPrevScreenName("ScreenTitleMenu")
		SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToPrevScreen")
    end
end

-- OPERATIONS
local t = Def.ActorFrame {
	-- Entrada da tela
	OnCommand=function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
		index = 1
		MESSAGEMAN:Broadcast("UpdateGameModeCursor")
	end,
}

-- itens do menu
for i,entry in ipairs(choices) do
	t[#t+1] = Def.ActorFrame {
		InitCommand=function(self)
		end,
		
		Def.BitmapText {
			Font="Common Normal",
			InitCommand=function(self)
				self:x(SCREEN_CENTER_X)
				self:y(SCREEN_CENTER_Y + (i-1)*40)
				self:settext(entry.name)
				self:zoom(0.7)
			end,
			UpdateGameModeCursorMessageCommand=function(self)
				if index == i then
					self:diffuse(Color.Yellow)
				else
					self:diffuse(Color.White)
				end
			end
		}
	}
end

return t