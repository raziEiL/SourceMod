#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <left4dhooks>
#include <l4d_lib>

#define DEBUG 0
#define PAIN_SOUND_LEN 54
#define L4D_Z_MULT 1.6
#define HAS_BIT(%0,%1,%2) (%0 && %1 & (1 << %2))
// --------------------------------------------------------------
// CONST
// --------------------------------------------------------------
static const int SOUND_MIN = 1;
static const int SOUND_MAX[sizeof(L4D2_LIB_SURVIVOR_CHARACTER)] = {7 ,4, 8, 6, 9, 7, 11, 5};
static const char FORMAT_PAIN_SOUND[] = "player/survivor/voice/%s/hurtcritical0%d.wav";

static const char FORMAT_MESSAGE_1C[] = "\x04%N\x01 was \x02%s\x01 by \x04%N\x01!";
static const char FORMAT_MESSAGE_1[] = "%N was %s by %N!";
static const char FORMAT_MESSAGE_2C[] = "\x01You \x02%s \x04%N";
static const char FORMAT_MESSAGE_2[] = "You %s %N";
static const char FORMAT_MESSAGE_3C[] = "\x01Got \x02%s by \x04%N!";
static const char FORMAT_MESSAGE_3[] = "Got %s by %N!";
static const char FORMAT_MESSAGE_TYPE[][] = {"shoved", "slapped"};

