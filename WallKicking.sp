#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Stop Wall Kicking",
	author = "raziEiL [disawar1]",
	description = "Prevent player from using the wall kicking trick",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static bool:bWallKick[MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar("stop_wallkicking_version", PLUGIN_VERSION, "Stop Wall Kicking plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("ability_use", WK_Event_AbilityUse);
	HookEvent("player_jump", WK_Event_PlayerJump);
}

public Action:WK_Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!bWallKick[client] && IsPlayerHunter(client) && GetClientButtons(client) & IN_JUMP){

		bWallKick[client] = true;
		CreateTimer(1.5, WK_t_Unlock, client);
	}
}

public Action:WK_Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (bWallKick[client] && !(GetEntityFlags(client) & FL_ONGROUND)){

		decl String:sAbility[64];
		GetEventString(event, "ability", sAbility, 64);

		if (strcmp(sAbility, "ability_lunge") == 0){

			ForcePlayerSuicide(client);

			if (IsPlayerAlive(client)){

				SetEntityMoveType(client, MOVETYPE_NONE);
				CreateTimer(3.0, WK_t_L4D2BugFix, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
				PrintToChatAll("%N punished for using wallkicking", client);
		}
	}
}

public Action:WK_t_L4D2BugFix(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerHunter(client)) return;

	PrintToChatAll("WTF! %N what are you doing?", client);
	SetEntityMoveType(client, MOVETYPE_CUSTOM);
	ForcePlayerSuicide(client);
}

public Action:WK_t_Unlock(Handle:timer, any:client)
{
	bWallKick[client] = false;
}

bool:IsPlayerHunter(client)
{
	return GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 3;
}