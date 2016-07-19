#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <smlib>

#define DR_MSG "\x03[DeathRun] \x01%t"
#define PLUGIN_VERSION "1.0"

//#define DEBUG_VERSION

//Timers marco
#define ON_DISCONNECT_CHANGES 0.03
#define TEAM_CHANGE_DELAY 0.005
#define SCOUT_RETURN_DELAY 0.05
#define TEAM_SWAP_DELAY 2.0
#define BLOCK_BLINDING_DELAY 0.01
#define GIVE_SCOUT_DELAY 0.1
#define RAGDOLL_DISSOLVE_DELAY 1.5

//Scouts macro
#define SCOUT_FREE_SLOT -1

public Plugin:myinfo =
{
	name = "QUAD DeathRun Manager",
	author = "Push#STEAM_0:0:21470394",
	description = "Manages players on deathrun maps.",
	version = PLUGIN_VERSION,
	url = "http://css-quad.ru"
};

//DR Stuff
new Handle:dr_enabled =						INVALID_HANDLE;
new Handle:dr_block_suicide =				INVALID_HANDLE;
new Handle:dr_block_fall_damage =			INVALID_HANDLE;
new Handle:dr_clients_to_get_frag =		INVALID_HANDLE;
new Handle:dr_noblock =						INVALID_HANDLE;
new Handle:dr_ratio =							INVALID_HANDLE;
new Handle:dr_block_team_flashing =		INVALID_HANDLE;
new Handle:dr_frags_for_ter_win =			INVALID_HANDLE;
new Handle:dr_block_win_pannel =			INVALID_HANDLE;
new Handle:dr_dissolve_after_death =		INVALID_HANDLE;
new Handle:dr_prevent_collusion =			INVALID_HANDLE;
new Handle:dr_allow_set_terrorists =		INVALID_HANDLE;
new Handle:dr_all_maps =						INVALID_HANDLE;

//Bonuses stuff
new Handle:dr_bonuses_enabled =			INVALID_HANDLE;
new Handle:dr_block_frag_trolling =		INVALID_HANDLE;

new String:g_szPathToBonuses[ PLATFORM_MAX_PATH ];
new bool:g_bIsOnLadder[ MAXPLAYERS + 1 ];
new Float:g_fPlayerGravity[ MAXPLAYERS + 1 ];


//Scouts stuff
new Handle:dr_scouts_enabled =			INVALID_HANDLE;
new Handle:dr_scouts_colored =			INVALID_HANDLE;
new Handle:dr_auto_dispenser =			INVALID_HANDLE;
new Handle:dr_scouts_block_protect =	INVALID_HANDLE;

new g_iScoutsData[ MAXPLAYERS + 1 ] = { SCOUT_FREE_SLOT, ... };
new bool:g_bScoutsInAction[ MAXPLAYERS + 1 ];

//Global stuff
new Handle:g_hPlayersInAdminQueue =		INVALID_HANDLE;

new bool:g_bForceBlockTeamJoining;
new bool:g_bFirstRound;
new bool:g_bJoiningInTeam[ MAXPLAYERS + 1 ]; // Variable for preventing bug with frags

new g_iPlayersFrags[ MAXPLAYERS + 1 ];
new g_iFlashbangOwner;

new bool:g_bTeamChangeNotice;

#include "deathrun/dr_deathrun.sp"
#include "deathrun/dr_scouts.sp"
#include "deathrun/dr_bonuses.sp"
#include "deathrun/dr_timers.sp"
#include "deathrun/dr_hooks.sp"