static const char INFECTED_CLAW[][]=
{
	"",
	"smoker_claw",
	"boomer_claw",
	"hunter_claw",
	"spitter_claw",
	"jockey_claw",
	"charger_claw"
};
// --------------------------------------------------------------
// GLOBAL VARS
// --------------------------------------------------------------
bool g_bCvarEnabled;
int g_iCvarSlapFlags, g_iCvarShoveFlags, g_iCvarIncapFlags, g_iCvarAnnounce;
float g_fCvarPower, g_fCvarZMult, g_fCvarCooldown, g_fLastSlapTime[MPS];
// --------------------------------------------------------------
// CORE
// --------------------------------------------------------------
public Plugin myinfo =
{
	name = "[L4D & L4D2] Special Infected Ability",
	author = "raziEiL [disawar1]",
	description = "Provides to Special Infected the ability to slap and shove Survivors.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public void OnPluginStart()
{
	CreateConVar("l4d_si_ability_version", PLUGIN_VERSION, "L4D & L4D2 Special Infected Slap/Shove Ability Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cVar = CreateConVar("l4d_si_ability_enabled", "1", "Enable/Disable the Special Infected Slap/Shove Ability Plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCvarEnabled = cVar.BoolValue;
	cVar.AddChangeHook(OnCvarChange_Enabled);

	cVar = CreateConVar("l4d_si_ability_power", "150", "How much force is applied to the victim (Slap ability).", FCVAR_NOTIFY, true, 0.0);
	g_fCvarPower = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_Power);

	cVar = CreateConVar("l4d_si_ability_vertical_mult", "1.5", "Vertical force multiplier (Slap ability).", FCVAR_NOTIFY, true, 0.0);
	g_fCvarZMult = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_ZMult);

	cVar = CreateConVar("l4d_si_ability_cooldown", "1.0", "0=Off, >0: Seconds before SI can slap/shove again.", FCVAR_NOTIFY, true, 0.0);
	g_fCvarCooldown = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_Cooldown);

	cVar = CreateConVar("l4d_si_ability_announce", "1", "0=Off, 1=Chat, 2=Center chat, 3=Hint.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_iCvarAnnounce = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_Announce);

	cVar = CreateConVar("l4d_si_ability_incap", "68", "Slapping incapacitating people. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Boomer|Charger.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarIncapFlags = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_IncapFlags);

	cVar = CreateConVar("l4d_si_ability_slap", "68", "Special Infected who can slap. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Boomer|Charger.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarSlapFlags = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_SlapFlags);

	cVar = CreateConVar("l4d_si_ability_shove", "18", "Special Infected who can shove. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Smoker|Spitter.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarShoveFlags = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_ShoveFlags);

	HookEvent("player_hurt", Event_PlayerHurt);
	AutoExecConfig(true, "l4d_si_ability");
#if DEBUG
	RegServerCmd("sm_si_ability_cvar", CommandCvar);
	RegServerCmd("sm_si_ability_test", CommandTest);
#endif
}

public void OnMapStart()
{
	char painSound[PAIN_SOUND_LEN];
	for (int i; i < sizeof(L4D2_LIB_SURVIVOR_CHARACTER); i++){
		for (int n = SOUND_MIN; n <= SOUND_MAX[i]; n++){
			FormatEx(SZF(painSound), FORMAT_PAIN_SOUND, L4D2_LIB_SURVIVOR_CHARACTER[i], n);
#if DEBUG
			PrintToServer("%d, %s", PrecacheSound(painSound, true), painSound);
#else
			PrecacheSound(painSound, true);
#endif
		}
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarEnabled) return;

	int slapper = CID(event.GetInt("attacker"));
	if (!IsInfectedAndInGame(slapper) || !CanSlapAgain(slapper)) return;

	int target = CID(event.GetInt("userid"));
	if (!IsSurvivorAndInGame(target)) return;

	int class = GetPlayerClass(slapper);
	bool bIncaped = IsIncaped(target);
	bool bSlap = HAS_BIT(!bIncaped, g_iCvarSlapFlags, class) || HAS_BIT(bIncaped, g_iCvarIncapFlags, class);

	if (!(bSlap || HAS_BIT(!bIncaped, g_iCvarShoveFlags, class))) return;

	char sWeapon[14];
	event.GetString("weapon", SZF(sWeapon));

	if (sWeapon[0] && StrEqual(sWeapon, INFECTED_CLAW[class]))
	{
		if (g_iCvarAnnounce && !IsFakeClient(target))
			Print(slapper, target, bSlap);

		PlaySurvivorPainSound(target);

		if (bSlap){
			// math code by AtomicStryker https://forums.alliedmods.net/showthread.php?t=97952
			float HeadingVector[3], resulting[3];
			GetClientEyeAngles(slapper, HeadingVector);
			GetEntPropVector(target, Prop_Data, "m_vecVelocity", resulting);

			resulting[0] += Cosine(DegToRad(HeadingVector[1])) * g_fCvarPower;
			resulting[1] += Sine(DegToRad(HeadingVector[1])) * g_fCvarPower;
			resulting[2] = g_fCvarPower * g_fCvarZMult;

			if (IsL4DGameEx()){
				resulting[2] *= L4D_Z_MULT;
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
			}
			else
				L4D2_CTerrorPlayer_Fling(target, slapper, resulting);
		}
		else {
			float fPos[3];
			GetClientAbsOrigin(slapper, fPos);
			L4D_StaggerPlayer(target, slapper, fPos);
		}
		if (g_fCvarCooldown)
			g_fLastSlapTime[slapper] = GetEngineTime();
#if DEBUG
		SetEntityHealth(target, 100);
#endif
	}
}
// AcceptEntityInput(target, "DisableLedgeHang");
bool CanSlapAgain(int client)
{
	return g_fCvarCooldown ? ((GetEngineTime() - g_fLastSlapTime[client]) > g_fCvarCooldown) : true;
}

void PlaySurvivorPainSound(int target)
{
	int strIndex = GetCharStrIndex(target);
	if (strIndex < 0) return;

	char painSound[PAIN_SOUND_LEN];
	FormatEx(SZF(painSound), FORMAT_PAIN_SOUND, L4D2_LIB_SURVIVOR_CHARACTER[strIndex], GetRandomInt(SOUND_MIN, SOUND_MAX[strIndex]));

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			EmitSoundToClient(i, painSound, target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
}

void Print(int slapper, int target, bool type, bool allChat = true)
{
	switch (g_iCvarAnnounce)
	{
		case 1:
		{
			if (allChat)
				PrintToChatAll(FORMAT_MESSAGE_1C, target, FORMAT_MESSAGE_TYPE[type], slapper);
			else {
				PrintToChat(slapper, FORMAT_MESSAGE_2C, FORMAT_MESSAGE_TYPE[type], target);
				PrintToChat(target, FORMAT_MESSAGE_3C, FORMAT_MESSAGE_TYPE[type], slapper);
			}
		}
		case 2:
		{
			if (allChat)
				PrintCenterTextAll(FORMAT_MESSAGE_1, target, FORMAT_MESSAGE_TYPE[type], slapper);
			else {
				PrintCenterText(slapper, FORMAT_MESSAGE_2, FORMAT_MESSAGE_TYPE[type], target);
				PrintCenterText(target, FORMAT_MESSAGE_3, FORMAT_MESSAGE_TYPE[type], slapper);
			}
		}
		case 3:
		{
			if (allChat)
				PrintHintTextToAll(FORMAT_MESSAGE_1, target, FORMAT_MESSAGE_TYPE[type], slapper);
			else {
				PrintHintText(slapper, FORMAT_MESSAGE_2, FORMAT_MESSAGE_TYPE[type], target);
				PrintHintText(target, FORMAT_MESSAGE_3, FORMAT_MESSAGE_TYPE[type], slapper);
			}
		}
	}
}
// --------------------------------------------------------------
// CONVARS
// --------------------------------------------------------------
public void OnCvarChange_Enabled(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_bCvarEnabled = cVar.BoolValue;
}

public void OnCvarChange_Power(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarPower = cVar.FloatValue;
}

public void OnCvarChange_ZMult(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarZMult = cVar.FloatValue;
}

public void OnCvarChange_Cooldown(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarCooldown = cVar.FloatValue;
}

public void OnCvarChange_Announce(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarAnnounce = cVar.IntValue;
}

public void OnCvarChange_IncapFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarIncapFlags = cVar.IntValue;
}

public void OnCvarChange_SlapFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarSlapFlags = cVar.IntValue;
}

public void OnCvarChange_ShoveFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarShoveFlags = cVar.IntValue;
}
// --------------------------------------------------------------
// DEBUG
// --------------------------------------------------------------
#if DEBUG
// blocks si ability
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_ATTACK && IsInfected(client) && IsFakeClient(client))
		buttons &= ~IN_ATTACK;
	return Plugin_Continue;
}

