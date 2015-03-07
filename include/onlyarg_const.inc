#if defined _onlyarg_const_included
  #endinput
#endif
#define _onlyarg_const_included


#define CMDTARGET_SELF			(1<<0)
#define CMDTARGET_ONLY_ALIVE		(1<<1)
#define CMDTARGET_ONLY_DEAD		(1<<2)
#define CMDTARGET_ONLY_REGISTER	(1<<3)
#define CMDTARGET_ONLY_GUEST		(1<<4)
#define CMDTARGET_SAMELEVEL		(1<<5)
#define CMDTARGET_CHECKLEVEL		(1<<6)

#define ACCESS_ALL		0	/* everyone */
#define ACCESS_RESERVATION	(1<<0)	/* flag "a" */
#define ACCESS_BAN_ADD		(1<<1)	/* flag "b" */
#define ACCESS_UNBAN		(1<<2)	/* flag "c" */
#define ACCESS_PERMANENT_BAN	(1<<3)	/* flag "d" */
#define ACCESS_BAN		(1<<4)	/* flag "e" */
#define ACCESS_BANIP		(1<<5)	/* flag "f" */
#define ACCESS_KICK		(1<<6)	/* flag "g" */
#define ACCESS_SLAY		(1<<7)	/* flag "h" */
#define ACCESS_SLAP		(1<<8)	/* flag "i" */
#define ACCESS_CHAT		(1<<9)	/* flag "j" */
#define ACCESS_CVAR		(1<<10)	/* flag "k" */
#define ACCESS_CFG		(1<<11)	/* flag "l" */
#define ACCESS_PASSWORD		(1<<12)	/* flag "m" */
#define ACCESS_PAUSE		(1<<13)	/* flag "n" */
#define ACCESS_PLUGIN		(1<<14)	/* flag "o" */
#define ACCESS_MAP		(1<<15)	/* flag "p" */
#define ACCESS_VOTE		(1<<16)	/* flag "q" */
#define ACCESS_TEAM		(1<<17)	/* flag "r" */
#define ACCESS_LEVEL_1		(1<<18)	/* flag "s" */
#define ACCESS_LEVEL_2		(1<<19)	/* flag "t" */
#define ACCESS_LEVEL_3		(1<<20)	/* flag "u" */
#define ACCESS_LEVEL_4		(1<<21)	/* flag "v" */
#define ACCESS_LEVEL_5		(1<<22)	/* flag "w" */
#define ACCESS_LEVEL_6		(1<<23)	/* flag "x" */
#define ACCESS_LEVEL_7		(1<<24)	/* flag "y" */
#define ACCESS_LEVEL_8		(1<<25)	/* flag "z" */
#define ACCESS_ANY_ADM		(1<<26)	/* no used on player */
#define ACCESS_HIDDEN		(1<<27)	/* stuff */

enum {
	ACCESS_GROUP_OWNER=1,
	ACCESS_GROUP_SMOD,
	ACCESS_GROUP_SUPERVISOR,
	ACCESS_GROUP_ADMIN,
	ACCESS_GROUP_VIP,
}

enum {
	LOGIN_NONE=0,
	LOGIN_GUEST,
	LOGIN_REGISTER
}

enum {
	color_team=0,
	color_grey=33,
	color_red,
	color_blue
}

enum {
	TEAM_AUTO=0,
	TEAM_UNASSIGNED=0,
	TEAM_TT,
	TEAM_CT,
	TEAM_SPECT
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang11274\\ f0\\ fs16 \n\\ par }
*/
