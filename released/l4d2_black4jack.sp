#define PLUGIN_VERSION "1.1"
/*
	_______________________¶¶¶¶___¶¶¶¶¶
	_____________________¶¶____¶¶¶____¶¶__¶¶¶
	___________________¶¶___¶¶¶____¶¶¶¶¶¶¶___¶¶
	_________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
	______________¶¶¶¶¶__¶__________________________¶¶
	___________¶¶¶¶__¶¶__¶___________________________¶
	_________¶¶¶_¶¶__¶__¶¶¶__________________________¶
	______¶¶¶_¶¶_¶¶¶_¶_¶¶_¶¶_________¶_______________¶
	_____¶_¶¶__¶_¶_¶¶¶¶_¶¶¶__________¶¶______________¶
	___¶¶¶_¶¶¶¶¶_¶¶¶¶¶¶_¶¶¶_________¶¶¶______________¶
	_¶¶__¶¶¶¶¶¶¶¶_¶¶_¶¶____________¶¶¶¶¶_____________¶
	¶_¶¶__¶__¶¶¶¶____¶¶___________¶¶¶¶¶¶¶____________¶
	¶__¶¶¶¶¶¶¶¶¶¶____¶¶__________¶¶¶¶¶¶¶¶¶¶__________¶
	_¶¶¶_¶_¶¶___¶¶___¶¶________¶¶¶¶¶¶¶¶¶¶¶¶¶_________¶
	__¶¶_¶¶_¶___¶¶___¶¶______¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_______¶
	___¶¶____¶___¶___¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_____¶
	____¶¶___¶¶__¶¶__¶¶___¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶___¶
	_____¶¶___¶__¶¶__¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__¶
	______¶¶___¶__¶__¶¶_¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_¶
	_______¶¶__¶¶_¶__¶¶_¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_¶
	________¶¶__¶_¶¶_¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_¶
	_________¶¶__¶_¶_¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__¶
	__________¶¶_¶¶¶_¶¶___¶¶¶¶¶¶¶¶¶__¶¶__¶¶¶¶¶¶¶¶¶___¶
	____________¶_¶¶_¶¶_____¶¶¶¶¶____¶¶____¶¶¶¶¶_____¶
	_____________¶_¶¶¶¶___________¶¶¶¶¶¶¶¶___________¶
	______________¶¶¶¶¶__________¶¶¶¶¶¶¶¶¶¶______¶¶__¶
	_______________¶¶¶____________¶¶¶¶¶¶¶¶_______¶¶¶_¶
	________________¶¶__________________________¶¶_¶_¶
	_________________¶¶__________________________¶¶__¶
	_________________¶¶__________________________¶¶¶_¶
	__________________¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
	__________________¶¶¶¶¶¶¶¶¶¶¶¶
	_____________________¶¶¶¶¶¶
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#pragma semicolon 1

/*=====================
 баг с игрой когда ты повис
        $ Tag $
=======================*/
#define FC  	  "{blue}[{green}Black4Jack{blue}]{default}"
#define TAG		  "[debug]"

#define debug 0 // on,off
#if debug
#endif
/*=====================
        $ Sound $
=======================*/
#define BlackJack "ambient/materials/ripped_screen01.wav"
#define NotNow "ambient/water/distant_drip2.wav"
#define Win "level/gnomeftw.wav"
#define Push "level/loud/bell_break.wav"
#define Lose "music/bacteria/hunterbacteria.wav"

#define BlackJack1 "ambient/materials/wood_creak4.wav"
#define Win1 "buttons/bell1.wav"
#define Push1 "buttons/button11.wav"

/*=====================
	   $ ConVar $
=======================*/
new		Handle:MsgTimer[MAXPLAYERS + 1], Handle:g_BJbet, Handle:g_HpLimit, Handle:g_Chance, Handle:g_Hud;

new		playercard[MAXPLAYERS + 1],  dealer[MAXPLAYERS + 1], card, card2, PlayerHp, g_CvarBet, Hp,
		g_CvarHpLimit, g_CvarChance, g_CvarHud, g_boomer;

