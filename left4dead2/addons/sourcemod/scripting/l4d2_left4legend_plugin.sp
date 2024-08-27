#pragma semicolon 1
#pragma newdecls required

#include <left4dhooks>

#define PLUGIN_VERSION		   "0.0.1"
#define CVAR_FLAGS			   FCVAR_NOTIFY
#define SPAWN_COMMAND_OLD	   "z_spawn_old"
#define SPAWN_ARGUMENT_AUTO	   "auto"
#define DEBUG_TAG			   "\x04[\x05L4LP\x04] \x03Debug:\x01"
#define DEBUG_EVENTS		   2
#define DEBUG_SOUNDS		   3
#define TEAM_SURVIVORS		   2
#define TEAM_INFECTED		   3
#define TANK_CLASS			   8
#define MAX_SI				   28
#define MAX_INT_STRING_LENGTH  11
#define MUTE				   0.0
#define DEFAULT_SPAWN_COUNT	   1
#define FIRST_ARGUMENT		   1
#define CLIENT_NOT_FOUND	   0
#define PLAYER_PATH_LENGTH	   7
#define ENABLE				   1
#define DISABLE				   0
#define EVENT_USER_MESSAGE	   "PZDmgMsg"
#define EVENT_PLAYER_DEATH	   "player_death"
#define EVENT_PLAYER_INCAP	   "player_incapacitated"
#define EVENT_LEDGE_GRAB	   "player_ledge_grab"
#define EVENT_WITCH_HARASSER   "witch_harasser_set"
#define EVENT_MISSION_LOST	   "mission_lost"
#define EVENT_HEAL_SUCCESS	   "heal_success"
#define EVENT_REVIVE_SUCCESS   "revive_success"
#define EVENT_SURVIVOR_RESCUED "survivor_rescued"
#define EVENT_AWARD_EARNED	   "award_earned"
#define EVENT_CAR_ALARM		   "OnCarAlarmStart"
#define PROP_CAR_ALARM		   "prop_car_alarm"

static const char g_sInfectedSounds[13][] = {
	"player/boomer/voice/alert/",
	"player/boomer/voice/idle/",
	"player/charger/voice/alert/",
	"player/charger/voice/idle/",
	"player/hunter/voice/alert/",
	"player/hunter/voice/idle/",
	"player/jockey/voice/alert/",
	"player/jockey/voice/idle/",
	"player/smoker/voice/alert/",
	"player/smoker/voice/idle/",
	"player/spitter/voice/alert/",
	"player/spitter/voice/idle/",
	"player/tank/voice/idle/"
};

static const char g_sInfectedClasses[6][] = {
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
};

static const int g_sInfectedClassesCount = sizeof(g_sInfectedClasses) - 1;

ConVar			 g_hCvarEnable, g_hCvarDebug, g_hCvarSurvivorIncap, g_hCvarSurvivorDeath, g_hCvarWitchHarasser, g_hCvarPrintRestarts, g_hCvarKillFeed, g_hCvarCarAlarm, g_hCvarSilentInfected;
int				 g_iCvarDebug, g_iCvarSurvivorIncap, g_iRestarts = 0, g_iInfectedSoundsLengths[sizeof(g_sInfectedSounds)];
bool			 g_bCvarEnable, g_bCvarSurvivorDeath, g_bCvarWitchHarasser, g_bCvarKillFeed, g_bCvarCarAlarm, g_bCvarSilentInfected, g_bCvarPrintRestarts;

