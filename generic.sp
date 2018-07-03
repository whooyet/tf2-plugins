#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
// #include <sourcemod-misc>
#include <sdkhooks>
#include <gmg\core> 
#include <gmg\misc>

#define flag ADMFLAG_KICK 
#define FUCCA "\x07FF1493[뿌까] "
// #define flag 0

new Float:rof[MAXPLAYERS+1];
new see[MAXPLAYERS+1];
new bool:seeb[MAXPLAYERS+1];
new bool:god[MAXPLAYERS+1];
new bool:jump[MAXPLAYERS+1];
new bool:bjump[MAXPLAYERS+1];
new bool:party[MAXPLAYERS+1];
new Float:sPos[MAXPLAYERS+1][2][3];

new sec;

public Plugin:myinfo = 
{
	name = "Generic Admin Commands",
	author = "Pelipoika + fucca",
	description = "A bunch of general admin commands",
	version = "1.4.6",
	url = "googlehammer.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_bring", Command_bring, flag, "플레이어를 데려옵니다.");
	RegAdminCmd("sm_goto", Command_Goto, flag, "플레이어에게 갑니다.");
	RegAdminCmd("sm_warp", Command_Warp, flag, "에임 둔 곳으로 이동합니다.");
	RegAdminCmd("sm_cri", Command_Crits, flag, "크리티컬을 킵니다.");
	RegAdminCmd("sm_god", Command_God, flag, "무적이됩니다. (buddha mod)");
	RegAdminCmd("sm_stun", Command_Stun, flag, "스턴에 걸리게합니다.");
	RegAdminCmd("sm_hp", Command_Health, flag, "체력을 조절합니다.");
	RegAdminCmd("sm_class", Command_Class, flag, "클래스를 변경합니다.");
	RegAdminCmd("sm_team", Command_Team, flag, "팀을 변경합니다.");
	RegAdminCmd("sm_scramble", Command_Scramble, flag, "팀을 섞습니다.");
	RegAdminCmd("sm_spawn", Command_Respawn, flag, "리스폰합니다.");
	RegAdminCmd("sm_players", Command_Players, flag, "접속된 유저의 정보를 볼 수 있습니다.");
	RegAdminCmd("sm_cond", Command_Addcond, flag, "치트를 사용합니다. (치트 번호)");
	RegAdminCmd("sm_restart", Command_Restart, flag, "라운드를 재시작합니다.");
	RegAdminCmd("sm_rof", Command_Rof, flag, "공속을 조절할 수 있습니다.");
	RegAdminCmd("sm_seeyou", Command_SeeYou, flag, "특정 타겟의 행동을 확인합니다 (Reload Key)");
	RegAdminCmd("sm_jump", Command_Jump, flag, "솔저, 데모맨 유저에게 탄약과 무적으로 점프에 도움을 줍니다.");
	RegAdminCmd("sm_bj", Command_BotJump, flag, "모든 봇에게 점프모드를 적용합니다.");
	RegAdminCmd("sm_bot", Command_AddBot, flag, "봇을 스폰합니다.");
	RegAdminCmd("sm_party", Command_Party, flag, "@party와 함께 사용합니다.");
	RegAdminCmd("sm_ano", Command_Ano, flag, "에임 둔 곳에 메세지를 띄울 수 있습니다.");
	
	RegAdminCmd("sm_heads", Command_HeadSize, flag, "머리 크기를 조절할 수 있습니다.");
	RegAdminCmd("sm_bodys", Command_BodySize, flag, "몸이 길어지거나 짧아지거나 할 수 있습니다.");
	RegAdminCmd("sm_hands", Command_HandSize, flag, "손의 크기를 조절할 수 있습니다. (무기에도 영향이 끼칩니다.)");
	RegAdminCmd("sm_voices", Command_VoiceSpeed, flag, "목소리의 굵기를 조절할 수 있습니다.");
	RegAdminCmd("sm_taunts", Command_TauntSpeed, flag, "도발 속도를 변경할 수 있습니다.");
	RegAdminCmd("sm_size", Command_Size, flag, "전체적으로 몸이 커지거나 작아지거나 조절할 수 있습니다.");
	RegAdminCmd("sm_resetsize", Command_ResetSize, flag, "변경된 몸의 크기를 초기화합니다.");
	
	// RegAdminCmd("sm_randomp", Command_RandomPlayer, flag);
	RegAdminCmd("sm_3", Command_ThreeSec, flag, "3초 셉니다.");
	RegAdminCmd("sm_noattack", Command_NoAttack, flag, "공격할 수 없도록 합니다.");
	
	RegConsoleCmd("sm_wr", Command_Whisper, "귓속말 할 수 있습니다.");
	RegAdminCmd("sm_s", Command_SetOrigin, flag, "위치를 저장합니다.");
	RegAdminCmd("sm_t", Command_Teleport, flag, "위치에 텔레포트합니다.");
	
	AddMultiTargetFilter("@admin", admin, "all admin", false) // 모든 어드민
	AddMultiTargetFilter("@party", member, "PPPPPAAAARRRRTTTTYYYY", false) // 모든 파티원
	AddMultiTargetFilter("@rb", redbots, "all red bots", false) //모든 레드봇
	AddMultiTargetFilter("@bb", blubots, "all blu bots", false) //모든 블루 봇
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	
}

