#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

static const String:g_sMusicBox[][] = 
{
	"physics/glass/glass_impact_bullet1.wav",
	"physics/glass/glass_impact_bullet2.wav",
	"physics/glass/glass_impact_bullet3.wav",
	"physics/glass/glass_impact_bullet4.wav",
	"physics/glass/glass_sheet_break1.wav",
	"physics/glass/glass_sheet_break2.wav",
	"physics/glass/glass_sheet_break3.wav",
	"physics/glass/glass_pottery_break1.wav",
	"physics/glass/glass_pottery_break2.wav",
	"physics/glass/glass_pottery_break3.wav",
	"physics/glass/glass_largesheet_break1.wav",
	"physics/glass/glass_largesheet_break2.wav",
	"physics/glass/glass_largesheet_break3.wav"
}

public Plugin:myinfo =
{
	name = "Ice Tank",
	author = "raziEiL [disawar1]",
	description = "Bla bla bla for 27 Days Later",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static		Handle:g_hIce, Handle:g_hChance, iEntSteam[MAXPLAYERS+1] = {-1, ...},  bool:bIceMan[MAXPLAYERS+1], bool:g_bCvarIce, g_iCvarChance;

public OnPluginStart()
{
	LoadTranslations("99TANKS.phrases");

	g_hIce		=	CreateConVar("ice_tank", "1", "", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hChance		=	CreateConVar("ice_chance", "100", "", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	
	HookConVarChange(g_hIce, OnCVarChange)
	HookConVarChange(g_hChance, OnCVarChange)
	GetCvars();

	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_shoved", PlayerShoved);
	HookEvent("player_death", PlayerDeath);
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);

	RegAdminCmd("ice", IceMeCmd, ADMFLAG_RCON);
	RegAdminCmd("hotme", CmdHotMe, ADMFLAG_RCON);
}

public Action:IceMeCmd(client, agrs) 
{
	if (!bIceMan[client])
		IT_FreezeMe(client);
	else
		IT_SoHot(client)

	return Plugin_Handled;
}

public Action:CmdHotMe(client, agrs) 
{
	IT_SoHot(client);
	return Plugin_Handled;
}
	
public OnMapStart()
{
	new MAX_ARRAY = sizeof(g_sMusicBox);

	for (new i = 0; i < MAX_ARRAY; i++ )
		PrecacheSound(g_sMusicBox[i], true);
}

// CLEAR CLIENT STATUS:
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
		IT_SoHot(i);
}

public OnClientDisconnect(client)
{
	IT_SoHot(client);
}
/* 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (GetClientTeam(client) == 2 && IsPlayerAlive(client)){

		if (!IsFakeClient(client) && buttons & IN_ATTACK2 ){

			new target = GetClientAimTarget(client, true);
			
			if (IsValidEntity(target)){

				if (bIceMan[target] && GetClientTeam(target) == 2){
				
					decl Float:fvPosClient[3], Float:fvPosTarget[3];
					
					GetClientAbsOrigin(client, fvPosClient);
					GetClientAbsOrigin(target, fvPosTarget);
					
					new Float:dis = GetVectorDistance(fvPosClient, fvPosTarget);
					PrintToChatAll("%N -> %N dis %2.f", client, target, dis);
					if (dis < 85){
						IT_PlayRandomSound(client);
						IT_SoHot(target);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
 */

public Action:PlayerShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new savior = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (bIceMan[client] && GetClientTeam(client) == 2 && GetClientTeam(savior) == 2){

		IT_PlayRandomSound(client);
		IT_SoHot(client);
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (bIceMan[client] && GetClientTeam(client) == 2)
		IT_SoHot(client);
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bCvarIce) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "dmg_health")
	
	if (!bIceMan[client] && Lucky() && client && attacker && dmg > 0 && GetClientTeam(client) == 2 && IsPlayerTank(attacker))
		IT_FreezeMe(client)
}

IT_FreezeMe(client)
{
	bIceMan[client] = true;

	IT_PlayRandomSound(client);
	PrintToChatAll("%N - '%t'", client, "Ice");

	SetEntityRenderFx(client, RenderFx:RENDERFX_PULSE_FAST_WIDE);
	SetEntityRenderColor(client, 0, 102, 153, 200);
	ScreenFade(client, 0, 0, 102, 153, 50, 0);

	iEntSteam[client] = IT_CreateParticle(client);
	new flags = GetEntityFlags(client)
	SetEntityFlags(client, (flags |= FL_ATCONTROLS)); // Õ¿…ƒ≈Õ —¿Ã€… À”◊ÿ»… —œŒ—Œ¡, ◊“Œ¡€ «¿ÃŒ–Œ«»“‹ »√–Œ ¿!
}

IT_SoHot(client)
{
	if (!bIceMan[client]) return;
	
	bIceMan[client] = false;
	PrintToChatAll("%N - '%t'", client, "Hot");

	SetEntityRenderFx(client, RenderFx:RENDERFX_NONE)
	SetEntityRenderColor(client, 255, 255, 255, 255);
	ScreenFade(client, 0, 0, 250, 130, 255, 1);
	
	IT_RemoveSteam(client);
	new flags = GetEntityFlags(client);
	SetEntityFlags(client, (flags &= ~FL_ATCONTROLS));
}

IT_CreateParticle(client)
{
	new particle = CreateEntityByName("info_particle_system");

	decl String:sBuffer[64];
	GetEntPropString(client, Prop_Data, "m_iName", sBuffer, 64);

	if (strcmp(sBuffer, "") == 0){
		FormatEx(sBuffer, 256, "iceman_%d", client);
		DispatchKeyValue(client, "targetname", sBuffer);
	}

	DispatchKeyValue(particle, "effect_name", "steam_manhole");
	DispatchKeyValue(particle, "angles", "-90 0 0");
	DispatchSpawn(particle);

	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	SetVariantString(sBuffer);
	AcceptEntityInput(particle, "SetParent")
	SetVariantString("medkit");
	AcceptEntityInput(particle, "SetParentAttachment")

	return particle;
}

ScreenFade(target, red, green, blue, alpha, duration, type)
{
	if (IsClientInGame(target)){
		new Handle:msg = StartMessageOne("Fade", target);
		BfWriteShort(msg, 500);
		BfWriteShort(msg, duration);
		if (type == 0)
			BfWriteShort(msg, (0x0002 | 0x0008));
		else
			BfWriteShort(msg, (0x0001 | 0x0010));
		BfWriteByte(msg, red);
		BfWriteByte(msg, green);
		BfWriteByte(msg, blue);
		BfWriteByte(msg, alpha);
		EndMessage();
	}
}

IT_PlayRandomSound(client)
{
	new track = GetRandomInt(0, sizeof(g_sMusicBox) - 1);
	EmitSoundToAll(g_sMusicBox[track], client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, SND_SHOULDPAUSE, SNDVOL_NORMAL, SNDPITCH_HIGH, -1, NULL_VECTOR, NULL_VECTOR);
}

bool:IsPlayerTank(client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

bool:Lucky()
{
	//PrintToChatAll("g_iCvarChance %d", g_iCvarChance)
	return GetRandomInt(1, 100) <= g_iCvarChance;
}

IT_RemoveSteam(client)
{
	if (IsValidEntity(iEntSteam[client]))
		AcceptEntityInput(iEntSteam[client], "Kill");
	iEntSteam[client] = -1;
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCvars();
}

public OnConfigsExecuted()
{
	GetCvars();
}

GetCvars()
{
	g_bCvarIce = GetConVarBool(g_hIce);
	g_iCvarChance = GetConVarInt(g_hChance);
}
