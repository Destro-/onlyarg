#include <amxmodx>

#define OA_UTIL_INC
#include <onlyarg.inc>

#define PLUGIN	"OA: Grenade&Radio"
#define VERSION	"1.0"
#define AUTHOR	"Destro"
/**********************************************/

enum _:_GRENADE_STRUCT
{
	GRENADE_TAG[6],
	GRENADE_ID,
	GRENADE_COLOR
}

new const grenade_data[][_GRENADE_STRUCT] = {
	{ "^3[HE]", CSW_HEGRENADE, color_red },
	{ "^3[FB]", CSW_FLASHBANG, color_grey },
	{ "^4[SG]", CSW_SMOKEGRENADE, color_team }
}

const Float:flood_time = 3.5

public plugin_init()
{
	oa_register_plugin(PLUGIN, VERSION, AUTHOR)
	
	static const radio_cmds[][] = {
		"radio1", "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire",
		"radio2", "go", "fallback", "sticktog", "getinpos", "stormfront", "report",
		"radio3", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin", "getout", "negative", "enemydown"
	}
	
	for(new i=0; i < sizeof radio_cmds; i++)
	{
		register_clcmd(radio_cmds[i], "clcmd_checkflood")
	}

	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("ShowMenu"), "message_show_menu")
}

public message_show_menu(msgid, dest, id)
{
	static radio[8]
	get_msg_arg_string(4, radio, 7)

	if(!equal(radio, "#Radio", 6))
		return PLUGIN_CONTINUE

	static const menuA[] = "\
	\yComandos de radio \d- \rGeneral^n^n\
	\r1. \wCover Me^n\
	\r2. \wYou Take the Point^n\
	\r3. \wHold This Position^n\
	\r4. \wRegroup Team^n\
	\r5. \wFollow Me^n\
	\r6. \wTaking Fire, Need Assistance^n^n\
	\r0. \wSalir"
		
	static const menuB[] = "\
	\yComandos de radio \d- \rEquipo^n^n\
	\r1. \wGo^n\
	\r2. \wFall Back^n\
	\r3. \wStick Together Team^n\
	\r4. \wGet in Position^n\
	\r5. \wStorm the Front^n\
	\r6. \wReport In^n^n\
	\r0. \wSalir"
	
	static const menuC[] = "\
	\yComandos de radio \d- \rResponder/Reportar^n^n\
	\r1. \wAffirmative/Roger^n\
	\r2. \wEnemy Spotted^n\
	\r3. \wNeed Backup^n\
	\r4. \wSector Clear^n\
	\r5. \wI'm in Position^n\
	\r6. \wReporting In^n\
	\r7. \wShe's gonna Blow!^n\
	\r8. \wNegative^n\
	\r9. \wEnemy Down^n^n\
	\r0. \wSalir"
		
	new type = radio[6]-'A'
	show_menu(id, get_msg_arg_int(1), (type==0)?menuA:(type==1)?menuB:menuC)
	
	return PLUGIN_HANDLED
}

public message_textmsg(msgid, msgdest, id)
{
	if(get_msg_args() != 5 || get_msg_argtype(5) != ARG_STRING)
		return PLUGIN_CONTINUE
		
	static buff[32], clip, ammo, weapon, sender
	
	get_msg_arg_string(2, buff, 31)
	sender = str_to_num(buff)
	
	if(!is_user_alive(sender))
		return PLUGIN_CONTINUE
	
	get_msg_arg_string(3, buff, 31)
	if(!equal(buff, "#Game_radio"))
		return PLUGIN_CONTINUE
		
	get_msg_arg_string(5, buff, 31)
	if(equal(buff, "#Fire_in_the_hole"))
	{
		weapon = get_user_weapon(sender, clip, ammo)
		for(new i; i < sizeof grenade_data; i++)
		{
			if(weapon == grenade_data[i][GRENADE_ID])
			{
				get_msg_arg_string(4, buff, 31)
			
				oa_chat_color(id, grenade_data[i][GRENADE_COLOR],
				"^4*(RADIO)* ^1%s :  ^4Fire in the hole! %s", buff, grenade_data[i][GRENADE_TAG])

				return PLUGIN_HANDLED
			}
		}
	}
	else {
		set_msg_arg_string(3, "^4*(RADIO)* ^1%s1 :  ^4%s2")
	}

	return PLUGIN_CONTINUE
}

public clcmd_checkflood(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	static Float:flooding[33], flood[33], Float:gametime
	
	gametime = get_gametime()
	if(flooding[id] > gametime)
	{
		if(flood[id] >= 4)
		{
			client_print(id, print_center, "*** ANTI RADIO FLOOD ***")
			flooding[id] = gametime + flood_time + 4.0
			
			return PLUGIN_HANDLED
		}
		flood[id]++
	}
	else if(flood[id]) flood[id]--

	flooding[id] = gametime + flood_time

	return PLUGIN_CONTINUE
}
