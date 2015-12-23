#include <amxmodx>
#include <fakemeta>

#define OA_ACC_INC
#include <onlyarg>

#define PLUGIN	"OA: SpecList"
#define VERSION	"1.0"
#define AUTHOR	"Destro"
/**********************************************/

const Float:UPDATETIME = 2.0
const Float:MIN_UPDATETIME = 0.3

/*Color del HUD (R - G - B)*/
new const COLOR[3] = { 64, 64, 64 }

new g_name[33][32], g_connect[33]
new g_maxplayers, g_HudSync

public plugin_init()
{
	oa_register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("SpecHealth2", "spec_target", "bd")
	
	g_maxplayers = get_maxplayers()
	g_HudSync = CreateHudSyncObj()
	
	set_task(UPDATETIME, "task_updatespec", .flags="b")
}

public fw_oa_acc_changename(id, const name[])
{
	copy(g_name[id], 31, name)
}

public client_putinserver(id)
{
	g_connect[id] = (!is_user_bot(id))
}

public client_disconnect(id)
{
	g_connect[id] = false
}

public spec_target(id)
{
	if(!g_connect[id])
		return

	static newtarget, oldtarget
	newtarget = read_data(2)
	oldtarget = pev(id, pev_iuser2)
	
	if(is_user_alive(newtarget))
	{
		remove_task(newtarget)
		set_task(MIN_UPDATETIME, "showspec", newtarget)
	}
	
	if(is_user_alive(oldtarget))
	{
		remove_task(oldtarget)
		set_task(MIN_UPDATETIME, "showspec", oldtarget)
	}
}

public task_updatespec()
{
	static id
	for(id=1; id <= g_maxplayers; id++)
	{
		if(!is_user_alive(id))
			continue
		
		showspec(id)
	}
}

public showspec(id)
{
	static buff[1100], sendto[32], count, dead, spec, len
	len = count = buff[0] = 0
		
	for(dead=1; dead <= g_maxplayers; dead++)
	{
		if(!g_connect[dead] || is_user_alive(dead) || pev(dead, pev_iuser2) != id)
			continue

		len += formatex(buff[len], charsmax(buff)-len, "- %s^n", g_name[dead])
		sendto[count++] = dead
	}
		
	if(!count) return

	format(buff, charsmax(buff), "Specteando a %s: (%d)^n%s", g_name[id], count, buff)

	set_hudmessage(COLOR[0], COLOR[1], COLOR[2], 0.75, 0.15, 0, 0.0, UPDATETIME+0.2, 0.0, 0.0)
	for(spec=0; spec < count; spec++)
		ShowSyncHudMsg(sendto[spec], g_HudSync, buff)
}

