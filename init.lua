local players_textlist = {}
local privs_textlist = {}
local selected_player = {}
local selected_priv = {}

local function getfs(name)
	if not name then return end
	local players = core.get_connected_players()
	local plist = {}
	for _,player in ipairs(players) do
		local pname = player and player:get_player_name()
		if pname and pname ~= "" then
			table.insert(plist, pname)
		end
	end
	table.sort(plist)
	players_textlist[name] = plist

	local target_privs = plist[selected_player[name]] and core.get_player_privs(plist[selected_player[name]])
	local privlist = {}
	if target_privs then
		for priv,_ in pairs(target_privs) do
			if priv and priv ~= "" then
				table.insert(privlist, priv)
			end
		end
		table.sort(privlist)
		privs_textlist[name] = privlist
	end

	local privs = core.get_player_privs(name)
	local fs = "textlist[0.2,0.2;5,9.5;uinv_plist_plist;"..table.concat(plist,",").."]" ..
		"label[5.3,1.5;Privs:]" ..
		"textlist[5.2,1.7;3,5;uinv_plist_privs;"..table.concat(privlist,",").."]"
	if privs["teleport"] or core.get_modpath("tpr") then
		fs = fs .. "button[5.2,0.2;2,1;uinv_plist_tpto;TP to player]" ..
		"button[7.2,0.2;2,1;uinv_plist_tphere;TP to here]"
	end
	if privs["privs"] then
		fs = fs .. "button[5.2,8.7;2,1;uinv_plist_revoke;Revoke]"
	end
	if privs["kick"] then
		fs = fs .. "field[8.4,1.7;3,1;uinv_plist_reason;Reason;]" ..
			"field_close_on_enter[uinv_plist_reason;false]" ..
			"button[8.4,2.8;1.5,1;uinv_plist_kick;Kick]"
		end
	if privs["ban"] then
		fs = fs .. "button[9.9,2.8;1.5,1;uinv_plist_ban;Ban]"
	end
	return fs
end

unified_inventory.register_page("uinv_plist", {
	get_formspec = function(player)
	local name = player:get_player_name()
	if not name then return end
		return {
			formspec = getfs(name),
				draw_inventory = false,
				draw_item_list = false,
				formspec_prepend = false,
			}
end})

unified_inventory.register_button("uinv_plist", {
	type = "image",
	image = "uinv_plist.png",
	tooltip = "PlayerList",
	hide_lite = false
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then return end
	local name = player:get_player_name()
	if not name then return end
	local plist = players_textlist[name]
	local privlist = privs_textlist[name]
	local privs = core.get_player_privs(name)
	local target = plist and plist[selected_player[name]]
	if fields.uinv_plist_plist then
		local evnt = core.explode_textlist_event(fields.uinv_plist_plist)
		selected_player[name] = evnt.index
		unified_inventory.set_inventory_formspec(player, "uinv_plist")
	end
	if fields.uinv_plist_privs then
		local evnt = core.explode_textlist_event(fields.uinv_plist_privs)
		selected_priv[name] = evnt.index
	end
	if fields.uinv_plist_tpto then
		if not target then
			core.chat_send_player(name, "Please choose player")
			return
		end
		if privs["teleport"] then
			core.chatcommands["teleport"].func(name,target)
		elseif core.chatcommands["tpr"] then
				local cmdprivs = core.chatcommands["tpr"].privs
				if cmdprivs and core.check_player_privs(name, cmdprivs) then
					core.chatcommands["tpr"].func(name, target)
				end
		end
	end
	if fields.uinv_plist_tphere then
		if not target then
			core.chat_send_player(name, "Please choose player")
			return
		end
		if privs["bring"] then
			core.chatcommands["teleport"].func(name,target.." "..name)
		elseif core.chatcommands["tphr"] then
				local cmdprivs = core.chatcommands["tphr"].privs
				if cmdprivs and core.check_player_privs(name, cmdprivs) then
					core.chatcommands["tphr"].func(name, target)
				end
		end
	end
	if fields.uinv_plist_kick then
		if not target then
			core.chat_send_player(name, "Please choose player")
			return
		end
		if not privs["kick"] then return end
		local reason = fields.uinv_plist_reason or ""
			core.kick_player(target,reason)
	end
	if fields.uinv_plist_ban then
		if not target then
			core.chat_send_player(name, "Please choose player")
			return
		end
		if not privs["ban"] then return end
		core.ban_player(target)
	end
	if fields.uinv_plist_revoke then
		local priv = privlist[selected_priv[name]]
		if not (target and priv) then
			core.chat_send_player(name, "Please choose player and privilege")
			return
		end
		if not privs["privs"] then return end
		core.chatcommands["revoke"].func(name,target.." "..priv)
		unified_inventory.set_inventory_formspec(player, "uinv_plist")
	end
end)
