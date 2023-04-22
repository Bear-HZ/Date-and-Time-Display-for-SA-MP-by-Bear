-----------------------------------------------------
-- INFO
-----------------------------------------------------


script_name("Date and Time Display")
script_author("Bear")
script_version("1.0.0")


-----------------------------------------------------
-- HEADERS & CONFIG
-----------------------------------------------------


local sampev = require "lib.samp.events"
local inicfg = require "inicfg"
local ig = require "lib.samp.imgui"
local fontFlags = require("moonloader").font_flag
local vk = require "vkeys"

local config_dir_path = getWorkingDirectory() .. "\\config\\"
if not doesDirectoryExist(config_dir_path) then createDirectory(config_dir_path) end

local config_file_path = config_dir_path .. "Date and Time Display by Bear v" .. script.this.version .. ".ini"

config_dir_path = nil

local config

if doesFileExist(config_file_path) then
	config = inicfg.load(nil, config_file_path)
else
	local new_config = io.open(config_file_path, "w")
	new_config:close()
	new_config = nil
	
	config = {
		Display = {
			time = true, date = false, type = false, box = false, isDTDTypeSystem = true
		},
		Text = {
			posX = 0.9, posY = 0.2, timeSize = 15, dateSize = 11, typeSize = 9, boxOpacity = tonumber("C8", 16),
			isBold = false, isItalicised = false, isBordered = true, isShadowed = true
		}
	}

	if not inicfg.save(config, config_file_path) then
		sampAddChatMessage("---- {FF88FF}Date and Time Display by Bear: {FFFFFF}Config file creation failed - contact the developer for help.", -1)
	end
end


-----------------------------------------------------
-- GLOBAL VARIABLES & FUNCTIONS
-----------------------------------------------------


local isServerTimeIntercepted, isPlayerMuted, areValsInitialized, isDTDMoveNeeded = false, false, false, false

local systemToServerTimeOffset

local window_resX, window_resY

local function fetchRes()
	window_resX, window_resY = getScreenResolution()
end

fetchRes()

local hasResChanged = true

local function timeSize()
	return window_resY * config.Text.timeSize / 1000
end

local function dateSize()
	return window_resY * config.Text.dateSize / 1000
end

local function typeSize()
	return window_resY * config.Text.typeSize / 1000
end

local drawText = {
	-- Set values in main
	line1_posX = 0, line1_blank_posX = 0, line1_posY = 0,
	line2_posX = 0, line2_blank_posX = 0, line2_posY = 0,
	line3_posX = 0, line3_posY = 0
}

-- Set values in main
local drawBox = {
	posX = 0, posY = 0,
	sizeX = 0, sizeY = 0
}

local timeFont, dateFont, typeFont

---------------------------------
-- NOE: Only use a monospaced fontface to maintain text alignment amongst lines

local fontFace = "Lucida Console"
---------------------------------

local function configureFont()
	timeFont = renderCreateFont(fontFace, timeSize(), (config.Text.isBold and fontFlags.BOLD or 0) + (config.Text.isItalicised and fontFlags.ITALICS or 0) + (config.Text.isBordered and fontFlags.BORDER or 0) + (config.Text.isShadowed and fontFlags.SHADOW or 0))
	dateFont = renderCreateFont(fontFace, dateSize(), (config.Text.isBold and fontFlags.BOLD or 0) + (config.Text.isItalicised and fontFlags.ITALICS or 0) + (config.Text.isBordered and fontFlags.BORDER or 0) + (config.Text.isShadowed and fontFlags.SHADOW or 0))
	typeFont = renderCreateFont(fontFace, typeSize(), (config.Text.isBold and fontFlags.BOLD or 0) + (config.Text.isItalicised and fontFlags.ITALICS or 0) + (config.Text.isBordered and fontFlags.BORDER or 0) + (config.Text.isShadowed and fontFlags.SHADOW or 0))
end

