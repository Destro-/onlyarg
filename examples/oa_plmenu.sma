#include <amxmodx>

#define OA_UTIL_INC
#define OA_SXEI_INC
#define OA_OLD_MENU_INC
#define OA_ADM_INC
#define OA_ACC_INC
#include <onlyarg>

#define PLUGIN	"OA: Adm PlayersMenu"
#define VERSION	"1.12"
#define AUTHOR	"Destro"
/**********************************************/

enum {
	MENU_KICK=0,
	MENU_SLAY,
	MENU_SLAP,
	MENU_TEAM,
	MAX_MENU
}
new const menu_name[MAX_MENU][] = { "Kick", "Slay", "Slap", "Team" }
new const menu_option[MAX_MENU] = { false, false, true, true }
new admin_item[MAX_MENU]

new const slap_damage[7] = { 0, 1, 5, 10, 20, 40, 80 }
new const team_prefix[4][] = { "UNS", "TT", "CT", "SPECT" }


new g_current_menu[33], g_menu_extradata[33][10]

new g_name[33][32], g_hid[33][10]

public plugin_init()
{
	oa_register_plugin(PLUGIN, VERSION, AUTHOR)

	oa_register_cmd("amx_kickmenu", "cmd_kickmenu", ACCESS_KICK, _, "- Menu de Kick")
	oa_register_cmd("amx_slaymenu", "cmd_slaymenu", ACCESS_SLAY, _, "- Menu de Slay")
	oa_register_cmd("amx_slapmenu", "cmd_slapmenu", ACCESS_SLAP, _, "- Menu de Slap")
	oa_register_cmd("amx_teammenu", "cmd_teammenu", ACCESS_TEAM, _, "- Menu de transferencia de equipo")
	
	admin_item[MENU_KICK] = oa_admin_add_item("Expulsar", ACCESS_KICK)
	admin_item[MENU_SLAY] = oa_admin_add_item("Matar", ACCESS_SLAY)
	admin_item[MENU_SLAP] = oa_admin_add_item("Abofetear", ACCESS_SLAP)
	admin_item[MENU_TEAM] = oa_admin_add_item("Cambiar team", ACCESS_TEAM)

	oldmenu_register()
}

public fw_oa_acc_changename(id, const name[])
{
	copy(g_name[id], 31, name)
}

public client_connect(id)
{
	get_user_hid(id, g_hid[id], 9)
}

/*** ADMIN ITEM **********************************************************************************/
public fw_oa_admin_itemselect(id, itemid)
{
	if(itemid == admin_item[MENU_KICK])
		display_menu(id, MENU_KICK)
	else if(itemid == admin_item[MENU_SLAY])
		display_menu(id, MENU_SLAY)
	else if(itemid == admin_item[MENU_SLAP])
		display_menu(id, MENU_SLAP)
	else if(itemid == admin_item[MENU_TEAM])
		display_menu(id, MENU_TEAM)
}

/*** MENU CMD  ***********************************************************************************/
public cmd_kickmenu(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED

	display_menu(id, MENU_KICK)
	return PLUGIN_HANDLED
}

public cmd_slaymenu(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED

	display_menu(id, MENU_SLAY)
	return PLUGIN_HANDLED
}

public cmd_slapmenu(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED

	display_menu(id, MENU_SLAP)
	return PLUGIN_HANDLED
}

public cmd_teammenu(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED

	display_menu(id, MENU_TEAM)
	return PLUGIN_HANDLED
}

action_player(id, target, menu, option)
{
	switch(menu)
	{
		case MENU_KICK:
		{
			server_cmd("kick #%d", get_user_userid(target))
			
			oa_show_activity(id, _, _, "!g%s !yexpulsado", g_name[target])
			log_admin_to(id, target, "Kick Menu")
		}
		case MENU_SLAY:
		{
			if(!is_user_alive(target)) return 1
				
			user_kill(target)
				
			oa_show_activity(id, _, _, "!g%s !yasesinado", g_name[target])
			log_admin_to(id, target, "Slay Menu")
		}
		case MENU_SLAP:
		{
			if(!is_user_alive(target)) return 1
			
			user_slap(target, slap_damage[option])
			
			oa_show_activity(id, _, _, "!g%s !yha sido bofeteado con %d de daño", g_name[target], slap_damage[option])
			log_admin_to(id, target, "Slap Menu", "- Damage: %d", slap_damage[option])
		}
		case MENU_TEAM:
		{
			new oldteam = oa_get_user_team(target)
			if(oldteam == option+1 || !oldteam)
				return 1
				
			oa_eng_change_team(target, option+1)
			
			if(oldteam != oa_get_user_team(target))
			{
				oa_show_activity(id, _, _, "!g%s !yha sido transferido al equipo !g%s", g_name[target], team_prefix[option+1])
				log_admin_to(id, target, "change team", "- team: %s", team_prefix[option+1])
			}

		}
	}
	return 1
}

