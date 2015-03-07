#include <amxmodx>

#define OA_UTIL_INC
#define OA_OLD_MENU_INC
#define OA_ADM_INC
#define OA_ACC_INC
#include <onlyarg>

#define PLUGIN	"OA: Adm Vote"
#define VERSION	"1.0.1"
#define AUTHOR	"Destro"
/**********************************************/

enum {
	VOTE_VOTE=0,
	VOTE_KICK,
	VOTE_MAP,
	VOTE_MAP_MULTI,
	MAX_VOTE
}

enum _:_VOTE_STRUCT
{
	NAME[16],
	Float:RATIO,
	CONFIRM
}

new const g_vote[MAX_VOTE][_VOTE_STRUCT] = {
	{ "Vote", 		0.1, 	0 },
	{ "Vote Kick",		0.60, 	1 },
	{ "Cambiar map",	0.60, 	1 },
	{ "Vote Map",		0.35, 	1 }
}

#define TASK_VOTE	111
#define MAX_OPTIONS	4
#define VOTE_TIME	10
#define VOTE_DELAY	3

new const func_menu_vote[] = "menu_vote"

new g_vote_option[MAX_OPTIONS][32], g_vote_vote[MAX_OPTIONS+1]
new g_in_voting, g_vote_last, g_vote_admin, g_vote_group, g_vote_num, g_vote_type, g_vote_win
new g_votekick_target[2]

public g_vote_extern = 0

new g_name[33][32], g_hid[33][10]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	oa_register_cmd("amx_votemap", "cmd_votemap", ACCESS_VOTE|ACCESS_MAP, _, "<map> [map] [map] [map]", true)
	oa_register_cmd("amx_votekick", "cmd_votekick", ACCESS_VOTE|ACCESS_KICK, _, "<nombre o #userid>", true)
	oa_register_cmd("amx_vote", "cmd_vote", ACCESS_VOTE, _, "<pregunta> <opcion #1> <opcion #2> [opcion #3] [opcion #4]", true)
	oa_register_cmd("amx_cancelvote", "cmd_cancelvote", ACCESS_VOTE, _, "- Cancela la ultima votacion", true)
	
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
	
public client_disconnect(id)
{
	if(g_vote_admin == id)
	{
		oa_show_activity(id, _, _, "el admin se ha desconectado, votacion actual cancelada")
		remove_task(TASK_VOTE)
		
		g_vote_last = get_systime()
		g_in_voting = false
		g_vote_admin = 0
	}
}

/*** ACTIONS ************************************************************************************/
action_vote_end(id, type, key)
{
	switch(type)
	{
		case VOTE_KICK:
		{
			if(key) return
			
			if(!is_user_connected(g_votekick_target[0]) || get_user_userid(g_votekick_target[0]) != g_votekick_target[1])
			{
				if(id) oa_chat_color(id, _, "!g-AdminVote: !yJugador invalido")
				return
			}
			
			console_cmd(id, "amx_kick #%d VoteKick", g_votekick_target[1])
		}
		case VOTE_MAP:
		{
			if(key) return
			
			console_cmd(id, "amx_map %s", g_vote_option[2])
		}
		case VOTE_MAP_MULTI:
		{
			console_cmd(id, "amx_map %s", g_vote_option[key])
		}
	}
	
}

confirm_vote_end(type, key)
{
	if(type == VOTE_KICK || type == VOTE_MAP)
		return !key
	else if(type == VOTE_MAP_MULTI)
		return 1
		
	return 0
}

/*** CMD ****************************************************************************************/
public cmd_cancelvote(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED

	if(g_in_voting)
	{
		if(!oa_has_access(id, 0, g_vote_group))
		{
			console_print(id, "[OA]- No tienes acceso para cancelar la votacion actual")
			return PLUGIN_HANDLED
		}
		
		if(g_vote_admin)
			oa_show_activity(id, _, _, "cancelo la votacion de !g%s", g_name[g_vote_admin])
		else 	oa_show_activity(id, _, _, "cancelo la votacion actual")
		
		log_admin(id, "cancel vote")
		
		remove_task(TASK_VOTE)
		
		g_vote_last = get_systime()
		g_in_voting = false
	}
	else if(g_vote_extern > get_systime())
		console_print(id, "[OA]- Las votaciones externas no se pueden cancelar")
	else console_print(id, "[OA]- No hay ninguna votacion en curso")

	return PLUGIN_HANDLED
}

