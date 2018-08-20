#define PLUGIN_VERSION "1.0"

#include <sourcemod>

public Plugin:myinfo =
{
	name = "Witch Stats",
	author = "raziEiL [disawar1]",
	description = "Plugin print demage dealt to witch",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static		g_iDmg[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintDmgToWitch(true);
	WipeStats();
}

public Action:Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientAndInGame(client)){

		if (GetEventBool(event, "oneshot")){

			PrintToChat(client, "You dealt %d dmg per oneshot!", g_iDmg[client]);
			WipeStats();
		}
		else
			PrintDmgToWitch();
	}
}

public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsClientAndInGame(attacker) && GetClientTeam(attacker) == 2 && IsWitch(GetEventInt(event, "entityid")))
		g_iDmg[attacker] += GetEventInt(event, "amount");
}

PrintDmgToWitch(bool:bRoundEnd = false)
{
	new survivors, players[MAXPLAYERS+1][2], totaldmg;

	for (new i = 1; i <= MaxClients; i++){

		if (!g_iDmg[i] || !IsClientInGame(i) || GetClientTeam(i) != 2) continue;

		players[survivors][0] = i;
		players[survivors][1] = g_iDmg[i];
		survivors++;

		totaldmg += g_iDmg[i];
	}
	if (survivors == 0) return;

	SortCustom2D(players, survivors, SortByDamageDesc);

	for (new i; i < survivors; i++)
	{
		new client = players[i][0];
		PrintToChatAll(" %d (%d%%): %N", g_iDmg[client], (RoundFloat(float(g_iDmg[client]) / 1000.0 * 100.0)), client);
		g_iDmg[client] = 0;
	}

	if (bRoundEnd)
		PrintToChatAll("Witch had %d health remaining", 1000 - totaldmg);
	else
		PrintToChatAll("Damage dealt to witch");
}

public SortByDamageDesc(x[], y[], const array[][], Handle:hndl)
{
	if (x[1] < y[1])
		return -1;
	else if (x[1] == y[1])
		return 0;
	return 1;
}

bool:IsClientAndInGame(index)
{
	return index && index <= MaxClients && IsClientInGame(index);
}

bool:IsWitch(entity)
{
	decl String:sClassName[64]
	GetEntityClassname(entity, sClassName, 64);
	return strcmp(sClassName, "witch") == 0;
}

WipeStats()
{
	for (new i = 1; i <= MaxClients; i++)
		g_iDmg[i] = 0;
}