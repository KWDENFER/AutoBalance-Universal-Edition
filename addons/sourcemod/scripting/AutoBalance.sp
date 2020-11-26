/*
* AutoBalance Universal Edition
* by: DENFER © 2020
*
* https://github.com/KWDENFER/AutoBalanceUE
* https://vk.com/denferez
* https://steamcommunity.com/id/denferez
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License, version 3.0, as published by the
* Free Software Foundation.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
* details.
*
* You should have received a copy of the GNU General Public License along with
* this program. If not, see <http://www.gnu.org/licenses/>.
*/

// Main Includes 
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <adminmenu>

// Сustom Includes
#include <colorvariables>
#include <autoexecconfig>

// Defines
#define AUTOBALANCE_VERSION "1.0.0"
#define AUTHOR 	"DENFER"
#define FILTERS 8	 // общее число фильтров, которые использует плагин 	
#define EASY 	0
#define MEDIUM 	1
#define HARD 	2		

// Defines Admin Menu Buttons  
#define ADMIN_MENU 				1	// разрешить ли в основной админ-панели SourceMod вкладку с админ-меню AutoBalance
#define ADMIN_FILTERS 			1	// управление фильтрами
#define ADMIN_BALANCE 			1	// баланс команд
#define ADMIN_SWAP 	  			1	// перенос игроков из одной команды в другую
#define ADMIN_RESTART_ROUND 	1	// рестарт раунда
#define ADMIN_RESTART_MATCH		1	// рестарт матча
#define ADMIN_RESPAWN			1	// возродить игроков
#define ADMIN_QUEUE				1	// управление очередями
#define ADMIN_IMMUNITY			1	// выдача иммунитета
#define ADMIN_BAN				1	// блокировка команд

// pragma 
#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0 

// Handles
Handle g_hSpectatorsTimer[MAXPLAYERS+1];
Handle g_hTimer;

#if ADMIN_MENU == 1
TopMenu g_hTopMenu = null;
#endif

ArrayList g_hQueueCt;
ArrayList g_hQueueT;

// Console Variables
ConVar gc_sCustomCommandsAdminTeamBalance;
ConVar gc_sCustomCommandsAdminSwapTeam;
ConVar gc_bOnTakeDamageSwappedPlayers;
ConVar gc_sCustomCommandsVoteBalance;
ConVar gc_iSwapFilterFactorHeadshot;
ConVar gc_sCustomCommandsAdminMenu;
ConVar gc_iCheckIntervalRoundStart;
ConVar gc_sCustomCommandsQueueCt;
ConVar gc_sCustomCommandsRequest;
ConVar gc_sCustomCommandsQueueT;
ConVar gc_bAdminQueueManagement;
ConVar gc_iAutoBalanceSettings;
ConVar gc_flPercentPlayersVote;
ConVar gc_bAdminBanJoiningTeam;
ConVar gc_iPreciseAutoBalanceCt;	
ConVar gc_iPreciseAutoBalanceT;
ConVar gc_iSwapFilterTimeTeam;
ConVar gc_iAutoBalanceOptions;
ConVar gc_sCustomCommandsMenu;
ConVar gc_bAdminRespwanPlayer;
ConVar gc_bAdminBalanceCheck;
ConVar gc_bAdminRestartRound;
ConVar gc_bAdminRestartMatch;
ConVar gc_bTeamChangeRequest;
ConVar gc_iPreciseAutoBalnce;
ConVar gc_bPersonalImmunity;
ConVar gc_iAutoBalanceLevel;
ConVar gc_bAdminBalanceTeam;
ConVar gc_bAdminSwapPlayers;
ConVar gc_flCheckSpectators;
ConVar gc_iAutoBalanceMode;
ConVar gc_bSwapAlivePlayer;
ConVar gc_iMinValuePlayers;
ConVar gc_iSwapFilterMoney;
ConVar gc_iSwapFilterAdmin;
ConVar gc_flCheckInterval; 
ConVar gc_iSwapFilterTime;
ConVar gc_bPluginMessages;
ConVar gc_iSwapFilterPing;
ConVar gc_iAutoConnected;
ConVar gc_iSwapFilterMVP;
ConVar gc_bSpectatorMode;
ConVar gc_iSwapFilterKD;
ConVar gc_bBalanceVote;
ConVar gc_bSwapFilters;
ConVar gc_sPrefix;
ConVar gc_iQueue;
ConVar gc_iRatio;

// Strings
char g_sPrefix[64];

// Floats
float g_flTimeTeam[MAXPLAYERS+1];

// Integers
int g_iSaveCollisionGroup[MAXPLAYERS+1];
int g_iSaveNewPlayerTeam[MAXPLAYERS+1];
int g_iSwapTeamBuffer[MAXPLAYERS+1];
int g_iAdminQueueFlag[MAXPLAYERS+1];
int g_iPlayerBuffer[MAXPLAYERS+1];
int g_iTeamBuffer[MAXPLAYERS+1];
int g_iTarget[MAXPLAYERS+1];
int g_iVoteTeamSwapCounter;
int g_iBalanceFlag;
int g_iBalanceMode; // 0 - равномерно, 1 - неравномерно
int g_iTimerID;
int g_iTime;

// Booleans 
bool g_bSwapTeamPair[MAXPLAYERS+1][MAXPLAYERS+1];
bool g_bSwapTeamFlag[MAXPLAYERS+1][MAXPLAYERS+1];
bool g_bVoteTeamSwap[MAXPLAYERS+1] = {true, ...};
bool g_bSpectator[MAXPLAYERS+1] = {true, ...};
bool g_bQueueCt[MAXPLAYERS+1] = {true, ...};
bool g_bQueueT[MAXPLAYERS+1] = {true, ...};
bool g_bPersonalImmunity[MAXPLAYERS+1];
bool g_bBalanceSwapped[MAXPLAYERS+1];
bool g_bRequestTimes[MAXPLAYERS+1];
bool g_bSelectPlayer[MAXPLAYERS+1];
bool g_bSwapBuffer[MAXPLAYERS+1];
bool g_bImmunity[MAXPLAYERS+1];
bool g_bSwapped[MAXPLAYERS+1];
bool g_bQueue[MAXPLAYERS+1];
bool g_bBanCt[MAXPLAYERS+1];
bool g_bBanT[MAXPLAYERS+1];
bool g_bSpecialEvent;
bool g_bSwapFilters;
bool g_bRoundEnd;
bool g_bTimer;
bool g_bWhen;

// Informations
public Plugin myinfo = {
	name = "AutoBalance",
	author = "DENFER (for all questions - https://vk.com/denferez)",
	description = "Custom balances players in teams",
	version = AUTOBALANCE_VERSION,
};

public void OnPluginStart()
{	
	// Translation 
	LoadTranslations("AutoBalance.phrases");
	
	#if ADMIN_MENU == 1
	if (LibraryExists("adminmenu"))
	{
		TopMenu hTopMenu;
			
		if((hTopMenu = GetAdminTopMenu()) != null) 
		{
			OnAdminMenuReady(hTopMenu);
		}
	}
	#endif
	
	// AutoExecConfig
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("AutoBalance", AUTHOR);
	
	// Commands Listener
	AddCommandListener(Listener_SwitchTeamBlock, "jointeam");
	
	// ConVars
	gc_bPluginMessages = AutoExecConfig_CreateConVar("sm_ab_plugin_messages", "1", "Включить сообщения плагина? (0 - выкл, 1 - вкл)", 0, true, 0.0, true, 1.0);
	gc_sPrefix = AutoExecConfig_CreateConVar("sm_ab_prefix", "[{green}SM{default}]", "Префикс перед сообщениями плагина");
	gc_iAutoBalanceMode = AutoExecConfig_CreateConVar("sm_ab_mode", "1", "0 - отменяет баланс в игре, 1 - балансировать КТ относительно Т, 2 - балансировать Т относительно КТ", 0, true, 0.0, true, 2.0);
	gc_iAutoBalanceLevel = AutoExecConfig_CreateConVar("sm_ab_level", "1", "0 - обычный уровень балансирования команд (easy), 1 - средний уровень балансировани команд (medium), 2 - сложный уровень балансирования команд (hard)", 0, true, 0.0, true, 2.0);
	gc_iRatio = AutoExecConfig_CreateConVar("sm_ab_ratio", "2", "Сколько игроков приходится на одного игрока? (смотря относительно какой команды вы будете балансировать, если КТ, то на 1 КТ - N Т и наоборот, там где N - ваше число)", 0, true, 0.0, false);
	gc_iPreciseAutoBalnce = AutoExecConfig_CreateConVar("sm_ab_precise", "0", "Разрешить балансировать до определенного соотношения игроков? (0 - запретить, 1 - разрешить)\nАвто-баланс будет балансировать команды так, чтобы образовалась соответсвующее соотношение игроков из одной комнады к другой, игроки которые будут переваливать через допустимый предел пропорции - отправляются в наблюдатели (N / N, там где N - значение переменной)(Тем самым вы можете настроить баланс для 2x2, 5x5, 10x10 игроков)(Работает исключительно при gc_iRatio = 0)", 0, true, 0.0, true, 1.0);
	gc_iPreciseAutoBalanceT = AutoExecConfig_CreateConVar("sm_ab_precise_t", "5", "Максимальное число игроков в команде Т? (Если количество игроков в данной команде будет превышать данное значение - игроки будут перенесены в наблюдатели) (работает исключительно при gc_iPreciseAutoBalnce = 1)", 0, true, 1.0, false);
	gc_iPreciseAutoBalanceCt= AutoExecConfig_CreateConVar("sm_ab_precise_ct", "5", "Максимальное число игроков в команде КТ? (Если количество игроков в данной команде будет превышать данное значение - игроки будут перенесены в наблюдатели) (работает исключительно при gc_iPreciseAutoBalnce = 1)", 0, true, 1.0, false);
	gc_iAutoBalanceSettings = AutoExecConfig_CreateConVar("sm_ab_settings", "3", "0 - постоянно балансировать в течение всей игры, 1 - балансировать в начале раунда, 2 - балансировать в конце раунда, 3 - балансировать в начале и в конце раунда, 4 - балансировать во время \"специальных\" событий, 5 - администартор сам выбирает, когда требуется включить и отключить авто-баланс", 0, true, 0.0, true, 5.0);
	gc_flCheckInterval = AutoExecConfig_CreateConVar("sm_ab_interval", "0.5", "Промежуток времени, через который будет осуществляться проверка баланса", 0, true, 0.1, false);
	gc_iCheckIntervalRoundStart = AutoExecConfig_CreateConVar("sm_ab_interval_rs", "5", "В течение скольки секунд после начала раунда балансирвоать команды? (учтите, что не стоит устанавливать слишком большое значение)", 0, true, 1.0, false);
	gc_iAutoBalanceOptions  = AutoExecConfig_CreateConVar("sm_ab_options", "0", "Запретить переносить игроков из команды? (0 - выключает данную опцию, 1 - запретить перемещать игроков из команды КТ, 2 - запретить перемещать игроков из команды Т)", 0, true, 0.0, true, 2.0);
	gc_bSwapAlivePlayer = AutoExecConfig_CreateConVar("sm_ab_swap_alive", "1", "Разрешить переносить живых игроков во время баланса команд? (игрок автоматически сменит команду и перенесется на спавн новой команды)(0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bOnTakeDamageSwappedPlayers = AutoExecConfig_CreateConVar("sm_ab_on_take_damage", "1", "Разрешить перемещенным игрокам в конце раунда наносить/принимать урон? (0 - разрешить, 1 - запретить)", 0, true, 0.0, true, 1.0);
	gc_iAutoConnected = AutoExecConfig_CreateConVar("sm_ab_auto_connected", "0", "После подключение игрока на сервер, автоматически присоединять его к команде (0 - оставить игрока в наблюдателях, 1 - присоединять к команде, которую выберет авто-баланс)", 0, true, 0.0, true, 1.0);
	gc_bSpectatorMode = AutoExecConfig_CreateConVar("sm_ab_spectator_mode", "0", "Разрешить игрокам находится в команде зрителей? (0 - разрешить, 1 - запретить (через N(настраивается ниже) секунд игрок будет автоматически перемещен за команду по правилам баланса))", 0, true, 0.0, true, 1.0);
	gc_flCheckSpectators = AutoExecConfig_CreateConVar("sm_ab_check_spectator", "5", "Время, через которое игрок будет перемещен с команды зрителей (указывать в секундах)", 0, true, 1.0, false);
	gc_bTeamChangeRequest = AutoExecConfig_CreateConVar("sm_ab_request", "1", "Разрешить игрокам меняться командами с определенными игроками (в противоположной команде)? (определенный игрок за Т, может предложить игроку за КТ поменяться командами) (0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bBalanceVote = AutoExecConfig_CreateConVar("sm_ab_balance_vote", "0", "Разрешить игрокам голосовать за баланс команд во время игры (игроки сами могут выбрать время, когда нужно сбалансировать команды)(0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_flPercentPlayersVote = AutoExecConfig_CreateConVar("sm_ab_percent_vote", "0.8", "Какой процент игроков должен проголосовать, чтобы начать баланс команд? (работает при sm_ab_percent_vote = 1) (указывать ввиде десятичной дроби, то есть 100 (процентов) = 1.0, 90 (процентов) = 0.9 и тд)", 0, true, 0.0, true, 1.0);
	gc_iMinValuePlayers = AutoExecConfig_CreateConVar("sm_ab_min_players", "5", "Минимальное число игроков на сервере (учитываются только КТ и Т), чтобы разрешить голосование?", 0, true, 0.0, false);
	gc_bPersonalImmunity = AutoExecConfig_CreateConVar("sm_ab_immunity", "1", "Разрешить администратору выдавать игрокам специальный иммунитет от баланса? (иммунитет будет спасать игрока от автоматического баланса и любых других перемещений не вопреки воле игрока)(0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bAdminBanJoiningTeam = AutoExecConfig_CreateConVar("sm_ab_admin_ban_team", "1", "Разрешить администратору запрещать игроку вступать в определенную команду? (баланс не будет переносить данного игрока) (0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bAdminBalanceTeam = AutoExecConfig_CreateConVar("sm_ab_admin_balance", "1", "Разрешить администратору балансировать команды специальными фильтрами? (0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bAdminSwapPlayers = AutoExecConfig_CreateConVar("sm_ab_admin_swap", "1", "Разрешить администратору переносить игроков из одной команды в другую? (0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bAdminBalanceCheck = AutoExecConfig_CreateConVar("sm_ab_admin_check", "1", "Включить защиту от нарушения баланса во время перемещения игроков при помощи админ-возможностей? (0 - выключить, 1 - включить)", 0, true, 0.0, true, 1.0);
	gc_bAdminRestartRound = AutoExecConfig_CreateConVar("sm_ab_admin_restart_round", "1", "Разрешить администратору делать рестарт текущего раунда с последующим балансом команд? (0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bAdminRestartMatch = AutoExecConfig_CreateConVar("sm_ab_admin_restart_match", "1", "Разрешить администратору делать рестарт игры с последующим балансом команд? (0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_bAdminRespwanPlayer = AutoExecConfig_CreateConVar("sm_ab_admin_respwan_player", "1", "Разрешить администратору возрождать игроков? (0 - запретить, 1 - разрешить)", 0, true, 0.0, true, 1.0);
	gc_iQueue = AutoExecConfig_CreateConVar("sm_ab_queue", "3", "Разрешить очередь за определенную команду? (если баланс не позволяет зайти игроку за команду он может занять свое  место в очереди) (0 - запретить очереди, 1 - разрешить очередь только в команду КТ, 2 - разрешить очередь только в команду Т, 3 - разрешить очереди в обе команды)", 0, true, 0.0, true, 3.0);
	gc_bAdminQueueManagement = AutoExecConfig_CreateConVar("sm_ab_admin_queue_management", "1", "Разрешает администратору управлять очередями (перемещать, удалять и менять местами игроков в очередях) (0 - запретить, 1 - разрешить))", 0, true, 0.0, true, 1.0);
	gc_bSwapFilters = AutoExecConfig_CreateConVar("sm_ab_swap_filters", "1", "Разрешить фильтры балансирования команд (при помощи фильтров авто-баланс выбирает игроков, которых нужно переместить впервую очередь) (0 - выкл. филтры, 1 - вкл. фильтры)", 0, true, 0.0, true, 1.0);
	gc_iSwapFilterKD = AutoExecConfig_CreateConVar("sm_ab_swap_filter_kd", "0", "Фильтр, отвечающий за перемещение игроков по KD (отношение убийств к смертям) (0 - выкл. фильтр, 1 - перемещать игрока с большим КД, 2 - перемещать игрока с меньшим КД)", 0, true, 0.0, true, 2.0);
	gc_iSwapFilterMVP = AutoExecConfig_CreateConVar("sm_ab_filter_MVP", "0", "Фильтр, отвечающий за перемещение игроков по MVP (ценности игрока в игре) (0 - выкл. фильтр, 1 - перемещать игрока с большим количеством MVP, 2 - перемещать игрока с меньшим количеством MVP)", 0, true, 0.0, true, 2.0);
	gc_iSwapFilterTime = AutoExecConfig_CreateConVar("sm_ab_swap_filter_time", "0", "Фильтр, отвечающий за перемещение игроков по времени нахождения на сервере (0 - выкл. фильтр, 1 - перемещать игрока, который дольше находятся на сервере, 2 - перемещать игрока, который меньше находятся на сервере)", 0, true, 0.0, true, 2.0);
	gc_iSwapFilterMoney = AutoExecConfig_CreateConVar("sm_ab_swap_filter_money", "0", "Фильтр, отвечающий за перемещение игроков в зависимости от количества денег (0 - выкл. фильтр, 1 - перемещать игрока с наибольшим количеством денег, 2 - перемещать игрока с наименьшим количеством денег)", 0, true, 0.0, true, 2.0);
	gc_iSwapFilterPing = AutoExecConfig_CreateConVar("sm_ab_swap_filter_ping", "0", "Фильтр, отвечающий за перемещение игроков в зависимости от пинга (задержки) на сервере (0 - выкл. фильтр, 1 - перемещать игрока с наибольшим пингом, 2 - перемещать игрока с наименьшим пингом)", 0, true, 0.0, true, 2.0);
	gc_iSwapFilterAdmin = AutoExecConfig_CreateConVar("sm_ab_swap_filter_admin", "0", "Фильтр, отвечающий за проверку игрока на администратора (0 - выкл. фильтр, 1 - перемещать администратора, 2 - в приоритете перемещать администратора, 3 - не перемещать администратора)", 0, true, 0.0, true, 3.0);
	gc_iSwapFilterFactorHeadshot = AutoExecConfig_CreateConVar("sm_ab_swap_filter_headshot", "0", "Фильтр, отвечает за проверку игроков на вероятность попадания в голову (0 - выкл. фильтр, 1 - перемещать игрока с наибольшей вероятностью попадания в голову, 2 - перемещать игрока с наименьшей вероятностью попадания в голову)", 0, true, 0.0, true, 2.0);
	gc_iSwapFilterTimeTeam = AutoExecConfig_CreateConVar("sm_ab_swap_time_team", "0", "Фильтр, отвечающий за перемещение игроков по времени нахождения в команде (0 - выкл. фильтр, 1 - перемещать игрока, который дольше находится в команде, 2 - перемещать игрока, который меньше находится в команде)", 0, true, 0.0, true, 2.0);
	gc_sCustomCommandsMenu = AutoExecConfig_CreateConVar("sm_ab_cc_menu", "bm, balance, balancemenu", "Команды которые будут вызывать общее меню для игроков (указывайте строго через запятую!)");
	gc_sCustomCommandsAdminMenu = AutoExecConfig_CreateConVar("sm_ab_cc_admin_menu", "ab, autobalance", "Команды которые будут вызывать специальное админ баланс-меню (указывайте строго через запятую!)");
	gc_sCustomCommandsAdminTeamBalance = AutoExecConfig_CreateConVar("sm_ab_cc_admin_team_balance", "tb, teambalance", "Команды которые будут вызывать меню для балансирования команд по вашим правилам (указывайте строго через запятую!)");
	gc_sCustomCommandsAdminSwapTeam = AutoExecConfig_CreateConVar("sm_ab_cc_admin_swap_team", "st, swapteam", "Команды которые будут вызывать меню для перемещения игроков из разных команд (указывайте строго через запятую!)");
	gc_sCustomCommandsRequest = AutoExecConfig_CreateConVar("sm_ab_cc_request", "rq, request", "Команды которые будут вызывать меню, в котором игрок сможет предложить другому игроку, поменяться командами (указывайте строго через запятую!)");
	gc_sCustomCommandsVoteBalance = AutoExecConfig_CreateConVar("sm_ab_cc_vote_balance", "vb, votebalance, voteb", "Команды которые позволят игроку проголосовать за баланс на сервере (указывайте строго через запятую!)");
	gc_sCustomCommandsQueueCt = AutoExecConfig_CreateConVar("sm_ab_cc_queue_ct", "ct, q_ct", "Команды которые позволят игрокам встать в очередь КТ (указывайте строго через запятую!)");
	gc_sCustomCommandsQueueT = AutoExecConfig_CreateConVar("sm_ab_cc_queue_t", "t, q_t", "Команды которые позволят игрокам встать в очередь T (указывайте строго через запятую!)");
	
	// Hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_death", Event_PlayerDeath_Pre, EventHookMode_Pre);
	HookEvent("player_connect_full", Event_PlayerConnected);
	HookConVarChange(FindConVar("mp_limitteams"), SettingConVars);
	HookConVarChange(FindConVar("mp_autoteambalance"), SettingConVars);
	HookConVarChange(FindConVar("mp_autokick"), SettingConVars);
	
	// AutoExecConfig
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{	

	if(IsValidClient(victim) && IsValidClient(inflictor) && IsClientInGame(victim) && IsClientInGame(inflictor) && ((g_bSwapped[victim] && g_bSwapped[inflictor]) || (g_bSwapped[victim] && !g_bSwapped[inflictor]) || (!g_bSwapped[victim] && g_bSwapped[inflictor])))
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action Hook_StartTouch(int client, int other)
{
	if(g_bRoundEnd)
	{
		if(client == other)
		{	
			return Plugin_Stop;
		}
		if(client <= 0 || client > MaxClients)
		{
			return Plugin_Stop;
		}
		if(other <= 0 || other > MaxClients)
		{
			return Plugin_Stop;
		}
		
		if(IsPlayerAlive(client) && IsPlayerAlive(other))
		{
			SetEntProp(other, Prop_Data, "m_CollisionGroup", 17); // COLLISION_GROUP_PUSHAWAY
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 17); // COLLISION_GROUP_PUSHAWAY
		}
	}
	
	return Plugin_Changed;
}

public Action Hook_EndTouch(int client, int other)
{
	if(client == other)
	{	
		return Plugin_Stop;
	}
	if(client <= 0 || client > MaxClients)
	{
		return Plugin_Stop;
	}
	if(other <= 0 || other > MaxClients)
	{
		return Plugin_Stop;
	}
		
	if(IsPlayerAlive(client) && IsPlayerAlive(other))
	{
		SetEntProp(other, Prop_Data, "m_CollisionGroup", g_iSaveCollisionGroup[client]);
		SetEntProp(client, Prop_Data, "m_CollisionGroup", g_iSaveCollisionGroup[client]);
	}
	
	return Plugin_Changed;
}

public void OnGameFrame()
{
	if(gc_iQueue.BoolValue)
	{
		if(GameRules_GetProp("m_bWarmupPeriod"))
		{
			if(g_hQueueCt != null && g_hQueueCt.Length != 0 && CheckBalance(g_hQueueCt.Get(0), GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_CT))
			{
				MyChangeClientTeam(g_hQueueCt.Get(0), CS_TEAM_CT);
			}
			
			if(g_hQueueT != null && g_hQueueT.Length != 0 && CheckBalance(g_hQueueT.Get(0), GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_T))
			{
				MyChangeClientTeam(g_hQueueT.Get(0), CS_TEAM_T);
			}
		}
	}
}

#if ADMIN_MENU == 1
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hTopMenu = null;
	}
}
#endif

public void OnConfigsExecuted()
{	
	SetConVarInt(FindConVar("mp_limitteams"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("mp_autokick"), 0);
	gc_sPrefix.GetString(g_sPrefix, sizeof(g_sPrefix));
	
	// Timer
	if(!gc_iAutoBalanceSettings.IntValue)
		CreateTimer(gc_flCheckInterval.FloatValue, Timer_PlayerCounter, 0, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		
	SetCommands();
		
	// Global ArrayList 
	if(gc_iQueue.BoolValue)
	{
		g_hQueueCt = new ArrayList();
		g_hQueueT = new ArrayList();
	}
}

public void SettingConVars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) != StringToInt(oldValue))
	{
		SetConVarInt(convar, 0);
	}
}

public void OnClientDisconnect(int client)
{
	if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
	{
		g_bSwapped[client] = true;
		SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		SDKUnhook(client, SDKHook_StartTouch, Hook_StartTouch);
		SDKUnhook(client, SDKHook_EndTouch, Hook_EndTouch);
	}

	if(gc_bBalanceVote.BoolValue)
	{
		if(g_bVoteTeamSwap[client])
		{
			g_bVoteTeamSwap[client] = true;
			g_iVoteTeamSwapCounter > 0 ? g_iVoteTeamSwapCounter-- : g_iVoteTeamSwapCounter;
		}
		else
		{
			int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
			
			if(g_iVoteTeamSwapCounter >= RoundToCeil(clients * gc_flPercentPlayersVote.FloatValue))
			{
				g_iVoteTeamSwapCounter--;
			}
		}
	}
	
	if(gc_iQueue.BoolValue)
	{
		if(gc_iQueue.IntValue == 1 || gc_iQueue.IntValue == 3)
		{
			if(g_hQueueCt.FindValue(client) != -1)
			{
				g_hQueueCt.Erase(g_hQueueCt.FindValue(client));
				g_bQueue[client] = false;
			}
		}
		
		if(gc_iQueue.IntValue == 2 || gc_iQueue.IntValue == 3)
		{
			if(g_hQueueT.FindValue(client) != -1)
			{
				g_hQueueT.Erase(g_hQueueT.FindValue(client));
				g_bQueue[client] = false;
			}
		}
	}
}

///////////////////////////////////////////////////
// 												 //
//			 	    ADMIN MENU					 //
//												 //
///////////////////////////////////////////////////

#if ADMIN_MENU == 1
public void OnAdminMenuReady(Handle topmenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(topmenu);

    if (hTopMenu == g_hTopMenu)
    {
        return;
    }

    g_hTopMenu = hTopMenu;
	
	g_hTopMenu.AddCategory("ab_admin_category", Handler_MenuAdmin, "ab_admin", ADMFLAG_ROOT, "Админ баланс-меню");
	TopMenuObject hCategory = g_hTopMenu.FindCategory("ab_admin_category");
	
	if(hCategory != INVALID_TOPMENUOBJECT)
	{
		char buffer[64];
		
		if(GetButton(ADMIN_FILTERS)) // меню фильтров 
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Filters_Menu");
			g_hTopMenu.AddItem("ab_item_1", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);
		}
		
		if(GetButton(ADMIN_BALANCE)) // балансирует игроков в команде 
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Team_Balance_Menu");
			g_hTopMenu.AddItem("ab_item_2", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);
		}
		
		if(GetButton(ADMIN_SWAP)) // переместить игроков из одной команды в другую 
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Swap_Menu");
			g_hTopMenu.AddItem("ab_item_3", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);
		}
		
		if(GetButton(ADMIN_RESTART_ROUND)) // рестарт текущего раунда
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Restart_Round");
			g_hTopMenu.AddItem("ab_item_4", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);
		}
		
		if(GetButton(ADMIN_RESTART_MATCH)) // рестарт матча
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Restart_Match");
			g_hTopMenu.AddItem("ab_item_5", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);
		}
		
		if(GetButton(ADMIN_RESPAWN)) // возродить игрока
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Respwan_Player");
			g_hTopMenu.AddItem("ab_item_6", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);
		}
		
		if(GetButton(ADMIN_QUEUE)) // управление очередями 
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Queue_Management");
			g_hTopMenu.AddItem("ab_item_7", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);
		}
		
		if(GetButton(ADMIN_IMMUNITY)) // выдать иммунитет игроку 
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Immunity_Menu");
			g_hTopMenu.AddItem("ab_item_8", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);	
		}
		
		if(GetButton(ADMIN_BAN)) // блокировка команд игрокам
		{
			FormatEx(buffer, sizeof(buffer), "%t", "Title_Ban_Management_Menu");
			g_hTopMenu.AddItem("ab_item_9", Handler_MenuAdminItem, hCategory, "ab_item", ADMFLAG_ROOT, buffer);	
		}
	}
}