public Plugin myinfo =
{ name = "[L4D2] Left 4 Legend plugin", author = "Sefo, Lombaxtard", description = "Makes L4D2 challenging again!", version = PLUGIN_VERSION, url = "Sefo.su"


}

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");

		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_left4legend_plugin.phrases");

	CreateConVar("l4d2_l4lp_version", PLUGIN_VERSION, "Left 4 Legend plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);
	g_hCvarEnable		  = CreateConVar("l4d2_l4lp_enable", "1", "0 = Plugin off, 1 = Plugin on", CVAR_FLAGS, true, float(DISABLE), true, float(ENABLE));
	g_hCvarDebug		  = CreateConVar("l4d2_l4lp_debug", "0", "0 = Debug off, 1 = Debug on, 2 = Debug events, 3 = Debug sounds", CVAR_FLAGS, true, float(DISABLE), true, float(DEBUG_SOUNDS));
	g_hCvarSurvivorIncap  = CreateConVar("l4d2_l4lp_incap_spawn_si", "1", "0 = Off, Number of special infected spawned when a survivor is incapacitated", CVAR_FLAGS, true, float(DISABLE), true, float(MAX_SI));
	g_hCvarSurvivorDeath  = CreateConVar("l4d2_l4lp_death_spawn_mob", "1", "0 = Off, 1 = Spawn horde when a survivor dies", CVAR_FLAGS, true, float(DISABLE), true, float(ENABLE));
	g_hCvarWitchHarasser  = CreateConVar("l4d2_l4lp_witch_spawn_mob", "1", "0 = Off, 1 = Spawn horde when witch is enraged", CVAR_FLAGS, true, float(DISABLE), true, float(ENABLE));
	g_hCvarPrintRestarts  = CreateConVar("l4d2_l4lp_print_restarts", "0", "0 = Off, 1 = Show in chat number of restarts on each new round", CVAR_FLAGS, true, float(DISABLE), true, float(ENABLE));
	g_hCvarKillFeed		  = CreateConVar("l4d2_l4lp_kill_feed", "1", "0 = Off, 1 = Disable kill feed", CVAR_FLAGS, true, float(DISABLE), true, float(ENABLE));
	g_hCvarCarAlarm		  = CreateConVar("l4d2_l4lp_alarm_spawn_tank", "1", "0 = Off, 1 = A car alarm spawns tank", CVAR_FLAGS, true, float(DISABLE), true, float(ENABLE));
	g_hCvarSilentInfected = CreateConVar("l4d2_l4lp_silent_infected", "1", "0 = Off, 1 = Disable alert & idle sounds of special infected", CVAR_FLAGS, true, float(DISABLE), true, float(ENABLE));
	AutoExecConfig(true, "l4d2_left4legend_plugin");

	g_hCvarEnable.AddChangeHook(CvarChanged_Enable);
	g_hCvarDebug.AddChangeHook(CvarChanged_Cvars);
	g_hCvarSurvivorIncap.AddChangeHook(CvarChanged_Cvars);
	g_hCvarSurvivorDeath.AddChangeHook(CvarChanged_Cvars);
	g_hCvarWitchHarasser.AddChangeHook(CvarChanged_Cvars);
	g_hCvarPrintRestarts.AddChangeHook(CvarChanged_Cvars);
	g_hCvarKillFeed.AddChangeHook(CvarChanged_Cvars);
	g_hCvarCarAlarm.AddChangeHook(CvarChanged_Cvars);
	g_hCvarSilentInfected.AddChangeHook(CvarChanged_Cvars);

	RegAdminCmd("sm_debug", CommandSetDebug, ADMFLAG_ROOT, "Set plugin debug mode");
	RegAdminCmd("sm_spawn_tank", CommandSpawnTank, ADMFLAG_ROOT, "Spawns specified number of tanks (1 by default)");
	RegAdminCmd("sm_spawn_si", CommandSpawnRandomSI, ADMFLAG_ROOT, "Spawns specified number of random special infected (1 by default)");
	RegAdminCmd("sm_spawn_mob", CommandSpawnMob, ADMFLAG_ROOT, "Spawn horde");

	RegConsoleCmd("sm_restarts", CommandPrintRestarts, "Show number of restarts in chat");
	RegConsoleCmd("sm_time", CommandPrintTime, "Show current date & time in chat");

	SetLengths();

	if (g_iCvarDebug) PrintToChatAll("%s OnPluginStart", DEBUG_TAG);
}

public void OnConfigsExecuted()
{
	if (g_iCvarDebug) PrintToChatAll("%s OnConfigsExecuted", DEBUG_TAG);

	EnablePlugin();
}

void CvarChanged_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (g_iCvarDebug) PrintToChatAll("%s CvarChanged_Enable", DEBUG_TAG);

	EnablePlugin();
}

void CvarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (g_iCvarDebug) PrintToChatAll("%s CvarChanged_Cvars", DEBUG_TAG);

	GetCvars();
}

