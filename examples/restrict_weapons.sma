#include <amxmodx>
#include <fakemeta>
#include <cstrike>

#define OA_UTIL_INC
#define OA_OLD_MENU_INC
#define OA_ADM_INC
#include <onlyarg.inc>

#define PLUGIN	"OA: Retrict Weapons"
#define VERSION	"1.0"
#define AUTHOR	"Destro"
/**********************************************/

#define m_iMenu 205
#define cs_get_user_menu(%0)	get_pdata_int(%0, m_iMenu)

enum {
	MENU_BUY=4,
	MENU_BUYPistol,
	MENU_BUYRifle,
	MENU_BUYMachineGun,
	MENU_BUYShotgun,
	MENU_BUYSubMachineGun,
	MENU_BUYItem
}

enum {
	CSW_DEFUSER=33,
	CSW_NVGS,
	CSW_SHIELD,
	CSW_PRIMAMMO,
	CSW_SECAMMO
}

const TE_WEAPONS = (1<<CSW_ELITE)|(1<<CSW_GALIL)|(1<<CSW_AK47)|(1<<CSW_SG552)|(1<<CSW_G3SG1)|(1<<CSW_MAC10)
const CT_WEAPONS = (1<<CSW_FIVESEVEN)|(1<<CSW_FAMAS)|(1<<CSW_M4A1)|(1<<CSW_AUG)|(1<<CSW_SG550)|(1<<CSW_TMP)|(1<<CSW_SHIELD)

new const g_items_tt[][] = {
	{0, 0, 0, 0, 0, 0, CSW_PRIMAMMO, CSW_SECAMMO, 0},
	{0, CSW_GLOCK18, CSW_USP, CSW_P228, CSW_DEAGLE, CSW_ELITE, 0, 0, 0},
	{0, CSW_GALIL, CSW_AK47, CSW_SCOUT, CSW_SG552, CSW_AWP, CSW_G3SG1, 0, 0},
	{0, CSW_M249, 0, 0, 0, 0, 0, 0, 0},
	{0, CSW_M3, CSW_XM1014, 0, 0, 0, 0, 0, 0},
	{0, CSW_MAC10, CSW_MP5NAVY, CSW_UMP45, CSW_P90, 0, 0, 0, 0},
	{0, CSW_VEST, CSW_VESTHELM, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_NVGS, 0, 0}
}

new const g_items_ct[][] = {
	{0, 0, 0, 0, 0, 0, CSW_PRIMAMMO, CSW_SECAMMO, 0},
	{0, CSW_GLOCK18, CSW_USP, CSW_P228, CSW_DEAGLE, CSW_FIVESEVEN, 0, 0, 0},
	{0, CSW_FAMAS, CSW_SCOUT, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_AWP, 0, 0},
	{0, CSW_M249, 0, 0, 0, 0, 0, 0, 0},
	{0, CSW_M3, CSW_XM1014, 0, 0, 0, 0, 0, 0},
	{0, CSW_TMP, CSW_MP5NAVY, CSW_UMP45, CSW_P90, 0, 0, 0, 0},
	{0, CSW_VEST, CSW_VESTHELM, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_NVGS, CSW_DEFUSER, CSW_SHIELD}
}


new const g_category[7][] = {
	"Pistolas",
	"Escopetas",
	"Metralletas",
	"Rifles - Assault & Sniper",
	"Ametralladoras",
	"Equipamiento",
	"Municion"
}

#define MAX_WEAPONS (CSW_SECAMMO+1)
#define MAX_ITEMS 34
new const g_items[MAX_ITEMS][2] = {
	/* Pistolas */
	{CSW_GLOCK18, 0}, {CSW_USP, -1}, {CSW_P228, -1}, {CSW_DEAGLE, -1}, {CSW_ELITE, -1}, {CSW_FIVESEVEN, -1},
	/* Escopetas */
	{CSW_XM1014, 1}, {CSW_M3, -1},
	/* Metralletas */
	{CSW_MAC10, 2}, {CSW_TMP, -1}, {CSW_MP5NAVY, -1}, {CSW_UMP45, -1}, {CSW_P90, -1},
	/* Rifles - Assault & Sniper */
	{CSW_FAMAS, 3}, {CSW_GALIL, -1}, {CSW_AUG, -1}, {CSW_SG552, -1}, {CSW_M4A1, -1}, {CSW_AK47, -1}, {CSW_SCOUT, -1}, {CSW_SG550, -1}, {CSW_G3SG1, -1}, {CSW_AWP, -1},
	/* Ametralladoras */
	{CSW_M249, 4},
	/* Equipamiento */
	{CSW_HEGRENADE, 5}, {CSW_SMOKEGRENADE, -1}, {CSW_FLASHBANG, -1}, {CSW_VEST, -1}, {CSW_VESTHELM, -1}, {CSW_DEFUSER, -1}, {CSW_NVGS, -1}, {CSW_SHIELD, -1},
	/* Municion */
	{CSW_PRIMAMMO, 6}, {CSW_SECAMMO, -1}
}