collect_player(id, player, menu, option, itemname[], maxlen)
{
	static comp
	comp = oa_admin_compare(id, player)
	
	switch(menu)
	{
		case MENU_KICK:
		{
			if(comp == id || player == id)
			{
				copy(itemname, maxlen, g_name[player])
				return 1
			}
			
			formatex(itemname, maxlen, "%s\r*", g_name[player])
		}
		case MENU_SLAY, MENU_SLAP:
		{
			if(comp != id && id != player)
				formatex(itemname, maxlen, "%s\r*", g_name[player])
			else if(!is_user_alive(player))
				formatex(itemname, maxlen, "%s", g_name[player])
			else {
				new iteam = oa_get_user_team(player)
				formatex(itemname, maxlen, "%s \y%s", g_name[player], team_prefix[iteam])
				return 1
			}
		}
		case MENU_TEAM:
		{
			new iteam = oa_get_user_team(player)
			
			if(comp == player)
				formatex(itemname, maxlen, "%s\r* \y%s", g_name[player], team_prefix[iteam])
			else if(iteam-1 == option || !iteam)
				formatex(itemname, maxlen, "%s \y%s", g_name[player], team_prefix[iteam])
			else {
				formatex(itemname, maxlen, "%s \y%s", g_name[player], team_prefix[iteam])
				return 1
			}
		}
	}
	return 0
}

collect_option(menu, &option, name[], len)
{
	switch(menu)
	{
		case MENU_SLAP:
		{

			option = (option%sizeof(slap_damage))
			formatex(name, len, "Daño: \r%d", slap_damage[option])
			
		}
		case MENU_TEAM:
		{
			option = option%3
			formatex(name, len, "Pasar a: \y%s", team_prefix[option+1])
		}
	}
}

/*** MENU **************************************************************************************/
display_menu(id, menu)
{
	g_current_menu[id] = menu
	g_menu_extradata[id][7] = 0
	show_menu_players(id)
}

show_menu_players(id, page=1)
{
	static maxpages, start, end, players[32], count, name[48], option[20]
	get_players(players, count)
	oldmenu_calculate_pages(maxpages, start, end, page, count, menu_option[g_current_menu[id]]?6:7)
	
	oldmenu_create("menu_players", "\r%s Menu: %d/%d",
	menu_name[g_current_menu[id]], page, maxpages)
	
	if(menu_option[g_current_menu[id]])
		collect_option(g_current_menu[id], g_menu_extradata[id][7], option, 19)
		
	count = 0
	for(new pl = start; pl < end; pl++)
	{
		count++
		g_menu_extradata[id][count] = get_user_userid(players[pl])
		if(collect_player(id, players[pl], g_current_menu[id], g_menu_extradata[id][7], name, 47))
			oldmenu_additem(count, players[pl], "\r%d. \w%s", count, name)
		else oldmenu_additem(-1, 0, "\d%d. %s", count, name)
	}
	
	if(menu_option[g_current_menu[id]])
	{
		for(;count < 6; count++)
			oldmenu_additem(-1, 0, "")
		
		oldmenu_additem(7, 0, "\r7. \w%s", option)
	}
		
	oldmenu_pagination(page, maxpages, !menu_option[g_current_menu[id]])
	oldmenu_display(id, page)
}

public menu_players(id, itemnum, value, page)
{
	if(!itemnum) return
	
	if(menu_option[g_current_menu[id]] && itemnum == 7)
	{
		g_menu_extradata[id][7]++
		show_menu_players(id, page)
		return
	}
	if(itemnum > 7)
	{
		show_menu_players(id, page+value)
		return
	}
    
	if(!is_user_connected(value) || get_user_userid(value) != g_menu_extradata[id][itemnum])
	{
		oa_chat_color(id, _, "!g-%s Menu: !yJugador invalido", menu_name[g_current_menu[id]])
		show_menu_players(id, page)
		return
	}
	
	if(action_player(id, value, g_current_menu[id], g_menu_extradata[id][7]))
		show_menu_players(id, page)
}
