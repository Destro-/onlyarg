#include <amxmodx>
#include <engine>

#define OA_UTIL_INC
#define OA_OLD_MENU_INC
#define OA_ADM_INC
#define OA_ACC_INC
#include <onlyarg>

#define PLUGIN	"OA: Map Spawns Editor"
#define VERSION	"1.0"
#define AUTHOR	"iG_os&Destro"
/**********************************************/

enum (+= 100)
{
	TASK_RESET_ENT=1111,
	TASK_CHECKDEATH,
	TASK_CHECK
}

#define TIME_CHECK		0.5
#define SAFEp2p			85	// point to point safe distance
#define SAFEp2w			40	// point to wall safe distance
	
#define SPAWN_PRESENT_OFFSET	10
#define SPAWN_ABOVE_OFFSET	115

#define _TT			0
#define _CT			1

new const beam_colors[4][3]	= { {255,0,0}, {0,255,0}, {200,200,0}, {0,0,255} } 
new const entity_classname[] 	= "Map_Spawns_Editor"
new const model_player_t[]	= "models/player/leet/leet.mdl"
new const model_player_ct[]	= "models/player/gign/gign.mdl"
new const sprite_laser[]	= "sprites/laserbeam.spr"

new g_modify_spawns		= false
new g_above_player 		= false
new g_check_death 		= false
new g_load_successed 		= false
new g_in_precache 		= true
new g_check_distance 		= true
new g_offset 			= SPAWN_PRESENT_OFFSET

new g_spawn_file[256], g_die_file[256]
new g_editing, g_spawns[2], g_edits[2]
new g_laserSpr

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_in_precache = false

	spawns_count()
	
	new value[16]
	formatex(value, 15, "T(%d) CT(%d)", g_spawns[_TT], g_spawns[_CT])
	register_cvar("map_spawns", value, FCVAR_SERVER)

	register_event("TextMsg", "event_restartgame", "a", "2&#Game_C","2&#Game_w")
	register_event("DeathMsg", "event_death", "a")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")

	oa_register_cmd("amx_spawn_editor", "clcmd_editor", ACCESS_CVAR, ACCESS_GROUP_SUPERVISOR, "- Editar los spawn point del mapa")
	
	oldmenu_register()
}

public clcmd_editor(id, level, cid)
{
	if(!oa_cmd_access(id, cid, 0))
		return PLUGIN_HANDLED

	if(!g_editing)
	{
		g_editing = id
		clear_alledit(0)
		load_spawns()
		spawns_to_edit()
		
		show_menu_spawn(id)
	}
	else if(g_editing == id)
		show_menu_spawn(id)
	else {
		new name[32]
		get_user_name(g_editing, name, 31)
		
		console_print(id, "[OA]- El editor esta siendo utilizado por ^"%s^".", name)
	}
	
	return PLUGIN_HANDLED
}

show_menu_closed(id)
{
	oldmenu_create("menu_closed", "\yMap Spawns Editor vOA:")
	
	oldmenu_additem(1, 0, "\r1. \wGuardar Cambios")
	oldmenu_additem(2, 0, "\r2. \wGuardar y reiniciar map")
	oldmenu_additem(0, 0, "^n\r0. \wCerrar sin Guardar")
	
	oldmenu_display(id)
}

public menu_closed(id, itemnum/*, value, page*/)
{
	if(itemnum)
	{
		save_spawnsfile()
		if(itemnum == 2) server_cmd("restart")
		
		oa_chat_color(id, _, "!g-MapSpawnsEditor: !ySpawns Points guardados correctamente")
	}

	g_editing = 0
	clear_alledit(0)
	remove_task(id+TASK_CHECK)
}