local function configureTextAndBox()
	local timeLength = renderGetFontDrawTextLength(timeFont, "00:00", true)
	local timeLength_blank = renderGetFontDrawTextLength(timeFont, "--", true)
	
	local dateLength = renderGetFontDrawTextLength(dateFont, "MON, JAN 01 1000", true)
	local dateLength_blank = renderGetFontDrawTextLength(dateFont, "--", true)
	
	local typeLength = config.Display.isDTDTypeSystem and renderGetFontDrawTextLength(typeFont, "SYSTEM TIME", true) or renderGetFontDrawTextLength(typeFont, "HZRP TIME", true)
	
	local spacingCoef = 1.25
	
	-------
	-- TEXT
	-------
	
	drawText.line1_posX = config.Text.posX * window_resX
	drawText.line1_blank_posX = drawText.line1_posX + ((timeLength - timeLength_blank) / 2)
	
	drawText.line2_posX = drawText.line1_posX - ((dateLength - timeLength) / 2)
	drawText.line2_blank_posX = drawText.line2_posX + ((dateLength - dateLength_blank) / 2)
	
	drawText.line3_posX = drawText.line1_posX - ((typeLength - timeLength) / 2)
	
	if config.Display.time and not config.Display.date then
		drawText.line1_posY = config.Text.posY * window_resY
		drawText.line3_posY = drawText.line1_posY + ((timeSize() + typeSize()) * spacingCoef)
	elseif config.Display.date and not config.Display.time then
		drawText.line2_posY = config.Text.posY * window_resY
		drawText.line3_posY = drawText.line2_posY + ((dateSize() + typeSize()) * spacingCoef)
	else
		drawText.line1_posY = config.Text.posY * window_resY
		drawText.line2_posY = drawText.line1_posY + ((timeSize() + dateSize()) * spacingCoef)
		drawText.line3_posY = drawText.line2_posY + ((dateSize() + typeSize()) * spacingCoef)
	end
	
	------
	-- BOX
	------
	
	if (config.Display.time and (timeLength + timeSize()) or 0) > (config.Display.date and (dateLength + dateSize()) or 0) then
		if (config.Display.time and (timeLength + timeSize()) or 0) > (config.Display.type and (typeLength + typeSize()) or 0) then
			drawBox.sizeX = timeLength + timeSize()
			drawBox.posX = drawText.line1_posX - (timeSize() / 2)
		else
			drawBox.sizeX = typeLength + typeSize()
			drawBox.posX = drawText.line3_posX - (typeSize() / 2)
		end
	elseif (config.Display.date and (dateLength + dateSize()) or 0) > (config.Display.type and (typeLength + typeSize()) or 0) then
		drawBox.sizeX = dateLength + dateSize()
		drawBox.posX = drawText.line2_posX - (dateSize() / 2)
	else
		drawBox.sizeX = typeLength + typeSize()
		drawBox.posX = drawText.line3_posX - (typeSize() / 2)
	end
	
	if config.Display.time then
		drawBox.posY = drawText.line1_posY - (timeSize() * spacingCoef / 2)
	else
		drawBox.posY = drawText.line2_posY - (dateSize() * spacingCoef / 2)
	end
	
	local new_drawBox_sizeY = 0
	
	if config.Display.time then new_drawBox_sizeY = new_drawBox_sizeY + (timeSize() * spacingCoef * 2) end
	if config.Display.date then new_drawBox_sizeY = new_drawBox_sizeY + (dateSize() * spacingCoef * 2) end
	if config.Display.type then new_drawBox_sizeY = new_drawBox_sizeY + (typeSize() * spacingCoef * 2) end
	
	drawBox.sizeY = new_drawBox_sizeY
end

boxColor = nil

