#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <devzones>

#define BALL "models/player/items/scout/soccer_ball.mdl"
#define BALL2 "models/props_gameplay/ball001.mdl"
#define BallSound		"passtime/ball_smack.wav"
#define Goal		"passtime/crowd_cheer.wav"
#define Boo		"passtime/crowd_react_neg.wav"

#define SPEED 700.0

new RED, BLU;

static int g_iLaserMaterial, g_iHaloMaterial;

new bool:Charge[MAXPLAYERS+1] = false;
new bool:Reload[MAXPLAYERS+1] = false;
new owner[2048];

public OnPluginStart()
{
	new ball = -1;
	while ((ball = FindEntityByClassname2(ball, BALL)) != -1) AcceptEntityInput(ball, "Kill");
}

public OnConfigsExecuted()
{
	if(IsSoccerMap())
	{
		HookEvent("player_spawn", PlayerSpawn);
		HookEvent("player_death", player_death);
		
		AddCommandListener(hook_JoinClass, "joinclass");
	}
}

public OnClientPutInServer(client)
{
	Charge[client] = false;
	Charge[client] = false;
	Reload[client] = false;
	RED = 0;
	BLU = 0;
}

public OnMapStart()
{ 
	PrecacheModel(BALL);
	PrecacheModel(BALL2);
	PrecacheSound(BallSound, true);
	PrecacheSound(Goal, true);
	PrecacheSound(Boo, true);
	
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
}

public Action hook_JoinClass(int client, const char[] command, int argc)
{
	char cmd1[32];
	if(argc < 1) return Plugin_Handled;
	GetCmdArg(1, cmd1, sizeof(cmd1));
	
	if(!StrEqual(cmd1, "demoman"))
	{
		PrintCenterText(client, "데모맨만 선택 가능합니다.");
		// ShowVGUIPanel(client, "class_red");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], index, &Handle:hItem)
{
	if(!IsSoccerMap()) return Plugin_Continue;
	if (StrEqual(classname, "tf_weapon_cannon")) return Plugin_Handled;
	if (StrEqual(classname, "tf_weapon_pipebomblauncher")) return Plugin_Handled;
	if (StrEqual(classname, "tf_weapon_grenadelauncher")) return Plugin_Handled;
	if (index == 132) return Plugin_Handled;
	if (index == 1082) return Plugin_Handled;
	ChangePlayerWeaponSlot(client, 2);
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, SpanwClient, client);
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.2, SpanwClient2, client);
}

public Action:SpanwClient2(Handle:timer, any:client) TF2_RespawnPlayer(client);
 
public Action:SpanwClient(Handle:timer, any:client)
{
	new Float:pos[3];
	if(GetClientTeam(client) == 2)
	{
		pos[0] = -11272.927734;
		pos[1] = -349.687194;
		pos[2] = -11135.968750;
	}
	else if(GetClientTeam(client) == 3)
	{
		pos[0] = -11302.817382;
		pos[1] = 2783.458740;
		pos[2] = -11135.968750;
	}
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR); 
}

public Zone_OnClientEntry(client, String:zone[])
{
	if(!IsSoccerMap()) return;
	if(StrEqual(zone, "축구장"))
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			new ball = -1;
			while ((ball = FindEntityByClassname2(ball, BALL)) == -1)
			{
				new ent = CreateEntityByName("prop_physics_override"); 
				if(ent == -1) return;
				
				new Float:pos[3];
				pos[0] = -9285.045898;
				pos[1] = 1214.288940;
				pos[2] = -11135.968750 + 800.0;
						
				SetEntityModel(ent, BALL); 
				DispatchKeyValue(ent, "Solid", "6"); 
				DispatchKeyValue(ent, "spawnflags", "1026"); 
						
				DispatchKeyValue(ent, "classname", BALL);
				SetEntPropFloat(ent, Prop_Send, "m_flModelScale",1.2);

				DispatchSpawn(ent); 
				AcceptEntityInput(ent, "TurnOn", ent, ent, 0); 
				AcceptEntityInput(ent, "EnableCollision"); 
				TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR); 
				SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
			}
		}
	}
}


