local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramework

local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function rand_str(length)
	local res = ""
	for _ = 1, length, 1 do
		local randInt = math.random(1, #charset)
		res = res .. charset:sub(randInt, randInt)
	end

	return res
end

local ADDON_NAME = rand_str(math.random(6, 10))
local BOUND_TAGS = 1
local callbacks = {}

local function register_handle(key)
	_G["SLASH_" .. ADDON_NAME .. BOUND_TAGS] = "/" .. key
	BOUND_TAGS = BOUND_TAGS + 1
end

local function no_cmd_message()
	local purpleHex = "|cFF8788EE"
	print(purpleHex .. "Available commands: ")

	for key, value in pairs(callbacks) do
		local hint = value.help or "No info"
		print(" - " .. purpleHex .. key .. "|r : " .. purpleHex .. hint)
	end
end

local function slash_handler(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if cmd and callbacks[cmd] then
		callbacks[cmd].callback(args)
	elseif not cmd or cmd == "" then
		no_cmd_message()
	else
		local redHex = "|cFFFF0000"
		print(redHex .. "Unknown command: " .. cmd)
	end

	return true
end

SlashCmdList[ADDON_NAME] = slash_handler

register_handle("mak")
register_handle("makulu")
register_handle("clipper")
local Aware = MakuluFramework.Aware
local GetSpellTexture = C_Spell.GetSpellTexture

local function registerHandler(tag, callback, help, flags)
	local callback_obj = {
		tag = tag,
		callback = callback,
		help = help,
		flags = flags,
	}

	callbacks[tag] = callback_obj
end

local function burstModeHandler()
	if MakuluFramework.burstMode then
		return
	end

	MakuluFramework.burstMode = true
	local purpleHex = "|cFF8788EE"
	local greenHex = "|cFF00FF00"
	local resetHex = "|r"

	local message = purpleHex .. " - Force Burst" .. resetHex .. " | " .. greenHex .. "Enabled!" .. resetHex

	local iconTexture = GetSpellTexture(381623)
	Aware:displayMessage(message, "White", 10, iconTexture, true)

	C_Timer.After(8, function()
		MakuluFramework.burstMode = false
	end)
end

local function rampModeHandler()
	if MakuluFramework.rampMode then
		return
	end

	MakuluFramework.rampMode = true
	local purpleHex = "|cFF8788EE"
	local greenHex = "|cFF00FF00"
	local resetHex = "|r"

	local message = purpleHex .. " - Force Ramp" .. resetHex .. " | " .. greenHex .. "Enabled!" .. resetHex

	local iconTexture = GetSpellTexture(381623)
	--Aware:displayMessage(message, "White", 10, iconTexture, true)

	C_Timer.After(MakuluFramework.rampModeTimer, function()
		MakuluFramework.rampMode = false
	end)
end

MakuluFramework.Commands = {
	register = registerHandler,
}

MakuluFramework.burstMode = false
MakuluFramework.rampMode = false

MakuluFramework.rampModeTimer = 8

-- Register burst command
MakuluFramework.Commands.register("burst", burstModeHandler, "Enable burst mode for 8 seconds", {})
MakuluFramework.Commands.register("ramp", rampModeHandler, "Enable ramp mode for 8 seconds", {})

local function useTrinketHandler()
	local trinket1 = 229492
	local trinket2 = 229783

	local function useTrinket(trinketID)
		local usable, noMana = C_Item.IsUsableItem(trinketID)
		local count = C_Item.GetItemCount(trinketID)
		local startTime, duration, enable = C_Item.GetItemCooldown(trinketID)
		local equipped = C_Item.IsEquippedItem(trinketID)

		if not equipped then
			return Aware:displayMessage(" - No trinket equipped!", "Red", 1.4, C_Spell.GetSpellTexture(208683))
		end

		if duration > 0 then
			return Aware:displayMessage(" - Trinket is on CD!", "Red", 1.4, C_Spell.GetSpellTexture(208683))
		end

		if not usable then
			return
		end

		if not MakuluFramework.ConstUnits.player.cc or MakuluFramework.ConstUnits.player.ccRemains <= 500 then
			return Aware:displayMessage(" - We are not in CC!", "Red", 1.4, C_Spell.GetSpellTexture(208683))
		end

		UseItemByName(trinketID) -- this works but C_Item.UseItemByName doesnt
		Aware:displayMessage(" - Using Trinket [MACRO]", "Green", 1.4, C_Spell.GetSpellTexture(208683))
	end

	if C_Item.GetItemCount(trinket1) > 0 and C_Item.IsEquippedItem(trinket1) then
		useTrinket(trinket1)
	elseif C_Item.GetItemCount(trinket2) > 0 and C_Item.IsEquippedItem(trinket2) then
		useTrinket(trinket2)
	end
end

MakuluFramework.Commands.register("trinket", useTrinketHandler, "Use Medallion Trinket", {})

