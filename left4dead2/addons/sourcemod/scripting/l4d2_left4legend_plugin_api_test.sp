#pragma semicolon 1
#pragma newdecls required

#undef REQUIRE_PLUGIN
#include <l4d2_left4legend_plugin>

#define TEST_TAG "\x04[\x05L4LP\x04] \x03Test:\x01"

public void OnPluginStart()
{
	RegConsoleCmd("sm_si", TestSpawnRandomSI);
	RegConsoleCmd("sm_tank", TestSpawnTank);
	RegConsoleCmd("sm_mob", TestSpawnMob);
	RegConsoleCmd("sm_res", TestPrintRestarts);
}

Action TestSpawnRandomSI(int client, int arguments)
{
	PrintToChatAll("%s L4LP_SpawnRandomSI", TEST_TAG);

	L4LP_SpawnRandomSI(client);

	return Plugin_Handled;
}

Action TestSpawnTank(int client, int arguments)
{
	PrintToChatAll("%s L4LP_SpawnTank", TEST_TAG);

	L4LP_SpawnTank(client);

	return Plugin_Handled;
}

Action TestSpawnMob(int client, int arguments)
{
	PrintToChatAll("%s L4LP_SpawnMob", TEST_TAG);

	L4LP_SpawnMob(client);

	return Plugin_Handled;
}

Action TestPrintRestarts(int client, int arguments)
{
	PrintToChatAll("%s L4LP_GetRestartsCount \x04%d", TEST_TAG, L4LP_GetRestartsCount());

	return Plugin_Handled;
}