#include <amxmodx>

#define OA_UTIL_INC
#define OA_ADM_INC
#define OA_ACC_INC
#include <onlyarg>

#define PLUGIN	"OA: Admin Chat"
#define VERSION	"1.0.1"
#define AUTHOR	"Destro"
/**********************************************/

#define MAX_COLORS 8
new const colors_key[MAX_COLORS] = { 'w', 'r', 'g', 'b', 'y', 'm', 'c', 'o' }
new const colors_value[MAX_COLORS][3] = { {255, 255, 255}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {227, 96, 8} }
new const Float:hud_position[4][2] = { {0.0, 0.0}, {0.05, 0.55}, {-1.0, 0.2}, {-1.0, 0.7} }

#define HUD_MAX 5
#define HUD_MAX_PER_ADMIN 3
#define HUD_DISPLAY_TIME 5.0

enum _:_HUD {
	Float:HUD_TIME,
	HUD_ADMIN
}
new g_hud[HUD_MAX][_HUD]

new g_buff[128]
new g_name[33][32]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say", "clcmd_sayall", ACCESS_CHAT, "@[@|@|@][w|r|g|b|y|m|c]<mensaje> - Muestra un hudmessage a todos", 0)
	register_clcmd("say_team", "clcmd_sayadmin", 0, "@<mensaje> - Envia un mensaje a todos los admins", 0)
	
	oa_register_cmd("amx_chat", "concmd_chat", ACCESS_CHAT, _, "<mensaje> - Envia un mensaje a todos los admins", true)
	oa_register_cmd("amx_say", "concmd_say", ACCESS_CHAT, _, "<mensaje> - Envia un mensaje a todos", true)
	oa_register_cmd("amx_psay", "concmd_psay", ACCESS_CHAT, _, "<nombre o #userid/> <mensaje> - Envia un mensaje privado a un jugador", true)
	oa_register_cmd("amx_tsay", "concmd_tsay", ACCESS_CHAT, _, "<color[w|r|g|b|y|m|c]> <mensaje> - Muestra un hudmessage a todos", true)
	oa_register_cmd("amx_csay", "concmd_tsay", ACCESS_CHAT, _, "<color[w|r|g|b|y|m|c]> <mensaje> - Muestra un hudmessage a todos (centrado)", true)
}

public fw_oa_acc_changename(id, const name[])
{
	copy(g_name[id], 31, name)
}

public clcmd_sayall(id)
{
	if(!oa_has_access(id, ACCESS_CHAT))
		return PLUGIN_CONTINUE
	
	static i, icolor, start, hud
	icolor = i = 0
	
	read_argv(1, g_buff, 5)
	
	while(g_buff[i] == '@') i++
	if(!i || i > 3) return PLUGIN_CONTINUE
	start = i

	hud = get_free_hud(id)
	if(hud == -1)
	{
		oa_chat_color(id, _, "!g-AdminChat: !yNo puedes tener mas de !g%d !yhudmessages al mismo tiempo", HUD_MAX_PER_ADMIN)
		return PLUGIN_HANDLED
	}
	if(hud == -2)
	{
		oa_chat_color(id, _, "!g-AdminChat: !yNo pueden haber mas de !g%d !yhudmessages al mismo tiempo", HUD_MAX)
		return PLUGIN_HANDLED
	}
	
	g_hud[hud][HUD_TIME] = _:(get_gametime() + HUD_DISPLAY_TIME)
	g_hud[hud][HUD_ADMIN] = id
	
	while(icolor < sizeof colors_key)
	{
		if(g_buff[i] == colors_key[icolor])
		{
			start++
			break
		}
		icolor++
	}
	if(icolor == sizeof colors_key)
		icolor = oa_acc_get_key(id, "admclr")

	while(g_buff[start] && isspace(g_buff[start])) start++
	
	read_args(g_buff, 127)
	filter_buff(id)
	
	log_chat(id, "tsayall", g_buff[start])
	log_message("^"%s^" amx_tsay (text ^"%s^")", g_name[id], g_buff[start])
	
	new Float:verpos = hud_position[i][1]+hud/32.0
	set_dhudmessage(colors_value[icolor][0], colors_value[icolor][1], colors_value[icolor][2], hud_position[i][0], verpos, 0, HUD_DISPLAY_TIME, HUD_DISPLAY_TIME, 0.5, 0.15)
	
	show_dhudmessage(0, "%s: %s", g_name[id], g_buff[start])
	client_print(0, print_notify, "%s: %s", g_name[id], g_buff[start])

	return PLUGIN_HANDLED
}


public clcmd_sayadmin(id)
{
	read_argv(1, g_buff, 1)
	if(g_buff[0] != '@')
		return PLUGIN_CONTINUE
	
	read_args(g_buff, 127)
	filter_buff(id)
	trim(g_buff[1])
	
	if(!g_buff[1]) return PLUGIN_HANDLED
	
	log_chat(id, "adminprivate", g_buff[1])
	log_message("^"%s^" amx_chat (text ^"%s^")", g_name[id], g_buff[1])
	
	if(oa_has_access(id, ACCESS_ANY_ADM))
		format(g_buff, 127, "!g-(adm chat)  !y(ADMIN) !t%s :  !y%s", g_name[id], g_buff[1])
	else {
		oa_filter_badwords(g_buff, 100, true)
		format(g_buff, 127, "!g-(adm chat)  !y(PLAYER) !t%s :  !y%s", g_name[id], g_buff[1])
	}

	new players[32], count
	get_players(players, count)
	
	for(new i = 0; i < count; i++)
	{
		if(players[i] != id && oa_has_access(players[i], ACCESS_ANY_ADM))
			oa_chat_color(players[i], id?id:33, "%s", g_buff)
	}
	oa_chat_color(id, _, "%s", g_buff)
	
	return PLUGIN_HANDLED
}


