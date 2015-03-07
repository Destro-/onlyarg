#include <amxmodx>

#define OA_UTIL_INC
#define OA_ADM_INC
#define OA_ACC_INC
#include <onlyarg>

#define PLUGIN	"OA: Adm CMD"
#define VERSION	"1.0.1"
#define AUTHOR	"Destro"
/**********************************************/

new g_name[33][32], g_hid[33][10]
new g_maxplayers

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	oa_register_cmd("amx_kick", "cmd_kick", ACCESS_KICK, _, "<nombre o #userid> [razon]", true)
	oa_register_cmd("amx_slay", "cmd_slay", ACCESS_SLAY, _, "<nombre o #userid>", true)
	oa_register_cmd("amx_slap", "cmd_slap", ACCESS_SLAP, _, "<nombre o #userid> [daño]", true)
	oa_register_cmd("amx_leave", "cmd_leave", ACCESS_KICK, ACCESS_GROUP_SUPERVISOR, "<tag> [tag] [tag] [tag]", true)
	oa_register_cmd("amx_cvar", "cmd_cvar", ACCESS_CVAR, _, "<cvar> [valor]", true)
	oa_register_cmd("amx_plugins", "cmd_plugins", ACCESS_ANY_ADM, _, "- Muestra todos los plugins", true)
	oa_register_cmd("amx_modules", "cmd_modules", ACCESS_PLUGIN, ACCESS_GROUP_SMOD, "- Muestra todos los modulos", true)
	oa_register_cmd("amx_map", "cmd_map", ACCESS_MAP, _, "<mapname>", true)
	oa_register_cmd("amx_cfg", "cmd_cfg", ACCESS_CFG, _, "<filename>", true)

	register_concmd("amx_help", "cmd_help")

	g_maxplayers = get_maxplayers()
}

public fw_oa_acc_changename(id, const name[])
{
	copy(g_name[id], 31, name)
}

public client_connect(id)
{
	get_user_hid(id, g_hid[id], 9)
}

/*** ADMIN CMDs ***********************************************************************************/
public cmd_kick(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED

	new arg[32], player
	read_argv(1, arg, 31)
	player = oa_cmd_target(id, arg, CMDTARGET_CHECKLEVEL | CMDTARGET_SELF)
	
	if(!player) return PLUGIN_HANDLED

	read_argv(2, arg, 31)
	server_cmd("kick #%d ^"%s^"", get_user_userid(player), arg)
	
	console_print(id, "[OA]- ^"%s^" ha sido expulsado", g_name[player])
	oa_show_activity(id, _, _, "g%s !yexpulsado", g_name[player])
	log_admin_to(id, player, "Kick", "- Razon: %s", arg)
	
	return PLUGIN_HANDLED
}

public cmd_slay(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED
	
	new arg[32], player
	read_argv(1, arg, 31)
	player = oa_cmd_target(id, arg, CMDTARGET_CHECKLEVEL | CMDTARGET_SELF | CMDTARGET_ONLY_ALIVE)
	
	if(!player) return PLUGIN_HANDLED
	
	user_kill(player)
	
	console_print(id, "[OA]- ^"%s^" ha sido asesinado", g_name[player])
	oa_show_activity(id, _, _, "!g%s !yasesinado", g_name[player])
	log_admin_to(id, player, "Slay")
	
	return PLUGIN_HANDLED
}

public cmd_slap(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED

	new arg[32], player
	read_argv(1, arg, 31)
	player = oa_cmd_target(id, arg, CMDTARGET_CHECKLEVEL | CMDTARGET_SELF | CMDTARGET_ONLY_ALIVE)
	
	if(!player) return PLUGIN_HANDLED

	new spower[5], damage
	read_argv(2, spower, 4)
	
	damage = str_to_num(spower)
	if(damage < 0) damage = 0
	
	user_slap(player, damage)

	console_print(id, "[OA]- ^"%s^" ha sido bofeteado", g_name[player])
	oa_show_activity(id, _, _, "!g%s !yha sido bofeteado con !g%d !yde daño", g_name[player], damage)
	log_admin_to(id, player, "Slap", "- Damage: %d", damage)
	
	return PLUGIN_HANDLED
}

contain_tag(name[], tags[4][32], tags_num)
{
	for(new a = 0; a < tags_num; ++a)
		if(contain(name, tags[a]) != -1)
			return a
	return -1
}

