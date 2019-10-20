
#if defined _gamechaos_stocks_strings_included
	#endinput
#endif
#define _gamechaos_stocks_strings_included

/**
 * Prints a message to all admins in the chat area.
 *
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @error					If the client is not connected an error will be thrown.
 */
stock void PrintToChatAdmins(const char[] format, any ...)
{
	char buffer[256];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			AdminId id = GetUserAdmin(i);
			if (!GetAdminFlag(id, Admin_Generic))
			{
				continue;
			}
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToChat(i, "%s", buffer);
		}
	}
}

/**
 * Removes trailings zeroes from a string. Also removes the decimal point if it can.
 *
 * @param string			
 * @param strsize			
 * @param separator			
 * @param array				
 * @param arraysize			
 * @error					If the client is not connected an error will be thrown.
 */
stock bool RemoveTrailing0s(char[] buffer, int maxlen)
{
	bool removed;
	for (int i = maxlen - 4; buffer[i] == '0' || buffer[i] == '.' || buffer[i] == 0; i--)
	{
		if (buffer[i] == 0)
		{
			continue;
		}
		if (buffer[i] == '.')
		{
			buffer[i] = 0;
			removed = true;
			break;
		}
		buffer[i] = 0;
		removed = true;
	}
	return removed;
}

/**
 * Formats time by HHMMSS. Uses ticks for the time.
 *
 * @param timeInTicks		Time in ticks.
 * @param tickRate			Tickrate.
 * @param formattedTime		String to use for formatting.
 * @param size				String size.
 */
stock void FormatTickTimeHHMMSS(int timeInTicks, float tickRate, char[] formattedTime, int size)
{
	if (timeInTicks <= 0)
	{
		FormatEx(formattedTime, size, "-00:00:00");
		return;
	}
	
	int time = RoundFloat(float(timeInTicks) / tickRate * 100.0); // centiseconds
	int iHours = time / 360000;
	int iMinutes = time / 6000 - iHours * 6000;
	int iSeconds = (time - iHours * 360000 - iMinutes * 6000) / 100;
	int iCentiSeconds = time % 100;
	
	if (iHours != 0)
	{
		FormatEx(formattedTime, size, "%02i:", iHours);
	}
	if (iMinutes != 0)
	{
		Format(formattedTime, size, "%s%02i:", formattedTime, iMinutes);
	}
	
	Format(formattedTime, size, "%s%02i.%02i", formattedTime, iSeconds, iCentiSeconds);
}

/**
 * Formats time by HHMMSS. Uses seconds.
 *
 * @param seconds			Time in seconds.
 * @param formattedTime		String to use for formatting.
 * @param size				String size.
 * @param decimals			Amount of decimals to use for the fractional part.
 */
stock void FormatTimeHHMMSS(float seconds, char[] formattedTime, int size, int decimals)
{
	int iFlooredTime = RoundToFloor(seconds);
	int iHours = iFlooredTime / 3600;
	int iMinutes = iFlooredTime / 60 - iHours * 60;
	int iSeconds = iFlooredTime - iHours * 3600 - iMinutes * 60;
	int iFraction = RoundToFloor(FloatFraction(seconds) * Pow(10.0, float(decimals)));
	
	if (iHours != 0)
	{
		FormatEx(formattedTime, size, "%02i:", iHours);
	}
	if (iMinutes != 0)
	{
		Format(formattedTime, size, "%s%02i:", formattedTime, iMinutes);
	}
	char szFraction[32];
	FormatEx(szFraction, sizeof(szFraction), "%i", iFraction);
	
	int iTest = strlen(szFraction);
	for (int i; i < decimals - iTest; i++)
	{
		Format(szFraction, sizeof(szFraction), "%s%s", "0", szFraction);
	}
	
	Format(formattedTime, size, "%s%02i.%s", formattedTime, iSeconds, szFraction);
}