show_menu_spawn(id, page=1)
{
	oldmenu_create("menu_spawn", "\yMap Spawns Editor vOA: \r%d/2", page)
	
	oldmenu_additem(-1, 0, "\r-Spawns Originales: \d( TT=%d + CT=%d )^n\r-Spawns Editados:   \d( TT=%d + CT=%d )^n",
	g_spawns[_TT], g_spawns[_CT], g_edits[_TT],g_edits[_CT])
		

	if(page == 1)
	{
		oldmenu_additem(-1, 0, "\r-Nuevo Spawn - Posicion: \y(%s)\r:", g_above_player?"Arriba":"Actual")
		oldmenu_additem(1, 1, "\r1. \wTT")
		oldmenu_additem(2, 2, "\r2. \wCT")
		
		oldmenu_additem(-1, 0, "^n\r-Spawn Apuntado:")
		oldmenu_additem(3, 3, "\r3. \wGirar a la \yIzquierda")
		oldmenu_additem(4, 4, "\r4. \wGirar a la \yDerecha")
		oldmenu_additem(5, 5, "\r5. \wTraer")
		oldmenu_additem(6, 6, "\r6. \wBorrar")
	}
	else if(page == 2)
	{
		oldmenu_additem(-1, 0, "\r-Configuracion:")
		oldmenu_additem(1, 7, "\r1. \wPosicion \y[%s]", g_above_player?"Arriba":"Actual")
		oldmenu_additem(2, 8, "\r2. \wRango seguro \y[%s]", g_check_distance?"SI":"NO")
		
		oldmenu_additem(-1, 0, "^n\r-Borrar:")
		oldmenu_additem(3, 9, "\r3. \wSpawns \yTT")
		oldmenu_additem(4, 10, "\r4. \wSpawns \yCT")
		oldmenu_additem(5, 11, "\r5. \wTodos los spawns")
		oldmenu_additem(6, 12, "\r6. \wArchivo de spawns")
	}

	oldmenu_additem(8, 0, "^n\r8. \wMas Opciones")
	oldmenu_additem(9, 0, "\r9. \wCerrar Editor")
	oldmenu_additem(0, 0, "\r0. \wOcultar Menu")
	oldmenu_display(id, page)
	
	remove_task(id+TASK_CHECK)
	set_task(TIME_CHECK, "task_check", id+TASK_CHECK, .flags="b")
}

public menu_spawn(id, itemnum, value, page)
{
	if(!itemnum || g_editing != id)
		return
	
	if(itemnum > 7)
	{
		if(itemnum == 9)
		{
			if(g_modify_spawns)
				show_menu_closed(id)
			else	menu_closed(id, 0)
		}
		else show_menu_spawn(id, (page==1)?2:1)
		return
	}
	
	switch(value)
	{
		case 1,2:
		{
			if(g_check_distance && !SafeRangeCheck(id, g_offset))
				client_print(id, print_center, "Error: La posicion no es segura para el spawn")
			else if(create_edit_ent(id, value, g_offset))
			{
				g_edits[value-1]++
				g_modify_spawns = true
				oa_chat_color(id, 33+value, "!g-MapSpawnsEditor: !ySpawn !t%s !yagregado", (value==1)?"TT":"CT")
			}
		}
		case 3..6:
		{
			new ent = get_edit_point_byaim(id)
			if(ent)
			{
				if(value < 5)
					entity_turn_angle(ent, (value==3)?10:-10)
				else if(value == 5)
				{
					if(g_check_distance && !SafeRangeCheck(id, g_offset))
						client_print(id, print_center, "Error: La posicion no es segura para el spawn")
					else {
						new Float:origin[3]
						
						entity_get_vector(id, EV_VEC_origin, origin)
						origin[2] += g_offset
						entity_set_origin(ent, origin)
					}
				}
				else if(value == 6)
				{
					new team = entity_get_int(ent, EV_INT_iuser2)
					g_edits[team-1]--
				
					oa_chat_color(id, 33+team, "!g-MapSpawnsEditor: !ySpawn !t%s !yremovido", (team==1)?"TT":"CT")
					remove_entity(ent)
				}
				g_modify_spawns = true
			}
			else client_print(id, print_center, "No estas apuntando a un spawn valido")
		}
		case 7:
		{
			g_above_player = !(g_above_player)
			g_offset = g_above_player?SPAWN_ABOVE_OFFSET:SPAWN_PRESENT_OFFSET
		}
		case 8:
		{
			g_check_distance = !(g_check_distance)
		}
		case 9:
		{
			clear_alledit(1)
			oa_chat_color(id, color_red, "!g-MapSpawnsEditor: !yTodos los spawns !tTT fueron removidos")
			g_modify_spawns = true
		}
		case 10:
		{
			clear_alledit(2)
			oa_chat_color(id, color_blue, "!g-MapSpawnsEditor: !yTodos los spawns !tTT fueron removidos")
			g_modify_spawns = true
		}
		case 11:
		{
			clear_alledit(0)
			oa_chat_color(id, _, "!g-MapSpawnsEditor: !yTodos los spawns fueron removidos")
			g_modify_spawns = true
		}
		case 12:
		{ 
			if(file_exists(g_spawn_file))
			{
				delete_file(g_spawn_file)
				oa_chat_color(id, _, "!g-MapSpawnsEditor: !yEl archivo !t%s !yha sido eliminado", g_spawn_file)
			}
			else oa_chat_color(id, _, "!g-MapSpawnsEditor: !yEl archivo no existe (no hay spawns personalizados)")
		}
	}
	
	show_menu_spawn(id, page)
}

