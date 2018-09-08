#include <tf2_stocks>
// #include <tf2attributes>

#define FUCCA "\x07FF1493[뿌까] \x07FFFFFF"

new TFClassType:red;
new TFClassType:blu;

new bool:g_bWaitingForPlayers;
new bool:melee;

new Float:VoteCoolTime;

public OnPluginStart()
{
	LoadTranslations("basevotes.phrases");
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("post_inventory_application", inven);
	RegAdminCmd("sm_vc", voteclass, 0);
	
	AddCommandListener(hook_JoinClass, "joinclass");
}

public OnMapStart()
{
	red = TFClass_Unknown;
	blu = TFClass_Unknown;
}

public TF2_OnWaitingForPlayersStart()
{
	g_bWaitingForPlayers = true;
	red = TFClass_Unknown;
	blu = TFClass_Unknown;
}

public TF2_OnWaitingForPlayersEnd() g_bWaitingForPlayers = false;

public Action:hook_JoinClass(client, const String:command[], argc)
{
	if(g_bWaitingForPlayers) return Plugin_Continue;
	if(red == TFClass_Unknown || blu == TFClass_Unknown) return Plugin_Continue;
	
	decl String:cmd1[32];
	
	if(argc < 1) return Plugin_Handled;
	
	GetCmdArg(1, cmd1, sizeof(cmd1));
	
	if(GetClientTeam(client) == 2) if(!StrEqual(cmd1, ClassName(red), false)) return Plugin_Handled;
	if(GetClientTeam(client) == 3) if(!StrEqual(cmd1, ClassName(blu), false)) return Plugin_Handled;

	return Plugin_Continue;
}

stock SetClass)
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == 2) TF2_SetPlayerClass(i, red);
			else if(GetClientTeam(i) == 3) TF2_SetPlayerClass(i, blu);
				
			if(red == blu) melee = true;
			else melee = false;
				
			TF2_RespawnPlayer(i);
		}
	}
}

public Action:voteclass(client, args)
{
	if(!CheckCoolTime(client, 45.0))
	{
		PrintToChat(client, "%s45초 후에 다시 사용하세요. (45초 / %1.f초)", FUCCA, GetEngineTime() - VoteCoolTime);
		return Plugin_Handled;
	}
	VoteCoolTime = GetEngineTime();
	
	new Handle:voteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_DEFAULT);
	SetMenuTitle(voteMenu, "클래스 변경");
	AddMenuItem(voteMenu, "ㅌ,", "방지", ITEMDRAW_DISABLED);
	
	if(GetClientTeam(client) == 2)
	{
		AddMenuItem(voteMenu, "2_1", "스카웃");
		AddMenuItem(voteMenu, "2_3", "솔저");
		AddMenuItem(voteMenu, "2_7", "파이로");
		AddMenuItem(voteMenu, "2_4", "데모맨");
		AddMenuItem(voteMenu, "2_6", "헤비");
		AddMenuItem(voteMenu, "2_9", "엔지니어");
		AddMenuItem(voteMenu, "2_5", "메딕");
		AddMenuItem(voteMenu, "2_2", "스나이퍼");
		AddMenuItem(voteMenu, "2_8", "스파이");
	}
	
	else
	{
		AddMenuItem(voteMenu, "3_1", "스카웃");
		AddMenuItem(voteMenu, "3_3", "솔저");
		AddMenuItem(voteMenu, "3_7", "파이로");
		AddMenuItem(voteMenu, "3_4", "데모맨");
		AddMenuItem(voteMenu, "3_6", "헤비");
		AddMenuItem(voteMenu, "3_9", "엔지니어");
		AddMenuItem(voteMenu, "3_5", "메딕");
		AddMenuItem(voteMenu, "3_2", "스나이퍼");
		AddMenuItem(voteMenu, "3_8", "스파이");
	}
	
	SetMenuExitButton(voteMenu, false);
	
	for (new i = 1; i <= MaxClients; i++) 
		if(IsValidClient(i)) if(GetClientTeam(client) == GetClientTeam(i)) VoteMenuToAll(voteMenu, 30);
	return Plugin_Handled;
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		
		case MenuAction_VoteCancel:
			if(param1 == VoteCancel_NoVotes) PrintToChatAll("[SM] %t", "No Votes Cast");
			
		case MenuAction_VoteEnd:
		{
			decl String:mm[128], String:ClassIndex[64], String:aa[2][3];
			new Float:percent, votes, totalVotes;
			
			GetMenuVoteInfo(param2, votes, totalVotes);
			GetMenuItem(menu, param1, mm, sizeof(mm), _, ClassIndex, sizeof(ClassIndex));
			ExplodeString(mm, "_", aa,2,3);
			
			percent = GetVotePercent(votes, totalVotes);
			
			PrintToChatAll("%t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
			
			if(StringToInt(aa[0]) == 2) PrintToChatAll("%s[SM] 레드팀 클래스는 %s 입니다. (곧 클래스가 변경됩니다.)", FUCCA, ClassIndex);
			else PrintToChatAll("%s블루팀 클래스는 %s 입니다. (곧 클래스가 변경됩니다.)", FUCCA, ClassIndex);
			
			new Handle:hTemp;
			CreateDataTimer(3.0, Timer_Load, hTemp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
			WritePackCell(hTemp, StringToInt(aa[0]));
			WritePackCell(hTemp, TFClassType:StringToInt(aa[1]));
		}
	}
}