new const g_items_names[][] = { 
	"",
	"P228 Compact",		// CSW_P228
	"",
	"Schmidt Scout",	// CSW_SCOUT
	"HE Grenade",		// CSW_HEGRENADE
	"XM1014 M4",		// CSW_XM1014
	"",			// CSW_C4
	"Ingram MAC-10",	// CSW_MAC10
	"Steyr AUG A1",		// CSW_AUG
	"Smoke Grenade",	// CSW_SMOKEGRENADE
	"Dual Elite Berettas",	// CSW_ELITE
	"Five-Seven",		// CSW_FIVESEVEN
	"UMP 45",		// CSW_UMP45
	"SG-550 Auto-Sniper",	// CSW_SG550
	"IMI Galil",		// CSW_GALIL
	"Famas",		// CSW_FAMAS
	"USP .45",		// CSW_USP
	"Glock 18C",		// CSW_GLOCK18
	"AWP Magnum Sniper",	// CSW_AWP
	"MP5 Navy",		// CSW_MP5NAVY
	"M249 Machinegun",	// CSW_M249
	"M3 Super 90",		// CSW_M3
	"M4A1 Carbine",		// CSW_M4A1
	"Schmidt TMP",		// CSW_TMP
	"G3SG1 Auto-Sniper",	// CSW_G3SG1
	"Flashbang",		// CSW_FLASHBANG
	"Desert Deagle",	// CSW_DEAGLE
	"SG-552 Commando",	// CSW_SG552
	"AK-47",		// CSW_AK47
	"",			// CSW_KNIFE
	"ES P90",		// CSW_P90
	"Kevlar",		// CSW_VEST
	"Kevlar+Helmet",	// CSW_VESTHELM
	"Defusal Kit",		// CSW_DEFUSER
	"NightVision",		// CSW_NVGS
	"Tactical Shield",	// CSW_SHIELD
	"Prim. Ammo",		// CSW_PRIMAMMO
	"Sec. Ammo"		// CSW_SECAMMO
}

new g_retrict[MAX_WEAPONS]
new admin_item

public plugin_init()
{
	oa_register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("menuselect", "clcmd_menuselect") 
	
	admin_item = oa_admin_add_item("Restringir arma", ACCESS_CVAR, ACCESS_GROUP_SMOD)
	
	load_retrict()
	
	oldmenu_register()
}

public plugin_end()
{
	save_retrict()
}

stock can_buy_item(id, weapon)
{
	if(g_retrict[weapon])
	{
		client_print(id, print_center, "Arma restringida para su compra")
		return true
	}
	
	return false
}

// Menu
public fw_oa_admin_itemselect(id, itemid)
{
	if(itemid == admin_item)
		show_menu_weapons(id)
}

stock show_menu_weapons(id, page=1)
{
	new maxpages, start, end, count
	oldmenu_calculate_pages(maxpages, start, end, page, MAX_ITEMS)
	oldmenu_create("menu_weapons", "\yRestringir armas: \r%d/%d", page, maxpages)
	
	for(new item=start; item < end; item++)
	{
		count++
		
		if(g_items[item][1] != -1)
		{
			oldmenu_additem(-1, 0, "^n\r- \y%s", g_category[g_items[item][1]])
		}
		
		oldmenu_additem(count, item, "\r%d. \w%s%s", count, g_items_names[g_items[item][0]],
		(g_retrict[g_items[item][0]])?" \r[bloqueado]":"")
	}
	
	oldmenu_pagination(page, maxpages)
	oldmenu_display(id, page)
}

public menu_weapons(id, itemnum, value, page)
{
	if(!itemnum)
		return
	
	if(itemnum > 7)
	{
		show_menu_weapons(id, page+value)
		return
	}
	
	new w = g_items[value][0]
	g_retrict[w] = !(g_retrict[w])
	
	log_admin(id, "RetricWeapon: Weapon:[%s] - Retric:[%d]", g_retrict[w], g_items_names[g_items[w][0]])
	
	show_menu_weapons(id, page)
}

// save/load
stock load_retrict()
{
	new data[MAX_WEAPONS+1]
	get_vaultdata("retrict_wpn", data, charsmax(data))
	
	for(new w; w < MAX_WEAPONS; w++)
	{
		if(data[w] == '1') g_retrict[w] = 1
	}
}

stock save_retrict()
{
	new data[MAX_WEAPONS+1]
	
	for(new w; w < MAX_WEAPONS; w++)
	{
		data[w] = g_retrict[w]?'1':'0'
	}
	
	set_vaultdata("retrict_wpn", data)
}

