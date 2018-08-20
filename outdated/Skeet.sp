#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <left4downtown_l4d2>

public Plugin:myinfo =
{
	name = "Skeet",
	author = "raziEiL [disawar1]",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public Action:L4D_OnShovedBySurvivor(client, victim, const Float:vector[3])
{
	PrintToChat(client, "Your M2 is useless now");
	return Plugin_Handled;
}