public Zone_OnClientLeave(client, String:zone[])
{
	if(!IsSoccerMap()) return;
	if(StrEqual(zone, "축구장")) if(IsValidClient(client) && IsPlayerAlive(client)) TF2_RegeneratePlayer(client);
}

public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)
{
	if(!IsSoccerMap()) return Plugin_Continue;
	if(IsPlayerAlive(client))
	{
		SetHudTextParams(0.33, 0.93, 0.1, 150, 150, 0, 150, 0, 0.0, 0.0, 0.0);
		if(!(iButtons & IN_SCORE)) ShowHudText(client, 1, "RED : %d                                                Blu : %d", RED, BLU);
		
		if(TF2_IsPlayerInCondition(client, TFCond:17)) Charge[client] = true;
		else Charge[client] = false;
		
		if(iButtons & IN_ATTACK3) Reload[client] = true;
		else Reload[client] = false;
		
		// PrintToChat(client, "%d", GetClientSpeed(client));
		
		if(RED == 5)
		{
			ResetScore();
			PrintToChatAll("\x03레드팀이 이겼습니다.");
		}
		
		if(BLU == 5)
		{
			ResetScore();
			PrintToChatAll("\x03블루팀이 이겼습니다.");
		}
		
		
		new ball = -1;
		while ((ball = FindEntityByClassname2(ball, BALL)) != -1)
		{
			decl Float:bpos[3], Float:cpos[3], Float:distance;
			GetEntPropVector(ball, Prop_Data, "m_vecAbsOrigin", bpos);
	
			GetClientEyePosition(client, cpos);
			distance = GetVectorDistance(cpos, bpos);

			if(distance <= 72.0)
			{
				decl Float:aim[3]; new Float:vBuffer[3], Float:vec[3];
				GetClientEyeAngles(client, aim);
				// GetClientAbsAngles(client, aim);
				
				ScaleVector(vec, 1.3);
				
				GetAngleVectors(aim, vBuffer, NULL_VECTOR, NULL_VECTOR);
				
				if(Charge[client])
				{
					EmitSoundToAll(BallSound, ball, SNDCHAN_AUTO);
					vec[0] = vBuffer[0]*800.0;
					vec[1] = vBuffer[1]*800.0;
					vec[2] = 750.0;
				}
				else
				{
					if(!(GetEntityFlags(client) & FL_ONGROUND))
					{
						EmitSoundToAll(BallSound, ball, SNDCHAN_AUTO);
						vec[0] = vBuffer[0]*500.0;
						vec[1] = vBuffer[1]*500.0;
						vec[2] = 450.0;
					}
					else
					{
						if(GetClientSpeed(client) != 0)
						{
							if(Reload[client])
							{
								EmitSoundToAll(BallSound, ball, SNDCHAN_AUTO, _, _, 0.05);
								vec[0] = vBuffer[0]*200.0;
								vec[1] = vBuffer[1]*200.0;
							}
							else
							{
								EmitSoundToAll(BallSound, ball, SNDCHAN_AUTO);
								vec[0] = vBuffer[0]*900.0;
								vec[1] = vBuffer[1]*900.0;
							}
						}
					}
				}
				TeleportEntity(ball, NULL_VECTOR, NULL_VECTOR, vec);
				owner[ball] = EntIndexToEntRef(client);
			}
			
			new Float:pos[3], Float:distance2;
			pos[0] = -9285.045898;
			pos[1] = 1214.288940;
			pos[2] = -11135.968750 + 800.0;
			
			distance2 = GetVectorDistance(pos, bpos);
			
			if(distance2 >= 1800.0) TeleportEntity(ball, pos, NULL_VECTOR, NULL_VECTOR);
		}
		
		while ((ball = FindEntityByClassname2(ball, "trigger_multiple")) != -1)
		{
			if(GetTargetName(ball, "레드_골대"))
			{
				decl Float:pos[3], Float:vMaxs[3], Float:vMin[3];
				GetEntPropVector(ball, Prop_Send, "m_vecOrigin", pos);
				GetEntPropVector(ball, Prop_Send, "m_vecMaxs", vMaxs)
				GetEntPropVector(ball, Prop_Send, "m_vecMins", vMin)
				TE_DrawBox(ball, pos, vMin, vMaxs, _, { 255, 0, 0, 255 }, 2);
			}
			
			if(GetTargetName(ball, "블루_골대"))
			{
				decl Float:pos[3], Float:vMaxs[3], Float:vMin[3];
				GetEntPropVector(ball, Prop_Send, "m_vecOrigin", pos);
				GetEntPropVector(ball, Prop_Send, "m_vecMaxs", vMaxs)
				GetEntPropVector(ball, Prop_Send, "m_vecMins", vMin)
				TE_DrawBox(ball, pos, vMin, vMaxs, _, { 0, 0, 255, 255 }, 3);
			}
		}
	}
	return Plugin_Continue;
}