public OnPluginStart( )
{
#if !defined DEBUG_VERSION
	LoadTranslations( "deathrun_manager.phrases" );
#endif
	
	BuildPath( Path_SM, g_szPathToBonuses, PLATFORM_MAX_PATH, "configs/bonuses.cfg" );
	
	dr_enabled =					CreateConVar( "dr_enabled", "1", "Enable deathrun manager?" );
	dr_block_suicide =			CreateConVar( "dr_block_suicide", "1", "Block player's tries of suicide?" );
	dr_block_fall_damage =		CreateConVar( "dr_fall_damage", "1", "Block terrorist's fall damage?" );
	dr_clients_to_get_frag =	CreateConVar( "dr_clients_to_get_frag", "5", "How many clients needed to give frag to terrorists each round?" );
	dr_noblock =					CreateConVar( "dr_noblock", "1","Enable noblock on deathrun maps?" );
	dr_ratio =						CreateConVar( "dr_ratio", "0,1-18,2-24,3", "Terrorists to counter terrorists relation?" );
	dr_block_team_flashing =	CreateConVar( "dr_block_team_flashing", "1", "Block team flashing on deathrun maps?" );
	dr_frags_for_ter_win =		CreateConVar( "dr_frags_for_ter_win", "1", "Frags to terrorists' win?" );
	dr_block_win_pannel =		CreateConVar( "dr_block_win_pannel", "1", "Block win pannel on round end?" );
	dr_dissolve_after_death =	CreateConVar( "dr_dissolve_after_death", "1", "Dissolve player's ragdoll after death?" );
	dr_prevent_collusion =		CreateConVar( "dr_prevent_collusion", "0", "Prevent collusion between CT and T?" );
	dr_allow_set_terrorists =	CreateConVar( "dr_allow_set_terrorists", "1", "Allow admins to change terrorists for the next round?" );
	
	dr_bonuses_enabled =		CreateConVar( "dr_bonuses_enabled", "1", "Enable bonuses?" );
	dr_block_frag_trolling = 	CreateConVar( "dr_block_frag_trolling", "1", "Block kills by players with max frags?" );
	
	dr_scouts_block_protect =	CreateConVar( "dr_scouts_block_protect", "1", "Prevent trap blocking?" );
	dr_scouts_enabled =			CreateConVar( "dr_scouts_enabled", "1", "Enable scouts manager?" );
	dr_scouts_colored =			CreateConVar( "dr_scouts_colored", "1", "Use colored scouts?" );
	dr_auto_dispenser =			CreateConVar( "dr_auto_dispenser", "1", "Enable anto dispense of scouts?" );
	dr_all_maps =					CreateConVar( "dr_all_maps", "0", "DeathRun manager works on all types of maps." );
	
	AutoExecConfig( true, "plugin.deathrun_manager" );
	
	// DeathRun admin commands
	RegAdminCmd( "sm_move", DR_MovePlayerInTerroristsQueue, ADMFLAG_BAN );
	RegAdminCmd( "sm_getback", Scouts_ReturnScoutsCallback, ADMFLAG_BAN );
	
	// Scouts commands hooks
	RegConsoleCmd( "sm_scout", Scouts_MakeScoutCallback );
	RegConsoleCmd( "say", Scouts_BlockMessageCallback );
	RegConsoleCmd( "say_team", Scouts_BlockMessageCallback );
	
	// Deathrun commands hooks
	RegConsoleCmd( "kill", DR_BlockCommandCallback );
	RegConsoleCmd( "explode", DR_BlockCommandCallback );
	RegConsoleCmd( "joinclass", DR_BlockCommandCallback );
	
	RegConsoleCmd( "jointeam", DR_CheckTeamJoining );
	RegConsoleCmd( "spectate", DR_CheckSpectatorCallback );
	
	HookEvent( "player_spawn", EHK_OnPlayerSpawn_Post, EventHookMode_Post );
	HookEvent( "player_death", EHK_OnPlayerDeath_Post, EventHookMode_Post );
	
	HookEvent( "player_team", EHK_OnPlayerTeam_Pre, EventHookMode_Pre );
	HookEvent( "player_disconnect", EHK_OnClientDisconnect_Pre, EventHookMode_Pre );
	HookEvent( "cs_win_panel_round", EHK_OnWinPannelDisplayed_Pre, EventHookMode_Pre );
	HookEvent( "flashbang_detonate", EHK_OnFlashbangDetonated_Pre, EventHookMode_Pre );
	HookEvent( "player_blind", EHK_OnPlayerBlinded_Pre, EventHookMode_Pre );
	HookEvent( "round_end", EHK_OnRoundEnd_Pre, EventHookMode_Pre );
	HookEvent( "round_start", EHK_OnRoundStart_Pre, EventHookMode_Pre );
}

public OnConfingsExecuted()
{
	if(!GetConVarBool(dr_all_maps))
	{
		new String:szMapName[PLATFORM_MAX_PATH];
		
		GetCurrentMap( szMapName, sizeof( szMapName ) );
		
		if( !strncmp( szMapName, "dr", 2, false ) || !strncmp( szMapName, "deathrun", 8, false ) || !strncmp( szMapName, "dtka", 4, false ) )
		{
			LogMessage( "Deathrun map detected, enabling deathrun manager..." );
			SetConVarBool( dr_enabled, true );
		}
		else
		{
			LogMessage( "Deathrun map undetected, disabling deathrun manager..." );
			SetConVarBool( dr_enabled, false );
		}
	}
}

public OnGameFrame( )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_bonuses_enabled ) )
		{
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == CS_TEAM_CT )
				{
					new bool:bOldState = g_bIsOnLadder[ i ];
					
					if( !( g_bIsOnLadder[ i ] = ( GetEntityMoveType( i ) == MOVETYPE_LADDER ) ) && bOldState )
					{
						if( g_fPlayerGravity[ i ] != 1.0 )
						{
							SetEntityGravity( i, g_fPlayerGravity[ i ] );
						}
					}
				}
				else
				{
					g_bIsOnLadder[ i ] = false;
				}
			}
		}
	}
}

public OnClientPutInServer( client )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			SDKHook( client, SDKHook_WeaponCanUse, Hook_WeaponCanUse );
		}
	}
}

public OnMapStart( )
{
	g_bFirstRound = true;
	
	g_hPlayersInAdminQueue = CreateArray( );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		g_iPlayersFrags[ i ] = 0;
	}
}

public OnMapEnd( )
{
	CloseHandle( g_hPlayersInAdminQueue );
}

public OnEntityCreated( entity, const String:szClassName[] )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( IsValidEntity( entity ) )
		{
			if( StrEqual( "flashbang_projectile", szClassName ) 
			|| StrEqual( "hegrenade_projectile", szClassName ) 
			|| StrEqual( "smokegrenade_projectile", szClassName ) )
			{
				SetEntData( entity, FindSendPropOffs( "CBaseEntity", "m_CollisionGroup" ), 2, 4, true );
			}
		}
	}
}