local function setDrawboxColor()
	local opacity_str = ""
	local quotient = math.floor(config.Text.boxOpacity / 16)
	local remainder = config.Text.boxOpacity % 16
	
	if quotient > 9 then
		if quotient == 10 then opacity_str = "A" elseif quotient == 11 then opacity_str = "B" elseif quotient == 12 then opacity_str = "C" elseif quotient == 13 then opacity_str = "D" elseif quotient == 14 then opacity_str = "E" elseif quotient == 15 then opacity_str = "F" end
	elseif quotient > 0 then
		opacity_str = tostring(quotient)
	end
	
	if remainder > 9 then
		if remainder == 10 then opacity_str = opacity_str .. "A" elseif remainder == 11 then opacity_str = opacity_str .. "B" elseif remainder == 12 then opacity_str = opacity_str .. "C" elseif remainder == 13 then opacity_str = opacity_str .. "D" elseif remainder == 14 then opacity_str = opacity_str .. "E" elseif remainder == 15 then opacity_str = opacity_str .. "F" end
	else
		opacity_str = opacity_str .. tostring(remainder)
	end
	
	loadstring("boxColor = " .. "0x" .. opacity_str .. "000000")()
end

setDrawboxColor()

local ig_style = ig.GetStyle()

ig_style.WindowTitleAlign = ig.ImVec2(0.5, 0.5)

ig_style.Colors[ig.Col.WindowBg] = ig.ImVec4(0, 0, 0, 0.9)
ig_style.Colors[ig.Col.TitleBg] = ig.ImVec4(0, 0, 0, 0.9)
ig_style.Colors[ig.Col.TitleBgActive] = ig.ImVec4(0, 0, 0, 0.9)
ig_style.Colors[ig.Col.TitleBgCollapsed] = ig.ImVec4(0, 0, 0, 0.2)

ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
ig_style.Colors[ig.Col.ButtonHovered] = ig.ImVec4(0.2, 0.2, 0.2, 1)
ig_style.Colors[ig.Col.ButtonActive] = ig.ImVec4(0.3, 0.3, 0.3, 1)

ig_style.Colors[ig.Col.SliderGrab] = ig.ImVec4(0, 0, 0, 0.6)
ig_style.Colors[ig.Col.SliderGrabActive] = ig.ImVec4(0, 0, 0, 1)

ig_style.Colors[ig.Col.FrameBg] = ig.ImVec4(0.1, 0.1, 0.1, 1)
ig_style.Colors[ig.Col.FrameBgHovered] = ig.ImVec4(0.2, 0.2, 0.2, 1)
ig_style.Colors[ig.Col.FrameBgActive] = ig.ImVec4(0.3, 0.3, 0.3, 1)


local menu = {
	sl_timeSize = ig.ImInt(config.Text.timeSize),
	sl_dateSize = ig.ImInt(config.Text.dateSize),
	sl_typeSize = ig.ImInt(config.Text.typeSize),
	sl_boxOpacity = ig.ImInt(config.Text.boxOpacity)
}


-----------------------------------------------------
-- API-SPECIFIC FUNCTIONS
-----------------------------------------------------


