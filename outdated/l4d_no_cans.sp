#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MAX_CAN_NAMES       3

new Handle:cvar_noCans;

static const String:CAN_MODEL_NAMES[MAX_CAN_NAMES][] = {
    "models/props_junk/gascan001a.mdl",
    "models/props_junk/propanecanister001a.mdl",
    "models/props_equipment/oxygentank01.mdl"
};

public Plugin:myinfo =
{
    name        = "L4D2 Remove Cans",
    author      = "Jahze fixed by raziEiL [disawar1]",
    version     = "0.1",
    description = "Removes oxygen, propane and gas cans"
}

public OnPluginStart() {
    cvar_noCans = CreateConVar("l4d_no_cans", "1", "Removes oxygen, propane and gas cans", FCVAR_PLUGIN);
    HookConVarChange(cvar_noCans, NoCansChange);
    HookEv();
}



static bool:bHook;

HookEv()
{
	if (!bHook && GetConVarBool(cvar_noCans)){
		HookEvent("round_start", RoundStartHook);
		bHook = true;
	}
	else if (bHook && !GetConVarBool(cvar_noCans)){
		UnhookEvent("round_start", RoundStartHook);
		bHook = false;
	}
}

public NoCansChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
	 HookEv();
}

IsCan( iEntity ) {
    decl String:sModelName[128];
    
    GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
    
    for ( new i = 0; i < MAX_CAN_NAMES; i++ ) {
        if ( StrEqual(sModelName, CAN_MODEL_NAMES[i], false) ) {
            if ( bool:GetEntProp(iEntity, Prop_Send, "m_isCarryable", 1) ) {
                return true;
            }
        }
    }
    
    return false;
}

public Action:RoundStartHook( Handle:event, const String:name[], bool:dontBroadcast ) {
    CreateTimer(1.0, RoundStartNoCans);
}

public Action:RoundStartNoCans( Handle:timer ) { 
    new iEntity;
    
    while ( (iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1 ) {
        if ( !IsValidEdict(iEntity) || !IsValidEntity(iEntity) ) {
            continue;
        }
        
        // We found a gas can
        if ( IsCan(iEntity) ) {
            AcceptEntityInput(iEntity, "Kill");
        }
    }
}