public cmd_leave(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED
	
	new argnum = read_argc()
	new ltags[4][32]
	new ltagsnum = 0
	
	for(new a = 1; a < 5; ++a)
	{
		if(a < argnum) read_argv(a, ltags[ltagsnum++], 31)
		else ltags[ltagsnum++][0] = 0
	}
	
	new ires, count
	for(new player = 1; player <= g_maxplayers; player++)
	{
		if(!is_user_connected(player) && !is_user_connecting(player))
			continue

		ires = contain_tag(g_name[player], ltags, ltagsnum)
		
		if(ires != -1)
		{
			console_print(id, "[OA]- Ignorando a ^"%s^" (contiene ^"%s^")", g_name[player], ltags[ires])
			continue
		}
		
		if(oa_admin_compare(id, player) != id)
		{
			console_print(id, "[OA]- Ignorando a ^"%s^" (inmune)", g_name[player])
			continue
		}
		
		console_print(id, "[OA]- Expulsando a ^"%s^"", g_name[player])
		
		server_cmd("kick #%d ^"Has sido expulsado porque el admin solo ha permitido jugar a un grupo especifico de clientes^"",
		get_user_userid(player))
		
		count++
	}
		
	console_print(id, "[OA]- %d clientes expulsados", count)
	
	oa_show_activity(id, _, _, "Leave: !g%s %s %s %s", ltags[0], ltags[1], ltags[2], ltags[3])
	log_admin(id, "todos expulsados exepto: (tag1 ^"%s^") (tag2 ^"%s^") (tag3 ^"%s^") (tag4 ^"%s^")", ltags[0], ltags[1], ltags[2], ltags[3])
	
	return PLUGIN_HANDLED
}

public cmd_cvar(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED
	
	new arg[32], arg2[64], pointer, access_protected
	read_argv(1, arg, 31)
	read_argv(2, arg2, 63)
	
	access_protected = oa_has_access(id, ACCESS_CVAR, ACCESS_GROUP_SMOD)

	if(equal(arg, "add") && access_protected)
	{
		if((pointer = get_cvar_pointer(arg2)))
		{
			new flags = get_pcvar_flags(pointer)
			
			if(!(flags & FCVAR_PROTECTED))
				set_pcvar_flags(pointer, flags | FCVAR_PROTECTED)
		}
		return PLUGIN_HANDLED
	}
	
	pointer = get_cvar_pointer(arg)
	if(!pointer)
	{
		console_print(id, "[OA]- Cvar desconocida: %s", arg)
		return PLUGIN_HANDLED
	}
	
	new is_protected = (get_pcvar_flags(pointer) & FCVAR_PROTECTED)
	if(is_protected  && !access_protected)
	{
		if(!(equali(arg,"sv_password") && oa_has_access(id, ACCESS_PASSWORD)))
		{
			console_print(id, "[OA]- No tienes acceso a esta cvar")
			return PLUGIN_HANDLED
		}
	}
	
	if(read_argc() < 3)
	{
		get_pcvar_string(pointer, arg2, 63)
		console_print(id, "[OA]- La cvar ^"%s^" vale ^"%s^"", arg, arg2)
		return PLUGIN_HANDLED
	}

	set_cvar_string(arg, arg2)
	
	console_print(id, "[OA]- Cvar ^"%s^" cambiada a ^"%s^"", arg, arg2)
	log_admin(id, "Set CVAR: (name ^"%s^") (value ^"%s^")", arg, arg2)
	
	if(is_protected || equali(arg, "rcon_password"))
	{
		for(new pl=1; pl <= g_maxplayers; pl++)
		{
			if(!is_user_connected(pl))
				continue

			if(oa_has_access(pl, ACCESS_CVAR, ACCESS_GROUP_SMOD))
				oa_chat_color(pl, id, "!g-ADMIN:  !t%s:  !yha establecido la cvar !g%s !ya !g^"%s^"", g_name[id], arg, arg2)
			else oa_chat_color(pl, id, "!g-ADMIN:  !t%s:  !yha establecido la cvar !g%s !ya !g^"***oculto***^"", g_name[id], arg)
		}
	}
	else oa_show_activity(id, 0, 0, "ha establecido la cvar !g%s !ya !g^"%s^"", arg, arg2)
	
	return PLUGIN_HANDLED
}

public cmd_plugins(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED
		
	if(!id)
	{
		server_cmd("amxx plugins")
		server_exec()
		return PLUGIN_HANDLED
	}

	new name[32], version[32], author[32], filename[32], status[32]
	new lName[32], lVersion[32], lAuthor[32], lFile[32], lStatus[32]

	format(lName, 31, "nombre")
	format(lVersion, 31, "version")
	format(lAuthor, 31, "autor")
	format(lFile, 31, "archivo")
	format(lStatus, 31, "estado")

	new temp[96], StartPLID, EndPLID, num, running

	num = get_pluginsnum()
	if(read_argc() > 1)
	{
		read_argv(1, temp, charsmax(temp))
		StartPLID = str_to_num(temp)-1
	}

	EndPLID = min(StartPLID + 10, num)
	
	console_print(id, "----- Plugins cargados actualmente -----")
	console_print(id, "%-18.17s %-11.10s %-17.16s %-16.15s %-9.8s", lName, lVersion, lAuthor, lFile, lStatus)

	new i = StartPLID
	while(i <EndPLID)
	{
		get_plugin(i++, filename, 31, name, 31, version, 31, author, 31, status, 31)
		console_print(id, "%-18.17s %-11.10s %-17.16s %-16.15s %-9.8s", name, version, author, filename, status)
		
		if (status[0]=='d' || status[0]=='r')
			running++
	}
	console_print(id, "%d plugins, %d en ejecucion", EndPLID-StartPLID, running)
	console_print(id, "Entradas %d - %d de %d", StartPLID + 1,EndPLID, num)
	
	if(EndPLID < num) console_print(id, "Use 'amx_plugin %d' para ver mas plugins", EndPLID + 1)
	else console_print(id, "Escribe 'amx_plugin 1' para volver al principio")

	return PLUGIN_HANDLED
}