public plugin_precache()
{
	new configdir[128]
	get_configsdir(configdir, 127)
	
	new spawndir[256]
	formatex(spawndir, 255, "%s/spawns", configdir)
	
	if(!dir_exists(spawndir))
	{
		if(mkdir(spawndir))
			set_fail_state("Error al crear la carpeta 'amxmodx/configs/spawns/'")
	}

	precache_model(model_player_t)
	precache_model(model_player_ct)
	g_laserSpr = precache_model(sprite_laser)

	new map[32]
	get_mapname(map, 31)
	
	formatex(g_spawn_file, 255, "%s/%s_spawns.cfg", spawndir, map)
	formatex(g_die_file, 255, "%s/%s_spawns_die.cfg", spawndir, map)

	g_load_successed = load_spawns()
}

stock load_spawns()
{
	if(!file_exists(g_spawn_file))
		return 0
		
	new buff[128], team[2], str_origin[3][8], str_angles[3][8]
	new Float:origin[3], Float:angles[3], ent, i

	new file = fopen(g_spawn_file, "rt")
	if(!file) return 0

	while(!feof(file))
	{
		fgets(file, buff, 127)
		trim(buff)
		
		if(buff[0] != 'T' && buff[0] != 'C')
			continue

		parse(buff, team, 1,
		str_origin[0], 7, str_origin[1], 7, str_origin[2], 7,
		str_angles[0], 7, str_angles[1], 7, str_angles[2], 7)
			
		for(i=0; i < 3; i++)
		{
			origin[i] = str_to_float(str_origin[i])
			angles[i] = str_to_float(str_angles[i])
		}
		
		if(team[0] == 'T')
		{
			if(g_in_precache) ent = create_entity("info_player_deathmatch")
			else ent = find_ent_by_class(ent, "info_player_deathmatch")
		}
		else {
			if(g_in_precache) ent = create_entity("info_player_start")
			else ent = find_ent_by_class(ent, "info_player_start")
		}
		
		if(ent)
		{
			entity_set_int(ent, EV_INT_iuser1, 1)
			entity_set_origin(ent, origin)
			entity_set_vector(ent, EV_VEC_angles, angles)
		}
	}
	fclose(file)
	
	return 1
}

public pfn_keyvalue(ent)
{
	if(!g_load_successed || !g_in_precache)
		return
		
	new classname[32], null[2]
	copy_keyvalue(classname, 31, null, 1, null, 1)

	if(equal(classname, "info_player_deathmatch") || equal(classname, "info_player_start"))
	{
		if(is_valid_ent(ent) && entity_get_int(ent, EV_INT_iuser1) != 1)
			remove_entity(ent)
	}
}

public event_restartgame()
{
	if(g_editing && file_exists(g_die_file))
		delete_file(g_die_file)

	g_check_death = true

	if(g_editing)
	{
		clear_alledit(0)
		load_spawns()
		spawns_to_edit()
	}
}

public event_death()
{
	if(!g_check_death)
		return

	new string[11]
	read_data(4, string, 10)
	
	if(string[0] != 'w' || string[3] != 'l' || string[9] != 'n')
		return
		
	new id, team
	id = read_data(2)
	
	if(g_editing)
	{
		new ent[1]
		find_sphere_class(id, entity_classname, 30.0, ent, 1)
		
		if(ent[0])
		{
			team = entity_get_int(ent[0],EV_INT_iuser2)
			
			if(team == 1) g_edits[_TT]--
			else g_edits[_CT]--

			oa_chat_color(g_editing, (team==1)?color_red:color_blue,
			"!g-MapSpanwsEditor: !ySe Auto-Elimino un punto de spawn !t%s !yincorrecto.", (team==1)?"TT":"CT")
			
			remove_entity(ent[0])
		}
	}
	else
	{
		team = get_user_team(id)
		if(team==1) point_save(g_die_file, 1, id)
		else if(team==2) point_save(g_die_file, 2, id)
	}
}

public event_newround()
{
	remove_task(TASK_CHECKDEATH)
	set_task(3.0, "task_checkdeath", TASK_CHECKDEATH)
}

public task_checkdeath()
	g_check_death = false



