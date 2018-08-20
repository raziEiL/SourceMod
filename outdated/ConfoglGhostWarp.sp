#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

#define NUM_OF_SURVIVORS	 8

public Plugin:myinfo =
{
	name = "GhostWarp",
	author = "Confogl Team, raziEiL [disawar1]",
	description = "Sets whether infected ghosts can right click for warp to next survivor",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

new Handle:GW_hGhostWarp, bool:GW_bEnabled, bool:GW_bDelay[MAXPLAYERS+1], GW_iLastTarget[MAXPLAYERS+1], iSurvivorIndex[NUM_OF_SURVIVORS], g_iSurvivorsArrayLimit;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax)
{
	GW_bEnabled = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	if (GW_bEnabled)
		SI_BuildIndex();

	GW_hGhostWarp = CreateConVar("ghost_warp", "1", "Sets whether infected ghosts can right click for warp to next survivor");

	HookEvent("player_death",	GW_ev_PlayeDeath);
	HookEvent("player_team", GW_ev_PlayerTeam, EventHookMode_PostNoCopy);
	HookEvent("round_start", GW_ev_Fired, EventHookMode_PostNoCopy);
	HookEvent("round_end"	, GW_ev_Fired, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect"	, GW_ev_Fired, EventHookMode_PostNoCopy);

	HookConVarChange(GW_hGhostWarp,GW_ConVarChange);
	GW_bEnabled = GetConVarBool(GW_hGhostWarp);
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GW_OnPlayerRunCmd(client, buttons))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool:GW_OnPlayerRunCmd(client, buttons)
{
	if (!GW_bEnabled || !g_iSurvivorsArrayLimit || !(buttons & IN_ATTACK2) || GW_bDelay[client]) return false;
	if (!IsClientInGame(client) || IsFakeClient(client) ||  GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_isGhost", 1) != 1) return false;

	GW_bDelay[client] = true;
	CreateTimer(0.35, GW_ResetDelay, client);

	GW_WarpToSurvivor(client);

	return true;
}

public GW_ev_Fired(Handle:event, const String:name[], bool:dontBroadcast)
{
	SI_BuildIndex();
}

public GW_ev_PlayeDeath(Handle:event, const String:name[], bool:dB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GW_Reset(client);
}

public GW_ev_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, SI_BuildIndex_Timer);
}

GW_Reset(client)
{
	GW_iLastTarget[client] = 0;
	SI_BuildIndex();
}

GW_WarpToSurvivor(client)
{
	if (!g_iSurvivorsArrayLimit) return;

	new target = iSurvivorIndex[GW_iLastTarget[client]];

	if (!target){

		GW_Reset(client);
		GW_WarpToSurvivor(client);
		return;
	}

	// Prevent people from spawning and then warp to survivor
	SetEntProp(client, Prop_Send, "m_ghostSpawnState", 256);

	decl Float:position[3], Float:anglestarget[3];

	GetClientAbsOrigin(target, position);
	GetClientAbsAngles(target, anglestarget);
	TeleportEntity(client, position, anglestarget, NULL_VECTOR);

	if (++GW_iLastTarget[client] == g_iSurvivorsArrayLimit)
		GW_iLastTarget[client] = 0;
}


SI_BuildIndex()
{
	if (!IsServerProcessing()){return;}

	g_iSurvivorsArrayLimit = 0;

	for (new client = 1; client <= MaxClients; client++){

		if (g_iSurvivorsArrayLimit == NUM_OF_SURVIVORS)
			break;

		if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;

		iSurvivorIndex[g_iSurvivorsArrayLimit++] = client;
	}
}

public Action:SI_BuildIndex_Timer(Handle:timer)
{
	SI_BuildIndex();
}

public Action:GW_ResetDelay(Handle:timer, any:client)
{
	GW_bDelay[client] = false;
}

public GW_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GW_bEnabled = GetConVarBool(GW_hGhostWarp);
}

