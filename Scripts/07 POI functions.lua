function GetColor_POI(inputString)
	local colorMap = {
		-- others
		Black = color("#000000"),
		Invisible  = Color.Invisible,

		-- IDK or Placeholder charts
		IDK = color("#FFFF00"),
		Placeholder = color("#888888"),

		-- chart stepstype
		Single = color("#ff8811"),
		Halfdouble = color("#11eeee"),
		Double = color("#119922"),

		-- song origins
		["The 1st DF"] = color("#ff00ff"),
		["The 2nd DF"] = color("#1144ff"),
		["O.B.G The 3rd"] = color("#33bb00"),
		["O.B.G Season Evo."] = color("#ffff00"),
		["Perfect"] = color("#ff9900"),
		["Extra"] = color("#ff0000"),
		["Premiere"] = color("#ff00ff"),
		["Rebirth"] = color("#1144ff"),
		["Premiere 3"] = color("#33bb00"),
		["Prex 3"] = color("#ffff00"),
		["Exceed"] = color("#ff9900"),
		["Exceed S.E"] = color("#ff9900"),
		["Exceed 2"] = color("#ff0000"),
		["Zero"] = color("#ff00ff"),
		["NX"] = color("#1144ff"),
		["Pro"] = color("#33bb00"),
		["Pro Encore"] = color("#33bb00"),
		["NX2"] = color("#ffff00"),
		["NX Absolute"] = color("#ff9900"),
		["Fiesta"] = color("#ff9900"),
		["Fiesta EX"] = color("#ff0000"),
		["Fiesta 2"] = color("#ff00ff"),
		["Prime"] = color("#1144ff"),
		["Prime 2"] = color("#33bb00"),
		["XX"] = color("#ffff00"),
		["M"] = color("#ff9900"),
		["Phoenix"] = color("#ff0000"),
		["Pro 2"] = color("#888888"),
		["Infinity"] = color("#aaaaaa"),

		-- song genres
		ORIGINAL = color("#1144ff"),
		KPOP = color("#ffff00"),
		WORLDMUSIC = color("#11eeee"),
		JMUSIC = color("#ff0000"),
		XROSS = color("#33bb00"),

		-- song tags
		ARCADE = color("#ffffff"),
		ANOTHER = color("#ff0000"),
		SHORTCUT = color("#ffff00"),
		REMIX = color("#1144ff"),
		FULLSONG = color("#33bb00"),

		-- song tags for quads
		ARCADEQUAD = color("#ffffff00"),
		ANOTHERQUAD = color("#ee0000bb"),
		SHORTCUTQUAD = color("#eeee00bb"),
		REMIXQUAD = color("#0033eebb"),
		FULLSONGQUAD = color("#22aa00bb"),

		-- grades
		GOLD = color("#ffcc33"),
		SILVER = color("#aaaaaa"),
		BRONZE = color("#dd7733"),
		PASSED = color("#3399ff"),
		FAILED = color("0,0,0,0.4"),
		NOT_PLAYED = color("0,0,0,0.2"),
	}

	return colorMap[inputString] or colorMap["Black"]
end