stock create_edit_ent(id, team, offset)
{
	new Float:origin[3],Float:angles[3]
	entity_get_vector(id, EV_VEC_origin, origin)
	entity_get_vector(id, EV_VEC_angles, angles)
	origin[2] += float(offset)

	new ent = create_entity("info_target")
	if(ent)
	{
		entity_set_string(ent, EV_SZ_classname, entity_classname)
		entity_set_model(ent,(team==1)?model_player_t:model_player_ct)
		entity_set_origin(ent, origin)
		entity_set_vector(ent, EV_VEC_angles, angles)
		entity_set_int(ent, EV_INT_sequence, 4)
		entity_set_int(ent, EV_INT_iuser2, team)
		
		return true
	}
	return false
}

stock clear_alledit(type)
{
	new ent
	switch(type)
	{
		case 0:
		{
			while((ent = find_ent_by_class(ent, entity_classname)))
				remove_entity(ent)
				
			g_edits[_TT] = 0
			g_edits[_CT] = 0
		}
		case 1:
		{
			while((ent = find_ent_by_class(ent, entity_classname)))
				if(entity_get_int(ent,EV_INT_iuser2) == 1)
					remove_entity(ent)
			g_edits[_TT] = 0
		}
		case 2:
		{
			while ((ent = find_ent_by_class(ent, entity_classname)))
				if(entity_get_int(ent, EV_INT_iuser2) == 2)
					remove_entity(ent)
			g_edits[_CT] = 0
		}
	}
}

stock spawns_to_edit()
{
	new ent
	g_edits[_TT] = 0
	while((ent = find_ent_by_class(ent, "info_player_deathmatch")))
	{
		create_edit_ent(ent, 1, 0)
		g_edits[_TT]++
	}
	
	ent = 0
	g_edits[_CT] = 0
	while((ent = find_ent_by_class(ent, "info_player_start")))
	{
		create_edit_ent(ent, 2, 0)
		g_edits[_CT]++
	}
}

stock spawns_count()
{
	new ent
	g_spawns[_TT] = 0
	while((ent = find_ent_by_class(ent, "info_player_deathmatch")))
		g_spawns[_TT]++

	ent = 0
	g_spawns[_CT] = 0
	while((ent = find_ent_by_class(ent, "info_player_start")))
		g_spawns[_CT]++
}

public task_check(task)
{
	get_edit_point_byaim(task-TASK_CHECK)
}

public reset_entity_stats(task)
{
	new ent = task - TASK_RESET_ENT
	if(is_valid_ent(ent))
	{
		entity_set_float(ent, EV_FL_animtime, 0.0)
		entity_set_float(ent, EV_FL_framerate, 0.0)
		entity_set_int(ent, EV_INT_sequence, 4)
	}
}

stock entity_turn_angle(ent, turn)
{
	if(!is_valid_ent(ent))
		return
		
	new Float:angles[3]
	entity_get_vector(ent, EV_VEC_angles, angles)
	
	angles[1] += turn
	if(angles[1] >= 360) angles[1] -= 360
	if(angles[1] < 0) angles[1] += 360
	
	entity_set_vector(ent, EV_VEC_angles, angles)
}

stock SafeRangeCheck(id, offset)
{
	new safepostion = true
	new Float:origin[3], Float:angles[3], Float:inFrontPoint[3], Float:HitPoint[3]
	
	entity_get_vector(id, EV_VEC_origin, origin)
	entity_get_vector(id, EV_VEC_angles, angles)
	
	origin[2] += offset

	for(angles[1] = 0.0; angles[1] < 360.0; angles[1] += 10.0)
	{
		Vector_By_Angle(origin, angles, (SAFEp2w * 2.0), 1, inFrontPoint)


		trace_line(-1, origin, inFrontPoint, HitPoint)
		new distance = floatround(vector_distance(origin, HitPoint))

		if(distance < SAFEp2w)
		{
			Make_TE_BEAMPOINTS(id, 0, HitPoint, 2, 255)
			safepostion = false
		}
		else if(distance < (SAFEp2w * 1.5))
			Make_TE_BEAMPOINTS(id, 2, HitPoint, 2, 255)
	}

	new entlist[10], Float:vDistance, Float:entity_origin[3]
	
	find_sphere_class(0, entity_classname, (SAFEp2p * 1.5), entlist, 9, origin)
	for(new i; i < 10 && entlist[i]; i++)
	{
		entity_get_vector(entlist[i], EV_VEC_origin, entity_origin)
		
		vDistance = vector_distance(origin, entity_origin)
		if(vDistance < SAFEp2p)
		{
			Make_TE_BEAMPOINTS(id, 0, entity_origin, 5, 255)
			
			entity_set_int(entlist[i], EV_INT_sequence, 64)
			safepostion = false

			remove_task(entlist[i]+TASK_RESET_ENT)
			set_task(TIME_CHECK+0.1, "reset_entity_stats", entlist[i]+TASK_RESET_ENT)
		}
		else Make_TE_BEAMPOINTS(id, 1, entity_origin, 5, 255)
	}

	return safepostion
}