void EnablePlugin()
{
	if (g_iCvarDebug) PrintToChatAll("%s EnablePlugin", DEBUG_TAG);

	bool isEnabled = g_hCvarEnable.BoolValue;
	GetCvars();

	if (g_bCvarEnable == false && isEnabled == true)
	{
		g_bCvarEnable = true;
		HookEvents();
	}
	else if (g_bCvarEnable == true && isEnabled == false) {
		g_bCvarEnable = false;
		UnhookEvents();
	}
}

void GetCvars()
{
	if (g_iCvarDebug) PrintToChatAll("%s GetCvars", DEBUG_TAG);

	g_iCvarDebug		  = g_hCvarDebug.IntValue;
	g_iCvarSurvivorIncap  = g_hCvarSurvivorIncap.IntValue;

	g_bCvarSurvivorDeath  = g_hCvarSurvivorDeath.BoolValue;
	g_bCvarWitchHarasser  = g_hCvarWitchHarasser.BoolValue;
	g_bCvarKillFeed		  = g_hCvarKillFeed.BoolValue;
	g_bCvarCarAlarm		  = g_hCvarCarAlarm.BoolValue;
	g_bCvarSilentInfected = g_hCvarSilentInfected.BoolValue;
	g_bCvarPrintRestarts  = g_hCvarPrintRestarts.BoolValue;
}

void HookEvents()
{
	if (g_iCvarDebug) PrintToChatAll("%s HookEvents", DEBUG_TAG);

	HookEvent(EVENT_PLAYER_DEATH, Event_PlayerDeath);
	HookEvent(EVENT_PLAYER_INCAP, Event_PlayerIncap);
	HookEvent(EVENT_LEDGE_GRAB, Event_PlayerIncap);
	HookEvent(EVENT_WITCH_HARASSER, Event_WitchHarasser);
	HookEvent(EVENT_PLAYER_DEATH, Event_Hide, EventHookMode_Pre);
	HookEvent(EVENT_PLAYER_INCAP, Event_Hide, EventHookMode_Pre);
	HookEvent(EVENT_HEAL_SUCCESS, Event_Hide, EventHookMode_Pre);
	HookEvent(EVENT_REVIVE_SUCCESS, Event_Hide, EventHookMode_Pre);
	HookEvent(EVENT_SURVIVOR_RESCUED, Event_Hide, EventHookMode_Pre);
	HookEvent(EVENT_AWARD_EARNED, Event_Hide, EventHookMode_Pre);
	HookEvent(EVENT_MISSION_LOST, Event_RoundEnd, EventHookMode_PostNoCopy);

	HookUserMessage(GetUserMessageId(EVENT_USER_MESSAGE), PZDmgMsg, true);
	HookEntityOutput(PROP_CAR_ALARM, EVENT_CAR_ALARM, Event_CarAlarm);
	AddNormalSoundHook(SoundHook);
}

void UnhookEvents()
{
	if (g_iCvarDebug) PrintToChatAll("%s UnhookEvents", DEBUG_TAG);

	UnhookEvent(EVENT_PLAYER_DEATH, Event_PlayerDeath);
	UnhookEvent(EVENT_PLAYER_INCAP, Event_PlayerIncap);
	UnhookEvent(EVENT_LEDGE_GRAB, Event_PlayerIncap);
	UnhookEvent(EVENT_WITCH_HARASSER, Event_WitchHarasser);
	UnhookEvent(EVENT_PLAYER_DEATH, Event_Hide, EventHookMode_Pre);
	UnhookEvent(EVENT_PLAYER_INCAP, Event_Hide, EventHookMode_Pre);
	UnhookEvent(EVENT_HEAL_SUCCESS, Event_Hide, EventHookMode_Pre);
	UnhookEvent(EVENT_REVIVE_SUCCESS, Event_Hide, EventHookMode_Pre);
	UnhookEvent(EVENT_SURVIVOR_RESCUED, Event_Hide, EventHookMode_Pre);
	UnhookEvent(EVENT_AWARD_EARNED, Event_Hide, EventHookMode_Pre);
	UnhookEvent(EVENT_MISSION_LOST, Event_RoundEnd, EventHookMode_PostNoCopy);

	UnhookUserMessage(GetUserMessageId(EVENT_USER_MESSAGE), PZDmgMsg, true);
	UnhookEntityOutput(PROP_CAR_ALARM, EVENT_CAR_ALARM, Event_CarAlarm);
	RemoveNormalSoundHook(SoundHook);
}

