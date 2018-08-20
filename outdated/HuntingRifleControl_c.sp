#define PLUGIN_VERSION "1.4"

/*
	1. Ќаходит все снайперские винтовки и измен€ет их количество на 1 штуку (вз€в 1 раз она исчезнет)
	2. ¬озможность создать и сохранить охотничью винтовку там, где тебе нужно. ≈сли имеетс€ сохранение на текущей карте все Valve винтовки будут удалены
*/
 
#include <sourcemod>
#include <sdktools>

#define HUNTING_RIFLE_MODEL	"models/w_models/weapons/w_sniper_mini14.mdl"

#define HR_ENT_0		"weapon_spawn"
#define HR_ENT_1		"weapon_hunting_rifle_spawn"

public Plugin:myinfo =
{
	name = "Hunting Rifle Tweaking",
	author = "raziEiL [disawar1]",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static		Handle:hRPGSave, Handle:g_hAmmo, Handle:g_hWipe, Handle:hGunArray, g_iCvarAmmo, bool:g_bCvarWipe, String:SavePath[256], bool:bIsSecondRound;

public OnPluginStart()
{
	hRPGSave = CreateKeyValues("HR");
	BuildPath(Path_SM, SavePath, 255, "data/l4d_hr.cfg");

	if (FileExists(SavePath))
		FileToKeyValues(hRPGSave, SavePath);
	else
		KeyValuesToFile(hRPGSave, SavePath);

	g_hAmmo = FindConVar("ammo_huntingrifle_max");
	g_hWipe = CreateConVar("hr_control_wipe", "1", "Wipe (1 = Yes, 0 = No)", FCVAR_NOTIFY);

	HookConVarChange(g_hAmmo, OnCvarChange_Ammo);
	HookConVarChange(g_hWipe, OnCvarChange_Wipe);
	HRC_GetAllCvar();

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	RegAdminCmd("sm_hr", HR, ADMFLAG_ROOT, "Spawn hunter rifle weapon by client origin and save to file");

	hGunArray = CreateArray(3);
}

public Action:HR(client, agrs)
{
	if (!client)
		return Plugin_Handled;

	decl Float:vOrg[3], Float:vAng[3];
	GetClientAbsOrigin(client, vOrg)
	GetClientAbsAngles(client, vAng)
	vOrg[2] += 1;
	vAng[2] = 90.0;

	HRC_SaveLoad(vOrg, vAng, false);

	ReplyToCommand(client, "Saved <%.1f %.1f %.1f>", vOrg[0], vOrg[1], vOrg[2]);
	return Plugin_Handled;
}

public OnMapStart()
{
	ClearArray(hGunArray)
	bIsSecondRound = false;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.6, HRC_t_StartLoop, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:HRC_t_StartLoop(Handle:timer)
{
	new iVariable = HRC_SaveLoad();

	HRC_Loop(HR_ENT_0, iVariable);
	HRC_Loop(HR_ENT_1, iVariable);
	bIsSecondRound = true;

	if (GetArraySize(hGunArray) == 0) return;

	decl Float:fHRData[2][3];

	iVariable = GetArraySize(hGunArray);

	for (new i = 0; i < iVariable; i += 2){

		GetArrayArray(hGunArray, i, fHRData[0]);
		GetArrayArray(hGunArray, i + 1, fHRData[1]);

		HRC_CreateEnitity(fHRData[0], fHRData[1]);

		LogMessage("GET FORM ARRAY AND CREATE HR %f %f %f", fHRData[0][0], fHRData[0][1], fHRData[0][2]);
	}
}

HRC_Loop(const String:WEAPONS[], iDontTochMe)
{
	decl String:sModelName[128];
	new iEnt = -1;

	if (g_bCvarWipe && iDontTochMe){

		while ((iEnt = FindEntityByClassname(iEnt , WEAPONS)) != INVALID_ENT_REFERENCE){

			if (iEnt == iDontTochMe) continue;

			GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName))

			if (strcmp(sModelName, HUNTING_RIFLE_MODEL, false) == 0){
				LogMessage("WIPE ALL HUNING RIFLE %d WE HAVE SAVE!", iEnt);
				AcceptEntityInput(iEnt, "Kill");
			}
		}
	}
	else {

		decl Float:fHRData[2][3];

		while ((iEnt = FindEntityByClassname(iEnt , WEAPONS)) != INVALID_ENT_REFERENCE){

			GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName))

			if (strcmp(sModelName, HUNTING_RIFLE_MODEL, false) == 0){

				if (!bIsSecondRound){

					GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fHRData[0]);
					GetEntPropVector(iEnt, Prop_Send, "m_angRotation", fHRData[1]);
					PushArrayArray(hGunArray, fHRData[0]);
					PushArrayArray(hGunArray, fHRData[1]);
					LogMessage("PUSH TO ARRAY AND KILL HR %f %f %f", fHRData[0][0], fHRData[0][1], fHRData[0][2]);
				}
				else
					LogMessage("SECOND ROUND KILL HR %d", iEnt);
				AcceptEntityInput(iEnt, "Kill");
			}
		}
		LogMessage("END");
	}
}

HRC_SaveLoad(Float:vOrg[3] = {0.0, ...}, Float:vAng[3] = {0.0, ...}, bool:bLoad = true)
{
	new Handle:kv = CreateKeyValues("HR");
	FileToKeyValues(kv, SavePath);

	decl String:sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	KvJumpToKey(kv, sMap, true);

	if (bLoad){
		KvGetVector(kv, "pos", vOrg);
		KvGetVector(kv, "ang", vAng);
	}
	else {
		KvSetVector(kv, "pos", vOrg);
		KvSetVector(kv, "ang", vAng);
		KvRewind(kv);
		KeyValuesToFile(kv, SavePath);
		//LogMessage("HUNING RIFLE SAVE FROM FILE");
	}
	CloseHandle(kv);

	if (vOrg[0] != 0 && vOrg[1] != 0 && vOrg[2] != 0){
		LogMessage("HUNING RIFLE LOAD FROM FILE");
		return HRC_CreateEnitity(vOrg, vAng);
	}
	return 0;
}

HRC_CreateEnitity(const Float:vOrg[3], const Float:vAng[3])
{
	new iEnt = CreateEntityByName("weapon_hunting_rifle");
	TeleportEntity(iEnt, vOrg, vAng, NULL_VECTOR);
	DispatchSpawn(iEnt);

	SetEntProp(iEnt, Prop_Send, "m_iExtraPrimaryAmmo", g_iCvarAmmo);
	SetEntityMoveType(iEnt, MOVETYPE_NONE);
	//LogMessage("HUNING RIFLE %d CREATED", iEnt);
	return iEnt;
}

public OnCvarChange_Wipe(Handle:hHandle, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_bCvarWipe = GetConVarBool(g_hWipe);
}

public OnCvarChange_Ammo(Handle:hHandle, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarAmmo = GetConVarInt(g_hAmmo);
}

HRC_GetAllCvar()
{
	g_bCvarWipe = GetConVarBool(g_hWipe);
	g_iCvarAmmo = GetConVarInt(g_hAmmo);
}