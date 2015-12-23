#include <amxmodx>
#include <fakemeta>
#include <onlyarg>

#define PLUGIN	"OA: Anti Scroll"
#define VERSION	"1.01"
#define AUTHOR	"Destro"
/**********************************************/

public plugin_init()
{
	oa_register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_CmdStart, "fw_CmdStart", 1)
}

public fw_CmdStart(id, pUC, seed)
{
	static buttons, Float:fGameTime, Float:origin[3],
	last_stand[33], Float:duck_start_time[33], Float:last_origin[33][3]
	
	buttons = get_uc(pUC, UC_Buttons)
	
	if(buttons & IN_DUCK)
	{
		if(last_stand[id])
		{
			pev(id, pev_origin, last_origin[id])
			
			duck_start_time[id] = get_gametime()	
			last_stand[id] = false
		}
		
	}
	else
	{
		if(!last_stand[id])
		{
			fGameTime = get_gametime()
			
			if((fGameTime - duck_start_time[id]) < 0.04)
			{
				pev(id, pev_origin, origin)
				if(get_distance_f(origin, last_origin[id]) < 60.0)
				{
					engfunc(EngFunc_SetOrigin, id, last_origin[id])
					set_pev(id, pev_bInDuck, false)
				}
			}
		}
		last_stand[id] = true
	}
	
}
