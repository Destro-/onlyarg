#if defined _onlyarg_stock_included
  #endinput
#endif
#define _onlyarg_stock_included

/*
# Registra un comando para admins
*/
stock oa_register_cmd(const name[], const func[], access=ACCESS_ALL, group=0, const info[], concmd=false)
{
	new _info[128]
	_info[0] = 1+group
	if(info[0]) copy(_info[1], 127, info)
	
	if(!concmd) return register_clcmd(name, func, access, _info, 0)
	return register_concmd(name, func, access, _info, 0)
}

stock get_configsdir(name[],len)
{
	return get_localinfo("amxx_configsdir",name,len)
}

stock oa_add_base_plugin(title[])
{
	server_cmd("amx_pausecfg add ^"%s^"", title)
}

stock __dhud_color
stock __dhud_x
stock __dhud_y
stock __dhud_effect
stock __dhud_fxtime
stock __dhud_holdtime
stock __dhud_fadeintime
stock __dhud_fadeouttime

stock set_dhudmessage(red=0, green=160, blue=0, Float:x=-1.0, Float:y=0.65, effects=2, Float:fxtime=6.0, Float:holdtime=3.0, Float:fadeintime=0.1, Float:fadeouttime=1.5)
{
	#define clamp_byte(%1)       (clamp(%1, 0, 255))
	#define pack_color(%1,%2,%3) (%3 + (%2<<8) + (%1<<16))

	__dhud_color       = pack_color( clamp_byte(red), clamp_byte(green), clamp_byte(blue))
	__dhud_x           = _:x
	__dhud_y           = _:y
	__dhud_effect      = effects
	__dhud_fxtime      = _:fxtime
	__dhud_holdtime    = _:holdtime
	__dhud_fadeintime  = _:fadeintime
	__dhud_fadeouttime = _:fadeouttime

	return 1
}

stock show_dhudmessage(id, const msg[], any:...)
{
	new numArguments = numargs()

	if(numArguments == 2)
	{
		send_dhudMessage(id, msg)
	}
	else {
		new buffer[128]
		vformat(buffer, charsmax(buffer), msg, 3)
		send_dhudMessage(id, buffer)
	}
	return 1
}

stock send_dhudMessage(const id, const msg[])
{
	message_begin(id?MSG_ONE_UNRELIABLE:MSG_BROADCAST, SVC_DIRECTOR, _, id)
	{
		write_byte(strlen(msg) + 31)
		write_byte(DRC_CMD_MESSAGE)
		write_byte(__dhud_effect)
		write_long(__dhud_color)
		write_long(__dhud_x)
		write_long(__dhud_y)
		write_long(__dhud_fadeintime)
		write_long(__dhud_fadeouttime)
		write_long(__dhud_holdtime)
		write_long(__dhud_fxtime)
		write_string(msg)
	}
	message_end()
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
