#define PLUGIN_VERSION "1.1"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <l4d_lib>

#define debug 0

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Stop Wall Kicking",
	author = "raziEiL [disawar1]",
	description = "Prevents players from using the wallkicking trick",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

#define GROUND_POST_TIME 0.3

static  Handle:g_hTrickTimer[MAXPLAYERS+1], Float:g_fCvarPounceCrouchDelay, bool:g_bCvarPluginMode;

public OnPluginStart()
{
	CreateConVar("stop_wallkicking_version", PLUGIN_VERSION, "Stop Wall Kicking plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	new Handle:hCvarPounceCrouchDelay = FindConVar("z_pounce_crouch_delay");
	new Handle:hCvarPluginState = CreateConVar("stop_wallkicking_enable", "1", "If set, stops hunters from wallkicking", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	new Handle:hCvarPluginMode = CreateConVar("stop_wallkicking_mode", "0", "How the plugin prevents wall kicking. 0: block trick, 1: slay player", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GetPounceCrouchDealyCvar(hCvarPounceCrouchDelay);
	if (GetConVarBool(hCvarPluginState)) TooglePluginStateEvent(true);
	if (GetConVarBool(hCvarPluginMode)) TooglePluginModeEvent(true);

	HookConVarChange(hCvarPounceCrouchDelay, OnConvarChange_PounceCrouchDelay);
	HookConVarChange(hCvarPluginState, OnConvarChange_PluginState);
	HookConVarChange(hCvarPluginMode, OnConvarChange_PluginMode);
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (!g_bCvarPluginMode && buttons & IN_ATTACK){

		if (buttons & IN_JUMP && IsAttemptingToTrick(client))
			RunTrickChecking(client);

		if (g_hTrickTimer[client] != INVALID_HANDLE)
			buttons &= ~IN_ATTACK;
	}
}

public Action:WK_ev_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetClientButtons(client) & IN_JUMP && IsAttemptingToTrick(client))
		RunTrickChecking(client);
}

public Action:WK_ev_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_hTrickTimer[client] != INVALID_HANDLE){

		decl String:sAbility[64];
		GetEventString(event, "ability", sAbility, 64);

		if (strcmp(sAbility, "ability_lunge") == 0){

			ForcePlayerSuicide(client);

			if (IsInfectedAlive(client)){

				SetEntityMoveType(client, MOVETYPE_NONE);
				CreateTimer(3.0, WK_t_GodModFix, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
				PrintToChatAll("%N punished for using wallkicking", client);
		}
	}
}

RunTrickChecking(client)
{
	if (g_hTrickTimer[client] != INVALID_HANDLE){
		KillTimer(g_hTrickTimer[client]);
		g_hTrickTimer[client] = INVALID_HANDLE;
	}

	g_hTrickTimer[client] = CreateTimer(g_fCvarPounceCrouchDelay, WK_t_BlockWallKick, client, TIMER_REPEAT);

#if debug
	PrintToChat(client, "%f start checking", GetEngineTime())
#endif
}

public Action:WK_t_GodModFix(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerHunter(client)) return;

	PrintToChatAll("%N punished for using wallkicking", client);
	SetEntityMoveType(client, MOVETYPE_CUSTOM);
	ForcePlayerSuicide(client);
}

public Action:WK_t_BlockWallKick(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerHunter(client) && IsInfectedAlive(client)){

		if (GetEntityFlags(client) & FL_ONGROUND){

			g_hTrickTimer[client] = CreateTimer(GROUND_POST_TIME, WK_t_StopTrickChecking, client);
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}

	g_hTrickTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:WK_t_StopTrickChecking(Handle:timer, any:client)
{
	g_hTrickTimer[client] = INVALID_HANDLE;

#if debug
	PrintToChat(client, "%f stop checkig", GetEngineTime());
#endif
}

bool:IsPlayerHunter(client)
{
	return GetPlayerClass(client) == 3;
}

bool:IsAttemptingToTrick(client)
{
	return IsPlayerHunter(client) && !GetEntProp(client, Prop_Send, "m_isAttemptingToPounce");
}

public OnConvarChange_PounceCrouchDelay(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		GetPounceCrouchDealyCvar(convar);
}

public OnConvarChange_PluginState(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		TooglePluginStateEvent(GetConVarBool(convar));
}

public OnConvarChange_PluginMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue))
		TooglePluginModeEvent(GetConVarBool(convar));
}

GetPounceCrouchDealyCvar(Handle:convar)
{
	g_fCvarPounceCrouchDelay = GetConVarFloat(convar) / 2;
}

TooglePluginStateEvent(bool:hook)
{
	static bool:bHooked;

	if (!bHooked && hook){

		HookEvent("player_jump", WK_ev_PlayerJump);
		bHooked = true;
	}
	else if (bHooked && !hook){

		UnhookEvent("player_jump", WK_ev_PlayerJump);
		bHooked = false;
	}
}

TooglePluginModeEvent(bool:hook)
{
	g_bCvarPluginMode = hook;
	static bool:bHooked;

	if (!bHooked && hook){

		HookEvent("ability_use", WK_ev_AbilityUse);
		bHooked = true;
	}
	else if (bHooked && !hook){

		UnhookEvent("ability_use", WK_ev_AbilityUse);
		bHooked = false;
	}
}
