#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <fun>

#define OA_UTIL_INC
#define OA_OLD_MENU_INC
#define OA_ADM_INC
#define OA_ACC_INC
#include <onlyarg.inc>

#define PLUGIN	"OA: Auto-Mix"
#define VERSION	"1.3Beta"
#define AUTHOR	"Destro"
/**********************************************/

#define _A 0
#define _B 1
#define PRIMERA 0
#define SEGUNDA 1
#define TOTAL 2
#define LADO 3
#define TOTAL_ROUNDS 15
#define WAITING_TIME 7
#define SEEABLE_TIME 8

#define is_user_valid_connected(%1) (1 <= %1 <= g_maxplayers && g_is_connected[%1])
#define is_user_valid_alive(%1) (1 <= %1 <= g_maxplayers && g_is_alive[%1])

enum (+= 500)
{
	TASK_MENU = 2000,
	TASK_TEAMSELEC,
	TASK_RESET,
	TASK_SPAWN,
	TASK_RESTART,
	TASK_AFK,
}

enum {
	_MATCH_WARMUP,
	_MATCH_VOTEMAP,
	_MATCH_WAIT,
	_MATCH_RANDOMORCAPTAIN,
	_MATCH_VOTECAPTAIN,
	_MATCH_SELECTTEAM,
	_MATCH_KNIFE,
	_MATCH_VOTESIDE,
	_MATCH_STARTED,
	_MATCH_END
}

new const CFG_WARMUP[] = "practica.cfg"
new const CFG_CLOSED[] = "cerrado.cfg"

new g_roundswin[2][4], g_hatf, g_match_status, g_roundwinteam
new g_captain[2], g_teammenu, g_teammenu_noplayers
new g_ready[33], g_name[33][32], g_login[33], g_lastopen[33], g_disconnect_time
new g_seeable_time[33], g_spect_target[33], g_curspect[33], g_curspect_team[33], g_cache_team[33]
new g_waitingcount, g_waiting[33]
new g_best_info[2][256]

new g_maxplayers, g_systime, g_msgTeamScore, g_msgScreenFade, g_MsgSync, g_MsgSync2, g_MsgSync3, g_MsgSync4

new g_vote_precaptain[2], g_vote_captain[33], g_vote_side[2], g_players[32]

new g_is_connected[33], g_is_alive[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /resultado", "clcmd_result")
	register_clcmd("say_team /resultado", "clcmd_result")
	
	g_msgTeamScore = get_user_msgid("TeamScore")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	
	register_message(g_msgTeamScore, "message_teamscore")
	register_message(g_msgScreenFade, "message_screenfade")
	register_message(get_user_msgid("Money"), "message_money")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("SendAudio", "event_audio_tt", "a", "2&%!MRAD_terwin") 
	register_event("SendAudio", "event_audio_ct", "a", "2&%!MRAD_ctwin") 
	register_event("TeamInfo", "event_jointeam", "a")
	register_event("TextMsg", "event_spect_mode", "bd", "2&Spec_Mode")
	register_event("SpecHealth2", "event_spect_target", "bd")

	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_forward(FM_AddToFullPack, "fw_AddToFullPack", 1)
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem")
	
	new wpn_ent[20]
	for(new wpn = CSW_P228; wpn <= CSW_P90; wpn++)
	{
		if(wpn == 2 || wpn == CSW_C4)
			continue
			
		if(get_weaponname(wpn, wpn_ent, charsmax(wpn_ent))) 
			RegisterHam(Ham_Weapon_PrimaryAttack, wpn_ent, "fw_primary_attack_post", 1)
	}
	
	g_MsgSync = CreateHudSyncObj()
	g_MsgSync2 = CreateHudSyncObj()
	g_MsgSync3 = CreateHudSyncObj()
	g_MsgSync4 = CreateHudSyncObj()
	
	g_maxplayers = get_maxplayers()
	
	set_task(1.0, "show_hud", .flags="b")
	
	new data[4]
	get_vaultdata("automix_status", data, 3)
	set_vaultdata("automix_status", "0")
	
	g_match_status = str_to_num(data)
	
	if(g_match_status == _MATCH_WARMUP)
		server_cmd("exec %s", CFG_WARMUP)
	else {
		server_cmd("exec %s", CFG_CLOSED)
		set_task(180.0, "automix_reset", TASK_RESET)
	}
	
	oldmenu_register()
}

public plugin_end()
{
	if(g_match_status == _MATCH_VOTEMAP)
	{
		set_vaultdata("automix_status", "2")
		server_cmd("exec %s", CFG_CLOSED)
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(victim == attacker || !is_user_valid_connected(attacker) || !is_user_valid_connected(victim))
		return HAM_IGNORED

	if(oa_get_user_team(attacker) != oa_get_user_team(victim))
	{
		if(g_match_status == _MATCH_STARTED)
		{
			update_seeable(victim, (SEEABLE_TIME / 2))
		}	
		return HAM_IGNORED
	}
	

	SetHamParamEntity(1, attacker)
	return HAM_IGNORED
}

public fw_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id))
		return
	
	static team;team=oa_get_user_team(id)
	if(team != 1 && team != 2) return
	
	g_is_alive[id] = true
	g_seeable_time[id] = g_systime + 14
	
	if(g_match_status <= _MATCH_VOTEMAP) cs_set_user_money(id, 16000, 0)

	if(g_match_status == _MATCH_KNIFE)
	{
		cs_set_user_money(id, 0, 0)
		strip_user_weapons(id)
		give_item(id, "weapon_knife")
	}
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(!is_user_valid_connected(victim))
		return

	g_is_alive[victim] = false
	
	if(g_match_status <= _MATCH_VOTEMAP)
	{
		set_task(3.0, "respawn_player", victim+TASK_SPAWN)
	}
}