stock TE_DrawBox(int ent, float m_vecOrigin[3], float m_vecMins[3], float m_vecMaxs[3], float flDur = 0.1, int color[4], type)
{
	//Trace top down
	float tStart[3]; tStart = m_vecOrigin;
	float tEnd[3];   tEnd = m_vecOrigin;
	
	tStart[2] = (tStart[2] + m_vecMaxs[2]);
	
	Handle trace = TR_TraceHullFilterEx(tStart, tEnd, m_vecMins, m_vecMaxs, MASK_SHOT|CONTENTS_GRATE, WorldOnly, ent);
	new iHitEntity = TR_GetEntityIndex(trace);
	
	if( m_vecMins[0] == m_vecMaxs[0] && m_vecMins[1] == m_vecMaxs[1] && m_vecMins[2] == m_vecMaxs[2] )
	{
		m_vecMins = view_as<float>({-15.0, -15.0, -15.0});
		m_vecMaxs = view_as<float>({15.0, 15.0, 15.0});
	}
	else
	{
		AddVectors(m_vecOrigin, m_vecMaxs, m_vecMaxs);
		AddVectors(m_vecOrigin, m_vecMins, m_vecMins);
	}
	
	float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
	vPos1 = m_vecMaxs;
	vPos1[0] = m_vecMins[0];
	vPos2 = m_vecMaxs;
	vPos2[1] = m_vecMins[1];
	vPos3 = m_vecMaxs;
	vPos3[2] = m_vecMins[2];
	vPos4 = m_vecMins;
	vPos4[0] = m_vecMaxs[0];
	vPos5 = m_vecMins;
	vPos5[1] = m_vecMaxs[1];
	vPos6 = m_vecMins;
	vPos6[2] = m_vecMaxs[2];
	
	TE_SendBeam( m_vecMaxs, vPos1, flDur, color);
	TE_SendBeam( m_vecMaxs, vPos2, flDur, color);
	TE_SendBeam( m_vecMaxs, vPos3, flDur, color);
	TE_SendBeam( vPos6, vPos1, flDur, color);
	TE_SendBeam( vPos6, vPos2, flDur, color);
	TE_SendBeam( vPos6, m_vecMins, flDur, color);
	TE_SendBeam( vPos4, m_vecMins, flDur, color);
	TE_SendBeam( vPos5, m_vecMins, flDur, color);
	TE_SendBeam( vPos5, vPos1, flDur, color);
	TE_SendBeam( vPos5, vPos3, flDur, color);
	TE_SendBeam( vPos4, vPos3, flDur, color);
	TE_SendBeam( vPos4, vPos2, flDur, color);

	if(iHitEntity > 0)
	{
		new client = EntRefToEntIndex(owner[iHitEntity]);
		if(type == 3) // 블루 골대
		{
			RED++;
			
			if(GetClientTeam(client) == 2)
			{
				PrintToChatAll("\x07FF4040%N \x07FFFFFF님이 \x04골\x07FFFFFF을 넣어 \x07FF4040레드팀 \x04+1점", EntRefToEntIndex(owner[iHitEntity]));
				SetScore(client, 1);
			}
			else if(GetClientTeam(client) == 3) PrintToChatAll("\x0799CCFF%N \x07FFFFFF님이 \x04자살골\x07FFFFFF을 넣어 \x07FF4040레드팀 \x04+1점", EntRefToEntIndex(owner[iHitEntity]));
			
			ReSpawnBall(iHitEntity);
			
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && GetClientTeam(i) == 2) EmitSoundToClient(i, Goal);
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && GetClientTeam(i) == 3) EmitSoundToClient(i, Boo);
		}
		else if(type == 2)
		{
			BLU++;
			
			if(GetClientTeam(client) == 3)
			{
				PrintToChatAll("\x0799CCFF%N \x07FFFFFF님이 \x04골\x07FFFFFF을 넣어 \x0799CCFF블루팀 \x04+1점", EntRefToEntIndex(owner[iHitEntity]));
				SetScore(client, 1);
			}
			else if(GetClientTeam(client) == 2) PrintToChatAll("\x07FF4040%N \x07FFFFFF님이 \x04자살골\x07FFFFFF을 넣어 \x0799CCFF블루팀 \x04+1점", EntRefToEntIndex(owner[iHitEntity]));
			
			ReSpawnBall(iHitEntity);
			
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && GetClientTeam(i) == 2) EmitSoundToClient(i, Boo);
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && GetClientTeam(i) == 3) EmitSoundToClient(i, Goal);
		}
	}
	
	delete trace;
}