new		bool:pass[MAXPLAYERS + 1], bool:passblock[MAXPLAYERS + 1],  bool:dilerpass[MAXPLAYERS + 1],
		bool:hpblock[MAXPLAYERS + 1], bool:invite[MAXPLAYERS + 1], bool:incapblock[MAXPLAYERS + 1],
		bool:ledgeblock[MAXPLAYERS + 1], bool:g_l4d1, bool:hook;

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Black 4 Jack",
	author = "raziEiL [disawar1]",
	description = "The card game for man!",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

/*=====================
	$ PLUGIN START! $
=======================*/
public OnPluginStart()
{
/*
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	g_l4d1 = false;
	if (StrEqual(game, "left4dead"))
			g_l4d1 = true;
*/
	g_BJbet = CreateConVar("black_jack_bet", "10", "Player's bet in his health", FCVAR_PLUGIN);
	g_HpLimit = CreateConVar("black_jack_health", "100", "You cannot Win more health than this limit!", FCVAR_PLUGIN);
	g_Chance = CreateConVar("black_jack_chance", "50", "Chance to spawn witch or boomer when player lose", FCVAR_PLUGIN);
	g_Hud = CreateConVar("black_jack_menu", "1", "Show BJ game menu to player", FCVAR_PLUGIN);
	//AutoExecConfig(true, "l4d2_Black4Jack");

	HookConVarChange(g_BJbet, OnCVarChange);
	HookConVarChange(g_HpLimit, OnCVarChange);
	HookConVarChange(g_Chance, OnCVarChange);
	HookConVarChange(g_Hud, OnCVarChange);

	HookEvent("player_incapacitated", BlackJackIncapLock);
	HookEvent("revive_success", BlackJackIncapUnLock);
	HookEvent("round_start", RoundStart);
	HookEvent("player_ledge_grab", LedgeGrab);

	RegConsoleCmd("bj", CmdBlakJack, "Play Blackjack");
	RegConsoleCmd("pass", CmdPass, "Blackjack Pass");
	//RegConsoleCmd("invite", CmdInvite, "Play Blackjack with someone");
	RegAdminCmd("kj", CmdKillJack, ADMFLAG_KICK, "Cancel all BJ game");
}

public OnMapStart()
{
	if (g_l4d1)
	{
		PrecacheSound(BlackJack1, true);
		PrecacheSound(Win1, true);
		PrecacheSound(Push1, true);
	}
	else
	{
		PrecacheSound(BlackJack, true);
		PrecacheSound(Win, true);
		PrecacheSound(Push, true);
	}
	PrecacheSound(Lose, true);
	PrecacheSound(NotNow, true);
	GameisOverForAll();
}
/*=====================
	  $ Message $
=======================*/
public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client)){
		new clientID = GetClientUserId(client);
		CreateTimer(12.0, Welcome, clientID);
	}
}

public Action:Welcome(Handle:timer, any:client)
{
	#if debug
	CPrintToChatAll("%s Welcome Message", TAG);
	#endif
	client = GetClientOfUserId(client);
	if (client && IsClientInGame(client)  && GetClientTeam(client) != 3 && !IsFakeClient(client) && IsPlayerAlive(client))
	{

		CPrintToChat(client, "%s You can win a prize! bet - {blue}%dhp{default}. Type {olive}!bj{default}, {olive}!invite{default} in chat.", FC, g_CvarBet);

		#if debug
		CPrintToChatAll("%s Welcome Message 2", TAG);
		#endif
	}
}

public Action:Welcome2(Handle:timer, any:client)
{
	#if debug
	CPrintToChatAll("%s Welcome Message 2", TAG);
	#endif
	if (client && IsClientInGame(client)  && GetClientTeam(client) != 3 && !IsFakeClient(client) && IsPlayerAlive(client)){

		if (incapblock[client] == true || ledgeblock[client] == true)
		{
			CPrintToChat(client, "%s {blue}%N{default} you can help uself. Try to play BlackJack and win. Type {olive}!bj{default} in chat.", FC, client);
		}
	}
}

