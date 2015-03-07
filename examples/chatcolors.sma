/* LuKks estuvo aqui. */

#include <amxmodx>

#define OA_UTIL_INC
#define OA_ADM_INC
#define OA_ACC_INC
#include <onlyarg.inc>

#define PLUGIN	"OA: ChatColor"
#define VERSION	"1.2"
#define AUTHOR	"Destro"
/**********************************************/

new const group_name[][] = { "Owner", "Super Mod", "Supervisor", "Admin", "Vip" }

new msg[192], send_buff[2][96], alive, listen, rtn
new cvar_listen, g_maxplayers

new g_name[33][32], g_group[33], g_access[33], g_warning[33], g_lastwarning[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_message(get_user_msgid ("SayText"), "message_saytext")
	
	/*
	- 0 desactivado (solo se comprueban insultos)
	- 1 los admins leen los mensajes de todos
	- 2 +los jugadores se leen entre vivos&muertos */
	cvar_listen = register_cvar("amx_chatlisten", "1")
	
	g_maxplayers = get_maxplayers()
}

public plugin_cfg()
{
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_sayteam")
}

public fw_oa_acc_changename(id, const name[])
{
	copy(g_name[id], 31, name)
}

public fw_oa_admin_update(id, access, group)
{
	g_access[id] = access
	g_group[id] = group
}

public client_putinserver(id)
{
	g_warning[id] = 0
	g_lastwarning[id] = 0
}

public message_saytext(msgid, msgdest, id)
{
	return PLUGIN_HANDLED
}

public hook_say(id)
{
	rtn = read_say(id)
	if(rtn) return rtn-1
	
	if(g_group[id] && g_access[id] & ACCESS_CHAT && ~g_access[id] & ACCESS_HIDDEN)
	{
		if(alive) format(msg, charsmax(msg), "^4(%s) ^3%s : ^1%s", group_name[g_group[id]-1], g_name[id], msg)
		else format(msg, charsmax(msg), "^1*MUERTO* ^4(%s) ^3%s : ^1%s", group_name[g_group[id]-1], g_name[id], msg)
	}
	else {
		if(alive) format(msg, charsmax(msg), "^3%s : ^1%s", g_name[id], msg)
		else format(msg, charsmax(msg), "^1*MUERTO* ^3%s : ^1%s", g_name[id], msg)
	}
	wrap_msg()
	
	if(listen == 1)
	{
		for(new pl=1; pl <= g_maxplayers; pl++ )
		{
			if(!is_user_connected(pl))
				continue
				
			if(g_access[pl] & ACCESS_CHAT || is_user_alive(pl) == alive)
				send_msg(pl, id)
		}
	}
	else send_msg(0, id)

	log_chat("say", msg)
	return PLUGIN_HANDLED_MAIN
}

public hook_sayteam(id)
{
	rtn = read_say(id)
	if(rtn) return rtn-1
	
	static const team_name[][] = { "Uniendose", "Terrorista", "Anti-Terrorista", "Espectador" }
	new team = oa_get_user_team(id)
	
	if(g_group[id] && g_access[id] & ACCESS_CHAT && ~g_access[id] & ACCESS_HIDDEN)
	{
		if(alive) format(msg, charsmax(msg), "^1(%s) ^4(%s) ^3%s : ^1%s", team_name[team], group_name[g_group[id]-1], g_name[id], msg)
		else format(msg, charsmax(msg), "^1*MUERTO* ^1(%s) ^4(%s) ^3%s : ^1%s", team_name[team], group_name[g_group[id]-1], g_name[id], msg)
	}
	else {
		if(alive) format(msg, charsmax(msg), "^1(%s) ^3%s : ^1%s", team_name[team], g_name[id], msg)
		else format(msg, charsmax(msg), "^1*MUERTO* ^1(%s) ^3%s : ^1%s", team_name[team], g_name[id], msg)
	}
	wrap_msg()
	
	for(new pl=1; pl <= g_maxplayers; pl++ )
	{
		if(!is_user_connected(pl))
			continue
				
		if((listen && g_access[pl] & ACCESS_CHAT) || ((alive == 2 || is_user_alive(pl) == alive) && oa_get_user_team(pl) == team))
			send_msg(pl, id)
	}

	log_chat("say_team", msg)
	return PLUGIN_HANDLED_MAIN
}

stock read_say(id)
{
	read_args(msg, charsmax(msg))
	
	if(!msg[0]) return PLUGIN_HANDLED+1
	
	remove_quotes(msg)
	oa_filter_print(msg, charsmax(msg))
	trim(msg)

	if(!msg[0]) return PLUGIN_HANDLED+1

	if(!g_group[id] || g_group[id] > ACCESS_GROUP_SUPERVISOR)
	{
		static systime
		
		systime = get_systime()
		
		rtn = oa_filter_badwords(msg, (g_warning[id]>5)?0:2, (g_warning[id]>2)?2:g_warning[id]?1:0)
		if(rtn)
		{
			if(g_warning[id] < 10) g_warning[id]++
			g_lastwarning[id] = systime + 90
			
			if(rtn == 2)
			{
				oa_chat_color(id, _, "!g- !yEl mensaje fue bloqueado por considerarse un insulto")
				return PLUGIN_HANDLED+1
			}
			
			client_print(id, print_center, "Mensaje censurado por contener insulto(s)")
		}
		else if(g_warning[id] && g_lastwarning[id] < systime)
		{
			g_warning[id]--
		}
		
		rtn = oa_filter_spam(msg, -1)
		if(rtn)
		{
			if(rtn == 2)
			{
				oa_chat_color(id, _, "!g- !yEl mensaje fue bloqueado por considerarse spam")
				return PLUGIN_HANDLED+1
			}
			
			client_print(id, print_center, "Mensaje censurado por contener spam")
		}
	}
	
	listen = get_pcvar_num(cvar_listen)
	if(listen < 1) return PLUGIN_CONTINUE+1

	alive = is_user_alive(id)
	
	return 0
}

stock wrap_msg()
{
	if(strlen(msg) > 95)
	{
		formatex(send_buff[0], 95, "%s..", msg)
		formatex(send_buff[1], 95, "..%s", msg[95])
	}
	else {
		copy(send_buff[0], 95, msg)
		send_buff[1][0] = 0
	}
}

stock send_msg(player, color)
{
	oa_chat_color(player, color, send_buff[0])
	if(send_buff[1][0])
		oa_chat_color(player, color, send_buff[1])
}

stock log_chat(type[], msg[])
{
	static filename[32], oldday, newday
	
	date(_, _, newday)
	if(!filename[0] || newday != oldday)
	{
		oldday = newday
		format_time(filename, 31, "L%Y%m%d_chat.log")
	}
	
	log_to_file(filename, "(%s) %s", type, msg)
}