-- menu
function ig.OnDrawFrame()
	local screenWidth, screenHeight = getScreenResolution()
	local setWindowWidth, setWindowHeight = screenHeight / 1.4, screenHeight / 2.6
	
	if hasResChanged then
		-- Window sizing & positioning
		ig.SetNextWindowPos(ig.ImVec2(screenWidth / 2, screenHeight / 2), ig.Cond.Always, ig.ImVec2(0.5, 0.5))
		ig.SetNextWindowSize(ig.ImVec2(setWindowWidth, setWindowHeight), ig.Cond.Always)
		
		hasResChanged = false
	end
	
	ig.Begin("Date and Time Display v" .. script.this.version)
	ig.SetWindowFontScale(screenHeight / 900)
	ig_style.WindowPadding = ig.ImVec2(screenHeight / 180, screenHeight / 180)
	ig_style.ItemSpacing = ig.ImVec2(0, 0)
	ig_style.WindowRounding = screenHeight / 100
	
	local common_buttonHeight = screenHeight / 35
	
	-----------
	-- DTD TYPE
	-----------
	
	ig.Columns(2, _, false)
	
	if config.Display.isDTDTypeSystem then
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.25, 0.25, 0.25, 1)
	else
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
	end
	
	if ig.Button("SYSTEM TIME", ig.ImVec2(ig.GetColumnWidth() - (screenHeight / 240), common_buttonHeight)) then
		config.Display.isDTDTypeSystem = true
		if inicfg.save(config, config_file_path) then
			configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
		end
	end
	
	ig.NextColumn()
	
	if config.Display.isDTDTypeSystem then
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
	else
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.25, 0.25, 0.25, 1)
	end
	
	ig.SetCursorPosX(ig.GetCursorPosX() - (screenHeight / 720))
	
	if ig.Button("HZRP TIME", ig.ImVec2(ig.GetColumnWidth() - (screenHeight / 240), common_buttonHeight)) then
		if string.find(sampGetCurrentServerName(), "Horizon Roleplay") then
			config.Display.isDTDTypeSystem = false
			if inicfg.save(config, config_file_path) then
				configureTextAndBox()
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
			end
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Connect to Horizon Roleplay for server time.", -1)
		end
	end
	
	ig.Columns()
	ig.NewLine() ig.NewLine()
	
	-----------------------
	-- LINE TOGGLES & SIZES
	-----------------------
	
	ig.PushItemWidth(ig.GetWindowWidth() / 1.235)
	ig_style.ItemSpacing = ig.ImVec2(0, screenHeight / 200)
	
	if ig.RadioButton("Time", config.Display.time) then
		config.Display.time = not config.Display.time
		
		if inicfg.save(config, config_file_path) then
			configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.SameLine() ig.SetCursorPosX(ig.GetWindowWidth() / 11)
	
	if ig.SliderInt("Time Size", menu.sl_timeSize, 5, 50) then
		if not tonumber(menu.sl_timeSize.v) or not (tonumber(menu.sl_timeSize.v) > 4) or not (tonumber(menu.sl_timeSize.v) < 51) then
			menu.sl_timeSize.v = "15"
		end
		
		config.Text.timeSize = tonumber(menu.sl_timeSize.v)
		
		if inicfg.save(config, config_file_path) then
			configureFont() configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	if ig.RadioButton("Date", config.Display.date) then
		config.Display.date = not config.Display.date
		
		if inicfg.save(config, config_file_path) then
			configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.SameLine() ig.SetCursorPosX(ig.GetWindowWidth() / 11)
	
	if ig.SliderInt("Date Size", menu.sl_dateSize, 5, 50) then
		if not tonumber(menu.sl_dateSize.v) or not (tonumber(menu.sl_dateSize.v) > 4) or not (tonumber(menu.sl_dateSize.v) < 51) then
			menu.sl_dateSize.v = "8"
		end
		
		config.Text.dateSize = tonumber(menu.sl_dateSize.v)
		
		if inicfg.save(config, config_file_path) then
			configureFont() configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	if ig.RadioButton("Type", config.Display.type) then
		config.Display.type = not config.Display.type
		
		if inicfg.save(config, config_file_path) then
			configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.SameLine() ig.SetCursorPosX(ig.GetWindowWidth() / 11)
	
	if ig.SliderInt("Type Size", menu.sl_typeSize, 5, 50) then
		if not tonumber(menu.sl_typeSize.v) or not (tonumber(menu.sl_typeSize.v) > 4) or not (tonumber(menu.sl_typeSize.v) < 51) then
			menu.sl_typeSize.v = "15"
		end
		
		config.Text.typeSize = tonumber(menu.sl_typeSize.v)
		
		if inicfg.save(config, config_file_path) then
			configureFont() configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	if ig.RadioButton("Box", config.Display.box) then
		config.Display.box = not config.Display.box
		
		if not inicfg.save(config, config_file_path) then
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig_style.ItemSpacing = ig.ImVec2(0, 0)
	
	ig.SameLine() ig.SetCursorPosX(ig.GetWindowWidth() / 11)
	
	if ig.SliderInt("Opacity", menu.sl_boxOpacity, 1, 255) then
		if not tonumber(menu.sl_boxOpacity.v) or not (tonumber(menu.sl_boxOpacity.v) > 0) or not (tonumber(menu.sl_boxOpacity.v) < 256) then
			menu.sl_boxOpacity.v = tostring(tonumber("C8", 16))
		end
		
		config.Text.boxOpacity = tonumber(menu.sl_boxOpacity.v)
		
		if inicfg.save(config, config_file_path) then
			setDrawboxColor()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.NewLine() ig.NewLine()
	
	------------------------
	-- FORMATTING & MOVEMENT
	------------------------
	
	ig.Columns(4, _, false)
	
	if config.Text.isBold then
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.25, 0.25, 0.25, 1)
	else
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
	end
	
	if ig.Button("BOLD", ig.ImVec2(ig.GetColumnWidth() - (screenHeight / 240), common_buttonHeight)) then
		config.Text.isBold = not config.Text.isBold
		
		if inicfg.save(config, config_file_path) then
			configureFont() configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.NextColumn()
	
	if config.Text.isItalicised then
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.25, 0.25, 0.25, 1)
	else
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
	end
	
	if ig.Button("ITALICS", ig.ImVec2(ig.GetColumnWidth() - (screenHeight / 240), common_buttonHeight)) then
		config.Text.isItalicised = not config.Text.isItalicised
		
		if inicfg.save(config, config_file_path) then
			configureFont() configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.NextColumn()
	
	if config.Text.isBordered then
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.25, 0.25, 0.25, 1)
	else
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
	end
	
	if ig.Button("BORDER", ig.ImVec2(ig.GetColumnWidth() - (screenHeight / 240), common_buttonHeight)) then
		config.Text.isBordered = not config.Text.isBordered
		
		if inicfg.save(config, config_file_path) then
			configureFont() configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.NextColumn()
	ig.SetCursorPosX(ig.GetCursorPosX() - (screenHeight / 360))
	
	if config.Text.isShadowed then
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.25, 0.25, 0.25, 1)
	else
		ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
	end
	
	if ig.Button("SHADOW", ig.ImVec2(ig.GetColumnWidth() - (screenHeight / 240), common_buttonHeight)) then
		config.Text.isShadowed = not config.Text.isShadowed
		
		if inicfg.save(config, config_file_path) then
			configureFont() configureTextAndBox()
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving display data to config failed - contact the developer for help.", -1)
		end
	end
	
	ig.Columns() ig.NewLine()
	
	ig_style.Colors[ig.Col.Button] = ig.ImVec4(0.1, 0.1, 0.1, 1)
	
	if ig.Button("MOVE DISPLAY [/MOVEDTD]", ig.ImVec2(ig.GetWindowWidth() - (screenHeight / 90), common_buttonHeight)) then
		isDTDMoveNeeded = not isDTDMoveNeeded
		ig.Process = false
	end
	
	------------------
	-- CREDITS & CLOSE
	------------------
	
	ig.SetCursorPosY(setWindowHeight * 0.83)
	
	ig.Text("Developer: Bear (Swapnil#9308)")
	
	ig.NewLine()
	
	if ig.Button("CLOSE", ig.ImVec2(ig.GetWindowWidth() - (screenHeight / 90), common_buttonHeight)) then ig.Process = false end
	
	ig.End()