-- Reads the Database_POI table of elements to populate the Groups list
function AssembleGroupSorting_POI()
	if not (SONGMAN and GAMESTATE) then
        Warn("SONGMAN or GAMESTATE were not ready! Aborting!")
        return
    end
	
	-- initialize/clean the global variables
	MasterGroupsList = {}
	GroupsList = {}

	-- initialize local helper variables
	local allSongs = SONGMAN:GetAllSongs()

	-- for each playlist found in Database_POI,
	for i, thisPlaylist in ipairs(Database_POI()) do

		-- grab an array of strings which is the list of songs allowed in		
		local listOfAllowedSongsAsString = {}
		for _, song in ipairs(thisPlaylist.AllowedSongs) do
			table.insert(listOfAllowedSongsAsString, song.SongPath)
		end

		-- grab an array of Song elements related to the list of songs allowed in		
		local arrayOfAllowedSongs = {}
		for _, listedDir in ipairs(listOfAllowedSongsAsString) do
			for _, thisSong in ipairs(allSongs) do
				if thisSong:GetSongDir() == listedDir then
					table.insert(arrayOfAllowedSongs, thisSong)
				end
			end
		end

		-- adds everything to the global variable called MasterGroupsList
		MasterGroupsList[#MasterGroupsList + 1] = {
			Name = thisPlaylist.Name,
			Banner = THEME:GetPathG("", thisPlaylist.Banner),
			Description = thisPlaylist.Description,
			StartingPoint = thisPlaylist.StartingPoint,
			AllowedSongs = thisPlaylist.AllowedSongs,
			Songs = arrayOfAllowedSongs
		}

		-- trace
		Trace("Playlist added: " .. MasterGroupsList[#MasterGroupsList].Name .. " - " .. #MasterGroupsList[#MasterGroupsList].Songs .. " songs")
	end

	--trace
	Trace("POI Playlist sorting created!")
end

-- Updates the Groups list as required
function UpdateGroupSorting_POI()
	Trace("Creating group list copy from master...")
    GroupsList = deepcopy(MasterGroupsList)

    Trace("Removing unplayable songs from list...")
    for MainGroup in pairs(GroupsList) do
		GroupsList[MainGroup].Songs = PlayableSongs(GroupsList[MainGroup].Songs)
        if #GroupsList[MainGroup].Songs == 0 then
        	table.remove(GroupsList, MainGroup)
        end
    end

    MESSAGEMAN:Broadcast("UpdateChartDisplay")
    Trace("POI Playlist sorting updated!")
end

-- inputs:
-- 1) a string related to the name of the group, such as |"Pump It Up Exceed 2"|
-- 2) an integer, related to the index of a song, such as |3|
-- returns: an array of strings, as in this example:
-- { "EXC2-NORMAL", "EXC2-HARD", "EXC2-CRAZY", "EXC2-FREESTYLE", "EXC2-NIGHTMARE" }
function GetAllowedChartsAsString_POI(input_groupName, input_currentIndex)

	local output = {}

	for _, playlist in ipairs(Database_POI()) do
		if playlist.Name == input_groupName then
			local songEntry = playlist.AllowedSongs[input_currentIndex]
			if songEntry then
				output = songEntry.Charts
			end
		end
	end
	
	return output
end

-- inputs:
-- 1) an array of Chart objects
-- 2) an array of strings related to the charts you want to filter, such as { "EXC2-NORMAL", "EXC2-HARD", "EXC2-FREESTYLE" }
-- returns: an array of Chart objects, but filtered according to the second parameter
-- { [Object for a "EXC2-NORMAL" chart], [Object for a "EXC2-HARD" chart], [Object for a "EXC2-FREESTYLE" chart] }
function CreateChartArrayBasedOnList_POI(input_chartArray, input_allowedCharts)
	local output_ChartArray = {}

    for _, chart in ipairs(input_chartArray) do
        local description = chart:GetDescription()
        
        for _, allowedChart in ipairs(input_allowedCharts) do
            if description == allowedChart then
                table.insert(output_ChartArray, chart)
                break  -- No need to continue checking if the chart has been added
            end
        end
    end

    return output_ChartArray
end

-- inputs:
-- 1) an array of Chart objects
-- 2) a string related to the name of the group, such as |"Pump It Up Exceed 2"|
-- 3) an integer, related to the index of a song, such as |3|
-- returns: an array of Chart objects, as in this example:
-- { [Object for a "EXC2-NORMAL" chart], [Object for a "EXC2-HARD" chart], [Object for a "EXC2-CRAZY" chart] }
function GetAllowedCharts_POI(input_chartArray, input_groupName, input_currentIndex)
	local output = {}

	if input_groupName == "Problematic songs" or input_groupName == "All Tunes" then
		output = input_chartArray
	else
		local listOfAllowedChartsAsString = GetAllowedChartsAsString_POI(input_groupName, input_currentIndex)
		output = CreateChartArrayBasedOnList_POI(input_chartArray, listOfAllowedChartsAsString)
	end

	if #output == 0 then
		return {} -- this will make the function return an empty ChartArray, which will be handled, in some way, by whatever called this function
	end

	return output
