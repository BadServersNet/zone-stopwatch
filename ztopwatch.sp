#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// not required to have either
#undef REQUIRE_PLUGIN
#include <gokz/core>
#include <kztimer>

public Plugin myinfo = 
{
	name = "Zone Stopwatch", 
	author = "GameChaos", 
	description = "A stopwatch with zones.", 
	version = "0.2"
}

#define CHOICE0 	"#choice0"
#define CHOICE1 	"#choice1"
#define CHOICE2 	"#choice2"
#define CHOICE3 	"#choice3"
#define CHOICE4 	"#choice4"
#define CHOICE5 	"#choice5"
#define CHOICE6 	"#choice6"
#define GREEN		{ 0, 255, 0, 255 }
#define RED			{ 255, 0, 0, 255 }
#define OUTOFRANGE	99999.0
#define MAX_RADIUS	160.0

enum
{
	Mm_Origin,
	Mm_Eye_Dir,
	Mm_Radius,
	MM_COUNT
}

char g_szMeasureMode[][] = 
{
	"Measuring mode - Origin",
	"Measuring mode - Eye dir",
	"Measuring mode - Eye radius"
};

float g_fStartCorner1[MAXPLAYERS + 1][3];
float g_fStartCorner2[MAXPLAYERS + 1][3];
float g_fEndCorner1[MAXPLAYERS + 1][3];
float g_fEndCorner2[MAXPLAYERS + 1][3];

float g_fPlayerPos[MAXPLAYERS + 1][3];

float corners[8][3];
float corner[2][3];

float g_fTimerStart[MAXPLAYERS + 1];

int pairs[8][3] =  {  { 0, 0, 0 }, { 1, 0, 0 }, { 1, 1, 0 }, { 0, 1, 0 }, { 0, 0, 1 }, { 1, 0, 1 }, { 1, 1, 1 }, { 0, 1, 1 } };
int edges[12][2] =  {  { 0, 1 }, { 0, 3 }, { 0, 4 }, { 2, 1 }, { 2, 3 }, { 2, 6 }, { 5, 4 }, { 5, 6 }, { 5, 1 }, { 7, 4 }, { 7, 6 }, { 7, 3 } };

int g_iMeasureMode[MAXPLAYERS + 1];

bool g_bStartCorner1[MAXPLAYERS + 1];
bool g_bStartCorner2[MAXPLAYERS + 1];

bool g_bEndCorner1[MAXPLAYERS + 1];
bool g_bEndCorner2[MAXPLAYERS + 1];

bool g_bStartOnJump[MAXPLAYERS + 1];
bool g_bStopOnLand[MAXPLAYERS + 1];
bool g_bEditStartZone[MAXPLAYERS + 1];

static int g_Beam;

Handle g_hTimer_ShowZones[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_ztopwatch", Command_Ztopwatch);
}

public void OnClientConnected(int client)
{
	resetVars(client);
}

public void resetVars(int client)
{
	g_bStartCorner1[client] = false;
	g_bStartCorner2[client] = false;
	g_bEndCorner1[client] = false;
	g_bEndCorner2[client] = false;
	
	if (g_hTimer_ShowZones[client] != null)
	{
		delete g_hTimer_ShowZones[client];
		g_hTimer_ShowZones[client] = null;
	}
	
	for (int i = 0; i <= MaxClients; i++)
	{
		g_fStartCorner1[i] = view_as<float>( { OUTOFRANGE, OUTOFRANGE, OUTOFRANGE } );
		g_fStartCorner2[i] = view_as<float>( { OUTOFRANGE, OUTOFRANGE, OUTOFRANGE } );
		g_fEndCorner1[i] = view_as<float>( { OUTOFRANGE, OUTOFRANGE, OUTOFRANGE } );
		g_fEndCorner2[i] = view_as<float>( { OUTOFRANGE, OUTOFRANGE, OUTOFRANGE } );
	}
}

