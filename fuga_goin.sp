#include <chat-processor>

new bool:tag[33];

public Plugin myinfo = 
{
	name = "고인물",
	author = "뿌까",
	description = "하하하하",
	version = "1.0",
	url = "x"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_goin", CommandGoInMool, ADMFLAG_KICK);
}

public Action:CommandGoInMool(client, args)
{
	decl String:arg[64];
	GetCmdArgString(arg, sizeof(arg));
	
	if(StrEqual(arg, ""))
	{
		ReplyToCommand(client, "Usage: sm_goin <player>");
		return Plugin_Handled;
	}
	
	decl String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/goin.txt");
	
	new Handle:hFile = OpenFile(sPath, "a+");
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
	
		if (!PlayerCheck(user)) return Plugin_Handled;
		
		
		decl String:steamID[64], String:Steam64[256];
		GetClientAuthId(user, AuthId_Steam2, steamID, sizeof(steamID));
		GetClientAuthId(user, AuthId_SteamID64, Steam64, sizeof(Steam64));
		
		if(hFile != INVALID_HANDLE)
		{
			WriteFileLine(hFile, "%s http://steamcommunity.com/profiles/%s", steamID, Steam64);
			tag[user] = true;
			FlushFile(hFile);
			CloseHandle(hFile);
		}
	}
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	tag[client] = false;
	
	decl String:steamID[64];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	
	decl String:sPath[PLATFORM_MAX_PATH], String:yes[256], String:aa[2][64];

	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/goin.txt");
	
	new Handle:hFile;
	if(FileExists(sPath, true))
	{
		hFile = OpenFile(sPath, "r");
		while(ReadFileLine(hFile, yes, sizeof(yes)))
		{
			ExplodeString(yes, " ", aa,2,64);
			if(StrEqual(steamID, aa[0]))
			{
				tag[client] = true;
			}
		}
		FlushFile(hFile);
		CloseHandle(hFile);
	}
	else LogMessage("고인물 파일이 없습니다.");
	// return Plugin_Handled;
}

public Action: CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	if(tag[author]) Format(name, MAXLENGTH_NAME, "\x04[고인물] \x03%s", name);
	return Plugin_Changed;
}

stock bool:PlayerCheck(Client){
	if(Client > 0 && Client <= MaxClients){
		if(IsClientConnected(Client) == true){
			if(IsClientInGame(Client) == true){
				return true;
			}
		}
	}
	return false;
}