public fw_AddPlayerItem(id, weapon_ent)
{
	if(g_match_status == _MATCH_STARTED || !is_user_valid_alive(id))
		return HAM_IGNORED

	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)

	if(g_match_status == _MATCH_KNIFE && weaponid != CSW_KNIFE)
	{
		set_pev(weapon_ent, pev_flags, FL_KILLME)
		return HAM_SUPERCEDE
	}
	
	if(weaponid == CSW_C4)
	{
		set_pev(weapon_ent, pev_flags, FL_KILLME)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public fw_primary_attack_post(ent)
{
	if(g_match_status != _MATCH_STARTED)
		return
		
	static id
	id = pev(ent, pev_owner)
	
	update_seeable(id, SEEABLE_TIME)
}

public fw_AddToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if(g_match_status != _MATCH_STARTED)
		return
	
	if(!player || !g_is_alive[ent] || !g_waiting[host])
		return
	
	if((g_seeable_time[ent] - 2) < g_systime && g_curspect_team[host] == g_cache_team[ent])
		set_es(es, ES_Effects, EF_NODRAW)
}

public fw_oa_acc_joingame(id, acc_id, pj_id)
{
	if(pj_id) g_login[id] = LOGIN_REGISTER
	else g_login[id] = LOGIN_GUEST
	
	g_ready[id] = true
	
	show_hud()
	
	if(g_match_status == _MATCH_SELECTTEAM && g_teammenu_noplayers)
	{
		g_teammenu_noplayers = false
		show_menu_teamselec(g_teammenu)
	}
	
	if(g_match_status <= _MATCH_VOTEMAP)
	{
		
		set_task(2.0, "respawn_player", id+TASK_SPAWN)
		return TEAM_AUTO
	}

	return TEAM_SPECT
}

public fw_oa_acc_changename(id, const name[])
{
	copy(g_name[id], 31, name)
}

public client_putinserver(id)
{
	g_is_connected[id] = true
	g_login[id] = LOGIN_GUEST
}

public client_disconnect(id)
{
	g_is_connected[id] = false
	g_vote_captain[id] = false
	g_is_alive[id] = false
	g_ready[id] = false
	
	remove_waiting(id)

	new count = count_connecteds()
	
	if(g_match_status == _MATCH_STARTED && count < 6)
	{
		automix_reset()
		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 5.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync3, "AutoMix Reiniciado por falta de jugadores")
	}
	
	if(g_match_status > _MATCH_SELECTTEAM)
	{
		new team = oa_get_user_team(id)
		if(team == 1 || team == 2)
			g_disconnect_time = get_systime()
	}
	
	if(_MATCH_KNIFE >= g_match_status >= _MATCH_RANDOMORCAPTAIN)
	{
		if(count < 8)
		{
			oa_chat_color(0, _, "!g[Only-Arg] !tPlayers insuficiente. Volviendo al estado de espera.")
			g_match_status = _MATCH_WAIT
			
			for(new i=1; i <= g_maxplayers; i++)
			{
				if(!g_is_connected[i]) continue
				
				if(oa_get_user_team(i) != TEAM_SPECT)
					oa_eng_change_team(i, TEAM_SPECT)
			}
			
			remove_task(TASK_RESET)
			set_task(360.0, "automix_reset", TASK_RESET)
		}
		else if(g_match_status == _MATCH_SELECTTEAM)
		{
			if(g_captain[_A] == id)
			{
				count = get_cts(g_players)
				if(!count) count = get_spects(g_players)
			
				g_captain[_A] = g_players[random_num(1, count)-1]
				oa_chat_color(0, _, "!g[Only-Arg] !tEl capitan del Equipo A se ha ido,!y%s es el nuevo capitan.", g_name[g_captain[_A]])
				if(g_teammenu == id)
					show_menu_teamselec(g_captain[_A])
			}
			if(g_captain[_B] == id)
			{
				count = get_tts(g_players)
				if(!count) count = get_spects(g_players)

				g_captain[_B] = g_players[random_num(1, count)-1]
				oa_chat_color(0, _, "!g[Only-Arg] !tEl capitan del Equipo B se ha ido,!y%s es el nuevo capitan.", g_name[g_captain[_B]])
				if(g_teammenu == id)
					show_menu_teamselec(g_captain[_B])
			}
		}
	}
}

/*=================================================================================================================*
|		 Eventos&MSG																							  |
*================================================================================================================*/

public event_round_start()
{
	g_roundwinteam = TEAM_UNASSIGNED
	
	if(g_match_status == _MATCH_KNIFE)
	{
		oa_chat_color(0, _, "!g[Only-Arg] !tIniciando Ronda a Faka")
	}
}

