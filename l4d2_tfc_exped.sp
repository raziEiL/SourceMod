#define PLUGIN_VERSION "1.5"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

/*////////////////////////
	= Chat debug, Tag =
*////////////////////////
#define debug 0
#if debug
#endif
#define TAG  	  "[debug]"
#define FC  	  "{green}[{blue}TankFightClub{green}]{default}"
/*////////////////////////
		= ConVar =
*////////////////////////
static	Handle:g_enable, Handle:g_info, Handle:g_zombie, Handle:g_extra, Handle:g_timer, Handle:g_support,
		Handle:g_ko, Handle:g_bs, Handle:g_health, Handle:g_health1, Handle:g_health2, Handle:g_health3,
		Handle:g_health4, Handle:g_health5, Handle:g_health6, Handle:g_health7, Handle:g_round1,
		Handle:g_round2, Handle:g_round3,Handle:g_round4, Handle:g_round5, Handle:g_round6, Handle:g_round7, Handle:tankhp, Handle:zombie, Handle:bosses, Handle:specials, Handle:mobs, Handle:ST, Handle:STF,
		Handle:STI, Handle:ST1, Handle:ST2, Handle:ST3,

		g_CvarEnable, g_CvarInfo, g_CvarZombie, g_CvarExtra, g_CvarTimer, g_CvarSupport, g_CvarKo, g_CvarBS,
		g_CvarHealth, g_CvarHealth1, g_CvarHealth2, g_CvarHealth3, g_CvarHealth4, g_CvarHealth5,
		g_CvarHealth6, g_CvarHealth7, g_CvarRound1, g_CvarRound2, g_CvarRound3, g_CvarRound4, g_CvarRound5, g_CvarRound6, g_CvarRound7,

		n, m, TankALL, TankLive, TankCount, TankRound,

		Handle:MsgTimer, Handle:TankFightClubTimer,

		bool:club, //access to TankFightClub.
		bool:block = false,	//blocks PanicEvent if already been started
		bool:block2 = false, //blocks OnClientPost.. if already been started.
		bool:block3 = false, //blocks OnClientPost.. and PanicEvent if game is started.
		bool:block4 = false, //blocks OnClientPost.. when UnhookEvent.
		bool:block5 = false, //blocks re-HookEvent, re-UnhookEvent.
		bool:KOblock = false, //block counter
		bool:KOblock2 = false,
		bool:L4D2 = true;
/*////////////////////////
		= Sound =
*////////////////////////
#define SOUND_CLOCK "level/countdown.wav"
#define SOUND_FIGHT "level/scoreregular.wav"
#define SOUND_TANK "ui/littlereward.wav"

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Tank Fight Club: Expanded Edition",
	author = "raziEiL [disawar1]",
	description = "Welcome to the Tank Fight Club. Kill Them All!",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