end

-- inputs:
-- 1) a song object
-- 2) a string detailing what you want, from this list:
-- "First Tag", "Second Tag", "Song Category", "Display-formatted Song Category", "Display-formatted Song Genre", "Minimalist Song Genre"
-- "Song Display BPMs"
-- "Song Origin Color", "Song Genre Color", "Song Category Color"
-- returns:
-- it actually depends on what you want, really
function FetchFromSong(input_song, fetch_details)
	
	local output = ""

	if input_song then
		if fetch_details == "First Tag" then
			-- returns a string
			
			local fullTagAttribute = input_song:GetTags()
			if fullTagAttribute ~= "" then
				local words = {} -- array of strings, one for each separate word
				for thisWord in fullTagAttribute:gmatch("%S+") do
					table.insert(words, thisWord)
				end
			output = words[1] -- gets the first word in that array
			end
		
		elseif fetch_details == "Second Tag" then
			-- returns a string
			
			local fullTagAttribute = input_song:GetTags()
			if fullTagAttribute ~= "" then
				local words = {} -- array of strings, one for each separate word
				for thisWord in fullTagAttribute:gmatch("%S+") do
					table.insert(words, thisWord)
				end
				
				-- Check if the words table has more than one element
				if #words >= 2 then
					output = words[2] -- gets the second word in that array		
				end
			end
		
		elseif fetch_details == "Song Category" then
			-- returns a string
			
			local song_firstTag = FetchFromSong(input_song, "First Tag")
			local song_secondTag = FetchFromSong(input_song, "Second Tag")
			if song_firstTag == "SHORTCUT" then	output = "SHORTCUT"
			elseif song_firstTag == "REMIX" then output = "REMIX"
			elseif song_firstTag == "FULLSONG" then	output = "FULLSONG"
			elseif song_secondTag == "ANOTHER" then	output = "ANOTHER"
			else output = "ARCADE"
			end

		elseif fetch_details == "Display-formatted Song Category" then
			-- returns a string

			local song_firstTag = FetchFromSong(input_song, "First Tag")
			local song_secondTag = FetchFromSong(input_song, "Second Tag")
			if song_firstTag == "SHORTCUT" then	output = "SHORT CUT"
			elseif song_firstTag == "REMIX" then output = "REMIX"
			elseif song_firstTag == "FULLSONG" then	output = "FULL SONG"
			elseif song_secondTag == "ANOTHER" then	output = "ANOTHER"
			else output = ""
			end

		elseif fetch_details == "Display-formatted Song Genre" then
			-- returns a string

			if input_song:GetGenre() == "KPOP" then output = "K-Pop"
			elseif input_song:GetGenre() == "ORIGINAL" then output = "PIU Originals"
			elseif input_song:GetGenre() == "WORLDMUSIC" then output = "World Music"
			else output = input_song:GetGenre()
			end

		elseif fetch_details == "Minimalist Song Genre" then
			-- returns a string

			if input_song:GetGenre() == "KPOP" then output = "K"
			elseif input_song:GetGenre() == "ORIGINAL" then output = "O"
			elseif input_song:GetGenre() == "WORLDMUSIC" then output = "W"
			else output = input_song:GetGenre()
			end

		elseif fetch_details == "Song Display BPMs" then
			-- returns a string

			local bpm_raw = input_song:GetDisplayBpms()
			local bpm_low = math.ceil(bpm_raw[1])
			local bpm_high = math.ceil(bpm_raw[2])
			local bpm_display = (bpm_low == bpm_high and bpm_high or bpm_low .. "-" .. bpm_high)
			output = bpm_display .. " BPM"

		elseif fetch_details == "Song Origin Color" then
			-- returns a color object, such to use inside a self:diffuse(x)

			output = GetColor_POI(input_song:GetOrigin())
		
		elseif fetch_details == "Song Genre Color" then
			-- returns a color object, such to use inside a self:diffuse(x)

			output = GetColor_POI(input_song:GetGenre())
		
		elseif fetch_details == "Song Category Color" then
			-- returns a color object, such to use inside a self:diffuse(x)
			
			local song_firstTag = FetchFromSong(input_song, "First Tag")
			local song_secondTag = FetchFromSong(input_song, "Second Tag")
			if song_firstTag == "SHORTCUT" or song_firstTag == "REMIX" or song_firstTag == "FULLSONG" then
				output = GetColor_POI(song_firstTag)
			elseif song_secondTag == "ANOTHER" then
				output = GetColor_POI(song_secondTag)
			else
				output = GetColor_POI("ARCADE")
			end

		elseif fetch_details == "Song Category Color for quads" then
			-- returns a color object, such to use inside a self:diffuse(x)
			
			local song_firstTag = FetchFromSong(input_song, "First Tag")
			local song_secondTag = FetchFromSong(input_song, "Second Tag")
			if song_firstTag == "SHORTCUT" or song_firstTag == "REMIX" or song_firstTag == "FULLSONG" then
				output = GetColor_POI(song_firstTag.."QUAD")
			elseif song_secondTag == "ANOTHER" then
				output = GetColor_POI(song_secondTag.."QUAD")
			else
				output = GetColor_POI("ARCADEQUAD")
			end

		end

	end
	
	return output