public OnMapStart()
{
	PrecacheSound(SOUND_TELE);
	
	PrecacheSound("vo/announcer_begins_3sec.mp3");
	PrecacheSound("vo/announcer_begins_2sec.mp3");
	PrecacheSound("vo/announcer_begins_1sec.mp3");
	
	PrecacheSound("vo/announcer_ends_3sec.mp3");
	PrecacheSound("vo/announcer_ends_2sec.mp3");
	PrecacheSound("vo/announcer_ends_1sec.mp3");
	
	PrecacheSound("vo/halloween_merasmus/sf14_merasmus_begins_03sec.mp3");
	PrecacheSound("vo/halloween_merasmus/sf14_merasmus_begins_02sec.mp3");
	PrecacheSound("vo/halloween_merasmus/sf14_merasmus_begins_01sec.mp3");
}

public OnClientPutInServer(client)
{
	if(rof[client] != 0.0) rof[client] = 0.0;
	if(see[client] != 0) see[client] = 0;
	if(seeb[client]) seeb[client] = false;
	if(god[client]) god[client] = false;
	if(jump[client]) jump[client] = false;
	if(bjump[client]) bjump[client] = false;
	if(party[client]) party[client] = false;
	
	for(new i = 0; i <= 2; i++)
	{
		sPos[client][0][i] = 0.0;
		sPos[client][1][i] = 0.0;
	}
		
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(jump[client] || god[client]) SetGod(client, true);
}

public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		decl String:steamID[64];
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));

		new String:reason[64];
		GetEventString(event, "reason", reason, sizeof(reason));

		if(StrContains(reason, "Timed out", false) != -1) CPrintToChatAll("{orange}%N{default} Timed out.", client);
	}
	return Plugin_Continue;
}

public Action:Command_bring(client, args)
{
	decl String:arg[64];
	GetCmdArgString(arg, sizeof(arg));
	
	if(StrEqual(arg, ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_bring <player>");
		return Plugin_Handled;
	}
	
	decl String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
	
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;
		
		if(user != client)
		{
			new Float:origin[3];
			GetCollisionPoint(client, origin);
			TeleportPlayer(user, origin, true);
			
			CPrintToChat(user, "%s{green}%N{white}님이 {green}%N{white}님을 이동시켰습니다.", FUCCA, client, user);
			if(user != client) CPrintToChat(client, "%s{white}%N님을 {green}이동{white}시켰습니다.", FUCCA, user);
		}
	}
	return Plugin_Handled;
}

public Action:Command_Goto(client, args)
{
	if(!IsPlayerAlive(client))
	{
		Fucca_ReplyToCommand(client, "살아 있지 않는 상태에선 불가능합니다.");
		return Plugin_Handled;
	}
	
	decl String:arg[64], target, Float:TargetOrigin[3];
	GetCmdArgString(arg, sizeof(arg));
	
	if(StrEqual(arg, ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_goto <player>");
		return Plugin_Handled;
	}
	
	if ((target = FindTarget(client, arg, false, true)) <= 0)
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}
	
	if(target == client) 
	{
		ReplyInvalidTarget(client);
		return Plugin_Handled;
	}

	GetClientAbsOrigin(target, TargetOrigin);
	TargetOrigin[2] += 20;
	TeleportPlayer(client, TargetOrigin, true);
	return Plugin_Handled;
}

public Action:Command_Warp(client, args)
{
	if(!IsPlayerAlive(client))
	{
		Fucca_ReplyToCommand(client, "살아 있지 않는 상태에선 불가능합니다.");
		return Plugin_Handled;
	}
	
	new Float:endPos[3];
	GetCollisionPoint(client, endPos);
	TeleportPlayer(client, endPos, true);
	return Plugin_Handled;
}

