#include <tf2_stocks>
#include <tf2attributes>
#include <tf2idb>

new Handle:g_hWeaponEquip, Handle:g_hGameConfig;

public OnPluginStart()
{
	g_hGameConfig = LoadGameConfigFile("give.bots.weapons");
	if (!g_hGameConfig) SetFailState("Failed to find give.bots.weapons.txt gamedata! Can't continue.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();
	
	if (!g_hWeaponEquip) SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	
	RegAdminCmd("sm_a", MapList, 0);
}

public Action:MapList(client, args)
{
	new p = SpawnWeapon(client, 0);
	new s = SpawnWeapon(client, 1);
	new m = SpawnWeapon(client, 2);
	
	if(p == -1)
	{
		PrintToChat(client, "플러그인 오류가 발생했습니다. (CODE A)");
		return Plugin_Handled;
	}
	if(s == -1)
	{
		PrintToChat(client, "플러그인 오류가 발생했습니다. (CODE B)");
		return Plugin_Handled;
	}
	if(m == -1)
	{
		PrintToChat(client, "플러그인 오류가 발생했습니다. (CODE C)");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

stock SpawnWeapon(client, slot)
{
	new index;
	
	index = RandomWeapon(slot);
	
	if(index == -1)
	{
		PrintToChat(client, "플러그인 오류가 발생했습니다. (CODE D)");
		return -1;
	}
	
	return CreateWeapon(client, slot, GetItemClassname(index), index, "", 0); 
}

stock RandomWeapon(slot)
{
	new Handle:test, index = -1, index_fastive, index_bot;
	
	// if(test == INVALID_HANDLE) return -1;
	
	switch(slot)
	{
		case 0: test = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item WHERE slot='primary' AND propername=1")
		case 1: test = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item WHERE slot='secondary' AND propername=1")
		case 2: test = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item WHERE slot='melee' AND propername=1")
	}
	
	index = GetArrayCell(test, mt_rand(0, GetArraySize(test) - 1));
	
	new Handle:fastive = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item_attributes WHERE attribute=834");
	
	// if(fastive == INVALID_HANDLE) return -1;
	 
	for(new i = 0; i < GetArraySize(fastive); i++)
	{
		index_fastive = GetArrayCell(fastive, i);
		if(index_fastive == index) index = GetArrayCell(test,  mt_rand(0, GetArraySize(test) - 1));
	}
	
	// new Handle:BotWeapon = TF2IDB_FindItemCustom("SELECT id FROM tf2idb_item_attributes WHERE attribute=328");
	 
	// for(new i = 0; i < GetArraySize(BotWeapon); i++)
	// {
		// index_bot = GetArrayCell(BotWeapon, i);
		// if(index_bot == index) index = GetArrayCell(test, GetRandomInt(0, GetArraySize(test) - 1));
	// }
	
	// CloseHandle(BotWeapon);
	CloseHandle(fastive);
	CloseHandle(test);
	return index;
}

stock String:GetItemClassname(index)
{
	new String:classname[128];
	TF2IDB_GetItemClass(index, classname, sizeof(classname));
	return classname;
}

stock CreateWeapon(client, slot, String:classname[], itemindex, String:att[], ammo)
{
	new weapon = CreateEntityByName(classname);
	if (!IsValidEntity(weapon)) return -1;
	
	TF2_RemoveWeaponSlot(client, slot);
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), 69);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);	

	switch (itemindex)
	{
		case 810: SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3 );
		case 998: SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomUInt(0,2));
	}
	
	DispatchSpawn(weapon);
	AttAtt(weapon, att);
	if(ammo != 0) SetSpeshulAmmo(client, weapon, ammo);
	
	// new TFClassType:class = FixReload(client, itemindex, classname);
	
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	SDKCall(g_hWeaponEquip, client, weapon);
	
	// if (class != TFClass_Unknown)
	// {
		// if(GetConVarInt(cv_debug) == 0) TF2_SetPlayerClass(client, ClientClass[client]);
		// else TF2_SetPlayerClass(client, class);
	// }
	
	return weapon;
} 

stock AttAtt(entity, String:att[])
{
	new String:atts[32][32]; 
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 1) for (new i = 0; i < count; i+= 2) TF2Attrib_SetByDefIndex(entity, StringToInt(atts[i]), StringToFloat(atts[i+1]));
}

stock SetSpeshulAmmo(client, weapon, newAmmo)
{
	if (!IsValidEntity(weapon)) return;
	new type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (type < 0 || type > 31) return;
	SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);
}

stock GetRandomUInt(min, max) return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
stock mt_rand(min, max) return RoundToNearest(GetURandomFloat() * (max - min) + min);

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