public void OnConfigsExecuted()
{
	g_Beam = PrecacheModel("materials/sprites/laser.vmt", true);
}

public void setCorner(int client, float vecCorner[3], int measureMode)
{
	if (measureMode == Mm_Origin)
	{
		GetClientAbsOrigin(client, vecCorner);
		for (int i = 0; i < 3; i++)
		{
			vecCorner[i] = RoundToNearest(vecCorner[i]) + 0.0
		}
	}
	else if (measureMode == Mm_Eye_Dir)
	{
		float eyeAngles[3];
		GetClientEyePosition(client, vecCorner);
		GetClientEyeAngles(client, eyeAngles);
		
		TR_TraceRayFilter(vecCorner, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceEntityFilterPlayer);
		if (TR_DidHit())
		{
			TR_GetEndPosition(vecCorner);
		}
	}
	else if (measureMode == Mm_Radius)
	{
		float eyeAngles[3];
		GetClientEyePosition(client, vecCorner);
		GetClientEyeAngles(client, eyeAngles);
		
		GetAngleVectors(eyeAngles, eyeAngles, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(eyeAngles, eyeAngles);
		ScaleVector(eyeAngles, MAX_RADIUS);
		
		TR_TraceRayFilter(vecCorner, eyeAngles, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayer);
		if (TR_DidHit())
		{
			TR_GetEndPosition(vecCorner);
		}
	}
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, CHOICE0))
			{
				g_bEditStartZone[param1] = !g_bEditStartZone[param1];
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE1))
			{
				//setCorner(param1, g_fStartCorner2[param1]);
				//g_bStartCorner2[param1] = true;
				resetVars(param1);
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE2))
			{
				g_bStartOnJump[param1] = !g_bStartOnJump[param1];
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE3))
			{
				g_bStopOnLand[param1] = !g_bStopOnLand[param1];
				ShowMenu(param1);
			}
			else if (StrEqual(info, CHOICE4))
			{
				g_iMeasureMode[param1]++;
				if (g_iMeasureMode[param1] >= MM_COUNT)
				{
					g_iMeasureMode[param1] = 0;
				}
				ShowMenu(param1);
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("[ztopwatch] Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public Action Timer_ShowZones(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	int colour[4];
	
	if (IsTimerRunning(client))
	{
		return Plugin_Continue;
	}
	
	if ((g_bStartCorner1[client] && g_bStartCorner2[client]) || (g_bEndCorner1[client] && g_bEndCorner2[client]))
	{
		for (int i = 0; i < 2; i++)
		{
			if (i == 0)
			{
				corner[0] = g_fStartCorner1[client]
				corner[1] = g_fStartCorner2[client]
				colour = GREEN;
			}
			else if (i == 1)
			{
				corner[0] = g_fEndCorner1[client]
				corner[1] = g_fEndCorner2[client]
				colour = RED;
			}
			for (int l = 0; l < 8; l++)
			{
				corners[l][0] = corner[pairs[l][0]][0];
				corners[l][1] = corner[pairs[l][1]][1];
				corners[l][2] = corner[pairs[l][2]][2];
			}
			for (int l = 0; l < 12; l++)
			{
				TE_SetupBeamPoints(corners[edges[l][0]], corners[edges[l][1]], g_Beam, 0, 0, 0, 0.2, 3.0, 3.0, 10, 0.0, colour, 0);
				TE_SendToClient(client, 0.0);
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	static bool bJumped[MAXPLAYERS + 1];
	static bool bLastInJump[MAXPLAYERS + 1];
	static int iButtonPressed[MAXPLAYERS + 1];
	
	iButtonPressed[client] = GetEntProp(client, Prop_Data, "m_afButtonPressed");
	
	if (iButtonPressed[client] & IN_ATTACK)
	{
		if (g_bEditStartZone[client])
		{
			setCorner(client, g_fStartCorner1[client], g_iMeasureMode[client]);
			g_bStartCorner1[client] = true;
		}
		else
		{
			setCorner(client, g_fEndCorner1[client], g_iMeasureMode[client]);
			g_bEndCorner1[client] = true;
		}
	}
	else if (iButtonPressed[client] & IN_ATTACK2)
	{
		if (g_bEditStartZone[client])
		{
			setCorner(client, g_fStartCorner2[client], g_iMeasureMode[client]);
			g_bStartCorner1[client] = true;
		}
		else
		{
			setCorner(client, g_fEndCorner2[client], g_iMeasureMode[client]);
			g_bEndCorner2[client] = true;
		}
	}
	
	if (g_fStartCorner1[client][2] == g_fStartCorner2[client][2] && g_fStartCorner1[client][2] != OUTOFRANGE)
	{
		g_fStartCorner2[client][2] += 16.0;
	}
	if (g_fEndCorner1[client][2] == g_fEndCorner2[client][2] && g_fEndCorner1[client][2] != OUTOFRANGE)
	{
		g_fEndCorner2[client][2] += 16.0;
	}
	
	bJumped[client] = !bLastInJump[client] && GetEntityFlags(client) & FL_ONGROUND;
	
	if ((g_bStartCorner1[client] && g_bStartCorner2[client]) || (g_bEndCorner1[client] && g_bEndCorner2[client]))
	{
		if (g_hTimer_ShowZones[client] == null)
		{
			g_hTimer_ShowZones[client] = CreateTimer(0.2, Timer_ShowZones, GetClientSerial(client), TIMER_REPEAT);
		}
	}
	
	if (g_bStartCorner1[client] && g_bStartCorner2[client] && g_bEndCorner1[client] && g_bEndCorner2[client])
	{
		GetClientAbsOrigin(client, g_fPlayerPos[client]);
		
		if (PointIsInCuboid(g_fPlayerPos[client], g_fStartCorner1[client], g_fStartCorner2[client]))
		{
			if (g_bStartOnJump[client])
			{
				if (bJumped[client])
				{
					g_fTimerStart[client] = GetEngineTime();
				}
			}
			else
			{
				g_fTimerStart[client] = GetEngineTime();
			}
		}
		else if (PointIsInCuboid(g_fPlayerPos[client], g_fEndCorner1[client], g_fEndCorner2[client]) && 
						   g_fTimerStart[client] != 0.0 && GetEngineTime() != g_fTimerStart[client])
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
	else if (g_hTimer_ShowZones[client] != null)
	{
		delete g_hTimer_ShowZones[client];
		g_hTimer_ShowZones[client] = null;
	}
	
	bLastInJump[client] = !!(buttons & IN_JUMP);
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
	menu.SetTitle("Ztopwatch\n+attack to set 1st corner\n+attack2 to set 2nd corner");
	if (g_bEditStartZone[client])
		menu.AddItem(CHOICE0, "Current zone - Start");
	else
		menu.AddItem(CHOICE0, "Current zone - End");
	
	menu.AddItem(CHOICE1, "Reset zones");
	
	if (g_bStartOnJump[client])
		menu.AddItem(CHOICE2, "Start timer on jump - ON");
	else
		menu.AddItem(CHOICE2, "Start timer on jump - OFF");
	
	if (g_bStopOnLand[client])
		menu.AddItem(CHOICE3, "Stop timer on land - ON");
	else
		menu.AddItem(CHOICE3, "Stop timer on land - OFF");
	
	menu.AddItem(CHOICE4, g_szMeasureMode[g_iMeasureMode[client]]);
	
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

bool IsTimerRunning(int client)
{
	// just a check so peanut brained idiots don't abuse this to see invisible walls
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

/*stock bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client));
}*/

stock bool TraceEntityFilterPlayer(int entity, any data)
{
	return entity > MAXPLAYERS;
}