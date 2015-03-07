#if defined _onlyarg_included
  #endinput
#endif
#define _onlyarg_included

/*****************************************************
************* ONLY ARG - API v1.0.1 ******************
*****************************************************/

/* LIBRERIAS ==================*

//#define OA_MYSQL_INC
//#define OA_SERVER_INC
//#define OA_UTIL_INC
//#define OA_OLD_MENU_INC
//#define OA_ACC_INC
//#define OA_ADM_INC
*============================*/


#include <onlyarg_const.inc>
#include <onlyarg_stocks.inc>


/*===========================================================================================================
=============================================================================================================
=============================================================================================================
=============================================================================================================
===========================================================================================================*/
#if defined OA_MYSQL_INC
#pragma reqlib onlyarg_mysql
#include <mysqlt>

/*
# Inicio de la conexión mysql
# Si connection es 0 o errnum es distinto de 0 el intento de conexión fallo
# Si la conexión falla se reintentara en 15~20 segundos
*/
forward fw_oa_mysql_connect(Handle:connection, errnum)
#endif


/*===========================================================================================================
=============================================================================================================
=============================================================================================================
=============================================================================================================
===========================================================================================================*/
#if defined OA_SERVER_INC
#pragma reqlib onlyarg_server

/*
# Indica si es un servidor valido
# Si serverid es 0 no es un servidor valido
# serverid es el index del servidor en la tabla "servidores"
*/
forward fw_oa_server_index(serverid)
#endif


/*===========================================================================================================
=============================================================================================================
=============================================================================================================
=============================================================================================================
===========================================================================================================*/
#if defined OA_UTIL_INC
#pragma reqlib onlyarg_util

/*
# Muestra un MOTD via web
# 'title' titulo del motd
# 'webfile' archivo/script en www.onlyarg.com/ingame/ (ejemplo: "csstats_top.php?sv=%d")
*/
native oa_motd(id, title[], webfile[], any:...)


/*
# Similar al chatcolor de ConnorMcLeod
# 'color' puede ser el index de otro jugador
*/
native oa_chat_color(id, color=color_team, const msg[], any:...)


/*
# Filtra un string para remover cualquier carácter problemático
# - 'checkrange' comprueba que solo sean caracteres ascii(desactivar si se usa para filtrar un string que contenga ^1/^2/^3)
*/
native oa_filter_print(string[], len, checkrange=true)

/*
# Filtra los insultos (puto, puta)
# - 'mask' cantidad de insultos que se ocultan
# - 'strict' activa el modo estricto. (se eliminan todos los caracteres que no sean letras y los numeros se reemplazan por letras (ejmp: 3=e, 1=i) detecta(put@,put0, etc))
# return: devuelve '0' si no contiene insultos, '1' si se ocultaron los insultos, o '2' si contiene insultos sin ocultar
*/
native oa_filter_badwords(string[], mask=1, strict=0)

/*
# Filtra el spam (ip/muchos numeros/nombre de comunidades)
# - 'mask' oculta el spam, -1 solo oculta numeros, 0 no oculta nada, otro numero positivo indica la cantidad de palabras que se ocultaran
#         los numeros se olcultan si hay mas de 5 y menos de 9 numeros, con mas de 9 numeros se considera spam siempre y cuando 'mask' sea menor a 10 
# return: devuelve '0' si no contiene spam, '1' si se oculto el spam, o '2' si contiene spam
*/
native oa_filter_spam(string[], mask=-1)

/*
# Cambia el equipo de un jugador usando el engine del CS (jointeam etc...)
# - 'other_frame' indica si se utilizara un task para cambiar el equipo en otro frame,
#    utilizar 'other_frame' cuando se quiera cambiar de equipo al hookear algun mensaje (VGUIMenu, etc...).
*/
native oa_eng_change_team(id, team=TEAM_AUTO, other_frame=false)


/*
# Cambia el equipo de un jugador usando usando el offset del CS
# - 'teaminfo' indica si se actualizara el equipo en los clientes (scoreboard,color del chat, etc...), (es seguro para cambios masivos)
# - 'changemodel' indica si se cambiara el model al del equipo nuevo (es seguro para cambios masivos)
*/
native oa_set_user_team(id, team=TEAM_UNASSIGNED, teaminfo=true, changemodel=true)


/*
# Obtiene el equipo actual usando el offset del CS
*/
native oa_get_user_team(id)


/*
# Setea un model personalizado a un jugador (seguro para cambios masivos)
# - 'modelindex' indica si se utilizaron los hitbox del model personalizado
*/
native oa_set_player_model(id, model[], modelindex=0)

/*
# Obtiene el model actual del jugador
*/
stock  oa_get_player_model(id, model[], len)
{
	get_user_info(id, "model", model, len)
}

/*
# Remueve el model personalizado y deja el correcto segundo el equipo del jugador
*/
native oa_reset_player_model(id)


/*
# Obtiene el ShortHID de un jugador
*/
stock get_user_hid(id, hid[], len)
{
	get_user_info(id, "*HID", hid, len)
}

#endif



