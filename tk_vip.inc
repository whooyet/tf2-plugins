#if defined _vip_included
  #endinput
#endif
#define _vipmanager_included

public SharedPlugin __pl_vip = {
  name = "tk_vip",
  file = "tk_vip.smx",
#if defined REQUIRE_PLUGIN
  required = 1
#else
  required = 0
#endif
};


native bool:IsClientVip(client);
native VipMenu(client);


#if !defined REQUIRE_PLUGIN
public __pl_vipmanager_SetNTVOptional() {
  MarkNativeAsOptional("IsClientVip");
  MarkNativeAsOptional("VipMenu");
}
#endif
