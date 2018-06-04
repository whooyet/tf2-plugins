#include <clientprefs>

public Plugin:myinfo = 
{
	name = "뿌까 YouTube Song",
	author = "뿌까",
	description = "Youtube Song",
	version = "1.3",
	url = "x"
}

new Handle:kv[500] = {INVALID_HANDLE, ...};

new MaxItem;
new vol[MAXPLAYERS+1];
new lastTime[MAXPLAYERS+1];

new String:LastSearch[MAXPLAYERS+1][256];
new String:LastSong[MAXPLAYERS+1][256];

new bool:StopSong[MAXPLAYERS+1];

Handle:volume_cookie;

new Handle:Enabled = INVALID_HANDLE;
new String:g_url[256];

public OnPluginStart()
{
	SetCover();
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_ysearch", CommandSerach, 0);
	RegAdminCmd("sm_yvol", CommandVolume, 0);
	RegAdminCmd("sm_ymenu", CommandSongMenu, 0);
	RegAdminCmd("sm_yopen", CommandSongOpen, 0);
	RegAdminCmd("sm_yall", CommandSongMenuAll, ADMFLAG_KICK);
	
	RegAdminCmd("sm_ystop", CommandStopSong, 0);
	RegAdminCmd("sm_ystopall", CommandStopAllSong, ADMFLAG_KICK);
	
	RegAdminCmd("sm_yreload", CommandReloaConfig, ADMFLAG_KICK);
	
	Enabled = CreateConVar("sm_youtube", "x");
	GetConVarString(Enabled, g_url, sizeof(g_url));
	HookConVarChange(Enabled, ConVarChanged);
	
	volume_cookie = RegClientCookie("sm_youtube_volume", "0 ~ 100", CookieAccess_Protected);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			vol[i] = 75;
			LastSearch[i] = "";
			LastSong[i] = "";
			
			if(AreClientCookiesCached(i)) OnClientCookiesCached(i);
		}
	}
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) GetConVarString(cvar, g_url, sizeof(g_url));

public OnMapStart() SetCover();
public OnMapEnd() for(new i = 0 ; i < 500 && i < MaxItem; i++) if(kv[i] != INVALID_HANDLE) CloseHandle(kv[i])

public OnClientPutInServer(client)
{
	lastTime[client] = 0;
	LastSong[client] = "";
	LastSearch[client] = "";
	StopSong[client] = true;
	vol[client] = 25;
	
	if(AreClientCookiesCached(client)) OnClientCookiesCached(client);
}

public OnClientCookiesCached(client){
	char temp[3];
	GetClientCookie(client, volume_cookie, temp, sizeof(temp));
	LogMessage("볼륨 쿠키 %N : %s", client, temp);
	if(!StrEqual(temp, "")) vol[client] = StringToInt(temp);
}

public Action:CommandSerach(client, args)
{
	decl String:arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(StrEqual(arg, ""))
	{
		ReplyToCommand(client, "Usage: sm_ysearch <song>");
		return Plugin_Handled;
	}
	
	SearchMusic(client, arg, 0, true);
	return Plugin_Handled;
}

public Action:CommandVolume(client, args)
{
	decl String:arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(StrEqual(arg, ""))
	{
		ReplyToCommand(client, "Usage: sm_yvolume <0 ~ 100> (현재: %d)", vol[client]);
		return Plugin_Handled;
	}
	
	vol[client] = StringToInt(arg);
	PrintToChat(client, "\x03볼륨 설정이되었습니다. (%d)", vol[client]);
	
	Format(arg, sizeof(arg), "%d", StringToInt(arg));
	SetClientCookie(client, volume_cookie, arg);
	
	if(!StrEqual(LastSong[client], "")) PlayMusic(client, LastSong[client], GetTime()-lastTime[client]-8, false);
	if(!StrEqual(LastSearch[client], "")) SearchMusic(client, LastSearch[client], GetTime()-lastTime[client]-8, false);
	return Plugin_Handled;
}

public Action:CommandSongMenu(client, args) // 여기서 손 보면 댐
{
	SongMenu(client, 0);
	return Plugin_Handled;
}

public Action:CommandSongMenuAll(client, args)
{
	SongMenu(client, 1);
	return Plugin_Handled;
}

public Action:CommandSongOpen(client, args)
{
	if(StopSong[client])
	{
		ReplyToCommand(client, "\x03노래를 키지 않았습니다.");
		return Plugin_Handled;
	}
	
	if(!StrEqual(LastSong[client], "")) PlayMusic(client, LastSong[client], GetTime()-lastTime[client]-8, true);
	if(!StrEqual(LastSearch[client], "")) SearchMusic(client, LastSearch[client], GetTime()-lastTime[client]-8, true);
	return Plugin_Handled;
}

public Action:CommandReloaConfig(client, args)
{
	SetCover();
	PrintToChat(client, "\x03리로드되었습니다.");
	return Plugin_Handled;
}