end

function sampev.onDisplayGameText(_, _, gameText)
	if string.find(sampGetCurrentServerName(), "Horizon Roleplay") and gameText:find("~y~%d%d? %a+~n~~g~%a+~n~~w~%d%d?:%d%d$") then
		-- Calculating time offset (server time - system time)
		local serverTime_dayOfMonth = gameText:match("%d+")
		
		local serverTime_month
		if gameText:match("%a+", 6) == "January" then serverTime_month = 1
		elseif gameText:match("%a+", 6) == "February" then serverTime_month = 2
		elseif gameText:match("%a+", 6) == "March" then serverTime_month = 3
		elseif gameText:match("%a+", 6) == "April" then serverTime_month = 4
		elseif gameText:match("%a+", 6) == "May" then serverTime_month = 5
		elseif gameText:match("%a+", 6) == "June" then serverTime_month = 6
		elseif gameText:match("%a+", 6) == "July" then serverTime_month = 7
		elseif gameText:match("%a+", 6) == "August" then serverTime_month = 8
		elseif gameText:match("%a+", 6) == "September" then serverTime_month = 9
		elseif gameText:match("%a+", 6) == "October" then serverTime_month = 10
		elseif gameText:match("%a+", 6) == "November" then serverTime_month = 11
		elseif gameText:match("%a+", 6) == "December" then serverTime_month = 12
		elseif config.Display.isDTDTypeSystem == false then
			sampAddChatMessage("---- {FF88FF}Date and Time Display: {FFFFFF}Failure to detect server time's month - contact the developer for help.", -1)
			
			config.Display.isDTDTypeSystem = true
			if inicfg.save(config, config_file_path) then
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Showing System Time", -1)
				return false
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
			end
		end
		
		local serverTime_hour = string.match(gameText:match("~w~%d%d?:"), "%d+")
		
		local serverTime_minute = string.sub(gameText:match(":%d%d"), 2, 3)
		
		systemToServerTimeOffset =
			os.time{year = os.date("%Y"), month = serverTime_month, day = serverTime_dayOfMonth, hour = serverTime_hour, min = serverTime_minute}
			- os.time{year = os.date("%Y"), month = os.date("%m"), day = os.date("%d"), hour = os.date("%H"), min = os.date("%M")}
		
		if not isServerTimeIntercepted then
			isServerTimeIntercepted = true
			return false -- Prevents the /time response banner text from forming only if /time is entered by the mod
		end
	end