public void OnMapStart()
{
	g_iRestarts = 0;

	if (g_iCvarDebug) PrintToChatAll("%s OnMapStart \x04%d", DEBUG_TAG, g_iRestarts);
}

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (!g_bCvarSilentInfected) return Plugin_Continue;

	if (strncmp(sample, "player/", PLAYER_PATH_LENGTH, false) == 0)
		for (int i = 0; i < sizeof(g_sInfectedSounds); i++)
			if (strncmp(sample[PLAYER_PATH_LENGTH], g_sInfectedSounds[i][PLAYER_PATH_LENGTH], g_iInfectedSoundsLengths[i] - PLAYER_PATH_LENGTH, false) == 0)
			{
				if (g_iCvarDebug == DEBUG_SOUNDS) PrintToChatAll("%s %s", DEBUG_TAG, sample);

				volume = MUTE;

				return Plugin_Changed;
			}

	if (strncmp(sample, "npc/witch/voice/idle/", 21, false) == 0)
	{
		if (g_iCvarDebug == DEBUG_SOUNDS) PrintToChatAll("%s %s", DEBUG_TAG, sample);

		volume = MUTE;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

Action Event_Hide(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarKillFeed) return Plugin_Continue;

	if (g_iCvarDebug == DEBUG_EVENTS) PrintToChatAll("%s Event_Hide \x04%s \x05%s", DEBUG_TAG, GetName(GetEventClient(event)), name);

	event.BroadcastDisabled = true;

	return Plugin_Changed;
}

Action PZDmgMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (g_bCvarKillFeed) return Plugin_Handled;

	return Plugin_Continue;
}

Action CommandSetDebug(int client, int arguments)
{
	g_iCvarDebug = GetDebugMode(arguments);

	PrintToChatAll("%s CommandSetDebug \x04%d", DEBUG_TAG, g_iCvarDebug);

	return Plugin_Handled;
}

Action CommandSpawnRandomSI(int client, int arguments)
{
	SpawnRandomSI(client, GetSpawnCount(arguments));

	return Plugin_Handled;
}

Action CommandSpawnTank(int client, int arguments)
{
	SpawnTank(client, GetSpawnCount(arguments));

	return Plugin_Handled;
}

Action CommandSpawnMob(int client, int arguments)
{
	SpawnMob(client);

	return Plugin_Handled;
}

Action CommandPrintTime(int client, int arguments)
{
	char time[64];
	FormatTime(time, sizeof(time), "\x05%d\x01.\x05%m\x01.\x05%y \x04%B\x01, \x04%A \x03%H\x01:\x03%M\x01:\x03%S \x04%p", GetTime());
	PrintToChatAll(time);

	return Plugin_Handled;
}

Action CommandPrintRestarts(int client, int arguments)
{
	PrintRestarts();

	return Plugin_Handled;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iRestarts++;

	if (g_iCvarDebug) PrintToChatAll("%s Event_RoundEnd \x04%s \x05%d", DEBUG_TAG, name, g_iRestarts);

	if (g_bCvarPrintRestarts) PrintRestarts();
}

void Event_CarAlarm(const char[] output, int caller, int activator, float delay)
{
	if (!g_bCvarCarAlarm) return;

	if (!IsValidEntity(caller) || HasTank()) return;

	int client = GetAnyClient();

	if (!client) return;

	if (g_iCvarDebug) PrintToChatAll("%s Event_CarAlarm \x04%s \x05%s", DEBUG_TAG, GetName(client), output);

	SpawnTank(client);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarSurvivorDeath) return;

	int client = GetEventClient(event);

	if (!IsValidSurvivor(client)) return;

	if (g_iCvarDebug) PrintToChatAll("%s Event_PlayerDeath \x04%s \x05%s", DEBUG_TAG, GetName(client), name);

	SpawnMob(client);
}

void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_iCvarSurvivorIncap) return;

	int client = GetEventClient(event);

	if (!IsValidSurvivor(client)) return;

	if (g_iCvarDebug) PrintToChatAll("%s Event_PlayerIncap \x04%s \x05%s", DEBUG_TAG, GetName(client), name);

	SpawnRandomSI(client, g_iCvarSurvivorIncap);
}

