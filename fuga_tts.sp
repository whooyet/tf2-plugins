public Plugin:myinfo = 
{
	name = "뿌까 TTS",
	author = "뿌까",
	description = "Chat Speech",
	version = "1.0",
	url = "x"
}

new String:TTS[MAXPLAYERS+1][12];
new Speed[MAXPLAYERS+1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_vo", CommandTTS, ADMFLAG_KICK);
	RegAdminCmd("sm_vsetting", SettingTTS, ADMFLAG_KICK);
}

public OnClientPutInServer(client)
{
	TTS[client] = "mijin";
	Speed[client] = 0;
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			TTS[i] = "mijin";
			Speed[i] = 0;
		}
	}
}		

public Action:CommandTTS(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "Usage: sm_vo <player> <text>");
		return Plugin_Handled;
	}
	
	decl String:arg[64], String:arg2[256];
	
	GetCmdArg(1, arg, sizeof(arg));

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new String:temp[256];
	
	GetCmdArgString(arg2, sizeof(arg2));
	ReplaceString(arg2, 255, arg, "");
	
	TrimString(arg2);
	StripQuotes(arg2);
	
	if (!arg2[0])
	{
		ReplyToCommand(client, "Usage: sm_vo <player> <text>");
		return Plugin_Handled;
	}
	
	Format(temp, sizeof(temp), "http://secret77.codns.com/aa.php?text=%s&speeker=%s&speed=%d", arg2, TTS[client], Speed[client]);
	// PrintToChatAll(temp);
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		SetUrl(user, temp);
	}
	return Plugin_Handled;
}

public Action:SettingTTS(client, args)
{
	Setting(client);
	return Plugin_Handled;
}

public Setting(client)
{
	new Handle:info = CreateMenu(SettingSelect);
	SetMenuTitle(info, "TTS 설정");
	
	AddMenuItem(info, "1", "나라 목소리 설정");  
	AddMenuItem(info, "2", "목소리 속도 설정");  
	
	SetMenuExitButton(info, true);
	DisplayMenu(info, client, 30);
}

public SettingSelect(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0) SetVoice(client);
		else if(select == 1) SetSpeed(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

stock SetVoice(client)
{
	new Handle:info = CreateMenu(VoiceSelect);
	SetMenuTitle(info, "TTS 목소리 설정");
	
	AddMenuItem(info, "mijin", "한국 여자 목소리");  
	AddMenuItem(info, "jinho", "한국 남자 목소리");  
	AddMenuItem(info, "yuri", "일본 여자 목소리");  
	AddMenuItem(info, "shinji", "일본 남자 목소리");  
	AddMenuItem(info, "clara", "영어 여자 목소리 (한글 X)");  
	AddMenuItem(info, "matt", "영어 남자 목소리 (한글 X)");  
	
	AddMenuItem(info, "meimei", "중국 여자 목소리 (한글 X)");  
	AddMenuItem(info, "liangliang", "중국 남자 목소리 (한글 X)");
	
	AddMenuItem(info, "jose", "스페인 여자 목소리 (한글 X)");  
	AddMenuItem(info, "carmen", "스페인 남자 목소리 (한글 X)"); 
	
	SetMenuExitButton(info, true);

	DisplayMenu(info, client, 30);
} 

public VoiceSelect(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[12];
		GetMenuItem(menu, select, info, sizeof(info));
		TTS[client] = info;
		Setting(client);
		PrintToChat(client, "\x03설정되었습니다.");
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

stock SetSpeed(client)
{
	new Handle:info = CreateMenu(SpeedSelect);
	SetMenuTitle(info, "TTS 속도 줄이기");
	
	AddMenuItem(info, "0", "정상");  
	AddMenuItem(info, "1", "1");  
	AddMenuItem(info, "2", "2");  
	AddMenuItem(info, "3", "3");  
	AddMenuItem(info, "4", "4");  
	AddMenuItem(info, "5", "5");  

	SetMenuExitButton(info, true);

	DisplayMenu(info, client, 30);
} 

public SpeedSelect(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[12];
		GetMenuItem(menu, select, info, sizeof(info));
		Speed[client] = StringToInt(info);
		Setting(client);
		PrintToChat(client, "\x03설정되었습니다. (%d)", Speed[client]);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

stock SetUrl(client, String:url[256])
{
	new Handle:kv = CreateKeyValues("data");
	
	KvSetString(kv, "title", "tts");
	KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
	KvSetString(kv, "msg", url);
	
	ShowVGUIPanel(client, "info", kv, false);
	CloseHandle(kv);
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