public Action:Timer_Load(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new team = ReadPackCell(hPack);
	new TFClassType:index = ReadPackCell(hPack);
	
	
	if(team == 2) red = TFClassType:index;
	else blu = TFClassType:index;
	
	SetClass();
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bWaitingForPlayers) return Plugin_Continue;
	
	VoteCoolTime = GetEngineTime();
	
	red = TFClassType:mt_rand(1, 9);
	blu = TFClassType:mt_rand(1, 9); 
	
	PrintCenterTextAll("%s vs %s", ClassName(red), ClassName(blu));
	
	CreateTimer(2.0, Timer_Delay, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_Delay(Handle:timer) SetClass();

public Action:inven(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bWaitingForPlayers) return Plugin_Continue;
	if(!melee) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	for (new slot = 0; slot < 5; slot++)
	{
		if(TF2_GetPlayerClass(client) == TFClassType:TFClass_Spy)
		{
			if(slot != 2 && slot != 3 && slot != 4)
			{
				new ent = GetPlayerWeaponSlot(client, slot);
				if (ent != -1) RemoveEdict(ent);
			}
		}
		else
		{
			if(slot != 2)
			{
				new ent = GetPlayerWeaponSlot(client, slot);
				if (ent != -1) RemoveEdict(ent);
			}
		}
	}
	
	ChangePlayerWeaponSlot(client, 2);
	return Plugin_Continue;
}

stock String:ClassName(TFClassType:team)
{
	new String:class[32];
	if(team == TFClass_Scout) class = "scout";
	if(team == TFClass_Soldier) class = "soldier";
	if(team == TFClass_Pyro) class = "pyro";
	if(team == TFClass_DemoMan) class = "demoman";
	if(team == TFClass_Heavy) class = "heavyweapons";
	if(team == TFClass_Engineer) class = "engineer";
	if(team == TFClass_Medic) class = "medic";
	if(team == TFClass_Sniper) class = "sniper";
	if(team == TFClass_Spy) class = "spy";
	return class;
}

stock bool:ChangePlayerWeaponSlot(iClient, iSlot) {
	new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > MaxClients) {
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
		return true;
	}
	return false;
}

stock Float:GetVotePercent(votes, totalVotes) return FloatDiv(float(votes),float(totalVotes));
stock mt_rand(min, max) return RoundToNearest(GetURandomFloat() * (max - min) + min);

stock bool:CheckCoolTime(any:iClient, Float:fTime)
{
	if(GetEngineTime() - VoteCoolTime >= fTime) return true;
	else return false;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