public cmd_vote(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 3))
		return PLUGIN_HANDLED
	
	if(!can_vote(id))
		return PLUGIN_HANDLED

	new quest[48]
	read_argv(1, quest, charsmax(quest))
	filter_string(id, quest, charsmax(quest))
	
	oldmenu_create(func_menu_vote, "\y%s\d:", quest)
	
	new argc = read_argc()-2
	if(argc > MAX_OPTIONS) argc = MAX_OPTIONS
	
	for(new i=0; i < argc; i++)
	{
		read_argv(i+2, g_vote_option[i], charsmax(g_vote_option[]))
		filter_string(id, g_vote_option[i], charsmax(g_vote_option[]))
		
		oldmenu_additem(i+1, 0, "\r%d. \w%s", i+1, g_vote_option[i])
	}
	
	oldmenu_vote_display(id, argc, VOTE_VOTE)
	
	oa_show_activity(id, _, _, "inicio una votacion personalizada")
	log_admin(id, "votacion personalizada")
	
	return PLUGIN_HANDLED
}

public cmd_votemap(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED
	
	if(!can_vote(id))
		return PLUGIN_HANDLED
	
	new argc = read_argc()-1
	if(argc > MAX_OPTIONS) argc = MAX_OPTIONS
	
	new valid_maps
	
	for(new i=0; i < argc; i++)
	{
		read_argv(i+1, g_vote_option[valid_maps], charsmax(g_vote_option[]))
		
		if(is_map_valid(g_vote_option[valid_maps])) valid_maps++
	}
	
	if(!valid_maps)
	{
		if(argc == 1) console_print(id, "[OA]- El mapa ingresado no es valido")
		else console_print(id, "[OA]- Los mapas ingresados no son validos")
		return PLUGIN_HANDLED
	}
	
	if(valid_maps == 1)
	{
		copy(g_vote_option[2], charsmax(g_vote_option[]), g_vote_option[0])
		oldmenu_create(func_menu_vote, "\yCambiar el mapa a \r%s\d:", g_vote_option[2])
		
		g_vote_option[0] = "SI"
		g_vote_option[1] = "NO"
		oldmenu_additem(1, 0, "\r1. \wSI")
		oldmenu_additem(2, 0, "\r2. \wNO")
		
		oldmenu_vote_display(id, 2, VOTE_MAP)
	}
	else {
		oldmenu_create(func_menu_vote, "\yVotar mapa\d:")
		
		for(new i=0; i < valid_maps; i++)
		{

			oldmenu_additem(i+1, 0, "\r%d. \w%s", i+1, g_vote_option[i])
		}
		
		oldmenu_vote_display(id, valid_maps, VOTE_MAP_MULTI)
	}
	
	oa_show_activity(id, _, _, "inicio una votacion para cambiar el mapa")
	log_admin(id, "votemap")
	
	return PLUGIN_HANDLED
}

public cmd_votekick(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED
	
	if(!can_vote(id))
		return PLUGIN_HANDLED
	
	new arg[32], player
	read_argv(1, arg, 31)
	
	player = oa_cmd_target(id, arg, CMDTARGET_CHECKLEVEL | CMDTARGET_SELF | CMDTARGET_SAMELEVEL)
	if(!player) return PLUGIN_HANDLED

	g_votekick_target[0] = player
	g_votekick_target[1] = get_user_userid(player)
	
	oldmenu_create(func_menu_vote, "\yKickear a \r%s \y?\d:", g_name[player])
	
	g_vote_option[0] = "SI"
	g_vote_option[1] = "NO"
	oldmenu_additem(1, 0, "\r1. \wSI")
	oldmenu_additem(2, 0, "\r2. \wNO")

	oldmenu_vote_display(id, 2, VOTE_KICK)
	
	oa_show_activity(id, _, _, "inicio una votacion para expulsar a !g%s", g_name[player])
	log_admin_to(id, player, "votekick")
	
	return PLUGIN_HANDLED
}