public Action:Command_Crits(client, args)
{
	decl String:arg[64];
	GetCmdArgString(arg, sizeof(arg));
	
	if(StrEqual(arg, ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_cri <player>");
		return Plugin_Handled;
	}
	
	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;
		
		TF2_AddCondition(user, TFCond_CritOnWin, -1.0);
		CPrintToChat(user, "%s{white}크리 {green}On", FUCCA);
		
		if(user != client) CPrintToChat(client, "%s{white}%N님이 {green}크리{white}를 사용합니다.", FUCCA, user);
	}
	return Plugin_Handled;
}

public Action:Command_God(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_god <player> <on / off>");
		return Plugin_Handled;
	}
	
	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;
		
		if(StrEqual(aa[1], "on"))
		{
			SetGod(user, true);
			CPrintToChat(user, "%s{white}무적 {green}On", FUCCA);
			god[user] = true;
			if(user != client) CPrintToChat(client, "%s{white}%N님이 {green}무적{white}을 사용합니다.", FUCCA, user);
		}
		else if(StrEqual(aa[1], "off"))
		{
			SetGod(user, false);
			CPrintToChat(user, "%s{white}무적 {green}Off", FUCCA);
			god[user] = false;
			if(user != client) CPrintToChat(client, "%s{white}%N님이 {green}무적{white}을 사용하지 않습니다.", FUCCA, user);
		}
	}
	return Plugin_Handled;
}

public Action:Command_Stun(client, args)
{
	if(args < 3)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_stun <player> <time> <message>");
		return Plugin_Handled;
	}
	
	new String:arg[32], String:arg2[10], String:arg3[256];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	GetCmdArgString(arg3, sizeof(arg3));
	ReplaceString(arg3, 255, arg, "");
	// ReplaceString(arg3, 255, arg2, "");
	
	TrimString(arg3);
	StripQuotes(arg3);
	
	if (!arg3[0])
	{
		Fucca_ReplyToCommand(client, "Usage: sm_stun <player> <time> <message>");
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;
		
		TF2_StunPlayer(user, StringToFloat(arg2), _, TF_STUNFLAGS_NORMALBONK);
		CPrintToChat(user, "%s{green}%N님 {green}스턴 %i초 {white}%s", FUCCA, user, StringToInt(arg2), arg3);
		
		if(user != client) CPrintToChat(client, "%s{white}%N님이 {green}스턴{white}을 받았습니다.", FUCCA, user);
	}
	return Plugin_Handled;
}

public Action:Command_Health(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_health <player> <amount>");
		return Plugin_Handled;
	}
	new health = StringToInt(aa[1]);
	
	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;
		
		new Gethp = GetClientHealth(client);
		SetHealth(user, Gethp, health);
		if(user != client) CPrintToChat(client, "%s{white}%N님은 {green}체력{white}이 증가되거나 감소되었습니다.", FUCCA, user);
	}
	return Plugin_Handled;
}

public Action:Command_Class(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_class <player> <1 ~ 9>");
		return Plugin_Handled;
	}
	
	new TFClassType:class;
	
	if(StrEqual(aa[1], "1", false)) class = TFClass_Scout;
	else if(StrEqual(aa[1], "2", false)) class = TFClass_Soldier;
	else if(StrEqual(aa[1], "3", false)) class = TFClass_Pyro;
	else if(StrEqual(aa[1], "4", false)) class = TFClass_DemoMan;
	else if(StrEqual(aa[1], "5", false)) class = TFClass_Heavy;
	else if(StrEqual(aa[1], "6", false)) class = TFClass_Engineer;
	else if(StrEqual(aa[1], "7", false)) class = TFClass_Medic;
	else if(StrEqual(aa[1], "8", false)) class = TFClass_Sniper;
	else if(StrEqual(aa[1], "9", false)) class = TFClass_Spy;
	else
	{
		ReplyToCommand(client, "%s\x07FFFFFF[SM] Invalid Class (\"%s\")", FUCCA, aa[1]);
		return Plugin_Handled;
	}
	
	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;
		
		decl Float:pos[3];
		GetClientAbsOrigin(user, pos);
		
		TF2_SetPlayerClass(user, class);
		TF2_RespawnPlayer(user);
		
		TeleportEntity(user, pos, NULL_VECTOR, NULL_VECTOR);
		
		if(user != client) CPrintToChat(client, "%s{white}%N님의 {green}클래스{white}가 변경되었습니다.", FUCCA, user);
	}

	return Plugin_Handled;
}