/*===========================================================================================================
=============================================================================================================
=============================================================================================================
=============================================================================================================
===========================================================================================================*/
#if defined OA_OLD_MENU_INC

// https://amxmodx-es.com/Thread-API-OldMenu-1-1
#include <api_oldmenu>
#endif



/*===========================================================================================================
=============================================================================================================
=============================================================================================================
=============================================================================================================
===========================================================================================================*/
#if defined OA_ACC_INC
#pragma reqlib onlyarg_acc

/*
# Muestra el menu de la cuenta
*/
native oa_acc_menu(id)

/*
# Inidica/comprueba si esta permitido jugar como invitado
# - 'allow' en 0 no se permiten invitados
    en 1 se permiten invitados
    en -1 la native devuelve el valor actual
*/
native oa_acc_allow_guests(allow=-1)


/*
# Setea/Obtiene datos 'no seguros' de la cuenta
# Es como si fuera algo similar a "setinfo" pero de la cuenta
*/
native oa_acc_get_key(id, const keyname[])
native oa_acc_set_key(id, const keyname[], value)


/*
# Obtiene el UserID del foro (si tiene la cuenta sincronizada)
*/
native oa_acc_get_forum_uid(id)


/*
# Forward llamada cuando un jugador elige a un PJ o ingresa como invitado
# Si acc_id o pj_id es 0 el jugador ingreso como invitado
# El valor devuelto se tomara como el equipo al que el jugador debe ser ingresado,
# si el valor devuelto es -1 el jugador queda como unassigned
*/
forward fw_oa_acc_joingame(id, acc_id, pj_id, const user[], const name[])


forward fw_oa_acc_logout(id) // sin uso

/*
# Forward llamada cuando se muestra el menu principal
# Devolver -1 para bloquear o 1 para bloquear las opciones de cambio de equipo
*/
forward fw_oa_acc_mainmenu(id)


/*
# Forward llamada cuando se cambia el nombre de un jugador
# ideal para cachear el name
*/
forward fw_oa_acc_changename(id, const name[])
#endif


/*===========================================================================================================
=============================================================================================================
=============================================================================================================
=============================================================================================================
===========================================================================================================*/

#if defined OA_ADM_INC
#pragma reqlib onlyarg_adm

/*
# Obtiene los accesos como admin de un jugador
*/
native oa_get_access(id, &group)

/*
# Comprueba los accesos de un jugador
*/
native oa_has_access(id, access, group=0) 


/*
# Comprueba si un jugador tiene acceso al comando
*/
native oa_cmd_access(id, cid, num=0, access=-1, group=-1, silent=false)


/*
# Busca un jugador como objetivo dado al argumento dado
# - 'arg' puede el el nombre,parte del nombre, el userid o la ip.
# FLAGS:
- CMDTARGET_SELF		: Permite invluirse a uno mismo en la busqueda
- CMDTARGET_ONLY_ALIVE		: Solo jugadores vivos
- CMDTARGET_ONLY_DEAD		: Solo jugadores muertos
- CMDTARGET_ONLY_REGISTER	: Solo jugadores registrados
- CMDTARGET_ONLY_GUEST		: Solo invitados
- CMDTARGET_SAMELEVEL		: Jugadores que tengan el mismo nivel de acceso (omitir inmunidad para el mismo nivel)
- CMDTARGET_CHECKLEVEL		: Comprueba que el jugador tenga un nivel inferior de acceso (sin inmunidad)
*/
native oa_cmd_target(id, const arg[], flags)


/* TYPE
- 0: Normal (es afectado por el modo invisible)
- 1: Oculta el nombre del admin a todos los jugadores (lo muestra a cualquier admin)
- 2: Oculta el nombre del admin a todos los jugadores con un grupo de acceso inferior
- 3: Solo muestra el mensaje a los admins que tengan el mismo o mayor grupo de acceso (el grupo del admin o el parametro group)
*/
native oa_show_activity(admin, type=0, group=0, const fmt[], any:... )


/*
# Compara dos jugadores (admins)
# devuelve el id del jugador con el grupo de mayor acceso
# en caso de se iguales devuelve 0
*/
native oa_admin_compare(id, id2)


/*
# Devuelve true si el PJ tiene un admin en estado de suspencion
*/
native oa_admin_is_suspended(id)


/*
# Abre el menu de admin (algo similar a amxmodmenu)
*/
native oa_admin_openmenu(id)


/*
# Añade un item al menu de admin
# Si 'access' es -1 se toma como una categoria y no un item
# - 'color':
#    0: blanco
#    1: amarillo
#    2: rojo
*/
native oa_admin_add_item(const itemname[], access=ACCESS_ANY_ADM, group=0, color=0)

/*
# Logea acciones de un admin hacia un jugador
*/
native log_admin_to(admin, target, action[], info[]="", any:...)


/*
# Logea acciones de un admin
*/
native log_admin(admin, info[]="", any:...)

/*
# Forward llamada cuando hay algun cambio en los accesos de un jugador
*/
forward fw_oa_admin_update(id, access, group)


/*
# Forward llamada cuando cuando se selecciona una opcion del admin menu
*/
forward fw_oa_admin_itemselect(id, itemid)


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
#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