stock get_edit_point_byaim(id)
{
	new ent[1], team
	new Float:origin[3], Float:angles[3], Float:vdist[3]
	
	entity_get_vector(id, EV_VEC_origin, origin)
	entity_get_vector(id, EV_VEC_v_angle, angles)
	
	origin[2] += 10.0

	for(new Float:dist; dist <= 600.0; dist += 20.0)
	{
		Vector_By_Angle(origin, angles, dist, 1, vdist)

		find_sphere_class(0, entity_classname, 20.0, ent, 1, vdist)
		if(ent[0])
		{
			entity_set_float(ent[0], EV_FL_animtime, 1.0)
			entity_set_float(ent[0], EV_FL_framerate, 1.0)
			entity_get_vector(ent[0], EV_VEC_origin, vdist)
			
			Make_TE_BEAMPOINTS(id, 0, vdist, 4, 255, 5)
			
			team = entity_get_int(ent[0], EV_INT_iuser2)
			client_print(id, print_center, "Spawn: %s - Entity: #%d", (team==1)?"TT":"CT", ent[0])
			
			if(task_exists(ent[0]+TASK_RESET_ENT)) 
				remove_task(ent[0]+TASK_RESET_ENT)
				
			set_task(TIME_CHECK+0.1, "reset_entity_stats", ent[0]+TASK_RESET_ENT)
			break
		}
	}

	return ent[0]
}

stock Vector_By_Angle(Float:fOrigin[3], Float:vAngles[3], Float:multiplier, FRU, Float:vecReturn[3])
{
	angle_vector(vAngles, FRU, vecReturn)
	vecReturn[0] = vecReturn[0] * multiplier + fOrigin[0]
	vecReturn[1] = vecReturn[1] * multiplier + fOrigin[1]
	vecReturn[2] = vecReturn[2] * multiplier + fOrigin[2]
}

// draw laserBeam
stock Make_TE_BEAMPOINTS(id, color, Float:vEnd[3], width, brightness, life=4)
{
	message_begin(MSG_ONE_UNRELIABLE ,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(TE_BEAMENTPOINT)
	write_short(id) 
	write_coord(floatround(vEnd[0])) // end position
	write_coord(floatround(vEnd[1]))
	write_coord(floatround(vEnd[2]))
	write_short(g_laserSpr) // sprite index
	write_byte(1) // starting frame
	write_byte(0) // frame rate in 0.1's
	write_byte(life) // life in 0.1's
	write_byte(width) // line width in 0.1's
	write_byte(0) // noise amplitude in 0.01's
	write_byte(beam_colors[color][0])
	write_byte(beam_colors[color][1])
	write_byte(beam_colors[color][2])
	write_byte(brightness) // brightness)
	write_byte(0) // scroll speed in 0.1's
	message_end()
}


stock save_spawnsfile()
{
	if(file_exists(g_spawn_file))
		delete_file(g_spawn_file)

	new map[32], line[128]
	get_mapname(map, 31)
	
	formatex(line, 127, "/* %s TT=%d,CT=%d */ Map Spawns Editor Format File (vOA)", map, g_edits[_TT], g_edits[_CT])
	
	write_file(g_spawn_file, line)

	new ent, team
	while((ent = find_ent_by_class(ent, entity_classname)))
	{
		team = entity_get_int(ent, EV_INT_iuser2)
		point_save(g_spawn_file, team, ent)
	}
}

stock point_save(file[], team, entity)
{
	new line[128]
	new origin[3], angles[3]
	new Float:fOrigin[3],Float:fAngles[3]

	entity_get_vector(entity, EV_VEC_origin, fOrigin)
	entity_get_vector(entity, EV_VEC_angles, fAngles)
	FVecIVec(fOrigin, origin)
	FVecIVec(fAngles, angles)
	
	if(angles[1] >= 360) angles[1] -= 360
	if(angles[1] < 0) angles[1] += 360

	formatex(line, 127, "%s %d %d %d %d %d %d", (team==1)?"TT":"CT", origin[0], origin[1], origin[2], 0, angles[1], 0)
	write_file(file, line)
}
