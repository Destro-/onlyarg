#if defined _sxei_included
  #endinput
#endif
#define _sxei_included
#pragma reqlib API_sXeI

/**************************************/
/*** API: sXe Injected Events 1.03 ***/
/**************************************/


// make_screenshot
enum {
	SCREEN_SUCCESS=0,
	SCREEN_WAIT_SXEI,
	SCREEN_NO_SXEI,
	SCREEN_INVALID_TARGET,
	SCREEN_INVALID_ADMIN,
	SCREEN_UPLOAD,
	SCREEN_DOWNLOAD,
	SCREEN_STOPPED,
	SCREEN_UNKNOWN_ERROR,
	SCREEN_ADMIN_BUSY
}

// fw_screen_save
enum {
	ERROR_NONE=0,
	ERROR_DISCONNECT,
	ERROR_TRANSFER,
	ERROR_SAVE_FILE
}

// get_user_16bpp
enum {
	BPP_UNKNOWN=0,
	BPP_16BPP,
	BPP_32BPP
}

/* [Saca una ScreenShot a un jugador]
 - admin: admin/jugador al que se le envia la ScreenShot (si es 0 solo se guarda en el servidor)
 - return:
  Devuelve "SCREEN_SUCCESS" si la ScreenShot fue iniciada correctamente,
  de lo contario devuelve cualquier otro "SCREEN_"
*/
native make_screenshot(id, admin)


/* [Devuelve el porcentaje actual de la transferencia]
 - return:
   Si la ScreenShot se envia a un admin el porcentaje es 50%-50% (upload-download),
   de lo contario es el 100% del upload.
   Devuelve -1 si no existe una transferencia en curso
*/
native screen_progress(id)


/* [Muestra en un MOTD la ultima ScreenShot recivida por el jugador]
 - return:
  Devuelve true si se mostro la ultima ScreenShot
*/
native screen_viewlast(id)


/* [el print del sxei-SS-info */
native print_sxei(id, const msg[], any:...)


/* [Devuelve el HID del jugador] */
native get_user_hid(id, hid[], len)


/* [Devuelve el HID corto de setinfo] */
native get_user_shorthid(id, hid[], len)


/* [Comprueba si esta en 16bpp]
 - return:
	BPP_UNKNOWN: No se puede saber (no sxe)
	BPP_16BPP: Esta en 16bpp
	BPP_32BPP: Esta en 32bpp
*/
native get_user_16bpp(id)


/* [Forward llamada cuando se completa o cancela la subida de la ScreenShot]
 - filename: Nombre del archivo de la imagen que se guarda en el servidor
 - error:
	ERROR_NONE:       Se subio y guardo la ScreenShot correctamente
	ERROR_DISCONNECT: Se cancelo la transferencia porque se desconecto el jugador
	ERROR_TRANSFER:   Ocurrio un error desconocido en la transferencia
	ERROR_SAVE_FILE:  Ocurrio un error al guardar la ScreenShot en el servidor
 - return:
  Devuelve true si se mostro la ultima ScreenShot
*/
forward fw_screen_save(id, admin, const filename[], error)


/* [Forward llamada cuando se inicia una ScreenShot] */
forward fw_screen_take(id, admin)


/* [Forward llamada cuando la ScreenShot llego al admi/jugadorn] */
forward fw_screen_recv(id, player)


/* [Forward llamada cuando se recive el HID] */
forward fw_recv_hid(id, const hid[], const shorthid[])
