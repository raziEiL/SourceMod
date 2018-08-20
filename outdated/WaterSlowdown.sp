#define PLUGIN_VERSION "1.1"

#include <sourcemod>

public Plugin:myinfo =
{
	name = "Water Slow down",
	author = "raziEiL [disawar1]",
	description = "Allow the water to slow down survivors when they are in",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static  Handle:hFactor, Float:fCvarFactor, bool:bSlowed[MAXPLAYERS+1];

public OnPluginStart()
{
	hFactor = CreateConVar("wsd_factor", "0.75");

	HookConVarChange(hFactor, WSD_OnCvarChange_Factor);
	fCvarFactor = GetConVarFloat(hFactor);

	RegAdminCmd("sm_wdump", CmdWDump, ADMFLAG_ROOT);
}

public Action:CmdWDump(client, agrs)
{
	new team;
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			ReplyToCommand(client, "factor = %.2f, (IN WATER = %s), (%s) - %N", GetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue"), GetEntityFlags(i) & FL_INWATER ? "YES" : "NO", (team = GetClientTeam(i)) == 2 ? "Survivor" : team == 3 ? "Infected" : "Spectator", i);
	return Plugin_Handled;
}

public OnGameFrame()
{
	if (!IsServerProcessing()) return;

	for (new i = 1; i <= MaxClients; i++){
		
		if (IsClientInGame(i) && GetClientTeam(i) == 2){

			if (GetEntityFlags(i) & FL_INWATER){
			
				if (bSlowed[i]) continue;
				
				bSlowed[i] = true;
				SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", fCvarFactor);
			}
			else if (bSlowed[i]){

				bSlowed[i] = false;
				SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
			}
		}
	}
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
		if (bSlowed[i] && IsClientInGame(i) && !IsFakeClient(i))
			SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
}

public WSD_OnCvarChange_Factor(Handle:hHandle, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		fCvarFactor = GetConVarFloat(hFactor);
}