/*=====================
	  $ Events $
=======================*/
public LedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if debug
	CPrintToChatAll("%s LedgeGrab", TAG);
	#endif
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(5.0, Welcome2, client);
	ledgeblock[client]=true;
}

public BlackJackIncapLock(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if debug
	CPrintToChatAll("%s BlackJackIncapLock", TAG);
	#endif
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (BlackAndWhite(client))
		CreateTimer(5.0, Welcome2, client);
	incapblock[client]=true;
	GameisOver(client);
}

public BlackJackIncapUnLock(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if debug
	CPrintToChatAll("%s BlackJackIncapUnLock", TAG);
	#endif
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	incapblock[client]=false;
	ledgeblock[client]=false;
	GameisOver(client);
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	GameisOverForAll();
}
bool:ICantPlay(client)
{
	if (pass[client] == true){
		CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client);
		return true;
	}
	else if (GetClientTeam(client) != 2){
		CPrintToChat(client, "%s {blue}%N{default} Zombie cant play in BJ!", FC, client);
		return true;
	}
	else if (!IsPlayerAlive(client)){
		CPrintToChat(client, "%s {blue}%N{default} Deadman cant play in BJ :)", FC, client);
		return true;
	}
	else if (PlayerHp <= g_CvarBet){
		CPrintToChat(client, "%s {blue}%N{default} Not health - no game.", FC, client);
		return true;
	}

	// incap game
	new IncapValue=g_CvarBet*3;

	if (PlayerHp <= IncapValue && hpblock[client] == false)
	{
		CPrintToChat(client, "%s {blue}%N{default} Not health - no game. incap", FC, client);
		return true;
	}
	return false;
}

bool:BlackAndWhite(client)
{
	if (ledgeblock[client] == true) return true;
	new offset = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	new x = GetEntData(client, offset, 1);
	if (x == 0)
		return true;
	return false;
}

/*=====================
	  $ Command $
=======================*/
public Action:CmdBlakJack(client, agrs)
{
/*
	new offset = FindSendPropOffs("CTerrorPlayer","m_isHangingFromLedge");
	new offset2 = FindSendPropOffs("CTerrorPlayer","m_isIncapacitated");
	new offset3 = FindSendPropOffs("CTerrorPlayer","m_reviveOwner");
	SetEntData(client, offset, 0, 1);
	SetEntData(client, offset2, 1, 1);
	SetEntData(client, offset3, 0, 1);
*/
	PlayerHp=GetClientHealth(client);
	Hp=PlayerHp-g_CvarBet;
	new IncapValue=g_CvarBet*3;

	if (incapblock[client] == false && ledgeblock[client] == false)
	{
		if (ICantPlay(client))
		{
			EmitSoundToClient(client, NotNow);
			return Plugin_Handled;
		}
		if (PlayerHp > g_CvarBet && hpblock[client] == false)
		{
			SetEntProp(client, Prop_Send, "m_iHealth", Hp);
			hpblock[client]=true;
		}
	}
/*												+--------------------------------+
												|			If Inacaped			 |
												+--------------------------------+
*/
	if (incapblock[client] == true || ledgeblock[client] == true)
	{
		if (!BlackAndWhite(client) || ICantPlay(client))
		{
			CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client);
			EmitSoundToClient(client, NotNow);
			return Plugin_Handled;
		}
		if (PlayerHp > IncapValue && hpblock[client] == false)
		{
			new IncapHp=PlayerHp-g_CvarBet*3;
			SetEntProp(client, Prop_Send, "m_iHealth", IncapHp);
			hpblock[client]=true;
		}
	}
//														*sound*
	if (g_l4d1) EmitSoundToClient(client, BlackJack1);
	else if (!g_l4d1) EmitSoundToClient(client, BlackJack);

	PlayerIdle(client);
