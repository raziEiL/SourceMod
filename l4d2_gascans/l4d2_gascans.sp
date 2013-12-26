#define PLUGIN_VERSION "1.0"

/*
	Установка:
	
		Мод включает в себя два необходимых файла аддон в формате .vpk и плагин, одно не работает без другого!
	
	Как этим пользоваться?
	
		1. Разместите нужное вам кол-во канистр (команда !gascanme)
		2. Перезагрузите карту
		3. Начните проходить сценарий, чтобы увидеть результат
		
	Некоторые подробности:

		Максимальное возможное число канистр с бензином (созданные Valve + плагином) составляет 999 шт. Если больше игра будет испорчена!
		Плагин не "брикает" систему очков (Scoring System) за прохождение в игровом режиме Сражение (VS)
		
	Редактирование:
	
		Фаил сохранения уже имеется? Чтобы продолжить создание канистр с того места где вы остановились, введите в чат !gascans команду
		После чтения из файла плагин загрузит ранее сохраненные канистры, для их подсветки включите ауры (команда !gasinput)
		Вы так же можете использовать команду разработчика для быстрой телепортации к канистрам или любой энтити по индексу (!teletoent)
		Эта команда доступна при компиляции исходного кода с переменной debug 1
		
	Удаление плагина:

		Я настоятельно рекомендую полное удаление установленного мода - аддона вместе с плагином из вашей директории сервера
		Но вы также отключить плагин воспользовавшись консольной командой (Covar) НЕ ЖЕЛАТЕЛЬНО!
*/

#include <sourcemod>
#include <sdktools>

#define debug 0

public Plugin:myinfo =
{
	name = "[L4D2] Gas Can limit increase",
	author = "raziEiL [disawar1]",
	description = "Increases the limit of gascans",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static		Handle:g_hGCEnable, Handle:g_hKv, String:g_sPatch[PLATFORM_MAX_PATH], bool:bEvents, bool:bSkip, iGasCansPoured, iTotalCans;

public OnPluginStart()
{
	CreateConVar("l4d2_gascan_version", PLUGIN_VERSION, "L4D2 Gas Can plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hGCEnable = CreateConVar("l4d2_gascan_enable", "1", "Enable / Disable plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	
	RegAdminCmd("sm_gascanme", CmdGasCanSave, ADMFLAG_ROOT, "Create and save gascan to file by client origin");
	RegAdminCmd("sm_gascans", CmdGasCanLoad, ADMFLAG_ROOT, "Load all gascans from file");
	RegAdminCmd("sm_gasinput", CmdGasCanInpt, ADMFLAG_ROOT, "Toggle ON / OFF scavenge glows to all gascans");
	#if debug
		RegAdminCmd("sm_teletoent", CmdTeleToEnt, ADMFLAG_ROOT, "Developer cmd teleport to any entity");
	#endif

	GC_SetupDateBaseFile();
}

/*											+==========================================+
											|		  		COMMANDS				   |
											+==========================================+	
*/

#if debug
public Action:CmdTeleToEnt(client, agrs)
{
	if (agrs == 0){

		ReplyToCommand(client, "[GC] !teletoent <index>")
		return Plugin_Handled;
	}

	decl String:sInput[64];
	GetCmdArg(1, sInput, sizeof(sInput));

	new iEnt = StringToInt(sInput);
	
	if (iEnt && IsValidEntity(iEnt)){
	
		decl Float:vPosEntity[3];
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPosEntity);
		
		TeleportEntity(client, vPosEntity, NULL_VECTOR, NULL_VECTOR);
	
		PrintToChat(client, "[GC] Teleported to <%d> entity", iEnt);
	}

	return Plugin_Handled;
}
#endif

public Action:CmdGasCanInpt(client, agrs)
{
	if (agrs == 0){
	
		ReplyToCommand(client, "[GC] !gasinput <0|1>")
		return Plugin_Handled;
	}
	
	decl String:sInput[64];
	
	GetCmdArg(1, sInput, sizeof(sInput));
	new Input = StringToInt(sInput);

	PrintToChat(client, "[GS] Turn %s glow to all gascans", Input == 1 ? "ON" : "OFF");
	GS_GlowsAndDisplay(Input);

	return Plugin_Handled;
}

public Action:CmdGasCanSave(client, agrs)
{
	decl Float:vOrg[3];
	GetClientAbsOrigin(client, vOrg);
	
	GS_KvJumpToMap();
	GC_SaveLoadGasCan(vOrg);

	return Plugin_Handled;
}	

public Action:CmdGasCanLoad(client, agrs)
{
	GS_KvJumpToMap();
	
	new TotalCans = KvGetNum(g_hKv, "total cans", 0);

	for (new Can = 0; Can < TotalCans; Can++)
		GC_SaveLoadGasCan(_, true);
		
	if (client)
		PrintToChatAll("[GS] Successfully loaded %d gascans", TotalCans);

	GC_SaveLoadGasCan(_, true, true);

	return Plugin_Handled;
}

/*											+==========================================+
											|		  	GAS CANS HEAD CODE			   |
											+==========================================+	
*/

public Event_GsScavengeIsReady(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (bSkip) return;
	
	if (iTotalCans == 0 && GetConVarBool(g_hGCEnable))
		CmdGasCanLoad(0, 0);
		
	bSkip = true;
	GS_GlowsAndDisplay(1, true);
	
	#if debug
		PrintToChatAll("[GS] Scavenge is ready!")
	#endif
}

public Event_GsPourCompleted(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (++iGasCansPoured == iTotalCans){

		#if debug
			PrintToChatAll("[GS] Are u ready?!")
		#endif
		
		Ent_Fire("relay_car_ready", "trigger");
	}
	#if debug
	else
		PrintToChatAll("[GS] %d / %d", iGasCansPoured, iTotalCans)
	#endif
}

public Event_GsRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	#if debug
		PrintToChatAll("[GS] Round start - reset all")
	#endif

	bSkip = false;
	iGasCansPoured = 0;

	GS_GlowsAndDisplay();
}

