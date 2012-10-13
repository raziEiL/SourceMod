#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

/*=====================
 - фикс вокалайз бага V
 - фикс пропан бага
 - фикс дропа аптек \ пилса V
 - фикс появления ботов больше чем разрешено V
        * Tag *
=======================*/
#define FS		  "[Sacrifice Fix]"

/*=====================
      * ConVar *
=======================*/
new		Handle:g_Sf, Handle:g_Behop, Handle:g_Survivor, Handle:g_Timer, Handle:g_Items, Handle:g_Physics, 
		Handle:g_GameMode, Handle:freeze;

new 	bool:block, bool:block_event;

new		g_CvarSf, g_CvarMin, g_CvarMax, g_CvarTimer, g_CvarItems, g_CvarPhysics;

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Sacrifice Bug Fix",
	author = "raziEiL [disawar1]",
	description = "BIG PACK FIX for LEFT4DEAD.",
	version = PLUGIN_VERSION,
	url = "www.27days-support.at.ua"
}

/*=====================
	* PLUGIN START! *
=======================*/
public OnPluginStart()
{
		
	CreateConVar("sacrifice_fix_version", PLUGIN_VERSION, "Sacrifice Bug Fix plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Sf		=	CreateConVar("fix_sacrifice", "1", "1: Enable Sacrifice Bug Fix for survival mode, 0: Disable fix");
	g_Behop		=	CreateConVar("fix_behop", "4", "Min amount of Survivors when round starts (sometimes behop cant kick bot when player leave), 0: Disable fix");
	g_Survivor	=	CreateConVar("fix_extrabots", "8", "Max amount of Survivors on your server (sometimes you can see more bots than in the your cfg), 0: Disable fix");
	g_Timer		=	CreateConVar("fix_extratimer", "15", "Check Survivors limit after x.x sec when round started, Disable if fix_extrabots set to 0");
	g_Items		=	CreateConVar("fix_dropitems", "1", "1: Delete all player || bot items when they disconnected (blocks item spam for behop, multislot.. plugin) WARNING working only if fix_behop || fix_extrabots cvar enabled, 0: Disable fix");
	g_Physics	=	CreateConVar("fix_physics", "0", "1: When created (oxygentank, propanetank, fireworkcrate) change entnity class to prop_physics, now it can be exploded! You not more need to pickup it to explode, 0: Disable fix");
	//AutoExecConfig(true, "SacrificeBugFix");
	
	g_GameMode	=	FindConVar("mp_gamemode");
	freeze		=	FindConVar("sb_stop");
	
	HookConVarChange(g_GameMode, OnGameModeChange);
	HookConVarChange(g_Behop, OnCVarChange);
	HookConVarChange(g_Survivor, OnCVarChange);
	HookConVarChange(g_Timer, OnCVarChange);
	HookConVarChange(g_Items, OnCVarChange);
	HookConVarChange(g_Physics, OnCVarChange);
	
	RegAdminCmd("fx", CmdFix, ADMFLAG_KICK);
}

/* * * Test Command * * */
public Action:CmdFix(client, args)
{
	ValidMode();
	//ValidLimit();
	OnClientDisconnect(client);
	return Plugin_Handled;
}

public OnMapStart()
{
	block=false;
	ValidMode();
}

/*										+------------------------------------------+
										|	 	 Sacrifice BOT BUG FIX  		   |
										|								 (survival)|
										+------------------------------------------+	
*/
public ValidMode()
{
	decl String:mode[32];
	GetConVarString(g_GameMode, mode, sizeof(mode));
	
	if (strcmp(mode, "survival") == 0 && g_CvarSf == 1){
	
		ValidMap();
	}
}

ValidMap()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	if (strcmp(map, "c7m1_docks") == 0 ||
		strcmp(map, "c7m3_port") == 0){
	
		LogMessage("%s Valid map \"%s\"", FS, map);
		new Handle:g_Rest = FindConVar("mp_restartgame");
		SetConVarInt(g_Rest, 1);
		LogMessage("%s Sacrifice Bug is fixed!", FS);
	}
}

/*										+------------------------------------------+
										|	 	 	Behop bug FIX  				   |
										|							 (all gamemode)|
										+------------------------------------------+	
*/
public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && GetClientTeam(client) != 3 && !IsFakeClient(client) && g_CvarMin != 0)
		CreateTimer(1.0, DoIt2);
}

