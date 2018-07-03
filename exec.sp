#include <sourcemod>

public Plugin myinfo = 
{
	name = "exec",
	author = "뿌까",
	description = "하하하하",
	version = "1.0",
	url = "x"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_ugc", pug);
}

public OnConfigsExecuted()
{
	SetConVarInt(FindConVar("sm_chat_mode"),0)
}

public Action:pug(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[SM]\x03!ugc 66 hl pro bball ulti 0");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	SetConfig(client, arg);
	return Plugin_Handled;
}

stock SetConfig(client, String:ugc[])
{
	if(StrEqual(ugc, "hl"))
	{
		// SetConVarInt(FindConVar("sm_pug_hl"), 1);
		// SetConVarInt(FindConVar("sm_pug_max"), 18);
		
		if(IsCpMap()) ServerCommand("exec ugc_HL_standard");
		else if(IsPlMap()) ServerCommand("exec ugc_HL_stopwatch");
		else if(IsKothMap()) ServerCommand("exec ugc_HL_koth");
	}
	else if(StrEqual(ugc, "66"))
	{
		// SetConVarInt(FindConVar("sm_pug_hl"), 0);
		// SetConVarInt(FindConVar("sm_pug_max"), 12);
		
		if(IsKothMap()) ServerCommand("exec afckoth");
		else ServerCommand("exec afcpush");
	}
	else if(StrEqual(ugc, "pro"))
	{
		ServerCommand("exec afcpush");
		ServerCommand("exec prolander");
	}
	else if(StrEqual(ugc, "bball")) ServerCommand("exec bball");
	else if(StrEqual(ugc, "ulti")) ServerCommand("exec tfcl_ulti");

	else if(StrEqual(ugc, "0")) ServerCommand("exec ugc_off");
	else PrintToChat(client, "\x07FFFFFF66, 99 둘 중 하나만 적어주세요");
}

stock bool:IsCpMap2()
{
	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	return StrContains(strMap, "cp_", false) == 0;
}

stock bool:IsCpMap()
{
	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	return StrContains(strMap, "cp_", false) == 0;
}

stock bool:IsPlMap()
{
	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	return StrContains(strMap, "pl_", false) == 0;
}

stock bool:IsKothMap()
{
	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	return StrContains(strMap, "koth_", false) == 0;
}