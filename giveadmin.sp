#include <morecolors>
#define PLUGIN_VERSION		"2.0"

public Plugin:myinfo = 
{
	name = "GiveAdmin",
	author = "3V0Lu710N",
	description = "Add an admin during the game with sm_giveadmin",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("smgiveadmin_version", PLUGIN_VERSION, "GiveAdmin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_giveadmin", Command_GiveAdmin, 0, "Adds an admin to admins_simple.ini");
}

public Action:Command_GiveAdmin(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_giveadmin <name or #userid> <flags>");
		return Plugin_Handled;
	}
	
	char identity[MAX_NAME_LENGTH];
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetClientName(client, identity, sizeof(identity));
	
	char szTargetId[64], szTarget[64], szName[MAX_NAME_LENGTH], szFlags[20], cName[MAX_NAME_LENGTH]; 

	GetCmdArg(1, szTarget, sizeof(szTarget));
	GetCmdArg(2, szFlags, sizeof(szFlags));
	GetCmdArg(3, cName, sizeof(cName));
	
	int target = FindTarget(client, szTarget);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	GetClientAuthId(target, AuthId_Steam2, szTargetId, sizeof(szTargetId));
	GetClientName(target, szName, sizeof(szName));

	char szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"%s\" // %s", szTargetId, szFlags, cName);

	CloseHandle(hFile);
	
	if(StrContains(szFlags, "z") == 0)
	{
		Format(szFlags, sizeof(szFlags), "ROOT");
	}
	
	// Prints to chat your target's info
	CPrintToChatAll("{limegreen}[SM] New Admin Sucessfully added:");
	CPrintToChatAll("{limegreen}Name: %s", szName);
	CPrintToChatAll("{limegreen}Steam ID: %s", szTargetId);
	CPrintToChatAll("{limegreen}Access: %s", szFlags);
	
	ServerCommand("sm_reloadadmins");

	return Plugin_Handled;
}