public Action:DoIt2(Handle:timer)
{
	new fake=0, spectator=0, total=0;

	for (new i = 1; i <= MaxClients; i++){
	
		if (IsClientInGame(i) && GetClientTeam(i) != 3)
		{
			if (GetClientTeam(i) == 2)
				total++;
			if (GetClientTeam(i) == 2 && IsFakeClient(i))
				fake++;
			if (GetClientTeam(i) == 1 && !IsFakeClient(i))
				spectator++;
			if (total > g_CvarMin && fake > spectator && IsFakeClient(i))
			{
				total--;
				Items(i);
				KickClient(i);
				PrintToChatAll("%s kick %N", FS, i);
			}
		}
	}
	PrintToChatAll("Survivors: %d, Fake: %d, Spec: %d", total, fake, spectator);
}

/*										+------------------------------------------+
										|	 	 	Item spam FIX  				   |
										|							 (all gamemode)|
										+------------------------------------------+	
*/
Items(client)
{
	if (g_CvarItems == 1){
	
		new weapons = GetPlayerWeaponSlot(client, 0);
		if (weapons != -1)
			RemovePlayerItem(client, weapons);

		new pistol = GetPlayerWeaponSlot(client, 1);
		if (pistol != -1)	
			RemovePlayerItem(client, pistol);
			
		new bomb = GetPlayerWeaponSlot(client, 2);
		if (bomb != -1)	
			RemovePlayerItem(client, bomb);

		new medkit = GetPlayerWeaponSlot(client, 3);
		if (medkit != -1)	
			RemovePlayerItem(client, medkit);
			
		new pills = GetPlayerWeaponSlot(client, 4);
		if (pills != -1)	
			RemovePlayerItem(client, pills);
	}
}

/*										+------------------------------------------+
										|	 	Extra SURVIVORS Bots BUG FIX       |
										|							 (all gamemode)|
										+------------------------------------------+	
*/
public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client) && block == false && g_CvarMax > 0){
	
		block=true;
		ValidTime();
	}
}

public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	ValidTime();
}

public ValidTime()
{
	PrintToChatAll("%s Cheking please wait...", FS);
	SetConVarInt(freeze, 1);
	CreateTimer(g_CvarTimer * 1.0, DoIt);
}

public Action:DoIt(Handle:timer)
{
	ValidLimit();
}

public ValidLimit()
{
	new x=0, k=0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			x++;
			if (x > g_CvarMax && IsFakeClient(i)){
				k++;
				x--;
				Items(i);
				KickClient(i);	
			}
		}
	}
	if (k != 0){
		PrintToChatAll("%s Detected \"%d\" extra bot, they have been removed. %d", FS, k, x);
		LogMessage("%s Detected \"%d\" extra bot, they have been removed.", FS, k);
		LogMessage("%s Extra Survivors Bug is fixed!", FS);
	}
	else PrintToChatAll("%s All is okay.", FS);
	
	SetConVarInt(freeze, 0);
}

/*										+------------------------------------------+
										|	 		classname name changer	       |
										|							(prop_physics)  |
										+------------------------------------------+	
*/
public OnEntityCreated(entity, const String:classname[])
{
	if (g_CvarPhysics == 1){
	
		if (strcmp(classname, "weapon_oxygentank") == 0 || 
			strcmp(classname, "weapon_propanetank") == 0 || 
			strcmp(classname, "weapon_fireworkcrate") == 0){
			
			//if (entity != -1){
		
				DispatchKeyValue(entity, "solid", "0");
				PrintToChatAll("entity created <%s>", classname);
			//}
		}
	}
}

/*=====================
	* GetConVar *
=======================*/
public OnGameModeChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	ValidMode();
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
	Plugin();
}

public OnConfigsExecuted()
{
	GetCVars();
	Plugin();
}

public GetCVars()
{
	g_CvarSf = GetConVarInt(g_Sf);
	g_CvarMin = GetConVarInt(g_Behop);
	g_CvarItems = GetConVarInt(g_Items);
	g_CvarPhysics = GetConVarInt(g_Physics);
}

public Plugin()
{
	g_CvarMax = GetConVarInt(g_Survivor);
	g_CvarTimer = GetConVarInt(g_Timer);
	
	if (g_CvarMax > 0 && block_event == false)
	{
		HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
		block_event = true;
		PrintToChatAll("%s HookEvent", FS);
	}
	else if (g_CvarMax == 0 && block_event == true)
	{
		UnhookEvent("round_start", RoundStart);
		block_event = false;
		PrintToChatAll("%s UnhookEvent", FS);
	}
}