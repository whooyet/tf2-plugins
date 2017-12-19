#include <sdktools>
#include <morecolors>
#include <soundlib>

new Handle:kv[500] = {INVALID_HANDLE, ...};
new MaxItem;

new CheckSoundOverLap;
new bool:SayCheck[99];

new Float:CheckTime[99];
new Float:SaySoundDelay[MAXPLAYERS+1];

new Handle:g_hHudSync = INVALID_HANDLE;
new Handle:SayX = INVALID_HANDLE;
new Handle:SayY = INVALID_HANDLE;
new Handle:SayR = INVALID_HANDLE;
new Handle:SayG = INVALID_HANDLE;
new Handle:SayB = INVALID_HANDLE;
new Handle:SayA = INVALID_HANDLE;
new Handle:CvarTag = INVALID_HANDLE;

new String:TAG[100];

public Plugin myinfo = 
{
	name = "Simple SaySounds",
	author = "뿌까",
	description = "하하하하",
	version = "3.6",
	url = "x"
};

public OnPluginStart()
{
	AddCommandListener(Say, "say");
	
	RegConsoleCmd("sm_stop", SayStop);
	RegAdminCmd("sm_allstop", SayAllStop, ADMFLAG_KICK);
	RegAdminCmd("sm_saylist", SaySoundList, 0);
	
	SayX = CreateConVar("sm_saysounds_x", "0.75", "Hud x");
	SayY = CreateConVar("sm_saysounds_y", "0.17", "Hud Y");
	SayR = CreateConVar("sm_saysounds_r", "0", "Hud R");
	SayG = CreateConVar("sm_saysounds_g", "153", "Hud G");
	SayB = CreateConVar("sm_saysounds_b", "51", "Hud B");
	SayA = CreateConVar("sm_saysounds_a", "150", "Hud A");
	g_hHudSync = CreateHudSynchronizer();
	
	CvarTag = CreateConVar("sm_saysounds_tag", "뿌까");
	HookConVarChange(CvarTag, ConVarChanged);
	GetConVarString(CvarTag, TAG, sizeof(TAG));
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) GetConVarString(CvarTag, TAG, sizeof(TAG));

public OnClientConnected(client) SaySoundDelay[client] = 0.0;

public Action:OnPlayerRunCmd(client, &buttons) 
{
	SetHudTextParams(GetConVarFloat(SayX), GetConVarFloat(SayY), 0.5, GetConVarInt(SayR), GetConVarInt(SayG), GetConVarInt(SayB), GetConVarInt(SayA));
	
	decl String:SayFile[256], String:SayTitle[256], overlap;
	for(new i = 0; i < MaxItem; i++)
	{
		if(kv[i] != INVALID_HANDLE)
		{
			GetArrayString(kv[i], 1, SayFile, sizeof(SayFile));
			GetArrayString(kv[i], 2, SayTitle, sizeof(SayTitle));
			overlap = GetArrayCell(kv[i], 4);
		}
		if(SayCheck[i])
		{ 
			if(overlap == 1 && CheckSoundOverLap == i)
			{
				if(PlayerCheck(client))
				{
					if(buttons & IN_SCORE) ClearSyncHud(client, g_hHudSync);
					else ShowSyncHudText(client, g_hHudSync, "song: %s", SayTitle);
				}
			}
					
			new Float:time = FileSecond(SayFile);
			new Float:current_time = GetEngineTime() - CheckTime[i];

			if(time <= current_time)
			{
				if(CheckSoundOverLap == i)
				{
					CheckSoundOverLap = -1;
					ClearSyncHud(client, g_hHudSync);
				}
				SayCheck[i] = false;
				CheckTime[i] = 0.0;
			}
		}
	}
}

