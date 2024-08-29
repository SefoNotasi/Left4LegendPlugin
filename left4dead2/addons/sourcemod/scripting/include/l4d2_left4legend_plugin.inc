#if defined _l4d2_left4legend_plugin_included
	#endinput
#endif

#define _l4d2_left4legend_plugin_included
#define DEFAULT_SPAWN_COUNT 1

public SharedPlugin __pl_l4d2_left4legend_plugin = {
	name = "[L4D2] Left 4 Legend plugin",
	file = "l4d2_left4legend_plugin.smx",

#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public void __pl_l4d2_left4legend_plugin_SetNTVOptional()
{
	MarkNativeAsOptional("L4LP_SpawnRandomSI");
	MarkNativeAsOptional("L4LP_SpawnTank");
	MarkNativeAsOptional("L4LP_SpawnMob");
	MarkNativeAsOptional("L4LP_GetRestartsCount");
}
#endif

/**
 * @brief	Spawns specified number of random special infected
 *
 * @param	client	[integer] Client index
 * @param	count	[optional integer] Number of random special infected, default value is DEFAULT_SPAWN_COUNT (1)
 *
 * @error	Invalid arguments or client index
 *
 * @noreturn
 */
native void L4LP_SpawnRandomSI(int client, int count = DEFAULT_SPAWN_COUNT);

/**
 * @brief	Spawns specified number of tanks
 *
 * @param	client	[integer] Client index
 * @param	count	[optional integer] Number of tanks, default value is DEFAULT_SPAWN_COUNT (1)
 *
 * @error	Invalid arguments or client index
 *
 * @noreturn
 */
native void L4LP_SpawnTank(int client, int count = DEFAULT_SPAWN_COUNT);

/**
 * @brief	Spawn horde
 *
 * @param	client	[integer] Client index
 *
 * @error	Invalid arguments or client index
 *
 * @noreturn
 */
native void L4LP_SpawnMob(int client);

/**
 * @brief	Get number of restarts
 *
 * @return	[integer] Number of restarts
 */
native int	L4LP_GetRestartsCount();