GS_GlowsAndDisplay(const Input = 0, bool:bHud = false)
{
	new	EntIndex = -1, cans;

	while ((EntIndex = FindEntityByClassname(EntIndex, "weapon_scavenge_item_spawn")) != INVALID_ENT_REFERENCE){
		cans++;

		if (Input)
			AcceptEntityInput(EntIndex, "TurnGlowsOn");
		else
			AcceptEntityInput(EntIndex, "TurnGlowsOff");
	}

	if (!bHud) return;
	
	iTotalCans = cans;

	Ent_Fire("progress_display", "SetTotalItems", iTotalCans);
}

/*											+==========================================+
											|		  		SAVE & LOAD		 	 	   |
											+==========================================+	
*/

/**
*	Сбрасываем счетчик загруженных / сохраненных канистр / залитых канистр / общее кол-во канистр
*/
public OnMapStart()
{
	decl String:sMap[5];
	GetCurrentMap(sMap, sizeof(sMap));
	
	new bool:hook;
	if (strcmp(sMap, "c1m4") == 0 || strcmp(sMap, "c6m3") == 0){
	
		bSkip = false;
		iTotalCans = 0;
		iGasCansPoured = 0;
		GC_SaveLoadGasCan(_, _, true);

		hook = true;
	}

	GC_HookEvents(hook);
}

/**
*	Загружаем файл, если отсутвует будет создан
*/
GC_SetupDateBaseFile()
{
	g_hKv = CreateKeyValues("Collect My Gas Cans");
	
	BuildPath(Path_SM, g_sPatch, PLATFORM_MAX_PATH, "data/l4d2_gascan.cfg");
	
	if (FileExists(g_sPatch))
		FileToKeyValues(g_hKv, g_sPatch);
	else
		KeyValuesToFile(g_hKv, g_sPatch);
}

GC_SaveLoadGasCan(Float:vOrg[3] = {0.0, 0.0, 0.0}, bool:bLoad = false, bool:bLoadComplite = false)
{
	static count, gascan;
	
	if (bLoadComplite){
	
		if (bLoad)
			count = gascan;
		else
			count = 0;
		gascan = 0;
		KvRewind(g_hKv);
		return;
	}
	
	decl String:sBuffer[24];
	Format(sBuffer, sizeof(sBuffer), "gascan %d", !bLoad ? ++count : ++gascan);
	
	if (!bLoad)
		KvSetNum(g_hKv, "total cans", count);
	KvJumpToKey(g_hKv, sBuffer, true);
	
	if (!bLoad){
		KvSetVector(g_hKv, "origin", vOrg);
		KvRewind(g_hKv);
		KeyValuesToFile(g_hKv, g_sPatch);

		PrintToChatAll("[GS] Total saved %d gascans", count);
	}
	else {
		KvGetVector(g_hKv, "origin", vOrg);
		KvGoBack(g_hKv);
	}
	
	GC_CreateScavengeEnitity(vOrg);
}