public void Handler_MenuAdmin(TopMenu menu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int length)
{	
    switch(action)
    {
		case TopMenuAction_DisplayOption:
        {
            FormatEx(buffer, length, "%t", "Title_Admin_Menu");
        }
		case TopMenuAction_DisplayTitle:
        {
            FormatEx(buffer, length, "%t", "Title_Admin_Menu");
        }
    }
}

public void Handler_MenuAdminItem(TopMenu menu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int length)
{
    switch(action)
    {
		case TopMenuAction_DisplayOption:
        {
			char info[16];
			menu.GetObjName(object_id, info, sizeof(info));
			
			if(StrEqual(info, "ab_item_1"))
			{
				FormatEx(buffer, length, "%t", "Title_Filters_Menu");
			}
			else if(StrEqual(info, "ab_item_2"))
			{
				FormatEx(buffer, length, "%t", "Team_Balance_Menu");
			}
			else if(StrEqual(info, "ab_item_3"))
			{
				FormatEx(buffer, length, "%t", "Title_Swap_Menu");
			}
			else if(StrEqual(info, "ab_item_4"))
			{
				FormatEx(buffer, length, "%t", "Title_Restart_Round");
			}
			else if(StrEqual(info, "ab_item_5"))
			{
				FormatEx(buffer, length, "%t", "Title_Restart_Match");
			}
			else if(StrEqual(info, "ab_item_6"))
			{
				FormatEx(buffer, length, "%t", "Title_Respwan_Player");
			}
			else if(StrEqual(info, "ab_item_7"))
			{
				FormatEx(buffer, length, "%t", "Title_Queue_Management");
			}
			else if(StrEqual(info, "ab_item_8"))
			{
				FormatEx(buffer, length, "%t", "Title_Immunity_Menu");
			}
			else if(StrEqual(info, "ab_item_9"))
			{
				FormatEx(buffer, length, "%t", "Title_Ban_Management_Menu");
			}
        }
		case TopMenuAction_SelectOption:
        {
            char info[16];
			menu.GetObjName(object_id, info, sizeof(info));
			
			if(StrEqual(info, "ab_item_1"))
			{
				Menu_Filters(client, 0);
			}
			else if(StrEqual(info, "ab_item_2"))
			{
				Menu_BalanceTeam(client, 0);
			}
			else if(StrEqual(info, "ab_item_3"))
			{
				Menu_SwapPlayers(client, 0);
			}
			else if(StrEqual(info, "ab_item_4"))
			{
				RestartRound(client);
			}
			else if(StrEqual(info, "ab_item_5"))
			{
				RestartMatch(client);
			}
			else if(StrEqual(info, "ab_item_6"))
			{
				Menu_RespwanPlayer(client, 0);
			}
			else if(StrEqual(info, "ab_item_7"))
			{
				Menu_QueueManagement(client, 0);
			}
			else if(StrEqual(info, "ab_item_8"))
			{
				Menu_SelectPlayerImmunity(client);
			}
			else if(StrEqual(info, "ab_item_9"))
			{
				Menu_BanManagement(client);
			}
        }
    }
}
#endif

///////////////////////////////////////////////////
// 												 //
//			 	    LISTENER					 //
//												 //
///////////////////////////////////////////////////

