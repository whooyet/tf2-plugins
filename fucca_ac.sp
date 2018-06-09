#include <sourcemod>
#include <sdktools>

#define FUCCA "\x07FF1493[뿌까] "

public Plugin myinfo = 
{
	name = "출첵 플러그인",
	author = "뿌까",
	description = "심심",
	version = "1.0",
	url = "알아서 찾아와!"
};

new bool:check[33]
new String:connect[33][64];

public OnPluginStart() RegAdminCmd("sm_ac", aaa, ADMFLAG_RESERVATION);

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	Format(connect[client], 64, daydayday());
	CreateTimer(2400.0, Timer, client);
	return true;
}

public OnClientDisconnect(client)
{
	connect[client] = "";
	check[client] = false;
}

public OnMapStart() PrecacheSound("replay/cameracontrolerror.wav");

public Action:aaa(client, args)
{
	if(overlap(client))
	{
		PrintToChat(client, "%s \x07FFFFFF이미 출석체크하였습니다.", FUCCA);
		return Plugin_Handled;
	}
		
	if(check[client])
	{
		decl String:FileName[PLATFORM_MAX_PATH], String:SteamID[64], String:Steam64[32];
		
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		GetClientAuthId(client, AuthId_SteamID64, Steam64, sizeof(Steam64));
		
		new String:temp[2][128], String:buffer[256];
		ExplodeString(daydayday(), " ", temp,2, 128);
		
		BuildPath(Path_SM, FileName, sizeof(FileName), "data/ac/%s.txt", temp[0]);
		
		Format(buffer, sizeof(buffer), "%s %s http://steamcommunity.com/profiles/%s %N", daydayday(), SteamID, Steam64, client);
		
		new Handle:log = OpenFile(FileName, "a+");
		if(log != INVALID_HANDLE)
		{
			WriteFileLine(log, "%s", buffer);
			PrintToChat(client, "%s \x07FFFFFF출석체크되었습니다.", FUCCA);
			FlushFile(log);
			CloseHandle(log);
		}
		else
		{
			EmitSoundToClient(client, "replay/cameracontrolerror.wav");
			PrintToChat(client, "%s \x04알수없는 에러가 발생했습니다.", FUCCA);
		}
	}
	else
	{
		PrintToChat(client, "%s \x07FFFFFF아직 40분이 지나지 않았습니다. \x04(%s)", FUCCA, connect[client]);
	}
	return Plugin_Handled;
}

public Action:Timer(Handle:Timer, any:client)
{
	if(!PlayerCheck(client)) return Plugin_Stop;
	if(IsClientAdmin(client)) check[client] = true;
	return Plugin_Continue;
}

stock bool:overlap(client)
{
	decl String:FileName[PLATFORM_MAX_PATH], String:buffer[256], String:SteamID[64];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	new String:temp[2][128], String:temp2[4][256];
	ExplodeString(daydayday(), " ", temp,2, 128);
		
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/ac/%s.txt", temp[0]);
	
	if (FileExists(FileName, true))
	{
		new Handle:log = OpenFile(FileName, "r");
		
		while (ReadFileLine(log, buffer, sizeof(buffer)))
		{
			ExplodeString(buffer, " ", temp2, 4, 256);
			if(StrEqual(temp2[3], SteamID)) return true;
		}
		FlushFile(log);
		CloseHandle(log);
	} 
	return false;
}

stock String:daydayday()
{
	decl String:year[21], String:mon[21], String:day[21];
		
	FormatTime(year, sizeof(year), "%Y", -1);
	FormatTime(mon, sizeof(mon), "%m", -1);
	FormatTime(day, sizeof(day), "%d", -1);
		
	decl String:AM_PM[21], String:Hour[21], String:minute[21], String:second[21];
		
	FormatTime(AM_PM, sizeof(AM_PM), "%p", -1);
	FormatTime(Hour, sizeof(Hour), "%I", -1);
	FormatTime(minute, sizeof(minute), "%M", -1);
	FormatTime(second, sizeof(second), "%S", -1);
	
	new String:temp[128];
	Format(temp, sizeof(temp), "%s-%s-%s %s %s:%s:%s", year, mon, day, AM_PM, Hour, minute, second);
	return temp;
}
	
stock bool:IsClientAdmin(client)
{
	new AdminId:Cl_ID;
	Cl_ID = GetUserAdmin(client);
	if(Cl_ID != INVALID_ADMIN_ID)
		return true;
	return false;
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