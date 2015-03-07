#if defined _oldmenu_included
  #endinput
#endif
#define _oldmenu_included

#if !defined _fakemeta_included
	#include <fakemeta>
#endif

#define MAX_MENU_LEN 1024
#define MAX_ITEM_LEN 256

stock const oldmenuhandler[] = "oldmenu_handler"

enum _:_OLDMENU_DATA
{
	_MENU[MAX_MENU_LEN+1],
	_FUNCID,
	_KEYS,
	_LEN,
	_ITEMS[10],
}

stock g_oldmenu[_OLDMENU_DATA]
stock g_olmenu_player[33][12]

stock oldmenu_register()
{
	register_menucmd(register_menuid(oldmenuhandler, 0), 1023, oldmenuhandler)
}

stock oldmenu_create(const handler[], const title[], any:...)
{
	if(title[0])
	{
		if(numargs() == 2)
			g_oldmenu[_LEN] = formatex(g_oldmenu[_MENU], MAX_MENU_LEN, "%s^n^n", title)
		else {
			vformat(g_oldmenu[_MENU], MAX_MENU_LEN, title, 3)
			g_oldmenu[_LEN] = add(g_oldmenu[_MENU], MAX_MENU_LEN, "^n^n")
		}
	}
	else g_oldmenu[_LEN] = 0
	
	g_oldmenu[_KEYS] = 0
	g_oldmenu[_FUNCID] = get_func_id(handler)
}

stock oldmenu_additem(itemnum, value, const item[], any:...)
{
	new len = min(MAX_ITEM_LEN, MAX_MENU_LEN-g_oldmenu[_LEN])

	if(numargs() == 3)
		g_oldmenu[_LEN] += formatex(g_oldmenu[_MENU][g_oldmenu[_LEN]], len, "%s^n", item)
	else {
		vformat(g_oldmenu[_MENU][g_oldmenu[_LEN]], len, item, 4)
		g_oldmenu[_LEN] = add(g_oldmenu[_MENU], MAX_MENU_LEN, "^n")
	}
	
	if(itemnum != -1)
	{
		if(itemnum > 9 || itemnum <= 0) itemnum = 9
		else itemnum--
		
		g_oldmenu[_ITEMS][itemnum] = value
		g_oldmenu[_KEYS] |= (1<<itemnum)
	}
}

stock oldmenu_display(id, page=1, display_time=-1)
{
	if(!id)
	{
		new players[32], count, k
		get_players(players, count, "ch")
		
		for(new i = 0; i < count; i++)
		{
			for(k=0; k <= 9; k++) g_olmenu_player[players[i]][k] = g_oldmenu[_ITEMS][k]
			g_olmenu_player[players[i]][10] = g_oldmenu[_FUNCID]
			g_olmenu_player[players[i]][11] = page
			
			fix_pdata_menu(id)
		}
	}
	else {
		for(new k=0; k <= 9; k++) g_olmenu_player[id][k] = g_oldmenu[_ITEMS][k]
		g_olmenu_player[id][10] = g_oldmenu[_FUNCID]
		g_olmenu_player[id][11] = page
		
		fix_pdata_menu(id)
	}
	
	show_menu(id, g_oldmenu[_KEYS], g_oldmenu[_MENU], display_time, oldmenuhandler)
}

stock fix_pdata_menu(id)
{
	// m_iMenu: 205 -- OFFSET_LINUX: 5
	if(pev_valid(id) == 2) set_pdata_int(id, 205, 0, 5)
	
}

public oldmenu_handler(id, key)
{
	new itemnum = (key+1)
	if(itemnum > 9) itemnum = 0

	callfunc_begin_i(g_olmenu_player[id][10], -1)
	callfunc_push_int(id)
	callfunc_push_int(itemnum)
	callfunc_push_int(g_olmenu_player[id][key])
	callfunc_push_int(g_olmenu_player[id][11])
	callfunc_end
	
	return PLUGIN_HANDLED
}

stock oldmenu_maxpages(maxitems, perpage=7)
{
	new p = 1, i = perpage
	while(maxitems > i)
	{
		i += perpage
		p++
	}
	return p
}

stock oldmenu_calculate_pages(&maxpages, &start, &end, &page, const maxitems, const perpage=7, const start_offset=0)
{
	maxpages = oldmenu_maxpages(maxitems, perpage)
	
	if(page < 1) page=1
	else if(page > maxpages) page=maxpages
	
	start = ((page-1)*perpage)+start_offset
	end = min(start+perpage, maxitems)
}

stock oldmenu_pagination(page, maxpages, addspace=true)
{
	if(maxpages != 1)
	{
		if(page > 1) oldmenu_additem(8, -1, "^n\r8. \wAtras")
		else oldmenu_additem(-1, 0, "^n\d8. Atras")
		if(page < maxpages) oldmenu_additem(9, 1, "\r9. \wSiguiente")
		else oldmenu_additem(-1, 0, "\d9. Siguiente")
	}
	else if(addspace) oldmenu_additem(-1, 0, "^n")
	
	oldmenu_additem(0, 0, "\r0. \wSalir")
}

stock oldmenu_pagination_y(page, maxpages, addspace=true)
{
	if(maxpages != 1)
	{
		if(page > 1) oldmenu_additem(8, -1, "^n\r8. \yAtras")
		else oldmenu_additem(-1, 0, "^n\d8. Atras")
		if(page < maxpages) oldmenu_additem(9, 1, "\r9. \ySiguiente")
		else oldmenu_additem(-1, 0, "\d9. Siguiente")
	}
	else if(addspace) oldmenu_additem(-1, 0, "^n")
	
	oldmenu_additem(0, 0, "\r0. \ySalir")
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/