/**********************************
****** Debug INC Tool By Destro ***
**********************************/

#define DEBUG_DRAW_NONE    0
#define DEBUG_DRAW_CONSOLE 1
#define DEBUG_DRAW_LOG	   2
	
#if defined _DEBUG_ON
	#define _DEBUG_BUFF	1024
	#define _debug(%1,%2)	__debug(%1,%2)
	#define _debug_draw()	__debug_draw()

	new debug_info[_DEBUG_BUFF]
	new const debug_file[] = "debug.log"
	
	stock __debug(const draw, const func[], any:...)
	{
		vformat(debug_info, _DEBUG_BUFF-1, func, 3) // Save LastCall

		if(draw == DEBUG_DRAW_NONE)
			return

		if(draw == DEBUG_DRAW_CONSOLE)
		{
			static _time[10]
			format_time(_time, 9, "%H:%M:%S", get_systime())
			server_print("*DEBUG: %s: GameTime[%.3f] - Info[%s]", _time, get_gametime(), debug_info)
		}
		else /*if(draw == DEBUG_DRAW_LOG) */
		{
			static lines
			if(++lines > 500)
			{
				lines = 0
				delete_file(debug_file)
				log_to_file(debug_file, "Clear debug file")
			}
				
			log_to_file(debug_file, "*DEBUG: GameTime[%.3f] - Info[%s]", get_gametime(), debug_info)
		}
	}
	stock __debug_draw()
	{
		log_to_file(debug_file, "*DEBUG END: LastCall: GameTime[%.3f] - Info[%s]", get_gametime(), debug_info)
	}
#else
	#define _debug(%1,%2)  {}
	#define _debug_draw()  {}
#endif