end

function sampev.onServerMessage(_, msg_text)
	if
	string.find(sampGetCurrentServerName(), "Horizon Roleplay")
	and string.sub(msg_text, 1, 48) == "You have been muted automatically for spamming. " then
		isPlayerMuted = true
	end
end

function onD3DPresent()
	if areValsInitialized and not isPauseMenuActive() and sampGetChatDisplayMode() > 0 then
		if (config.Display.time or config.Display.date) and config.Display.box then
			renderDrawBox(drawBox.posX, drawBox.posY, drawBox.sizeX, drawBox.sizeY, boxColor)
		end
		
		if config.Display.isDTDTypeSystem then
			if config.Display.time then
				renderFontDrawText(timeFont, os.date("%H:%M"), drawText.line1_posX, drawText.line1_posY, 0xFFFFFFFF, true)
			end
			
			if config.Display.date then
				renderFontDrawText(dateFont, os.date("%a, %b %d %Y"):upper(), drawText.line2_posX, drawText.line2_posY, 0xFFFFFFFF, true)
			end
			
			if (config.Display.time or config.Display.date) and config.Display.type then
				renderFontDrawText(typeFont, "SYSTEM TIME", drawText.line3_posX, drawText.line3_posY, 0xFFFFFFFF, true)
			end
		elseif isServerTimeIntercepted then
			if config.Display.time then
				renderFontDrawText(timeFont, os.date("%H:%M", os.time() + systemToServerTimeOffset), drawText.line1_posX, drawText.line1_posY, 0xFFFFFFFF, true)
			end
			
			if config.Display.date then
				renderFontDrawText(dateFont, os.date("%a, %b %d %Y", os.time() + systemToServerTimeOffset):upper(), drawText.line2_posX, drawText.line2_posY, 0xFFFFFFFF, true)
			end
			
			if (config.Display.time or config.Display.date) and config.Display.type then
				renderFontDrawText(typeFont, "HZRP TIME", drawText.line3_posX, drawText.line3_posY, 0xFFFFFFFF, true)
			end
		elseif config.Display.time then
			renderFontDrawText(timeFont, "--", drawText.line1_blank_posX, drawText.line1_posY, 0xFFFFFFFF, true)
		elseif config.Display.date then
			renderFontDrawText(dateFont, "--", drawText.line2_blank_posX, drawText.line2_posY, 0xFFFFFFFF, true)
		end
	end
