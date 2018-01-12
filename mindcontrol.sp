#include <sdktools>
#include <smlib>

#define MODEL_EMPTY "models/empty.mdl"

new Cbutton, Float:Cangle[3];
new bool:aaa[MAXPLAYERS+1];

new g_vViewControll[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ... };

public OnPluginStart()
{
	RegConsoleCmd("sm_tc", aaaa);
}

public void OnMapStart()
{
	PrecacheModel(MODEL_EMPTY);
}

public Action:aaaa(client, args)
{
	if(!aaa[client])
	{
		aaa[client] = true;
		SetEntityMoveType(client, MOVETYPE_NONE);

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsFakeClient(i))
			{
				// CreateCamera(i);
				
				// if(IsValidEntity(g_vViewControll[i]))
					// SetClientViewEntity(client, g_vViewControll[i]);
				// else PrintToChatAll("A");
				SetClientViewEntity(client, i);
			}
		}
	}
	else
	{
		aaa[client] = false;
		PrintToChat(client, "no");
		SetClientViewEntity(client, client);
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:fVel[3], Float:angles[3], &weapon)
{
	if(IsValidClient(client))
	{
		SetHudTextParams(-1.0, -1.0, 0.1, 150, 150, 0, 150, 0, 0.0, 0.0, 0.0);
		ShowHudText(client, -1, "*");
		if(!IsFakeClient(client))
		{

			Cbutton = buttons;
			Array_Copy(angles, Cangle, 2);
		}
		else
		{
			buttons |= Cbutton;
			
			if (buttons & (IN_FORWARD|IN_BACK) == IN_FORWARD|IN_BACK) fVel[0] = 0.0;
			else if (buttons & IN_FORWARD) fVel[0] = 400.0;
			else if (buttons & IN_BACK) fVel[0] = -400.0;
			if (buttons & (IN_MOVELEFT|IN_MOVERIGHT) == IN_MOVELEFT|IN_MOVERIGHT) fVel[1] = 0.0;
			else if (buttons & IN_MOVELEFT) fVel[1] = -400.0;
			else if (buttons & IN_MOVERIGHT) fVel[1] = 400.0;
			
			Array_Copy(Cangle, angles, 2);	
			TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock CreateCamera(entity)
{
	decl Float:ang[3];
	decl Float:pos[3];
	GetClientEyeAngles(entity, ang);
	GetClientEyePosition(entity, pos);
				
	new camera = CreateEntityByName("point_viewcontrol"); 
	if(IsValidEntity(camera)) 
	{
		DispatchKeyValueVector(camera, "angles", ang); 
		TeleportEntity(camera, pos, ang, NULL_VECTOR);
		DispatchSpawn(camera);
		
		SetVariantString("!activator"); 
		AcceptEntityInput(camera, "SetParent", entity); 
		
		SetVariantString("eyes");
		AcceptEntityInput(camera, "SetParentAttachment", entity);
		
		
		AcceptEntityInput(camera, "Enable", entity);
		
		g_vViewControll[entity] = EntIndexToEntRef(camera);
		
		PrintToChatAll("파랜트 : %N", entity);
	}
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