public cmd_modules(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED

	new name[32], version[32], author[32], status, sStatus[16]
	new lName[32], lVersion[32], lAuthor[32], lStatus[32];

	format(lName, 31, "nombre")
	format(lVersion, 31, "version")
	format(lAuthor, 31, "autor")
	format(lStatus, 31, "estado")

	new num = get_modulesnum()
	
	console_print(id, "Modulos cargados actualmente:")
	console_print(id, "%-23.22s %-11.10s %-20.19s %-11.10s", lName, lVersion, lAuthor, lStatus)
	
	for (new i = 0; i < num; i++)
	{
		get_module(i, name, 31, author, 31, version, 31, status)
		
		switch (status)
		{
			case module_loaded: copy(sStatus, 15, "running")
			default: 
			{
				copy(sStatus, 15, "bad load")
				copy(name, charsmax(name), "unknown")
				copy(author, charsmax(author), "unknown")
				copy(version, charsmax(version), "unknown")
			}
		}
		
		console_print(id, "%-23.22s %-11.10s %-20.19s %-11.10s", name, version, author, sStatus)
	}
	console_print(id, "%d modulos", num)

	return PLUGIN_HANDLED
}

public cmd_map(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED

	new arg[32]
	new arglen = read_argv(1, arg, 31)
	
	if(!is_map_valid(arg))
	{
		console_print(id, "[OA]- No se encontro ningun mapa con ese nombre o el mapa es invalido")
		return PLUGIN_HANDLED
	}
	
	oa_show_activity(id, _, _, "cambiando a !g%s", arg)
	log_admin(id, "changelevel ^"%s^"", arg)

	message_begin(MSG_ALL, SVC_FINALE)
	write_string("Comunidad OnlyArg^n^n OnlyArg.com")
	message_end()
		
	message_begin(MSG_ALL, SVC_INTERMISSION)
	message_end()

	set_task(2.0, "task_changemap", 0, arg, arglen+1)
	return PLUGIN_HANDLED
}
public task_changemap(map[]) server_cmd("changelevel %s", map)

public cmd_cfg(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 1))
		return PLUGIN_HANDLED
	
	new arg[128]
	read_argv(1, arg, 127)
	if(!file_exists(arg))
	{
		console_print(id, "[OA]- No se encontro el archivo ^"%s^"", arg)
		return PLUGIN_HANDLED
	}
	
	server_cmd("exec %s", arg)
	
	console_print(id, "[OA]- Executing file ^"%s^"", arg)
	
	oa_show_activity(id, _, _, "cambiando a !g%s", arg)
	log_admin(id, "execute cfg (file ^"%s^")", arg)

	return PLUGIN_HANDLED
}

public cmd_help(id)
{
	new MAX_CMD = id?15:50
	
	new arg1[5], start, total, i, count, valid, info[128], cmd[32], access, group
	
	start = read_argv(1, arg1, 4)?str_to_num(arg1):0
	total = cmd_count(id)
	if((start+MAX_CMD) > total) start = max(0, total-MAX_CMD)
	
	while(get_cmd(i++, cmd, 31, info, 127, access, group, id) && count < MAX_CMD)
	{
		if(!oa_has_access(id, access, group)) continue
	
		if(valid++ >= start)
		{
			count++
			console_print(id, "#%3d: %s %s", start+count, cmd, info)
		}
	}

	console_print(id, "------------------------------------------------------------------")
	console_print(id, "Comandos: %d..%d - Total: %d", start+1, start+count, total)
	if((start+count) < total)
		console_print(id, "Ecribe 'amx_help %d' para ver mas comandos", start+count)

	console_print(id, "------------------------------------------------------------------")
	
	return PLUGIN_HANDLED
}

/*** STOCKS *******************************************************************************/
stock cmd_count(id)
{
	new i, count, cmd[32], info[3], access, group
	while(get_cmd(i++, cmd, 31, info, 2, access, group, id))
	{
		if(oa_has_access(id, access, group))
			count++
	}
	
	return count
}

stock get_cmd(cid, command[], maxlen1, info[], maxlen2, &access, &group, id=1)
{
	new result = get_concmd(cid, command, maxlen1, access, info, maxlen2, -1, id)
	
	if(result)
	{
		if(info[0] && info[0] <= (ACCESS_GROUP_VIP+1))
		{
			group = info[0]-1
			copy(info, maxlen2, info[1])
		}
		else group = 0
	}
	else {
		access = 0
		group  = 0
	}
	
	return result
}