public Action:Command_Team(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_team <player> <2,3>");
		return Plugin_Handled;
	}
	
	new team = StringToInt(aa[1]);
	
	if(team > 3)
	{
		Fucca_ReplyToCommand(client, "\x03관전자팀은 1 레드팀은 2 | 블루팀은 3");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;
		if(team == 1 || team == 0) ChangeClientTeam(user, 1);
		else
		{
			if(!IsPlayerAlive(client)) ChangeClientTeam(user, team);
			else ChangeClientTeamAlive(user, team);
			
			CPrintToChat(user, "%s{green}%N{white}님의 팀이 변경되었습니다.", FUCCA, user);
			if(user != client) CPrintToChat(client, "%s{white}%N님의 {green}팀{white}을 변경하였습니다.", FUCCA, user);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Scramble(client, args)
{
	ServerCommand("mp_scrambleteams 1");
	Fucca_ReplyToCommand(client, "\x04팀을 섞습니다.");
	return Plugin_Handled;
}

public Action:Command_Respawn(client, args)
{
	decl String:arg[64];
	GetCmdArgString(arg, sizeof(arg));

	if(StrEqual(arg, ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_respawn <player>");
		return Plugin_Handled;
	}
	
	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;
		TF2_RespawnPlayer(user);
	}
	return Plugin_Handled;
}

public Action:Command_Players(client, args)
{
	new String:Search[64]
	GetCmdArgString(Search, sizeof(Search));
	PlayerMenu(client, Search);
	return Plugin_Handled;
}

public PlayerMenu(client, String:Search[])
{
	new Handle:menu = CreateMenu(Menu_PlayersList), count;
	SetMenuTitle(menu, "플레이어 목록 (Search On)");
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			decl String:info[8], String:display[100];
			Format(info, sizeof(info), "%i", i);
			
			if(IsClientAdmin(i)) Format(display, sizeof(display), "[어드민] %N", i);
			else Format(display, sizeof(display), "%N", i);
			
			if(StrContains(display, Search, false) > -1)
			{
				AddMenuItem(menu, info, display);
				count++;
			}
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public Menu_PlayersList(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[8];
		GetMenuItem(menu, select, info, sizeof(info))
		new user = StringToInt(info);
		
		new Handle:menu2 = CreateMenu(Menu_PlayersInfo);
		SetMenuTitle(menu2, "%N", user);

		new String:Steam2[32], String:Steam64[32], String:temp[100], String:playtime[100], String:id[256];
		
		GetClientAuthId(user, AuthId_Steam2, Steam2, sizeof(Steam2));
		GetClientAuthId(user, AuthId_SteamID64, Steam64, sizeof(Steam64));
		
		Format(temp, sizeof(temp), "http://steamcommunity.com/profiles/%s", Steam64);
		Format(playtime, sizeof(playtime), "https://steamcommunity.com/profiles/%s/stats/TF2", Steam64);
		Format(id, sizeof(id), "%s%\x0733ccff%N\x07FFFFFF 님의 고유번호: \x07ff9966%s\n\x07ff9966https://steamcommunity.com/profiles/%s/", FUCCA, user, Steam2, Steam64);
		
		AddMenuItem(menu2, temp, "스팀 프로필 이동");  
		AddMenuItem(menu2, playtime, "클래스 플탐 확인");  
		AddMenuItem(menu2, id, "고유번호와 주소 확인");  
		
		SetMenuExitBackButton(menu2, true);
		SetMenuExitButton(menu2, true);

		DisplayMenu(menu2, client, 60);
	}
	else if(action == MenuAction_Cancel) if(select == MenuCancel_ExitBack) PlayerMenu(client, "");
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Menu_PlayersInfo(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[256];
		GetMenuItem(menu, select, info, sizeof(info))
		
		if(select == 0) motd(client, info);
		else if(select == 1) motd(client, info);
		else if(select == 2) PrintToChat(client, info);
	}
	else if(action == MenuAction_Cancel) if(select == MenuCancel_ExitBack) PlayerMenu(client, "");
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action:Command_Addcond(client, args)
{
	new String:arg[256], String:aa[3][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 3, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], "") || StrEqual(aa[2], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_cond <player> <condid> <duration>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;

		new Float:duration = StringToFloat(aa[2]);
		new cond = StringToInt(aa[1]);
		
		TF2_AddCondition(user, TFCond:cond, duration);
		if(user != client) CPrintToChat(client, "%s{white}%N님은 {green}치트{white}를 사용합니다.", FUCCA, user);
	}
	
	return Plugin_Handled;
}

public Action:Command_Restart(client, args)
{
	ServerCommand("mp_restartgame 1");
	Fucca_ReplyToCommand(client, "\x04라운드를 다시 시작합니다.");
	return Plugin_Handled;
}

public Action:Command_Rof(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_rof <player> <amount>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;
		rof[user] = StringToFloat(aa[1]);
		CPrintToChat(user, "%s{white} 공속 %.1f", FUCCA, rof[user]);
		if(user != client) CPrintToChat(client, "%s{white}%N님의 {green}공속{white}이 변경되었습니다.", FUCCA, user);
	}
	return Plugin_Handled;
}

public Action:Command_SeeYou(client, args)
{
	decl String:arg[64];
	GetCmdArgString(arg, sizeof(arg));

	if(StrEqual(arg, ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_seeyou <player>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user) && !IsPlayerAlive(user)) return Plugin_Handled;

		see[client] = user;
		CPrintToChat(client, "%s{white}재장전 키로 관찰합니다.", FUCCA);
		CPrintToChat(user, "%s{white}누군가 당신을 보고 있습니다.", FUCCA);
	}
	
	return Plugin_Handled;
}

