#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Witches Tracking",
	author = "raziEiL [disawar1]",
	description = "Teleport witches in the same place where they were at round one",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static  Handle:hWitchArray, bool:bFirstRound, iIndex;

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("witch_spawn", Event_WitchSpawn);
	hWitchArray = CreateArray(3);
}

public OnMapEnd()
{
	bFirstRound = false;
	ClearArray(hWitchArray);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bFirstRound = !bFirstRound;
	iIndex = 0;
}

public Action:Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iEnt = GetEventInt(event, "witchid");

	decl Float:fWitchData[2][3];

	if (bFirstRound){
	
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fWitchData[0]);
		GetEntPropVector(iEnt, Prop_Send, "m_angRotation", fWitchData[1]);
		PushArrayArray(hWitchArray, fWitchData[0]);
		PushArrayArray(hWitchArray, fWitchData[1]);
		//PrintToChatAll("witch %d %f %f %f, %f %f %f ", iIndex, fWitchData[0][0], fWitchData[0][1], fWitchData[0][2], fWitchData[1][0], fWitchData[1][1], fWitchData[1][2]);
	}
	else {

		if (GetArraySize(hWitchArray) <= iIndex) return;
		
		GetArrayArray(hWitchArray, iIndex, fWitchData[0]);
		GetArrayArray(hWitchArray, iIndex + 1, fWitchData[1]);
		TeleportEntity(iEnt, fWitchData[0], fWitchData[1], NULL_VECTOR);
		//PrintToChatAll("array %d %f %f %f, %f %f %f ", iIndex, fWitchData[0][0], fWitchData[0][1], fWitchData[0][2], fWitchData[1][0], fWitchData[1][1], fWitchData[1][2]);
		iIndex += 2;
	}
}

