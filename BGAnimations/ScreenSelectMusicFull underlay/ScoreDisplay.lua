-- DECLARING SOME LEVERS AND VARIABLES
local Scoring = LoadModule("Config.Load.lua")("ScoringSystem", "Save/OutFoxPrefs.ini") or "Old"
local ClassicGrades = LoadModule("Config.Load.lua")("ClassicGrades", "Save/OutFoxPrefs.ini") and Scoring == "Old"
local SongIsChosen = false

local correction_2P = pn == PLAYER_2 and 0 or 0 --offsetting X for player 2

local personalGradeAnchor_X = 330+60-330
local personalScoreAnchor_X = 330+60-330
local PersonalDateAnchor_X = 390+60-330

local records_Yspacing = 42

local rowPer1Anchor_Y = 20
local rowPer2Anchor_Y = rowPer1Anchor_Y + records_Yspacing
local rowPer3Anchor_Y = rowPer2Anchor_Y + records_Yspacing

-- OPERATIONS
local t = Def.ActorFrame {

	Def.Quad { Name="EntireQuadBG",
		InitCommand=function(self)
			self:xy(0, 0)
			self:zoomto(1272, 353)
			self:align(0.5, 0)
			self:diffuse(color("0,0,0,0.4"))
		end,
	},

	Def.Quad { Name="SeparatorLine",
		InitCommand=function(self)
			self:xy(0, 4)
			self:zoomto(3, 345)
			self:align(0.5, 0)
			self:diffuse(color("0.2,0.2,0.2,0.5"))
		end,
	},

}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	t[#t+1] = Def.ActorFrame {
		CurrentChartChangedMessageCommand=function(self, params)
			if SongIsChosen and params.Player == pn then
				self:playcommand("Refresh")
			end
		end,
		InitCommand=function(self)
			self:x(0)
			self:y(0)
		end,
		SongChosenMessageCommand=function(self)
			SongIsChosen = true
			self:playcommand("Refresh")
		end,
		SongUnchosenMessageCommand=function(self)
			SongIsChosen = false
		end,
		RefreshCommand=function(self)
			Song = GAMESTATE:GetCurrentSong()
			Chart = GAMESTATE:GetCurrentSteps(pn)
			
			-- logic for top 6 "machine records"
			local MachineHighScores = PROFILEMAN:GetMachineProfile():GetHighScoreList(Song, Chart):GetHighScores()
			for i = 1, 6 do
				local scoreIndex = MachineHighScores[i]

				if scoreIndex ~= nil then
					--
					local truncatedDate = string.sub(scoreIndex:GetDate(), 1, 10)
					local displayDate = FormatDate_POI(truncatedDate)
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("Date"):settext(displayDate)

					--					
					local MachineName = scoreIndex:GetName()
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("Name"):settext(MachineName)
					
					--
					local MachineDP = round(scoreIndex:GetPercentDP() * 100, 2) .. "%"
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("Score"):settext(MachineDP)

					--
					local displayGrade = THEME:GetPathG("", "LetterGrades/" .. LoadModule("PIU/Score.Grading.lua")(scoreIndex))
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("Grade"):Load(displayGrade)

					-- MAXCOMBO
					local displayMaxCombo = scoreIndex:GetMaxCombo()
					--local displayMaxCombo = "9999"
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("NotesMaxCombo"):settext(displayMaxCombo)

					-- PERFECT
					local displayPerfects = scoreIndex:GetTapNoteScore("TapNoteScore_W1")
					--local displayPerfects = "9999"
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("NotesPerfect"):settext(displayPerfects)

					-- GREAT
					local displayGreats = scoreIndex:GetTapNoteScore("TapNoteScore_W2")
					--local displayGreats = "9999"
					if displayGreats == 0 then displayGreats = "·" end
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("NotesGreat"):settext(displayGreats)

					-- GOOD
					local displayGoods = scoreIndex:GetTapNoteScore("TapNoteScore_W3")
					--local displayGoods = "9999"
					if displayGoods == 0 then displayGoods = "·" end
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("NotesGood"):settext(displayGoods)

					-- BAD
					local displayBads = scoreIndex:GetTapNoteScore("TapNoteScore_W4")
					--local displayBads = "9999"
					if displayBads == 0 then displayBads = "·" end
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("NotesBad"):settext(displayBads)

					-- MISS
					local displayMisses = scoreIndex:GetTapNoteScore("TapNoteScore_Miss")
					--local displayMisses = "9999"
					if displayMisses == 0 then displayMisses = "·" end
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):GetChild("NotesMiss"):settext(displayMisses)

					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):visible(true)
				else
					self:GetChild("MachineRecords_module"):GetChild("MachineRecordsGroup_" .. i):visible(false)
				end
			end
			
			-- logic for top 3 "personal records"
			-- apparently engine doesn't allow more than 3 personal records for now
			if PROFILEMAN:IsPersistentProfile(pn) then
				ProfileScores = PROFILEMAN:GetProfile(pn):GetHighScoreList(Song, Chart):GetHighScores()
				for i = 1, 3 do
					local scoreIndex = ProfileScores[i]

					if scoreIndex ~= nil then
						--
						local truncatedDate = string.sub(scoreIndex:GetDate(), 1, 10)
						local displayDate = FormatDate_POI(truncatedDate)
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("Date"):settext(displayDate)

						--
						local MachineDP = round(scoreIndex:GetPercentDP() * 100, 2) .. "%"
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("Score"):settext(MachineDP)

						--
						local displayGrade = THEME:GetPathG("", "LetterGrades/" .. LoadModule("PIU/Score.Grading.lua")(scoreIndex))
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("Grade"):Load(displayGrade)

						-- MAXCOMBO
						local displayMaxCombo = scoreIndex:GetMaxCombo()
						--local displayMaxCombo = "9999"
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("NotesMaxCombo"):settext(displayMaxCombo)

						-- PERFECT
						local displayPerfects = scoreIndex:GetTapNoteScore("TapNoteScore_W1")
						--local displayPerfects = "9999"
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("NotesPerfect"):settext(displayPerfects)

						-- GREAT
						local displayGreats = scoreIndex:GetTapNoteScore("TapNoteScore_W2")
						--local displayGreats = "9999"
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("NotesGreat"):settext(displayGreats)

						-- GOOD
						local displayGoods = scoreIndex:GetTapNoteScore("TapNoteScore_W3")
						--local displayGoods = "9999"
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("NotesGood"):settext(displayGoods)

						-- BAD
						local displayBads = scoreIndex:GetTapNoteScore("TapNoteScore_W4")
						--local displayBads = "9999"
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("NotesBad"):settext(displayBads)

						-- MISS
						local displayMisses = scoreIndex:GetTapNoteScore("TapNoteScore_Miss")
						--local displayMisses = "9999"
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):GetChild("NotesMiss"):settext(displayMisses)

						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):visible(true)
					else
						self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):visible(false)
					end
				end
			else
				for i = 1, 3 do
					self:GetChild("PersonalRecords_module"):GetChild("PersonalRecordsGroup_" .. i):visible(false)
				end
			end
			
		end,
		
		
		-- DRAWING
		Def.ActorFrame { Name="MachineRecords_module",
			InitCommand=function(self)
				self:x(476 * (pn == PLAYER_2 and 1 or -1))
				self:y(4)
			end,
			
			Def.Quad { -- machine records label bg quad
				InitCommand=function(self)
					self:zoomto(312, 21)
					self:valign(0)
					self:diffuse(Color.Black)
					self:diffusealpha(0.4)
				end,
			},
			Def.BitmapText { -- machine records label text
				Font="Montserrat normal 20px",
				Text="MACHINE RECORDS",
				InitCommand=function(self)
					self:zoom(0.9)
					self:y(10)
					self:halign(0.5)
					self:maxwidth(300)
					self:shadowlength(1)
					self:skewx(-0.1)
				end,
			},

			Def.ActorFrame { Name="MachineRecordsGroup_1",
				InitCommand=function(self)
					self:y(50)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Name",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(-150,6)
						self:zoom(0.9)
						self:halign(0):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(154)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

			Def.ActorFrame { Name="MachineRecordsGroup_2",
				InitCommand=function(self)
					self:y(104)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Name",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(-150,6)
						self:zoom(0.9)
						self:halign(0):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(154)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

			Def.ActorFrame { Name="MachineRecordsGroup_3",
				InitCommand=function(self)
					self:y(158)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Name",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(-150,6)
						self:zoom(0.9)
						self:halign(0):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(154)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

			Def.ActorFrame { Name="MachineRecordsGroup_4",
				InitCommand=function(self)
					self:y(212)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Name",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(-150,6)
						self:zoom(0.9)
						self:halign(0):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(154)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

			Def.ActorFrame { Name="MachineRecordsGroup_5",
				InitCommand=function(self)
					self:y(266)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Name",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(-150,6)
						self:zoom(0.9)
						self:halign(0):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(154)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

			Def.ActorFrame { Name="MachineRecordsGroup_6",
				InitCommand=function(self)
					self:y(320)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Name",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(-150,6)
						self:zoom(0.9)
						self:halign(0):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(154)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

		},

		Def.ActorFrame { Name="PersonalRecords_module",
			InitCommand=function(self)
				self:x(160 * (pn == PLAYER_2 and 1 or -1))
				self:y(4)
			end,
					
			Def.Quad { -- personal records label bg quad
				InitCommand=function(self)
					self:zoomto(312, 21)
					self:valign(0)
					self:diffuse(Color.Black)
					self:diffusealpha(0.4)
				end
			},

			Def.BitmapText { -- personal records label text
				Font="Montserrat normal 20px",
				Text="PERSONAL RECORDS",
				InitCommand=function(self)
					self:zoom(0.9)
					self:y(10)
					self:halign(0.5)
					self:maxwidth(300)
					self:shadowlength(1)
					self:skewx(-0.1)
				end
			},

			Def.ActorFrame { Name="PersonalRecordsGroup_1",
				InitCommand=function(self)
					self:y(50)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

			Def.ActorFrame { Name="PersonalRecordsGroup_2",
				InitCommand=function(self)
					self:y(104)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

			Def.ActorFrame { Name="PersonalRecordsGroup_3",
				InitCommand=function(self)
					self:y(158)
					self:visible(false)
				end,

				Def.Quad { -- bg quad
					InitCommand=function(self)
						self:zoomto(312, 50)
						self:diffuse(Color.White):diffusealpha(0.4)
					end,
				},
				Def.BitmapText { Name="Date",
					Font="Montserrat normal 20px",
					InitCommand=function(self)
						self:xy(-102,-16)
						self:zoom(0.7)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="Score",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(122,14)
						self:zoom(0.8)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.Sprite { Name="Grade",
					InitCommand=function(self)
						self:xy(120,-8)
						self:zoom(0.11)
					end,
				},
				Def.BitmapText { Name="LabelMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-15)
						self:zoom(0.6)
						self:settext("MAX")
						self:halign(1):diffuse(Color.Yellow):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMaxCombo",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,-1)
						self:zoom(0.6)
						self:settext("P")
						self:halign(1):diffuse(Color.Blue):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesPerfect",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(1,13)
						self:zoom(0.6)
						self:settext("G")
						self:halign(1):diffuse(Color.Green):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGreat",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(21,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-15)
						self:zoom(0.6)
						self:settext("G")
						self:halign(0.5):diffuse(Color.Orange):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesGood",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-15)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,-1)
						self:zoom(0.6)
						self:settext("B")
						self:halign(0.5):diffuse(Color.Purple):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesBad",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,-1)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="LabelMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(46,13)
						self:zoom(0.6)
						self:settext("M")
						self:halign(0.5):diffuse(Color.Red):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},
				Def.BitmapText { Name="NotesMiss",
					Font="Montserrat semibold 20px",
					InitCommand=function(self)
						self:xy(71,13)
						self:zoom(0.6)
						self:halign(0.5):diffuse(Color.White):vertspacing(-6):shadowlength(1):maxwidth(265)
					end,
				},

			},

		},

	}

end

return t