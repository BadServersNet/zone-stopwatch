
#define PLUGIN_NAME				"Zone Stopwatch"
#define PLUGIN_AUTHOR			"GameChaos"
#define PLUGIN_DESCRIPTION		"A stopwatch that uses zones."
#define PLUGIN_VERSION			"1.0.3"
#define PLUGIN_URL				"https://bitbucket.org/GameChaos/zone-stopwatch"

#define C_WHITE					{ 255, 255, 255, 255 }
#define C_GREEN					{   0, 255,   0, 255 }
#define C_RED					{ 255,   0,   0, 255 }

#define PREFIX					"{default}[{olive}GC{default}]"

#include <sourcemod>
#include <sdktools>

#include <gamechaos/client>
#include <gamechaos/misc>
#include <gamechaos/strings>
#include <gamechaos/tracing>
#include <colors>

#undef REQUIRE_PLUGIN
#include <gokz/core>
#include <kztimer>

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

int g_iBeam;

bool g_bStartOnJump[MAXPLAYERS + 1];
bool g_bStopOnLand[MAXPLAYERS + 1];

float g_fStartTime[MAXPLAYERS + 1];
float g_fEndTime[MAXPLAYERS + 1];

enum struct Zone
{
	float point1[3];
	float point2[3];
	float mins[3];
	float maxs[3];
	bool point1_active;
	bool point2_active;
	
	void SetPoint1(int client)
	{
		this.SetPoint(client, this.point1);
		this.point1_active = true;
		CPrintToChat(client, "%s {grey}Point #{lime}1{grey} set!", PREFIX);
		
		if (this.point1_active && this.point2_active)
		{
			CalculateAABBMinsMaxs(this.point1, this.point2, this.mins, this.maxs);
		}
	}
	
	void SetPoint2(int client)
	{
		this.SetPoint(client, this.point2);
		this.point2_active = true;
		CPrintToChat(client, "%s {grey}Point #{lime}2{grey} set!", PREFIX);
		
		if (this.point1_active && this.point2_active)
		{
			CalculateAABBMinsMaxs(this.point1, this.point2, this.mins, this.maxs);
		}
	}
	
	void SendPoint1Square(int client, int modelIndex, const int colour[4])
	{
		SendBeamSquare(client, modelIndex, this.point1, colour);
	}
	
	void SendPoint2Square(int client, int modelIndex, const int colour[4])
	{
		SendBeamSquare(client, modelIndex, this.point2, colour);
	}
	
	void SendBeamZone(int client, int modelIndex, const int colour[4])
	{
		if (this.point1_active && this.point2_active)
		{
			TE_SendBeamBox(client, view_as<float>({ 0.0, 0.0, 0.0 }), this.point1, this.point2, modelIndex, 0, 1.0, 2.0, colour, 2.0);
		}
	}
	
	void SetPoint(int client, float point[3])
	{
		float fOrigin[3];
		GetClientEyePosition(client, fOrigin);
		float fAngles[3];
		GetClientEyeAngles(client, fAngles);
		float fMins[3] = { -16.0, -16.0, 0.0 };
		float fMaxs[3] = { 16.0, 16.0, 0.0 };
		
		TraceHullDirection(fOrigin, fAngles, fMins, fMaxs, point, 256.0);
	}
	
	// Reset zone positions
	void Reset()
	{
		this.point1_active = false;
		this.point2_active = false;
		this.point1 = NULL_VECTOR;
		this.point2 = NULL_VECTOR;
	}
}

Zone g_zoneStart[MAXPLAYERS + 1];
Zone g_zoneEnd[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_ztopwatch", Command_SmZtopwatch);
	HookEvent("player_jump", Event_PlayerJump);
}

public void OnConfigsExecuted()
{
	g_iBeam = PrecacheModel("materials/sprites/laser.vmt", true);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			OnClientConnected(client);
		}
	}
}

public void OnClientConnected(int client)
{
	ResetVars(client);
}

public void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!g_bStartOnJump[client])
	{
		return;
	}
	
	if (!g_zoneStart[client].point1_active || !g_zoneStart[client].point2_active
	 || !g_zoneEnd[client].point1_active || !g_zoneEnd[client].point2_active)
	{
		return;
	}
	
	TryStartingTimer(client);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClientExt(client, true)
		|| IsTimerRunning(client))
	{
		return;
	}
	
	// refresh zone every half second
	if (!(GetGameTickCount() % RoundFloat(0.5 / GetTickInterval())))
	{
		g_zoneStart[client].SendBeamZone(client, g_iBeam, C_GREEN);
		g_zoneEnd[client].SendBeamZone(client, g_iBeam, C_RED);
	}
	
	TimeZones(client);
}