public logevent_round_end()
{
	if(!g_roundwinteam)
		return
	
	if(g_match_status == _MATCH_KNIFE)
	{
		new ttalive, ctalive
		for(new id=1; id <= g_maxplayers; id++)
		{
			if(!is_user_valid_alive(id))
				continue
			
			if(oa_get_user_team(id) == TEAM_CT)
				ctalive++
			else	ttalive++
		}
	
		
		if(ctalive == ttalive)
		{
			oa_chat_color(0, _, "!g[Only-Arg] !tNingun equipo gano la ronda a faka. Sin cambio de lados")
			g_roundswin[_A][LADO] = TEAM_CT
			g_roundswin[_B][LADO] = TEAM_TT
			automix_start()
			return
		}
		
		if(ctalive > ttalive)
			oa_chat_color(0, _, "!g[Only-Arg] !tEl !gEquipo A !tgana la ronda a faka")
		else	oa_chat_color(0, _, "!g[Only-Arg] !tEl !gEquipo B !tgana la ronda a faka")
		
		oa_chat_color(0, _, "!g[Only-Arg] !tIniciando votacion por el lado")
		show_menu_voteside(g_roundwinteam)
		return
	}
	
	if(g_match_status == _MATCH_STARTED)
	{
		if(g_roundswin[_A][LADO] == g_roundwinteam)
			g_roundswin[_A][g_hatf]++
		else 
			g_roundswin[_B][g_hatf]++
		
		g_roundswin[_A][TOTAL] = g_roundswin[_A][PRIMERA]+g_roundswin[_A][SEGUNDA]
		g_roundswin[_B][TOTAL] = g_roundswin[_B][PRIMERA]+g_roundswin[_B][SEGUNDA]
		
		if(g_hatf)
		{
			if(g_roundswin[_A][TOTAL] == (TOTAL_ROUNDS+1))
			{
				set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 5.0, 0.0, 0.0, -1)
				ShowSyncHudMsg(0, g_MsgSync3, "Game Over^nEquipo A gana el juego!")
				set_task(10.0, "automix_reset")
				info_best()
				g_match_status = _MATCH_END
			}
			else if(g_roundswin[_B][TOTAL] == (TOTAL_ROUNDS+1))
			{
				set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 5.0, 0.0, 0.0, -1)
				ShowSyncHudMsg(0, g_MsgSync3, "Game Over^nEquipo B gana el juego!")
				set_task(10.0, "automix_reset")
				info_best()
				g_match_status = _MATCH_END
			}
			else if(g_roundswin[_A][TOTAL] == TOTAL_ROUNDS && TOTAL_ROUNDS == g_roundswin[_B][TOTAL])
			{
				set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 5.0, 0.0, 0.0, -1)
				ShowSyncHudMsg(0, g_MsgSync3, "Game Over^nJuego Empatado")
				set_task(10.0, "automix_reset")
				info_best()
				g_match_status = _MATCH_END
			}
		}
		else {
			if((g_roundswin[_A][PRIMERA]+g_roundswin[_B][PRIMERA]) == TOTAL_ROUNDS)
			{
				info_best()
				
				if(g_roundswin[_A][LADO] == TEAM_CT)
				{
					g_roundswin[_A][LADO] = TEAM_TT
					g_roundswin[_B][LADO] = TEAM_CT
				}
				else {
					g_roundswin[_A][LADO] = TEAM_CT
					g_roundswin[_B][LADO] = TEAM_TT
				}
				
				g_hatf = 1
				
				oa_chat_color(0, _, "!g[Only-Arg] !tFinalizo la primera parte,cambio de lado")
				set_task(1.5, "change_teams")
				task_restart(2)
			}
		}
		
		set_team_score(g_roundswin[_A][LADO], g_roundswin[_A][TOTAL])
		set_team_score(g_roundswin[_B][LADO], g_roundswin[_B][TOTAL])
	}
}

public event_audio_tt()
	g_roundwinteam = TEAM_TT

public event_audio_ct()
	g_roundwinteam = TEAM_CT
	
public event_jointeam()
{
	static id, team[2]
	
	id = read_data(1)
	read_data(2, team, 1)
	
	if(team[0] == 'C' || team[0] == 'T')
	{
		remove_waiting(id)
		g_cache_team[id] = (team[0]=='C')?TEAM_CT:TEAM_TT
	}
	else if(g_ready[id])
	{
		add_waiting(id)
		event_spect_mode(id)
	}
}

public message_teamscore()
{
	static team[2]
	get_msg_arg_string(1, team, charsmax(team))
	
	if(team[0] == 'C')
	{
		if(g_roundswin[_A][LADO] == TEAM_CT)
			set_msg_arg_int(2, ARG_SHORT, g_roundswin[_A][TOTAL])
		else
			set_msg_arg_int(2, ARG_SHORT, g_roundswin[_B][TOTAL])
	}
	else if(team[0] == 'T')
	{
		if(g_roundswin[_A][LADO] == TEAM_TT)
			set_msg_arg_int(2, ARG_SHORT, g_roundswin[_A][TOTAL])
		else
			set_msg_arg_int(2, ARG_SHORT, g_roundswin[_B][TOTAL])
	}
}

public message_money(msg_id, msg_dest, id)
{
	if(!is_user_connected(id)) return PLUGIN_CONTINUE
	
	if(g_match_status == _MATCH_KNIFE)
	{
		cs_set_user_money(id, 0, 0)
		set_msg_arg_int(1, ARG_LONG, 0)
	}

	return PLUGIN_CONTINUE
}