stock SongMenu(client, num)
{
	decl String:SearchWord[16], SearchValue, String:name[256], String:SongName[256], open;
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	
	new Handle:menu;
	if(num == 0) menu = CreateMenu(song_select);
	else menu = CreateMenu(song_select2);
	
	SetMenuTitle(menu, "추천 노래 리스트", client);
	AddMenuItem(menu, "랜덤", "랜덤");
		
	for(new i = 0 ; i < MaxItem ; i++)
	{
		if(kv[i] != INVALID_HANDLE)
		{
			GetArrayString(kv[i], 0, name, sizeof(name));
			GetArrayString(kv[i], 1, SongName, sizeof(SongName));
			open = GetArrayCell(kv[i], 2);
		}
		
		new String:temp[256];
		Format(temp, sizeof(temp), "%s**%s**%d", name, SongName, open);
			
		if(StrContains(name, SearchWord, false) > -1)
		{
			AddMenuItem(menu, temp, name);  
			SearchValue++;
		}
	}
	
	if(!SearchValue) PrintToChat(client, "\x03이름이 잘못되었거나 없는 이름입니다.");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public song_select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{ 
		decl String:name[256], String:aa[3][256];
		GetMenuItem(menu, select, name, sizeof(name));
		ExplodeString(name, "**", aa, 3, 256);
		
		new open = StringToInt(aa[2]);

		if(StrEqual(name, "랜덤")) SetRandomSong(client);
		else
		{
			PlayMusic(client, aa[1]);
			if(open == 1) CreateTimer(0.5, oopen, client);
			PrintToChatAll("\x04%N\x07FFFFFF님이 \x04%s \x07FFFFFF노래를 듣습니다.", client, aa[0]);
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public song_select2(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{ 
		decl String:name[256], String:aa[3][256];
		GetMenuItem(menu, select, name, sizeof(name));
		ExplodeString(name, "**", aa, 3, 256);
		
		new open = StringToInt(aa[2]);
		
		if(StrEqual(name, "랜덤")) SetRandomSong(client, true);
		else
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i))
				{
					PlayMusic(i, aa[1]);
					if(open == 1) CreateTimer(0.5, oopen, i);
				}
			}
			PrintToChatAll("\x04Admin\x07FFFFFF님이 \x04%s \x07FFFFFF노래를 틀었습니다.", aa[0]);
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action:oopen(Handle:timer, any:client) FakeClientCommandEx(client, "sm_yopen");

public Action:CommandStopSong(client, args)
{
	SetUrl(client, "about:blank");
	StopSong[client] = true;
	PrintToChat(client, "\x03노래를 중지했습니다.");
	return Plugin_Handled;
}

public Action:CommandStopAllSong(client, args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SetUrl(i, "about:blank");
			StopSong[i] = true;
		}
	}
	PrintToChatAll("\x03어드민이 노래를 중지했습니다.");
	return Plugin_Handled;
}

stock SetRandomSong(client, bool:check = false)
{
	decl String:SongName[256], String:SongTitle[256];

	new random = GetRandomInt(0, MaxItem);
	GetArrayString(kv[random], 0, SongTitle, sizeof(SongTitle));
	GetArrayString(kv[random], 1, SongName, sizeof(SongName));
		
	if(!check)
	{
		PlayMusic(client, SongName);
		PrintToChatAll("\x04%N\x07FFFFFF님이 \x04%s \x07FFFFFF노래를 듣습니다.", client, SongTitle);
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i)) PlayMusic(i, SongName);
		PrintToChatAll("\x04Admin\x07FFFFFF님이 \x04%s \x07FFFFFF노래를 틀었습니다.", SongTitle);
	}
	
}

stock SearchMusic(client, String:text[], time = 0, bool:open = false)
{
	new String:temp[256];
	if(time == 0) Format(temp, sizeof(temp), "%s?q=%s&vol=%d", g_url, text, vol[client]);
	else Format(temp, sizeof(temp), "%syousearch.php?q=%s&vol=%d&time=%d", g_url, text, vol[client], time);
	SetUrl(client, temp, open);

	StopSong[client] = false;
	
	Format(LastSearch[client], 256, "%s", text);
	LastSong[client] = "";
	lastTime[client] = GetTime();
}

stock PlayMusic(client, String:text[], time = 0, bool:open = false)
{
	new String:temp[256];
	Format(temp, sizeof(temp), "%syoutube.php?q=%s&vol=%d&time=%d", g_url, text, vol[client], time);
	SetUrl(client, temp, open);
	
	StopSong[client] = false;
	
	Format(LastSong[client], 256, "%s", text);
	LastSearch[client] = "";
	lastTime[client] = GetTime();
}

stock SetUrl(client, String:url[256], bool:open = false)
{
	new Handle:site = CreateKeyValues("data");
	
	KvSetString(site, "title", "tts");
	KvSetNum(site, "type", MOTDPANEL_TYPE_URL);
	KvSetString(site, "msg", url);
	
	ShowVGUIPanel(client, "info", site, open);
	CloseHandle(site);
}

stock Float:Convert_Time(const String:buffer[])
{
	decl String:part[5];
	new pos = SplitString(buffer, ":", part, sizeof(part));
	if (pos == -1)
		return StringToFloat(buffer);
	else
	{
		// Convert from mm:ss to seconds
		return (StringToFloat(part)*60.0) +
				StringToFloat(buffer[pos]);
	}
}

stock SetCover()
{
	decl String:strPath[192], String:szBuffer[256];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/youtube.cfg");
	new count = 0;
	
	new Handle:DB = CreateKeyValues("youtube");
	FileToKeyValues(DB, strPath);

	if(KvGotoFirstSubKey(DB))
	{
		do
		{
			kv[count] = CreateArray(540);
			
			KvGetSectionName(DB, szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);		
			
			KvGetString(DB, "video", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			PushArrayCell(kv[count], KvGetNum(DB, "open"));
			count++;
		}
		while(KvGotoNextKey(DB));
	}
	CloseHandle(DB);
	MaxItem = count;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
