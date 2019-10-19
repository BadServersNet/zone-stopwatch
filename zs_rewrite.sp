
#define PLUGIN_NAME				"Zone Stopwatch"
#define PLUGIN_AUTHOR			"GameChaos"
#define PLUGIN_DESCRIPTION		"A stopwatch that uses zones."
#define PLUGIN_VERSION			"0.00"
#define PLUGIN_URL				"https://bitbucket.org/GameChaos/zone-stopwatch"

#define PREFIX					"[GC]"

#include <sourcemod>
#include <sdktools>
#include <gamechaos>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

enum struct Zone
{
	float startcorner[3];
	float endcorner[3];
};

bool g_bLateLoad;

bool g_bStartOnJump[MAXPLAYERS + 1];
bool g_bStopOnLand[MAXPLAYERS + 1];
bool g_bEditStartZone[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_ztopwatch", Command_SmZtopwatch);
}

public Action Command_SmZtopwatch(int client, int args)
{
	if (!IsValidClientExt(client, true))
	{
		PrintToChat(client, "%s You have to be alive to use this!", PREFIX);
		return Plugin_Handled;
	}
	Showmenu_Ztopwatch(client);
	return Plugin_Handled;
}

public Showmenu_Ztopwatch(int client)
{
	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	menu.Pagination = MENU_NO_PAGINATION;
	menu.SetTitle("Ztopwatch");
	
	char szEditStartZone[64];
	FormatEx(szEditStartZone, sizeof(szEditStartZone), "Current zone - %s", g_bEditStartZone[client] ? "Start" : "End");
	menu.AddItem("0", szEditStartZone);
	
	menu.AddItem("1", "Reset zones");
	
	char szStartOnJump[64];
	FormatEx(szStartOnJump, sizeof(szStartOnJump), "Start timer on jump - %s", g_bStartOnJump[client] ? "ON" : "OFF");
	menu.AddItem("2", szStartOnJump);
	
	char szStopOnLand[64];
	FormatEx(szStopOnLand, sizeof(szStopOnLand), "Stop timer on land - %s", g_bStopOnLand[client] ? "ON" : "OFF");
	menu.AddItem("3", szStopOnLand);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Ztopwatch(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char szInfo[16];
			menu.GetItem(param2, szInfo, sizeof(szInfo));
			int iInfo = StringToInt(szInfo);
			switch (iInfo)
			{
				// current zone
				case 0:
				{
					g_bEditStartZone[param1] = !g_bEditStartZone[param1];
					ShowMenu(param1);
				}
				// reset zones
				case 1:
				{
					//resetVars(param1);
					ShowMenu(param1);
				}
				case 2:
				{
					g_bStartOnJump[param1] = !g_bStartOnJump[param1];
					ShowMenu(param1);
				}
				case 3:
				{
					g_bStopOnLand[param1] = !g_bStopOnLand[param1];
					ShowMenu(param1);
				}
				default:
				{
					ShowMenu(param1);
				}
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}