/*////////////////////////
	= PLUGIN START! =
*////////////////////////
public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		L4D2 = false;
	}

	CreateConVar("tank_fight_club_version", PLUGIN_VERSION, "Tank Fight Club: Expanded Edition plugin version.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	g_enable = CreateConVar("tank_club_enable", "1", "Plugin: 0 - Disable, 1 - Enable", FCVAR_PLUGIN);
	g_info = CreateConVar("tank_club_info", "1", "Show info message: 0 - Disable, 1 - Type I, 2 - Type II, 3 - Type III", FCVAR_PLUGIN);
	g_zombie = CreateConVar("tank_club_zombie", "1", "Blocks Boss and zombie spawns: 0 - Disable, 1 - Enable", FCVAR_PLUGIN);
	g_extra = CreateConVar("tank_club_extra", "1", "Extra 5, 6, 7 rounds: 0 - Disable, 1 - Enable", FCVAR_PLUGIN);
	g_timer = CreateConVar("tank_club_timer", "60", "Delay before game starts in sec", FCVAR_PLUGIN);
	g_support = CreateConVar("tank_club_st", "0", "Supports SuperTanks plugin.  Tanks will be spawned at 3 and 6 rounds: 0 - Disable, 1 - Enable", FCVAR_PLUGIN);
	g_ko = CreateConVar("tank_club_ko", "1", "Forced to slay all the tanks when the next round begins: 0 - Disable, 1 - Enable", FCVAR_PLUGIN);
	g_bs = CreateConVar("tank_club_bs", "2", "Auto-balance feature. Tanks count will depend on player number.", FCVAR_PLUGIN);
	g_health = CreateConVar("tank_club_hp_zero", "2000", "Default Tank health.", FCVAR_PLUGIN);
	g_health1 = CreateConVar("tank_club_hp_one", "4000", "Tank health in 1st round.", FCVAR_PLUGIN);
	g_health2 = CreateConVar("tank_club_hp_two", "6000", "Tank health in 2 round.", FCVAR_PLUGIN);
	g_health3 = CreateConVar("tank_club_hp_three", "8000", "Tank health in 3 round.", FCVAR_PLUGIN);
	g_health4 = CreateConVar("tank_club_hp_four", "10000", "Tank health in 4 round.", FCVAR_PLUGIN);
	g_health5 = CreateConVar("tank_club_hp_five", "15000", "Tank health in 5 round.", FCVAR_PLUGIN);
	g_health6 = CreateConVar("tank_club_hp_six", "22000", "Tank health in 6 round.", FCVAR_PLUGIN);
	g_health7 = CreateConVar("tank_club_hp_seven", "30000", "Tank health in 7 round.", FCVAR_PLUGIN);
	g_round1 = CreateConVar("tank_club_count_zero", "2", "Tanks in the zero round.", FCVAR_PLUGIN);
	g_round2 = CreateConVar("tank_club_count_one", "5", "Tanks in the 1st round.", FCVAR_PLUGIN);
	g_round3 = CreateConVar("tank_club_count_two", "10", "Tanks in the 2 round.", FCVAR_PLUGIN);
	g_round4 = CreateConVar("tank_club_count_three", "12", "Tanks in the 3 round.", FCVAR_PLUGIN);
	g_round5 = CreateConVar("tank_club_count_four", "15", "Tanks in the 4 round.", FCVAR_PLUGIN);
	g_round6 = CreateConVar("tank_club_count_five", "20", "Tanks in the 5 round.", FCVAR_PLUGIN);
	g_round7 = CreateConVar("tank_club_count_six", "28", "Tanks in the 6 round.", FCVAR_PLUGIN);
	AutoExecConfig(true, "l4d2_TankFightClub");

	HookConVarChange(g_enable, OnPluginEnable);
	HookConVarChange(g_info, OnCVarChange);
	HookConVarChange(g_zombie, OnDirectorEnable);
	HookConVarChange(g_extra, OnCVarChange);
	HookConVarChange(g_timer, OnCVarChange);
	HookConVarChange(g_support, OnExpandedEditionEnable);
	HookConVarChange(g_ko, OnCVarChange);
	HookConVarChange(g_bs, OnCVarChange);
	HookConVarChange(g_health, OnCVarChange);
	HookConVarChange(g_health1, OnCVarChange);
	HookConVarChange(g_health2, OnCVarChange);
	HookConVarChange(g_health3, OnCVarChange);
	HookConVarChange(g_health4, OnCVarChange);
	HookConVarChange(g_health5, OnCVarChange);
	HookConVarChange(g_health6, OnCVarChange);
	HookConVarChange(g_health7, OnCVarChange);
	HookConVarChange(g_round1, OnCVarChange);
	HookConVarChange(g_round2, OnCVarChange);
	HookConVarChange(g_round3, OnCVarChange);
	HookConVarChange(g_round4, OnCVarChange);
	HookConVarChange(g_round5, OnCVarChange);
	HookConVarChange(g_round6, OnCVarChange);
	HookConVarChange(g_round7, OnCVarChange);

	RegConsoleCmd("sm_fc", CmdCount, "Tank Fight Club info");
	RegConsoleCmd("sm_fightclub", CmdCount, "Tank Fight Club info");
	RegConsoleCmd("sm_tankclub", CmdCount, "Tank Fight Club info");
	RegAdminCmd("sm_ko", CmdSlay, ADMFLAG_KICK, "K.O - Slay all Tanks");
	RegAdminCmd("sm_knockout", CmdSlay, ADMFLAG_KICK, "K.O - Slay all Tanks");

	tankhp = FindConVar("z_tank_health");
	zombie = FindConVar("z_common_limit");
	bosses = FindConVar("director_no_bosses");
	specials = FindConVar("director_no_specials");
	mobs = FindConVar("director_no_mobs");
	Director();
}

public OnPluginEnd()
{
	ResetConVar(tankhp);
	ResetConVar(zombie);
	ResetConVar(bosses);
	ResetConVar(specials);
	ResetConVar(mobs);
}

