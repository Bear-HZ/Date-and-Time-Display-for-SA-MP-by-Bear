-----------------------------------------------------
-- INFO
-----------------------------------------------------


script_name("Date and Time Display by Bear")
script_author("Bear")
script_version("0.2.2")
local script_version = "0.2.2"


-----------------------------------------------------
-- HEADERS & CONFIG
-----------------------------------------------------


local sampev = require "lib.samp.events"
local inicfg = require "inicfg"

local config_dir_path = getWorkingDirectory() .. "\\config\\"
if not doesDirectoryExist(config_dir_path) then createDirectory(config_dir_path) end

local config_file_path = config_dir_path .. "Date and Time Display by Bear.ini"

config_dir_path = nil

local config_table

if doesFileExist(config_file_path) then
	config_table = inicfg.load(nil, config_file_path)
else
	local new_config = io.open(config_file_path, "w")
	new_config:close()
	new_config = nil
	
	config_table = {
		Options = {
			isDTDDisabled = false,
			position_horizontalOffset = 900,
			position_verticalOffset = 250,
			isDTDTypeSetToSystem = true
		}
	}

	if not inicfg.save(config_table, config_file_path) then
		sampAddChatMessage("---- {FF88FF}Date and Time Display by Bear: {FFFFFF}Config file creation failed - contact the developer for help.", -1)
	end
end


-----------------------------------------------------
-- GLOBAL VARIABLES
-----------------------------------------------------


local textSize = 1 -- Changing this might cause the 2 textdraws to overlap/separate

local isRedrawNeeded = false

local isServerTimeIntercepted = false

local systemToServerTimeOffset


-----------------------------------------------------
-- API-SPECIFIC FUNCTIONS
-----------------------------------------------------


function sampev.onDisplayGameText(_, _, gameText)
	if string.find(sampGetCurrentServerName(), "Horizon Roleplay") then
		if gameText:find("~y~%d%d? %a+~n~~g~%a+~n~~w~%d%d?:%d%d$") then
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
			else
				sampAddChatMessage("---- {FF88FF}Date and Time Display by Bear: {FFFFFF}Failure to detect server time's month - contact the developer for help.", -1)
				
				config_table.Options.isDTDTypeSetToSystem = true
				if inicfg.save(config_table, config_file_path) then
					sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Showing System Time", -1)
					return false
				else
					sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
					thisscript():unload()
				end
			end
			
			local serverTime_hour = string.match(gameText:match("~w~%d%d:"), "%d%d")
			
			local serverTime_minute = string.sub(gameText:match(":%d%d"), 2, 3)
			
			systemToServerTimeOffset =
				os.time{year = os.date("%Y"), month = serverTime_month, day = serverTime_dayOfMonth, hour = serverTime_hour, min = serverTime_minute}
				- os.time{year = os.date("%Y"), month = os.date("%m"), day = os.date("%d"), hour = os.date("%H"), min = os.date("%M")}

			-- If the time difference (which should be a multiple of 30 mins) happens to be calculated a minute more or less, this rectifies the discrepancy
			if systemToServerTimeOffset % 600 ~= 0 then
				if (systemToServerTimeOffset + 60) % 600 == 0 then
					systemToServerTimeOffset = systemToServerTimeOffset + 60
				elseif (systemToServerTimeOffset - 60) % 600 == 0 then
					systemToServerTimeOffset = systemToServerTimeOffset - 60
				end
			end
			
			-- As of Jan 2023, the server time seems to be running ~10 seconds past GMT. This adjustment accounts for that.
			systemToServerTimeOffset = systemToServerTimeOffset + 10
			
			if not isServerTimeIntercepted then
				isServerTimeIntercepted = true
				return false -- Prevents the /time response banner text from forming only if /time is entered by the mod
			end
		end
	end
end


-----------------------------------------------------
-- LOCALLY DECLARED FUNCTIONS
-----------------------------------------------------


