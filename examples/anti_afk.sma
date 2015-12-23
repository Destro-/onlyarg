#include <amxmodx>
#include <cstrike>
#include <engine>

#define OA_UTIL_INC
#define OA_ADM_INC
#include <onlyarg.inc>

#define PLUGIN	"OA: Anti AFK"
#define VERSION	"1.1"
#define AUTHOR	"Destro"
/**********************************************/

#define AFK_CHECK_FREQ		4.0
#define GROUP_IMMUNITY		ACCESS_GROUP_SUPERVISOR

new const MSG_ALERT[]		= "Muevete o seras kickeado en %d segundos"
new const MSG_ALERT_COLOR[]	= "!g[Only-Arg] !tMuevete o seras kickeado en !y%d !tsegundos"
new const MSG_KICK[]		= "!g[Only-Arg] !y%s !tfue kickeado por estar AFK por mas de !y%d !tsegundos"
new const KICK_RAZON[]		= "Kickeado por estar AFK"

new pcvar_time, pcvar_bomb, g_afk_time, g_afk_bomb
new g_maxplayers

new g_is_connected[33]

public plugin_init()
{
	oa_register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	pcvar_time = register_cvar("afk_time", "70")
	pcvar_bomb = register_cvar("afk_bombtime", "20")

	g_maxplayers = get_maxplayers()
	
	set_task(AFK_CHECK_FREQ, "check_afk", .flags="b")
	set_task(1.0, "event_round_start")
}

public event_round_start()
{
	g_afk_time = get_pcvar_num(pcvar_time)
	g_afk_bomb = get_pcvar_num(pcvar_bomb)

	new Float:gametime = get_gametime()
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id]) continue
		
		cs_set_user_lastactivity(id, gametime)
	}
}

public client_disconnect(id)
{
	g_is_connected[id] = false
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id))
		return

	g_is_connected[id] = true
	cs_set_user_lastactivity(id, get_gametime())
}

public check_afk()
{
	static id, Float:gametime, lastactivity
	
	gametime = get_gametime()
	
	for(id=1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id] || !is_user_alive(id))
			continue
		
		lastactivity = floatround(gametime - cs_get_user_lastactivity(id))
		
		if(g_afk_bomb && user_has_weapon(id, CSW_C4))
		{
			if(lastactivity >= g_afk_bomb)
				transfer_bomb(id, gametime)
		}
			
		if(oa_has_access(id, ACCESS_ANY_ADM, GROUP_IMMUNITY))
			continue
			
		if(lastactivity < (g_afk_time - 15))
			continue
			
		if(lastactivity >= g_afk_time)
		{
			kick_user(id)
			continue
		}
		client_print(id, print_center, MSG_ALERT, g_afk_time-lastactivity)
		client_print(id, print_console, MSG_ALERT, g_afk_time-lastactivity)
		oa_chat_color(id, _, MSG_ALERT_COLOR, g_afk_time - lastactivity)
	}
}

public transfer_bomb(id, Float:gametime)
{
	new players[32], num
	get_players(players, num, "ae", "TERRORIST")

	if(num < 2) return

	new origin[3], origin_target[3], target, distance, min_distance = 999999
	get_user_origin(id, origin)
	
	for(new p = 0; p < num; p++)
	{
		if((gametime-cs_get_user_lastactivity(players[p])) > 10) continue
		
		get_user_origin(players[p], origin_target)
		distance = get_distance(origin, origin_target)
		if(distance < min_distance) {
			min_distance = distance
			target = players[p]
		}
	}

	if(!target) return
	
	engclient_cmd(id, "drop", "weapon_c4")
	new c4 = find_ent_by_class(-1, "weapon_c4")

	if(!is_valid_ent(c4)) return
	
	new backpack = entity_get_edict(c4, EV_ENT_owner)
	if(backpack <=  g_maxplayers) return
	
	entity_set_int(backpack, EV_INT_flags, entity_get_int(backpack, EV_INT_flags) | FL_ONGROUND)
	fake_touch(backpack, target)

	new name[32]
	get_user_name(target, name, 31)
	
	set_hudmessage(255, 0, 0, -1.0, 0.8, 0, 6.0, 5.0)
	for(new p = 0; p < num; p++)
	{
		if(players[p] == target) continue
		
		show_hudmessage(players[p], "ANTI AFK BOMB: C4 transferida a %s", name)
	}

	show_hudmessage(target, "ANTI AFK BOMB: Tu tienes la C4")
}

kick_user(id)
{
	server_cmd("kick #%d ^"%s^"", get_user_userid(id), KICK_RAZON)

	new name[32]
	get_user_name(id, name, 31)
	oa_chat_color(0, _, MSG_KICK, name, g_afk_time)
}