/*=================================================================================================================*
|		 HUDs																									 |
*================================================================================================================*/
public show_hud()
{
	static id, info_a[512], info_b[512]
	
	if(g_match_status == _MATCH_WARMUP || g_match_status == _MATCH_WAIT)
	{
		static len, len2, players

		g_ready[0] = 0

		len = formatex(info_a, charsmax(info_a), "Jugadores Listos:^n")
		len2 = formatex(info_b, charsmax(info_b), "Jugadores en espera:^n")
	
		for(id=1; id <= g_maxplayers; id++)
		{
			if(!g_is_connected[id])
				continue
		
			players++
		
			if(g_ready[id])
			{
				len += formatex(info_a[len], charsmax(info_a)-len, "- %s^n", g_name[id])
				g_ready[0]++
			}
			else {
				len2 += formatex(info_b[len2], charsmax(info_b)-len2, "%s -^n", g_name[id])
			}
		}

		if(g_ready[0] >= 10)
		{
			if(g_match_status == _MATCH_WARMUP)
			{
				g_match_status = _MATCH_VOTEMAP
				oa_chat_color(0, _, "!g[Only-Arg] !tIniciando votacion de map.")
				server_cmd("amx_start_votemap")
			}
			else {
				remove_task(TASK_RESET)

				oa_chat_color(0, _, "!g[Only-Arg] !tIniciando votacion de formacion.")
				show_menu_precaptain()
			}
			return
		}

		set_hudmessage(0, 200, 0, 0.0, 0.2, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, info_a)

		set_hudmessage(255, 0, 0, 1.0, 0.2, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync2, info_b)


		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 1.1, 0.0, 0.0, -1)

		if(g_match_status == _MATCH_WAIT)
			ShowSyncHudMsg(0, g_MsgSync3, "Estado: En espera^nFaltan %d jugadores para seleccion de equipos", 10-g_ready[0])
		else
			ShowSyncHudMsg(0, g_MsgSync3, "Estado: Modo Practica^nFaltan %d jugadores para comenzar el automix", 10-g_ready[0])
	}
	else if(g_match_status == _MATCH_VOTEMAP)
	{
		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync3, "Estado: Votando Mapa")
	}
	else if(g_match_status == _MATCH_RANDOMORCAPTAIN)
	{
		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync3, "Estado: Votando Formacion")
	}
	else if(g_match_status == _MATCH_VOTECAPTAIN)
	{
		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync3, "Estado: Votando Capitanes")
	}
	else if(g_match_status == _MATCH_SELECTTEAM)
	{
		static len, len2, team

		len = formatex(info_a, charsmax(info_a), "Equipo A:^n- *%s^n", g_name[g_captain[_A]])
		len2 = formatex(info_b, charsmax(info_b), "Equipo B:^n- *%s^n", g_name[g_captain[_B]])
	
		for(id=1; id <= g_maxplayers; id++)
		{
			if(!g_is_connected[id])
				continue
		
			team = oa_get_user_team(id)
			if(team == 2 && id != g_captain[_A])
				len += formatex(info_a[len], charsmax(info_a)-len, "- %s^n", g_name[id])
			else if(team == 1 && id != g_captain[_B])
				len2 += formatex(info_b[len2], charsmax(info_b)-len2, "- %s^n", g_name[id])
		}

		set_hudmessage(0, 0, 255, 0.2, 0.2, 0, 3.0, 1.2, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, info_a)
	
		set_hudmessage(255, 0, 0, 0.75, 0.2, 0, 3.0, 1.2, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync2, info_b)
		
		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 3.0, 1.2, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync3, "Estado: Armando Equipos")
	}
	else if(g_match_status == _MATCH_KNIFE)
	{
		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 3.0, 1.2, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync3, "Estado: Ronda a Faka")
	}
	else if(g_match_status == _MATCH_STARTED)
	{
		for(id=1; id <= g_maxplayers; id++)
		{
			if(g_is_connected[id] && g_waiting[id])
				update_spectator(id)
		}
	}
	else if(g_match_status == _MATCH_END)
	{
		if(g_roundswin[_A][LADO] == TEAM_CT)
			formatex(info_a, charsmax(info_a), "Equipo A(CT): %d !t- Equipo B(TT): %d", g_roundswin[_A][TOTAL], g_roundswin[_B][TOTAL])
		else
			formatex(info_a, charsmax(info_a), "Equipo A(TT): %d !t- Equipo B(CT): %d", g_roundswin[_A][TOTAL], g_roundswin[_B][TOTAL])
			
		set_hudmessage(255, 255, 255, -1.0, 0.12, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync3, "Estado: Mix Finalizado^n%s", info_a)
		
		
		set_hudmessage(255, 50, 50, -1.0, 0.2, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync, g_best_info[0])
	
		set_hudmessage(255, 50, 50, -1.0, 0.23, 0, 2.5, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_MsgSync2, g_best_info[1])
	}
	
	if(_MATCH_SELECTTEAM < g_match_status < _MATCH_END)
	{
		static len, missing, wait
		
		missing = (get_playings(g_players) < 10)
		g_systime = get_systime()
		
		get_waitings(g_players)
		len = 0
		
		len = formatex(info_a, 511, "Cola de espera:^n")
		for(new i; i < g_waitingcount; i++)
		{
			wait = (g_disconnect_time + (WAITING_TIME * i)) - g_systime
			
			if(!missing)
				len += formatex(info_a[len], 511-len, "- %s^n", g_name[g_players[i]])
			else if(wait > 0)
				len += formatex(info_a[len], 511-len, "- %s [%ds]^n", g_name[g_players[i]], wait)
			else 
				len += formatex(info_a[len], 511-len, "- %s*^n", g_name[g_players[i]])

			if(wait <= 0 && missing && g_lastopen[g_players[i]] < g_systime)
			{
				g_lastopen[g_players[i]] = g_systime + WAITING_TIME
				show_menu_main(g_players[i])
			}
		}
		
		set_hudmessage(255, 128, 5, 0.02, 0.15, 0, 3.0, 1.2, 0.0, 0.0, -1)
		
		for(id=1; id <= g_maxplayers; id++)
		{
			if(!g_is_connected[id] || oa_get_user_team(id) != TEAM_SPECT)
				continue
		
			ShowSyncHudMsg(id, g_MsgSync4, info_a)
		}
	}
	
}

