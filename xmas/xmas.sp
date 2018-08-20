#define PLUGIN_VERSION "1.6"
/*
                                              Yt$$$.
                                           .,e$$$$$F'
                         4e r               $$$$$$$.
                         d$$br            _z$$$$$$$F`
                          ?$$b._          ^?$$$$$$$
                           4$$$"     -eec.  ""JP" ..eee$%..
                           -**N #c   -^***.eE  ^z$P$$$$$$$$$r-
                  .ze$$$$$eu?$eu '$$$$b $=^*$$ .$$$$$$$$$$"
               --."?$$$$$$$$$c"$$c .""" e$K  =""*?$$$P""""
   ueee. `:`  $E !!h ?$$$$$$$$b R$N'~!! *$$F J"""C.  `
  J  `"$$eu`!h !!!`4!!<?$$$$$$$P ?".eee-z.ee" ~$$e.br
  'j$$Ne`?$$c`4!~`-e-:!:`$$$$$$$ $$**"z $^R$P  3 "$$$bJ
   4$$$F".`?$$c`!! \).!!!`?$$$$F.$$$# $u$% ee*"^ :4`"$"?$q
    ""`,!!!:`$$N.4!!~~.~~4 ?$$F'$$F.@.* -L.e@$$$$ec.      "
    "Rr`!!!!h ?$$c`h: `# !! $F,r4$L***  e$$$$$$$$$$$$hc
      #e'4!!!!L`$$b'!.:!h`~~ .$F'"    d$$$$$$$$$$$$$$$$$h,
       ^$.`!!!!h $$b`!. -    $P /'   .$$$$$$$$$$$$$$$$$$$$$c
         "$c`!!!h`$$.4~      $$$r'   <$$$$$$$$$$$$$$$$$$$P"""
           ^te.`~ $$b        `Fue-   `$$$$$$$$$$$$$$P".:  !! "<
              ^"=4$P"     .,,,. -^.   ?$$$$$$$$$$"?:. !! :!!~ ,,ec..
                    ..z$$$$$$$$$h,    `$$$$$$P"..`!f :!f ~)Lze$$$P""""?i
                  ud$$$$$$$$$$$$$$h    `?$$F :~)ue$$P*"..:!!!!! J
                .K$$$$$$$$$$$$$$$$$,     P.>e'!f !~ ed$$P".:!!!!!!!!`.d"
               z$$$$$$$$$$$$$$$$$$$$      4!!~\e$$$P`:!!!!!!!!!!'.eP'
              -*". . "??$$$$$$$$$$$$       ~ `z$$$F".`!!!!!!!!!!',dP"
            ." ):!!h i`!- ("?$$$$$$f        ,$$P":! ). `'!!!!`,d$F'
       .ueeeu.J`-^.!h <-  ~`.. ??$$'       ,$$ :!!`e$$$$e `,e$F'
    e$$$$$$$$$$$$$eeiC ")?:-<:%':^?        ?$f !!! ?$$$$",F"
   P"....```""?$$$$$$$$$euL^.!..` .         "Tu._.,``""
   $ !!!!!!!!!!::.""??$$$$$$eJ~^=.            ````
   ?$.`!!!!!!!!!!!!!!:."??$$$$$c'.
    "?b.`!!!!!!!!!!!!!!!!>."?$$$$c
      ^?$c`'!!!!!!!!!!!',eeb, "$$$k
         "?$e.`'!!!!!!! $$$$$ ;.?$$
            "?$ee,``''!."?$P`i!! 3P
                ""??$bec,,.,ceeeP"
                       `""""""
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

/*======================================*/
#define TAG		"\x03[\x05xMas\x03]\x04 "
#define MUSIC		"music/flu/jukebox/all_i_want_for_xmas.wav"
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_NOTIFY
#define MAX_CLIENTS		(MaxClients + 1)
/*========*/
new		Handle:g_hTimer, Handle:g_hxMsg, Handle:g_hSendTo, Handle:g_hMsgTimer, Handle:g_hSnow, Handle:g_hNoSnowFix,
		g_iSpamBlock[MAXPLAYERS+1], Float:g_fCvarTimer = 120.0, g_iCvarSendTo, bool:g_bCvarSnow, bool:g_bCvarSnowFix,
		bool:g_bOn, bool:g_bBlock;