public OnMapStart()
{
	if (block4 == false){
		block2 = false;
		block3 = false;
		PrecacheSound(SOUND_CLOCK, true);
		PrecacheSound(SOUND_FIGHT, true);
		PrecacheSound(SOUND_TANK, true);
		ExpandedEditionEnable();
	}
	else {

		#if debug
		PrintToServer("%s OnMapStart Blocked! Plugin [Tank Fight Club: Expanded edition] Disable", TAG);
		#endif
	}
}

public OnClientPostAdminCheck(client)
{
	if (block4 == false){

		new clientID = GetClientUserId(client);
		CreateTimer(20.0, Welcome, clientID);

		if (block2 == false && block3 == false){

			#if debug
			CPrintToChatAll("%s OnClientPostAdminCheck is NOT Blocked!", TAG);
			#endif

			block2 = true;
			ResetValues();
		}
		else {

			#if debug
			CPrintToChatAll("%s OnClientPostAdminCheck is Blocked!", TAG);
			#endif
		}
	}
	else {

		#if debug
		CPrintToChatAll("%s OnClientPostAdminCheck is Blocked! Plugin Disable", TAG);
		#endif
	}
}
/*////////////////////////
		= Event =
*////////////////////////
public RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (g_CvarInfo == 1 || g_CvarInfo == 2 || g_CvarInfo == 3){
		CPrintToChatAll("%s haha Tanks beat you? {olive}Table{default} of Fighting is:\n Tanks Today: {green}%d{default}\n Tanks Killed: {blue}%d{default}\n Last Round was: {olive}%d{default}\n ------", FC, TankALL, TankCount, n);
	}
	ResetValues();
}

public NewTank(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if debug
	CPrintToChatAll("%s New Tank", TAG);
	#endif

	if (TankLive <= 10) //fixed bug *
		TankLive++;
	else
		CPrintToChatAll("%s WARNING! Reached the Maximum Tanks limit!", FC);
}

public TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TankLive >= 1) //fixed bug *
	TankLive--;

	if (KOblock == false){
		TankALL++;
		TankRound++;
		TankCount++;
		Info();

		switch (n)
		{
			case 0:
			{
				if (TankRound == g_CvarRound1)
				{
					KO();
					SetConVarInt(tankhp, g_CvarHealth1);
					PrintHintTextToAll("Round 1");
					TankRound = 0;
					n = 1;
					EmitSoundToAll(SOUND_FIGHT);
				}
			}
			case 1:
			{
				if (TankRound == g_CvarRound2)
				{
					KO();
					SetConVarInt(tankhp, g_CvarHealth2);
					PrintHintTextToAll("Round 2");
					TankRound = 0;
					n = 2;
					EmitSoundToAll(SOUND_FIGHT);
				}
			}
			case 2:
			{
				if (TankRound == g_CvarRound3)
				{
					KO();
					SetConVarInt(tankhp, g_CvarHealth3);
					TankRound = 0;
					n = 3;
					EmitSoundToAll(SOUND_FIGHT);
					if (g_CvarSupport == 0){
						PrintHintTextToAll("Round 3");
					}
					//===Ext Ed===
					if (g_CvarSupport == 1){
						PrintHintTextToAll("Round 3 SuperTanks");
						SetConVarInt(ST, 1);
						SetConVarInt(STI, 1);
					}
				}
			}
			case 3:
			{
				if (TankRound == g_CvarRound4)
				{
					KO();
					SetConVarInt(tankhp, g_CvarHealth4);
					PrintHintTextToAll("Round 4");
					TankRound = 0;
					n = 4;
					EmitSoundToAll(SOUND_FIGHT);
					if (g_CvarSupport == 1){
						SetConVarInt(ST, 0);
						SetConVarInt(STI, 0);
					}
				}
			}
			case 4:
			{
			//Extra
				if (TankRound == g_CvarRound5 && g_CvarExtra == 1)
				{
					KO();
					SetConVarInt(tankhp, g_CvarHealth5);
					PrintHintTextToAll("Extra Round 5");
					TankRound = 0;
					n = 5;
					EmitSoundToAll(SOUND_FIGHT);
				}
			}
			case 5:
			{
				if (TankRound == g_CvarRound6 && g_CvarExtra == 1)
				{
					KO();
					SetConVarInt(tankhp, g_CvarHealth6);
					TankRound = 0;
					n = 6;
					EmitSoundToAll(SOUND_FIGHT);
					if (g_CvarSupport == 0){
						PrintHintTextToAll("Extra Round 6");
					}
					//===Ext Ed===
					if (g_CvarSupport == 1){
						PrintHintTextToAll("Extra Round 6 SuperTanks");
						SetConVarInt(ST, 1);
						SetConVarInt(STI, 1);
					}
				}
			}
			case 6:
			{
				if (TankRound == g_CvarRound7 && g_CvarExtra == 1)
				{
					KO();
					SetConVarInt(tankhp, g_CvarHealth7);
					PrintHintTextToAll("Extra Round 7");
					TankRound = 0;
					n = 7;
					EmitSoundToAll(SOUND_FIGHT);
					if (g_CvarSupport == 1){
						SetConVarInt(ST, 0);
						SetConVarInt(STI, 0);
					}
				}
			}
		}
	}
	#if debug
	CPrintToChatAll("%s Tank is Die, TankHp = {green}%d{default}, TankLive =  {green}%d", TAG, GetConVarInt(tankhp), TankLive);
	#endif
}

public PanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (block == false && block3 == false){
		#if debug
		CPrintToChatAll("%s Panic Event before time up!", TAG);
		#endif

		club = true;
		block = true;
		Triger();
	}
	else {
		#if debug
		CPrintToChatAll("%s Panic Event is Blocked!", TAG);
		#endif

		return;
	}
}

/*////////////////////////
		= Timer =
*////////////////////////
public Action:PrintMsg(Handle:timer)
{
	new l = g_CvarTimer - m;

	if(l <= 0){
		club = true;
		Triger();
	}
	else {
		CPrintToChatAll("Game Starts in {green}%d{default} sec.", l);
		EmitSoundToAll(SOUND_CLOCK);
		m += 15;
	}
	return Plugin_Continue;
}

public Action:SpawnTank(Handle:timer)
{
	new client = GetRandomClient();
	if (client){

		if (TankLive <= 1)
		{
			new human = 0;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					human++;
					if (TankLive < human - g_CvarBS)
					{
						CheatCommand(client, L4D2 ? "z_spawn_old" : "z_spawn", "tank auto");
					}
				}
			}
		}
	}
	else {
		#if debug
		CPrintToChatAll("%s `SpawnTank` return client BOT, clent not on Game!", TAG);
		#endif
	return;
	}
}

public Action:Welcome(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
		CPrintToChat(client, "%s {olive}%N{default} Welcome to TFC by {olive}raziEiL [disawar1]{default}\nType {olive}!fc{default} in chat to see the results of fights.", FC, client);
}

Triger()
{
	if (MsgTimer != INVALID_HANDLE){
		KillTimer(MsgTimer);
		MsgTimer = INVALID_HANDLE;

		#if debug
		CPrintToChatAll("%s Kill timer", TAG);
		#endif
	}
	if (TankFightClubTimer != INVALID_HANDLE){
		KillTimer(TankFightClubTimer);
		TankFightClubTimer = INVALID_HANDLE;

		#if debug
		CPrintToChatAll("%s Kill timer spawntank", TAG);
		#endif
	}
	if (club == true){

		TankFightClub();
	}
}

/*////////////////////////
	= Tank Fight Club =
*////////////////////////
TankFightClub()
{
	block3 = true;
	CPrintToChatAll("{green}Game Started!");
	PrintHintTextToAll("Fight!");
	EmitSoundToAll(SOUND_FIGHT);
	CheatCommand(GetRandomClient(), "director_force_panic_event");
	TankFightClubTimer=CreateTimer(5.0, SpawnTank, _, TIMER_REPEAT);
}

/*////////////////////////
   = Expanded Edition =
*////////////////////////
ExpandedEditionEnable()
{
	g_CvarSupport = GetConVarInt(g_support);

	if (g_CvarSupport == 1 && g_CvarEnable == 1){

		ExpandedEdition(true);
	}
}

