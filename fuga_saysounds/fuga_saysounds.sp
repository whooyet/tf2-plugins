#include <sdktools>
#include <morecolors>
#include <soundlib>

#define MAX 99

enum Sound_enum
{
	String:SaySound[256],
	String:SayFile[256],
	String:SaySoundTitle[256],
	SayOverLap,
	SayAdmin,
	bool:SayCheck,
	MAX_Config
};

new Pucca[MAX][Sound_enum];
new Float:CheckTime[MAX];
new CheckSoundOverLap;

new Handle:g_hHudSync;

new Float:SaySoundDelay[MAXPLAYERS+1];

new Handle:SayX = INVALID_HANDLE;
new Handle:SayY = INVALID_HANDLE;
new Handle:SayR = INVALID_HANDLE;
new Handle:SayG = INVALID_HANDLE;
new Handle:SayB = INVALID_HANDLE;
new Handle:SayA = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "덜덜 SaySounds",
	author = "뿌까",
	description = "하하하하",
	version = "2.0",
	url = "x"
};

public OnPluginStart()
{
	if(!SoundConfig()) return;
	for(new i = 0; i < MAX; i++) CheckTime[i] = 0.0;
	CheckSoundOverLap = -1;
	
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
}

public OnMapStart()
{
	if(!SoundConfig()) return;
	new String:temp[256];
	for(new i = 0; i < MAX; i++)
	{
		if(Pucca[i][MAX_Config] == MAX)
		{
			Format(temp, sizeof(temp), "sound/%s", Pucca[i][SayFile]);
			PrecacheSound(Pucca[i][SayFile], true);
			AddFileToDownloadsTable(temp);
		}
	}
}

public OnClientConnected(client) SaySoundDelay[client] = 0.0;

public Action:OnPlayerRunCmd(client, &buttons) 
{
	SetHudTextParams(GetConVarFloat(SayX), GetConVarFloat(SayY), 0.1, GetConVarInt(SayR), GetConVarInt(SayG), GetConVarInt(SayB), GetConVarInt(SayA), 0, 0.0, 0.0, 0.0);
	
	for(new i = 0; i < MAX; i++)
	{
		if(Pucca[i][MAX_Config] == MAX)
		{
			if(Pucca[i][SayCheck])
			{
				if(Pucca[i][SayOverLap] == 1 && CheckSoundOverLap == i)
				{
					if(PlayerCheck(client))
					{
						if(buttons & IN_SCORE) ClearSyncHud(client, g_hHudSync);
						else ShowSyncHudText(client, g_hHudSync, "song: %s", Pucca[i][SaySoundTitle]);
					}
				}
					
				new Float:time = FileSecond(Pucca[i][SayFile]);
				new Float:current_time = GetEngineTime() - CheckTime[i];

				if(time <= current_time)
				{
					ClearSyncHud(client, g_hHudSync);
					if(CheckSoundOverLap == i) CheckSoundOverLap = -1;
					Pucca[i][SayCheck] = false;
					CheckTime[i] = 0.0;
				}
			}
		}
	}
}

public Action:Say(client, String:command[], argc)
{
	decl String:text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	new bool:a;
	if(acv()) a = true;
	else a = false;

	for(new i = 0; i < MAX; i++)
	{
		if(Pucca[i][MAX_Config] == MAX)
		{
			if(StrEqual(text, Pucca[i][SaySound]))
			{
				if(CheckSoundCoolTime(client, 3.0))
				{
					if(a && Pucca[i][SayOverLap] == 1)
					{
						PrintToChat(client, "\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x04중복으로 틀 수 없습니다.");
						return Plugin_Handled;
					}
					
					if(Pucca[i][SayAdmin] == 1 && !IsClientAdmin(client))
					{
						PrintToChat(client, "\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x04당신은 이 노래를 틀 수 없습니다.");
						return Plugin_Handled;	
					}
					if(Pucca[i][SayOverLap] == 1) CheckSoundOverLap = i;
					
					CheckTime[i] = GetEngineTime();
					EmitSoundToAll(Pucca[i][SayFile], _, _, _, _, 1.0);
					Pucca[i][SayCheck] = true;
					PrintToChatAll("\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x0700ccff%N\x07FFFFFF 님이 \x04%s \x07FFFFFF노래를 틀었습니다.", client, Pucca[i][SaySound]);
					SaySoundDelay[client] = GetEngineTime();
					return Plugin_Handled;
				}
				else PrintToChat(client, "\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x043초 후에 다시 사용 가능 합니다.");
			}
		}
	}
	return Plugin_Continue;
}

public Action:SayStop(client, args)
{
	for(new i = 0; i < MAX; i++) if(Pucca[i][MAX_Config] == MAX) if(Pucca[i][SayCheck]) StopSound(client, SNDCHAN_AUTO, Pucca[i][SayFile]);
	PrintToChat(client, "\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x04노래가 꺼졌습니다.");
	return Plugin_Handled;
}