public Plugin:myinfo =
{
	name = "[L4D & L4D2] xMas",
	author = "raziEiL [disawar1], gratters by Electr000999",
	description = "Happy New Year and Merry Christmas!",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

/*========*/
public OnPluginStart()
{
	LoadTranslations("xMas.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("xmas_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	g_hTimer			=	CreateConVar("xmas_timer",		"300",		"Show Xmas messages to everyone every x.x seconds. (0 = Disable gratters)", CVAR_FLAGS, true, 0.0);
	g_hSendTo			=	CreateConVar("xmas_msg",			"2", 		"Max wishes messages player can send to another player on map", CVAR_FLAGS, true, 0.0);
	g_hSnow			=	CreateConVar("xmas_snow", 		"1",		"Enable, Disable snowfall", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hNoSnowFix		=	CreateConVar("xmas_snow_fix", 	"1",		"Enable, Disable no snow fix (Removes other func_precipitation entities)", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d2_xMas");

	GetCVars();
	HookConVarChange(g_hTimer,		OnCVarChange);
	HookConVarChange(g_hSendTo,		OnCVarChange);
	HookConVarChange(g_hSnow,			OnCVarChange);
	HookConVarChange(g_hNoSnowFix,	OnCVarChange);

	RegAdminCmd("sm_xmas_party", Command_XmasParty, ADMFLAG_KICK, "Turn the music louder, and congratulate all even yourself");
	RegConsoleCmd("sm_xmas", Command_Xmas, "Send msg to other player with the wishes!");

	SetupTimer();
}

public OnMapStart()
{
	g_bOn = false;
	PrecacheSound(MUSIC, true);

	for (new i = 1; i <= MaxClients; i++)
		g_iSpamBlock[i] = 0;
}

public XM_ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, XM_t_CreateSnowFall);
}

public Action:Command_XmasParty(client, agrs)
{
	if (client){

		if (!g_bOn){

			g_bOn = true;
			EmitSoundToAll(MUSIC);
			KillMsgTimer();
			g_hMsgTimer = CreateTimer(220.0, XM_t_DontLoopSound);
			PrintToChatAll("%s%t", TAG, "xMas Enable");

			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && !IsFakeClient(i))
					PrintToChat(i, "%s%N\x01, %t", TAG, i, "xMas Msg");
		}
		else
			StopMidnightTrack();
	}
	return Plugin_Handled;
}

StopMidnightTrack()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			StopSound(i, SNDCHAN_AUTO, MUSIC);

	PrintToChatAll("%s%t", TAG, "xMas Disable");
	KillMsgTimer();
	g_bOn = false;
}

public Action:XM_t_DontLoopSound(Handle:timer)
{
	g_hMsgTimer = INVALID_HANDLE;
	StopMidnightTrack();
}

KillMsgTimer()
{
	if (g_hMsgTimer != INVALID_HANDLE){

		CloseHandle(g_hMsgTimer);
		g_hMsgTimer = INVALID_HANDLE;
	}
}

public Action:XM_t_CreateSnowFall(Handle:timer)
{
	new iEnt = -1;

	if (g_bCvarSnowFix){

		while ((iEnt = FindEntityByClassname(iEnt , "func_precipitation")) != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iEnt, "Kill");
		while ((iEnt = FindEntityByClassname(iEnt , "func_precipitation_blocker")) != INVALID_ENT_REFERENCE)
			AcceptEntityInput(iEnt, "Kill");
	}

	iEnt = -1;
	iEnt = CreateEntityByName("func_precipitation");

	if (iEnt != -1){

		decl String:sMap[64], Float:vMins[3], Float:vMax[3], Float:vBuff[3];

		GetCurrentMap(sMap, 64);
		Format(sMap, sizeof(sMap), "maps/%s.bsp", sMap);
		PrecacheModel(sMap, true);

		DispatchKeyValue(iEnt, "model", sMap);
		DispatchKeyValue(iEnt, "preciptype", "3");

		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMax);
		GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);

		SetEntPropVector(iEnt, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", vMax);

		vBuff[0] = vMins[0] + vMax[0];
		vBuff[1] = vMins[1] + vMax[1];
		vBuff[2] = vMins[2] + vMax[2];

		TeleportEntity(iEnt, vBuff, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
	}
}