end

-- inputs:
-- 1) a chart object
-- 2) a string detailing what you want, from this list:
-- "Chart POI Name", "Chart Origin", "Chart Meter"
-- "Chart Author", "Chart Level", "Chart Stepstype Color"
-- returns:
-- it actually depends on what you want, really
function FetchFromChart(input_chart, fetch_details)
	
	local output = ""

	if fetch_details == "Chart POI Name" then
		-- returns a string

		local chartFullChartnameFromSSC = input_chart:GetChartName()
		local openParen = chartFullChartnameFromSSC:find("%(")
		output = chartFullChartnameFromSSC:sub(1, openParen - 2)

	elseif fetch_details == "Chart Origin" then
		-- returns a string

		local chartFullChartnameFromSSC = input_chart:GetChartName()
		local openParen = chartFullChartnameFromSSC:find("%(")
		local closeParen = chartFullChartnameFromSSC:find("%)")
		output = chartFullChartnameFromSSC:sub(openParen + 1, closeParen - 1)

	elseif fetch_details == "Chart Meter" then
		-- returns a string

		local originalChartMeter = input_chart:GetMeter()
		if originalChartMeter == 99 then output = "??"
		else output = string.format("%02d", originalChartMeter)
		end

	elseif fetch_details == "Chart Author" then
		-- returns a string
		
		if (input_chart:GetAuthorCredit() == "") then output = "Author is blank"
		else output = input_chart:GetAuthorCredit() end

	elseif fetch_details == "Chart Level" then
		-- returns a string
		
		if input_chart:GetMeter() == 99 then output = "??"
		else output = string.format("%02d", input_chart:GetMeter()) end

	elseif fetch_details == "Chart Stepstype Color" then
		-- returns a color object, such to use inside a self:diffuse(x)

		if FetchFromChart(input_chart, "Chart POI Name"):sub(1, 3) == "IDK" then
			output = GetColor_POI("IDK")
		elseif input_chart:GetAuthorCredit() == "Placeholder" then
			output = GetColor_POI("Placeholder")
		else 
			output = GetColor_POI(ToEnumShortString(ToEnumShortString(input_chart:GetStepsType())))
		end

	end

	return output

