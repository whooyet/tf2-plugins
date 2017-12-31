#pragma semicolon 1

#define PLUGIN_AUTHOR "AI"
#define PLUGIN_VERSION "0.1.0"

#include <sourcemod>
#include <sdktools>
#include <smlib/entities>
#include <smlib/effects>

int g_iLaserModel;
int g_iHaloModel;

public Plugin myinfo = 
{
	name = "Spawn box",
	author = PLUGIN_AUTHOR,
	description = "Draws spawn boxes",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=301101"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_s", cmdSpawnBox);
}

public void OnMapStart() {
	g_iLaserModel = PrecacheModel("sprites/laser.vmt");
	g_iHaloModel = PrecacheModel("materials/sprites/halo01.vmt");
}

public Action cmdSpawnBox(int iClient, int iArgs) {
	int iEntity = -1;
	
	float fOrigin[3];
	GetClientEyePosition(iClient, fOrigin);

	float fPos[3], fMin[3], fMax[3];
	while ((iEntity = FindEntityByClassname(iEntity, "info_player_teamspawn")) != INVALID_ENT_REFERENCE) {
		Entity_GetAbsOrigin(iEntity, fPos);
		
		fMin[0] = -25.0;
		fMin[1] = -25.0;
		fMin[2] = 0.0;
		
		fMax[0] = 25.0;
		fMax[1] = 25.0;
		fMax[2] = 80.0;
			
		AddVectors(fPos, fMin, fMin);
		AddVectors(fPos, fMax, fMax);
		
		// if (GetVectorDistance(fPos, fOrigin) < 1000.0) { 
			// Effect_DrawBeamBoxToAll(fMin, fMax, g_iLaserModel, g_iHaloModel);
		// }
		
		Effect_DrawBeamBoxToAll(fMin, fMax, g_iLaserModel, g_iHaloModel);
	}
	
	return Plugin_Handled;
}