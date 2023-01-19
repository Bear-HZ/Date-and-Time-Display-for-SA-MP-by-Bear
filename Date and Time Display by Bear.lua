-----------------------------------------------------
-- INFO
-----------------------------------------------------


script_name("Date and Time Display by Bear")
script_author("Bear")
script_version("0.1.0")
local script_version = "0.1.0"


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
			position_verticalOffset = 250
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


-----------------------------------------------------
-- LOCALLY DECLARED FUNCTIONS
-----------------------------------------------------


local function makeTextdraws()
	local window_resX, window_resY = getScreenResolution()
	local game_resX, game_resY = convertWindowScreenCoordsToGameScreenCoords(window_resX, window_resY)
	
	-- Hour and minute
	sampTextdrawCreate(1313, os.date("%H:%M"), game_resX * config_table.Options.position_horizontalOffset / 1000, game_resY * config_table.Options.position_verticalOffset / 1000)
	sampTextdrawSetStyle(1313, 2)
	sampTextdrawSetAlign(1313, 2)
	sampTextdrawSetLetterSizeAndColor(1313, textSize / 2, textSize * 2, 0xFFFFFFFF)
	sampTextdrawSetBoxColorAndSize(1313, 1, 0x50000000, 0, game_resY * textSize / 5.5)
	
	-- Day of week, day of month, month of year and the year
	sampTextdrawCreate(1314, os.date("%a,\t%b\t%d\t%Y"), game_resX * config_table.Options.position_horizontalOffset / 1000, game_resY * config_table.Options.position_verticalOffset / 1000 + (textSize * game_resY * 0.048)) -- 0.048 if textSize is 1; calibrate it yourself for other sizes
	sampTextdrawSetStyle(1314, 1)
	sampTextdrawSetAlign(1314, 2)
	sampTextdrawSetLetterSizeAndColor(1314, textSize / 4, textSize, 0xFFFFFFFF)
	sampTextdrawSetBoxColorAndSize(1314, 1, 0x50000000, 0, game_resY * textSize / 5.5)
end


-----------------------------------------------------
-- MAIN
-----------------------------------------------------


function main()
	---------------
	-- INITIALIZING
	---------------
	
	repeat wait(50) until isSampAvailable()
	
	sampTextdrawDelete(1313) -- Removes any existing textdraws with the same ID
	
	sampAddChatMessage("--- {FF88FF}Date and Time Display v" .. script_version .. " {FFFFFF}by Bear | Use {FF88FF}/dtdhelp", -1)
	
	sampRegisterChatCommand("dtd", cmd_dtd)
	sampRegisterChatCommand("movedtd", cmd_movedtd)
	sampRegisterChatCommand("dtdhelp", cmd_dtdhelp)
	
	while true do
		while config_table.Options.isDTDDisabled do wait(100) end
		
		makeTextdraws() -- Create the textdraws
		
		repeat
			repeat
				sampTextdrawSetString(1313, os.date("%H:%M"))
				sampTextdrawSetString(1314, os.date("%a,\t%b\t%d\t%Y"))
				
				wait(500)
			until isRedrawNeeded or config_table.Options.isDTDDisabled
			
			-- Remake the textdraws if settings are changed
			if isRedrawNeeded then
				isRedrawNeeded = false
				makeTextdraws()
			end
		until config_table.Options.isDTDDisabled
		
		sampTextdrawDelete(1313)
		sampTextdrawDelete(1314)
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