public Action Listener_SwitchTeamBlock(int client, const char[] command, int argc) // args: 0 - name , 1 - target team, 2 - index player
{		
	if(client && IsClientInGame(client))
	{
		int Ts = GetTeamClientCount(CS_TEAM_T); 
		int Cts = GetTeamClientCount(CS_TEAM_CT); 
		int team = GetCmdArgInt(1);
		
		if(team == CS_TEAM_SPECTATOR)
		{
			return Plugin_Continue;
		}
		
		if(IsPlayerBannedTeam(client, team))
		{
			if(gc_bPluginMessages.BoolValue) 
			{
				if(team == CS_TEAM_CT)
					CPrintToChat(client, "%s %t", g_sPrefix, "Team_Banned", "CT");
				else
					CPrintToChat(client, "%s %t", g_sPrefix, "Team_Banned", "T");
			}
			
			return Plugin_Handled;
		}
		
		if(gc_iQueue.BoolValue)
		{
			if(gc_iQueue.IntValue == 1 || gc_iQueue.IntValue == 3)
			{
				if(team == CS_TEAM_CT)
				{
					if(g_hQueueCt.Length != 0)
					{
						if(g_hQueueCt.FindValue(client) == -1)
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Queue_Of_N_People", g_hQueueCt.Length);
							return Plugin_Handled;
						}
						else
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_In_Queue", g_hQueueCt.FindValue(client) + 1);
							return Plugin_Handled;
						}
					}
				}
			}
			
			if(gc_iQueue.IntValue == 2 || gc_iQueue.IntValue == 3)
			{
				if(team == CS_TEAM_T)
				{
					if(g_hQueueT.Length != 0)
					{
						if(g_hQueueT.FindValue(client) == -1)
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Queue_Of_N_People", g_hQueueT.Length);
							return Plugin_Handled;
						}
						else
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_In_Queue", g_hQueueT.FindValue(client) + 1);
							return Plugin_Handled;
						}
					}
				}
			}
		}
		
		if(gc_iAutoBalanceMode.BoolValue && !CheckBalance(client, Ts, Cts, team))
		{
			if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Doesnt_Allow_Balance");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

///////////////////////////////////////////////////
// 												 //
//			 	      EVENTS					 //
//												 //
///////////////////////////////////////////////////

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{	
	g_bRoundEnd = false;
	
	if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
			{
				g_bSwapped[i] = true;
				SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
				SDKUnhook(i, SDKHook_StartTouch, Hook_StartTouch);
				SDKUnhook(i, SDKHook_EndTouch, Hook_EndTouch);
			}
		}
	}
	
	if(gc_iAutoBalanceLevel.IntValue > 1 && gc_iAutoBalanceSettings.BoolValue) // снимаем иммунитеты, если они есть
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && g_bImmunity[i])
			{
				SetImmunity(i, false);
			}
		}
	}
	
	if(gc_iQueue.BoolValue)
	{
		// флаги выхода из цикла, если баланс невозможен в обоих командах
		bool flag1 = true; 
		bool flag2 = true; 
		
		while((g_hQueueCt.Length != 0 || g_hQueueT.Length != 0) && (flag1 || flag2))
		{
			if(gc_iAutoBalanceMode.BoolValue && g_hQueueCt.Length != 0 && CheckBalance(g_hQueueCt.Get(0), GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_CT))
			{
				if(IsPlayerAlive(g_hQueueCt.Get(0)))
				{
					SafeSlapPlayer(g_hQueueCt.Get(0));
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueCt.Get(0), "%s %t", g_sPrefix, "Place_In_The_Team"); // отработает событие player_death
					MyChangeClientTeam(g_hQueueCt.Get(0), CS_TEAM_CT);
				}
			}
			else
			{
				flag1 = false;
			}
			
			if(g_hQueueT.Length != 0)
			{
				if(gc_iAutoBalanceMode.BoolValue && g_hQueueT.Length != 0 && CheckBalance(g_hQueueT.Get(0), GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_T))
				{
					if(IsPlayerAlive(g_hQueueT.Get(0)))
					{
						SafeSlapPlayer(g_hQueueT.Get(0));
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueT.Get(0), "%s %t", g_sPrefix, "Place_In_The_Team");
						MyChangeClientTeam(g_hQueueT.Get(0), CS_TEAM_T);
					}
				}
				else
				{
					flag2 = false;
				}	
			}
			else
			{
				flag2 = false;
			}
		}
	}
	
	if(gc_bAdminBanJoiningTeam.BoolValue)
	{
		for(int i = 1;i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && IsPlayerBannedTeam(i, GetClientTeam(i)))
			{
				if(CheckBalance(i, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), OppositeTeam(GetClientTeam(i))))
				{
					MyChangeClientTeam(i, OppositeTeam(GetClientTeam(i)));
					if(gc_bPluginMessages.BoolValue) 
					{
						if(OppositeTeam(GetClientTeam(i) == CS_TEAM_CT))
						{
							CPrintToChat(i, "%s %t", g_sPrefix, "Ban_Change_Team", "CT");
						}
						else
						{
							CPrintToChat(i, "%s %t", g_sPrefix, "Ban_Change_Team", "T");
						}
					}
				}
				else if(!gc_bSpectatorMode.BoolValue)
				{
					MyChangeClientTeam(i, CS_TEAM_SPECTATOR);
					if(gc_bPluginMessages.BoolValue) CPrintToChat(i, "%s %t", g_sPrefix, "Ban_Change_Team", "SPEC");
				}
				else
				{
					g_bSpectator[i] = false; // игрок может находится в спектаторах
					MyChangeClientTeam(i, CS_TEAM_SPECTATOR);
					if(gc_bPluginMessages.BoolValue) CPrintToChat(i, "%s %t", g_sPrefix, "Ban_Change_Team", "SPEC");
				}
			}
		}
	}
	
	if(gc_iAutoBalanceSettings.IntValue == 1 || gc_iAutoBalanceSettings.IntValue == 3 || gc_iAutoBalanceSettings.IntValue == 4)
	{
		if(gc_iAutoBalanceSettings.IntValue != 4 || (gc_iAutoBalanceSettings.IntValue == 4 && g_bSpecialEvent == true))
		{
			if(g_hTimer != null)
			{
				KillTimer(g_hTimer);
				g_hTimer = null;
			}
				
			g_iTimerID = 1;
			
			g_bSpecialEvent = false; // исключительно для gc_iAutoBalanceSettings.IntValue == 4
			g_iTime = gc_iCheckIntervalRoundStart.IntValue * 10;
			g_hTimer = CreateTimer(0.1, Timer_PlayerCounter, 1, TIMER_REPEAT);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	g_bRoundEnd = true;
	
	if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
	{
		for(int i = 1;i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
				g_iSaveCollisionGroup[i] = GetEntProp(i, Prop_Data, "m_CollisionGroup");
				SDKHook(i, SDKHook_StartTouch, Hook_StartTouch);
				SDKHook(i, SDKHook_EndTouch, Hook_EndTouch);
			}
		}
	}
	
	if(gc_iQueue.BoolValue)
	{
		// флаги выхода из цикла, если баланс невозможен в обоих командах
		bool flag1 = true; 
		bool flag2 = true; 
		
		while((g_hQueueCt.Length != 0 || g_hQueueT.Length != 0) && (flag1 || flag2))
		{
			if(gc_iAutoBalanceMode.BoolValue && g_hQueueCt.Length != 0 && CheckBalance(g_hQueueCt.Get(0), GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_CT))
			{
				if(IsPlayerAlive(g_hQueueCt.Get(0)))
				{ 
					if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueCt.Get(0), "%s %t", g_sPrefix, "Place_In_The_Team");
						g_bSwapped[g_hQueueCt.Get(0)] = true;
						MyChangeClientTeam(g_hQueueCt.Get(0), CS_TEAM_CT);
					}
					else
					{
						SafeSlapPlayer(g_hQueueCt.Get(0)); // отработает событие player_death
					}
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueCt.Get(0), "%s %t", g_sPrefix, "Place_In_The_Team");
					MyChangeClientTeam(g_hQueueCt.Get(0), CS_TEAM_CT); // вызовет событие player_team 
				}
			}
			else
			{
				flag1 = false;
			}
			
			if(g_hQueueT.Length != 0)
			{
				if(gc_iAutoBalanceMode.BoolValue && g_hQueueT.Length != 0 && CheckBalance(g_hQueueT.Get(0), GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_T))
				{
					if(IsPlayerAlive(g_hQueueT.Get(0)))
					{	
						if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueT.Get(0), "%s %t", g_sPrefix, "Place_In_The_Team");
							g_bSwapped[g_hQueueT.Get(0)] = true;
							MyChangeClientTeam(g_hQueueT.Get(0), CS_TEAM_T);
						}
						else
						{
							SafeSlapPlayer(g_hQueueT.Get(0));
						}
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueT.Get(0), "%s %t", g_sPrefix, "Place_In_The_Team");
						MyChangeClientTeam(g_hQueueT.Get(0), CS_TEAM_T);
					}
				}
				else
				{
					flag2 = false;
				}	
			}
			else
			{
				flag2 = false;
			}
		}
	}
	
	if(gc_bAdminBanJoiningTeam.BoolValue)
	{
		for(int i = 1;i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && IsPlayerBannedTeam(i, GetClientTeam(i)))
			{
				if(CheckBalance(i, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), OppositeTeam(GetClientTeam(i))))
				{
					MyChangeClientTeam(i, OppositeTeam(GetClientTeam(i)));
				}
				else if(!gc_bSpectatorMode.BoolValue)
				{
					MyChangeClientTeam(i, CS_TEAM_SPECTATOR);
				}
				else
				{
					g_bSpectator[i] = false; // игрок может находится в спектаторах
				}
			}
		}
	}
	
	if(gc_iAutoBalanceSettings.IntValue == 1 || gc_iAutoBalanceSettings.IntValue == 3 || gc_iAutoBalanceSettings.IntValue == 4)
	{
		if(gc_iAutoBalanceSettings.IntValue != 4 || (gc_iAutoBalanceSettings.IntValue == 4 && g_bSpecialEvent == true))
		{
			if(g_hTimer != null)
			{
				KillTimer(g_hTimer);
				g_hTimer = null;
			}
			
			g_iTimerID = 0;
			
			g_bSpecialEvent = false; // исключительно для gc_iAutoBalanceSettings.IntValue == 4
			g_iTime = 50;
			g_hTimer = CreateTimer(0.1, Timer_PlayerCounter, 0, TIMER_REPEAT);
		}
	}
	
	if(gc_bTeamChangeRequest.BoolValue)
	{
		for(int i = 1; i <= MaxClients; ++i) // i - client
		{
			if(IsClientInGame(i))
			{
				for(int j = 1; j <= MaxClients; ++j) // j - target
				{
					if(IsClientInGame(j))
					{
						if(g_bSwapTeamPair[i][j] && g_bSwapTeamPair[j][i])
						{			
							if(IsPlayerBannedTeam(i, GetClientTeam(j)))
							{
								if(gc_bPluginMessages.BoolValue) 
								{
									char player[MAX_NAME_LENGTH]; GetClientName(i, player, sizeof(player));
									CPrintToChat(j, "%s %t", g_sPrefix, "Team_Banned_You_Not_Change_1", player);
									GetClientName(j, player, sizeof(player));
									CPrintToChat(i, "%s %t", g_sPrefix, "Team_Banned_You_Not_Change_2", player);
								}
								
								continue;
							}
							
							if(IsPlayerBannedTeam(j, GetClientTeam(i)))
							{
								if(gc_bPluginMessages.BoolValue) 
								{
									char player[MAX_NAME_LENGTH]; GetClientName(j, player, sizeof(player));
									CPrintToChat(i, "%s %t", g_sPrefix, "Team_Banned_You_Not_Change_1", player);
									GetClientName(i, player, sizeof(player));
									CPrintToChat(j, "%s %t", g_sPrefix, "Team_Banned_You_Not_Change_2", player);
								}
								
								continue;
							}
							
							SwapTeamPlayers(i, j);
						}
					}
					else
					{
						if(g_bSwapTeamPair[i][j])
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(i, "%s %t", g_sPrefix, "Player_Left_Server");
							g_bSwapTeamPair[i][j] = false;
							g_bSwapTeamPair[j][i] = false;
							g_bSwapTeamFlag[i][j] = false;
							g_bSwapTeamFlag[j][i] =  false;
						}
					}
				}
			}
			else 
			{
				for(int j = 1; j <= MaxClients; ++j) // j - target
				{
					if(IsClientInGame(j))
					{
						if(g_bSwapTeamPair[i][j])
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(j, "%s %t", g_sPrefix, "Player_Left_Server");
							g_bSwapTeamPair[i][j] = false;
							g_bSwapTeamPair[j][i] = false;
							g_bSwapTeamFlag[i][j] = false;
							g_bSwapTeamFlag[j][i] =  false;
						}
					}
				}
			}
		}
	}
	
	if(gc_bAdminBalanceTeam.BoolValue && g_iBalanceFlag && g_bWhen)
	{
		switch(g_iBalanceFlag)
		{
			case 1:
			{
				BalancePlayersKD(g_iBalanceMode);
			}
			case 2:
			{
				BalancePlayersMVP(g_iBalanceMode);
			}
			case 3:
			{
				BalancePlayersTime(g_iBalanceMode);
			}
			case 4:
			{
				BalancePlayersTimeTeam(g_iBalanceMode);
			}
			case 5:
			{
				BalancePlayersMoney(g_iBalanceMode);
			}
			case 6:
			{
				BalancePlayersPing(g_iBalanceMode);
			}
			case 7:
			{
				BalancePlayersHeadshot(g_iBalanceMode);
			}
		}
		
		g_iBalanceFlag = 0;
		g_bWhen = false;
	}
	
	if(gc_bAdminSwapPlayers.BoolValue)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && g_bSwapBuffer[i])
			{
				if(gc_iAutoBalanceMode.BoolValue && gc_bAdminBalanceCheck.BoolValue && CheckBalance(i, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), g_iSaveNewPlayerTeam[i]) || g_iSaveNewPlayerTeam[i] == CS_TEAM_SPECTATOR)
				{
					if(IsPlayerAlive(i)) 
					{
						if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
						{
							g_bSwapped[i] = true;
						}
						else
						{
							SafeSlapPlayer(i);
						}
						
						MyChangeClientTeam(i, g_iSaveNewPlayerTeam[i]);
					}
					else
					{
						MyChangeClientTeam(i, g_iSaveNewPlayerTeam[i]);
					}
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(i, "%s %t", g_sPrefix, "Not_Been_Swap");
				}
				
				g_bSwapBuffer[i] = false;
			}
		}
	}
	
	if(gc_iAutoBalanceLevel.IntValue > 1 && gc_iAutoBalanceSettings.BoolValue) // снимаем иммунитеты, если они есть
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && g_bImmunity[i])
			{
				SetImmunity(i, false);
			}
		}
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	int oldteam = GetClientOfUserId(GetEventInt(event, "oldteam"));
	
	if(gc_bSpectatorMode.BoolValue)
	{
		if(oldteam == CS_TEAM_SPECTATOR && (team == CS_TEAM_CT || team == CS_TEAM_T) && !g_bSpectator[client])
		{
			g_bSpectator[client] = true;
		}
	}
	
	if(!IsFakeClient(client))
	{
		g_flTimeTeam[client] = GetClientTime(client);
	}
	
	if(gc_iQueue.BoolValue)
	{
		if(gc_iQueue.IntValue == 1 || gc_iQueue.IntValue == 3)
		{
			if(team == CS_TEAM_CT)
			{
				if(g_hQueueCt.FindValue(client) != -1)
				{
					g_hQueueCt.Erase(g_hQueueCt.FindValue(client));
					g_bQueue[client] = false;
				}
			}
		}
		
		if(gc_iQueue.IntValue == 2 || gc_iQueue.IntValue == 3)
		{
			if(team == CS_TEAM_T)
			{
				if(g_hQueueT.FindValue(client) != -1)
				{
					g_hQueueT.Erase(g_hQueueT.FindValue(client));
					g_bQueue[client] = false;
				}
			}
		}
	}
	
	if(gc_bBalanceVote.BoolValue)
	{
		if((oldteam == CS_TEAM_CT || oldteam == CS_TEAM_T) && team == CS_TEAM_SPECTATOR)
		{
			if(g_bVoteTeamSwap[client])
			{
				g_bVoteTeamSwap[client] = false;
				g_iVoteTeamSwapCounter > 0 ? g_iVoteTeamSwapCounter-- : g_iVoteTeamSwapCounter;
			}
		}
	}
	
	if(gc_bTeamChangeRequest.BoolValue)
	{	
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(g_bSwapTeamFlag[client][i] && g_bSwapTeamFlag[i][client])
			{
				g_bSwapTeamFlag[client][i] = false;
				g_bSwapTeamFlag[i][client] = false;
				char player[MAX_NAME_LENGTH];
				GetClientName(i, player, sizeof(player));
				
				if(gc_bPluginMessages.BoolValue) 
				{
					CPrintToChat(i, "%s %t", g_sPrefix, "Player_Changed_Team");
					CPrintToChat(client, "%s %t", g_sPrefix, "You_Changed_Team", player);
				}
			}
		}
	}

	if(gc_bSpectatorMode.BoolValue)
	{	
		if((team == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE) && g_bSpectator[client])
		{
			if(0 < client <= MaxClients && IsClientInGame(client))
			{
				if(g_hSpectatorsTimer[client] != null)
				{
					KillTimer(g_hSpectatorsTimer[client]);
					g_hSpectatorsTimer[client] = null;
				}
				g_hSpectatorsTimer[client] = CreateTimer(gc_flCheckSpectators.FloatValue, Timer_Spectators, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			if(g_hSpectatorsTimer[client] != null)
			{
				KillTimer(g_hSpectatorsTimer[client]);
				g_hSpectatorsTimer[client] = null;
			}
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(gc_iQueue.BoolValue)
	{
		if(g_hQueueCt.FindValue(client) == 0)
		{
			if(gc_iAutoBalanceMode.BoolValue && CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_CT))
			{
				MyChangeClientTeam(client, CS_TEAM_CT);
				if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Place_In_The_Team");
			}
		}
		else if(g_hQueueT.FindValue(client) == 0)
		{
			if(gc_iAutoBalanceMode.BoolValue && CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_T))
			{
				MyChangeClientTeam(client, CS_TEAM_T);
				if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Place_In_The_Team");
			}
		}
	}
}

public Action Event_PlayerDeath_Pre(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(g_bBalanceSwapped[victim] && attacker == victim)
	{
		g_bBalanceSwapped[victim] = false;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Event_PlayerConnected(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(0.5, Timer_AutoJoinTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE); // таймер исправляет баг, когда игрок автоматически подключается к спектаторам и не может выбрать команду
}

///////////////////////////////////////////////////
// 												 //
//			 	      MENU				 	     //
//												 //
///////////////////////////////////////////////////

public Action Menu_Balance(int client, int args)
{
	Menu menu = new Menu(HandlerMenu_Balance);
	char info[128];
	
	FormatEx(info, sizeof(info), "%T", "Title_Balance_Menu", client);
    menu.SetTitle(info);
	
	if(gc_bTeamChangeRequest.BoolValue)
	{
		FormatEx(info, sizeof(info), "%T", "Change_Request", client);
		menu.AddItem("request", info);
	}
	
	if((gc_iQueue.IntValue == 1 || gc_iQueue.IntValue == 3) && GetClientTeam(client) != CS_TEAM_CT && !g_bQueue[client])
	{
		FormatEx(info, sizeof(info), "%T", "Queue_Ct", client);
		menu.AddItem("queue_ct", info);
	}
	else if(g_bQueue[client] && g_hQueueCt.FindValue(client) != -1)
	{
		FormatEx(info, sizeof(info), "%T", "Quit_Ct", client);
		menu.AddItem("quit_ct", info);
	}
	
	if((gc_iQueue.IntValue == 2 || gc_iQueue.IntValue == 3) && GetClientTeam(client) != CS_TEAM_T && !g_bQueue[client])
	{
		FormatEx(info, sizeof(info), "%T", "Queue_T", client);
		menu.AddItem("queue_t", info);
	}
	else if(g_bQueue[client] && g_hQueueT.FindValue(client) != -1)
	{
		FormatEx(info, sizeof(info), "%T", "Quit_T", client);
		menu.AddItem("quit_t", info);
	}
	
	if(gc_bBalanceVote.BoolValue)
	{
		FormatEx(info, sizeof(info), "%T", "Vote_Balance", client);
		menu.AddItem("vote_balance", info);
	}
	
	menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int HandlerMenu_Balance(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "request"))
			{
				if(((GetClientTeam(param1) == CS_TEAM_SPECTATOR || GetClientTeam(param1) == CS_TEAM_NONE) && (GetTeamClientCount(CS_TEAM_CT) != 0 || GetTeamClientCount(CS_TEAM_T) != 0)) || ((GetClientTeam(param1) == CS_TEAM_CT || GetClientTeam(param1) == CS_TEAM_T) && (GetTeamClientCount(CS_TEAM_SPECTATOR) !=0 || (GetTeamClientCount(CS_TEAM_CT) != 0 && GetTeamClientCount(CS_TEAM_T) != 0))))
				{
					bool flag = true;
					char name[MAX_NAME_LENGTH];
					
					for(int i = 1; i <= MaxClients; ++i)
					{
						if(g_bSwapTeamFlag[param1][i] && g_bSwapTeamFlag[i][param1])
						{
							flag = false;
							GetClientName(i, name, sizeof(name));
						}
					}
					
					if(flag) // для устарнение двойной смены команды
					{
						if(!g_bRequestTimes[param1])
						{
							Menu_ChangeRequest(param1, 0);
						}
						else
						{
							if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Request_Has_Already");
						}
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Already_Accepted", name);
					}
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "No_Players");
				}
			}
			else if(StrEqual(info, "vote_balance"))
			{
				Vote_Balance(param1, 0);
			}
			else if(StrEqual(info, "queue_ct"))
			{
				TakeQueueCt(param1, 0);
				Menu_Balance(param1, 0);
			}
			else if(StrEqual(info, "quit_ct"))
			{
				GetOutOfQueueCt(param1);
				Menu_Balance(param1, 0);
			}
			else if(StrEqual(info, "queue_t"))
			{

				TakeQueueT(param1, 0);
				Menu_Balance(param1, 0);
			}
			else if(StrEqual(info, "quit_t"))
			{
				GetOutOfQueueT(param1);
				Menu_Balance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_ChangeRequest(int client, int argc)
{
	Menu menu = new Menu(HandlerMenu_ChangeRequest);
	char info[128];
	
	FormatEx(info, sizeof(info), "%T", "Title_Change_Request", client);
    menu.SetTitle(info);
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == OppositeTeam(GetClientTeam(client)) && i != client && !IsPlayerBannedTeam(i, GetClientTeam(client)))
		{
			char userid[16];
			char name[MAX_NAME_LENGTH];
			GetClientName(i, name, sizeof(name));
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			menu.AddItem(userid, name);
		}
		else if(IsClientInGame(i) && (GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE) && (GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T) && i != client)
		{
			char userid[16];
			char name[MAX_NAME_LENGTH];
			GetClientName(i, name, sizeof(name));
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			menu.AddItem(userid, name);
		}
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_ChangeRequest(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int target = GetClientOfUserId(StringToInt(info));
			
			if(target && !g_bRequestTimes[param1])
			{
				g_bRequestTimes[param1] = true;
				CreateTimer(15.0, Timer_Request, GetClientUserId(param1), TIMER_FLAG_NO_MAPCHANGE);
				char name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Sent_A_Request");
				Menu_Request(param1, target);
			}
			else if(target)
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Request_Has_Already");
			}
			else
			{
				CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_1");
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_Balance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_Request(int client, int target)
{
	if(gc_bTeamChangeRequest.BoolValue && !IsFakeClient(target))
	{
		Menu menu = new Menu(HandlerMenu_Request);
		char info[128];
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		g_iSwapTeamBuffer[target] = client;
		
		FormatEx(info, sizeof(info), "%T", "Title_Request_Menu", target, name);
		menu.SetTitle(info);
		
		FormatEx(info, sizeof(info), "%T", "Accept", target);
		menu.AddItem("accept", info);
		
		FormatEx(info, sizeof(info), "%T", "Refuse", target);
		menu.AddItem("refuse", info);
		
		menu.Display(target, 15);
	}
	else if(IsFakeClient(target))
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(target, name, sizeof(name));
		
		int botFlag = GetRandomInt(0,1);
		
		char name_target[MAX_NAME_LENGTH];
		
		GetClientName(target, name_target, sizeof(name_target));
		
		if(botFlag)
		{
			g_bSwapTeamPair[target][client] = true;
			g_bSwapTeamPair[client][target] = true;
				
			g_bSwapTeamFlag[target][client] = true;
			g_bSwapTeamFlag[client][target] = true;

			if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Accepted_Request", name);
		}
		else
		{
			g_bSwapTeamPair[target][client] = false;
				
			if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Dont_Accept_Your_Request", name);
		}
	}
	
	return Plugin_Handled;
}

public int HandlerMenu_Request(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			char name_client[MAX_NAME_LENGTH];
			char name_target[MAX_NAME_LENGTH];
				
			GetClientName(param1, name_client, sizeof(name_client));
			GetClientName(g_iSwapTeamBuffer[param1], name_target, sizeof(name_target));
			
			if(StrEqual(info, "accept"))
			{
				g_bSwapTeamPair[param1][g_iSwapTeamBuffer[param1]] = true; // g_iSwapTeamBuffer - хранит индекс клиента, который отправил запрос, при этом индекс ячейки массива = индексу игрока, который принял запрос.
				g_bSwapTeamPair[g_iSwapTeamBuffer[param1]][param1] = true;
				
				g_bSwapTeamFlag[param1][g_iSwapTeamBuffer[param1]] = true;
				g_bSwapTeamFlag[g_iSwapTeamBuffer[param1]][param1] = true;
				
				if(gc_bPluginMessages.BoolValue)
				{
					CPrintToChat(g_iSwapTeamBuffer[param1], "%s %t", g_sPrefix, "Accepted_Request", name_client);
					CPrintToChat(param1, "%s %t", g_sPrefix, "You_Accepted_Refuse", name_target);
				}
			}
			else if(StrEqual(info, "refuse"))
			{
				g_bSwapTeamPair[param1][g_iSwapTeamBuffer[param1]] = false;
				g_bSwapTeamPair[g_iSwapTeamBuffer[param1]][param1] = false;
				
				g_bSwapTeamFlag[param1][g_iSwapTeamBuffer[param1]] = false;
				g_bSwapTeamFlag[g_iSwapTeamBuffer[param1]][param1] = false;
				
				if(gc_bPluginMessages.BoolValue)
				{
					CPrintToChat(g_iSwapTeamBuffer[param1], "%s %t", g_sPrefix, "Dont_Accept_Your_Request", name_client);
					CPrintToChat(param1, "%s %t", g_sPrefix, "You_Refused", name_target);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Disconnected)
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iSwapTeamBuffer[param1], "%s %t", g_sPrefix, "Player_Disconnected");
				
			}
			else if(param2 == MenuCancel_Timeout)
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iSwapTeamBuffer[param1], "%s %t", g_sPrefix, "Player_Timeout");
			}
			
			g_bSwapTeamPair[param1][g_iSwapTeamBuffer[param1]] = false;
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_AutoBalance(int client, int argc)
{
	Menu menu = new Menu(HandlerMenu_AutoBalance);
	char info[128];
	
	FormatEx(info, sizeof(info), "%T", "Title_Admin_Menu", client);
    menu.SetTitle(info);
	
	if(gc_bSwapFilters.BoolValue) // меню фильтров 
	{
		FormatEx(info, sizeof(info), "%T", "Title_Filters_Menu", client);
		menu.AddItem("filters", info);
	}
	
	if(gc_bAdminBalanceTeam.BoolValue) // балансирует игроков в команде 
	{
		FormatEx(info, sizeof(info), "%T", "Team_Balance_Menu", client);
		menu.AddItem("balance", info);
	}
	
	if(gc_iAutoBalanceSettings.IntValue == 5 && !g_bTimer)
	{
		FormatEx(info, sizeof(info), "%T", "Title_On_Balance", client);
		menu.AddItem("on_balance", info);
	}
	else if(gc_iAutoBalanceSettings.IntValue == 5)
	{
		FormatEx(info, sizeof(info), "%T", "Title_Off_Balance", client);
		menu.AddItem("off_balance", info);
	}
	
	if(gc_bAdminSwapPlayers.BoolValue) // переместить игроков из одной команды в другую 
	{
		FormatEx(info, sizeof(info), "%T", "Title_Swap_Menu", client);
		menu.AddItem("swap", info);
	}
	
	if(gc_bAdminRestartRound.BoolValue) // рестарт текущего раунда
	{
		FormatEx(info, sizeof(info), "%T", "Title_Restart_Round", client);
		menu.AddItem("restart_round", info);
	}
	
	if(gc_bAdminRestartMatch.BoolValue) // рестарт матча
	{
		FormatEx(info, sizeof(info), "%T", "Title_Restart_Match", client);
		menu.AddItem("restart_match", info);
	}
	
	if(gc_bAdminRespwanPlayer.BoolValue) // возродить игрока
	{
		FormatEx(info, sizeof(info), "%T", "Title_Respwan_Player", client);
		menu.AddItem("respawn", info);
	}
	
	if(gc_bAdminQueueManagement.BoolValue && gc_iQueue.BoolValue) // управление очередями 
	{
		FormatEx(info, sizeof(info), "%T", "Title_Queue_Management", client);
		menu.AddItem("management", info);
	}
	
	if(gc_bPersonalImmunity.BoolValue) // выдать иммунитет игроку 
	{
		FormatEx(info, sizeof(info), "%T", "Title_Immunity_Menu", client);
		menu.AddItem("immunity", info);
	}
	
	if(gc_bAdminBanJoiningTeam.BoolValue) // управление блокировками команд игрокам
	{
		FormatEx(info, sizeof(info), "%T", "Title_Ban_Management_Menu", client);
		menu.AddItem("ban_management", info);
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int HandlerMenu_AutoBalance(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "filters"))
			{
				Menu_Filters(param1, 0);
			}
			else if(StrEqual(info, "balance"))
			{
				Menu_BalanceTeam(param1, 0);
			}
			else if(StrEqual(info, "swap"))
			{
				Menu_SwapPlayers(param1, 0);
			}
			else if(StrEqual(info, "restart_round"))
			{
				RestartRound(param1);
			}
			else if(StrEqual(info, "restart_match"))
			{
				RestartMatch(param1);
			}
			else if(StrEqual(info, "on_balance"))
			{
				EnableBalanceTimer(param1);
				Menu_AutoBalance(param1, 0);
			}
			else if(StrEqual(info, "off_balance"))
			{
				EnableBalanceTimer(param1);
				Menu_AutoBalance(param1, 0);
			}
			else if(StrEqual(info, "respawn"))
			{
				Menu_RespwanPlayer(param1, 0);
			}
			else if(StrEqual(info, "management"))
			{
				Menu_QueueManagement(param1, 0);
			}
			else if(StrEqual(info, "immunity"))
			{
				Menu_SelectPlayerImmunity(param1);
			}
			else if(StrEqual(info, "ban_management"))
			{
				Menu_BanManagement(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				ClientCommand(param1, "sm_admin");
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_BanManagement(int client)
{
	if(gc_bAdminBanJoiningTeam.BoolValue)
	{
		Menu menu = new Menu(HandlerMenu_BanManagement);
		char info[128];
		
		FormatEx(info, sizeof(info), "%T", "Select_Player", client);
		menu.SetTitle(info);
		
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
			{
				char userid[16];
				char name[MAX_NAME_LENGTH];
					
				GetClientName(i, name, sizeof(name));
				IntToString(GetClientUserId(i), userid, sizeof(userid));
				
				if(IsPlayerBannedTeam(i, 0))
				{
					FormatEx(name, sizeof(name), "%s [x]", name);
					menu.AddItem(userid, name);
				}
				else
				{
					FormatEx(name, sizeof(name), "%s [ ]", name);
					menu.AddItem(userid, name);
				}
			}
		}
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
}

public int HandlerMenu_BanManagement(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int target = GetClientOfUserId(StringToInt(info));
			
			if(target)
			{			
				Menu_SelectBanTeam(param1, target);
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_1");
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_AutoBalance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_SelectBanTeam(int client, int target)
{
	Menu menu = new Menu(HandlerMenu_SelectBanTeam);
	char info[128];
	g_iTarget[client] = target;
		
	FormatEx(info, sizeof(info), "%T", "Select_Team", client);
	menu.SetTitle(info);
		
	if(g_bBanCt[target])
	{
		FormatEx(info, sizeof(info), "%s [x]", "CT");
		menu.AddItem("ct", info);
	}
	else
	{
		FormatEx(info, sizeof(info), "%s [ ]", "CT");
		menu.AddItem("ct", info);
	}
	
	if(g_bBanT[target])
	{
		FormatEx(info, sizeof(info), "%s [x]", "T");
		menu.AddItem("t", info);
	}
	else
	{
		FormatEx(info, sizeof(info), "%s [ ]", "T");
		menu.AddItem("t", info);
	}
		
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_SelectBanTeam(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int target = g_iTarget[param1];
			
			if(target)
			{
				char name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));
				
				if(StrEqual(info, "ct"))
				{
					if(g_bBanCt[target])
					{
						g_bBanCt[target] = false;
						if(gc_bPluginMessages.BoolValue)
						{
							CPrintToChat(param1, "%s %t", g_sPrefix, "Unban_Team", name, "CT");
							GetClientName(param1, name, sizeof(name));
							CPrintToChat(target, "%s %t", g_sPrefix, "Admin_Unban_Team", name, "CT");
						}
					}
					else
					{
						g_bBanCt[target] = true;
						if(gc_bPluginMessages.BoolValue)
						{
							CPrintToChat(param1, "%s %t", g_sPrefix, "Ban_Team", name, "CT");
							GetClientName(param1, name, sizeof(name));
							CPrintToChat(target, "%s %t", g_sPrefix, "Admin_Ban_Team", name, "CT");
						}
					}
				}
				else if(StrEqual(info, "t"))
				{
					if(g_bBanT[target])
					{
						g_bBanT[target] = false;
						if(gc_bPluginMessages.BoolValue)
						{
							CPrintToChat(param1, "%s %t", g_sPrefix, "Unban_Team", name, "T");
							GetClientName(param1, name, sizeof(name));
							CPrintToChat(target, "%s %t", g_sPrefix, "Admin_Unban_Team", name, "T");
						}
					}
					else
					{
						g_bBanT[target] = true;
						if(gc_bPluginMessages.BoolValue)
						{
							CPrintToChat(param1, "%s %t", g_sPrefix, "Ban_Team", name, "T");
							GetClientName(param1, name, sizeof(name));
							CPrintToChat(target, "%s %t", g_sPrefix, "Admin_Ban_Team", name, "T");
						}
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_1");
			}
			
			Menu_SelectBanTeam(param1, target);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_BanManagement(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_SelectPlayerImmunity(int client)
{
	if(gc_bPersonalImmunity.BoolValue)
	{
		Menu menu = new Menu(HandlerMenu_SelectPlayerImmunity);
		char info[128];
		
		FormatEx(info, sizeof(info), "%T", "Title_Immunity", client);
		menu.SetTitle(info);
		
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
			{
				char userid[16];
				char name[MAX_NAME_LENGTH];
					
				GetClientName(i, name, sizeof(name));
				IntToString(GetClientUserId(i), userid, sizeof(userid));
				
				if(g_bPersonalImmunity[i])
				{
					FormatEx(name, sizeof(name), "%s [x]", name);
					menu.AddItem(userid, name);
				}
				else
				{
					FormatEx(name, sizeof(name), "%s [ ]", name);
					menu.AddItem(userid, name);
				}
			}
		}
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
}

public int HandlerMenu_SelectPlayerImmunity(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int target = GetClientOfUserId(StringToInt(info));
			
			if(target)
			{
				char name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));
				
				if(g_bPersonalImmunity[target])
				{
					g_bPersonalImmunity[target] = false;
					if(gc_bPluginMessages.BoolValue) 
					{
						CPrintToChat(param1, "%s %t", g_sPrefix, "Immunity_Removed", name); // name target
						GetClientName(param1, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Admin_Removed_Immunity", name); // name admin
					}
				}
				else
				{
					g_bPersonalImmunity[target] = true;
					if(gc_bPluginMessages.BoolValue) 
					{
						CPrintToChat(param1, "%s %t", g_sPrefix, "Immunity_Issued", name); // name admin
						GetClientName(param1, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Admin_Issued_Immunity", name); // name admin
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_1");
			}
			
			Menu_SelectPlayerImmunity(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_AutoBalance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_QueueManagement(int client, int argc)
{
	if(gc_bAdminQueueManagement.BoolValue)
	{
		Menu menu = new Menu(HandlerMenu_QueueManagement);
		char info[128];
		
		SetGlobalTransTarget(client);
		
		if(gc_iQueue.IntValue == 1) // очередь только для КТ
		{
			FormatEx(info, sizeof(info), "%t \n%t", "Title_Queue_Management", "Queue_CT_1", g_hQueueCt.Length);
			menu.SetTitle(info);
		}
		else if(gc_iQueue.IntValue == 2) // очередь только для Т
		{
			FormatEx(info, sizeof(info), "%t \n%t", "Title_Queue_Management", "Queue_T_1", g_hQueueT.Length);
			menu.SetTitle(info);
		}
		else if(gc_iQueue.IntValue == 3) // обе очереди 
		{
			FormatEx(info, sizeof(info), "%t\n%t\n%t", "Title_Queue_Management", "Queue_CT_1", g_hQueueCt.Length, "Queue_T_1", g_hQueueT.Length);
			menu.SetTitle(info);
		}
		
		FormatEx(info, sizeof(info), "%T", "Kick_Out_Of_Queue", client);
		menu.AddItem("kick", info);
		
		FormatEx(info, sizeof(info), "%T", "Move_From_Queue", client);
		menu.AddItem("move", info);
		 
		FormatEx(info, sizeof(info), "%T", "Shift_In_Queue", client);
		menu.AddItem("shift", info);
		
		FormatEx(info, sizeof(info), "%T", "Erase_Queue", client);
		menu.AddItem("erase", info);
		
		FormatEx(info, sizeof(info), "%T", "Create_New_Queue", client);
		menu.AddItem("create", info);
		
		FormatEx(info, sizeof(info), "%T", "Ban_Queue", client);
		menu.AddItem("ban_queue", info);
		
		FormatEx(info, sizeof(info), "%T", "View_Queue", client);
		menu.AddItem("view", info);
			
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
	
	return Plugin_Handled;
}

public int HandlerMenu_QueueManagement(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "kick"))
			{
				g_iAdminQueueFlag[param1] = 1;
				Menu_Queue(param1);
			}
			else if(StrEqual(info, "move"))
			{
				if(gc_iQueue.IntValue > 2)
				{
					g_iAdminQueueFlag[param1] = 2;
					Menu_Queue(param1);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Only_One_Queue");
				}
			}
			else if(StrEqual(info, "shift"))
			{
				g_iAdminQueueFlag[param1] = 3;
				Menu_Queue(param1);
			}
			else if(StrEqual(info, "erase"))
			{
				g_iAdminQueueFlag[param1] = 4;
				Menu_Queue(param1);
			}
			else if(StrEqual(info, "create"))
			{
				g_iAdminQueueFlag[param1] = 5;
				Menu_Queue(param1);
			}
			else if(StrEqual(info, "ban_queue"))
			{
				g_iAdminQueueFlag[param1] = 6;
				Menu_SelectPlayer(param1);
			}
			else if(StrEqual(info, "view"))
			{
				g_iAdminQueueFlag[param1] = 7;
				Menu_Queue(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_AutoBalance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_Queue(int client)
{
	if(gc_iQueue.IntValue == 3)
	{
		Menu menu = new Menu(HandlerMenu_Queue);
		char info[256];

		if(g_iAdminQueueFlag[client] != 5)
		{
			if(g_iAdminQueueFlag[client] != 4)
			{
				FormatEx(info, sizeof(info), "%T", "Title_Select_Queue", client);
				menu.SetTitle(info);
			}
			else
			{
				FormatEx(info, sizeof(info), "%T", "Title_Select_Queue_Want_To_Clear", client);
				menu.SetTitle(info);
			}
		}
		else
		{
			SetGlobalTransTarget(client);
			FormatEx(info, sizeof(info), "%t \n%t", "Note_1", "Title_Create_Queue");
			menu.SetTitle(info);
		}
		
		FormatEx(info, sizeof(info), "%T", "Queue_T_2", client);
		menu.AddItem("t", info);
	
		FormatEx(info, sizeof(info), "%T", "Queue_CT_2", client);
		menu.AddItem("ct", info);
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(gc_iQueue.IntValue == 2)
	{
		g_iTeamBuffer[client] = CS_TEAM_T;
		
		if(g_iAdminQueueFlag[client] != 5)
		{
			if(g_hQueueT.Length != 0)
			{
				if(g_iAdminQueueFlag[client] != 3)
				{
					if(g_iAdminQueueFlag[client] != 7)
					{
						if(g_iAdminQueueFlag[client] != 4)
						{
							Menu_SelectPlayerOfQueue(client, CS_TEAM_T);
						}
						else
						{
							EraseQueue(CS_TEAM_T, client);
						}
					}
					else
					{
						Menu_ViewQueue(client);
					}
				}
				else
				{
					if(g_hQueueT.Length == 1)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Only_One_Player_In_Queue");
					}
					else
					{
						Menu_SelectPlayerOfQueue(client, CS_TEAM_T);
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Queue_Is_Empty");
			}
		}
		else
		{
			Menu_CreateQueue(client);
		}
	}
	else if(gc_iQueue.IntValue == 1)
	{
		g_iTeamBuffer[client] = CS_TEAM_CT;
		
		if(g_iAdminQueueFlag[client] != 5)
		{
			if(g_hQueueCt.Length != 0)
			{
				if(g_iAdminQueueFlag[client] != 3)
				{
					if(g_iAdminQueueFlag[client] != 7)
					{
						if(g_iAdminQueueFlag[client] != 4)
						{
							Menu_SelectPlayerOfQueue(client, CS_TEAM_CT);
						}
						else
						{
							EraseQueue(CS_TEAM_CT, client);
						}
					}
					else
					{
						Menu_ViewQueue(client);
					}
				}
				else
				{
					if(g_hQueueCt.Length == 1)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Only_One_Player_In_Queue");
					}
					else
					{
						Menu_SelectPlayerOfQueue(client, CS_TEAM_CT);
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Queue_Is_Empty");
			}
		}
		else
		{
			Menu_CreateQueue(client);
		}
	}
}

public int HandlerMenu_Queue(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "ct"))
			{	
				g_iTeamBuffer[param1] = CS_TEAM_CT;
				
				if(g_iAdminQueueFlag[param1] == 5)
				{
					Menu_CreateQueue(param1);
				}
				else
				{	
					if(g_hQueueCt.Length != 0)
					{
						if(g_iAdminQueueFlag[param1] != 7)
						{
							if(g_iAdminQueueFlag[param1] == 3 && g_hQueueCt.Length == 1)
							{
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Only_One_Player_In_Queue");
							}
							else
							{
								if(g_iAdminQueueFlag[param1] != 4)
								{
									Menu_SelectPlayerOfQueue(param1, CS_TEAM_CT);
								}
								else
								{
									EraseQueue(g_iTeamBuffer[param1], param1);
								}
							}
						}
						else
						{
							Menu_ViewQueue(param1);
						}
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Queue_Is_Empty");
					}
				}
			}
			else if(StrEqual(info, "t"))
			{	
				g_iTeamBuffer[param1] = CS_TEAM_T;
				
				if(g_iAdminQueueFlag[param1] == 5)
				{
					Menu_CreateQueue(param1);
				}
				else
				{
					if(g_hQueueT.Length != 0)
					{
						if(g_iAdminQueueFlag[param1] != 7)
						{
							if(g_iAdminQueueFlag[param1] == 3 && g_hQueueT.Length == 1)
							{
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Only_One_Player_In_Queue");
							}
							else
							{
								if(g_iAdminQueueFlag[param1] != 5)
								{
									if(g_iAdminQueueFlag[param1] != 4)
									{
										Menu_SelectPlayerOfQueue(param1, CS_TEAM_T);
									}
									else
									{
										EraseQueue(g_iTeamBuffer[param1], param1);
									}
								}
								else
								{
									Menu_CreateQueue(param1);
								}
							}
						}
						else
						{
							Menu_ViewQueue(param1);
						}
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Queue_Is_Empty");
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_QueueManagement(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_ViewQueue(int client)
{
	Menu menu = new Menu(HandlerMenu_ViewQueue);
	char info[128];
	char name[MAX_NAME_LENGTH];
	
	if(g_iTeamBuffer[client] == CS_TEAM_CT)
	{
		FormatEx(info, sizeof(info), "%T", "Title_View_Queue", client, "CT", g_hQueueCt.Length);
		menu.SetTitle(info);
	}
	else
	{
		FormatEx(info, sizeof(info), "%T", "Title_View_Queue", client, "T", g_hQueueT.Length);
		menu.SetTitle(info);
	}
	
	switch(g_iTeamBuffer[client])
	{
		case CS_TEAM_CT:
		{
			for(int i = 0; i < g_hQueueCt.Length; ++i)
			{
				GetClientName(g_hQueueCt.Get(i), name, sizeof(name));
				menu.AddItem("0", name);
			}
		}
		case CS_TEAM_T:
		{
			for(int i = 0; i < g_hQueueT.Length; ++i)
			{
				GetClientName(g_hQueueT.Get(i), name, sizeof(name));
				menu.AddItem("0", name);
			}
		}
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_ViewQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			Menu_ViewQueue(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				if(gc_iQueue.IntValue > 2)
				{
					Menu_Queue(param1);
				}
				else
				{
					Menu_QueueManagement(param1, 0);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_SelectPlayer(int client)
{
	Menu menu = new Menu(HandlerMenu_SelectPlayer);
	char info[128];
	char name[MAX_NAME_LENGTH];
	char userid[16];
	
	FormatEx(info, sizeof(info), "%T", "Select_Player", client);
	menu.SetTitle(info);
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
		{
			GetClientName(i, name, sizeof(name));
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			
			menu.AddItem(userid, name);
		}
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_SelectPlayer(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int target = GetClientOfUserId(StringToInt(info));
			
			if(target)
			{
				Menu_SelectQueue(param1, target);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_QueueManagement(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_SelectQueue(int client, int target)
{
	Menu menu = new Menu(HandlerMenu_SelectQueue);
	char info[128];
	g_iTarget[client] = target; // g_iTarget[client] - индекс игрока с которым работает администартор
	
	FormatEx(info, sizeof(info), "%T", "Select_Queue", client);
	menu.SetTitle(info);
	
	if(gc_iQueue.IntValue == 1 || gc_iQueue.IntValue == 3)
	{
		if(g_bQueueCt[target])
		{
			FormatEx(info, sizeof(info), "%T [ ]", "Queue_CT_2", client);
			menu.AddItem("ct", info);
		}
		else
		{
			FormatEx(info, sizeof(info), "%T [x]", "Queue_CT_2", client);
			menu.AddItem("ct", info);
		}
	}
	
	if(gc_iQueue.IntValue == 2 || gc_iQueue.IntValue == 3)
	{
		if(g_bQueueT[target])
		{	
			FormatEx(info, sizeof(info), "%T [ ]", "Queue_T_2", client);
			menu.AddItem("t", info);
		}
		else
		{
			FormatEx(info, sizeof(info), "%T [x]", "Queue_T_2", client);
			menu.AddItem("t", info);
		}
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_SelectQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "ct"))
			{
				if(g_bQueueCt[g_iTarget[param1]])
				{
					if(g_hQueueCt.FindValue(g_iTarget[param1]) != -1)
					{
						g_bQueue[g_iTarget[param1]] = false;
						g_hQueueCt.Erase(g_hQueueCt.FindValue(g_iTarget[param1]));
						g_bQueueCt[g_iTarget[param1]] = false;
					}
					else
					{
						g_bQueueCt[g_iTarget[param1]] = false;
					}
					
					if(gc_bPluginMessages.BoolValue)
					{
						char name[MAX_NAME_LENGTH]; GetClientName(param1, name, sizeof(name));
						CPrintToChat(g_iTarget[param1], "%s %t", g_sPrefix, "You_Loked_Queue", name, "CT");
						CPrintToChat(param1, "%s %t", g_sPrefix, "Banned_Queue");
					}
				}
				else
				{
					g_bQueueCt[g_iTarget[param1]] = true;
					if(gc_bPluginMessages.BoolValue)
					{
						char name[MAX_NAME_LENGTH]; GetClientName(param1, name, sizeof(name));
						CPrintToChat(g_iTarget[param1], "%s %t", g_sPrefix, "You_Unloked_Queue", name, "CT");
						CPrintToChat(param1, "%s %t", g_sPrefix, "Unbanned_Queue");
					}
				}
			}
			else if(StrEqual(info, "t"))
			{
				if(g_bQueueT[g_iTarget[param1]])
				{
					if(g_hQueueT.FindValue(g_iTarget[param1]) != -1)
					{
						g_bQueue[g_iTarget[param1]] = false;
						g_hQueueT.Erase(g_hQueueT.FindValue(g_iTarget[param1]));
						g_bQueueT[g_iTarget[param1]] = false;
					}
					else
					{
						g_bQueueT[g_iTarget[param1]] = false;
					}
					
					if(gc_bPluginMessages.BoolValue)
					{
						char name[MAX_NAME_LENGTH]; GetClientName(param1, name, sizeof(name));
						CPrintToChat(g_iTarget[param1], "%s %t", g_sPrefix, "You_Loked_Queue", name, "T");
						CPrintToChat(param1, "%s %t", g_sPrefix, "Banned_Queue");
					}
				}
				else
				{
					g_bQueueT[g_iTarget[param1]] = true;
					if(gc_bPluginMessages.BoolValue)
					{
						char name[MAX_NAME_LENGTH]; GetClientName(param1, name, sizeof(name));
						CPrintToChat(g_iTarget[param1], "%s %t", g_sPrefix, "You_Unloked_Queue", name, "T");
						CPrintToChat(param1, "%s %t", g_sPrefix, "Unbanned_Queue");
					}
				}
			}
			
			Menu_SelectQueue(param1, g_iTarget[param1]);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_SelectPlayer(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_SelectPlayerOfQueue(int client, int team)
{
	Menu menu = new Menu(HandlerMenu_SelectPlayerOfQueue);
	char info[128];
	char name[MAX_NAME_LENGTH];
	char userid[16];
	
	if(team == CS_TEAM_CT)
	{
		switch(g_iAdminQueueFlag[client])
		{
			case 1:
			{
				FormatEx(info, sizeof(info), "%T", "Select_Player_Of_Queue_CT", client);
			}
			case 2:
			{
				FormatEx(info, sizeof(info), "%T", "Select_Player_Of_Queue_CT", client);
			}
			case 3:
			{
				FormatEx(info, sizeof(info), "%T", "Select_Player_Of_Queue_CT", client);
			}
		}
		menu.SetTitle(info);
		
		for(int i = 0;i < g_hQueueCt.Length; ++i)
		{
			GetClientName(g_hQueueCt.Get(i), name, sizeof(name));
			IntToString(GetClientUserId(g_hQueueCt.Get(i)), userid, sizeof(userid));
			
			menu.AddItem(userid, name);
		}
	}
	else
	{
		switch(g_iAdminQueueFlag[client])
		{
			case 1:
			{
				FormatEx(info, sizeof(info), "%T", "Select_Player_Of_Queue_T", client);
			}
			case 2:
			{
				FormatEx(info, sizeof(info), "%T", "Select_Player_Of_Queue_T", client);
			}
			case 3:
			{
				FormatEx(info, sizeof(info), "%T", "Select_Player_Of_Queue_T", client);
			}
		}
		menu.SetTitle(info);
		
		
		for(int i = 0;i < g_hQueueT.Length; ++i)
		{
			GetClientName(g_hQueueT.Get(i), name, sizeof(name));
			IntToString(GetClientUserId(g_hQueueT.Get(i)), userid, sizeof(userid));
			
			menu.AddItem(userid, name);
		}
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_SelectPlayerOfQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
					
			int target = GetClientOfUserId(StringToInt(info));
			
			if(target && g_bQueue[target])
			{
				g_iTarget[param1] = target;
				switch(g_iAdminQueueFlag[param1])
				{
					case 1:
					{	
						if(g_hQueueCt.FindValue(target) != -1)
						{
							g_hQueueCt.Erase(g_hQueueCt.FindValue(target));
							g_bQueue[target] = false; 
								
							if(gc_bPluginMessages.BoolValue) 
							{
								char name[MAX_NAME_LENGTH];
								GetClientName(param1, name, sizeof(name));
								CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Removed_From_Queue");
								CPrintToChat(target, "%s %t", g_sPrefix, "Kick_From_Queue", name, "CT");
							}
						}
						else if(g_hQueueT.FindValue(target) != -1)
						{
							g_hQueueT.Erase(g_hQueueT.FindValue(target));
							g_bQueue[target] = false; 
								
							if(gc_bPluginMessages.BoolValue) 
							{
								char name[MAX_NAME_LENGTH];
								GetClientName(target, name, sizeof(name));
								CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Removed_From_Queue");
								CPrintToChat(param1, "%s %t", g_sPrefix, "Kick_From_Queue", name, "T");
							}
						}
						else
						{
							if(gc_bPluginMessages.BoolValue)  CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue");
						}
					}
					case 2:
					{
						if(g_iTeamBuffer[param1] == CS_TEAM_CT)
						{
							if(g_hQueueCt.FindValue(target) != -1)
							{
								Menu_WhatQueue(param1);
							}
							else
							{
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue");
							}
						}
						else
						{
							if(g_hQueueT.FindValue(target) != -1)
							{
								Menu_WhatQueue(param1);
							}
							else
							{
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue");
							}
						}
					}
					case 3:
					{
						Menu_ReselectPlayerOfQueue(param1, g_iTeamBuffer[param1], target);
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue)
				{
					char name[MAX_NAME_LENGTH]; 
					
					if(!target)
					{
						GetClientName(target, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_2", name);
					}
					
					if(!g_bQueue[target] && target)
					{
						GetClientName(target, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Left_Queue", name);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				if(gc_iQueue.IntValue > 2)
				{
					Menu_Queue(param1);
				}
				else
				{
					Menu_QueueManagement(param1, 0);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_ReselectPlayerOfQueue(int client, int team, int target)
{
	Menu menu = new Menu(HandlerMenu_ReselectPlayerOfQueue);
	char info[128];
	char name[MAX_NAME_LENGTH]; GetClientName(target, name, sizeof(name));
	char userid[16];
	
	if(team == CS_TEAM_CT)
	{
		FormatEx(info, sizeof(info), "%T", "Reselect_Player_Of_Queue", client, name);
		menu.SetTitle(info);
		
		for(int i = 0;i < g_hQueueCt.Length; ++i)
		{
			GetClientName(g_hQueueCt.Get(i), name, sizeof(name));
			IntToString(GetClientUserId(g_hQueueCt.Get(i)), userid, sizeof(userid));
			
			if(g_hQueueCt.Get(i) == target)
			{
				FormatEx(name, sizeof(name), "%s <-", name);
			}
			
			menu.AddItem(userid, name);
		}
	}
	else
	{

		FormatEx(info, sizeof(info), "%T", "Reselect_Player_Of_Queue", client, name);
		menu.SetTitle(info);
		
		
		for(int i = 0;i < g_hQueueT.Length; ++i)
		{
			GetClientName(g_hQueueT.Get(i), name, sizeof(name));
			IntToString(GetClientUserId(g_hQueueT.Get(i)), userid, sizeof(userid));
			
			if(g_hQueueT.Get(i) == target)
			{
				FormatEx(name, sizeof(name), "%s <-", name);
			}
			
			menu.AddItem(userid, name);
		}
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_ReselectPlayerOfQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
					
			int targetNew = GetClientOfUserId(StringToInt(info));
			
			if(targetNew && IsClientInGame(g_iTarget[param1]) && g_bQueue[targetNew] && g_bQueue[g_iTarget[param1]])
			{
				if(targetNew == g_iTarget[param1])
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Not_Swap_Place_With_Himself");
				}
				else
				{
					if(g_iTeamBuffer[param1] == CS_TEAM_CT)
					{
						if(g_hQueueCt.FindValue(targetNew) != -1 && g_hQueueCt.FindValue(g_iTarget[param1]) != -1)
						{
							g_hQueueCt.SwapAt(g_hQueueCt.FindValue(targetNew), g_hQueueCt.FindValue(g_iTarget[param1]));
							if(gc_bPluginMessages.BoolValue)
							{
								char name_target[MAX_NAME_LENGTH], name_targetNew[MAX_NAME_LENGTH], admin[MAX_NAME_LENGTH];
								GetClientName(param1, admin, sizeof(admin)); GetClientName(targetNew, name_targetNew, sizeof(name_targetNew)); GetClientName(g_iTarget[param1], name_target, sizeof(name_target));
								CPrintToChat(param1, "%s %t", g_sPrefix, "Swapped_Two_Players");
								CPrintToChat(targetNew, "%s %t", g_sPrefix, "You_Were_Swapped", admin, name_target, g_hQueueCt.FindValue(targetNew) + 1);
								CPrintToChat(g_iTarget[param1], "%s %t", g_sPrefix, "You_Were_Swapped", admin, name_targetNew, g_hQueueCt.FindValue(g_iTarget[param1]) + 1);
							}
						}
						else
						{
							if(g_hQueueCt.FindValue(targetNew) == -1)
							{
								char name[MAX_NAME_LENGTH]; GetClientName(targetNew, name, sizeof(name));
								CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue_1", name);
							}
							else if(g_hQueueCt.FindValue(g_iTarget[param1]) == -1)
							{
								char name[MAX_NAME_LENGTH]; GetClientName(g_iTarget[param1], name, sizeof(name));
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue_1", name);
							}
						}
					}
					else
					{
						if(g_hQueueT.FindValue(targetNew) != -1 && g_hQueueT.FindValue(g_iTarget[param1]) != -1)
						{
							g_hQueueT.SwapAt(g_hQueueT.FindValue(targetNew), g_hQueueT.FindValue(g_iTarget[param1]));
							if(gc_bPluginMessages.BoolValue)
							{
								char name_target[MAX_NAME_LENGTH], name_targetNew[MAX_NAME_LENGTH], admin[MAX_NAME_LENGTH];
								GetClientName(param1, admin, sizeof(admin)); GetClientName(targetNew, name_targetNew, sizeof(name_targetNew)); GetClientName(g_iTarget[param1], name_target, sizeof(name_target));
								CPrintToChat(param1, "%s %t", g_sPrefix, "Swapped_Two_Players");
								CPrintToChat(targetNew, "%s %t", g_sPrefix, "You_Were_Swapped", admin, name_target, g_hQueueT.FindValue(targetNew) + 1);
								CPrintToChat(g_iTarget[param1], "%s %t", g_sPrefix, "You_Were_Swapped", admin, name_targetNew, g_hQueueT.FindValue(g_iTarget[param1]) + 1);
							}
						}
						else
						{
							char name[MAX_NAME_LENGTH];
							
							if(g_hQueueT.FindValue(targetNew) == -1)
							{
								GetClientName(targetNew, name, sizeof(name));
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue_1", name);
							}
							else if(g_hQueueT.FindValue(g_iTarget[param1]) == -1)
							{
								GetClientName(g_iTarget[param1], name, sizeof(name));
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue_1", name);
							}
						}
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue)
				{
					char name[MAX_NAME_LENGTH];
					
					if(!targetNew)
					{
						GetClientName(targetNew, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_2", name);
					}
					
					if(!IsClientInGame(g_iTarget[param1]))
					{
						GetClientName(g_iTarget[param1], name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_2", name);
					}
					
					if(!g_bQueue[targetNew] && targetNew)
					{
						GetClientName(targetNew, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Left_Queue", name);
					}
					
					if(!g_bQueue[g_iTarget[param1]] && !IsClientInGame(g_iTarget[param1]))
					{
						GetClientName(targetNew, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Left_Queue", name);
					}
				}
			}
			
			Menu_SelectPlayerOfQueue(param1, g_iTeamBuffer[param1]);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_SelectPlayerOfQueue(param1, g_iTeamBuffer[param1]);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_WhatQueue(int client)
{
	Menu menu = new Menu(HandlerMenu_WhatQueue);
	char info[128];
		
	FormatEx(info, sizeof(info), "%T", "Title_Select_What_Queue", client);
	menu.SetTitle(info);
		
	FormatEx(info, sizeof(info), "%T", "Queue_T_2", client);
	menu.AddItem("t", info);
	
	FormatEx(info, sizeof(info), "%T", "Queue_CT_2", client);
	menu.AddItem("ct", info);
		
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_WhatQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			int target = g_iTarget[param1];
			
			if(target)
			{
				if(StrEqual(info, "t"))
				{
					if(IsPlayerBannedTeam(target, CS_TEAM_T))
					{
						if(GetClientTeam(target) == CS_TEAM_SPECTATOR)
						{
							if(g_hQueueCt.FindValue(target) != -1)
							{
								if(gc_bPluginMessages.BoolValue)
								{
									char name[MAX_NAME_LENGTH];
									GetClientName(param1, name, sizeof(name));
									CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Moved");
									CPrintToChat(target, "%s %t", g_sPrefix, "Moved_Another_Queue", name, "T");
								}
								
								g_hQueueT.Push(target);
								g_hQueueCt.Erase(g_hQueueCt.FindValue(target));
							}
							else
							{
								if(g_hQueueT.FindValue(target) != -1)
								{
									if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Already_In_The_Queue");
								}
								else
									if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue");
							}
						}
						else
						{
							if(g_hQueueCt.FindValue(target) != -1)
							{
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Already_In_The_Queue");
							}
							else
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Already_In_This_Team");
						}
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Team_Banned_Player", "T");
					}
				}
				else if(StrEqual(info, "ct"))
				{
					if(IsPlayerBannedTeam(target, CS_TEAM_T))
					{
						if(GetClientTeam(target) == CS_TEAM_SPECTATOR)
						{
							if(g_hQueueT.FindValue(target) != -1)
							{				
								g_hQueueCt.Push(target);
								g_hQueueT.Erase(g_hQueueT.FindValue(target));
								
								if(gc_bPluginMessages.BoolValue)
								{
									char name[MAX_NAME_LENGTH];
									GetClientName(param1, name, sizeof(name));
									CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Moved");
									CPrintToChat(target, "%s %t", g_sPrefix, "Moved_Another_Queue", name, "CT");
								}
							}
							else
							{
								if(g_hQueueCt.FindValue(target) != -1)
								{
									if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Already_In_The_Queue");
								}
								else
									if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Is_Not_Queue");
							}
						}
						else
						{
							if(g_hQueueCt.FindValue(target) != -1)
							{
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Already_In_The_Queue");
							}
							else
								if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Already_In_This_Team");
						}
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Team_Banned_Player", "CT");
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_1");
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_SelectPlayerOfQueue(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void Menu_CreateQueue(int client)
{
	Menu menu = new Menu(HandlerMenu_CreateQueue);
	char info[128];
	char name[MAX_NAME_LENGTH];
	char userid[16];
	bool button;
	int count;
	
	switch(g_iTeamBuffer[client])
	{
		case CS_TEAM_CT:
		{
			SetGlobalTransTarget(client);
			FormatEx(info, sizeof(info), "%t %t:", "Title_Select_Players_For_Create_Queue", "CT");
			menu.SetTitle(info);
		}
		case CS_TEAM_T:
		{
			SetGlobalTransTarget(client);
			FormatEx(info, sizeof(info), "%t %t:", "Title_Select_Players_For_Create_Queue", "T");
			menu.SetTitle(info);
		}
	}
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && g_bSelectPlayer[i])
		{
			button = true;
			count++;
		}
	}
	
	if(button) // кнопка для создания очереди (занимает первый пункт)
	{
		FormatEx(info, sizeof(info), "%T", "Create_Queue", client, count);
		menu.AddItem("create", info);
	}
	
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != g_iTeamBuffer[client] && !IsPlayerBannedTeam(i, g_iTeamBuffer[client]))
		{
			GetClientName(i, name, sizeof(name));
			IntToString(GetClientUserId(i), userid, sizeof(userid));
				
			if(!g_bSelectPlayer[i])
			{
				FormatEx(name, sizeof(name), "%s [ ]", name);
			}
			else
			{
				FormatEx(name, sizeof(name), "%s [x]", name);
			}
				
			menu.AddItem(userid, name);	
		}
	}
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_CreateQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "create"))
			{
				char name[MAX_NAME_LENGTH]; GetClientName(param1, name, sizeof(name));
				
				if(g_iTeamBuffer[param1] == CS_TEAM_CT)
				{
					while(g_hQueueCt.Length != 0)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueCt.Get(0), "%s %t", g_sPrefix, "Delete_Of_New_Queue", name);
						g_bQueue[g_hQueueCt.Get(0)] = false;
						g_hQueueCt.Erase(0);
					}
					
					for(int i = 1;i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_CT && g_bSelectPlayer[i])
						{
							g_hQueueCt.Push(i);
							g_bQueue[i] = true;
							g_bSelectPlayer[i] = false;
							if(gc_bPluginMessages.BoolValue)  CPrintToChat(i, "%s %t", g_sPrefix, "Added_In_New_Queue", name);
						}
					}
				}
				else
				{
					while(g_hQueueT.Length != 0)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_hQueueT.Get(0), "%s %t", g_sPrefix, "Delete_Of_New_Queue", name);
						g_bQueue[g_hQueueT.Get(0)] = false;
						g_hQueueT.Erase(0);
					}
					
					for(int i = 1;i <= MaxClients; ++i)
					{
						if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_T && g_bSelectPlayer[i])
						{
							g_hQueueT.Push(i);
							g_bQueue[i] = true;
							g_bSelectPlayer[i] = false;
							if(gc_bPluginMessages.BoolValue) CPrintToChat(i, "%s %t", g_sPrefix, "Added_In_New_Queue", name);
						}
					}
				}
				
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Created_New_Queue");
			}
			else
			{
				int target = GetClientOfUserId(StringToInt(info));
				
				if(g_bQueueCt[target] || g_bQueueT[target])
				{
					if(target && !g_bSelectPlayer[target])
					{
						g_bSelectPlayer[target] = true;
						
					}
					else if(target && g_bSelectPlayer[target])
					{
						g_bSelectPlayer[target] = false;
					}
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) 
					{
						char name[MAX_NAME_LENGTH]; GetClientName(target, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Queue_Is_Blocked", name);
					}
				}
				
				Menu_CreateQueue(param1);
			}
		}
		case MenuAction_Cancel:
		{	
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && g_bSelectPlayer[i])
				{
					g_bSelectPlayer[i] = false;
				}
			}
			
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_QueueManagement(param1, 0);
			}
		}
		case MenuAction_End:
		{	
			delete menu;
		}
	}
}

public Action Menu_RespwanPlayer(int client, int argc)
{
	if(gc_bAdminRespwanPlayer.BoolValue)
	{
		Menu menu = new Menu(HandlerMenu_RespwanPlayer);
		char info[128];
		int count = 0;
				
		FormatEx(info, sizeof(info), "%T", "Respwan_Player", client);
		menu.SetTitle(info);
				
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
			{
				char userid[16];
				char name[MAX_NAME_LENGTH];
				char team[24];
				count++;
					
				GetClientName(i, name, sizeof(name));
				IntToString(GetClientUserId(i), userid, sizeof(userid));
					
				if(GetClientTeam(i) == CS_TEAM_CT)
				{
					FormatEx(team, sizeof(team), "%t", "CT");
				}
				else if(GetClientTeam(i) == CS_TEAM_T)
				{
					FormatEx(team, sizeof(team), "%t", "T");
				}
				
				FormatEx(name, sizeof(name), "%s [%s]", name, team);
				menu.AddItem(userid, name);
			}
		}
		
		if(!count)
		{
			if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "List_Dead_Players_Is_Empty");
			return Plugin_Handled;
		}
				
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
	
	return Plugin_Handled;
}

public int HandlerMenu_RespwanPlayer(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int target = GetClientOfUserId(StringToInt(info));
			
			if(target)
			{
				CS_RespawnPlayer(target);
				char name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Spawned", name);
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_1");
			}
			
			Menu_RespwanPlayer(param1, 0);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_AutoBalance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_Filters(int client, int argc)
{
	if(gc_bSwapFilters.BoolValue)
	{
		Menu menu = new Menu(HandlerMenu_Filters);
		char info[128];
		
		FormatEx(info, sizeof(info), "%T", "Title_Filters_Menu", client);
		menu.SetTitle(info);

		FormatEx(info, sizeof(info), "%T [%i]", "Filter_KD", client, gc_iSwapFilterKD.IntValue);
		menu.AddItem("kd", info);
		
		FormatEx(info, sizeof(info), "%T [%i]", "Filter_MVP", client, gc_iSwapFilterMVP.IntValue);
		menu.AddItem("mvp", info);
		
		FormatEx(info, sizeof(info), "%T [%i]", "Filter_Time", client, gc_iSwapFilterTime.IntValue);
		menu.AddItem("time", info);
		
		FormatEx(info, sizeof(info), "%T [%i]", "Filter_TimeTeam", client, gc_iSwapFilterTimeTeam.IntValue);
		menu.AddItem("timeteam", info);
		
		FormatEx(info, sizeof(info), "%T [%i]", "Filter_Money", client, gc_iSwapFilterMoney.IntValue);
		menu.AddItem("money", info);
		
		FormatEx(info, sizeof(info), "%T [%i]", "Filter_Ping", client, gc_iSwapFilterPing.IntValue);
		menu.AddItem("ping", info);
		
		FormatEx(info, sizeof(info), "%T [%i]", "Filter_Admin", client, gc_iSwapFilterAdmin.IntValue);
		menu.AddItem("admin", info);
		
		FormatEx(info, sizeof(info), "%T [%i]", "Filter_Headshot", client, gc_iSwapFilterFactorHeadshot.IntValue);
		menu.AddItem("headshot", info);
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
	
	return Plugin_Handled;
}

public int HandlerMenu_Filters(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{	
		case MenuAction_Select:
		{
			char info[128];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "kd"))
			{
				if(gc_iSwapFilterKD.IntValue == 2)
				{
					gc_iSwapFilterKD.IntValue = 0;
				}
				else
				{
					gc_iSwapFilterKD.IntValue++;
				}
				
				Menu_Filters(param1, 0);
			}
			else if(StrEqual(info, "mvp"))
			{
				if(gc_iSwapFilterMVP.IntValue == 2)
				{
					gc_iSwapFilterMVP.IntValue = 0;
				}
				else
				{
					if(!ChecksBots())
					{
						gc_iSwapFilterMVP.IntValue++;
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
					}
				}
				
				Menu_Filters(param1, 0);
			}
			else if(StrEqual(info, "time"))
			{
				if(gc_iSwapFilterTime.IntValue == 2)
				{
					gc_iSwapFilterTime.IntValue = 0;
				}
				else
				{
					if(!ChecksBots())
					{
						gc_iSwapFilterTime.IntValue++;
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
					}
				}
				
				Menu_Filters(param1, 0);
			}
			else if(StrEqual(info, "timeteam"))
			{
				if(gc_iSwapFilterTimeTeam.IntValue == 2)
				{
					gc_iSwapFilterTimeTeam.IntValue = 0;
				}
				else
				{
					if(!ChecksBots())
					{
						gc_iSwapFilterTimeTeam++;
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
					}
				}
			}
			else if(StrEqual(info, "money"))
			{
				if(gc_iSwapFilterMoney.IntValue == 2)
				{
					gc_iSwapFilterMoney.IntValue = 0;
				}
				else
				{
					gc_iSwapFilterMoney.IntValue++;
				}
				
				Menu_Filters(param1, 0);
			}
			else if(StrEqual(info, "ping"))
			{
				if(gc_iSwapFilterPing.IntValue == 2)
				{
					gc_iSwapFilterPing.IntValue = 0;
				}
				else
				{
					if(!ChecksBots())
					{
						gc_iSwapFilterPing.IntValue++;
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
					}
				}
				
				Menu_Filters(param1, 0);
			}
			else if(StrEqual(info, "admin"))
			{
				if(gc_iSwapFilterAdmin.IntValue == 3)
				{
					gc_iSwapFilterAdmin.IntValue = 0;
				}
				else
				{
					gc_iSwapFilterAdmin.IntValue++;
				}
				
				Menu_Filters(param1, 0);
			}
			else if(StrEqual(info, "headshot"))
			{
				if(gc_iSwapFilterFactorHeadshot.IntValue == 2)
				{
					gc_iSwapFilterFactorHeadshot.IntValue = 0;
				}
				else
				{
					gc_iSwapFilterFactorHeadshot.IntValue++;
				}
				
				Menu_Filters(param1, 0);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_AutoBalance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Vote_Balance(int client, int argc)
{
	if(gc_bBalanceVote.BoolValue)
	{
		int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
		
		if(clients >= gc_iMinValuePlayers.IntValue)
		{
			if(g_bVoteTeamSwap[client])
			{
				if(g_iVoteTeamSwapCounter < RoundToCeil(clients * gc_flPercentPlayersVote.FloatValue))
				{
					char name[MAX_NAME_LENGTH];
					GetClientName(client, name, sizeof(name));
					g_iVoteTeamSwapCounter++;
					if(gc_bPluginMessages.BoolValue) CPrintToChatAll("%s %t", g_sPrefix, "Voted", name, RoundToCeil(clients * gc_flPercentPlayersVote.FloatValue), g_iVoteTeamSwapCounter);
					g_bVoteTeamSwap[client] = false;
				}
				else
				{
					g_iVoteTeamSwapCounter = 0;
					if(gc_bPluginMessages.BoolValue) CPrintToChatAll("%s %t", g_sPrefix, "Balance_Successfully");
					
					for(int i = 1;i <= MaxClients; ++i)
					{
						g_bVoteTeamSwap[i] = true;
					}
					
					switch(gc_iAutoBalanceMode.IntValue)
					{
						case 1: 
						{
							CTRelationT(0);
						}
						case 2:
						{
							TRelationCT(0);
						}
					}
				}
			}
			else
			{
				if(RoundToCeil(clients * gc_flPercentPlayersVote.FloatValue) - g_iVoteTeamSwapCounter > 0)
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_Voted", RoundToCeil(clients * gc_flPercentPlayersVote.FloatValue) - g_iVoteTeamSwapCounter);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_Voted_2"); // скорее всего данная ситуация не произойдет и я даун
				}
			}
		}
		else
		{
			if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Minimum_Players", gc_iMinValuePlayers.IntValue - 1);
		}
	}
	
	return Plugin_Handled;
}

public Action Menu_BalanceTeam(int client, int argc)
{
	if(gc_bAdminBalanceTeam.BoolValue)
	{
		Menu menu = new Menu(HandlerMenu_BalanceTeam);
		char info[128];
		
		FormatEx(info, sizeof(info), "%T", "Team_Balance_Menu", client);
		menu.SetTitle(info);
		
		FormatEx(info, sizeof(info), "%T", "Evenly_Balance", client);
		menu.AddItem("evenly", info);
		
		FormatEx(info, sizeof(info), "%T", "Unevenly_Balance", client);
		menu.AddItem("unevenly", info);
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
	
	return Plugin_Handled;
}

public int HandlerMenu_BalanceTeam(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "evenly"))
			{
				Menu_SelectBalancingMode(param1, 0);
			}
			else if(StrEqual(info, "unevenly"))
			{
				Menu_SelectBalancingMode(param1, 1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_AutoBalance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_SelectBalancingMode(int client, int argc)
{
	Menu menu = new Menu(HandlerMenu_SelectBalancingMode);
	char info[128];
	
	if(!argc)
	{
		FormatEx(info, sizeof(info), "%T", "Evenly_Balance", client);
		menu.SetTitle(info);
	}
	else
	{
		FormatEx(info, sizeof(info), "%T", "Unevenly_Balance", client);
		menu.SetTitle(info);
	}
	
	FormatEx(info, sizeof(info), "%T", "Filter_KD", client); // использую названия фильтров, т.к. они аналогичны для балансировок
	menu.AddItem("kd", info);
	
	FormatEx(info, sizeof(info), "%T", "Filter_MVP", client);
	menu.AddItem("mvp", info);

	FormatEx(info, sizeof(info), "%T", "Filter_Time", client);
	menu.AddItem("time", info);
	
	FormatEx(info, sizeof(info), "%T", "Filter_TimeTeam", client);
	menu.AddItem("timeteam", info);
	
	FormatEx(info, sizeof(info), "%T", "Filter_Money", client);
	menu.AddItem("money", info);
	
	FormatEx(info, sizeof(info), "%T", "Filter_Ping", client);
	menu.AddItem("ping", info);
	
	FormatEx(info, sizeof(info), "%T", "Filter_Headshot", client);
	menu.AddItem("headshot", info);
	
	g_iBalanceMode = argc;
	
	menu.ExitButton = true;
	menu.ExitBackButton  = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HandlerMenu_SelectBalancingMode(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "kd"))
			{
				g_iBalanceFlag = 1;
				Menu_When(param1, 0);
			}
			else if(StrEqual(info, "mvp"))
			{
				if(!ChecksBots())
				{
					g_iBalanceFlag = 2;
					Menu_When(param1, 0);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
				}
			}
			else if(StrEqual(info, "time"))
			{
				if(!ChecksBots())
				{
					g_iBalanceFlag = 3;
					Menu_When(param1, 0);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
				}
			}
			else if(StrEqual(info, "timeteam"))
			{
				if(!ChecksBots())
				{
					g_iBalanceFlag = 4;
					Menu_When(param1, 0);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
				}
			}
			else if(StrEqual(info, "money"))
			{
				g_iBalanceFlag = 5;
				Menu_When(param1, 0);
			}
			else if(StrEqual(info, "ping"))
			{
				if(!ChecksBots())
				{
					g_iBalanceFlag = 6;
					Menu_When(param1, 0);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Bot_On_The_Server");
				}	
			}
			else if(StrEqual(info, "headshot"))
			{
				g_iBalanceFlag = 7;
				Menu_When(param1, 0);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_BalanceTeam(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_When(int client, int argc)
{
	Menu menu = new Menu(HandlerMenu_When);
	char info[128];
		
	FormatEx(info, sizeof(info), "%T", "Title_When_Menu", client);
	menu.SetTitle(info);
		
	FormatEx(info, sizeof(info), "%T", "Immediately", client);
	menu.AddItem("immediately", info);
		
	FormatEx(info, sizeof(info), "%T", "Round_The_End", client);
	menu.AddItem("end", info);
		
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int HandlerMenu_When(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "immediately"))
			{
				g_bWhen = false;
				
				switch(g_iBalanceFlag)
				{
					case 1:
					{
						BalancePlayersKD(g_iBalanceMode);
					}
					case 2:
					{
						BalancePlayersMVP(g_iBalanceMode);
					}
					case 3:
					{
						BalancePlayersTime(g_iBalanceMode);
					}
					case 4:
					{
						BalancePlayersTimeTeam(g_iBalanceMode);
					}
					case 5:
					{
						BalancePlayersMoney(g_iBalanceMode);
					}
					case 6:
					{
						BalancePlayersPing(g_iBalanceMode);
					}
					case 7:
					{
						BalancePlayersHeadshot(g_iBalanceMode);
					}
				}
				
				g_iBalanceFlag = 0;
			}
			else if(StrEqual(info, "end"))
			{
				g_bWhen = true;
				if(gc_bPluginMessages.BoolValue) CPrintToChatAll("%s %t", g_sPrefix, "Balance_Wiil_Round_End");
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_SelectBalancingMode(param1, g_iBalanceMode);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_SwapPlayers(int client, int argc)
{
	if(gc_bAdminSwapPlayers.BoolValue)
	{
		Menu menu = new Menu(HandlerMenu_SwapPlayers);
		char info[128];
			
		FormatEx(info, sizeof(info), "%T", "Title_Swap_Menu", client);
		menu.SetTitle(info);
			
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
			{
				char userid[16];
				char name[MAX_NAME_LENGTH];
				char team[24];
				
				if(GetClientTeam(i) == CS_TEAM_CT)
				{
					FormatEx(team, sizeof(team), "%t", "CT");
				}
				else if(GetClientTeam(i) == CS_TEAM_T)
				{
					FormatEx(team, sizeof(team), "%t", "T");
				}
				else
				{
					FormatEx(team, sizeof(team), "%t", "SPEC");
				}
				
				GetClientName(i, name, sizeof(name));
				IntToString(GetClientUserId(i), userid, sizeof(userid));
				if(g_bSwapBuffer[i])
				{
					FormatEx(name, sizeof(name), "%s [%s] [x]", name, team);
				}
				else
				{
					FormatEx(name, sizeof(name), "%s [%s] [ ]", name, team);
				}
				menu.AddItem(userid, name);
			}
		}
			
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
	
	return Plugin_Handled;
}

public int HandlerMenu_SwapPlayers(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int target = GetClientOfUserId(StringToInt(info));
			
			if(target && IsClientInGame(target))
			{
				if(!g_bSwapBuffer[target])
				{
					if(!IsPlayerImmunity(target))
					{
						Menu_WhichTeam(param1, target);
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Immunity");
						Menu_SwapPlayers(param1, 0);
					}
				}
				else
				{
					g_bSwapBuffer[target] = false;
					if(gc_bPluginMessages.BoolValue) 
					{
						char name[MAX_NAME_LENGTH];
						GetClientName(target, name, sizeof(name));
						CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Dont_Change_Team", name);
						GetClientName(param1, name, sizeof(name));
						CPrintToChat(target, "%s %t", g_sPrefix, "Admin_Remove_Change_Team", name);
						Menu_SwapPlayers(param1, 0);
					}
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Player_Left_Server_1");
				Menu_SwapPlayers(param1, 0);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_AutoBalance(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_SwapPlayersWhen(int client, int argc)
{
	Menu menu = new Menu(HandlerMenu_SwapPlayersWhen);
	char info[128];
		
	FormatEx(info, sizeof(info), "%T", "Title_When_Menu", client);
	menu.SetTitle(info);
		
	FormatEx(info, sizeof(info), "%T", "Immediately", client);
	menu.AddItem("immediately", info);
		
	FormatEx(info, sizeof(info), "%T", "Round_The_End", client);
	menu.AddItem("end", info);
		
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int HandlerMenu_SwapPlayersWhen(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "immediately"))
			{
				if(gc_iAutoBalanceMode.BoolValue && !gc_bAdminBalanceCheck.BoolValue || (gc_bAdminBalanceCheck.BoolValue && CheckBalance(g_iPlayerBuffer[param1], GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]])) || g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] == CS_TEAM_SPECTATOR)
				{
					if(IsPlayerAlive(g_iPlayerBuffer[param1])) // g_iPlayerBuffer[param1] - индекс клиента, которого переводят в новую команду
					{
						SafeSlapPlayer(g_iPlayerBuffer[param1]);
						MyChangeClientTeam(g_iPlayerBuffer[param1], g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]]); // g_iSaveNewPlayerTeam[] - сохраняет индекс команды в которую нужно перевести игрока
							
						if(!g_bRoundEnd)
						{
							CS_RespawnPlayer(g_iPlayerBuffer[param1]);
						}
					}
					else
					{
						MyChangeClientTeam(g_iPlayerBuffer[param1], g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]]);
					}
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Successfully_Swap");
				}
				else if(gc_iAutoBalanceMode.BoolValue && gc_bAdminBalanceCheck.BoolValue && !CheckBalance(g_iPlayerBuffer[param1], GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]]))
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Not_Successfully_Swap");
				}
				
				Menu_SwapPlayers(param1, 0);
			}
			else if(StrEqual(info, "end"))
			{
				g_bSwapBuffer[g_iPlayerBuffer[param1]] = true; // g_iPlayerBuffer[param1] ан-но, g_bSwapBuffer - флаг перевода
				
				if(gc_bAdminBalanceCheck.BoolValue || g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] != CS_TEAM_SPECTATOR)
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Flag_Set_Balance");
					
					if(g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] == CS_TEAM_CT)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iPlayerBuffer[param1], "%s %t", g_sPrefix, "Balance_Team", "CT");
					}
					else if(g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] == CS_TEAM_T)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iPlayerBuffer[param1], "%s %t", g_sPrefix, "Balance_Team", "T");
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iPlayerBuffer[param1], "%s %t", g_sPrefix, "Balance_Team", "SPEC");
					}
				}
				else 
				{
					if(g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] == CS_TEAM_CT)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iPlayerBuffer[param1], "%s %t", g_sPrefix, "Balance_Team_Round_End", "CT");
					}
					else if(g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] == CS_TEAM_T)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iPlayerBuffer[param1], "%s %t", g_sPrefix, "Balance_Team_Round_End", "T");
					}
					else
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(g_iPlayerBuffer[param1], "%s %t", g_sPrefix, "Balance_Team_Round_End", "SPEC");
					}
				}
				
				Menu_SwapPlayers(param1, 0);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_WhichTeam(param1, g_iPlayerBuffer[param1]);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Menu_WhichTeam(int client, int argc)
{
	Menu menu = new Menu(HandlerMenu_WhichTeam);
	char info[128];
	g_iPlayerBuffer[client] = argc; // команда в которую будет переведен игрок 
	
	FormatEx(info, sizeof(info), "%T", "Title_Which_Menu", client);
	menu.SetTitle(info);
		
	if(GetClientTeam(argc) != CS_TEAM_T)
	{
		FormatEx(info, sizeof(info), "%T", "T", client);
		menu.AddItem("t", info);
	}
		
	if(GetClientTeam(argc) != CS_TEAM_CT)
	{
		FormatEx(info, sizeof(info), "%T", "CT", client);
		menu.AddItem("ct", info);
	}
	
	if(GetClientTeam(argc) != CS_TEAM_SPECTATOR)
	{
		FormatEx(info, sizeof(info), "%T", "SPEC", client);
		menu.AddItem("spec", info);
	}
		
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int HandlerMenu_WhichTeam(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[8];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "t"))
			{
				if(!IsPlayerBannedTeam(g_iPlayerBuffer[param1], CS_TEAM_T))
				{
					g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] = CS_TEAM_T;
					Menu_SwapPlayersWhen(param1, 0);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Team_Banned_Player");
				}
			}
			else if(StrEqual(info, "ct"))
			{
				if(!IsPlayerBannedTeam(g_iPlayerBuffer[param1], CS_TEAM_T))
				{
					g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] = CS_TEAM_CT;
					Menu_SwapPlayersWhen(param1, 0);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(param1, "%s %t", g_sPrefix, "Team_Banned_Player");
				}
			}
			else if(StrEqual(info, "spec"))
			{
				g_iSaveNewPlayerTeam[g_iPlayerBuffer[param1]] = CS_TEAM_SPECTATOR;
				Menu_SwapPlayersWhen(param1, 0);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Menu_SwapPlayers(param1, 0);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action TakeQueueCt(int client, int argc)
{
	if(g_bQueueCt[client])
	{
		if(gc_iQueue.IntValue == 1 || gc_iQueue.IntValue == 3)
		{	
			if(!IsPlayerBannedTeam(client, CS_TEAM_CT))
			{
				if(g_hQueueCt.FindValue(client) == -1) // если клиента нет в очереди 
				{
					if(GetClientTeam(client) == CS_TEAM_CT)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Your_Team");
						return Plugin_Handled;
					}
					
					if(g_hQueueT.FindValue(client) != -1)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_In_Queue_1");
						return Plugin_Handled;
					}
					
					if(gc_iAutoBalanceMode.BoolValue && CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_CT))
					{
						if(!IsPlayerAlive(client))
						{
							if(g_hQueueCt.Length == 0)
							{
								MyChangeClientTeam(client, CS_TEAM_CT);
								if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Place_In_The_Team");
								return Plugin_Handled;
							}
						}
					}
					
					g_hQueueCt.Push(client);
					g_bQueue[client] = true; 
					if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "You_Took_Queue", g_hQueueCt.FindValue(client) + 1);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_In_Queue", g_hQueueCt.FindValue(client) + 1);
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Team_Banned", "CT");
			}
		}
	}
	else
	{
		if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Admin_Banned_Queue", "CT");
	}
	
	return Plugin_Handled;
}

public void GetOutOfQueueCt(int client)
{
	if(g_hQueueCt.FindValue(client) != -1)
	{
		g_bQueue[client] = false; 
		g_hQueueCt.Erase(g_hQueueCt.FindValue(client));
		if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Out_Of_Queue");
	}
	else
	{
		if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "No_Longer_In_Queue");
	}
}

public Action TakeQueueT(int client, int argc)
{
	if(g_bQueueCt[client])
	{
		if(gc_iQueue.IntValue == 2 || gc_iQueue.IntValue == 3)
		{	
			if(!IsPlayerBannedTeam(client, CS_TEAM_T))
			{
				if(g_hQueueT.FindValue(client) == -1) // если клиента нет в очереди 
				{
					if(GetClientTeam(client) == CS_TEAM_T)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Your_Team");
						return Plugin_Handled;
					}
					
					if(g_hQueueCt.FindValue(client) != -1)
					{
						if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_In_Queue_1");
						return Plugin_Handled;
					}
					
					if(gc_iAutoBalanceMode.BoolValue && CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_T))
					{
						if(!IsPlayerAlive(client))
						{
							if(g_hQueueT.Length == 0)
							{
								MyChangeClientTeam(client, CS_TEAM_T);
								if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Place_In_The_Team");
								return Plugin_Handled;
							}
						}
					}
					
					g_hQueueT.Push(client);
					g_bQueue[client] = true; 
					if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "You_Took_Queue", g_hQueueT.FindValue(client) + 1);
				}
				else
				{
					if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Already_In_Queue", g_hQueueT.FindValue(client) + 1);
				}
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Team_Banned", "T");
			}
		}
	}
	else
	{
		if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Admin_Banned_Queue", "T");
	}
	
	return Plugin_Handled;
}

public void GetOutOfQueueT(int client)
{
	if(g_hQueueT.FindValue(client) != -1)
	{
		g_bQueue[client] = false; 
		g_hQueueT.Erase(g_hQueueT.FindValue(client));
		if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Out_Of_Queue");
	}
	else
	{
		if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "No_Longer_In_Queue");
	}
}

public void EnableBalanceTimer(int client)
{
	if(gc_iAutoBalanceSettings.IntValue == 5)
	{
		if(!g_bTimer)
		{
			g_bTimer = true;
			CreateTimer(gc_flCheckInterval.FloatValue, Timer_PlayerCounter, 0, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			CPrintToChat(client, "%s %t", g_sPrefix, "On_Balance");
		}
		else
		{
			CPrintToChat(client, "%s %t", g_sPrefix, "Off_Balance");
			g_bTimer = false;
		}
	}
}

public void SetCommands()
{
	// Custom commands
	int count = 0;
	char Commands[256], CommandsL[16][32], Command[64];
	
	// Admin balance menu 
	gc_sCustomCommandsAdminMenu.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); // количество команд 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if (GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegAdminCmd(Command, Menu_AutoBalance, ADMFLAG_GENERIC); // админ баланс-меню
	}
	
	// Team balance menu 
	gc_sCustomCommandsAdminTeamBalance.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if (GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegAdminCmd(Command, Menu_BalanceTeam, ADMFLAG_GENERIC); // баланс команд 
	}
	
	// Team balance menu 
	gc_sCustomCommandsAdminSwapTeam.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if(GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegAdminCmd(Command, Menu_SwapPlayers, ADMFLAG_GENERIC); // баланс команд 
	}
	
	// General server menu 
	gc_sCustomCommandsMenu.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if(GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegConsoleCmd(Command, Menu_Balance); // меню сервера
	}
	
	// Request  
	gc_sCustomCommandsRequest.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if (GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegConsoleCmd(Command, Menu_Request); // предложение поменяться командами
	}
	
	// Vote
	gc_sCustomCommandsVoteBalance.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if (GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegConsoleCmd(Command, Vote_Balance); // проголосовать за баланс
	}
	
	// Queue of Ct
	gc_sCustomCommandsQueueCt.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if (GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegConsoleCmd(Command, TakeQueueCt); // занять очередь за кт
	}
	
	// Queue of T
	gc_sCustomCommandsQueueT.GetString(Commands, sizeof(Commands));
	ReplaceString(Commands, sizeof(Commands), " ", "");
	count = ExplodeString(Commands, ",", CommandsL, sizeof(CommandsL), sizeof(CommandsL[])); 
	
	for(int i = 0; i < count; ++i)
	{
		Format(Command, sizeof(Command), "sm_%s", CommandsL[i]);
		if (GetCommandFlags(Command) == INVALID_FCVAR_FLAGS)
			RegConsoleCmd(Command, TakeQueueT); // занять очередь за Т
	}
}

public void EraseQueue(int team, int admin)
{
	switch(team)
	{
		case CS_TEAM_CT:
		{
			while(g_hQueueCt.Length != 0)
			{
				g_bQueue[g_hQueueCt.Get(0)] = false;
				if(gc_bPluginMessages.BoolValue) 
				{
					char name[MAX_NAME_LENGTH]; GetClientName(admin, name, sizeof(name));
					CPrintToChat(g_hQueueCt.Get(0), "%s %t", g_sPrefix, "Your_Queue_Cleared", name);
				}
				g_hQueueCt.Erase(0);
			}
			CPrintToChat(admin, "%s %t", g_sPrefix, "Queue_Cleared");
		}
		case CS_TEAM_T:
		{
			while(g_hQueueT.Length != 0)
			{
				g_bQueue[g_hQueueT.Get(0)] = false;
				if(gc_bPluginMessages.BoolValue) 
				{
					char name[MAX_NAME_LENGTH]; GetClientName(admin, name, sizeof(name));
					CPrintToChat(g_hQueueT.Get(0), "%s %t", g_sPrefix, "Your_Queue_Cleared", name);
				}
				g_hQueueT.Erase(0);
			}
			CPrintToChat(admin, "%s %t", g_sPrefix, "Queue_Cleared");
		}
	}
}

///////////////////////////////////////////////////
// 												 //
//			 	      TIMERS					 //
//												 //
///////////////////////////////////////////////////

public Action Timer_PlayerCounter(Handle timer, int id)
{
	if(gc_iAutoBalanceSettings.IntValue != 5 || (g_bTimer && gc_iAutoBalanceSettings.IntValue == 5))
	{
		if(gc_iAutoBalanceSettings.IntValue != 0 && gc_iAutoBalanceSettings.IntValue != 5)
		{
			if(id != g_iTimerID)
			{
				g_hTimer = null;
				return Plugin_Stop;
			}
		
			if(g_iTime != 0)
			{
				g_iTime--;
			}
			else
			{
				g_hTimer = null;
				return Plugin_Stop;
			}
		}
		
		if(gc_iSwapFilterKD.BoolValue || gc_iSwapFilterTime.BoolValue || gc_iSwapFilterMoney.BoolValue || gc_iSwapFilterPing.BoolValue ||
		gc_iSwapFilterMVP.BoolValue || gc_iSwapFilterAdmin.BoolValue || gc_iSwapFilterFactorHeadshot.BoolValue || gc_iSwapFilterTimeTeam.BoolValue)
		{
			g_bSwapFilters = true;
		}
		
		switch(gc_iAutoBalanceMode.IntValue)
		{
			case 1: // КТ относительно Т
			{
				CTRelationT(0);
			}
			case 2: // Т относительно КТ
			{
				TRelationCT(0);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_Spectators(Handle timer, int userID)
{
	int client = GetClientOfUserId(userID);
	
	if(client)
	{
		if((GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE) && g_bSpectator[client])
		{
			if(CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_T), CS_TEAM_T))
			{
				MyChangeClientTeam(client, CS_TEAM_T);
			}
			else if(CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_T), CS_TEAM_CT))
			{
				MyChangeClientTeam(client, CS_TEAM_CT);
			}
			else
			{
				if(gc_bPluginMessages.BoolValue) CPrintToChat(client, "%s %t", g_sPrefix, "Not_Team_Change");
			}
		}
	}
	
	g_hSpectatorsTimer[client] = null;
	return Plugin_Stop;
}

public Action Timer_Request(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client)
	{
		g_bRequestTimes[client] = false;
	}
	
	return Plugin_Stop;
}

public Action Timer_AutoJoinTeam(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client)
	{
		switch(gc_iAutoConnected.IntValue)
		{
			case 0:
			{
				g_bSpectator[client] = false;
				MyChangeClientTeam(client, CS_TEAM_SPECTATOR);
			}
			case 1:
			{
				if(gc_iAutoBalanceMode.BoolValue && CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_CT))
				{
					MyChangeClientTeam(client, CS_TEAM_CT);
				}
				else if(gc_iAutoBalanceMode.BoolValue && CheckBalance(client, GetTeamClientCount(CS_TEAM_T), GetTeamClientCount(CS_TEAM_CT), CS_TEAM_T))
				{
					MyChangeClientTeam(client, CS_TEAM_T);
				}
				else
				{
					g_bSpectator[client] = false;
					MyChangeClientTeam(client, CS_TEAM_SPECTATOR);
				}
			}
		}
	}
	
	return Plugin_Changed;
}

///////////////////////////////////////////////////
// 												 //
//			 	   MY FUNCTIONS					 //
//												 //
///////////////////////////////////////////////////

public void SwapFilter(int client, int team)
{
	int candidates[FILTERS] = {0, ...};
	int workingFilters = 0;
	
	if(!gc_bSwapAlivePlayer.BoolValue && IsPlayerAlive(client))
	{
		return;
	}

	if(gc_iSwapFilterAdmin.IntValue == 2)
	{
		int admin = FilterAdmin(team);
		
		if(admin)
		{
			ChangeTeam(admin);
			return;
		}
	}
		
	if(gc_iSwapFilterKD.BoolValue)
	{
		candidates[0] = FilterKD(team);
		workingFilters++;
	}
	
	if(gc_iSwapFilterTime.BoolValue)
	{
		candidates[1] = FilterTime(team);
		workingFilters++;
	}
	
	if(gc_iSwapFilterMoney.BoolValue)
	{
		candidates[2] = FilterMoney(team);
		workingFilters++;
	}
	
	if(gc_iSwapFilterPing.BoolValue)
	{
		candidates[3] = FilterPing(team);
		workingFilters++;
	}
	
	if(gc_iSwapFilterMVP.BoolValue)
	{
		candidates[4] = FilterMVP(team);
		workingFilters++;
	}
	
	if(gc_iSwapFilterAdmin.BoolValue && gc_iSwapFilterAdmin.IntValue == 1)
	{
		candidates[5] = FilterAdmin(team);
		workingFilters++;
	}
	
	if(gc_iSwapFilterFactorHeadshot.BoolValue)
	{
		candidates[6] = FilterFactorHeadshot(team);
		workingFilters++;
	}
	
	if(gc_iSwapFilterTimeTeam.BoolValue)
	{
		candidates[7] = FilterTimeTeam(team);
		workingFilters++;
	}
	
	if(workingFilters == 0)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == team)
			{
				if(gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) != INVALID_ADMIN_ID)
					continue;
					
				ChangeTeam(i);
				return;
			}
		}
	}
	
	// Количество счетчиков должно быть = кол-ву фильтров
	int counter[FILTERS] = {0, ...};
	int max = -1;
	
	// Кол-во одинаковых игроков в фильтрах
	for(int i = 0;i < FILTERS;++i)
	{
		if(candidates[i] != 0) 
		{
			for(int j = 0;j < FILTERS;++j)
			{
				if(candidates[i] == candidates[j])
				{
					counter[i]++;
				}
			}
		}
		else // если в данном фильтре нет игрока или фильтра нет
		{
			continue;
		}
	}
	
	// часто встречающиеся игроки в фильтрах
	int amount = 0;
	
	for(int i = 0;i < FILTERS;++i)
	{
		if(counter[i] != 0)
		{
			if(counter[i] >= max)
			{
				amount++;
				
				if(amount == workingFilters) // если в каждом фильтре разные игроки, то случайным образом выбирается игрок для балансирования
				{
					ChoiceRandomClient(candidates, FILTERS);
					return;
				}
				
				max = counter[i];
			}
		}
		else
		{
			continue;
		}
	}
	
	// составляем свой массив из игроков с наибольшим числом повторений
	int[] reserve = new int[amount];
	
	for(int i = 0;i < amount;++i)
	{
		for(int j = 0;j < FILTERS; ++j)
		{
			if(counter[j] != 0)
			{
				if(counter[j] == max)
				{
					reserve[i] = candidates[j];
				}
			}
			else
			{
				continue;
			}
		}
	}
	 
	ChoiceRandomClient(reserve, amount);
}

public void ChoiceRandomClient(int[] arr, int amount)
{
	if(amount != 0)
	{
		int winner = GetRandomInt(0, amount - 1);
		ChangeTeam(arr[winner]);
		SetImmunity(arr[winner], true);
	}
	else
	{
		return;
	}
}

public int RoundToMath(float number)
{
	float fraction = FloatFraction(number);
	
	if(fraction >= 0.5)
	{
		return RoundToCeil(number);
	}
	else
	{
		return RoundToFloor(number);
	}
}

public bool IsPlayerBannedTeam(int client, int team)
{
	if(team == 0) // 0 - если нужно пройтись по всем коммандам
	{
		if(g_bBanCt[client])
		{
			return true;
		}
		
		if(g_bBanT[client])
		{
			return true;
		}	
	}
	
	if(team == CS_TEAM_CT)
	{
		if(g_bBanCt[client])
		{
			return true;
		}
	}
	if(team == CS_TEAM_T)
	{
		if(g_bBanT[client])
		{
			return true;
		}
	}
	
	return false;
}

public void RestartRound(int client) // * специальное событие *
{
	if(gc_bAdminRestartRound.BoolValue)
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		if(gc_bPluginMessages.BoolValue) CPrintToChatAll("%s %t", g_sPrefix, "Admin_Called_Restart_Round", name);
		CS_TerminateRound(1.0, CSRoundEnd_Draw, true);
		g_bSpecialEvent = true;
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
}

public void RestartMatch(int client) // * специальное событие *
{
	if(gc_bAdminRestartMatch.BoolValue)
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		if(gc_bPluginMessages.BoolValue) CPrintToChatAll("%s %t", g_sPrefix, "Admin_Called_Restart_Match", name);
		ServerCommand("mp_restartgame 1");
		g_bSpecialEvent = true;
	}
	else
	{
		if(gc_bPluginMessages.IntValue) CPrintToChat(client, "%s %t", g_sPrefix, "Function_Prohibited");
	}
}