/*=================================================================================================================*
|		 SPECTATOR																								|
*================================================================================================================*/
public event_spect_mode(id)
{
	if(g_match_status == _MATCH_STARTED && oa_get_user_team(id) == TEAM_SPECT && count_alives())
		set_pev(id, pev_iuser1, 4) // in eyes

	client_print(id, print_center, "")
}

public event_spect_target(id)
{
	if(g_match_status != _MATCH_STARTED || !g_waiting[id])
		return
		
	update_spectator(id, read_data(2))
}

public message_screenfade(msgid, dest, id)
{
	if(g_match_status != _MATCH_STARTED || !g_waiting[id])
		return PLUGIN_CONTINUE
		
	if(g_seeable_time[g_curspect[id]] < g_systime)
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

update_spectator(id, spect_target=0)
{
	static target, send_flashed[33]
	
	if(spect_target)
		target = g_curspect[id] = spect_target
	else	target = g_curspect[id] = pev(id, pev_iuser2)
	
	g_curspect_team[id] = g_cache_team[target]
	
	if(!g_is_alive[target])
		return
	
	if(g_seeable_time[target] < g_systime)
	{
		util_screenfade(id, 3, 3, 2, 2, 2, 255, 0x0004)
		
		send_flashed[id] = false
	}
	else if(!spect_target && !send_flashed[id])
	{
		send_flashed[id] = true
		if(!update_flashed(target, id))
			util_screenfade(id, 1, 1, 1, 1, 1, 1)
	}
}

update_seeable(id, _time)
{
	if(g_seeable_time[id] < g_systime)
	{
		g_seeable_time[id] = g_systime + _time
		
		static spect
		for(spect=1; spect <= g_maxplayers; spect++)
		{
			if(g_is_connected[spect] && g_waiting[spect] && g_curspect[spect] == id)
				update_spectator(spect)
		}
	}
	else {
		g_seeable_time[id] = g_systime + _time
	}
}

update_flashed(player, spectator)
{
	#define m_blindUntilTime	514
	#define m_blindStartTime	515
	#define m_blindHoldTime		516
	#define m_blindFadeTime		517
	#define m_blindAlpha		518
	
	new Float:blindStartTime, Float:blindFadeTime
	
	blindStartTime = get_pdata_float(player, m_blindStartTime, 5)
	blindFadeTime = get_pdata_float(player, m_blindFadeTime, 5)
	
	if(blindStartTime == 0 || blindFadeTime == 0)
		return 0
		
	new Float:blindHoldTime, Float:blindAlpha, Float:fadeTime, Float:holdTime,
	Float:alpha, Float:ratio, Float:gametime, Float:endTime
	
	endTime = blindFadeTime + blindHoldTime + blindStartTime
	blindHoldTime = get_pdata_float(player, m_blindHoldTime, 5)
	blindAlpha = get_pdata_float(player, m_blindAlpha, 5)
	gametime = get_gametime()
	
	if(endTime > gametime)
	{
		fadeTime = blindFadeTime
		alpha = blindAlpha
		holdTime = blindHoldTime + blindStartTime - gametime
		
		if(holdTime <= 0)
		{
			holdTime = 0.0
			ratio = (endTime - gametime) / blindFadeTime + 15.0
			alpha = blindAlpha * ratio
			fadeTime = ratio * fadeTime
		}

		util_screenfade(spectator, floatround(fadeTime), floatround(holdTime), 255, 255, 255, floatround(alpha))
		return 1
	}
	
	return 0
}
/*=================================================================================================================*
|		 CLCMD																									|
*================================================================================================================*/
public clcmd_result(id)
{
	if(g_match_status != _MATCH_STARTED)
	{
		oa_chat_color(id, _, "!g[Only-Arg] !tNo se esta jugando una partida")
		return 1
	}

	if(g_roundswin[_A][LADO] == TEAM_CT)
		oa_chat_color(0, _, "!g[Only-Arg] !tEquipo A(CT): !y%d !t- Equipo B(TT): !y%d", g_roundswin[_A][TOTAL], g_roundswin[_B][TOTAL])
	else oa_chat_color(0, _, "!g[Only-Arg] !tEquipo A(TT): !y%d !t- Equipo B(CT): !y%d", g_roundswin[_A][TOTAL], g_roundswin[_B][TOTAL])
	return 0
}

public fw_oa_acc_mainmenu(id)
{
	show_menu_main(id)
	return 2
}

show_menu_main(id)
{
	oldmenu_create("menu_main", "\rAuto-Mix \d- \yComunidad Only-Arg:")
	
	if(oa_get_user_team(id) == TEAM_SPECT && (_MATCH_SELECTTEAM < g_match_status < _MATCH_END))
		oldmenu_additem(1, 0, "\r1. \wIngresar^n")
	else 	oldmenu_additem(-1, 0, "\d1. Ingresar^n")

	if(g_login[id] == LOGIN_REGISTER)
	{
		if(oa_has_access(id, ACCESS_ANY_ADM))
			oldmenu_additem(3, 0, "\r3. \wAdmin")
		else if(oa_admin_is_suspended(id))
			oldmenu_additem(3, 0, "\r3. \rAdmin \d(Suspendido)")
		else oldmenu_additem(-1, 0, "\d3. Admin")
	
		oldmenu_additem(4, 0, "\r4. \wCuenta")
	}
				
	oldmenu_additem(0, 0, "^n\r0. \wSalir")
	oldmenu_display(id)
}

public menu_main(id, itemnum, value, page)
{
	if(!itemnum) return
	

	if(itemnum == 1)
	{
		if(oa_get_user_team(id) == TEAM_SPECT && g_match_status > _MATCH_SELECTTEAM)
		{
			static cts, tts
			cts = get_cts(g_players)
			tts = get_tts(g_players)
			
			if(cts == 5 && tts == 5)
				client_print(id, print_center, "Todos los equipos estan completos")
			else if(allow_pass(id))
				oa_eng_change_team(id, (cts<tts)?TEAM_CT:TEAM_TT)
			else	client_print(id, print_center, "Otro jugador ha estado esperando mas tiempo para jugar")
		}
	}
	else if(itemnum == 3)
		oa_admin_openmenu(id)
	else if(itemnum == 4)
		oa_acc_menu(id)
}


/*=================================================================================================================*
|		 RONDAS																								   |
*================================================================================================================*/
public round_knife()
{
	g_match_status = _MATCH_KNIFE
	
	task_restart(5)

	set_hudmessage(255, 200, 0, -1.0, 0.25, 0, 2.5, 5.5, 0.0, 0.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "Equipos Armados! ^n Preparando ronda a faka")
}

public automix_reset()
{
	server_cmd("exec %s", CFG_WARMUP)
	server_cmd("sv_restar 1")
	
	g_match_status = _MATCH_WARMUP
	
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id] || !g_ready[id])
			continue
				
		if(oa_get_user_team(id) == TEAM_SPECT)
			oa_eng_change_team(id, TEAM_AUTO)
	}
}

