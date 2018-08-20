#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

new bool:bLateLoad;

public Plugin:myinfo =
{
    name        = "Bash Kills",
    author      = "Jahze, raziEiL [disawar1]",
    version     = "1.0",
    description = "Stop special infected getting bashed to death"
}

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax) {
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart() {

	if ( bLateLoad ) {
		for ( new i = 1; i < MaxClients+1; i++ ) {
			if ( IsClientInGame(i) ) {
				SDKHook(i, SDKHook_OnTakeDamage, Hurt);
			}
		}
	}

	decl String:sGameFolder[64];
	GetGameFolderName(sGameFolder, 64);

	if (StrEqual(sGameFolder, "left4dead"))
		bLateLoad = true;
	else
		bLateLoad = false;
}

public OnClientPutInServer( client ) {
    SDKHook(client, SDKHook_OnTakeDamage, Hurt);
}

public Action:Hurt( victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3] ){

    if (damage != 250.0 || !IsSI(victim))
        return Plugin_Continue;

    if (((bLateLoad && !damageType && !weapon) || (!bLateLoad && damageType == 128 && weapon == -1)) && IsSurvivor(attacker))
        return Plugin_Handled;

    return Plugin_Continue;
}

bool:IsSI( client ) {
    if ( GetClientTeam(client) != 3 || !IsPlayerAlive(client) ) {
        return false;
    }
    new class = GetEntProp(client, Prop_Send, "m_zombieClass");
    if (class == 2  || (bLateLoad && class == 5) || (!bLateLoad && class == 8)) {
        return false;
    }
    
    return true;
}

bool:IsSurvivor( client ) {
    if ( client < 1
    ||  client > MaxClients
    || !IsClientInGame(client)
    || GetClientTeam(client) != 2
    || !IsPlayerAlive(client) ) {
        return false;
    }
    
    return true;
}