// =============
//   FUNCTIONS
// =============

// timing and stuff happens here
void TimeZones(int client)
{
	if (!g_zoneStart[client].point1_active || !g_zoneStart[client].point2_active
	 || !g_zoneEnd[client].point1_active || !g_zoneEnd[client].point2_active)
	{
		return;
	}
	
	float fPlayerMins[3];
	float fPlayerMaxs[3];
	GetClientMins(client, fPlayerMins);
	GetClientMaxs(client, fPlayerMaxs);
	
	if (!g_bStartOnJump[client])
	{
		TryStartingTimer(client);
	}
	
	if (g_bStopOnLand[client])
	{
		if (GetEntityFlags(client) & FL_ONGROUND
			&& TryEndingTimer(client))
		{
			OnTimerEnd(client);
		}
	}
	else if (TryEndingTimer(client))
	{
		OnTimerEnd(client);
	}
}

void OnTimerEnd(int client)
{
	char szTime[16];
	FormatTimeHHMMSS(g_fEndTime[client] - g_fStartTime[client], szTime, sizeof(szTime), 3);
	CPrintToChat(client, "%s {grey}Elapsed time: [{lime}%s{grey}].", PREFIX, szTime);
	
	ResetTimer(client);
}

bool TryStartingTimer(int client)
{
	float fPlayerMins[3];
	float fPlayerMaxs[3];
	GetClientMins(client, fPlayerMins);
	GetClientMaxs(client, fPlayerMaxs);
	float fPlayerOrigin[3];
	GetClientAbsOrigin(client, fPlayerOrigin);
	for (int i; i < 3; i++)
	{
		fPlayerMins[i] += fPlayerOrigin[i];
		fPlayerMaxs[i] += fPlayerOrigin[i];
	}
	
	if (!(AABBIntersecting(fPlayerMins, fPlayerMaxs, g_zoneStart[client].mins, g_zoneStart[client].maxs)))
	{
		return false;
	}
	g_fStartTime[client] = GetGameTime();
	return true;
}

bool TryEndingTimer(int client)
{
	if (g_fStartTime[client] == 0.0)
	{
		return false;
	}
	float fPlayerMins[3];
	float fPlayerMaxs[3];
	GetClientMins(client, fPlayerMins);
	GetClientMaxs(client, fPlayerMaxs);
	float fPlayerOrigin[3];
	GetClientAbsOrigin(client, fPlayerOrigin);
	for (int i; i < 3; i++)
	{
		fPlayerMins[i] += fPlayerOrigin[i];
		fPlayerMaxs[i] += fPlayerOrigin[i];
	}
	
	if (!(AABBIntersecting(fPlayerMins, fPlayerMaxs, g_zoneEnd[client].mins, g_zoneEnd[client].maxs)))
	{
		return false;
	}
	g_fEndTime[client] = GetGameTime();
	return true;
}

// resets timer stuff
void ResetTimer(int client)
{
	g_fStartTime[client] = 0.0;
	g_fEndTime[client] = 0.0;
}