GC_CreateScavengeEnitity(const Float:vOrg[3])
{
	new iEnt = CreateEntityByName("weapon_scavenge_item_spawn");

	DispatchKeyValue(iEnt, "angles", "0 0 0");
	DispatchKeyValue(iEnt, "body", "0");
	DispatchKeyValue(iEnt, "disableshadows", "1");
	DispatchKeyValue(iEnt, "glowstate", "3");
	DispatchKeyValue(iEnt, "model", "models/props_junk/gascan001a.mdl");
	DispatchKeyValue(iEnt, "skin", "0");
	DispatchKeyValue(iEnt, "solid", "0");
	DispatchKeyValue(iEnt, "spawnflags", "2");
	DispatchKeyValue(iEnt, "targetname", "scavenge_gascans_spawn");
	DispatchSpawn(iEnt);
	
	TeleportEntity(iEnt, vOrg, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEnt, "SpawnItem");
	AcceptEntityInput(iEnt, "TurnGlowsOff");
	
	#if debug
		PrintToChatAll("[GS] Gascan ent <%d> %f %f %f", iEnt, vOrg[0], vOrg[1], vOrg[2]);
	#endif
}

/**
*	Перемещаемся в раздел текущей карты или создаем его
*/
GS_KvJumpToMap()
{
	decl String:sMap[24];
	GetCurrentMap(sMap, sizeof(sMap));
	KvJumpToKey(g_hKv, sMap, true);
}

/*											+==========================================+
											|		  		OTHER STUFF		 	 	   |
											+==========================================+	
*/

/**
*	Использование: Ent_Fire <цель> [действие] [значение]
*
*	@Credits to [ANY] Dev Cmds plugin by Silver 
*/
Ent_Fire(const String:sName[], const String:sInput[], Params = -1)
{
	decl String:sEntName[64];

	for (new i = 0; i < 4096; i++){
	
		if (IsValidEntity(i)){
		
			GetEntPropString(i, Prop_Data, "m_iName", sEntName, sizeof(sEntName));
			
			if (StrEqual(sEntName, sName)){
					
				#if debug
					PrintToChatAll("[GS] ent_fire (%s %d, %s, %d)", sName, i, sInput, Params);
				#endif
				
				if (Params != -1)
					SetVariantInt(Params);

				AcceptEntityInput(i, sInput);
				break;
			}
		}
	}
}

/**
*	Отлавливаем нужные события
*/
GC_HookEvents(bool:bHook)
{
	#if debug
		LogMessage("[GS] %s Events", bHook && !bEvents ? "Hook" : !bHook && bEvents ? "Unhook" : "Skip");
	#endif
	
	if (bHook && !bEvents){
	
		HookEvent("gascan_pour_completed", Event_GsPourCompleted, EventHookMode_PostNoCopy);
		HookEvent("round_start", Event_GsRoundStart, EventHookMode_PostNoCopy);
		HookEvent("finale_start", Event_GsScavengeIsReady, EventHookMode_PostNoCopy);
		HookEvent("explain_c1m4_finale", Event_GsScavengeIsReady, EventHookMode_PostNoCopy);
		
		bEvents = true;
	}
	else if (!bHook && bEvents){
	
		UnhookEvent("gascan_pour_completed", Event_GsPourCompleted, EventHookMode_PostNoCopy);
		UnhookEvent("round_start", Event_GsRoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("finale_start", Event_GsScavengeIsReady, EventHookMode_PostNoCopy);
		UnhookEvent("explain_c1m4_finale", Event_GsScavengeIsReady, EventHookMode_PostNoCopy);
		bEvents = false;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (!IsDedicatedServer()) 
		return APLRes_Failure;

	decl String:buffer[12];
	GetGameFolderName(buffer, sizeof(buffer));

	if (strcmp(buffer, "left4dead2") == 0)
		return APLRes_Success;
	
	Format(buffer, sizeof(buffer), "Plugin not support \"%s\" game", buffer);
	strcopy(error, err_max, buffer);
	return APLRes_Failure;
}