#define PLUGIN_VERSION 		"1.0"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>

static Handle:g_hOnLeaveGhost, bLateLoad;

public Plugin:myinfo =
{
	name = "[L4D] Ghost Life Regeneration",
	author = "raziEiL [disawar1]",
	description = "Gives back full health to infected when they enter ghost mode",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static g_SmokerHp, g_BoomerHp, g_HunterHp;

public OnPluginStart()
{
	new Handle:temp = LoadGameConfigFile("l4d_spec2ghost");
	if (temp == INVALID_HANDLE )
		SetFailState("Missing required gamedata/l4d_spec2ghost.txt"); // silver signatures

	new offset = GameConfGetOffset(temp, "CTerrorPlayer_OnEnterGhostState");
	CloseHandle(temp);

	g_hOnLeaveGhost = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, OnLeaveGhost);

	CreateConVar("l4d_ghostlife_version", PLUGIN_VERSION, "Ghost life plugin version.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	g_SmokerHp = GetConVarInt(FindConVar("z_gas_health"));
	g_BoomerHp = GetConVarInt(FindConVar("z_exploding_health"));
	g_HunterHp = GetConVarInt(FindConVar("z_hunter_health"));
	
	if (bLateLoad)
		for( new i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) )
				OnClientPutInServer(i);
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
		DHookEntity(g_hOnLeaveGhost, false, client);
}

public MRESReturn:OnLeaveGhost(client)
{
	if (IsClientInGame(client))
		CreateTimer(0.0, GL_t_RestoreHP, client);

	return MRES_Ignored;
}

public Action:GL_t_RestoreHP(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_isGhost") == 1 ){

		switch(GetEntProp(client, Prop_Send, "m_zombieClass"))
		{
			case 1:
			{
				SetEntityHealth(client, g_SmokerHp);
			}
			case 2:
			{
				SetEntityHealth(client, g_BoomerHp);
			}
			case 3:
			{
				SetEntityHealth(client, g_HunterHp);
			}
		}
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLateLoad = late;
	return APLRes_Success;
}