public Action:Command_Jump(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_jump <player> on / off");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "on"))
		{
			jump[user] = true;
			CPrintToChat(user, "%s{white}점프 모드 {green}On", FUCCA);
			SetGod(user, true);
		}
		else if(StrEqual(aa[1], "off"))
		{
			jump[user] = false;
			CPrintToChat(user, "%s{white}점프 모드 {green}Off", FUCCA);
			SetGod(user, false);
		}
		
		if(user != client) CPrintToChat(client, "%s{white}%N님 {green}점프 모드{white} %s", FUCCA, user, aa[1]);
	}
	
	return Plugin_Handled;
}
public Action:Command_BotJump(client, args)
{
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsFakeClient(i)) bjump[i] = true;
	CPrintToChat(client, "%s{white}봇 점프 모드 {green}On", FUCCA);
	return Plugin_Handled;
}

public Action:Command_AddBot(client, args)
{
	if(args != 1)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_bot <0 ~ 32>");
		return Plugin_Handled;
	}
	
	decl String:szTarget[10];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	
	ServerCommand("tf_bot_quota %d", StringToInt(szTarget));
	return Plugin_Handled;
}

public Action:Command_Party(client, args)
{
	decl String:arg[64];
	GetCmdArgString(arg, sizeof(arg));

	if(StrEqual(arg, ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_party <name>");
		return Plugin_Handled;
	}
	
	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;
		
		if(!party[user])
		{
			party[user] = true;
			CPrintToChat(user, "%s{white}파티에 참가하였습니다.", FUCCA);
		}
		else
		{
			party[user] = false;
			CPrintToChat(user,  "%s{white}파티에서 나갔습니다.", FUCCA);
		}
		if(user != client)
		{
			if(!party[user]) CPrintToChat(client, "%s{white}%N님이 파티에서 나갔습니다.", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님이 파티에 참가하였습니다.", FUCCA, user);
		}
	}
	return Plugin_Handled;
} 

public Action:Command_Ano(client, args)
{	
	if(args != 2)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_ano <msg> <life time>");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		Fucca_ReplyToCommand(client, "살아 있지 않는 상태에선 불가능합니다.");
		return Plugin_Handled;
	}
	
	new String:arg[256], String:arg2[10];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	new Float:endPos[3];
	GetCollisionPoint(client, endPos);
	
	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i)) Annotate(endPos, i, arg, 1, StringToFloat(arg2), -1);
	return Plugin_Handled;
}

public Action:Command_HeadSize(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_heads <player> <value>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "off"))
		{
			TF2Attrib_RemoveByDefIndex(user, 444);	
			if(user != client) CPrintToChat(user, "%s{white}%N님의 머리 크기 초기화", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님의 머리 크기 초기화", FUCCA, client);
		}
		else
		{
			TF2Attrib_SetByDefIndex(user, 444, StringToFloat(aa[1]));
			if(user != client) CPrintToChat(user, "%s{white}%N님의 머리 크기 {green}%1.f", FUCCA, user, StringToFloat(aa[1]));
			else CPrintToChat(client, "%s{white}%N님의 머리 크기 {green}%1.f", FUCCA, client, StringToFloat(aa[1]));
		}
	}
	return Plugin_Handled;
}