public concmd_chat(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED

	read_args(g_buff, 127)
	filter_buff(id)
	
	log_chat(id, "amx_chat", g_buff)
	log_message("^"%s^" amx_chat (text ^"%s^")", g_name[id], g_buff)
	
	console_print(id, "*(ADMIN) %s: %s", g_name[id], g_buff)
	format(g_buff, 127, "!g-(adm chat)  !y(ADMIN) !t%s :  !y%s", g_name[id], g_buff)
		
	new players[32], count
	get_players(players, count)
	for(new i = 0; i < count; i++)
	{
		if(players[i] != id && oa_has_access(players[i], ACCESS_ANY_ADM))
			oa_chat_color(players[i], id?id:33, g_buff)
	}
	
	return PLUGIN_HANDLED
}

public concmd_say(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED

	read_args(g_buff, 127)
	filter_buff(id)
	
	log_chat(id, "amx_say", g_buff)
	log_message("^"%s^" amx_say (text ^"%s^")", g_name[id], g_buff)
	
	console_print(id, "[OA]- Mensaje enviado a todos lo jugadores")
	
	oa_chat_color(0, id?id:33, "!g-(all) !t%s:  !y%s", g_name[id], g_buff)
	
	return PLUGIN_HANDLED
}

public concmd_psay(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED
	
	new arg[32], target
	read_argv(1, arg, 31)
	
	target = oa_cmd_target(id, arg, CMDTARGET_CHECKLEVEL)
	if(!target) return PLUGIN_HANDLED
	
	new length = strlen(arg)+1

	read_args(g_buff, 127)
	filter_buff(id)
	
	if(g_buff[0] == '"' && g_buff[length] == '"') // HLSW fix
	{
		g_buff[0] = ' '
		g_buff[length] = ' '
		length += 2
	}
	
	remove_quotes(g_buff[length])

	if(id) oa_chat_color(id, _, "!g-(Privado)  !ya  !t%s :  !y%s", g_name[target], g_buff[length])
	oa_chat_color(target, id?id:33, "!g-(Privado)  !yde  !t%s:  !y%s", g_name[id], g_buff[length])
	
	log_chat(id, g_name[target], g_buff[length])
	log_message("^"%s^" amx_psay to ^"%s^" (text ^"%s^")", g_name[id], g_name[target], g_buff[length])
	
	return PLUGIN_HANDLED
}

public concmd_tsay(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 2))
		return PLUGIN_HANDLED
	
	new hud = get_free_hud(id)
	if(hud == -1)
	{
		console_print(id, "[OA]- No puedes tener mas de %d hudmessages al mismo tiempo", HUD_MAX_PER_ADMIN)
		return PLUGIN_HANDLED
	}
	if(hud == -2)
	{
		console_print(id, "[OA]- No pueden haber mas de %d hudmessages al mismo tiempo", HUD_MAX)
		return PLUGIN_HANDLED
	}
	
	new cmd[6], icolor, tsay, start
	read_argv(0, cmd, 5)
	tsay = (cmd[4]=='t' || cmd[4]=='T')
	
	read_args(g_buff, 127)
	remove_quotes(g_buff)
	
	if(g_buff[1] == ' ')
	{
		while(icolor < sizeof colors_key)
		{
			if(g_buff[0] == colors_key[icolor])
			{
				start = 2
				break
			}
			icolor++
		}
	}
	else {
		icolor = sizeof colors_key
	}

	if(icolor == sizeof colors_key)
		icolor = oa_acc_get_key(id, "admclr")
	
	filter_buff(id)
	
	g_hud[hud][HUD_TIME] = _:(get_gametime() + HUD_DISPLAY_TIME)
	g_hud[hud][HUD_ADMIN] = id
	

	log_chat(id, "amx_tsay", g_buff[start])
	log_message("^"%s^" amx_tsay (text ^"%s^")", g_name[id], g_buff[start])
	
	new Float:verpos = (tsay ? 0.55 : 0.1)+hud/32.0
	set_dhudmessage(colors_value[icolor][0], colors_value[icolor][1], colors_value[icolor][2], tsay ? 0.05 : -1.0, verpos, 0, HUD_DISPLAY_TIME, HUD_DISPLAY_TIME, 0.5, 0.15)
	
	show_dhudmessage(0, "%s: %s", g_name[id], g_buff[start])
	client_print(0, print_notify, "%s: %s", g_name[id], g_buff[start])
	
	return PLUGIN_HANDLED
}

stock get_free_hud(id)
{
	new Float:currentime, i, count, free
	currentime = get_gametime()
	free = -2
	
	for(i = 0; i < HUD_MAX; i++)
	{
		if(g_hud[i][HUD_TIME] > currentime)
		{
			if(g_hud[i][HUD_ADMIN] == id && ++count == HUD_MAX_PER_ADMIN)
				return -1
		}
		else free = i
	}
	
	return free
}

stock filter_buff(id)
{
	remove_quotes(g_buff)
	oa_filter_print(g_buff, charsmax(g_buff))
	
	if(!oa_has_access(id, ACCESS_ANY_ADM, ACCESS_GROUP_SUPERVISOR))
	{
		oa_filter_badwords(g_buff, 100, 0)
		oa_filter_spam(g_buff, 100)
	}
}

stock log_chat(id, type[], msg[])
{
	static filename[32], oldday, newday
	
	date(_, _, newday)
	if(!filename[0] || newday != oldday)
	{
		oldday = newday
		format_time(filename, 31, "L%Y%m%d_chat.log")
	}
	
	log_to_file(filename, "(%s)  %s :  %s", type, g_name[id], msg)
}