/*												+--------------------------------+
												|		Player vs Dealer		 |
												+--------------------------------+
*/
	if (invite[client] == false)
	{
		if (dilerpass[client] == false)
		{
			card2=GetRandomInt(1, 11);
			dealer[client]+=card2;
		}
		card=GetRandomInt(1, 11);
		playercard[client]+=card;

		#if debug
		CPrintToChat(client, "%s incapblock=%d, ledgeblock=%d", TAG, incapblock[client], ledgeblock[client]);
		#endif


		PlayingField(client);

		if (dealer[client] >= 17 && dilerpass[client] == false)
		{
			CPrintToChat(client, "%s Dealer - Pass!", FC, dealer[client]);
			dilerpass[client]=true;
		}
	}
/*												+--------------------------------+
												|		Player vs Player		 |
												+--------------------------------+
*/
	if (invite[client] == true)
	{
		card=GetRandomInt(1, 11);
		playercard[client]+=card;
		PlayingField(client);
	}
	if (g_CvarHud == 1)
		BJMenu(client);
	return Plugin_Handled;
}

public Action:CmdPass(client, agrs)
{
	if (pass[client] == true || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client);
		EmitSoundToClient(client, NotNow);
		return Plugin_Handled;
	}
/*												+--------------------------------+
												|		Player vs Dealer		 |
												+--------------------------------+
*/
	if (invite[client] == false)
	{
		if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 20 && dilerpass[client]==false)
		{
			pass[client]=true;
			passblock[client]=true;
			PlayerIdle(client);

			new x=playercard[client];

			for (new i=dealer[client]; i <= x; i+=card2)
			{
				card2=GetRandomInt(1, 11);
				dealer[client]+=card2;

				#if debug
				CPrintToChat(client, "%d +%d", dealer[client], card2);
				#endif
			}
			CPrintToChat(client, "%s {blue}%N{default} - Pass!", FC, client);
			PlayingField(client);
		}
		else if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 21)
		{
			pass[client]=true;
			passblock[client]=true;
			PlayerIdle(client);
			CPrintToChat(client, "%s {blue}%N{default} - Pass!", FC, client);
			PlayingField(client);
		}
		else if (playercard[client] > dealer[client] && dilerpass[client]==true)
		{
			pass[client]=true;
			PlayerIdle(client);
			CPrintToChat(client, "%s {blue}%N{default} - Pass!", FC, client);
			if (g_l4d1) EmitSoundToClient(client, Win1);
			else if (!g_l4d1) EmitSoundToClient(client, Win);
			GetBackMyHp(client);
			GameisOver(client);
		}
		else
		{
			CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client);
			EmitSoundToClient(client, NotNow);
			return Plugin_Handled;
		}
	}
/*												+--------------------------------+
												|		Player vs Player		 |
												+--------------------------------+
*/
	if (invite[client] == true)
	{
		pass[client]=true;
		PlayingField(client);
	}
	return Plugin_Handled;
}

public Action:CmdInvite(client, agrs)
{
	PlayerHp=GetClientHealth(client);
	if (playercard[client] != 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || invite[client] == true || PlayerHp <= g_CvarBet && hpblock[client] == false || incapblock[client] == true)
	{
		CPrintToChat(client, "%s {blue}%N{default} not NoW!", FC, client);
		EmitSoundToClient(client, NotNow);
		return Plugin_Handled;
	}
	else
	{
		invite[client]=true;
		PlayerIdle(client);
		CPrintToChat(client, "%s {blue}%N{default} confirm! say !bj to play.", FC, client);
		CSkipNextClient(client);
		CPrintToChatAll("%s {blue}%N{default} wants to play with someone, say {olive}!invite{default} to join.", FC, client);
	}
	return Plugin_Handled;
}