public void Distribution(int[] arr, int clients, int mode) 
{
	if(!mode) // равномерно
	{
		for(int i = 0; i < clients; ++i)
		{
			if(i % 2)
			{
				if(IsPlayerAlive(arr[i]))
				{
					if(gc_bOnTakeDamageSwappedPlayers.BoolValue && g_bRoundEnd)
					{
						MyChangeClientTeam(arr[i], CS_TEAM_CT);

						CS_RespawnPlayer(arr[i]);
					}
					else
					{
						SafeSlapPlayer(arr[i]);
						MyChangeClientTeam(arr[i], CS_TEAM_CT);

						CS_RespawnPlayer(arr[i]);
					}
				}
				else
				{
					MyChangeClientTeam(arr[i], CS_TEAM_CT);
				}
			}
			else
			{
				if(IsPlayerAlive(arr[i]))
				{
					if(gc_bOnTakeDamageSwappedPlayers.BoolValue && g_bRoundEnd)
					{
						MyChangeClientTeam(arr[i], CS_TEAM_T);

						CS_RespawnPlayer(arr[i]);
					}
					else
					{
						SafeSlapPlayer(arr[i]);
						MyChangeClientTeam(arr[i], CS_TEAM_T);

						CS_RespawnPlayer(arr[i]);
					}
				}
				else
				{
					MyChangeClientTeam(arr[i], CS_TEAM_T);
				}
			}
		}
	}
	else // неравномерно
	{	
		int team1, team2;
		
		if(GetRandomInt(0,1))
		{
			team1 = CS_TEAM_CT;
			team2 = CS_TEAM_T;
		}
		else
		{
			team1 = CS_TEAM_T;
			team2 = CS_TEAM_CT;
		}
		
		for(int i = 0; i < clients; ++i)
		{
			if(i < clients / 2)
			{
				if(IsPlayerAlive(arr[i]))
				{
					if(gc_bOnTakeDamageSwappedPlayers.BoolValue && g_bRoundEnd)
					{
						MyChangeClientTeam(arr[i], team1);

						CS_RespawnPlayer(arr[i]);
					}
					else
					{
						SafeSlapPlayer(arr[i]);
						MyChangeClientTeam(arr[i], team1);

						CS_RespawnPlayer(arr[i]);
					}
				}
				else
				{
					MyChangeClientTeam(arr[i], team1);
				}
			}
			else
			{
				if(IsPlayerAlive(arr[i]))
				{
					if(gc_bOnTakeDamageSwappedPlayers.BoolValue && g_bRoundEnd)
					{
						MyChangeClientTeam(arr[i], team2);
						CS_RespawnPlayer(arr[i]);
					}
					else
					{
						SafeSlapPlayer(arr[i]);
						MyChangeClientTeam(arr[i], team2);

						CS_RespawnPlayer(arr[i]);
					}
				}
				else
				{
					MyChangeClientTeam(arr[i], team2);
				}
			}
		}
	}
	
	if(gc_bPluginMessages.BoolValue) CPrintToChatAll("%s %t", g_sPrefix, "Teams_Were_Balanced");
}

