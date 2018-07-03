public Plugin myinfo = 
{
	name = "MapList (pm)",
	author = "뿌까",
	description = "하하하하",
	version = "1.0",
	url = "x"
};

public OnPluginStart()
{
	HookEvent("teamplay_game_over", GameOver);
	HookEvent("tf_game_over", GameOver);
	// HookEvent("player_spawn", GameOver);
	RegAdminCmd("sm_pm", MapList, 0);
}

public Action:GameOver(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sMap[256], String:year[20], String:mon[20], String:day[20];
	GetCurrentMap(sMap, sizeof(sMap));
	
	FormatTime(year, sizeof(year), "%Y", -1);
	FormatTime(mon, sizeof(mon), "%m", -1);
	FormatTime(day, sizeof(day), "%d", -1);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/pm/%s-%s-%s.txt", year, mon, day);
	
	new Handle:hFile = OpenFile(sPath, "a+");
	if(hFile != INVALID_HANDLE)
	{
		WriteFileLine(hFile, "%s", sMap);
		FlushFile(hFile);
		CloseHandle(hFile);
	}
}

public Action:MapList(client, args)
{
	decl String:sPath[PLATFORM_MAX_PATH], String:year[20], String:mon[20], String:day[20], String:map[256];
	
	FormatTime(year, sizeof(year), "%Y", -1);
	FormatTime(mon, sizeof(mon), "%m", -1);
	FormatTime(day, sizeof(day), "%d", -1);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/pm/%s-%s-%s.txt", year, mon, day);
	
	new Handle:hFile;
	if(FileExists(sPath, true))
	{
		hFile = OpenFile(sPath, "r");
		while(ReadFileLine(hFile, map, sizeof(map)))
		{
			PrintToChat(client, map);
			PrintToServer(map);
		}
		FlushFile(hFile);
		CloseHandle(hFile);
	}
	else PrintToChatAll("\x04기록이 없습니다.");
	
	return Plugin_Handled;
}