bool IsTimerRunning(int client)
{
	if (GetFeatureStatus(FeatureType_Native, "KZTimer_GetTimerStatus") == FeatureStatus_Available
		&& KZTimer_GetTimerStatus(client))
	{
		return true;
	}
	else if (GetFeatureStatus(FeatureType_Native, "GOKZ_GetTimerRunning") == FeatureStatus_Available
		&& GOKZ_GetTimerRunning(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}

void SendBeamSquare(int client, int modelIndex, const float point[3], const int colour[4])
{
	float vertices[4][3];
	RectangleVerticesFromPoint(vertices, point, view_as<float>({ -16.0, -16.0, 0.0 }), view_as<float>({ 16.0, 16.0, 0.0 }));
	
	float width = 2.0;
	float life = 3.0;
	
	// send the square
	for (int i; i < 4; i++)
	{
		int j = (i == 3) ? (0) : (i + 1);
		TE_SetupBeamPoints(vertices[i], vertices[j], modelIndex, 0, 0, 0, life, width, width, 0, 0.0, colour, 0);
		TE_SendToClient(client);
	}
	// make a nice cross
	TE_SendBeamCross(client, point, modelIndex, 0, life, width, colour, width);
}

void ResetVars(int client)
{
	g_zoneStart[client].Reset();
	g_zoneEnd[client].Reset();
	
	ResetTimer(client);
}

// checks if 2 AABBs are inside each other
bool AABBIntersecting(float a_mins[3], float a_maxs[3], float b_mins[3], float b_maxs[3])
{
	return (a_mins[0] <= b_maxs[0] && a_maxs[0] >= b_mins[0]) &&
		   (a_mins[1] <= b_maxs[1] && a_maxs[1] >= b_mins[1]) &&
		   (a_mins[2] <= b_maxs[2] && a_maxs[2] >= b_mins[2]);
}

void CalculateAABBMinsMaxs(const float point1[3], const float point2[3], float mins[3], float maxs[3])
{
	for (int i; i < 3; i++)
	{
		float new_mins;
		float new_maxs;
		new_mins = point1[i] < point2[i] ? point1[i] : point2[i];
		new_maxs = point1[i] > point2[i] ? point1[i] : point2[i];
		mins[i] = new_mins;
		maxs[i] = new_maxs;
	}
}

public Action Command_SmZtopwatch(int client, int args)
{
	if (!IsValidClientExt(client, true))
	{
		CPrintToChat(client, "%s {darkred}You have to be alive to use this!", PREFIX);
		return Plugin_Handled;
	}
	if (IsTimerRunning(client))
	{
		CPrintToChat(client, "%s {darkred}Your timer has to be off to use this!", PREFIX);
		return Plugin_Handled;
	}
	Showmenu_Ztopwatch(client);
	return Plugin_Handled;
}

// =========
//   MENUS
// =========

void Showmenu_Ztopwatch(int client)
{
	Menu menu = new Menu(Menu_Ztopwatch, MENU_ACTIONS_ALL);
	menu.Pagination = MENU_NO_PAGINATION;
	menu.SetTitle("Zone Stopwatch");
	menu.AddItem("0", "Start corner #1");
	menu.AddItem("1", "Start corner #2");
	menu.AddItem("2", "End corner #1");
	menu.AddItem("3", "End corner #2");
	menu.AddItem("4", "Reset zones");
	
	char szStartOnJump[64];
	FormatEx(szStartOnJump, sizeof(szStartOnJump), "Start timer on jump - %s", g_bStartOnJump[client] ? "ON" : "OFF");
	menu.AddItem("5", szStartOnJump);
	
	char szStopOnLand[64];
	FormatEx(szStopOnLand, sizeof(szStopOnLand), "Stop timer on land - %s", g_bStopOnLand[client] ? "ON" : "OFF");
	menu.AddItem("6", szStopOnLand);
	
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
				// Start corner #1
				case 0:
				{
					g_zoneStart[param1].SetPoint1(param1);
					g_zoneStart[param1].SendPoint1Square(param1, g_iBeam, C_WHITE);
					Showmenu_Ztopwatch(param1);
				}
				// Start corner #2
				case 1:
				{
					g_zoneStart[param1].SetPoint2(param1);
					g_zoneStart[param1].SendPoint2Square(param1, g_iBeam, C_WHITE);
					Showmenu_Ztopwatch(param1);
				}
				// End corner #2
				case 2:
				{
					g_zoneEnd[param1].SetPoint1(param1);
					g_zoneEnd[param1].SendPoint1Square(param1, g_iBeam, C_WHITE);
					Showmenu_Ztopwatch(param1);
				}
				// End corner #2
				case 3:
				{
					g_zoneEnd[param1].SetPoint2(param1);
					g_zoneEnd[param1].SendPoint2Square(param1, g_iBeam, C_WHITE);
					Showmenu_Ztopwatch(param1);
				}
				// reset zones
				case 4:
				{
					g_zoneStart[param1].Reset();
					g_zoneEnd[param1].Reset();
					Showmenu_Ztopwatch(param1);
				}
				// start on jump
				case 5:
				{
					g_bStartOnJump[param1] = !g_bStartOnJump[param1];
					Showmenu_Ztopwatch(param1);
				}
				// stop on land
				case 6:
				{
					g_bStopOnLand[param1] = !g_bStopOnLand[param1];
					Showmenu_Ztopwatch(param1);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}