public Action:Say(client, String:command[], argc)
{
	decl String:text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	decl String:SayName[256], String:SayFile[256], String:SayTitle[256], admin, overlap;
	for(new i = 0 ; i < MaxItem ; i++)
	{
		if(kv[i] != INVALID_HANDLE)
		{
			GetArrayString(kv[i], 0, SayName, sizeof(SayName));
			GetArrayString(kv[i], 1, SayFile, sizeof(SayFile));
			GetArrayString(kv[i], 2, SayTitle, sizeof(SayTitle));
			admin = GetArrayCell(kv[i], 3);
			overlap = GetArrayCell(kv[i], 4);
		}
		
		if(StrEqual(text, SayName))
		{
			if(!CheckSoundCoolTime(client, 3.0))
			{
				PrintToChat(client, "\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x043초 후에 다시 사용 가능 합니다.", TAG);
				return Plugin_Handled;
			}
			
			if(admin == 1  && !IsClientAdmin(client))
			{
				PrintToChat(client, "\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x04당신은 이 노래를 틀 수 없습니다.", TAG);
				return Plugin_Handled;	
			}
			
			if(overlap == 1)
			{
				if(CheckSoundOverLap != -1)
				{
					PrintToChat(client, "\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x04중복으로 틀 수 없습니다.", TAG);
					return Plugin_Handled;
				}
				else CheckSoundOverLap = i;
			}

			EmitSoundToAll(SayFile);
			CheckTime[i] = GetEngineTime();
			SaySoundDelay[client] = GetEngineTime();
				
			SayCheck[i] = true;
			PrintToChatAll("\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x0700ccff%N\x07FFFFFF 님이 \x04%s \x07FFFFFF노래를 틀었습니다.", TAG, client, SayName);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:SayStop(client, args)
{
	decl String:SayFile[256];
	for(new i = 0 ; i < MaxItem ; i++)
	{
		if(kv[i] != INVALID_HANDLE) GetArrayString(kv[i], 1, SayFile, sizeof(SayFile));
		if(SayCheck[i]) StopSound(client, SNDCHAN_AUTO, SayFile);
	}
	PrintToChat(client, "\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x04노래가 꺼졌습니다.", TAG);
	return Plugin_Handled;
}

public Action:SayAllStop(client, args) 
{
	decl String:SayFile[256];
	for(new i = 0 ; i < MaxItem ; i++)
	{
		if(kv[i] != INVALID_HANDLE) GetArrayString(kv[i], 1, SayFile, sizeof(SayFile));
		if(SayCheck[i])
		{
			for(new all = 1; all <= MaxClients; all++)
			{
				if(PlayerCheck(all))
				{
					StopSound(all, SNDCHAN_AUTO, SayFile);
					ClearSyncHud(all, g_hHudSync);
				}
			}
			SayCheck[i] = false;
			if(CheckSoundOverLap == i) CheckSoundOverLap = -1;
		}
	}
	PrintToChatAll("\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x0700ccff%N\x07FFFFFF 님이 노래를 껏습니다.", TAG, client);
	return Plugin_Handled;
}

public Action:SaySoundList(client, args)
{
	SoundMenu(client);
	return Plugin_Handled;
}

public Action:SoundMenu(client)
{
	new Handle:menu = CreateMenu(Sound_Select);
	SetMenuTitle(menu, "Sound List");
	
	new String:temp[10];
	decl String:SayName[256], admin;
	for(new i = 0 ; i < MaxItem ; i++)
	{
		if(kv[i] != INVALID_HANDLE)
		{
			GetArrayString(kv[i], 0, SayName, sizeof(SayName));
			admin = GetArrayCell(kv[i], 3);
		}
		
		if(!IsClientAdmin(client))
		{
			if(admin == 0)
			{
				IntToString(i, temp, sizeof(temp));
				AddMenuItem(menu, temp, SayName);
			}
		}
		else
		{
			IntToString(i, temp, sizeof(temp));
			AddMenuItem(menu, temp, SayName);
		}
	} 
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
} 

public Sound_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[10], String:SayName[256], String:SayFile[256], admin, overlap;
		GetMenuItem(menu, select, info, sizeof(info));
		
		new i = StringToInt(info);
		
		if(!CheckSoundCoolTime(client, 3.0))
		{
			PrintToChat(client, "\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x043초 후에 다시 사용 가능 합니다.", TAG);
			return;
		}
		
		if(kv[i] != INVALID_HANDLE)
		{
			GetArrayString(kv[i], 0, SayName, sizeof(SayName));
			GetArrayString(kv[i], 1, SayFile, sizeof(SayFile));
			admin = GetArrayCell(kv[i], 3);
			overlap = GetArrayCell(kv[i], 4);
		}
		
		if(admin == 1  && !IsClientAdmin(client))
		{
			PrintToChat(client, "\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x04당신은 이 노래를 틀 수 없습니다.", TAG);
			return;	
		}

		
		if(overlap == 1)
		{
			if(CheckSoundOverLap != -1)
			{
				PrintToChat(client, "\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x04중복으로 틀 수 없습니다.", TAG);
				return;
			}
			else CheckSoundOverLap = i;
		}

		EmitSoundToAll(SayFile);
		CheckTime[i] = GetEngineTime();
		SaySoundDelay[client] = GetEngineTime();
				
		SayCheck[i] = true;
		PrintToChatAll("\x07FFFFFF[\x07ff0000%s \x07FFFFFFSaySounds] \x0700ccff%N\x07FFFFFF 님이 \x04%s \x07FFFFFF노래를 틀었습니다.", TAG, client, SayName);
		return;
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public OnMapStart()
{
	decl String:strPath[192], String:szBuffer[256];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/fuga_saysounds.cfg");
	new count = 0, String:temp[256];
	
	new Handle:DB = CreateKeyValues("sounds");
	FileToKeyValues(DB, strPath);

	if(KvGotoFirstSubKey(DB))
	{
		do
		{
			kv[count] = CreateArray(540);
			
			KvGetSectionName(DB, szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);		
			
			KvGetString(DB, "file", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			
			KvGetString(DB, "title", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			
			PushArrayCell(kv[count], KvGetNum(DB, "admin"));
			PushArrayCell(kv[count], KvGetNum(DB, "overlap"));
			count++;
		}
		while(KvGotoNextKey(DB));
	}
	CloseHandle(DB);
	MaxItem = count;
	
	for(new i = 0; i < MaxItem; i++)
	{
		CheckTime[i] = 0.0;
		SayCheck[i] = false;
	}
	CheckSoundOverLap = -1;
	
	decl String:SayFile[256];
	for(new i = 0 ; i < MaxItem ; i++)
	{
		if(kv[i] != INVALID_HANDLE) GetArrayString(kv[i], 1, SayFile, sizeof(SayFile));
		Format(temp, sizeof(temp), "sound/%s", SayFile);
		PrecacheSound(SayFile, true);
		AddFileToDownloadsTable(temp);
	}
}

public OnMapEnd() for(new i = 0 ; i < 500 && i < MaxItem; i++) if(kv[i] != INVALID_HANDLE) CloseHandle(kv[i]);

stock bool:CheckSoundCoolTime(any:iClient, Float:fTime)
{
	if(GetEngineTime() - SaySoundDelay[iClient] >= fTime) return true;
	else return false;
}

stock Float:FileSecond(String:File2[])
{
	new Handle:h_Soundfile = INVALID_HANDLE;
	h_Soundfile = OpenSoundFile(File2, true);
	
	new Float:timebuf;
	if(h_Soundfile != INVALID_HANDLE) timebuf = GetSoundLengthFloat(h_Soundfile);
	CloseHandle(h_Soundfile);
	return timebuf;
}

stock acv()
{
	for(new i = 0 ; i < MaxItem ; i++) if(SayCheck[i] && CheckSoundOverLap == i) return true;
	return false;
}

stock bool:IsClientAdmin(client)
{
	new AdminId:Cl_ID;
	Cl_ID = GetUserAdmin(client);
	if(Cl_ID != INVALID_ADMIN_ID)
		return true;
	return false;
}

stock bool:PlayerCheck(client, bool:fake = true)
{
	if(client <= 0 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	if(fake) if(IsFakeClient(client)) return false;
	return true;
}
