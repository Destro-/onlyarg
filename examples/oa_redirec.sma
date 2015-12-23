#include <amxmodx>

#define OA_MYSQL_INC
#define OA_SERVER_INC
#define OA_UTIL_INC
#define OA_OLD_MENU_INC
#define OA_ADM_INC
#include <onlyarg>

#define PLUGIN	"OA: Redirec"
#define VERSION	"1.12"
#define AUTHOR	"Destro"
/**********************************************/

new const sql_table_servers[] = "oa_servers"

#define TASK_MENU	111
#define UPDATE_TIME	10

enum _:ARRAYS
{
	Array:ARRAY_TITLE,
	Array:ARRAY_IP,
	Array:ARRAY_MAP,
	Array:ARRAY_PLAYERS,
	Array:ARRAY_MAXPLAYERS,
	Array:ARRAY_ONLINE
}

new Array:g_servers[ARRAYS]

new g_count
new g_global_players, g_global_maxplayers

new g_next_update, g_server_id, g_server_ip[25]
new cvar_redirec, g_maxplayers

new Handle:g_Connection, g_Query[180]

public plugin_init()
{
	oa_register_plugin(PLUGIN, VERSION, AUTHOR)
		
	register_clcmd("say /server", "show_menu_redirec")
	register_clcmd("say_team /server", "show_menu_redirec")
	
	cvar_redirec = register_cvar("amx_redirec", "0")

	g_servers[ARRAY_TITLE] = ArrayCreate(32, 1)
	g_servers[ARRAY_IP] = ArrayCreate(25, 1)
	g_servers[ARRAY_MAP] = ArrayCreate(32, 1)
	g_servers[ARRAY_PLAYERS] = ArrayCreate(1, 1)
	g_servers[ARRAY_MAXPLAYERS] = ArrayCreate(1, 1)
	g_servers[ARRAY_ONLINE] = ArrayCreate(1, 1)
	
	g_maxplayers = get_maxplayers()
	
	get_user_ip(0, g_server_ip, charsmax(g_server_ip), 0)

	set_task(160.0, "task_load_servers", _, _, _, "b")
	oldmenu_register()
}

public fw_oa_mysql_connect(Handle:cn, errnum)
{
	g_Connection = cn
}

public fw_oa_server_index(serverid)
{
	if(!serverid) set_fail_state("Error al obtener el server ID")
	
	g_server_id = serverid
}

public task_load_servers()
{
	load_servers()
	set_task(1.0, "show_notice")
}

public show_notice()
{
	oa_chat_color(0, _, "!g[Only-Arg] !tLa ip de este servidor es:!y %s", g_server_ip)
	oa_chat_color(0, _, "!g[Only-Arg] !tTotal de jugadores conectados:!y%d/!y%d !tSlots libres:!y%d", g_global_players, g_global_maxplayers, g_global_maxplayers-g_global_players)
}

public client_connect(id)
{
	if(!g_count)
		return
	
	static sv
	sv = get_pcvar_num(cvar_redirec)
	if(sv) redirec_player(id, (sv-1))

	if(oa_has_access(id, ACCESS_RESERVATION))
		return

	if(get_playersnum(1) < (g_maxplayers-2) || (random_num(0, 10) < 4))
		return
		
	sv = random_num(0, g_count-1)
	redirec_player(id, sv)
}