stock ReSpawnBall(ball)
{
	if(IsValidEntity(ball))
	{
		new Float:pos[3];
		pos[0] = -9285.045898;
		pos[1] = 1214.288940;
		pos[2] = -11135.968750 + 800.0;
		TeleportEntity(ball, pos, NULL_VECTOR, NULL_VECTOR);
	}
}

stock ResetScore()
{
	new ball = -1;
	while ((ball = FindEntityByClassname2(ball, BALL)) != -1) owner[ball] = INVALID_ENT_REFERENCE;
	RED = 0; BLU = 0;
}

public bool WorldOnly(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	if(StrEqual(class, BALL)) return true;
	return false;
}

void TE_SendBeam(float m_vecMins[3], float m_vecMaxs[3], float flDur = 0.1, int color[4])
{
	TE_SetupBeamPoints(m_vecMins, m_vecMaxs, g_iLaserMaterial, g_iHaloMaterial, 0, 0, flDur, 1.0, 1.0, 1, 0.0, color, 0);
	TE_SendToAll();
}

stock SetScore(client, score)
{
	new Handle:event=CreateEvent("player_escort_score", true);
	SetEventInt(event, "player", client);
	SetEventInt(event, "points", score);
	FireEvent(event);
}

stock GetClientSpeed(client)
{
	static float vecVel[3];
	GetEntPropVector( client, Prop_Data, "m_vecVelocity", vecVel );
	return RoundFloat(SquareRoot( vecVel[0] * vecVel[0] + vecVel[1] * vecVel[1] ));
}

stock bool:RayDontHitSelf(entity, contentsMask, any:data)  return (entity != data); 

stock bool:GetTargetName(ent, String:name[])
{
	decl String:szname[120], String:aa[2][64];
	GetEntPropString(ent, Prop_Data, "m_iName", szname, sizeof(szname));
	ExplodeString(szname, " ", aa, 2, 64);
	if(StrContains(aa[1], name, false) != -1) return true;
	return false;
}

stock bool:IsSoccerMap()
{
	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	if(StrEqual(strMap, "tf_rmcity_sunset_club_v2fix3")) return true;
	return false;
}

stock bool:ChangePlayerWeaponSlot(iClient, iSlot) {
	new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > MaxClients) {
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		return true;
	}
	return false;
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

stock IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}