automix_start()
{
	g_match_status = _MATCH_STARTED
	task_restart(5)
	
	set_hudmessage(255, 200, 0, -1.0, 0.25, 0, 2.5, 5.5, 0.0, 0.0, -1)
	ShowSyncHudMsg(0, g_MsgSync, "Comienza la Partida!")
	
	g_roundswin[_A][PRIMERA] = g_roundswin[_A][SEGUNDA] = g_roundswin[_A][TOTAL] = 0
	g_roundswin[_B][PRIMERA] = g_roundswin[_B][SEGUNDA] = g_roundswin[_B][TOTAL] = 0
	g_hatf = 0
	
	oa_chat_color(0, _, "!g[Only-Arg] !tComienza la Partida!")
	oa_chat_color(0, _, "!g[Only-Arg] !tVale al Restart!")
}

info_best()
{
	new player, win_frags, frags, team
	
	for(new id; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id]) continue
		
		team = oa_get_user_team(id)
		if(team != TEAM_TT && team != TEAM_CT) continue
		
		frags = get_user_frags(id)
		if(frags > win_frags)
		{
			win_frags = frags
			player = id
		}
	}
	
	if(!g_hatf)
		formatex(g_best_info[0], charsmax(g_best_info[]),
		"Mejor jugador Primera Mitad %s con %d Frags", g_name[player], win_frags)
	else formatex(g_best_info[1], charsmax(g_best_info[]),
		"Mejor jugador Segunda Mitad %s con %d Frags", g_name[player], win_frags)


}

/*=================================================================================================================*
|		 TEAMSELECT																							   |
*================================================================================================================*/
show_menu_teamselec(id, page=1)
{
	g_teammenu = id
	
	new cts, tts, spect
	cts = get_cts(g_players)
	tts = get_tts(g_players)
	spect = get_spects(g_players)
	if(cts == 5 && tts == 5)
	{
		round_knife()
		return
	}
	
	if(!spect)
	{
		g_teammenu_noplayers = true
		oa_chat_color(id, _, "!g[Only-Arg] !tNo hay jugadores disponibles para elegir")
		return
	}
	
	if(g_captain[_A] == id && cts == 5) id = g_teammenu = g_captain[_B]
	else if(tts == 5) id = g_teammenu = g_captain[_A]
	
	new maxpages, start, end
	oldmenu_calculate_pages(maxpages, start, end, page, spect)
	oldmenu_create("menu_teamselec", "\rElegir Jugador: %d/%d", page, maxpages)
	
	spect = 0
	for(new pl=start; pl < end; pl++)
	{
		spect++
		g_vote_captain[g_players[pl]] = 0
		
		oldmenu_additem(spect, g_players[pl], "\r%d. \w%s", spect, g_name[g_players[pl]])
	}
	
	oldmenu_pagination(page, maxpages)
	oldmenu_display(id, page, 7)

	set_task(7.0, "random_select", id+TASK_TEAMSELEC)
}

public menu_teamselec(id, itemnum, value, page)
{
	if(!itemnum || id != g_teammenu)
		return

	if(itemnum > 7)
	{
		show_menu_teamselec(id, page+value)
		return
	}
	
	remove_task(id+TASK_TEAMSELEC)

	if(!g_is_connected[value] || oa_get_user_team(value) != TEAM_SPECT)
	{
		oa_chat_color(id, _, "!g[Only-Arg] !tPlayer invalido.")
		show_menu_teamselec(id)
		return
	}
	
	if(g_captain[_A] == id)
	{
		oa_chat_color(0, id, "!g[Only-Arg] !y%s !teligio a !y%s !t para el Equipo A", g_name[id], g_name[value])
		oa_eng_change_team(value, TEAM_CT)
		show_menu_teamselec(g_captain[_B])
	}
	else { 
		oa_chat_color(0, id, "!g[Only-Arg] !y%s !teligio a !y%s !t para el Equipo B", g_name[id], g_name[value])
		oa_eng_change_team(value, TEAM_TT)
		show_menu_teamselec(g_captain[_A])
	}
	
	set_task(2.0, "respawn_player", value+TASK_SPAWN)
}