public Action:Command_Xmas(client, args)
{
	if (client){

		if (g_iSpamBlock[client] >= g_iCvarSendTo){

			PrintToChat(client, "%s%t", TAG, "xMas Limit");
			return Plugin_Handled;
		}

		if (args != 2){

			ReplyToCommand(client, "%s%t", TAG, "zMas Help");
			return Plugin_Handled;
		}

		decl String:arg[MAX_NAME_LENGTH], String:arg2[128];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));

		decl String:target_name[MAX_TARGET_LENGTH];
		new players_list[MAX_CLIENTS], players_count, targetclient;
		new bool:send;

		if ((players_count = ProcessTargetString(arg, 0, players_list, MAX_CLIENTS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), send)) > 0){

			for (new i = 0; i < players_count; i++){

				targetclient = players_list[i];

				if (!IsFakeClient(targetclient)){

					PrintToChatAll("%s %N \x01- %s! by \x04%N", TAG, targetclient, arg2, client);
					PrintHintTextToAll("%N - %s! by %N", targetclient, arg2, client);
					PrintToChat(targetclient, "%s\x01%t", TAG, "zMas Msg", client);
				}
				else
					return Plugin_Handled;
			}
			g_iSpamBlock[client]++;
		}
	}
	return Plugin_Handled;
}

public Action:XM_t_PrintGratters(Handle:timer)
{
	decl String:sMsg[24];
	new iRadnomVal = GetRandomInt(1, 12);

	if (iRadnomVal != 12){

		FormatEx(sMsg, 24, "xMas%d", iRadnomVal);

		if (iRadnomVal > 2)
			PrintHintTextToAll("%t", sMsg);
		else
			PrintHintTextToAll("%t", sMsg, GetCurrentYear() + 1);
	}
	else {

		decl iClients[MAX_CLIENTS], iClient[2];
		new iCount;

		for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && !IsFakeClient(i))
				iClients[++iCount] = i;

		if (iCount > 1){

			iClient[0] = iClient[1] = iClients[GetRandomInt(1, iCount)];

			while (iClient[0] == iClient[1])
				iClient[1] = iClients[GetRandomInt(1, iCount)];
		}
		else
			return;

		decl String:sNames[96];
		FormatEx(sNames, 96, "%N, %N\n", iClient[0], iClient[1]);

		iRadnomVal = GetRandomInt(3, 8);

		if (iRadnomVal == 8)
			iRadnomVal = 12;

		FormatEx(sMsg, 24, "xMas%d", iRadnomVal);
		PrintHintTextToAll("%s%t",  sNames, sMsg);
	}
}

GetCurrentYear()
{
	decl String:sYear[24];
	FormatTime(sYear, 24, "%Y", GetTime());

	return StringToInt(sYear);
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
	HookEvents();

	if (!g_fCvarTimer && g_hxMsg != INVALID_HANDLE)
		KillTimer(g_hxMsg);
	else if (g_fCvarTimer && g_hxMsg == INVALID_HANDLE)
		SetupTimer();
}

public OnConfigsExecuted()
{
	GetCVars();
	HookEvents();
}

SetupTimer()
{
	g_hxMsg = CreateTimer(g_fCvarTimer, XM_t_PrintGratters, _, TIMER_REPEAT);
}

GetCVars()
{
	g_fCvarTimer		=	GetConVarFloat(g_hTimer);
	g_bCvarSnowFix	=	GetConVarBool(g_hNoSnowFix);
	g_iCvarSendTo	=	GetConVarInt(g_hSendTo);
}

HookEvents()
{
	g_bCvarSnow = GetConVarBool(g_hSnow);

	if (g_bCvarSnow && !g_bBlock){

		HookEvent("round_start", XM_ev_RoundStart, EventHookMode_PostNoCopy);
		g_bBlock = true;
	}
	else if (!g_bCvarSnow && g_bBlock){

		UnhookEvent("round_start", XM_ev_RoundStart);
		g_bBlock = false;
	}
}
/*
									M  E  R  R  Y    C  H  R  I  S  T  M  A  S
									~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
														AND!
										  __         __         __
										>(' )      >(' )      >(' )
										  )/   ,     )/   ,     )/   ,
										 /(____/\   /(____/\   /(____/\
										/        ) /        ) /        )
										\ `  =~~/  \ `  =~~/  \ `  =~~/
										 `---Y-' __ `---Y-' __ `---Y-' __
											~~' (__)   ~~' (__)   ~~' (__)

													:D
*/