end

-- inputs:
-- 1) a string, related to a date
-- returns: a string too, but correctly formatted according to the rules below
function FormatDate_POI(input_date_as_string)
	local output = ""
	
	-- Split the input string based on the hyphen separator
	local parts = string.split(input_date_as_string, "-")
	
	-- Assign each part to the corresponding variable
	local YearAsString = parts[1] or ""
	local MonthAsNumberString = parts[2] or ""
	local DayAsNumberString = parts[3] or ""
	
	-- Format the month
	local MonthAsString = ""
	local monthMap = {
		["01"] = "Jan", ["02"] = "Feb", ["03"] = "Mar", ["04"] = "Apr", ["05"] = "May", ["06"] = "Jun", 
		["07"] = "Jul", ["08"] = "Aug", ["09"] = "Sep", ["10"] = "Oct", ["11"] = "Nov", ["12"] = "Dec"
	}
	MonthAsString = monthMap[MonthAsNumberString] or ""
	
	-- Creates output
	output = YearAsString .. ", " .. DayAsNumberString .. " " .. MonthAsString
	
	return output
end

-- inputs:
-- 1) a string, related to the "POI Name" of a chart, which is based on its original difficulty name
-- returns: a string too, but correctly sanitized as to adjust to the difficulty name only
function FormatDifficultyFromPOIName_POI(input_playlistName, input_poiName_as_string)
	local difficultyMap_Prex = {
		["NORMAL i"] = "NORMAL",
		["HARD i"] = "HARD",
		["CRAZY i"] = "CRAZY",
		["EXTRA EXPERT"] = "CRAZY",
		["DOUBLE i"] = "DOUBLE",
		["DOUBLE ii"] = "DOUBLE",
		["FREESTYLE"] = "DOUBLE",
		["FREESTYLE i"] = "DOUBLE",
		["FREESTYLE ii"] = "DOUBLE",
		["EXTRA EXPERT DOUBLE"] = "DOUBLE",
	}
	local difficultyMap_Premiere2 = {
		["NORMAL"] = "EASY",
		["NORMAL i"] = "EASY",
		["HARD i"] = "HARD",
		["CRAZY i"] = "CRAZY",
		["DOUBLE"] = "FULL-DOUBLE",
		["DOUBLE i"] = "FULL-DOUBLE",
		["DOUBLE ii"] = "FULL-DOUBLE",
		["FREESTYLE"] = "FULL-DOUBLE",
		["FREESTYLE i"] = "FULL-DOUBLE",
		["FREESTYLE ii"] = "FULL-DOUBLE",
	}
	local difficultyMap_Premiere3 = {
		["NORMAL i"] = "NORMAL",
		["HARD i"] = "HARD",
		["CRAZY i"] = "CRAZY",
		["EXTRA EXPERT"] = "CRAZY",
		["DOUBLE"] = "FULL-DOUBLE",
		["DOUBLE i"] = "FULL-DOUBLE",
		["DOUBLE ii"] = "FULL-DOUBLE",
		["FREESTYLE"] = "FULL-DOUBLE",
		["FREESTYLE i"] = "FULL-DOUBLE",
		["FREESTYLE ii"] = "FULL-DOUBLE",
		["EXTRA EXPERT DOUBLE"] = "FULL-DOUBLE",
	}
	local difficultyMap_Freevolt = {
		["NORMAL i"] = "NORMAL",
		["NORMAL ii"] = "NORMAL",
		["NORMAL iii"] = "NORMAL",
		["HARD i"] = "HARD",
		["HARD ii"] = "HARD",
		["HARD iii"] = "HARD",
		["CRAZY i"] = "CRAZY",
		["CRAZY ii"] = "CRAZY",
		["CRAZY iii"] = "CRAZY",
		["EXTRA EXPERT"] = "CRAZY",
		["DOUBLE"] = "FREESTYLE",
		["DOUBLE i"] = "FREESTYLE",
		["DOUBLE ii"] = "FREESTYLE",
		["FREESTYLE i"] = "FREESTYLE",
		["FREESTYLE ii"] = "FREESTYLE",
		["NIGHTMARE i"] = "NIGHTMARE",
		["NIGHTMARE ii"] = "NIGHTMARE",
		["EXTRA EXPERT DOUBLE"] = "NIGHTMARE",
		["ANOTHER HARD"] = "A. HARD",
		["ANOTHER CRAZY"] = "A. CRAZY",
		["ANOTHER CRAZY i"] = "A. CRAZY",
		["ANOTHER FREESTYLE"] = "A. FREESTYLE",
		["ANOTHER NIGHTMARE"] = "A. NIGHTMARE",
		["ANOTHER NIGHTMARE i"] = "A. NIGHTMARE",
		["ANOTHER NIGHTMARE ii"] = "A. NIGHTMARE",
		-- If Vook and (PIU Zero or PIU NX), then HALF-DOUBLE >> A. FREESTYLE
		-- If Love is a Danger Zone and (PIU Zero or PIU NX), then HALF-DOUBLE >> A. FREESTYLE
		-- If Love is a Danger Zone and PIU NX, then DIVISION ALL WILD >> A. CRAZY
		-- If Mr. Larpus and PIU NX, then A. NIGHTMARE i >> A. FREESTYLE
	}

	if input_playlistName == "Pump It Up The Prex" then
		return difficultyMap_Prex[input_poiName_as_string] or input_poiName_as_string
	elseif input_playlistName == "Pump It Up The Premiere 2" then
		return difficultyMap_Premiere2[input_poiName_as_string] or input_poiName_as_string
	elseif input_playlistName == "Pump It Up The Premiere 3" then
		return difficultyMap_Premiere3[input_poiName_as_string] or input_poiName_as_string
	elseif input_playlistName == "Pump It Up The Prex 3" or
	       input_playlistName == "Pump It Up Exceed" or
		   input_playlistName == "Pump It Up Exceed 2 - Arcade Station" or
		   input_playlistName == "Pump It Up Exceed 2 - Remix Station" or
		   input_playlistName == "Pump It Up Zero - Easy Station" or
		   input_playlistName == "Pump It Up Zero - Arcade Station" or
		   input_playlistName == "Pump It Up Zero - Remix Station" or
		   input_playlistName == "Pump It Up NX - Arcade Station" or
		   input_playlistName == "Pump It Up NX - Special Zone" then
		return difficultyMap_Freevolt[input_poiName_as_string] or input_poiName_as_string
	else
		return input_poiName_as_string
	end
	