public int OppositeTeam(int team)
{
	if(team == CS_TEAM_CT)
	{
		return CS_TEAM_T;
	}
	else if(team == CS_TEAM_T)
	{
		return CS_TEAM_CT;
	}
	
	return -1;
}

public void SafeSlapPlayer(int client)
{
	g_bBalanceSwapped[client] = true;

	int frags = GetEntProp(client, Prop_Data, "m_iFrags");
	int deaths = GetEntProp(client, Prop_Data, "m_iDeaths");
	
	SetEntProp(client, Prop_Data, "m_iFrags", frags + 1);
	SetEntProp(client, Prop_Data, "m_iDeaths", deaths - 1);
	
	SlapPlayer(client, GetClientHealth(client), false);
}

public bool ChecksBots()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && IsFakeClient(i))
		{
			return true;
		}
	}
	
	return false;
}

public bool IsPlayerImmunity(int client)
{
	if(g_bImmunity[client] || g_bPersonalImmunity[client])
	{
		return true;
	}

	return false;
}
// ************************************************************************************************************************************
//	- иммунитет выдается при перемещение игрока из одной команды в другой во время баланса и действует в течение одного раунда, то есть
//	  если игрок был перемещен в начале раунда, то в конце он не будет перемещен обратно из-за баланса. 
//	  НО нужно учитывать тот факт, что если игрок был перемещен в конце раунда, то баланс может перевести его и в начале.
//	- иммунитет не выдается, если авто-баланс работает постоянно (sm_ab_settings = 0)
// ************************************************************************************************************************************
public void SetImmunity(int client, bool immunity)
{
	if(gc_iAutoBalanceLevel.IntValue > 1 && gc_iAutoBalanceSettings.BoolValue)
	{
		g_bImmunity[client] = immunity;
	}
}