public Action:Command_BodySize(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_bodys <player> <value>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "off"))
		{
			TF2Attrib_RemoveByDefIndex(user, 620);	
			if(user != client) CPrintToChat(user, "%s{white}%N님의 몸통 초기화", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님의 몸통 크기 초기화", FUCCA, client);
		}
		else
		{
			TF2Attrib_SetByDefIndex(user, 620, StringToFloat(aa[1]));
			if(user != client) CPrintToChat(user, "%s{white}%N님의 몸통 크기 {green}%1.f", FUCCA, user, StringToFloat(aa[1]));
			else CPrintToChat(client, "%s{white}%N님의 몸통 크기 {green}%1.f", FUCCA, client, StringToFloat(aa[1]));
		}
	}
	return Plugin_Handled;
}

public Action:Command_HandSize(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_hands <player> <value>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "off"))
		{
			TF2Attrib_RemoveByDefIndex(user, 699);	
			if(user != client) CPrintToChat(user, "%s{white}%N님의 손 크기 초기화", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님의 손 크기 초기화", FUCCA, client);
		}
		else
		{
			TF2Attrib_SetByDefIndex(user, 699, StringToFloat(aa[1]));
			if(user != client) CPrintToChat(user, "%s{white}%N님의 손 크기 {green}%1.f", FUCCA, user, StringToFloat(aa[1]));
			else CPrintToChat(client, "%s{white}%N님의 손 크기 {green}%1.f", FUCCA, client, StringToFloat(aa[1]));
		}
	}
	return Plugin_Handled;
}

public Action:Command_VoiceSpeed(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_voices <player> <value>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "off"))
		{
			TF2Attrib_RemoveByDefIndex(user, 2048);	
			if(user != client) CPrintToChat(user, "%s{white}%N님의 음성 속도 초기화", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님의 음성 속도 초기화", FUCCA, client);
		}
		else
		{
			TF2Attrib_SetByDefIndex(user, 2048, StringToFloat(aa[1]));
			if(user != client) CPrintToChat(user, "%s{white}%N님의 음성 속도 {green}%f", FUCCA, user, StringToFloat(aa[1]));
			else CPrintToChat(client, "%s{white}%N님의 음성 속도 {green}%f", FUCCA, client, StringToFloat(aa[1]));
		}
	}
	return Plugin_Handled;
}

public Action:Command_TauntSpeed(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_taunts <player> <value>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "off"))
		{
			TF2Attrib_RemoveByDefIndex(user, 201);	
			if(user != client) CPrintToChat(user, "%s{white}%N님의 도발 속도 초기화", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님의 도발 속도 초기화", FUCCA, client);
		}
		else
		{
			TF2Attrib_SetByDefIndex(user, 201, StringToFloat(aa[1]));
			if(user != client) CPrintToChat(user, "%s{white}%N님의 도발 속도 {green}%1.f", FUCCA, user, StringToFloat(aa[1]));
			else CPrintToChat(client, "%s{white}%N님의 도발 속도 {green}%1.f", FUCCA, client, StringToFloat(aa[1]));
		}
	}
	return Plugin_Handled;
}

public Action:Command_Size(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_size <player> <value>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "off"))
		{
			SetSize(user, 1.0);	
			if(user != client) CPrintToChat(user, "%s{white}%N님의 몸 크기 초기화", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님의 몸 크기 초기화", FUCCA, client);
		}
		else
		{
			SetSize(user, StringToFloat(aa[1]));
			if(user != client) CPrintToChat(user, "%s{white}%N님의 몸 크기 {green}%1.f", FUCCA, user, StringToFloat(aa[1]));
			else CPrintToChat(client, "%s{white}%N님의 몸 크기 {green}%1.f", FUCCA, client, StringToFloat(aa[1]));
		}
	}
	return Plugin_Handled;
}