local function makeTextdraws()
	local window_resX, window_resY = getScreenResolution()
	local game_resX, game_resY = convertWindowScreenCoordsToGameScreenCoords(window_resX, window_resY)
	
	-- Hour and minute
	sampTextdrawCreate(1313, "", game_resX * config_table.Options.position_horizontalOffset / 1000, game_resY * config_table.Options.position_verticalOffset / 1000)
	sampTextdrawSetStyle(1313, 2)
	sampTextdrawSetAlign(1313, 2)
	sampTextdrawSetLetterSizeAndColor(1313, textSize / 2, textSize * 2, 0xFFFFFFFF)
	sampTextdrawSetBoxColorAndSize(1313, 1, 0x50000000, 0, game_resY * textSize / 5.5)
	
	-- Day of week, day of month, month of year and the year
	sampTextdrawCreate(1314, "", game_resX * config_table.Options.position_horizontalOffset / 1000, game_resY * config_table.Options.position_verticalOffset / 1000 + (textSize * game_resY * 0.048)) -- 0.048 if textSize is 1; calibrate it yourself for other sizes
	sampTextdrawSetStyle(1314, 1)
	sampTextdrawSetAlign(1314, 2)
	sampTextdrawSetLetterSizeAndColor(1314, textSize / 4, textSize, 0xFFFFFFFF)
	sampTextdrawSetBoxColorAndSize(1314, 1, 0x50000000, 0, game_resY * textSize / 5.5)
	
	-- Source of data (system time or server time)
	sampTextdrawCreate(1315, "", game_resX * config_table.Options.position_horizontalOffset / 1000, game_resY * config_table.Options.position_verticalOffset / 1000 + (textSize * game_resY * 0.0755)) -- 0.0755 if textSize is 1; calibrate it yourself for other sizes
	sampTextdrawSetStyle(1315, 1)
	sampTextdrawSetAlign(1315, 2)
	sampTextdrawSetLetterSizeAndColor(1315, textSize / 6, textSize / 1.5, 0xFFFFFFFF)
	sampTextdrawSetBoxColorAndSize(1315, 1, 0x50000000, 0, game_resY * textSize / 5.5)
	
	if config_table.Options.isDTDTypeSetToSystem then
		-- Hour and minute
		sampTextdrawSetString(1313, os.date("%H:%M"))
		-- Day of week, day of month, month of year and the year
		sampTextdrawSetString(1314, os.date("%a,\t%b\t%d\t%Y")) -- 0.048 if textSize is 1; calibrate it yourself for other sizes
		-- Source of data (system time or server time)
		sampTextdrawSetString(1315, "System Time") -- 0.0755 if textSize is 1; calibrate it yourself for other sizes
	else
		sampTextdrawSetString(1313, "--")
		sampTextdrawSetString(1314, "Loading...")
		sampTextdrawSetString(1315, "--")
		
		isServerTimeIntercepted = false
		
		repeat
			sampSendChat("/time")
			
			for i = 1, 20 do -- ~2 second loop
				if isServerTimeIntercepted or config_table.Options.isDTDTypeSetToSystem then
					break
				end
				
				wait(100)
			end
		until isServerTimeIntercepted or config_table.Options.isDTDTypeSetToSystem
		
		if config_table.Options.isDTDTypeSetToSystem then -- if a loop was exited due to DTD type change
			makeTextdraws()
			return
		end
		
		-- Hour and minute
		sampTextdrawSetString(1313, os.date("%H:%M", os.time() + systemToServerTimeOffset))
		-- Day of week, day of month, month of year and the year
		sampTextdrawSetString(1314, os.date("%a,\t%b\t%d\t%Y", os.time() + systemToServerTimeOffset)) -- 0.048 if textSize is 1; calibrate it yourself for other sizes
		-- Source of data (system time or server time)
		sampTextdrawSetString(1315, "HZRP Time") -- 0.0755 if textSize is 1; calibrate it yourself for other sizes
	end
end


-----------------------------------------------------
-- MAIN
-----------------------------------------------------


function main()
	repeat wait(50) until isSampAvailable()
	
	-- Remove any existing textdraws with the same IDs
	sampTextdrawDelete(1313)
	sampTextdrawDelete(1314)
	sampTextdrawDelete(1315)
	
	sampAddChatMessage("--- {FF88FF}Date and Time Display v" .. script_version .. " {FFFFFF}by Bear | Use {FF88FF}/dtdhelp", -1)
	
	sampRegisterChatCommand("dtd", cmd_dtd)
	sampRegisterChatCommand("movedtd", cmd_movedtd)
	sampRegisterChatCommand("dtdhelp", cmd_dtdhelp)
	sampRegisterChatCommand("dtdtype", cmd_dtdtype)
	
	while true do
		while config_table.Options.isDTDDisabled do wait(100) end
		
		
		repeat
			makeTextdraws()
			
			repeat
				if config_table.Options.isDTDTypeSetToSystem then
					sampTextdrawSetString(1313, os.date("%H:%M"))
					sampTextdrawSetString(1314, os.date("%a,\t%b\t%d\t%Y"))
				else
					sampTextdrawSetString(1313, os.date("%H:%M", os.time() + systemToServerTimeOffset))
					sampTextdrawSetString(1314, os.date("%a,\t%b\t%d\t%Y", os.time() + systemToServerTimeOffset))
				end
				
				wait(500)
			until isRedrawNeeded or config_table.Options.isDTDDisabled
		
			if isRedrawNeeded then isRedrawNeeded = false end
		until config_table.Options.isDTDDisabled
		
		sampTextdrawDelete(1313)
		sampTextdrawDelete(1314)
		sampTextdrawDelete(1315)
	end