public bool IsValidClient(int client)
{
	if(client <= 0)
	{
		return false;
	}
	
	if(client > MaxClients)
	{
		return false;
	}
	
	return true;
}

public bool GetButton(int button)
{
	if(button)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public void MyChangeClientTeam(int client, int team)
{
	if(IsPlayerBannedTeam(client, team))
	{
		if(gc_bPluginMessages.BoolValue)
		{
			if(team == CS_TEAM_CT)
			{
				CPrintToChat(client, "%s %t", g_sPrefix, "Team_Banned", "CT");
			}
			else 
			{
				CPrintToChat(client, "%s %t", g_sPrefix, "Team_Banned", "T");
			}
		}
		
		return;
	}
	
	if(team == CS_TEAM_SPECTATOR)
	{
		ChangeClientTeam(client, team);
		g_bSpectator[client] = false;
	}
	else
	{
		CS_SwitchTeam(client, team);
	}
}

public bool CheckBalance(int client, int t, int ct, int team)
{
	if(ct == 0)
		ct = 1;
	
	if(t == 0)
		t = 1;
	
	if(GetTeamClientCount(CS_TEAM_T) / ct == 0 && team == CS_TEAM_T && GetTeamClientCount(CS_TEAM_T) == 0)
	{
		return true;
	}
	
	if(GetTeamClientCount(CS_TEAM_CT) / t == 0 && team == CS_TEAM_CT && GetTeamClientCount(CS_TEAM_CT) == 0)
	{
		return true;
	}
	
	if(gc_iPreciseAutoBalnce.BoolValue && !gc_iRatio.BoolValue)
	{
		if(GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE)
		{
			if(team == CS_TEAM_CT)
			{
				if(GetTeamClientCount(CS_TEAM_CT) <= GetTeamClientCount(CS_TEAM_T) && gc_iPreciseAutoBalanceT.IntValue == gc_iPreciseAutoBalanceCt.IntValue && GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue)
				{
					return true;
				}
				else if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue && GetTeamClientCount(CS_TEAM_T) >= gc_iPreciseAutoBalanceT.IntValue)
				{
					return true;
				}
			}
			
			if(team == CS_TEAM_T)
			{
				if(GetTeamClientCount(CS_TEAM_T) <= GetTeamClientCount(CS_TEAM_CT) && GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue)
				{
					return true;
				}
				else if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_CT) >= gc_iPreciseAutoBalanceCt.IntValue)
				{
					return true;
				}
			}
		}
		else if(GetClientTeam(client) == CS_TEAM_CT)
		{
			if(team == CS_TEAM_T)
			{
				if((GetTeamClientCount(CS_TEAM_T) + 1 <= GetTeamClientCount(CS_TEAM_CT) - 1 || (abs(GetTeamClientCount(CS_TEAM_CT) - GetTeamClientCount(CS_TEAM_T)) == 1 && GetTeamClientCount(CS_TEAM_CT) > GetTeamClientCount(CS_TEAM_T)) && GetTeamClientCount(CS_TEAM_T) + 1 <= gc_iPreciseAutoBalanceT.IntValue))
				{
					return true;
				}
				else if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_CT) >= gc_iPreciseAutoBalanceCt.IntValue)
				{
					return true;
				}
			}
		}
		else if(GetClientTeam(client) == CS_TEAM_T)
		{
			if(team == CS_TEAM_CT)
			{
				if((GetTeamClientCount(CS_TEAM_CT) + 1 <= GetTeamClientCount(CS_TEAM_T) - 1 || (abs(GetTeamClientCount(CS_TEAM_CT) - GetTeamClientCount(CS_TEAM_T)) == 1 && GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT)) && GetTeamClientCount(CS_TEAM_CT) + 1 <= gc_iPreciseAutoBalanceCt.IntValue))
				{
					return true;
				}
				else if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue && GetTeamClientCount(CS_TEAM_T) >= gc_iPreciseAutoBalanceT.IntValue)
				{
					return true;
				}
			}
		}
	}
	else
	{
		if(GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE)
		{
			switch(gc_iAutoBalanceMode.IntValue)
			{
				case 1: // команда КТ является основной 
				{
					switch(gc_iAutoBalanceLevel.IntValue)
					{
					case EASY:
					{
						if(team == CS_TEAM_T)	
						{
							return true;
						}
						else if(RoundToMath(float(t) / float(ct + 1)) >= gc_iRatio.IntValue)
						{
							if(team == CS_TEAM_CT)
							{
								return true;
							}
						}
					}
					case MEDIUM:
					{
						if(team == CS_TEAM_T)	
						{
							return true;
						}
						else if(RoundToMath(float(t) / float(ct + 1)) >= gc_iRatio.IntValue)
						{
							if(team == CS_TEAM_CT)
							{
								return true;
							}
						}
					}
					case HARD:
					{
						if(team == CS_TEAM_T)
						{
							if(float(t + 1) / float(ct) <= gc_iRatio.IntValue)
							{
								return true;
							}
							else if(float(t) / float(ct + 1) >=  gc_iRatio.IntValue)
							{
								return false;
							}
							else 
							{
								return true;
							}
						}
						else if(team == CS_TEAM_CT)
						{
							if(float(t) / float(ct + 1) >= gc_iRatio.IntValue)
							{
								return true;
							}
						}
					}
					}
				}
				case 2: // команда Т является основной	
				{		
					switch(gc_iAutoBalanceLevel.IntValue)
					{
					case EASY:
					{
						if(team == CS_TEAM_CT)	
						{
							return true;
						}
						else if(RoundToMath(float(ct) / float(t + 1)) >= gc_iRatio.IntValue)
						{
							if(team == CS_TEAM_T)
							{
								return true;
							}
						}
					}
					case MEDIUM:
					{
						if(team == CS_TEAM_CT)	
						{
							return true;
						}
						else if(RoundToMath(float(ct) / float(t + 1)) >= gc_iRatio.IntValue)
						{
							if(team == CS_TEAM_T)
							{
								return true;
							}
						}
					}
					case HARD:
					{
						if(team == CS_TEAM_CT)
						{
							if(float(ct + 1) / float(t) <= gc_iRatio.IntValue)
							{
								return true;
							}
							else if(float(ct) / float(t + 1) >=  gc_iRatio.IntValue)
							{
								return false;
							}
							else 
							{
								return true;
							}
						}
						else if(team == CS_TEAM_T)
						{
							if(float(ct) / float(t + 1) >= gc_iRatio.IntValue)
							{
								return true;
							}
						}
					}
					}
				}
			}
		}
		else if(GetClientTeam(client) == CS_TEAM_CT)
		{
			switch(gc_iAutoBalanceMode.IntValue)
			{
				case 1:
				{
					switch(gc_iAutoBalanceLevel.IntValue)
					{
					case EASY:
					{
						return true; // т.к. игрок за КТ, он свободно может зайти за Т при легком балансе
					}
					case MEDIUM:
					{
						return true;
					}
					case HARD:
					{
						if(team == CS_TEAM_T)
						{
							if(float(t + 1) / float(ct - 1) <= gc_iRatio.IntValue)
							{
								return true;
							}
							else if(float(t) / float(ct) >=  gc_iRatio.IntValue)
							{
								return false;
							}
							else 
							{
								return true;
							}
						}
					}
					}
				}
				case 2: 
				{					
					switch(gc_iAutoBalanceLevel.IntValue)
					{
					case EASY:
					{ 
						if(team == CS_TEAM_T)
						{
							if(float(ct - 1) / float(t + 1) >= gc_iRatio.IntValue)
							{
								return true;
							}
						}
					}
					case MEDIUM:
					{
						if(team == CS_TEAM_T)
						{
							if(float(ct - 1) / float(t + 1) >= gc_iRatio.IntValue)
							{
								return true;
							}
						}
					}
					case HARD:
					{
						if(team == CS_TEAM_T)
						{
							if(float(ct - 1) / float(t + 1) >= gc_iRatio.IntValue)
							{
								return true;
							}
						}
					}
					}
				}
			}
		}
		else if(GetClientTeam(client) == CS_TEAM_T)
		{
			switch(gc_iAutoBalanceMode.IntValue)
			{
				case 1:
				{				
					switch(gc_iAutoBalanceLevel.IntValue)
					{
					case EASY:
					{
						if(gc_iRatio.IntValue > 1)
						{
							if(team == CS_TEAM_CT)
							{
								if(RoundToMath(float(t - 1) / float(ct + 1)) >= gc_iRatio.IntValue)
								{
									return true;
								}
							}
						}
						else
						{
							if(team == CS_TEAM_CT)
							{
								if(float(t - 1) / float(ct + 1) >= gc_iRatio.IntValue)
								{
									return true;
								}
							}
						}
					}
					case MEDIUM:
					{
						if(gc_iRatio.IntValue > 1)
						{
							if(team == CS_TEAM_CT)
							{
								if(RoundToMath(float(t - 1) / float(ct + 1)) >= gc_iRatio.IntValue)
								{
									return true;
								}
							}
						}
						else
						{
							if(team == CS_TEAM_CT)
							{
								if(float(t - 1) / float(ct + 1) >= gc_iRatio.IntValue)
								{
									return true;
								}
							}
						}
					}
					case HARD:
					{
						if(gc_iRatio.IntValue > 1)
						{
							if(team == CS_TEAM_CT)
							{
								if(RoundToMath(float(t - 1) / float(ct + 1)) >= gc_iRatio.IntValue)
								{
									return true;
								}
							}
						}
						else
						{
							if(team == CS_TEAM_CT)
							{
								if(float(t - 1) / float(ct + 1) >= gc_iRatio.IntValue)
								{
									return true;
								}
							}
						}
					}
					}
				}
				case 2: 
				{				
					switch(gc_iAutoBalanceLevel.IntValue)
					{
					case EASY:
					{
						return true; // т.к. игрок за Т, он свободно может зайти за КТ при легком балансе
					}
					case MEDIUM:
					{
						return true;
					}
					case HARD:
					{
						if(gc_iRatio.IntValue > 1)
						{
							if(team == CS_TEAM_CT)
							{
								if(RoundToMath(float(ct + 1) / float(t - 1)) <= gc_iRatio.IntValue)
								{
									return true;
								}
								else if(RoundToMath(float(ct - 1) / float(t + 1)) >=  gc_iRatio.IntValue)
								{
									return false;
								}
								else 
								{
									return true;
								}
							}
						}
						else
						{
							if(team == CS_TEAM_CT)
							{
								if(float(ct + 1) / float(t - 1) <= gc_iRatio.IntValue)
								{
									return true;
								}
								else if(float(ct - 1) / float(t + 1) >=  gc_iRatio.IntValue)
								{
									return false;
								}
								else 
								{
									return true;
								}
							}
						}
					}
					}
				}
			}
		}
	}
	
	return false;
}