public Action:CmdKillJack(client, agrs)
{
	CPrintToChatAll("%s {olive}Admin has canceled all Games!", FC);
	GameisOverForAll();
	return Plugin_Handled;
}
/*=====================
		$ Timer $
=======================*/
public PlayerIdle(client)
{
	#if debug
	CPrintToChatAll("%s 1.PlayerIdle", TAG);
	#endif
	KillMsgTimer(client);// Player back, kill timer.
	new clientID=GetClientUserId(client);
	MsgTimer[client]=CreateTimer(55.0, CancelJack, clientID);// Player Idle, game is over!
}

public KillMsgTimer(client)
{
	if (MsgTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(MsgTimer[client]);
		MsgTimer[client] = INVALID_HANDLE;
	}
	#if debug
	CPrintToChatAll("%s 2.KillMsgTimer", TAG);
	#endif
}

public Action:CancelJack(Handle:timer, any:client)
{
	#if debug
	CPrintToChatAll("%s 3.CancelJack", TAG);
	#endif
	client=GetClientOfUserId(client);
	if (client && IsClientInGame(client) && playercard[client] > 1 || invite[client] == true)
	{
		CPrintToChat(client, "%s {blue}%N{default} game was cancelled.", FC, client);
		GameisOver(client);
	}
	MsgTimer[client] = INVALID_HANDLE;
}

/*=====================
	  $ Game Over $
=======================*/
public GameisOver(client)
{
	if (IsClientInGame(client) && GetClientTeam(client) != 3 && !IsFakeClient(client)){

									/*-----------Reset-Player-Game--------------*/
		playercard[client]=0;		/* - Reset u cards 							*/
		dealer[client]=0; 			/* - Reset dealer cards 					*/
		pass[client]=false; 		/* - Block other cmd when u said !pass 		*/
		passblock[client]=false; 	/* - Unlock somethink ways in Algorithm 	*/
		dilerpass[client]=false; 	/* - Diler have more 17 he ceases to play 	*/
		hpblock[client]=false; 	/* - If u have to low health 				*/
		invite[client]=false; 		/* - If u play vs players 					*/
									/*------------------------------------------*/

		ClientCommand(client, "slot10");
	}
	#if debug
	CPrintToChatAll("%s 4.GameisOver", TAG);
	#endif
}

public GameisOverForAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) != 3 && !IsFakeClient(i)){

			playercard[i]=0;
			dealer[i]=0;
			pass[i]=false;
			passblock[i]=false;
			dilerpass[i]=false;
			hpblock[i]=false;
			invite[i]=false;
			incapblock[i]=false;
			ledgeblock[i]=false;
			ClientCommand(i, "slot10");
		}
	}
	#if debug
	CPrintToChatAll("%s GameisOverForAll", TAG);
	#endif
}