public Action:SayAllStop(client, args) 
{
	for(new i = 0; i < MAX; i++)
	{
		if(Pucca[i][MAX_Config] == MAX)
		{
			if(Pucca[i][SayCheck])
			{
				for(new all = 1; all <= MaxClients; all++)
				{
					if(PlayerCheck(all))
					{
						StopSound(all, SNDCHAN_AUTO, Pucca[i][SayFile]);
						ClearSyncHud(all, g_hHudSync);
					}
				}
				Pucca[i][SayCheck] = false;
				if(CheckSoundOverLap == i) CheckSoundOverLap = -1;
			}
		}
	}
	PrintToChatAll("\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x0700ccff%N\x07FFFFFF 님이 노래를 껏습니다.", client);
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
	
	for(new i = 0; i < MAX; i++)
	{
		if(Pucca[i][MAX_Config] == MAX)
		{
			if(!IsClientAdmin(client))
			{
				if(Pucca[i][SayAdmin] == 0)
				{
					IntToString(i, temp, sizeof(temp));
					AddMenuItem(menu, temp, Pucca[i][SaySound]);
				}
			}
			else
			{
				IntToString(i, temp, sizeof(temp));
				AddMenuItem(menu, temp, Pucca[i][SaySound]);
			}
		}
	} 
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
} 

public Sound_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{ 
		if(CheckSoundCoolTime(client, 3.0))
		{
			decl String:info[10];
			GetMenuItem(menu, select, info, sizeof(info));
			
			new j = StringToInt(info);
			new bool:a;
			if(acv()) a = true;
			else a = false;
			
			for(new i = 0; i < MAX; i++)
			{
				if(Pucca[i][MAX_Config] == MAX)
				{
					if(a && Pucca[j][SayOverLap] == 1)
					{
						PrintToChat(client, "\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x04중복으로 틀 수 없습니다.");
						return;
					}
						
					if(Pucca[j][SayAdmin] == 1 && !IsClientAdmin(client))
					{
						PrintToChat(client, "\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x04당신은 이 노래를 틀 수 없습니다.");
						return;	
					}
					if(Pucca[j][SayOverLap] == 1) CheckSoundOverLap = j;
						
					CheckTime[j] = GetEngineTime();
					EmitSoundToAll(Pucca[j][SayFile]);
					Pucca[j][SayCheck] = true;
					PrintToChatAll("\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x0700ccff%N\x07FFFFFF 님이 \x04%s \x07FFFFFF노래를 틀었습니다.", client, Pucca[j][SaySound]);
					SaySoundDelay[client] = GetEngineTime();
					return;
				}
			}
		}
		else PrintToChat(client, "\x07FFFFFF[\x07ff0000덜덜 \x07FFFFFFSaySounds] \x043초 후에 다시 사용 가능 합니다.");
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

stock acv()
{
	for(new i = 0; i < MAX; i++) if(Pucca[i][MAX_Config] == MAX) if(Pucca[i][SayCheck] && CheckSoundOverLap == i) return true;
	return false;
}

bool:SoundConfig()
{
	decl String:strPath[192], String:strSection[15];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/fuga_saysounds.cfg");
	
	if(!FileExists(strPath))
	{
		SetFailState("Failed to find fuga_saysounds.cfg");
		return false;
	}
	
	new Handle:hKv = CreateKeyValues("sound");
	if(FileToKeyValues(hKv, strPath) && KvGotoFirstSubKey(hKv))
	{
		do
		{
			KvGetSectionName(hKv, strSection, sizeof(strSection));
			new num = StringToInt(strSection);
			if(num < 0 || num >= sizeof(Pucca))
			{
				LogMessage("fuga_saysounds index: \"%s\" is not valid. Must be between 0 - %d. Edit the fuga_saysounds.cfg File", strSection, sizeof(Pucca));
				continue;
			}
			
			KvGetString(hKv, "say", Pucca[num][SaySound], 256);
			KvGetString(hKv, "file", Pucca[num][SayFile], 256);
			// KvGetString(hKv, "time", Pucca[num][SaySoundTime], 64, "0:0");
			KvGetString(hKv, "title", Pucca[num][SaySoundTitle], 256, "제목 없음");
			Pucca[num][SayAdmin] = KvGetNum(hKv, "admin");
			Pucca[num][SayOverLap] = KvGetNum(hKv, "overlap");
			Pucca[num][MAX_Config] = MAX;

		}while(KvGotoNextKey(hKv));
		
		if(hKv != INVALID_HANDLE) CloseHandle(hKv);
		return true;
	}
	
	if(hKv != INVALID_HANDLE) CloseHandle(hKv);
	return false;
}

stock Float:Convert_Time(const String:buffer[])
{
	decl String:part[5];
	new pos = SplitString(buffer, ":", part, sizeof(part));
	if (pos == -1) return StringToFloat(buffer);
	else return (StringToFloat(part)*60.0) + StringToFloat(buffer[pos]);
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

stock bool:CheckSoundCoolTime(any:iClient, Float:fTime)
{
	if(GetEngineTime() - SaySoundDelay[iClient] >= fTime) return true;
	else return false;
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
