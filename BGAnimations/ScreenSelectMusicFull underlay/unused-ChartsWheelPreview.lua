local ItemW = 40
local args = {...}
local ItemAmount = args[1]

local FrameX = -(ItemW * ((ItemAmount - 1) / 2))

local ChartArray = nil

--

local t = Def.ActorFrame {
	RefreshCommand=function(self)
		ChartArray = nil



		local ThisSpecificSong = GAMESTATE:GetCurrentSong() -- problem 1, no, it shouldn't always be the current song



		if ThisSpecificSong then
			ChartArray = SongUtil.GetPlayableSteps(ThisSpecificSong)
			
			-- Filter out unwanted charts recursively
			local CurGroupName = GroupsList[LastGroupMainIndex] ~= nil and 
			GroupsList[LastGroupMainIndex].Name or ""
			
			local ShowFilters = {"ShowUCSCharts", "ShowQuestCharts", "ShowHiddenCharts" }
			local ChartFilters = {"UCS", "QUEST", "HIDDEN" }
			local PrevChartArray
			
			for i = 1, 3 do
				if LoadModule("Config.Load.lua")(ShowFilters[i], "Save/OutFoxPrefs.ini") == false then
					-- Only make a copy of the array if an attempt at removal will happen
					PrevChartArray = ShallowCopy(ChartArray)
					
					for j = #ChartArray, 1, -1 do
						if string.find(ToUpper(ChartArray[j]:GetDescription()), ChartFilters[i]) then
							table.remove(ChartArray, j)
						end
					end
					
					if #ChartArray == 0 then ChartArray = ShallowCopy(PrevChartArray) end
				end
			end

			-- Normal chart checks
			for i = #ChartArray, 1, -1 do
				-- Couple and Routine crashes the game :(
				if string.find(ToUpper(ChartArray[i]:GetStepsType()), "ROUTINE") or
					string.find(ToUpper(ChartArray[i]:GetStepsType()), "COUPLE") then
					table.remove(ChartArray, i)
				end
			end

			-- POI - this is where I set up my interference rigging module!
			-- uses the FilterChartFromSublist POI function to filter out the charts that will be displayed.
			-- takes into consideration the current Playlist, the current Sublist, and the current Song being selected (by checking the MusicWheel SongIndex)
			ChartArray = GetAllowedCharts_POI(ChartArray, CurGroupName, GetCurrentSongIndex())
			-- problem 2, nope, my interference rigging module should be different and not that the musicwheel index, maybe?
			
			-- If no charts are left, load all of them again in an attempt to avoid other crashes
			if #ChartArray == 0 then ChartArray = SongUtil.GetPlayableSteps(ThisSpecificSong) end
			table.sort(ChartArray, SortCharts)
		end

		if ChartArray then
			for j=1,ItemAmount do
				local Chart = ChartArray[ j ]
						
				if Chart then

					-- logic related to coloring the BGQuad
					self:GetChild("")[j]:GetChild("BGQuad"):visible(true)
					self:GetChild("")[j]:GetChild("BGQuad"):diffuse(Color.Black):diffusealpha(0.4)

					-- logic related to grabbing the top score and color the quad accordingly
					for k, chart in ipairs(ChartArray) do
						local scoreIndex = nil
						-- Fetch profile scores only if a valid chart is available
						if chart then
							local profile = PROFILEMAN:GetProfile(GAMESTATE:GetEnabledPlayers()[1])
							if profile then
								local scoreList = profile:GetHighScoreList(ThisSpecificSong, chart)
								if scoreList then
									local scores = scoreList:GetHighScores()
									if scores and #scores > 0 then
										scoreIndex = LoadModule("PIU/Score.Grading.lua")(scores[1])
									end
								end
							end
						end
						if scoreIndex then
							self:GetChild("")[k]:GetChild("ColoredQuad"):visible(true)
							self:GetChild("")[k]:GetChild("ColoredQuad"):diffuse(GetColorFromScoreIndex_POI(scoreIndex))
						else
							self:GetChild("")[k]:GetChild("ColoredQuad"):diffuse(Color.Invisible)
						end
					end

					-- logic related to filling up the number of the level of the chart
					self:GetChild("")[j]:GetChild("Level"):visible(true)
					self:GetChild("")[j]:GetChild("Level"):settext(FetchFromChart(Chart, "Chart Meter"))
					self:GetChild("")[j]:GetChild("Level"):diffuse(FetchFromChart(Chart, "Chart Stepstype Color"))
				else
					-- this is for empty slots
					self:GetChild("")[j]:GetChild("BGQuad"):visible(true)
					self:GetChild("")[j]:GetChild("BGQuad"):diffusealpha(0.1)
					self:GetChild("")[j]:GetChild("ColoredQuad"):visible(true)
					self:GetChild("")[j]:GetChild("ColoredQuad"):diffuse(Color.White):diffusealpha(0.1)
					self:GetChild("")[j]:GetChild("Level"):visible(false)
				end
			end
		else
			-- fallback if everything went to shit
			for j=1,ItemAmount do
				self:GetChild("")[j]:GetChild("BGQuad"):visible(false)
				self:GetChild("")[j]:GetChild("ColoredQuad"):visible(false)
				self:GetChild("")[j]:GetChild("Level"):visible(false)
			end
		end
	end,
}

for i=1,ItemAmount do
	t[#t+1] = Def.ActorFrame {

		Def.Quad {
			Name="BGQuad",
			InitCommand=function(self)
				self:xy(FrameX + ItemW * (i - 1), 0)
				self:zoomto(38, 38)
				self:diffuse(color("0,0,0,0.8"))
			end,
		},

		Def.Quad {
			Name="ColoredQuad",
			InitCommand=function(self)
				self:xy(FrameX + ItemW * (i - 1), 0)
				self:zoomto(31, 31)
			end,
		},

		Def.BitmapText {
			Name="Level",
			Font="Montserrat numbers 40px",
			InitCommand=function(self)
				self:xy(FrameX + ItemW * (i - 1), 0):zoom(0.5):maxwidth(75)
			end
		},

	}
end

return t