/*=====================
	$ Algorithm $
=======================*/
public PlayingField(client)
{
/*												+--------------------------------+
												|		Player vs Dealer		 |
												+--------------------------------+
*/
	if (invite[client] == false)
	{
		if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 21 && passblock[client]==true)
		{
			if (playercard[client] == dealer[client])
			{
				//CPrintToChat(client, "%s %d:%d - Push! lol", FC, playercard[client], dealer[client]);
				if (g_l4d1) EmitSoundToClient(client, Push1);
				else if (!g_l4d1) EmitSoundToClient(client, Push);
				GetBackMyHp(client);
				GameisOver(client);
			}
			else if (playercard[client] < dealer[client])
			{
				CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {olive}LOSE {default}:P", FC, playercard[client],dealer[client], client);
				EmitSoundToClient(client, Lose);
				PlayerLoseSpwanPrize(client);
				GameisOver(client);
			}
			else if (playercard[client] > dealer[client])
			{
				//CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN!", FC, playercard[client], dealer[client], client);
				if (g_l4d1) EmitSoundToClient(client, Win1);
				else if (!g_l4d1) EmitSoundToClient(client, Win);
				GetBackMyHp(client);
				GameisOver(client);
			}
		}
		else if (playercard[client] >= 17 && dealer[client] <= 21 && playercard[client] <= 20 && passblock[client]==false)
		{
			CPrintToChat(client, "%s %d:%d - take more? ;) !pass or !bj", FC, playercard[client], dealer[client]);
		}
		else if (playercard[client] > 21 || dealer[client] > 21)
		{
			if (playercard[client] > 21)
			{
				CPrintToChatAll( "%s %d Bust! - {blue}%N{default} is {olive}LOSE {default}:P", FC, playercard[client], client);
				EmitSoundToClient(client, Lose);
				PlayerLoseSpwanPrize(client);
				GameisOver(client);
			}
			else
			{
				//CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN!", FC, playercard[client], dealer[client], client);
				if (g_l4d1) EmitSoundToClient(client, Win1);
				else if (!g_l4d1) EmitSoundToClient(client, Win);
				GetBackMyHp(client);
				GameisOver(client);
			}
		}
		else if (playercard[client] <= 21)
		{
			if (playercard[client] <= 16 && dealer[client] <= 21)
			{
				if (dilerpass[client] == false)
					CPrintToChat(client, "%s %d - You, %d - Dealer.", FC, playercard[client], dealer[client]);
				else CPrintToChat(client, "%s %d - You, {blue}%d - Dealer.", FC, playercard[client], dealer[client]);
			}
			else if (playercard[client] == dealer[client] && playercard[client] == 21)
			{
				//CPrintToChat(client, "%s %d:%d - Push! lol", FC, playercard[client], dealer[client]);
				if (g_l4d1) EmitSoundToClient(client, Push1);
				else if (!g_l4d1) EmitSoundToClient(client, Push);
				GetBackMyHp(client);
				GameisOver(client);
			}
			else if (playercard[client] == 21 && dealer[client]!=21)
			{
				//CPrintToChatAll( "%s %d:%d - WoW {blue}%N{default} a {green}CHAMPION!", FC, playercard[client], dealer[client], client);
				if (g_l4d1) EmitSoundToClient(client, Win1);
				else if (!g_l4d1) EmitSoundToClient(client, Win);
				GetBackMyHp(client);
				GameisOver(client);
			}
		}
	}
/*												+--------------------------------+
												|		Player vs Player		 |
												+--------------------------------+
*/
	if (invite[client] == true)
	{
		new String:Message[256];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (invite[i] == true)
			{
				decl String:Name[MAX_NAME_LENGTH];
				GetClientName(i, Name, sizeof(Name));
				decl String:Card[10];
				decl String:chat[] = " - ";
				decl String:chat2[] = ", ";
				decl String:colorb[] = "{blue}";
				decl String:colord[] = "{default}";
				decl String:colorg[] = "{olive}";
				decl String:waiting[] = " waiting";
				IntToString(playercard[i], String:Card, sizeof(Card));
				if (pass[i] == false)
				{
					StrCat(String:Message, sizeof(Message), String:colorg);
					StrCat(String:Message, sizeof(Message), String:Card);
					StrCat(String:Message, sizeof(Message), String:colord);
					StrCat(String:Message, sizeof(Message), String:chat);
					StrCat(String:Message, sizeof(Message), String:colorb);
					StrCat(String:Message, sizeof(Message), String:Name);
					StrCat(String:Message, sizeof(Message), String:colord);
					if (playercard[i] >= 21) StrCat(String:Message, sizeof(Message), String:waiting);
					StrCat(String:Message, sizeof(Message), String:chat2);
				}
				if (pass[i] == true)
				{
					StrCat(String:Message, sizeof(Message), String:Card);
					StrCat(String:Message, sizeof(Message), String:chat);
					StrCat(String:Message, sizeof(Message), String:Name);
					StrCat(String:Message, sizeof(Message), String:chat2);
				}
			}
		}

		CPrintToChatAll("%s [%s]", FC, Message);
		if (playercard[client] >= 21)
		{
			pass[client] = true;
			//KillMsgTimer(client);
		}
	}
}