public show_menu_redirec(id, page)
{
	static _time
	if(id > 32) id -= TASK_MENU
	
	if(!g_Connection)
	{
		oa_chat_color(id, _, "!g[Only-Arg] !tUps.. ha ocurrido un error en la database :(")
		return
	}
	
	if(!page && g_next_update < (_time = time()))
	{
		g_next_update = _time+UPDATE_TIME

		load_servers()
		set_task(0.3, "show_menu_redirec", id+TASK_MENU)
		return
	}
	
	if(!g_count)
	{
		oa_chat_color(id, _, "!g[Only-Arg] !tNo hay servidores cargados")
		return
	}

	new maxpages, start, end, item
	oldmenu_calculate_pages(maxpages, start, end, page, g_count)
	
	oldmenu_create("menu_redirec",
	"\yServidores \dOnly-Arg: \r%d/%d^n\y- Players Online: \d%d/\d%d \y- Slots libres: \d%d^n",
	page, maxpages, g_global_players, g_global_maxplayers, g_global_maxplayers-g_global_players)
	
	for(new sv = start; sv < end; sv++)
	{
		item++

		if(ArrayGetCell(g_servers[ARRAY_ONLINE], sv))
		{
			oldmenu_additem(item, sv, "\r%d. \w%a^n\y    Map:\d %a\y, Players:\d %d/%d^n", item,
			ArrayGetStringHandle(g_servers[ARRAY_TITLE], sv),
			ArrayGetStringHandle(g_servers[ARRAY_MAP], sv),
			ArrayGetCell(g_servers[ARRAY_PLAYERS], sv),
			ArrayGetCell(g_servers[ARRAY_MAXPLAYERS], sv))
		}
		else {
			oldmenu_additem(item, sv, "\d%d. \d%a^n\r    Off-Line?^n", item, 
			ArrayGetStringHandle(g_servers[ARRAY_TITLE], sv))
		}
	}
	
	oldmenu_pagination(page, maxpages)
	oldmenu_display(id, page)
}

public menu_redirec(id, itemnum, value, page)
{
	if(!itemnum || value > g_count) return
	if(itemnum > 7)
	{
		show_menu_redirec(id, page+value)
		return
	}
	
	new name[32]
	get_user_name(id, name, 31)
	
	oa_chat_color(0, id, "!g[Only-Arg] !y%s !t se redirecciono al servidor !y%a!t.", name,
	ArrayGetStringHandle(g_servers[ARRAY_TITLE], value))
	
	redirec_player(id, value)
}

redirec_player(id, server)
{
	new ip[25]
	ArrayGetString(g_servers[ARRAY_IP], server, ip, 24)
	
	client_cmd(id, "echo ^"Haz sido redireccionado a la ip: %s^";^"CoNNect^" %s", ip, ip)
}

load_servers()
{
	ArrayClear(g_servers[ARRAY_TITLE])
	ArrayClear(g_servers[ARRAY_IP])
	ArrayClear(g_servers[ARRAY_MAP])
	ArrayClear(g_servers[ARRAY_PLAYERS])
	ArrayClear(g_servers[ARRAY_MAXPLAYERS])
	ArrayClear(g_servers[ARRAY_ONLINE])
	g_count = g_global_maxplayers = g_global_players = 0

	formatex(g_Query, charsmax(g_Query),
	"SELECT `ip`, `servertitle`, `map`, `players`, `maxplayers`, IF((UNIX_TIMESTAMP()-21)>`lastupdate`,0,1) as `online` FROM `%s` WHERE ( `id` != '%d' )",
	sql_table_servers, g_server_id)

	mysql_query(g_Connection, "query_handler", g_Query)
}


public query_handler(failstate, error[], errnum, data[], size, Float:queuetime)
{
	if(failstate != TQUERY_SUCCESS)
	{
		if(errnum > 2000) log_to_file("mysqlt.log", "[oa_redirec.amxx] query_handler: errnum[%d] - error:[%s]", errnum, error)
		else {
			mysql_get_query(g_Query, charsmax(g_Query))
			log_to_file("mysqlt.log", "[oa_redirec.amxx] query_handler: errnum[%d] - error:[%s] - query:[%s]", errnum, error, g_Query)
		}
		return
	}
	
	static util[32], players, maxplayers, online

	while(mysql_more_results())
	{
		players = mysql_read_result2("players")
		maxplayers = mysql_read_result2("maxplayers")
		online = mysql_read_result2("online")
		
		ArrayPushCell(g_servers[ARRAY_PLAYERS], players)
		ArrayPushCell(g_servers[ARRAY_MAXPLAYERS], maxplayers)
		ArrayPushCell(g_servers[ARRAY_ONLINE], online)
		
		mysql_read_result2("ip", util, 31)
		ArrayPushString(g_servers[ARRAY_IP], util)
		
		mysql_read_result2("servertitle", util, 31)
		ArrayPushString(g_servers[ARRAY_TITLE], util)
		
		mysql_read_result2("map", util, 31)
		ArrayPushString(g_servers[ARRAY_MAP], util)
		
		if(online)
		{
			g_global_players += players
			g_global_maxplayers += maxplayers
		}
		g_count++
		mysql_next_row()
	}

	g_global_players += get_playersnum(1)
	g_global_maxplayers += g_maxplayers
}