public Action CommandCvar(int args)
{
	PrintToServer("l4d test");
	for (int i = ZC_SMOKER; i <= ZC_HUNTER; i++){
		PrintToServer("%d. fling %d, stagger %d, %s", i, g_iCvarSlapFlags & (1 << i), g_iCvarShoveFlags  & (1 << i), L4D_LIB_INFECTED_CHARACTER_NAME[i]);
	}
	PrintToServer("l4d2 test");
	for (int i = ZC2_SMOKER; i <= ZC2_CHARGER; i++){
		PrintToServer("%d. fling %d, stagger %d, %s", i, g_iCvarSlapFlags & (1 << i), g_iCvarShoveFlags  & (1 << i), L4D2_LIB_INFECTED_CHARACTER_NAME[i]);
	}
}

enum (<<= 1)
{
	BIT_SMOKER = 2,
	BIT_BOOMER,
	BIT_HUNTER,
	BIT_SPITTER,
	BIT_JOCKEY,
	BIT_CHARGER
}

#define CONDITION(%0,%1,%2,%3,%4) (HAS_BIT(!%0,%2,%1) || HAS_BIT(%0,%3,%1) || HAS_BIT(!%0,%4,%1))

public Action CommandTest(int args)
{
	PrintToServer("%d, %d, %d, %d, %d, %d", BIT_SMOKER, BIT_BOOMER, BIT_HUNTER, BIT_SPITTER, BIT_JOCKEY, BIT_CHARGER);

	int cvarSlap, cvarIncap, cvarShove;
	bool bIncap;
	// ---------------------TEST 1: bIncap = false-------------------------------
	bIncap = false;
	cvarIncap = 0;
	cvarSlap = 0;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		PrintToServer("#1 Test %s [%s]", CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove) ? "not passed!"  : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 2: bIncap = true-------------------------------
	bIncap = true;
	cvarIncap = 0;
	cvarSlap = 0;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		PrintToServer("#2 Test %s [%s]", CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove) ? "not passed!"  : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 3: cvarIncap-------------------------------
	bIncap = true;
	cvarIncap = BIT_BOOMER;
	cvarSlap = 0;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#3 Test %s [%s]", class != ZC2_BOOMER ? "not passed!" : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 4: cvarSlap-------------------------------
	bIncap = false;
	cvarIncap = BIT_SMOKER|BIT_HUNTER;
	cvarSlap = BIT_BOOMER;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#4 Test %s [%s]", class != ZC2_BOOMER ? "not passed!" : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 5: cvarShove-------------------------------
	bIncap = false;
	cvarIncap = BIT_SMOKER|BIT_HUNTER;
	cvarSlap = 0;
	cvarShove = BIT_BOOMER;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++){
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#5 Test %s [%s]", class != ZC2_BOOMER ? "not passed!" : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	}
	// --------------------TEST 6: cvarIncap|cvarShove|cvarShove-------------------------------
	bIncap = true;
	cvarIncap = BIT_SMOKER;
	cvarSlap = BIT_HUNTER;
	cvarShove = BIT_BOOMER;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++){
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#6 Test %s [%s]", (class == ZC2_BOOMER || class == ZC2_SMOKER || class == ZC2_HUNTER) ? "passed!" : "not passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	}
}
#endif