public GetBackMyHp(client)
{
	PlayerHp=GetClientHealth(client);
/*												+--------------------------------+
												|	  Give Prize \ vs Dieler	 |
												+--------------------------------+
*/
	if (incapblock[client] == false && ledgeblock[client] == false)
	{
		if (playercard[client] == 21 && playercard[client]!= dealer[client])
		{
			new CanGiveHp=g_CvarHpLimit-g_CvarBet*3;
			Hp=PlayerHp+g_CvarBet*3;

			if (PlayerHp <= CanGiveHp)
			{
				SetEntProp(client, Prop_Send, "m_iHealth", Hp);
				CPrintToChatAll( "%s %d:%d - WoW {blue}%N{default} a {green}CHAMPION! +%dhp", FC, playercard[client], dealer[client], client, g_CvarBet*3);
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", g_CvarHpLimit);
				CPrintToChatAll( "%s %d:%d - WoW {blue}%N{default} a {green}CHAMPION! +%dhp", FC, playercard[client], dealer[client], client, g_CvarHpLimit-PlayerHp);
			}
		}
		if (playercard[client] == dealer[client])
		{
			new CanGiveHp=g_CvarHpLimit-g_CvarBet;
			Hp=PlayerHp+g_CvarBet;

			if (PlayerHp <= CanGiveHp)
			{
				SetEntProp(client, Prop_Send, "m_iHealth", Hp);
				CPrintToChat(client, "%s %d:%d - Push! lol {green}+%dhp", FC, playercard[client], dealer[client], g_CvarBet);
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", g_CvarHpLimit);
				CPrintToChat(client, "%s %d:%d - Push! lol {green}+%dhp", FC, playercard[client], dealer[client], g_CvarHpLimit-PlayerHp);
			}
		}
		else if (playercard[client] != 21)
		{
			new CanGiveHp=g_CvarHpLimit-g_CvarBet*2;
			Hp=PlayerHp+g_CvarBet*2;

			if (PlayerHp <= CanGiveHp)
			{
				SetEntProp(client, Prop_Send, "m_iHealth", Hp);
				CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN! +%dhp", FC, playercard[client], dealer[client], client, g_CvarBet*2);
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", g_CvarHpLimit);
				CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN! +%dhp", FC, playercard[client], dealer[client], client, g_CvarHpLimit-PlayerHp);
			}
		}
	}
/*												+--------------------------------+
												|	   Give Prize \ Incaped		 |
												+--------------------------------+
*/
	if (incapblock[client] == true || ledgeblock[client] == true)
	{
		if (playercard[client] == dealer[client])
		{
			CPrintToChat(client, "%s %d:%d - Push! lol", FC, playercard[client], dealer[client]);
		}
		else
		{
			CPrintToChatAll( "%s %d:%d - {blue}%N{default} is {green}WIN!", FC, playercard[client], dealer[client], client);

			if (incapblock[client] == true){
				CheatCommand(client, "give", "health");

				new IncapHp=GetClientHealth(client);
				Hp=IncapHp-100;

				SetEntProp(client, Prop_Send, "m_iHealth", Hp);

				new offset = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
				SetEntData(client, offset, 1, 1);
				/* silver souce
				new count = GetEntProp(client, Prop_Send, "m_currentReviveCount");
				SetEntProp(client, Prop_Send, "m_currentReviveCount", count+1);
				   end	*/
				incapblock[client]=false;
			}
			if (ledgeblock[client] == true){
				CheatCommand(client, "give", "health");

				//new xHp=GetClientHealth(client);
				//Hp=xHp-100;
				//SetEntProp(client, Prop_Send, "m_iHealth", Hp);

				// silver code
				/*
				g_hCvarDecayRate =FindConVar("pain_pills_decay_rate");
				g_hCvarGnomeRate =FindConVar("sv_healing_gnome_replenish_rate");


				new Float:fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
				new Float:fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
				fHealth -= (fGameTime - fHealthTime) * g_fCvarDecayRate;
				if( fHealth < 0.0 )
				fHealth = 0.0;

				new Float:fBuff = (0.1 * g_fCvarGnomeRate);

				if( fHealth + iHealth + fBuff > 100 )
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 100.1 - float(iHealth));
				else
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth + fBuff);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
*/
				ledgeblock[client]=false;
			}
		}
	}
}

