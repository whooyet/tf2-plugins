#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#define SPECMODE_NONE        0
#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_3RDPERSON   5
#define SPECMODE_FREELOOK    6

#define SKEYS_BUFFER_LEN 64
#define SKEYS_BUTTONS_FILTER (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP | IN_DUCK | IN_SCORE)

new g_iButtons[MAXPLAYERS + 1];
new g_iShownButtons[MAXPLAYERS + 1];
new Handle:g_hSkeysHudSynchronizer = INVALID_HANDLE;

public OnPluginStart() g_hSkeysHudSynchronizer = CreateHudSynchronizer();
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) g_iButtons[client] = buttons & SKEYS_BUTTONS_FILTER;

public OnGameFrame()
{
	new iPos;
	new buttons;
	new iObserverMode;
	new iObserverTarget;
	decl String:sOutput[SKEYS_BUFFER_LEN];
	
	SetHudTextParams(0.53, 0.4, 60.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	
	for (new client = 1; client < MaxClients; client++) 
	{
		if(IsValidClient(client) && IsClientObserver(client))
		{
			buttons = 0;
			
			if (g_iButtons[client] & IN_SCORE) {
				continue; // do not update while client hide, in score
			}
			
			iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			if (iObserverMode == SPECMODE_NONE || iObserverMode == SPECMODE_FREELOOK || iObserverMode == 7) {
				buttons = -1;  // hide, in free look and 3rd person
			}
			
			if (buttons != -1) {
				iObserverTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (IsValidClient(iObserverTarget)) {
					buttons = g_iButtons[iObserverTarget];
				} else {
					buttons = -1;
				}
			}
			
			if (buttons == g_iShownButtons[client]) {
				continue;  // for network optimization
			}
			
			g_iShownButtons[client] = buttons;
			
			if (buttons == -1) {
				ClearSyncHud(client, g_hSkeysHudSynchronizer);
				continue;
			}

			// Is he pressing "w"?
			iPos = 0;
			if (buttons & IN_FORWARD) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "      W     ");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "      _      ");
			}

			// Is he pressing "space"?
			if (buttons & IN_JUMP) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "     JUMP\n");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "\n");
			}

			// Is he pressing "a"?
			if (buttons & IN_MOVELEFT) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  A");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  _");
			}

			// Is he pressing "s"?
			if (buttons & IN_BACK) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  S");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  _");
			}

			// Is he pressing "d"?
			if (buttons & IN_MOVERIGHT) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  D");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  _");
			}

			// Is he pressing "ctrl"?
			if (buttons & IN_DUCK) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "       DUCK\n");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "\n");
			}
			ShowSyncHudText(client, g_hSkeysHudSynchronizer, sOutput);
		}
	}
} /* OnGameFrame */

stock bool:IsValidClient(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}
