#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Zone Stopwatch", 
	author = "GameChaos", 
	description = "A stopwatch with zones.", 
	version = "0.2"
}

#define CHOICE0 "#choice0"
#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"
#define CHOICE3 "#choice3"
#define CHOICE4 "#choice4"
#define CHOICE5 "#choice5"
#define CHOICE6 "#choice6"

float g_fStartCorner1[MAXPLAYERS + 1][3];
float g_fStartCorner2[MAXPLAYERS + 1][3];
float g_fEndCorner1[MAXPLAYERS + 1][3];
float g_fEndCorner2[MAXPLAYERS + 1][3];
float g_fTimerStart[MAXPLAYERS + 1];
float g_fPlayerPos[MAXPLAYERS + 1][3];
float corners[8][3];
float corner[2][3];
int colour[4];
int pairs[8][3] =  {  { 0, 0, 0 }, { 1, 0, 0 }, { 1, 1, 0 }, { 0, 1, 0 }, { 0, 0, 1 }, { 1, 0, 1 }, { 1, 1, 1 }, { 0, 1, 1 } };
int edges[12][2] =  {  { 0, 1 }, { 0, 3 }, { 0, 4 }, { 2, 1 }, { 2, 3 }, { 2, 6 }, { 5, 4 }, { 5, 6 }, { 5, 1 }, { 7, 4 }, { 7, 6 }, { 7, 3 } };
bool g_bStartCorner1[MAXPLAYERS + 1] = false;
bool g_bStartCorner2[MAXPLAYERS + 1] = false;
bool g_bEndCorner1[MAXPLAYERS + 1] = false;
bool g_bEndCorner2[MAXPLAYERS + 1] = false;
bool g_bJumped[MAXPLAYERS + 1] = false;
bool g_bLastJump[MAXPLAYERS + 1] = false;
bool g_bStartOnJump[MAXPLAYERS + 1] = true;
bool g_bStopOnLand[MAXPLAYERS + 1] = true;
static int g_Beam;

public void OnPluginStart()
{
	RegConsoleCmd("sm_ztopwatch", Command_Ztopwatch);
}

public void OnConfigsExecuted()
{
	g_Beam = PrecacheModel("materials/sprites/laser.vmt", true);
}