void Event_WitchHarasser(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarWitchHarasser) return;

	int client = GetEventClient(event);

	if (!client) return;

	if (g_iCvarDebug) PrintToChatAll("%s Event_WitchHarasser \x04%s \x05%s", DEBUG_TAG, GetName(client), name);

	SpawnMob(client);
}

void SpawnRandomSI(int client, int count = DEFAULT_SPAWN_COUNT)
{
	for (int i = 0; i < count; i++)
	{
		if (g_iCvarDebug) PrintToChatAll("%s SpawnRandomSI \x04%s", DEBUG_TAG, GetName(client));

		int	 randomIndex = GetRandomInt(0, g_sInfectedClassesCount);
		char argument[64];
		Format(argument, sizeof(argument), "%s %s", g_sInfectedClasses[randomIndex], SPAWN_ARGUMENT_AUTO);
		ExecuteCheat(client, SPAWN_COMMAND_OLD, argument);
	}
}

void SpawnTank(int client, int count = DEFAULT_SPAWN_COUNT)
{
	for (int i = 0; i < count; i++)
	{
		if (g_iCvarDebug) PrintToChatAll("%s SpawnTank \x04%s", DEBUG_TAG, GetName(client));

		char argument[64];
		Format(argument, sizeof(argument), "tank %s", SPAWN_ARGUMENT_AUTO);
		ExecuteCheat(client, SPAWN_COMMAND_OLD, argument);
	}
}

void SpawnMob(int client)
{
	if (g_iCvarDebug) PrintToChatAll("%s SpawnMob \x04%s", DEBUG_TAG, GetName(client));

	ExecuteCheat(client, "z_spawn", "mob");
}

void ExecuteCheat(int client, const char[] command, const char[] argument)
{
	if (!client) return;

	if (g_iCvarDebug) PrintToChatAll("%s ExecuteCheat \x04%s \x05%s \x03%s", DEBUG_TAG, GetName(client), command, argument);

	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, argument);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}

void PrintRestarts()
{
	PrintToChatAll("\x01%t: \x04%d", "Restarts", g_iRestarts);
}

int GetDebugMode(int arguments)
{
	if (arguments == FIRST_ARGUMENT)
	{
		int mode = GetArgument();

		if (mode != g_iCvarDebug && mode >= DISABLE && mode <= DEBUG_SOUNDS) return mode;
	}

	return g_iCvarDebug ? DISABLE : ENABLE;
}

int GetSpawnCount(int arguments)
{
	if (arguments == FIRST_ARGUMENT)
	{
		int count = GetArgument();

		if (count > DEFAULT_SPAWN_COUNT && count <= MAX_SI) return count;
	}

	return DEFAULT_SPAWN_COUNT;
}

int GetEventClient(Event event)
{
	return GetClientOfUserId(event.GetInt("userid"));
}

int GetAnyClient()
{
	for (int client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client)) return client;

	return CLIENT_NOT_FOUND;
}

char[] GetName(int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	return name;
}

bool IsValidSurvivor(int client)
{
	return IsValidEntity(client) && IsClient(client) && IsSurvivor(client);
}

bool IsClient(int client)
{
	return client > CLIENT_NOT_FOUND && client <= MaxClients;
}

bool IsSurvivor(int client)
{
	return GetClientTeam(client) == TEAM_SURVIVORS;
}

bool IsInfected(int client)
{
	return GetClientTeam(client) == TEAM_INFECTED;
}

bool HasTank()
{
	return GetTankCount() > 0;
}

int GetTankCount()
{
	int tankCount;

	for (int client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client) && IsPlayerAlive(client) && IsInfected(client))
			if (GetEntProp(client, Prop_Send, "m_zombieClass") == TANK_CLASS) tankCount++;

	return tankCount;
}

void SetLengths()
{
	for (int i = 0; i < sizeof(g_sInfectedSounds); i++)
		g_iInfectedSoundsLengths[i] = strlen(g_sInfectedSounds[i]);
}

int GetArgument()
{
	char argument[MAX_INT_STRING_LENGTH];
	GetCmdArg(FIRST_ARGUMENT, argument, sizeof(argument));

	return StringToInt(argument);
}