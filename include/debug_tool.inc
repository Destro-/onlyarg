/**********************************
****** Debug Tool INC By Destro ***
**********************************/

#if !defined _amxmodx_included
  #include <amxmodx>
#endif


#define DEBUG_DRAW_NONE    0
#define DEBUG_DRAW_CONSOLE 1
#define DEBUG_DRAW_LOG	   2

#if defined _DEBUG_ON
	#define _DEBUG_BUFF	512
	#define _DEBUG_CALLS	25
	#define _DEBUG_MAXLINES	300

	new _debug_buff[_DEBUG_CALLS][_DEBUG_BUFF], Float:_debug_time[_DEBUG_CALLS]
	new _debug_start, _debug_size, Float:_gametime
	
	new const debug_file[] = "debug.log"
	
	stock _debug(draw, const func[], any:...)
	{
		new slot
		if(_debug_size == _DEBUG_CALLS)
		{
			slot = _debug_start++
			_debug_start = _debug_start%_DEBUG_CALLS
		}
		else	slot = _debug_size++
	
		vformat(_debug_buff[slot], _DEBUG_BUFF-1, func, 3)
		_debug_time[slot] = _gametime = get_gametime()
		
		if(draw == DEBUG_DRAW_NONE)
			return

		if(draw == DEBUG_DRAW_CONSOLE)
			server_print("*DEBUG: -gametime: (%.3f)  |  -info[%s]", _gametime, _debug_buff[slot])
		else /*if(draw == DEBUG_DRAW_LOG) */
		{
			static lines
			if(++lines > _DEBUG_MAXLINES)
			{
				lines = 0
				delete_file(debug_file)
				log_to_file(debug_file, "==== Empty debug file =============")
			}
				
			log_to_file(debug_file, "*DEBUG: -gametime: (%.3f)  |  -info[%s]", _gametime, _debug_buff[slot])
		}
	}
	stock _debug_draw(max_calls=_DEBUG_CALLS, same_frame=true)
	{
		_gametime = get_gametime()
		
		new map[32], amxx_file[32]
		get_mapname(map, 31)
		get_plugin(-1, amxx_file, 31)
		log_to_file(debug_file, "# DEBUG END: plugin: [%s]  -  gametime: (%.3f)  -  map: [%s] ---", amxx_file, _gametime, map)
		
		if(_debug_size == 0)
		{
			log_to_file(debug_file, "No call log")
			log_to_file(debug_file, "----------------------------------------------------------------------^n")
			return
		}
		
		new _max, Float:_lastcall_time, slot
		_max = clamp(max_calls, 1, _debug_size)
		
		slot = _debug_start - 1
		if(slot < 0) slot += _debug_size
		_lastcall_time = _debug_time[slot]
		
		if(same_frame)
			log_to_file(debug_file, "# Time Difference: (%dms) - fix[%.4f] - [%f] vs - [%f]", floatround((_gametime - _lastcall_time) * 1000.0), (_gametime - _lastcall_time), _gametime, _lastcall_time)
		
		for(new count=1; count <= _max; count++)
		{
			slot = _debug_start - count
			if(slot < 0) slot += _debug_size
			
			if(same_frame)
			{
				if(_lastcall_time != _debug_time[slot])
					break

				log_to_file(debug_file, "#%2d:  -info:[%s]", count, _debug_buff[slot])
			}
			else {
				log_to_file(debug_file, "#%2d:  -difference: (%dms)   |   -info: [%s]", count, floatround((_gametime - _debug_time[slot]) * 1000.0), _debug_buff[slot])
			}
		}
	
		log_to_file(debug_file, "----------------------------------------------------------------------^n")
	}
#else
	#define _debug(%1)  {}
	#define _debug_draw(%1)  {}
#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