end


-----------------------------------------------------
-- MAIN
-----------------------------------------------------


function main()
	configureFont() configureTextAndBox()
	areValsInitialized = true
	
	repeat wait(50) until isSampAvailable()
	
	sampAddChatMessage("--- {FF88FF}Date and Time Display v" .. script.this.version .. " {FFFFFF}by Bear | Use {FF88FF}/dtd", -1)
	
	function cmd_dtd() ig.Process = not ig.Process end
	sampRegisterChatCommand("dtd", cmd_dtd)
	sampRegisterChatCommand("dtdhelp", cmd_dtd) -- alias to the above
	
	sampRegisterChatCommand("movedtd", function () isDTDMoveNeeded = not isDTDMoveNeeded end)
	
	sampRegisterChatCommand("dtdtype", function ()
		if config.Display.isDTDTypeSystem then
			if string.find(sampGetCurrentServerName(), "Horizon Roleplay") then
				config.Display.isDTDTypeSystem = false
				if inicfg.save(config, config_file_path) then
					sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Showing Server Time", -1)
				else
					sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
				end
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Connect to Horizon Roleplay for server time.", -1)
			end
		else
			config.Display.isDTDTypeSystem = true
			if inicfg.save(config, config_file_path) then
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Showing System Time", -1)
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
			end
		end
	end)
	
	sampRegisterChatCommand("dtdbox", function()
		config.Display.box = not config.Display.box
		
		if config.Display.box then
			if inicfg.save(config, config_file_path) then
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Box On", -1)
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display toggle in config failed - contact the developer for help.", -1)
			end
		else
			if inicfg.save(config, config_file_path) then
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Box Off", -1)
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display toggle in config failed - contact the developer for help.", -1)
			end
		end
	end)
	
	-- An extra thread that initiates a 13-second spam cooldown
	lua_thread.create(function()
		while true do
			wait(200)
			if isPlayerMuted then wait(13000) isPlayerMuted = false end
		end
	end)
	
	lua_thread.create(function()
		local r1_x, r1_y
		
		while true do
			r1_x, r1_y = getScreenResolution()
			wait(1000)
			fetchRes()
			
			if not (r1_x == window_resX and r1_y == window_resY) then
				configureFont() configureTextAndBox()
				
				hasResChanged = true
			end
		end
	end)
	
	lua_thread.create(function()
		while true do
			wait(500)
			
			if isDTDMoveNeeded then
				posX_original, posY_original = config.Text.posX, config.Text.posY
				sampToggleCursor(true)
				
				repeat
					wait(0)
					
					local cursorX, cursorY = getCursorPos()
					config.Text.posX, config.Text.posY = cursorX / window_resX, cursorY / window_resY
					configureTextAndBox()
				until wasKeyPressed(vk.VK_LBUTTON) or not isDTDMoveNeeded
				
				if isDTDMoveNeeded then
					repeat wait(0) until wasKeyReleased(vk.VK_LBUTTON)
					sampToggleCursor(false)
					
					if not inicfg.save(config, config_file_path) then
						sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Saving new position failed - contact the developer for help.", -1)
					end
					
					isDTDMoveNeeded = false
				else
					sampToggleCursor(false)
					config.Text.posX, config.Text.posY = posX_original, posY_original
					
					configureTextAndBox()
				end
			end
		end
	end)
	
	while true do
		while config.Display.isDTDTypeSystem do wait(100) end
		
		isServerTimeIntercepted = false
		
		repeat
			while isPlayerMuted do wait(0) end
			sampSendChat("/time")
			
			for i = 1, 20 do -- ~2 second loop
				if isServerTimeIntercepted or config.Display.isDTDTypeSystem then
					break
				end
				
				wait(100)
			end
		until isServerTimeIntercepted or config.Display.isDTDTypeSystem
		
		if isServerTimeIntercepted then configureTextAndBox() end
		
		repeat wait(100) until config.Display.isDTDTypeSystem
	end
end