public Action:Command_ResetSize(client, args)
{
	decl String:arg[65];
	GetCmdArgString(arg, sizeof(arg));

	if(StrEqual(arg, ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_resetsize <player>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;
		
		SetSize(user, 1.0);
		TF2Attrib_RemoveByDefIndex(user, 620);
		TF2Attrib_RemoveByDefIndex(user, 444);
		TF2Attrib_RemoveByDefIndex(user, 2048);
		TF2Attrib_RemoveByDefIndex(user, 699);
	}
	return Plugin_Handled;
}
/*
public Action:Command_RandomPlayer(client, args)
{
	if(args != 2)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_randomp <alive 1 / 0 > <blue = 3, red = 2, spec = 1, all = 0");
		return Plugin_Handled;
	}
	
	decl String:arg[12], String:arg2[12];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	new bool:alive;
	
	if(StringToInt(arg) == 1) alive = true;
	else alive = false
	
	new user = GetRandomClient(true, alive, false, StringToInt(arg2));
	
	if(user == 0)
	{
		ReplyToTargetError(client, 0);
		return Plugin_Handled;
	}
	CPrintToChatAll("{white}%N님이 랜덤으로 뽑혔습니다.", user);
	return Plugin_Handled;
}*/

public Action:Command_ThreeSec(client, args)
{
	switch(GetRandomInt(0,2))
	{
		case 0: sec = 0;
		case 1: sec = 1;
		case 2: sec = 2;
	}
	
	if(sec == 0) EmitSoundToAll("vo/announcer_begins_3sec.mp3");
	if(sec == 1) EmitSoundToAll("vo/announcer_ends_3sec.mp3");
	if(sec == 2) EmitSoundToAll("vo/halloween_merasmus/sf14_merasmus_begins_03sec.mp3");
	CreateTimer(1.0, two);
	return Plugin_Handled;
}

public Action:two(Handle:timer)
{
	if(sec == 0) EmitSoundToAll("vo/announcer_begins_2sec.mp3");
	if(sec == 1) EmitSoundToAll("vo/announcer_ends_2sec.mp3");
	if(sec == 2) EmitSoundToAll("vo/halloween_merasmus/sf14_merasmus_begins_02sec.mp3");
	CreateTimer(1.0, one);
}
public Action:one(Handle:timer)
{
	if(sec == 0) EmitSoundToAll("vo/announcer_begins_1sec.mp3");
	if(sec == 1) EmitSoundToAll("vo/announcer_ends_1sec.mp3");
	if(sec == 2) EmitSoundToAll("vo/halloween_merasmus/sf14_merasmus_begins_01sec.mp3");
}

public Action:Command_NoAttack(client, args)
{
	new String:arg[256], String:aa[2][256];
	GetCmdArgString(arg, sizeof(arg));
	ExplodeString(arg, " ", aa, 2, 256);
	
	if(StrEqual(aa[0], "") || StrEqual(aa[1], ""))
	{
		Fucca_ReplyToCommand(client, "Usage: sm_noattack <player> <on / off>");
		return Plugin_Handled;
	}

	decl  String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
	if ((target_count = ProcessTargetString(aa[0], client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
		
	for (new i = 0; i < target_count; i++)
	{
		new user = target_list[i];
		if (!IsClientInGame(user)) return Plugin_Handled;

		if(StrEqual(aa[1], "off"))
		{
			TF2Attrib_RemoveByDefIndex(user, 821);	
			if(user != client) CPrintToChat(user, "%s{white}%N님은 이제 공격 가능", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님은 이제 공격 가능", FUCCA, client);
		}
		else
		{
			TF2Attrib_SetByDefIndex(user, 821, 1.0);
			if(user != client) CPrintToChat(user, "%s{white}%N님은 이제 공격 불가능", FUCCA, user);
			else CPrintToChat(client, "%s{white}%N님은 이제 공격 불가능", FUCCA, client);
		}
	}
	return Plugin_Handled;
}

public Action:Command_Whisper(client, args)
{
	if(args != 2)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_wr <player> <say>");
		return Plugin_Handled;
	}
	
	decl String:arg[64], String:arg2[256];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new target = FindTarget(client, arg, true, true);
	
	if(!IsValidClient(target)) return Plugin_Handled;

	CPrintToChat(target, "%s\x07ADFF2F[귓속말] \x03%N: {white}%s", FUCCA, client, arg);
	CPrintToChat(client, "%s\x03%N {white}님에게 '{Green}%s{white}' 라고 전달되었습니다.", FUCCA, target, arg);
	return Plugin_Handled;
}

public Action:Command_SetOrigin(client, args)
{
	GetClientAbsOrigin(client, sPos[client][0]);
	GetClientAbsAngles(client, sPos[client][1]);
	
	CPrintToChat(client, "%s{white} 저장되었습니다.", FUCCA);
	return Plugin_Handled;
}

public Action:Command_Teleport(client, args)
{
	if(sPos[client][0][0] == 0.0)
	{
		CPrintToChat(client, "%s{white} 저장된 위치가 없습니다.", FUCCA);
		return Plugin_Handled;
	}
	TeleportEntity(client, sPos[client][0], sPos[client][1], NULL_VECTOR);
	CPrintToChat(client, "%s{white} 텔포!", FUCCA);
	return Plugin_Handled;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if(IsValidEntity(weapon) && IsValidClient(client))
	{
		if(jump[client] || bjump[client])
		{
			if(TF2_GetPlayerClass(client) == TFClassType:TFClass_Soldier || TF2_GetPlayerClass(client) == TFClassType:TFClass_DemoMan)
			{
				if(index != 730) SetEntProp(weapon, Prop_Send, "m_iClip1", 5);
				
				new type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
				if (type != -1) SetEntProp(client, Prop_Send, "m_iAmmo", 200, _, type);
			}
			else if(TF2_GetPlayerClass(client) == TFClassType:TFClass_Engineer) SetEntProp(client, Prop_Data, "m_iAmmo", 999, 4, 3);
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon == INVALID_ENT_REFERENCE) return Plugin_Continue;
		
		if(rof[client] != 0.0) ModRateOfFire(weapon, rof[client]);	
		
		if(see[client])
		{
			if(iButtons & IN_RELOAD && !seeb[client])
			{
				SetVariantInt(3);
				AcceptEntityInput(client, "SetForcedTauntCam");
				SetClientViewEntity(client, see[client]);
				seeb[client] = true;
			}
			else if (!(iButtons & IN_RELOAD) && seeb[client])
			{
				SetClientViewEntity(client, client);
				seeb[client] = false;
			}
		}
	}
	return Plugin_Continue;
}

stock Fucca_ReplyToCommand(client, String:say[]) ReplyToCommand(client, "%s\x07FFFFFF%s", FUCCA, say);

stock ChangeClientTeamAlive(client, team){
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

stock SetSize(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", value);
	SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * value)
}

stock SetGod(client, bool:num = true)
{
	if(num) SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
	else SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

stock SetHealth(client, Gethp, sethp)
{
	SetEntityHealth(client, sethp);
	if(Gethp < sethp) CPrintToChat(client, "%s{green}체력 %i {white}증가", FUCCA, sethp);
	else CPrintToChat(client, "%s{green}체력 %i {white}감소", FUCCA, sethp);
}

stock ModRateOfFire(iWeapon, Float:Amount)
{
	new Float:m_flNextPrimaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
	new Float:m_flNextSecondaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack");
	
	if (Amount > 12) SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 12.0);
	else SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", Amount);

	new Float:fGameTime = GetGameTime();
	new Float:fPrimaryTime = (m_flNextPrimaryAttack - fGameTime) - ((Amount - 1.0) / 50);
	new Float:fSecondaryTime = (m_flNextSecondaryAttack - fGameTime) - ((Amount - 1.0) / 50);

	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fPrimaryTime + fGameTime);
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", fSecondaryTime + fGameTime);
}

public motd(client, String:url[])
{
	new Handle:Kv = CreateKeyValues("motd");
	KvSetString(Kv, "title", "Profile");
	KvSetNum(Kv, "type", MOTDPANEL_TYPE_URL);
	KvSetString(Kv, "msg", url);
	KvSetNum(Kv, "customsvr", 1);

	ShowVGUIPanel(client, "info", Kv);
	CloseHandle(Kv);
}

stock Annotate(Float:pos[3], client, String:message[], offset = 0, Float:lifetime = 8.0, follow = -1)
{
	new Handle:event = CreateEvent("show_annotation");
	if (event == INVALID_HANDLE) return;
	
	SetEventFloat(event, "worldPosX", pos[0]);
	SetEventFloat(event, "worldPosY", pos[1]);
	SetEventFloat(event, "worldPosZ", pos[2]);
	SetEventFloat(event, "lifetime", lifetime);
	SetEventInt(event, "id", client + 8720 + offset); 
	if (follow != -1) SetEventInt(event, "follow_entindex", follow);
	SetEventString(event, "text", message);
	SetEventString(event, "play_sound", "vo/null.wav");
	SetEventString(event, "show_effect", "1");
	SetEventString(event, "show_distance", "1");
	SetEventInt(event, "visibilityBitfield", 1 << client);
	FireEvent(event);
}

public bool:admin(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && IsClientAdmin(i)) PushArrayCell(clients, i);
	return true;
}

public bool:member(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && party[i] == true) PushArrayCell(clients, i);
	return true;
}

public bool:redbots(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && IsFakeClient(i) && GetClientTeam(i) == 2) PushArrayCell(clients, i);
	return true;
}

public bool:blubots(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++) if(IsValidClient(i) && IsFakeClient(i) && GetClientTeam(i) == 3) PushArrayCell(clients, i);
	return true;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock bool:IsClientAdmin(client)
{
	new AdminId:Cl_ID;
	Cl_ID = GetUserAdmin(client);
	if(Cl_ID != INVALID_ADMIN_ID)
		return true;
	return false;
}