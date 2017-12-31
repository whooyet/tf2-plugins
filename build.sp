#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

#define DISPENSER_BLUEPRINT	"models/buildables/dispenser_blueprint.mdl"
#define MODEL_EMPTY "models/empty.mdl"

int g_CarriedDispenser[MAXPLAYERS+1];
float CoolTime[MAXPLAYERS+1];

public void OnPluginStart()
{

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			g_CarriedDispenser[i] = INVALID_ENT_REFERENCE;
}

public void OnClientPutInServer(int client)
{
	g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
}

public void OnMapStart()
{
	PrecacheModel(MODEL_EMPTY);
}

public void OnEntityDestroyed(int iEntity)
{
	if(IsValidEntity(iEntity))
	{
		char classname[64];
		GetEntityClassname(iEntity, classname, sizeof(classname));
		
		if(StrEqual(classname, "obj_dispenser") || StrEqual(classname, "obj_sentrygun") || StrEqual(classname, "obj_teleporter"))
		{
			char Tname[32], SteamID[32];
			GetEntPropString(iEntity, Prop_Data, "m_iName", Tname, sizeof(Tname));
			
			PrintToChatAll(Tname);
			
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
					
					if(StrEqual(SteamID, Tname))
					{
						if(g_CarriedDispenser[i] != INVALID_ENT_REFERENCE)
						{
							int Dispenser = EntRefToEntIndex(g_CarriedDispenser[i]);

							int iLink = GetEntPropEnt(Dispenser, Prop_Send, "m_hEffectEntity");
							if(IsValidEntity(iLink))
							{
								AcceptEntityInput(iLink, "ClearParent");
								AcceptEntityInput(iLink, "Kill");
							}
							
							g_CarriedDispenser[i] = INVALID_ENT_REFERENCE;
							TF2_RemoveCondition(i, TFCond_MarkedForDeath);
						}
					}
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if(g_CarriedDispenser[client] == INVALID_ENT_REFERENCE)
		{
			if(CheckCoolTime(client, 0.5) && buttons & IN_ATTACK3)
			{
				int iAim = GetClientAimTarget(client, false)
				if(IsValidEntity(iAim))
				{
					char strClass[64];
					GetEntityClassname(iAim, strClass, sizeof(strClass));
					
					if(GetClientTeam(client) == GetEntProp(iAim, Prop_Send, "m_iTeamNum"))
					{
						if(StrEqual(strClass, "obj_dispenser")) EquipDispenser(client, iAim, 1);
						else if(StrEqual(strClass, "obj_sentrygun")) EquipDispenser(client, iAim, 2);
						else if(StrEqual(strClass, "obj_teleporter")) EquipDispenser(client, iAim, 3);
					}
				}
				CoolTime[client] = GetEngineTime();
			}
		}	
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
		DestroyDispenser(client);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && g_CarriedDispenser[client] != INVALID_ENT_REFERENCE)
		DestroyDispenser(client);
}

stock void EquipDispenser(int client, int target, int type)
{
			
	float dPos[3], bPos[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", dPos);
	GetClientAbsOrigin(client, bPos);
	
	if(GetVectorDistance(dPos, bPos) <= 125.0 && IsValidBuilding(target))
	{	
		int trigger = -1;
		
		if(type == 1)
		{
			while ((trigger = FindEntityByClassname(trigger, "dispenser_touch_trigger")) != -1)
			{
				if(IsValidEntity(trigger))
				{
					int ownerentity = GetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity");
					if(ownerentity == target)
					{
						SetVariantString("!activator");
						AcceptEntityInput(trigger, "SetParent", target);
					}
				}
			}
		}
		else if(type == 2)
		{
			while ((trigger = FindEntityByClassname(trigger, "obj_sentrygun")) != -1)
			{
				if(IsValidEntity(trigger))
				{
					int ownerentity = GetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity");
					if(ownerentity == target)
					{
						SetVariantString("!activator");
						AcceptEntityInput(trigger, "SetParent", target);
					}
				}
			}
		}
		
		else if(type == 3)
		{
			while ((trigger = FindEntityByClassname(trigger, "obj_teleporter")) != -1)
			{
				if(IsValidEntity(trigger))
				{
					int ownerentity = GetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity");
					if(ownerentity == target)
					{
						SetVariantString("!activator");
						AcceptEntityInput(trigger, "SetParent", target);
					}
				}
			}
		}
		
		char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));	
		DispatchKeyValue(target, "targetname", SteamID);
		
		int iLink = CreateLink(client);
		
		SetVariantString("!activator");
		AcceptEntityInput(target, "SetParent", iLink); 
		
		SetVariantString("flag"); 
		AcceptEntityInput(target, "SetParentAttachment", iLink); 

		SetEntPropEnt(target, Prop_Send, "m_hEffectEntity", iLink);
		
		float pPos[3], pAng[3];

		pPos[0] += 30.0;	//This moves it up/down
		pPos[1] += 40.0;
		
		pAng[0] += 180.0;
		pAng[1] -= 90.0;
		pAng[2] += 90.0;

		SetEntPropVector(target, Prop_Send, "m_vecOrigin", pPos);
		SetEntPropVector(target, Prop_Send, "m_angRotation", pAng);
		
		SetEntProp(target, Prop_Send, "m_nSolidType", 0);
		SetEntProp(target, Prop_Send, "m_usSolidFlags", 0x0004);
		
		TF2_AddCondition(client, TFCond_MarkedForDeath, -1.0);
		
		g_CarriedDispenser[client] = EntIndexToEntRef(target);
	}
}

stock bool CheckCoolTime(any iClient, float fTime)
{
	if(!IsPlayerAlive(iClient)) return false;
	if(GetEngineTime() - CoolTime[iClient] >= fTime) return true;
	else return false;
}

stock void DestroyDispenser(int client)
{
	int Dispenser = EntRefToEntIndex(g_CarriedDispenser[client]);
	if(Dispenser != INVALID_ENT_REFERENCE)
	{
		int iLink = GetEntPropEnt(Dispenser, Prop_Send, "m_hEffectEntity");
		if(IsValidEntity(iLink))
		{
			AcceptEntityInput(iLink, "ClearParent");
			AcceptEntityInput(iLink, "Kill");
		
			SetVariantInt(5000);
			AcceptEntityInput(Dispenser, "RemoveHealth");
			
			TF2_RemoveCondition(client, TFCond_MarkedForDeath);
			g_CarriedDispenser[client] = INVALID_ENT_REFERENCE;
		}
	}
}

stock int CreateLink(int iClient)
{
	int iLink = CreateEntityByName("tf_taunt_prop");
	
	DispatchSpawn(iLink); 
	
	SetEntityModel(iLink, MODEL_EMPTY);
	
	SetEntProp(iLink, Prop_Send, "m_fEffects", 16|64);
	
	SetVariantString("!activator"); 
	AcceptEntityInput(iLink, "SetParent", iClient); 
	
	SetVariantString("flag");
	AcceptEntityInput(iLink, "SetParentAttachment", iClient);
	
	return iLink;
}

stock bool IsValidBuilding(int iBuilding)
{
	if (IsValidEntity(iBuilding))
	{
		if (GetEntProp(iBuilding, Prop_Send, "m_bPlacing") == 0
		 && GetEntProp(iBuilding, Prop_Send, "m_bCarried") == 0
		 && GetEntProp(iBuilding, Prop_Send, "m_bCarryDeploy") == 0)
			return true;
	}
	
	return false;
}

stock bool TraceRayDontHitEntity(int entity, int mask, any data)
{
	if (entity == data) return false;
	return true;
}