public void OnClientPutInServer(int client)
{
	CreateTimer(1.0, Timer_ZoneTimer, GetClientSerial(client), TIMER_REPEAT);
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu");
		}
		
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, CHOICE0))
			{
				float pos[3];
				GetClientAbsOrigin(param1, pos);
				for (int i = 0; i < 3; i++)
				{
					g_fStartCorner1[param1][i] = RoundToNearest(pos[i]) + 0.0
				}
				g_bStartCorner1[param1] = true;
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE1))
			{
				float pos[3];
				GetClientAbsOrigin(param1, pos);
				for (int i = 0; i < 3; i++)
				{
					g_fStartCorner2[param1][i] = RoundToNearest(pos[i]) + 0.0
				}
				g_bStartCorner2[param1] = true;
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE2))
			{
				float pos[3];
				GetClientAbsOrigin(param1, pos);
				for (int i = 0; i < 3; i++)
				{
					g_fEndCorner1[param1][i] = RoundToNearest(pos[i]) + 0.0
				}
				g_bEndCorner1[param1] = true;
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE3))
			{
				float pos[3];
				GetClientAbsOrigin(param1, pos);
				for (int i = 0; i < 3; i++)
				{
					g_fEndCorner2[param1][i] = RoundToNearest(pos[i]) + 0.0
				}
				g_bEndCorner2[param1] = true;
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE4))
			{
				g_bStartCorner1[param1] = false;
				g_bStartCorner2[param1] = false;
				g_bEndCorner1[param1] = false;
				g_bEndCorner2[param1] = false;
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE5))
			{
				g_bStartOnJump[param1] = !g_bStartOnJump[param1];
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE6))
			{
				g_bStopOnLand[param1] = !g_bStopOnLand[param1];
				ShowMenu(param1);
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action Timer_ZoneTimer(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial)
	
	if (g_bStartCorner1[client] && g_bStartCorner2[client] || g_bEndCorner1[client] && g_bEndCorner2[client])
	{
		for (new player = 1; player <= MaxClients; player++)
		{
			for (int i = 0; i < 2; i++)
			{
				if (i == 0)
				{
					corner[0] = g_fStartCorner1[player]
					corner[1] = g_fStartCorner2[player]
					colour[0] = 0;
					colour[1] = 255;
					colour[2] = 0;
					colour[3] = 255;
				}
				else if (i == 1)
				{
					corner[0] = g_fEndCorner1[player]
					corner[1] = g_fEndCorner2[player]
					colour[0] = 255;
					colour[1] = 0;
					colour[2] = 0;
					colour[3] = 255;
				}
				for (int l = 0; l < 8; l++)
				{
					corners[l][0] = corner[pairs[l][0]][0];
					corners[l][1] = corner[pairs[l][1]][1];
					corners[l][2] = corner[pairs[l][2]][2];
				}
				for (int l = 0; l < 12; l++)
				{
					TE_SetupBeamPoints(corners[edges[l][0]], corners[edges[l][1]], g_Beam, 0, 0, 0, 1.0, 3.0, 3.0, 10, 0.0, colour, 0);
					TE_SendToClient(player, 0.0);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (g_fStartCorner1[client][2] == g_fStartCorner2[client][2] && g_fStartCorner1[client][2] != 0.0)
	{
		g_fStartCorner2[client][2] += 96.0;
	}
	if (g_fEndCorner1[client][2] == g_fEndCorner2[client][2] && g_fEndCorner1[client][2] != 0.0)
	{
		g_fEndCorner2[client][2] += 96.0;
	}
	
	g_bJumped[client] = g_bLastJump[client] && GetEntityFlags(client) & FL_ONGROUND;
	
	if (g_bStartCorner1[client] && g_bStartCorner2[client] && g_bEndCorner1[client] && g_bEndCorner2[client] && IsValidClient(client))
	{
		GetClientAbsOrigin(client, g_fPlayerPos[client]);
		if (PointIsInCuboid(g_fPlayerPos[client], g_fStartCorner1[client], g_fStartCorner2[client]))
		{
			if (g_bStartOnJump[client])
			{
				if (g_bJumped[client])
				{
					g_fTimerStart[client] = GetEngineTime();
				}
			}
			else
			{
				g_fTimerStart[client] = GetEngineTime();
			}
		}
		else
			if (PointIsInCuboid(g_fPlayerPos[client], g_fEndCorner1[client], g_fEndCorner2[client]) && g_fTimerStart[client] != 0.0 && GetEngineTime() != g_fTimerStart[client])
		{
			if (g_bStopOnLand[client])
			{
				if (GetEntityFlags(client) & FL_ONGROUND)
				{
					float time;
					time = GetEngineTime() - g_fTimerStart[client];
					PrintToChat(client, "[KZ] Elapsed time is %f.", time);
					g_fTimerStart[client] = 0.0;
				}
			}
			else
			{
				float time;
				time = GetEngineTime() - g_fTimerStart[client];
				PrintToChat(client, "[KZ] Elapsed time is %f.", time);
				g_fTimerStart[client] = 0.0;
			}
		}
	}
	g_bLastJump[client] = !(buttons & IN_JUMP);
	return Plugin_Changed;
}

public Action Command_Ztopwatch(int client, int args)
{
	ShowMenu(client);
	return Plugin_Handled;
}

public ShowMenu(int client)
{
	Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
	menu.Pagination = MENU_NO_PAGINATION;
	menu.SetTitle("Ztopwatch");
	menu.AddItem(CHOICE0, "Start corner #1");
	menu.AddItem(CHOICE1, "Start corner #2");
	menu.AddItem(CHOICE2, "End corner #1");
	menu.AddItem(CHOICE3, "End corner #2");
	menu.AddItem(CHOICE4, "Reset Zones");
	char buffer[100];
			
	if (g_bStartOnJump[client])
	{
		Format(buffer, sizeof(buffer), "Start on jump - ON");
		menu.AddItem(CHOICE5, buffer);
	}
	else
	{
		Format(buffer, sizeof(buffer), "Start on jump - OFF");
		menu.AddItem(CHOICE5, buffer);
	}
	
	if (g_bStopOnLand[client])
	{
		Format(buffer, sizeof(buffer), "Stop on landing - ON");
		menu.AddItem(CHOICE6, buffer);
	}
	else
	{
		Format(buffer, sizeof(buffer), "Stop on landing - OFF");
		menu.AddItem(CHOICE6, buffer);
	}
	//menu.AddItem(CHOICE5, "Start time on jump");
	//menu.AddItem(CHOICE6, "Stop time on land");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public bool PointIsInCuboid(float ppos[3], float corner0[3], float corner1[3])
{
	float min[3];
	float max[3];
	
	for (int i = 0; i < 3; i++)
	{
		if (corner0[i] < corner1[i])
		{
			min[i] = corner0[i];
			max[i] = corner1[i];
		}
		else if (corner0[i] > corner1[i])
		{
			min[i] = corner1[i];
			max[i] = corner0[i];
		}
	}
	
	return (ppos[0] <= max[0] && ppos[0] >= min[0]) && (ppos[1] <= max[1] && ppos[1] >= min[1]) && (ppos[2] <= max[2] && ppos[2] >= min[2]);
}

stock bool IsValidClient(client)
{
	return (client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client));
}