#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Simple Anti-Bunnyhop",
	author = "CanadaRox, ProdigySim, blodia, raziEiL [disawar1]",
	description = "Stops bunnyhops by restricting speed when a player lands on the ground to their MaxSpeed",
	version = "0.1",
	url = "https://bitbucket.org/CanadaRox/random-sourcemod-stuff/"
};


#define DEBUG 0

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static Float:LeftGroundMaxSpeed[MAXPLAYERS + 1];

	if (IsPlayerAlive(client))
	{
		if(GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 3) // For l4d, dont block hunter bh
		{
			// Skipping calculation for This SI based on exception rules
			return Plugin_Continue;
		}

		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			if (LeftGroundMaxSpeed[client] != -1.0)
			{
				decl Float:CurVelVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", CurVelVec);
				
				if (GetVectorLength(CurVelVec) > LeftGroundMaxSpeed[client])
				{
					#if DEBUG
					PrintToChat(client, "Speed: %f {%.02f, %.02f, %.02f}, MaxSpeed: %f", GetVectorLength(CurVelVec), CurVelVec[0], CurVelVec[1], CurVelVec[2], LeftGroundMaxSpeed[client]);
					#endif
					NormalizeVector(CurVelVec, CurVelVec);
					ScaleVector(CurVelVec, LeftGroundMaxSpeed[client]);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
				}
				LeftGroundMaxSpeed[client] = -1.0;
			}
		}
		else if(LeftGroundMaxSpeed[client] == -1.0)
		{
			LeftGroundMaxSpeed[client] = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
		}
	}
	
	return Plugin_Continue;
}  