public random_select(id)
{
	id -= TASK_TEAMSELEC
	
	if(id != g_teammenu)
		return
	
	new count
	count = get_spects(g_players)
	if(!count) 
	{
		g_teammenu_noplayers = true
		oa_chat_color(id, _, "!g[Only-Arg] !tNo hay jugadores disponibles para elegir")
		return
	}
	
	new target = g_players[random_num(1, count)-1]
	
	if(g_captain[_A] == id)
	{
		oa_chat_color(0, id, "!g[Only-Arg] !y%s !tfue AutoTransferido para el Equipo A", g_name[target])
		oa_eng_change_team(target, TEAM_CT)
		show_menu_teamselec(g_captain[_B])
	}
	else { 
		oa_chat_color(0, id, "!g[Only-Arg] !y%s !tfue AutoTransferido para el Equipo B", g_name[target])
		oa_eng_change_team(target, TEAM_TT)
		show_menu_teamselec(g_captain[_A])
	}
	set_task(2.0, "respawn_player", target+TASK_SPAWN)
}

random_team()
{
	new count, cts, tts, rand, chance, loop
	loop = count = get_spects(g_players)
	
	while(loop && (cts != 5 && tts != 5))
	{
		rand = (random_num(1, count)-1)
		
		if(!g_players[rand]) continue
		
		if(chance && cts < 5)
		{
			cts++
			chance=0
			loop--
			oa_eng_change_team(g_players[rand], TEAM_CT)
		}
		else if(tts < 5)
		{
			tts++
			chance=1
			loop--
			oa_eng_change_team(g_players[rand], TEAM_TT)
		}

		g_players[rand] = 0
	}
	
	round_knife()
}

/*=================================================================================================================*
|		 VOTES																									|
*================================================================================================================*/
show_menu_voteside(team)
{
	g_match_status = _MATCH_VOTESIDE
	
	oldmenu_create("menu_voteside", "\rCambio de lado:")
	
	oldmenu_additem(1, 0, "\r1. \wQuedarse")
	oldmenu_additem(2, 1, "\r2. \wCambiar")

	for(new id=1; id <= g_maxplayers; id++)
	{
		if(g_is_connected[id] && oa_get_user_team(id) == team)
			oldmenu_display(id, _, 10)
	}
	

	set_task(10.0, "count_voteside", TASK_MENU)
}

public menu_voteside(id, itemnum, value)
{
	if(!itemnum) return
	
	g_vote_side[value]++
	oa_chat_color(0, _, "!g[Only-Arg] !y%s !tha voto por: !y%s", g_name[id], value?"Cambiar":"Quedarse")
}

public count_voteside()
{
	if(g_vote_side[1] > g_vote_side[0])
	{
		g_roundswin[_A][LADO] = TEAM_TT
		g_roundswin[_B][LADO] = TEAM_CT
		oa_chat_color(0, _, "!g[Only-Arg] !tVote finalizado,cambio de lado")
		change_teams()
	}
	else {
		g_roundswin[_A][LADO] = TEAM_CT
		g_roundswin[_B][LADO] = TEAM_TT
		oa_chat_color(0, _, "!g[Only-Arg] !tVote finalizado,sin cambios")
	}

	automix_start()
}

// =================================================================================================================
show_menu_precaptain()
{
	g_match_status = _MATCH_RANDOMORCAPTAIN
	
	oldmenu_create("menu_precaptain", "\rCambio de lado:")
	
	oldmenu_additem(1, 0, "\r1. \wEquipo al azar")
	oldmenu_additem(2, 1, "\r2. \wElegir capitan")

	for(new id=1; id <= g_maxplayers; id++)
	{
		if(g_is_connected[id] && g_ready[id])
			oldmenu_display(id, _, 10)
	}
	
	set_task(10.0, "count_precaptain", TASK_MENU)
}

public menu_precaptain(id, itemnum, value)
{
	if(!itemnum) return
	
	g_vote_precaptain[value]++
	oa_chat_color(0, _, "!g[Only-Arg] !y%s !tha voto por: !y%s", g_name[id], value?"Elegir capitan":"Equipo al azar")
}

public count_precaptain()
{
	if(g_vote_precaptain[1] > g_vote_precaptain[0])
	{
		oa_chat_color(0, _, "!g[Only-Arg] !tIniciando votacion de capitanes.")
		
		for(new id=1; id <= g_maxplayers; id++)
		{
			g_vote_captain[id] = 0
			
			if(g_is_connected[id] && g_ready[id])	
				show_menu_votecaptain(id)
		}
	
		set_task(10.0, "count_votecaptain", TASK_MENU)
		
	}
	else {
		oa_chat_color(0, _, "!g[Only-Arg] !tEquipos al azar!.")
		random_team()
	}
}
		
