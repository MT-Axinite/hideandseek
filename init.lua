-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local checkinterval = 2

-- Table Save Load Functions
local function save_data()
	if hideandseek.players == nil then
		return
	end

	local file = io.open(minetest.get_worldpath().."/hideandseek.txt", "w")
	if file then
		file:write(minetest.serialize(hideandseek.players))
		file:close()
	end
end

local function load_data()
	if hideandseek.players == nil then
		local file = io.open(minetest.get_worldpath().."/hideandseek.txt", "r")
		if file then
			local table = minetest.deserialize(file:read("*all"))
			if type(table) == "table" then
				hideandseek.players = table
				return
			end
		end
	end
	hideandseek.players = {}
end

local function distance(v, w)
	return math.sqrt(
		math.pow(v.x - w.x, 2) +
		math.pow(v.y - w.y, 2) +
		math.pow(v.z - w.z, 2)
	)
end

hideandseek = {

	zone = {["x"] = 6208, ["y"] = 301, ["z"] = 15726},
	radius = 150,

	players = nil,
	userdata = {},

	createPlayerTable = function(player)
		if not hideandseek.players then
			load_data()
		end

		if not player or not player:get_player_name() then
			return;
		end

		local name = player:get_player_name()

		if (name=="") then
			return;
		end

		hideandseek.players[name] = {}
		hideandseek.userdata[name] = player
	end,

	calculate_current_area = function(player)
		local name = player:get_player_name()
		if (name=="") then
			return;
		end
		if (not hideandseek.players[name]) then
			hideandseek.createPlayerTable(player)
		end
		if distance(player:getpos(),hideandseek.zone) < hideandseek.radius
			and not minetest.check_player_privs(player:get_player_name(),{ban = true}) then
			if (not hideandseek.players[name].zone or hideandseek.players[name].zone==false) then
				hideandseek.enter_area(player)
			end
		else
			if  (hideandseek.players[name].zone==true) then
				hideandseek.leave_area(player)
			end
		end
	end,

	enter_area = function(player)
		local name = player:get_player_name()
		hideandseek.players[name].zone=true
		-- save data
		save_data()
		-- Hide nametag
		player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
		-- Hide minimap
		player:hud_set_flags({minimap = false})
		minetest.chat_send_player(name, S("Your nametag is now hidden."))
	end,

	leave_area = function(player)
		local name = player:get_player_name()
		hideandseek.players[name].zone=false
		-- save data
		save_data()
		-- Show nametag
		player:set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})
		-- Allow minimap
		player:hud_set_flags({minimap = true})
		minetest.chat_send_player(name, S("Your nametag is now visible."))
	end,
}

load_data()

minetest.register_on_shutdown(function()
	save_data()
end)

minetest.register_on_joinplayer(function(player)
	hideandseek.createPlayerTable(player)
end)

minetest.register_on_leaveplayer(function(player)
	hideandseek.userdata[player:get_player_name()]=nil
end)

local time = 0
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time >= checkinterval then
		time = 0
		for _, plr in pairs(hideandseek.userdata) do
			hideandseek.calculate_current_area(plr)
		end
	end
end)