public void ChangeTeam(int client)
{
	if(!gc_bSwapAlivePlayer.BoolValue && client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		return;
	}
	
	switch(gc_iAutoBalanceOptions.IntValue)
	{
		case 1:
		{
			if(GetClientTeam(client) == CS_TEAM_CT)
			{
				return;
			}
		}
		case 2:
		{
			if(GetClientTeam(client) == CS_TEAM_T)
			{
				return;
			}
		}
	}
	
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(gc_bOnTakeDamageSwappedPlayers.BoolValue && g_bRoundEnd)
		{
			g_bSwapped[client] = true;
		}
		else
		{
			SafeSlapPlayer(client);
		}
			
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			MyChangeClientTeam(client, CS_TEAM_T);
		}
		else if(GetClientTeam(client) == CS_TEAM_T)
		{
			MyChangeClientTeam(client, CS_TEAM_CT);
		}
			
		if(!g_bRoundEnd)
		{
			CS_RespawnPlayer(client);
		}
	}
	else
	{
		if(client && GetClientTeam(client) == CS_TEAM_CT)
		{
			MyChangeClientTeam(client, CS_TEAM_T);
		}
		else if(client && GetClientTeam(client) == CS_TEAM_T)
		{
			MyChangeClientTeam(client, CS_TEAM_CT);
		}
	}
}

public void ChangeTeamSolo(int client, int team)
{
	if(GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE)
	{
		MyChangeClientTeam(client, team);	
	}
}

public int abs(int number)
{
	if(number < 0)
	{
		return -number;
	}
	else
	{
		return number;
	}
}

public float KD(int client)
{	
	int deaths = GetClientDeaths(client);
	int frags = GetClientFrags(client);
						
	if(!deaths)
	{
		deaths = 1;
	}
					
	if(frags < 0)
	{
		frags = 0;
	}
	
	float kd = float(frags) / float(deaths);
	
	return kd;
}

///////////////////////////////////////////////////
// 												 //
//			    BALANCE FUNCTIONS				 //
//												 //
///////////////////////////////////////////////////

public void CTRelationT(int client)
{
	if((GetTeamClientCount(CS_TEAM_CT) != 0 || GetTeamClientCount(CS_TEAM_T) != 0) && client == 0)
	{
		int clients = 0; // количество игроков на сервере
		int ix = 0; // индексы игроков в отдельном массиве
		
		for(int i = 1;i <= MaxClients; ++i) // определяем число игроков
		{
			if(IsClientInGame(i))
			{
				clients++;
			}
		}
		
		int[] players = new int[clients]; 
		
		for(int i = 1;i <= MaxClients; ++i) // заполняем массив 
		{
			if(IsClientInGame(i))
			{
				players[ix] = i;
				ix++;
			}
		}
		
		for(int i = 0;i < clients; ++i) // сортируем его в хаотичном порядке
		{
			int tmp = players[i];
			players[i] = players[GetRandomInt(0, clients - 1)];
			players[GetRandomInt(0, clients - 1)] = tmp;
		}
		
		for(int i = 0; i < clients; ++i)
		{
			int Cts = GetTeamClientCount(CS_TEAM_CT);
			
			if(Cts == 0)
			{
				Cts++;
			}
			
			if(!gc_iPreciseAutoBalnce.BoolValue && gc_iRatio.BoolValue)
			{
				if(IsClientInGame(players[i]) && GetClientTeam(players[i]) == CS_TEAM_CT && GetTeamClientCount(CS_TEAM_CT) > 1 && float(GetTeamClientCount(CS_TEAM_T)) / float(GetTeamClientCount(CS_TEAM_CT)) < gc_iRatio.IntValue)
				{
					int factor = RoundToCeil(float(GetTeamClientCount(CS_TEAM_T)) / gc_iRatio.FloatValue); // кол-во доступных игроков за КТ
					
					if(Cts > factor)
					{
						if(IsPlayerBannedTeam(players[i], CS_TEAM_T))
						{
							continue; // если игроку нельзя в другую команду - пропускаем итерацию
						}
						
						if(IsPlayerImmunity(players[i]))
						{
							continue; // если у игрока иммунитет - пропускаем итерацию 
						}
						
						if(g_bSwapFilters)
						{
							SwapFilter(players[i], CS_TEAM_CT);
						}
						else												
						{
							ChangeTeam(players[i]);
							SetImmunity(players[i], true);
						}
					}
				}
				else if(IsClientInGame(players[i]) && GetClientTeam(players[i]) == CS_TEAM_T && float(GetTeamClientCount(CS_TEAM_T)) / float(Cts) > gc_iRatio.IntValue)
				{
					if(float(GetTeamClientCount(CS_TEAM_T) - 1) / float(GetTeamClientCount(CS_TEAM_CT) + 1) > gc_iRatio.IntValue)
					{
						if(IsPlayerBannedTeam(players[i], CS_TEAM_CT))
						{
							continue; 
						}
						
						if(IsPlayerImmunity(players[i]))
						{
							continue; 
						}
						
						if(g_bSwapFilters)
						{
							SwapFilter(players[i], CS_TEAM_T);
						}
						else
						{
							ChangeTeam(players[i]);
							SetImmunity(players[i], true);
						}
					}
				}
			}
			else // если должны получить определенную пропорцию
			{
				if(GetTeamClientCount(CS_TEAM_CT) > 1 || GetTeamClientCount(CS_TEAM_T) > 1)
				{
					if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue || GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
					{
						if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(players[i]) == CS_TEAM_CT)
							{
								if(IsPlayerBannedTeam(players[i], CS_TEAM_T))
								{
									continue; 
								}
								
								if(IsPlayerImmunity(players[i]))
								{
									continue; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(players[i], CS_TEAM_CT);
								}
								else
								{
									ChangeTeam(players[i]);
									SetImmunity(players[i], true);
								}
								
								continue;
							}
							else if(GetTeamClientCount(CS_TEAM_T) >= gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(players[i]) == CS_TEAM_CT)
							{
								MyChangeClientTeam(players[i], CS_TEAM_SPECTATOR);
							}
						}
						
						if(GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(players[i]) == CS_TEAM_T)
							{
								if(IsPlayerBannedTeam(players[i], CS_TEAM_CT))
								{
									continue; 
								}
								
								if(IsPlayerImmunity(players[i]))
								{
									continue; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(players[i], CS_TEAM_T);
								}
								else
								{
									ChangeTeam(players[i]);
									SetImmunity(players[i], true);
								}
								
								continue;
							}
							else if(GetTeamClientCount(CS_TEAM_CT) >= gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(players[i]) == CS_TEAM_T)
							{
								MyChangeClientTeam(players[i], CS_TEAM_SPECTATOR);
							}
						}
					}
					else if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_CT) > GetTeamClientCount(CS_TEAM_T) + 1)
					{
						if(GetClientTeam(players[i]) == CS_TEAM_CT)
						{
							if(IsPlayerBannedTeam(players[i], CS_TEAM_T))
							{
								continue; 
							}
							
							if(IsPlayerImmunity(players[i]))
							{
								continue; 
							}
							
							if(g_bSwapFilters)
							{
								SwapFilter(players[i], CS_TEAM_CT);
							}
							else
							{
								ChangeTeam(players[i]);
								SetImmunity(players[i], true);
							}
						}
					}
					else if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue && GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT) + 1)
					{
						if(GetClientTeam(players[i]) == CS_TEAM_T)
						{
							if(IsPlayerBannedTeam(players[i], CS_TEAM_CT))
							{
								continue; 
							}
							
							if(IsPlayerImmunity(players[i]))
							{
								continue; 
							}
							
							if(g_bSwapFilters)
							{
								SwapFilter(players[i], CS_TEAM_T);
							}
							else
							{
								ChangeTeam(players[i]);
								SetImmunity(players[i], true);
							}
						}
					}
				}
			}
		}
	}
	else if(client != 0 && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client))
	{
		int Cts = GetTeamClientCount(CS_TEAM_CT);
			
		if(Cts == 0)
		{
			Cts++;
		}
		
		if(!gc_iPreciseAutoBalnce.BoolValue && gc_iRatio.BoolValue)
		{
			if((GetClientTeam(client) == CS_TEAM_SPECTATOR ||  GetClientTeam(client) == CS_TEAM_NONE) && GetTeamClientCount(CS_TEAM_CT) > 1 && float(GetTeamClientCount(CS_TEAM_T)) / float(GetTeamClientCount(CS_TEAM_CT)) < gc_iRatio.IntValue)
			{
				int factor = RoundToCeil(float(GetTeamClientCount(CS_TEAM_T)) / gc_iRatio.FloatValue); // кол-во доступных игроков за КТ
				
				if(IsPlayerImmunity(client)) 
				{
					return; 
				}	
				
				if(Cts + 1 >= factor) // проверяем слот т.к. спектатор будет подключен к кт
				{
					if(IsPlayerBannedTeam(client, CS_TEAM_T))
					{
						return; 
					}
					ChangeTeamSolo(client, CS_TEAM_T);
					SetImmunity(client, true);
				}
				else
				{
					if(IsPlayerBannedTeam(client, CS_TEAM_CT))
					{
						return; 
					}
					ChangeTeamSolo(client, CS_TEAM_CT);
					SetImmunity(client, true);
				}
			}
			else if((GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE) && float(GetTeamClientCount(CS_TEAM_T)) / float(Cts) > gc_iRatio.IntValue)
			{
				if(IsPlayerImmunity(client)) 
				{
					return; 
				}
				
				if(float(GetTeamClientCount(CS_TEAM_T) - 1) / float(GetTeamClientCount(CS_TEAM_CT) + 1) > gc_iRatio.IntValue)
				{
					if(IsPlayerBannedTeam(client, CS_TEAM_CT))
					{
						return; 
					}
					ChangeTeamSolo(client, CS_TEAM_CT);
					SetImmunity(client, true);
				}
			}
		}
		else 
		{
			if(GetTeamClientCount(CS_TEAM_CT) > 1 || GetTeamClientCount(CS_TEAM_T) > 1)
			{
				if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue || GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
				{
					if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(client) == CS_TEAM_CT)
							{
								if(IsPlayerBannedTeam(client, CS_TEAM_CT))
								{
									return; 
								}
								
								if(IsPlayerImmunity(client))
								{
									return; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(client, CS_TEAM_T);
								}
								else
								{
									ChangeTeam(client);
									SetImmunity(client, true);
								}
								
								return;
							}
							else if(GetTeamClientCount(CS_TEAM_T) >= gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(client) == CS_TEAM_CT)
							{
								MyChangeClientTeam(client, CS_TEAM_SPECTATOR);
							}
						}
						
						if(GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(client) == CS_TEAM_T)
							{
								if(IsPlayerBannedTeam(client, CS_TEAM_T))
								{
									return; 
								}
								
								if(IsPlayerImmunity(client))
								{
									return; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(client, CS_TEAM_CT);
								}
								else
								{
									ChangeTeam(client);
									SetImmunity(client, true);
								}
								
								return;
							}
							else if(GetTeamClientCount(CS_TEAM_CT) >= gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(client) == CS_TEAM_T)
							{
								MyChangeClientTeam(client, CS_TEAM_SPECTATOR);
							}
						}
				}
				else if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_CT) > GetTeamClientCount(CS_TEAM_T) + 1)
				{
					if(GetClientTeam(client) == CS_TEAM_CT)
					{
						if(IsPlayerBannedTeam(client, CS_TEAM_T))
						{
							return; 
						}

						if(IsPlayerImmunity(client))
						{
							return; 
						}
							
						if(g_bSwapFilters)
						{
							SwapFilter(client, CS_TEAM_CT);
						}
						else
						{
							ChangeTeam(client);
							SetImmunity(client, true);
						}
					}
				}
				else if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT) + 1)
				{
					if(GetClientTeam(client) == CS_TEAM_T)
					{
						if(IsPlayerBannedTeam(client, CS_TEAM_CT))
						{
							return; 
						}
						
						if(IsPlayerImmunity(client))
						{
							return; 
						}
						
						if(g_bSwapFilters)
						{
							SwapFilter(client, CS_TEAM_T);
						}
						else
						{
							ChangeTeam(client);
							SetImmunity(client, true);
						}
					}
				}
			}
		}
	}
}