end

-- inputs:
-- 1) a string, related to a grade
-- returns: a string too, but correctly formatted according to the rules below
function FormatGradeFromScoreIndex_POI(input_scoreIndex_as_string)
	local gradeMap = {
		Pass3S = "SSS", Fail3S = "SSS",
		Pass2S = "SS",  Fail2S = "SS",
		PassS = "S",   FailS = "S",
		PassA = "A",    FailA = "A",
		PassB = "B",    FailB = "B",
		PassC = "C",    FailC = "C",
		PassD = "D",    FailD = "D",
		PassF = "F",    FailF = "F",
	}
	return gradeMap[input_scoreIndex_as_string] or ""
end

-- inputs:
-- 1) a string, related to a grade
-- returns: a string, related to the color of the associated grade
function GetColorFromScoreIndex_POI(input_scoreIndex_as_string)
	local gradeColorMap = {
		Pass3S = "GOLD",
		Pass2S = "GOLD",
		PassS = "SILVER",

		PassA = "PASSED", PassB = "PASSED", PassC = "PASSED",
		PassD = "PASSED", PassF = "PASSED",

		Fail3S = "FAILED", Fail2S = "FAILED", FailS = "FAILED",
		FailA = "FAILED", FailB = "FAILED", FailC = "FAILED",
		FailD = "FAILED", FailF = "FAILED"
	}

	local colorKey = gradeColorMap[input_scoreIndex_as_string]
	if colorKey then
		return GetColor_POI(colorKey)
	else
		return GetColor_POI("NOT_PLAYED")
	end