ExpandedEdition(bool:status)
{
	if( ST == INVALID_HANDLE )
		ST = FindConVar("st_on");
	if( STF == INVALID_HANDLE )
		STF = FindConVar("st_finale_only");
	if( STI == INVALID_HANDLE )
		STI = FindConVar("st_display_health");
	if( ST1 == INVALID_HANDLE )
		ST1 = FindConVar("st_wave1_tanks");
	if( ST2 == INVALID_HANDLE )
		ST2 = FindConVar("st_wave2_tanks");
	if( ST3 == INVALID_HANDLE )
		ST3 = FindConVar("st_wave3_tanks");

	if (status){

		SetConVarInt(ST, 0);
		SetConVarInt(STF, 0);
		SetConVarInt(STI, 0);
		SetConVarInt(ST1, 0);
		SetConVarInt(ST2, 0);
		SetConVarInt(ST3, 0);
	}
}

KO()
{
	if (g_CvarKo == 1  && KOblock2 == false && TankLive != 0){
		KOblock = true;
		TanksKO();

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsPlayerTank(i) )
			{
				ForcePlayerSuicide(i);
			}
		}

		KOblock = false;
	}
}

TanksKO()
{
	if (g_CvarInfo == 0)
		return;
	CPrintToChatAll("%s {olive}Tanks K.O! -%d", FC, TankLive);
}
/*////////////////////////
		= Cmd =
*////////////////////////
public Action:CmdCount(client, agrs)
{
	CPrintToChat(client, "%s Round: {olive}%d{default}, Tanks Killed: {blue}%d{default}, TankOnMap: {green}%d", FC, n, TankCount, TankLive);
	return Plugin_Handled;
}

public Action:CmdSlay(client, agrs)
{
	CPrintToChat(client, "%s {blue}Trying to kill Tanks...", FC);
	if (KOblock == false){

		if (TankLive != 0)
		{
			KOblock2 = true;
			CPrintToChat(client, "%s {olive}Successfully! -%d", FC, TankLive);

			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsPlayerTank(i) )
				{
					ForcePlayerSuicide(i);
				}
			}
			KOblock2 = false;
		}
		else {

			CPrintToChat(client, "%s {blue}Can't, no target!", FC);
		}
	}
	if (KOblock == true){

		CPrintToChat(client, "%s {blue}Can't, try again later...", FC);
	}
	return Plugin_Handled;
}

bool:IsPlayerTank(i)
{
	return GetEntProp(i, Prop_Send, "m_zombieClass") == (L4D2 ? 8 : 5);
}

/*////////////////////////
		= Message =
*////////////////////////
Info()
{
	if (g_CvarInfo == 0)
		return;

	EmitSoundToAll(SOUND_TANK);

	if (g_CvarInfo == 1 || g_CvarInfo == 3){

		new i = g_CvarRound1 - TankCount;
		new a = g_CvarRound2 + g_CvarRound1;
		new b = a + g_CvarRound3;
		new c = b + g_CvarRound4;
		new d = c + g_CvarRound5;
		new e = d +	g_CvarRound6;
		new f = e +	g_CvarRound7;
		new a1 = a - TankCount;
		new b2 = b - TankCount;
		new c3 = c - TankCount;
		new d4 = d - TankCount;
		new e5 = e - TankCount;
		new f6 = f - TankCount;

		switch (n)
		{
			case 0:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound1);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", i);
				}
			}
			case 1:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound2);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", a1);
				}
			}
			case 2:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound3);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", b2);
				}
			}
			case 3:
			{
				if (g_CvarInfo == 3)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound4);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", c3);
				}
			}
			//
			case 4:
			{
				if (g_CvarInfo == 3 && g_CvarExtra == 1)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound5);
				}
				if (g_CvarInfo == 3 && g_CvarExtra == 0)
				{
					CPrintToChatAll("{olive}Total Tanks: {default}%d", TankRound);
				}
				if (g_CvarInfo == 1 && g_CvarExtra == 1)
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", d4);
				}
				if (g_CvarInfo == 1 && g_CvarExtra == 0)
				{
					CPrintToChatAll("{olive}Total Tanks: {default}%d", TankRound);
				}
			}
			case 5:
			{
				if (g_CvarInfo == 3 && g_CvarExtra == 1)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound6);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", e5);
				}
			}
			case 6:
			{
				if (g_CvarInfo == 3 && g_CvarExtra == 1)
				{
					CPrintToChatAll("{olive}Tanks: {default}%d/%d", TankRound, g_CvarRound7);
				}
				else
				{
					CPrintToChatAll("{blue}Tanks: {default}%d", f6);
				}
			}
			case 7:
			{
				CPrintToChatAll("{olive}Total Tanks: {default}%d", TankRound);
			}
		}
	}
	if (g_CvarInfo == 2){

			CPrintToChatAll("{green}Tanks Killed: {default}%d", TankCount);
	}
}

