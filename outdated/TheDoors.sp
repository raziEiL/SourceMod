#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "The Doors",
	author = "raziEiL [disawar1]",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static 	Handle:g_hTime, Handle:g_hAntySpam, g_iNumOfRound;

public OnPluginStart()
{
	g_hTime 		= CreateConVar("door_lock_time", "30", "Block start safe room door for <your choice> sec at each round");
	g_hAntySpam 	= CreateConVar("door_lock_spam", "2", "Survovors can close the door one time per <your choice> sec");
	
	HookEvent("round_end", DL_ev_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", DL_ev_PlayerSpawn, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	g_iNumOfRound = -1;
}

public Action:DL_ev_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iNumOfRound = 1;
}

public Action:DL_ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_iNumOfRound) return;

	CreateTimer(1.0, DL_t_LockSafeRoom, g_iNumOfRound == -1 ? GetConVarInt(g_hTime) : GetConVarInt(g_hTime) - 15, TIMER_FLAG_NO_MAPCHANGE);
	g_iNumOfRound = 0;
}

public Action:DL_t_LockSafeRoom(Handle:timer, any:time)
{
	decl Float:vSurvivor[3], Float:vDoor[3], String:sOutPut[128];

	for (new i = 1; i <= MaxClients; i++){

		if (IsClientInGame(i) && GetClientTeam(i) == 2){

			GetClientAbsOrigin(i, vSurvivor);

			if (vSurvivor[0] != 0 && vSurvivor[1] != 0 && vSurvivor[2] != 0)
				break;
		}
	}

	new iEnt = -1;

	while ((iEnt = FindEntityByClassname(iEnt, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE){

		if (GetEntProp(iEnt, Prop_Data, "m_spawnflags") == 32768) continue;

		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vDoor);

		if (GetVectorDistance(vSurvivor, vDoor) < 600){

			SetEntProp(iEnt, Prop_Data, "m_hasUnlockSequence", 1);
			AcceptEntityInput(iEnt, "Lock");

			FormatEx(sOutPut, 128, "OnUser1 !self:Unlock::%d:-1", time);
			SetVariantString(sOutPut);

			AcceptEntityInput(iEnt, "AddOutput");
			AcceptEntityInput(iEnt, "FireUser1");
		}

		if (!GetConVarInt(g_hAntySpam)) continue;

		HookSingleEntityOutput(iEnt, "OnFullyOpen", DL_OutPutOnFullyOpen);

		// for coop only l4d1
/* 		SetEntProp(iEnt, Prop_Data, "m_hasUnlockSequence", 1);
		
		FormatEx(sOutPut, 128, "OnFullyOpen !self:Lock:::-1");
		SetVariantString(sOutPut);
		AcceptEntityInput(iEnt, "AddOutput");

		FormatEx(sOutPut, 128, "OnFullyOpen !self:Unlock::%d:-1", GetConVarInt(g_hAntySpam));
		SetVariantString(sOutPut);
		AcceptEntityInput(iEnt, "AddOutput"); */
	}
}

public DL_OutPutOnFullyOpen(const String:output[], caller, activator, Float:delay)
{
	//SetEntityRenderColor(activator, 200, 0, 0, 255);
	SetEntProp(activator, Prop_Data, "m_hasUnlockSequence", 1);
	CreateTimer(GetConVarFloat(g_hAntySpam), DL_t_UnlockSafeRoom, EntIndexToEntRef(activator), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:DL_t_UnlockSafeRoom(Handle:timer, any:entity)
{
	if (!g_iNumOfRound && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
		SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 0);
	//SetEntityRenderColor(entity, 255, 255, 255, 255);
}