PlayerLoseSpwanPrize(client)
{
	if (GetRandomInt(0, 100) <= g_CvarChance)
	{
		decl Float:LoserPos[3], Float:ang_eye[3];
		new Float:distance = 50.0;
/*												+--------------------------------+
												|	 Loser Prize \ vs Dieler	 |
												+--------------------------------+
*/
		if (incapblock[client] == false && ledgeblock[client] == false)
		{
			new ent = CreateEntityByName("witch");
			if (ent != -1)
			{
				GetClientFrontLocation(client, LoserPos, ang_eye, distance);

				DispatchSpawn(ent);
				TeleportEntity(ent, LoserPos, ang_eye, NULL_VECTOR);
				SetEntPropFloat(ent, Prop_Send, "m_rage", 1.0); // agrs
				//SetEntProp(ent, Prop_Data, "m_nSequence", 4); // Sit
				CPrintToChatAll("%s but {olive}won{default} the consolation prize :)", FC);
			}
		}
/*												+--------------------------------+
												| 	  Loser Prize \ Incaped		 |
												+--------------------------------+
*/
		else if (incapblock[client] == true || ledgeblock[client] == true)
		{
			hook = true;
			CheatCommand(client, "z_spawn", "boomer");
			hook = false;

			GetClientAbsOrigin(client, LoserPos);

			LoserPos[2] += 80.0;
			LoserPos[1] += 20.0;

			TeleportEntity(g_boomer, LoserPos, NULL_VECTOR, NULL_VECTOR);
			CreateTimer(0.7, BlowBoomer);

			CPrintToChatAll("%s but {olive}won{default} the consolation prize :)", FC);
		}
	}
}
GetClientFrontLocation(client, Float:position[3], Float:angles[3], Float:distance = 50.0 )
{
	if (client > 0){

		decl Float:Origin[3], Float:Angles[3], Float:Direction[3];

		GetClientAbsOrigin(client, Origin);
		GetClientEyeAngles(client, Angles);
		GetAngleVectors(Angles, Direction, NULL_VECTOR, NULL_VECTOR );

		position[0] = Origin[0] + Direction[0] * distance;
		position[1] = Origin[1] + Direction[1] * distance;
		position[2] = Origin[2];

		angles[0] = 0.0;
		angles[1] = Angles[1] - 180.0;
		angles[2] = 0.0;
	}
}

public Action:BlowBoomer(Handle:timer)
{
	if (IsClientInGame(g_boomer) && g_boomer != -1)
		ForcePlayerSuicide(g_boomer);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (hook && strcmp(classname, "boomer") == 0)
	{
		if (entity > 0 && entity <= MaxClients)
		{
			g_boomer = entity;
		}
	}
}

CheatCommand(client, const String:command[], const String:arguments[]="")
{
	if (!client) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

BJMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler1);

	SetMenuTitle(menu, " %d : %d", playercard[client], dealer[client]);
	AddMenuItem(menu, "option1", "Get Card");
	if (playercard[client] >= 17)
		AddMenuItem(menu, "option2", "Say Pass");

	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				FakeClientCommand(client, "bj");
			}
			case 1:
			{
				FakeClientCommand(client, "pass");
			}
		}
	}
}

/*=====================
		$ Cvar $
=======================*/
public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}

GetCVars()
{
	g_CvarBet = GetConVarInt(g_BJbet);
	g_CvarHpLimit = GetConVarInt(g_HpLimit);
	g_CvarChance = GetConVarInt(g_Chance);
	g_CvarHud = GetConVarInt(g_Hud);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));

	if (!StrEqual(game, "left4dead", false) &&
		!StrEqual(game, "left4dead2", false) ||
		!IsDedicatedServer())
		return APLRes_Failure;
	if (StrEqual(game, "left4dead", false))
		g_l4d1 = true;
	return APLRes_Success;
}