public void TRelationCT(int client)
{
	if((GetTeamClientCount(CS_TEAM_CT) != 0 || GetTeamClientCount(CS_TEAM_T) != 0) && client == 0)
	{
		int clients = 0; 
		int ix = 0; 
		
		for(int i = 1;i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
			{
				clients++;
			}
		}
		
		int[] players = new int[clients]; 
		
		for(int i = 1;i <= MaxClients; ++i) 
		{
			if(IsClientInGame(i))
			{
				players[ix] = i;
				ix++;
			}
		}
		
		for(int i = 0;i < clients; ++i) 
		{
			int tmp = players[i];
			players[i] = players[GetRandomInt(0, clients - 1)];
			players[GetRandomInt(0, clients - 1)] = tmp;
		}
		
		for(int i = 0; i < clients; ++i)
		{
			int Ts = GetTeamClientCount(CS_TEAM_T);
			
			if(Ts == 0)
			{
				Ts++;
			}
			
			if(!gc_iPreciseAutoBalnce.BoolValue && gc_iRatio.BoolValue)
			{
				if(IsClientInGame(players[i]) && GetClientTeam(players[i]) == CS_TEAM_T && GetTeamClientCount(CS_TEAM_T) > 1 &&  GetTeamClientCount(CS_TEAM_CT) / GetTeamClientCount(CS_TEAM_T) < gc_iRatio.IntValue)
				{
					int factor = RoundToCeil(float(GetTeamClientCount(CS_TEAM_CT)) / gc_iRatio.FloatValue); // кол-во доступных игроков за КТ
					
					if(Ts > factor)
					{
						if(IsPlayerBannedTeam(players[i], CS_TEAM_T))
						{
							continue; 
						}
						if(IsPlayerImmunity(players[i]))
						{
							continue; // если у игрока иммунитет - пропускаем итерацию 
						}
						if(g_bSwapFilters)
						{
							SwapFilter(players[i], CS_TEAM_T);
						}
						else												
						{
							ChangeTeam(players[i]);
							SetImmunity(players[i], true);
						}
					}
				}
				else if(IsClientInGame(players[i]) && GetClientTeam(players[i]) == CS_TEAM_CT && float(GetTeamClientCount(CS_TEAM_CT)) / float(Ts) > gc_iRatio.IntValue)
				{
					if(float(GetTeamClientCount(CS_TEAM_CT) - 1) / float(GetTeamClientCount(CS_TEAM_T) + 1) > gc_iRatio.IntValue)
					{
						if(IsPlayerBannedTeam(players[i], CS_TEAM_CT))
						{
							continue; 
						}
						if(IsPlayerImmunity(players[i]))
						{
							continue; 
						}
						if(g_bSwapFilters)
						{
							SwapFilter(players[i], CS_TEAM_CT);
						}
						else
						{
							ChangeTeam(players[i]);
							SetImmunity(players[i], true);
						}
					}
				}
			}
			else
			{
				if(GetTeamClientCount(CS_TEAM_CT) > 1 || GetTeamClientCount(CS_TEAM_T) > 1)
				{
					if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue || GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
					{
						if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(players[i]) == CS_TEAM_CT)
							{
								if(IsPlayerBannedTeam(players[i], CS_TEAM_T))
								{
									continue; 
								}
								
								if(IsPlayerImmunity(players[i]))
								{
									continue; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(players[i], CS_TEAM_CT);
								}
								else
								{
									ChangeTeam(players[i]);
									SetImmunity(players[i], true);
								}
								
								continue;
							}
							else if(GetTeamClientCount(CS_TEAM_T) >= gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(players[i]) == CS_TEAM_CT)
							{
								MyChangeClientTeam(players[i], CS_TEAM_SPECTATOR);
							}
						}
						
						if(GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(players[i]) == CS_TEAM_T)
							{
								if(IsPlayerBannedTeam(players[i], CS_TEAM_CT))
								{
									continue; 
								}
								
								if(IsPlayerImmunity(players[i]))
								{
									continue; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(players[i], CS_TEAM_T);
								}
								else
								{
									ChangeTeam(players[i]);
									SetImmunity(players[i], true);
								}
								
								continue;
							}
							else if(GetTeamClientCount(CS_TEAM_CT) >= gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(players[i]) == CS_TEAM_T)
							{
								MyChangeClientTeam(players[i], CS_TEAM_SPECTATOR);
							}
						}
					}
					else if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_CT) > GetTeamClientCount(CS_TEAM_T) + 1)
					{
						if(GetClientTeam(players[i]) == CS_TEAM_CT)
						{
							if(IsPlayerBannedTeam(players[i], CS_TEAM_T))
							{
								continue; 
							}
							
							if(IsPlayerImmunity(players[i]))
							{
								continue; 
							}
							
							if(g_bSwapFilters)
							{
								SwapFilter(players[i], CS_TEAM_CT);
							}
							else
							{
								ChangeTeam(players[i]);
								SetImmunity(players[i], true);
							}
						}
					}
					else if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT) + 1)
					{
						if(GetClientTeam(players[i]) == CS_TEAM_T)
						{
							if(IsPlayerBannedTeam(players[i], CS_TEAM_CT))
							{
								continue; 
							}
							
							if(IsPlayerImmunity(players[i]))
							{
								continue; 
							}
							
							if(g_bSwapFilters)
							{
								SwapFilter(players[i], CS_TEAM_T);
							}
							else
							{
								ChangeTeam(players[i]);
								SetImmunity(players[i], true);
							}
						}
					}
				}
			}
		}
	}
	else if(client != 0 && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client))
	{
		int Ts = GetTeamClientCount(CS_TEAM_T);
			
		if(Ts == 0)
		{
			Ts++;
		}
		
		if(!gc_iPreciseAutoBalnce.BoolValue && gc_iRatio.BoolValue)
		{
			if((GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE) && GetTeamClientCount(CS_TEAM_T) > 1 &&  float(GetTeamClientCount(CS_TEAM_CT)) / float(GetTeamClientCount(CS_TEAM_T)) < gc_iRatio.IntValue)
			{
				int factor = RoundToCeil(float(GetTeamClientCount(CS_TEAM_T)) / gc_iRatio.FloatValue); // кол-во доступных игроков за КТ
						
				if(IsPlayerImmunity(client))
				{
					return; 
				}
						
				if(Ts + 1 >= factor) // проверяем слот т.к. спектатор будет подключен к кт
				{
					if(IsPlayerBannedTeam(client, CS_TEAM_CT))
					{
						return; 
					}
					ChangeTeamSolo(client, CS_TEAM_CT);
					SetImmunity(client, true);
				}
				else
				{
					if(IsPlayerBannedTeam(client, CS_TEAM_T))
					{
						return; 
					}
					ChangeTeamSolo(client, CS_TEAM_T);
					SetImmunity(client, true);
				}
			}
			else if((GetClientTeam(client) == CS_TEAM_SPECTATOR || GetClientTeam(client) == CS_TEAM_NONE) && float(GetTeamClientCount(CS_TEAM_CT)) / float(Ts) > gc_iRatio.IntValue)
			{
				if(IsPlayerImmunity(client))
				{
					return; 
				}
				
				if(float(GetTeamClientCount(CS_TEAM_CT)) / float(GetTeamClientCount(CS_TEAM_T) + 1) >= gc_iRatio.IntValue)
				{
					if(IsPlayerBannedTeam(client, CS_TEAM_T))
					{
						return; 
					}
					ChangeTeamSolo(client, CS_TEAM_T);
					SetImmunity(client, true);
				}
			}
		}
		else
		{
			if(GetTeamClientCount(CS_TEAM_CT) > 1 || GetTeamClientCount(CS_TEAM_T) > 1)
			{
				if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue || GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
				{
					if(GetTeamClientCount(CS_TEAM_CT) > gc_iPreciseAutoBalanceCt.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(client) == CS_TEAM_CT)
							{
								if(IsPlayerBannedTeam(client, CS_TEAM_T))
								{
									return; 
								}
								
								if(IsPlayerImmunity(client))
								{
									return; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(client, CS_TEAM_CT);
								}
								else
								{
									ChangeTeam(client);
									SetImmunity(client, true);
								}
								
								return;
							}
							else if(GetTeamClientCount(CS_TEAM_T) >= gc_iPreciseAutoBalanceT.IntValue && GetClientTeam(client) == CS_TEAM_CT)
							{
								MyChangeClientTeam(client, CS_TEAM_SPECTATOR);
							}
						}
						
						if(GetTeamClientCount(CS_TEAM_T) > gc_iPreciseAutoBalanceT.IntValue)
						{
							if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(client) == CS_TEAM_T)
							{
								if(IsPlayerBannedTeam(client, CS_TEAM_CT))
								{
									return; 
								}
								
								if(IsPlayerImmunity(client))
								{
									return; 
								}
								
								if(g_bSwapFilters)
								{
									SwapFilter(client, CS_TEAM_T);
								}
								else
								{
									ChangeTeam(client);
									SetImmunity(client, true);
								}
								
								return;
							}
							else if(GetTeamClientCount(CS_TEAM_CT) >= gc_iPreciseAutoBalanceCt.IntValue && GetClientTeam(client) == CS_TEAM_T)
							{
								MyChangeClientTeam(client, CS_TEAM_SPECTATOR);
							}
						}
				}
				else if(GetTeamClientCount(CS_TEAM_T) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_CT) > GetTeamClientCount(CS_TEAM_T) + 1)
				{
					if(GetClientTeam(client) == CS_TEAM_CT)
					{
						if(IsPlayerBannedTeam(client, CS_TEAM_T))
						{
							return; 
						}

						if(IsPlayerImmunity(client))
						{
							return; 
						}
							
						if(g_bSwapFilters)
						{
							SwapFilter(client, CS_TEAM_CT);
						}
						else
						{
							ChangeTeam(client);
							SetImmunity(client, true);
						}
					}
				}
				else if(GetTeamClientCount(CS_TEAM_CT) < gc_iPreciseAutoBalanceT.IntValue && GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT) + 1)
				{
					if(GetClientTeam(client) == CS_TEAM_T)
					{
						if(IsPlayerBannedTeam(client, CS_TEAM_CT))
						{
							return; 
						}
						
						if(IsPlayerImmunity(client))
						{
							return; 
						}
						
						if(g_bSwapFilters)
						{
							SwapFilter(client, CS_TEAM_T);
						}
						else
						{
							ChangeTeam(client);
							SetImmunity(client, true);
						}
					}
				}
			}
		}
	}
}

public void SwapTeamPlayers(int client1, int client2)
{
	if(g_bSwapTeamFlag[client1][client2] && g_bSwapTeamFlag[client2][client1])
	{
		g_bSwapTeamPair[client1][client2] = false;
		g_bSwapTeamPair[client2][client1] = false;
		g_bSwapTeamFlag[client1][client2] = false;
		g_bSwapTeamFlag[client2][client1] =  false;
		
		if(((CS_TEAM_CT == GetClientTeam(client1) || CS_TEAM_CT == GetClientTeam(client2)) && (CS_TEAM_T == GetClientTeam(client1) || CS_TEAM_T == GetClientTeam(client2))) || 
		((CS_TEAM_SPECTATOR == GetClientTeam(client1) || CS_TEAM_SPECTATOR == GetClientTeam(client2)) && (CS_TEAM_CT == GetClientTeam(client1) || CS_TEAM_CT == GetClientTeam(client2) || CS_TEAM_T == GetClientTeam(client1) || CS_TEAM_T == GetClientTeam(client2))))
		{

			if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
			{
				g_bSwapped[client1] = true;
			}
			
			if(gc_bOnTakeDamageSwappedPlayers.BoolValue)
			{
				g_bSwapped[client2] = true;
			}
			
			int tmp = GetClientTeam(client1);
			MyChangeClientTeam(client1, GetClientTeam(client2));
			MyChangeClientTeam(client2, tmp);
			
			if(gc_bPluginMessages.BoolValue)
			{
				CPrintToChat(client1, "%s %t", g_sPrefix, "Successfully_Changed_Team"); 
				CPrintToChat(client2, "%s %t", g_sPrefix, "Successfully_Changed_Team"); 
			}
		}
		else if(GetClientTeam(client1) == GetClientTeam(client2))
		{
			if(gc_bPluginMessages.BoolValue)
			{
				CPrintToChat(client1, "%s %t", g_sPrefix, "Same_Team");
				CPrintToChat(client2, "%s %t", g_sPrefix, "Same_Team");
			}
		}
	}
}

///////////////////////////////////////////////////
// 												 //
//			    FILTER FUNCTIONS				 //
//												 //
///////////////////////////////////////////////////

public int FilterKD(int team)
{
	int index = 0;
	
	switch(gc_iSwapFilterKD.IntValue)
	{
		case 1:
		{
			float MaxKD = 0.0;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int deaths = GetClientDeaths(i);
					int frags = GetClientFrags(i);
					
					if(!deaths)
					{
						deaths = 1;
					}
					
					if(frags < 0)
					{
						frags = 0;
					}
					
					if(frags / deaths > MaxKD)
					{
						MaxKD = float(frags) / float(deaths);
						index = i;
					}
				}
			}
		}
		case 2:
		{
			float MinKD = 3.4e38;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int deaths = GetClientDeaths(i);
					int frags = GetClientFrags(i);
					
					if(!deaths)
					{
						deaths = 1;
					}
					
					if(frags < 0)
					{
						frags = 0;
					}
					
					if(frags / deaths < MinKD)
					{
						MinKD = float(frags) / float(deaths);
						index = i;
					}
				}
			}
		}
	}
	
	return index;
}

public int FilterTime(int team)
{
	int index = 0;
	
	switch(gc_iSwapFilterTime.IntValue)
	{
		case 1:
		{
			float MaxTime = 0.0;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue != 3 || ( IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					float time = GetClientTime(i);
					
					if(time > MaxTime)
					{
						MaxTime = time;
						index = i;
					}
				}
			}
		}
		case 2:
		{
			float MinTime = 3.4e38;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					float time = GetClientTime(i);
					
					if(time < MinTime)
					{
						MinTime = time;
						index = i;
					}
				}
			}
		}
	}
	
	return index;
}

public int FilterMoney(int team)
{
	int index = 0;
	
	switch(gc_iSwapFilterMoney.IntValue)
	{
		case 1:
		{	
			int MaxMoney = -1;
		
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int money = GetEntProp(i, Prop_Send, "m_iAccount");
					
					if(money > MaxMoney)
					{
						MaxMoney = money;
						index = i;
					}
				}
			}
		}
		case 2:
		{
			int MinMoney = 2147483647;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int money = GetEntProp(i, Prop_Send, "m_iAccount");
					
					if(money < MinMoney)
					{
						MinMoney = money;
						index = i;
					}
				}
			}
		}
	}
	
	return index;
}

public int FilterPing(int team)
{
	int index = 0;
	
	switch(gc_iSwapFilterPing.IntValue)
	{
		case 1:
		{	
			float MaxPing = 0.0;
		
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					float ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;
					
					if(ping > MaxPing)
					{
						MaxPing = ping;
						index = i;
					}
				}
			}
		}
		case 2:
		{
			float MinPing = 3.4e38;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					float ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;
					
					if(ping < MinPing)
					{
						MinPing = ping;
						index = i;
					}
				}
			}
		}
	}
	
	return index;
}

public int FilterMVP(int team)
{
	int index = 0;
	
	switch(gc_iSwapFilterMVP.IntValue)
	{
		case 1:
		{	
			int MaxMVP = 0;
		
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int MVP = CS_GetMVPCount(i);
					
					if(MVP > MaxMVP)
					{
						MaxMVP = MVP;
						index = i;
					}
				}
			}
		}
		case 2:
		{
			int MinMVP = 2147483647;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int MVP = CS_GetMVPCount(i);
					
					if(MVP < MinMVP)
					{
						MinMVP = MVP;
						index = i;
					}
				}
			}
		}
	}
	
	return index;
}

public int FilterAdmin(int team)
{
	int index = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && GetUserAdmin(i) != INVALID_ADMIN_ID)
		{
			return index;
		}
	}
	
	return index;
}

public int FilterFactorHeadshot(int team)
{
	int index = 0;
	
	switch(gc_iSwapFilterFactorHeadshot.IntValue)
	{
		case 1:
		{	
			float MaxHeadshot = 0.0;
		
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int Headshots = GetEntProp(i, Prop_Send, "m_iMatchStats_HeadShotKills");
					int frags = GetClientFrags(i);
					
					if(frags == 0)
					{
						frags = 1;
					}
					
					float factorHeadshot = float(Headshots) / float(frags);
					
					if(factorHeadshot > MaxHeadshot)
					{
						MaxHeadshot = factorHeadshot;
						index = i;
					}
				}
			}
		}
		case 2:
		{
			float MinHeadshot = 3.4e38;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team &&  gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					int Headshots = GetEntProp(i, Prop_Send, "m_iMatchStats_HeadShotKills");
					int frags = GetClientFrags(i);
					
					float factorHeadshot = float(Headshots) / float(frags);
					
					if(factorHeadshot < MinHeadshot)
					{
						MinHeadshot = factorHeadshot;
						index = i;
					}
				}
			}
		}
	}
	
	return index;
}

public int FilterTimeTeam(int team)
{
	int index = 0;
	
	switch(gc_iSwapFilterTimeTeam.IntValue)
	{
		case 1:
		{
			float MaxTime = 0.0;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue != 3 || ( IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					float time = GetClientTime(i) - g_flTimeTeam[i];
					
					if(time > MaxTime)
					{
						MaxTime = time;
						index = i;
					}
				}
			}
		}
		case 2:
		{
			float MinTime = 3.4e38;
			
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue != 3 || (IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) && gc_iSwapFilterAdmin.IntValue == 3 && GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					float time = GetClientTime(i) - g_flTimeTeam[i];
					
					if(time < MinTime)
					{
						MinTime = time;
						index = i;
					}
				}
			}
		}
	}
	
	return index;
}

///////////////////////////////////////////////////
// 												 //
//			  ADMIN BALANCE FUNCTIONS			 //
//												 //
///////////////////////////////////////////////////

public void BalancePlayersKD(int mode)
{
	int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	
	int[] players = new int[clients];

	int ix = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
		{	
			players[ix] = i;
			ix++;
		}
	}
	
	for(int i = 0; i < ix; ++i)
	{
		for(int j = 0; j < ix - 1; ++j)
		{
			if(KD(players[j]) > KD(players[j+1]))
			{
				int tmp = players[j+1];
				players[j+1] = players[j];
				players[j] = tmp;
			}
		}
	}
	
	Distribution(players, ix, mode);
}

public void BalancePlayersTime(int mode)
{
	int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	
	int[] players = new int[clients];

	int ix = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
		{	
			players[ix] = i;
			ix++;
		}
	}
	
	for(int i = 0; i < ix; ++i)
	{
		for(int j = 0; j < ix - 1; ++j)
		{
			if(GetClientTime(players[j]) > GetClientTime(players[j+1]))
			{
				int tmp = players[j+1];
				players[j+1] = players[j];
				players[j] = tmp;
			}
		}
	}
	
	Distribution(players, ix, mode);
}

public void BalancePlayersMVP(int mode)
{
	int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	
	int[] players = new int[clients];

	int ix = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
		{	
			players[ix] = i;
			ix++;
		}
	}
	
	for(int i = 0; i < ix; ++i)
	{
		for(int j = 0; j < ix - 1; ++j)
		{
			if(CS_GetMVPCount(players[j]) > CS_GetMVPCount(players[j+1]))
			{
				int tmp = players[j+1];
				players[j+1] = players[j];
				players[j] = tmp;
			}
		}
	}
	
	Distribution(players, ix, mode);
}

public void BalancePlayersTimeTeam(int mode)
{
	int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	
	int[] players = new int[clients];

	int ix = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
		{	
			players[ix] = i;
			ix++;
		}
	}
	
	for(int i = 0; i < ix; ++i)
	{
		for(int j = 0; j < ix - 1; ++j)
		{
			float time1 = GetClientTime(players[j]) - g_flTimeTeam[j];
			float time2 = GetClientTime(players[j + 1]) - g_flTimeTeam[j +1 ];
			
			if(time1 > time2)
			{
				int tmp = players[j+1];
				players[j+1] = players[j];
				players[j] = tmp;
			}
		}
	}
	
	Distribution(players, ix, mode);
}

public void BalancePlayersMoney(int mode)
{
	int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	
	int[] players = new int[clients];

	int ix = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
		{	
			players[ix] = i;
			ix++;
		}
	}
	
	for(int i = 0; i < ix; ++i)
	{
		for(int j = 0; j < ix - 1; ++j)
		{
			int money1 = GetEntProp(players[j], Prop_Send, "m_iAccount");
			int money2 = GetEntProp(players[j + 1], Prop_Send, "m_iAccount");
			
			if(money1 > money2)
			{
				int tmp = players[j+1];
				players[j+1] = players[j];
				players[j] = tmp;
			}
		}
	}
	
	Distribution(players, ix, mode);
}

public void BalancePlayersPing(int mode)
{
	int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	
	int[] players = new int[clients];

	int ix = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
		{	
			players[ix] = i;
			ix++;
		}
	}
	
	for(int i = 0; i < ix; ++i)
	{
		for(int j = 0; j < ix - 1; ++j)
		{
			float ping1 = GetClientAvgLatency(players[j], NetFlow_Outgoing) * 1024;
			float ping2 = GetClientAvgLatency(players[j + 1], NetFlow_Outgoing) * 1024;
			
			if(ping1 > ping2)
			{
				int tmp = players[j+1];
				players[j+1] = players[j];
				players[j] = tmp;
			}
		}
	}
	
	Distribution(players, ix, mode);
}

public void BalancePlayersHeadshot(int mode)
{
	int clients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	
	int[] players = new int[clients];

	int ix = 0;
	
	for(int i = 1;i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR)
		{	
			players[ix] = i;
			ix++;
		}
	}
	
	for(int i = 0; i < ix; ++i)
	{
		for(int j = 0; j < ix - 1; ++j)
		{
			int headshots1 = GetEntProp(players[j], Prop_Send, "m_iMatchStats_HeadShotKills");
			int headshots2 = GetEntProp(players[j + 1], Prop_Send, "m_iMatchStats_HeadShotKills");
			
			if(headshots1 > headshots2)
			{
				int tmp = players[j+1];
				players[j+1] = players[j];
				players[j] = tmp;
			}
		}
	}
	
	Distribution(players, ix, mode);
}