/*** VOTE Count/End *****************************************************************************/
public menu_vote(id, itemnum, value, page)
{
	if(!itemnum || itemnum > MAX_OPTIONS || !g_in_voting)
		return
		
	g_vote_vote[itemnum-1]++
	g_vote_vote[MAX_OPTIONS]++
	
	oa_chat_color(0, _, "!g-AdminVote: !t%s !yvoto por: !g%s", g_name[id], g_vote_option[itemnum-1])
}

public end_vote()
{
	g_vote_win = 0
	for(new vote; vote < g_vote_num; vote++)
		if(g_vote_vote[g_vote_win] < g_vote_vote[vote])
			g_vote_win = vote
	
	new ratio = g_vote_vote[MAX_OPTIONS]?floatround(g_vote[g_vote_type][RATIO] * g_vote_vote[MAX_OPTIONS], floatround_ceil):1
	
	if(g_vote_vote[MAX_OPTIONS] < ratio)
	{
		oa_chat_color(0, color_blue, "!g[Only-Arg] !tVotacion fallida")
		g_in_voting = false
		g_vote_last = get_systime()
		g_vote_admin = 0
		return
	}
	
	oa_chat_color(0, color_blue, "!g[Only-Arg] !tVotacion finalizada, resultado %s: !y%s", g_vote[g_vote_type][NAME], g_vote_option[g_vote_win])
	
	if(g_vote[g_vote_type][CONFIRM] && g_vote_admin && confirm_vote_end(g_vote_type, g_vote_win))
	{
		oldmenu_create("menu_confirm", "\r%s \d- \yResultado: \r%s\d:", g_vote[g_vote_type][NAME], g_vote_option[g_vote_win])
		
		oldmenu_additem(1, 0, "\r1. \wAceptar")
		oldmenu_additem(2, 0, "\r2. \wRechazar")
		
		oldmenu_display(g_vote_admin, _, 6)
		set_task(6.0, "task_confirm", TASK_VOTE)
	}
	else _end_vote(true)
}

public menu_confirm(id, itemnum, value, page)
{
	if(!g_in_voting) return
	
	remove_task(TASK_VOTE)
	
	if(itemnum == 1)
	{
		oa_chat_color(id, _, "!g-AdminVote: !yresultado aceptado")
		_end_vote(true)
	}
	else {
		oa_chat_color(g_vote_admin, _, "!g-AdminVote: !yresultado rechazado")
		_end_vote(false)
	}
}

public task_confirm()
{
	if(g_in_voting)
	{
		if(g_vote_admin)
			oa_chat_color(g_vote_admin, _, "!g-AdminVote: !yresultado rechazado")
		
		_end_vote(false)
	}
}

/*** STOCKS *************************************************************************************/
stock can_vote(id)
{
	if(g_in_voting)
	{
		console_print(id, "[OA]- Hay una votacion en curso")
		return 0
	}
	
	if(g_vote_extern > get_systime())
	{
		console_print(id, "[OA]- Hay una votacion externa en curso")
		return 0
	}
	
	new delay = (g_vote_last + VOTE_DELAY) - get_systime()
	if(delay > 0)
	{
		console_print(id, "[OA]- Podras realizar una votacion en %d segundo(s)", delay)
		return 0
	}
	
	return 1
}

stock oldmenu_vote_display(admin, num, type)
{
	oldmenu_display(0, _, VOTE_TIME)
	set_task(VOTE_TIME*1.0, "end_vote", TASK_VOTE)
	
	g_in_voting = true
	g_vote_vote = { 0, 0, 0, 0, 0}
	g_vote_num = num
	g_vote_type = type
	
	g_vote_admin = admin
	oa_get_access(admin, g_vote_group)
}

stock _end_vote(call_action)
{
	if(call_action) action_vote_end(g_vote_admin, g_vote_type, g_vote_win)
		
	g_in_voting = false
	g_vote_last = get_systime()
	g_vote_admin = 0
}

stock filter_string(id, string[], len)
{
	oa_filter_print(string, len)
	
	if(!oa_has_access(id, ACCESS_ANY_ADM, ACCESS_GROUP_SUPERVISOR))
	{
		oa_filter_badwords(string, 100, false)
		oa_filter_spam(string, 100)
	}
}