/************************************************************************************************
# client_buy Forward ############################################################################
************************************************************************************************/
public client_command(id)
{
	if(is_user_alive(id))
	{
		new cmd[13]
		if(read_argv(0, cmd, charsmax(cmd)) < 12 )
			return check_buy_cmd(id, cmd)
	}

	return PLUGIN_CONTINUE
}

public CS_InternalCommand(id, const cmd[])
{
	if(is_user_alive(id) && strlen(cmd) < 12 )
		return check_buy_cmd(id, cmd)

	return PLUGIN_CONTINUE
}

stock check_buy_cmd(id , const cmd[])
{
	new item = get_aliasid(cmd)
	if(item)
	{
		if((TE_WEAPONS & (1<<item)) && cs_get_user_team(id) != CS_TEAM_T)
			return PLUGIN_CONTINUE
		else if((CT_WEAPONS & (1<<item)) && cs_get_user_team(id) != CS_TEAM_CT)
			return PLUGIN_CONTINUE

		return can_buy_item(id, item)
	}

	return PLUGIN_CONTINUE
}

public clcmd_menuselect(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	new arg[3]
	if(read_argv(1, arg, 2) == 1)
	{
		new slot = arg[0] - '0'
		if(1 <= slot <= 8)
		{
			new menu = cs_get_user_menu(id)
			if(MENU_BUY <= menu <= MENU_BUYItem)
			{
				new item
				switch(cs_get_user_team(id))
				{
					case CS_TEAM_T:item = g_items_tt[menu-4][slot]
					case CS_TEAM_CT:item = g_items_ct[menu-4][slot]
				}
				if(item) return can_buy_item(id, item)
			}
		}
	}
	return PLUGIN_CONTINUE
}

stock get_aliasid(const alias[])
{
	static Trie:aliasids = Invalid_Trie
	if(aliasids == Invalid_Trie)
	{
		aliasids = TrieCreate()
		TrieSetCell(aliasids, "p228",		CSW_P228)
		TrieSetCell(aliasids, "scout",		CSW_SCOUT)
		TrieSetCell(aliasids, "hegren",		CSW_HEGRENADE)
		TrieSetCell(aliasids, "xm1014",		CSW_XM1014)
		TrieSetCell(aliasids, "mac10",		CSW_MAC10)
		TrieSetCell(aliasids, "aug",		CSW_AUG)
		TrieSetCell(aliasids, "sgren",		CSW_SMOKEGRENADE)
		TrieSetCell(aliasids, "elites",		CSW_ELITE)
		TrieSetCell(aliasids, "fiveseven",	CSW_FIVESEVEN)
		TrieSetCell(aliasids, "ump45",		CSW_UMP45)
		TrieSetCell(aliasids, "sg550",		CSW_SG550)
		TrieSetCell(aliasids, "galil",		CSW_GALIL)
		TrieSetCell(aliasids, "famas",		CSW_FAMAS)
		TrieSetCell(aliasids, "usp",		CSW_USP)
		TrieSetCell(aliasids, "glock",		CSW_GLOCK18)
		TrieSetCell(aliasids, "awp",		CSW_AWP)
		TrieSetCell(aliasids, "magnum",		CSW_AWP)
		TrieSetCell(aliasids, "mp5",		CSW_MP5NAVY)
		TrieSetCell(aliasids, "m249",		CSW_M249)
		TrieSetCell(aliasids, "m3",		CSW_M3)
		TrieSetCell(aliasids, "m4a1",		CSW_M4A1)
		TrieSetCell(aliasids, "tmp",		CSW_TMP)
		TrieSetCell(aliasids, "g3sg1",		CSW_G3SG1)
		TrieSetCell(aliasids, "flash",		CSW_FLASHBANG)
		TrieSetCell(aliasids, "deagle",		CSW_DEAGLE)
		TrieSetCell(aliasids, "sg552",		CSW_SG552)
		TrieSetCell(aliasids, "ak47",		CSW_AK47)
		TrieSetCell(aliasids, "p90",		CSW_P90)

		TrieSetCell(aliasids, "vest",		CSW_VEST)
		TrieSetCell(aliasids, "vesthelm",	CSW_VESTHELM)

		TrieSetCell(aliasids, "defuser",	CSW_DEFUSER)
		TrieSetCell(aliasids, "nvgs",		CSW_NVGS)
		TrieSetCell(aliasids, "shield",		CSW_SHIELD)
		TrieSetCell(aliasids, "buyammo1",	CSW_PRIMAMMO)
		TrieSetCell(aliasids, "primammo",	CSW_PRIMAMMO)
		TrieSetCell(aliasids, "buyammo2",	CSW_SECAMMO)
		TrieSetCell(aliasids, "secammo",	CSW_SECAMMO)
	}

	new fix_alias[10]
	copy(fix_alias, 9, alias)
	strtolower(fix_alias)
	
	new wid
	if(TrieGetCell(aliasids, fix_alias, wid))
		return wid

	return 0
}