end


-----------------------------------------------------
-- COMMAND-SPECIFIC FUNCTIONS
-----------------------------------------------------


function cmd_dtd()
	if config_table.Options.isDTDDisabled then
		config_table.Options.isDTDDisabled = false
		if inicfg.save(config_table, config_file_path) then
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}On", -1)
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display toggle in config failed - contact the developer for help.", -1)
		end
	else
		config_table.Options.isDTDDisabled = true
		if inicfg.save(config_table, config_file_path) then
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Off", -1)
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display toggle in config failed - contact the developer for help.", -1)
		end
	end
end

function cmd_dtdtype()
	if config_table.Options.isDTDTypeSetToSystem then
		if string.find(sampGetCurrentServerName(), "Horizon Roleplay") then
			config_table.Options.isDTDTypeSetToSystem = false
			if inicfg.save(config_table, config_file_path) then
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Showing Server Time", -1)
				isRedrawNeeded = true
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
			end
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Connect to Horizon Roleplay for server time.", -1)
		end
	else
		config_table.Options.isDTDTypeSetToSystem = true
		if inicfg.save(config_table, config_file_path) then
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Showing System Time", -1)
			isRedrawNeeded = true
		else
			sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display type toggle in config failed - contact the developer for help.", -1)
		end
	end
end

function cmd_movedtd(args)
	if #args == 0 or not args:find("[^%s]") then
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {FF88FF}Usage:", -1)
		sampAddChatMessage("/movedtd (horizontal offset) (vertical offset)", -1)
		sampAddChatMessage("Both offsets should range from 0 to 1000.", -1)
		sampAddChatMessage("{FF88FF}Default: {FFFFFF}/movedtd 900 250", -1)
		sampAddChatMessage(" ", -1)
	elseif args:find("%s*%d+%s+%d+%s*$") then
		local arg_horizontalOffset = tonumber(args:match("%d+"))
		local arg_verticalOffset = tonumber(string.match(args:match("%d%s+%d+"), "%d+", 3))
		
		if
		0 <= arg_horizontalOffset and arg_horizontalOffset <= 1000
		and 0 <= arg_verticalOffset and arg_verticalOffset <= 1000
		then
			config_table.Options.position_horizontalOffset = arg_horizontalOffset
			config_table.Options.position_verticalOffset = arg_verticalOffset
			
			if inicfg.save(config_table, config_file_path) then
				sampAddChatMessage("--- {FF88FF}Updated Position: {FFFFFF} " .. config_table.Options.position_horizontalOffset .. ", " .. config_table.Options.position_verticalOffset, -1)
				isRedrawNeeded = true
			else
				sampAddChatMessage("--- {FF88FF}Date and Time Display: {FFFFFF}Display position adjustment in config failed - contact the developer for help.", -1)
			end
		else
			sampAddChatMessage(" ", -1)
			sampAddChatMessage("--- {FF6666}Invalid Entry {FFFFFF}| Both numbers should range from 0 to 1000.", -1)
			sampAddChatMessage("{FF88FF}Default: {FFFFFF}/movedtd 900 250", -1)
			sampAddChatMessage(" ", -1)
		end
	else
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {FF6666}Invalid Entry {FFFFFF}| {FF88FF}Usage:", -1)
		sampAddChatMessage("/movedtd (horizontal offset) (vertical offset)", -1)
		sampAddChatMessage("Both offsets should range from 0 to 1000.", -1)
		sampAddChatMessage("{FF88FF}Default: {FFFFFF}/movedtd 900 250", -1)
		sampAddChatMessage(" ", -1)
	end
end

function cmd_dtdhelp()
	sampAddChatMessage("------ {FF88FF}Date and Time Display by Bear - v" .. script_version .. " {FFFFFF}------", -1)
	sampAddChatMessage(" ", -1)
	sampAddChatMessage("{FF88FF}/dtd {FFFFFF}- Toggle the Date and Time Display", -1)
	sampAddChatMessage("{FF88FF}/movedtd (0-1000) (0-1000) {FFFFFF}- Adjust Display Position, Offset From Top-Left", -1)
	sampAddChatMessage(" ", -1)
	sampAddChatMessage("{FF88FF}Developer: {FFFFFF}Bear (Swapnil#9308)", -1)
	sampAddChatMessage(" ", -1)
	sampAddChatMessage("------------", -1)
end