// =================================================================================================================
show_menu_votecaptain(id, page=1)
{
	g_match_status = _MATCH_VOTECAPTAIN
	
	new maxpages, start, end, count
	count = get_spects(g_players)
	
	oldmenu_calculate_pages(maxpages, start, end, page, count)
	oldmenu_create("menu_votecaptain", "\rVotar Capitan: %d/%d", page, maxpages)
	
	count = 0
	for(new pl=start; pl < end; pl++)
	{
		count++
		oldmenu_additem(count, g_players[pl], "\r%d. \w%s", count, g_name[g_players[pl]])
	}
	
	oldmenu_pagination(page, maxpages)
	oldmenu_display(id, page, 10)
}

public menu_votecaptain(id, itemnum, value, page)
{
	if(!itemnum)
		return
	
	if(itemnum > 7)
	{
		show_menu_votecaptain(id, page+value)
		return
	}
	
	g_vote_captain[value]++
	oa_chat_color(0, _, "!g[Only-Arg] !y%s !tha voto por: !y%s", g_name[id], g_name[value])
}

public count_votecaptain()
{
	new win, win2
	
	for(new id=1; id <= g_maxplayers; id++)
	{

		if(!g_is_connected[id] || !g_ready[id])
			continue
		
		if(g_vote_captain[id] > g_vote_captain[win])
		{
			if(g_vote_captain[win] > g_vote_captain[win2])
				win2 = win
			win = id
		}
		else if(g_vote_captain[id] > g_vote_captain[win2])
			win2 = id
	}

	if(!win || !win2)
	{
		oa_chat_color(0, _, "!g[Only-Arg] !tFallo votacion de capitanes.")
		oa_chat_color(0, _, "!g[Only-Arg] !tEquipos al azar!.")
		random_team()
		return
	}
	
	oa_chat_color(0, _, "!g[Only-Arg] !tCapitanes elegidos.")
	oa_chat_color(0, _, "!g[Only-Arg] !tEquipo A: !y%s (%d votos) !t- Equipo B: !y%s (%d votos)", g_name[win], g_vote_captain[win], g_name[win2], g_vote_captain[win2])
	
	g_match_status = _MATCH_SELECTTEAM
	
	g_captain[_A] = win
	g_captain[_B] = win2
	
	oa_eng_change_team(g_captain[_A], TEAM_CT)
	oa_eng_change_team(g_captain[_B], TEAM_TT)
	
	show_menu_teamselec(g_captain[_A])
}

/*=================================================================================================================*
|		Funciones utiles/Stocks																				   |
*================================================================================================================*/	
public respawn_player(id)
{
	id -= TASK_SPAWN 
	if(!g_is_connected[id] || g_is_alive[id]) return
	
	new team = oa_get_user_team(id)
	if(team == 1 || team == 2)
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}

get_spects(players[32], ready=true)
{
	new num
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id] || oa_get_user_team(id) != TEAM_SPECT)
			continue
		
		if(ready && !g_ready[id])
			continue
			
		players[num++] = id
	}
	return num
}

get_cts(players[32])
{
	new num
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(g_is_connected[id] && oa_get_user_team(id) == TEAM_CT)
			players[num++] = id
	}
	return num
}

get_tts(players[32])
{
	new num
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(g_is_connected[id] && oa_get_user_team(id) == TEAM_TT)
			players[num++] = id
	}
	return num
}

get_playings(players[32])
{
	new num, team
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id])
			continue
		
		team = oa_get_user_team(id)
		if(team == TEAM_TT || team == TEAM_CT)
			players[num++] = id
	}
	return num
}

count_connecteds()
{
	new num
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(g_is_connected[id]) num++
	}
	return num
}

count_alives()
{
	new num
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(g_is_alive[id]) num++
	}
	return num
}

stock task_restart(seconds)
{
	remove_task(TASK_RESTART)
	set_task(0.1+seconds, "restart", TASK_RESTART)
}

public restart()
	server_cmd("sv_restart 1")

public change_teams()
{	
	new team
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(!g_is_connected[id])
			continue
		
		team = oa_get_user_team(id)
		if(team == TEAM_TT)
			oa_set_user_team(id, TEAM_CT)
		else if(team == TEAM_CT)
			oa_set_user_team(id, TEAM_TT)
	}
}

stock set_team_score(team, score)
{	 
	message_begin(MSG_ALL, g_msgTeamScore)
	write_string((team==TEAM_TT)?"TERRORIST":"CT")
	write_short(score)
	message_end()
}

/*
#define FFADE_IN		0x0000		// Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0001		// Fade out (not in)
#define FFADE_MODULATE		0x0002		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0004		// ignores the duration, stays faded out until new ScreenFade message received
*/
stock util_screenfade(id, duration, holdtime, red, green, blue, alpha, flags=0x0000)
{
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short((1<<12)*duration) // duration
	write_short((1<<12)*holdtime) // hold time
	write_short(flags) // fade type
	write_byte(red) // red
	write_byte(green) // green
	write_byte(blue) // blue
	write_byte(alpha) // alpha
	message_end()
}


// WAITING
add_waiting(id)
{
	if(g_waiting[id])
		return
	
	g_waiting[id] = ++g_waitingcount
}

remove_waiting(id)
{
	if(!g_waiting[id])
		return
	
	for(new pl=1; pl <= g_maxplayers; pl++)
	{
		if(g_waiting[pl] > g_waiting[id])
			g_waiting[pl]--
	}

	g_waiting[id] = 0
	g_waitingcount--
}

get_waitings(players[32])
{
	for(new id=1; id <= g_maxplayers; id++)
	{
		if(g_waiting[id]) players[(g_waiting[id] - 1)] = id
	}
	
	return g_waitingcount
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