/*////////////////////////
		= GetConVar =
*////////////////////////
public OnExpandedEditionEnable(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	ExpandedEditionEnable();
}

public OnPluginEnable(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	Plugin();
}

public OnDirectorEnable(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	Director();
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
	Plugin();
	Director();
	ExpandedEditionEnable();
}

GetCVars()
{
	g_CvarInfo = GetConVarInt(g_info);
	g_CvarHealth = GetConVarInt(g_health);
	g_CvarTimer = GetConVarInt(g_timer);
	g_CvarExtra = GetConVarInt(g_extra);
	g_CvarKo = GetConVarInt(g_ko);
	g_CvarBS = GetConVarInt(g_bs);
	g_CvarHealth1 = GetConVarInt(g_health1);
	g_CvarHealth2 = GetConVarInt(g_health2);
	g_CvarHealth3 = GetConVarInt(g_health3);
	g_CvarHealth4 = GetConVarInt(g_health4);
	g_CvarHealth5 = GetConVarInt(g_health5);
	g_CvarHealth6 = GetConVarInt(g_health6);
	g_CvarHealth7 = GetConVarInt(g_health7);
	g_CvarRound1 = GetConVarInt(g_round1);
	g_CvarRound2 = GetConVarInt(g_round2);
	g_CvarRound3 = GetConVarInt(g_round3);
	g_CvarRound4 = GetConVarInt(g_round4);
	g_CvarRound5 = GetConVarInt(g_round5);
	g_CvarRound6 = GetConVarInt(g_round6);
	g_CvarRound7 = GetConVarInt(g_round7);
}

/*////////////////////////
	= Enable\Disable =
*////////////////////////
Director()
{
	g_CvarZombie = GetConVarInt(g_zombie);

	if (g_CvarZombie == 1){
		DirectorEnable(true);
	}
	else if (g_CvarZombie == 0){
		DirectorEnable(false);
	}
}

DirectorEnable(bool:status)
{
	if (status){
		SetConVarInt(bosses, 1);
		SetConVarInt(specials, 1);
		SetConVarInt(mobs, 1);
		SetConVarInt(zombie, 0);
	}
	else {
		SetConVarInt(bosses, 0);
		SetConVarInt(specials, 0);
		SetConVarInt(mobs, 0);
		ResetConVar(zombie);
	}
}

Plugin()
{
	g_CvarEnable = GetConVarInt(g_enable);

	if (block5 == false && g_CvarEnable == 1){

		#if debug
		CPrintToChatAll("%s HookEvent", TAG);
		#endif

		ExpandedEditionEnable();// SuperBoss
		HookEvent("tank_killed", TankKilled);
		HookEvent("round_start", RoundStart);
		HookEvent("create_panic_event", PanicEvent);
		HookEvent("tank_spawn", NewTank);
		block4 = false;
		block5 = true;
	}
	else if (block5 == true && g_CvarEnable == 0){

		#if debug
		CPrintToChatAll("%s UnhookEvent", TAG);
		#endif

		Triger();// kill timer
		ResetConVar(tankhp);
		UnhookEvent("tank_killed", TankKilled);
		UnhookEvent("round_start", RoundStart);
		UnhookEvent("create_panic_event", PanicEvent);
		UnhookEvent("tank_spawn", NewTank);
		block4 = true;
		block5 = false;
	}
}

ResetValues()
{
	//reset
	TankLive = 0;
	TankCount = 0;
	TankRound = 0;
	n = 0;
	m = 0;
	club = false;
	block = false;
	block3 = false;
	//kill timer
	Triger();
	//reset hp
	SetConVarInt(tankhp, g_CvarHealth);
	//start timer
	MsgTimer=CreateTimer(15.0, PrintMsg, _, TIMER_REPEAT);
	Director();
	ExpandedEditionEnable();

	#if debug
	CPrintToChatAll("%s Restart_Round: TankHp = {green}%d{default}, TankCount = {green}%d{default}, TankRound = {green}%d{default}, TankLive = {green}%d", TAG, GetConVarInt(tankhp), TankCount, TankRound, TankLive);
	#endif
}

/*=========================
	= CheatCommand code =
==========================*/
CheatCommand(client, const String:command[], const String:arguments[]="")
{
	if (!client) return;
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

GetRandomClient()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			return i;
	return 0;
}