end

-- inputs:
-- 1) an array of Chart objects
-- 2) a string detailing what you want, from this list:
-- "Singles", "Not Singles",
-- "Easy Station", "Normal", "Hard", "Crazy", 
-- "Half-Double", "Freestyle", "Nightmare"
-- 3) a string representing the name of the playlist
-- 4) a string representing the name of the song
-- returns:
-- an array of Chart objects
function SplitChartArray(input_chartArray, input_string, input_playlistNameAsString, input_songNameAsString)
	
	local PrevChartArray = ShallowCopy(input_chartArray)
	local output = ShallowCopy(input_chartArray)

	if input_string == "Singles" then
		for i = #output, 1, -1 do
			if output[i]:GetStepsType() ~= "StepsType_Pump_Single" then
				table.remove(output, i)
			end
		end
	elseif input_string == "Not Singles" then
		for i = #output, 1, -1 do
			if output[i]:GetStepsType() == "StepsType_Pump_Single" then
				table.remove(output, i)
			end
		end
	elseif input_string == "Easy Station" then
		for i = #output, 1, -1 do
			local chartPOIName = FetchFromChart(output[i],"Chart POI Name")
   			if not (chartPOIName == "EASY STATION" or chartPOIName == "EASY STATION i" or chartPOIName == "EASY STATION ii" or chartPOIName == "EASY STATION iii") then
				table.remove(output, i)
			end
		end
	elseif input_string == "Normal" then
		for i = #output, 1, -1 do
			local chartPOIName = FetchFromChart(output[i],"Chart POI Name")
   			if not (chartPOIName == "NORMAL" or chartPOIName == "NORMAL i" or chartPOIName == "NORMAL ii" or chartPOIName == "NORMAL iii"
			or chartPOIName == "DIVISION ALL NORMAL") then
				table.remove(output, i)
			end
		end
	elseif input_string == "Hard" then
		for i = #output, 1, -1 do
			local chartPOIName = FetchFromChart(output[i],"Chart POI Name")
   			if not (chartPOIName == "HARD" or chartPOIName == "HARD i" or chartPOIName == "HARD ii" or chartPOIName == "HARD iii"
			or chartPOIName == "DIVISION ALL GROOVE" or chartPOIName == "ANOTHER HARD") then
				table.remove(output, i)
			end
		end
	elseif input_string == "Crazy" then
		for i = #output, 1, -1 do
			local chartPOIName = FetchFromChart(output[i],"Chart POI Name")
   			if not (chartPOIName == "CRAZY" or chartPOIName == "CRAZY i" or chartPOIName == "CRAZY ii" or chartPOIName == "CRAZY iii"
			or chartPOIName == "EXTRA EXPERT" or chartPOIName == "DIVISION ALL WILD" or chartPOIName == "DIVISION WILD STYLE ONE-W"
			or chartPOIName == "DIVISION WILD STYLE TWO-WW" or chartPOIName == "ANOTHER CRAZY") then
				table.remove(output, i)
			end
		end
	elseif input_string == "Half-Double" then
		for i = #output, 1, -1 do
			local chartPOIName = FetchFromChart(output[i],"Chart POI Name")
   			if not (chartPOIName == "HALF-DOUBLE" or chartPOIName == "HALF-DOUBLE i" or chartPOIName == "HALF-DOUBLE ii" or chartPOIName == "HALF-DOUBLE iii") then
				table.remove(output, i)
			end
		end
	elseif input_string == "Freestyle" then
		for i = #output, 1, -1 do
			local chartPOIName = FetchFromChart(output[i],"Chart POI Name")
			if ((input_playlistNameAsString == "Pump It Up The Prex") and (input_songNameAsString == "Chicken Wing"))
			or ((input_playlistNameAsString == "Pump It Up The Prex") and (input_songNameAsString == "Holiday"))
			or ((input_playlistNameAsString == "Pump It Up The Prex") and (input_songNameAsString == "Radetzky Can Can"))
			or ((input_playlistNameAsString == "Pump It Up The Prex 2") and (input_songNameAsString == "Chicken Wing"))
			or ((input_playlistNameAsString == "Pump It Up The Prex 2") and (input_songNameAsString == "Holiday"))
			or ((input_playlistNameAsString == "Pump It Up The Prex 2") and (input_songNameAsString == "Radetzky Can Can"))
			or ((input_playlistNameAsString == "Pump It Up The Premiere 3") and (input_songNameAsString == "Chicken Wing")) then
				-- these are exceptions to the rule
				if not (chartPOIName == "EXTRA EXPERT DOUBLE") then
					table.remove(output, i)
				end
			else
				-- regular situation
   				if not (chartPOIName == "FREESTYLE" or chartPOIName == "FREESTYLE i" or chartPOIName == "FREESTYLE ii" or chartPOIName == "FREESTYLE iii"
				or chartPOIName == "ANOTHER FREESTYLE" or chartPOIName == "ANOTHER FREESTYLE i" or chartPOIName == "ANOTHER FREESTYLE ii") then
					table.remove(output, i)
				end
			end
		end
	elseif input_string == "Nightmare" then
		for i = #output, 1, -1 do
			local chartPOIName = FetchFromChart(output[i],"Chart POI Name")
			if ((input_playlistNameAsString == "Pump It Up The Prex") and (input_songNameAsString == "Chicken Wing"))
			or ((input_playlistNameAsString == "Pump It Up The Prex") and (input_songNameAsString == "Holiday"))
			or ((input_playlistNameAsString == "Pump It Up The Prex") and (input_songNameAsString == "Radetzky Can Can"))
			or ((input_playlistNameAsString == "Pump It Up The Prex 2") and (input_songNameAsString == "Chicken Wing"))
			or ((input_playlistNameAsString == "Pump It Up The Prex 2") and (input_songNameAsString == "Holiday"))
			or ((input_playlistNameAsString == "Pump It Up The Prex 2") and (input_songNameAsString == "Radetzky Can Can"))
			or ((input_playlistNameAsString == "Pump It Up The Premiere 3") and (input_songNameAsString == "Chicken Wing")) then
				-- these are exceptions to the rule
				table.remove(output, i)
			else
				-- regular situation
   				if not (chartPOIName == "NIGHTMARE" or chartPOIName == "NIGHTMARE i" or chartPOIName == "NIGHTMARE ii" or chartPOIName == "NIGHTMARE iii"
				or chartPOIName == "EXTRA EXPERT DOUBLE" or chartPOIName == "ANOTHER NIGHTMARE" or chartPOIName == "ANOTHER NIGHTMARE i"
				or chartPOIName == "ANOTHER NIGHTMARE ii" or chartPOIName == "STAFF ROLL") then
					table.remove(output, i)
				end
			end
		end
	end

	return output
end

-- helper function to use elsewhere in the theme.
-- a Banner/Sprite can use this to zoom to a specific height and have it inserted with their original ratio preserved
function Actor:zoomtoheight_POI(desiredH)
    -- only works for Sprites (they have textures with width/height)
    if self.GetWidth and self.GetHeight then
        local nativeH = self:GetHeight()
        if nativeH > 0 then
            local zoom = desiredH / nativeH
            self:zoom(zoom)
        else
            Warn("zoomtoheight: Sprite has no valid height yet.")
        end
    else
        Warn("zoomtoheight: This actor doesn't support GetWidth/GetHeight.")
    end
    return self
end