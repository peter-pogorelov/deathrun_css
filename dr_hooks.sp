public Action:EHK_OnClientDisconnect_Pre( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
		if( DR_GetClientCountEx( CS_TEAM_CT ) >= 2 )
		{
			if( IsClientInGame( client ) && GetClientTeam( client ) == CS_TEAM_T )
			{
				new String:szClientModel[ PLATFORM_MAX_PATH ];
				new Float:fPlayerPos[3];
				new Float:fPlayerAngles[3];
				
				new terrorist = DR_GetRandomPlayer( CS_TEAM_CT, DR_GetClientCountEx( CS_TEAM_CT, true ) > 0 );
				GetClientModel( client, szClientModel, sizeof( szClientModel ) );
				
				if( terrorist != -1 )
				{
#if !defined DEBUG_VERSION
					PrintToChatAll( DR_MSG, "terrorist_leave_game" );
#else
					PrintToChatAll( "terrorist_leave_team" );
#endif
					DR_BlockTTeamJoining( );
					
					CS_SwitchTeam( terrorist, CS_TEAM_T );
					
					GetClientAbsOrigin( client, fPlayerPos );
					GetClientAbsAngles( client, fPlayerAngles );
					
					new Handle:hDataPack = CreateDataPack( );
					
					CreateDataTimer( ON_DISCONNECT_CHANGES, Timer_DR_TeleportTimer, hDataPack );
					
					WritePackCell( hDataPack, terrorist );
					
					WritePackFloat( hDataPack, fPlayerPos[ 0 ] );
					WritePackFloat( hDataPack, fPlayerPos[ 1 ] );
					WritePackFloat( hDataPack, fPlayerPos[ 2 ] );
					
					WritePackFloat( hDataPack, fPlayerAngles[ 0 ] );
					WritePackFloat( hDataPack, fPlayerAngles[ 1 ] );
					WritePackFloat( hDataPack, fPlayerAngles[ 2 ] );
					
					new Float:fPlayerSpeed = GetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue" );
					
					SetEntityModel( terrorist, szClientModel );
					SetEntityRenderMode( terrorist, RENDER_TRANSCOLOR );
					SetEntityRenderColor( terrorist, 255, 255, 255, 255 );
					SetEntityGravity( terrorist, GetEntityGravity( client ) );
					SetEntityHealth( terrorist, 100 );
					SetEntPropFloat( terrorist, Prop_Data, "m_flLaggedMovementValue", fPlayerSpeed );
				}
			}
		}
		
		g_iPlayersFrags[ client ] = 0;
	
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			if( g_iScoutsData[ client ] != SCOUT_FREE_SLOT )
			{
				if( IsValidEntity( g_iScoutsData[ client ] ) )
				{
					Scouts_DissolveScout( client );
				}
			
				g_iScoutsData[ client ] = SCOUT_FREE_SLOT;
			}
		}
	}
}

public Action:EHK_OnRoundStart_Pre( Handle:event, const String:name[], bool:dontBroadcast ) // Could do not i want
{
	if( GetConVarBool( dr_enabled ) )
	{
		DR_AllowTTeamJoining( );
	
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			Scouts_ResetScouts( );
		}
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame( i ) )
			{
				if( g_iPlayersFrags[ i ] > GetClientFrags( i ) )
				{
					SetEntProp( i, Prop_Data, "m_iFrags", g_iPlayersFrags[ i ] );
				}
				else
				{
					g_iPlayersFrags[ i ] = GetClientFrags( i );
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:EHK_OnRoundEnd_Pre( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		new String:szMessage[ 256 ];
		new bool:bGiveBonusFrag = false;
		
		strcopy( szMessage, sizeof( szMessage ), "\x03" );
		
		if( DR_GetClientCountEx( CS_TEAM_T ) && !g_bFirstRound )
		{
			if( GetEventInt( event, "winner" ) == CS_TEAM_T )
			{
				if( GetClientCount( ) > GetConVarInt( dr_clients_to_get_frag ) )
				{
					new iFragsForWin = GetConVarInt( dr_frags_for_ter_win );
					
					for( new i = 1; i <= MaxClients; i++ )
					{
						if( IsClientInGame( i ) && GetClientTeam( i ) == CS_TEAM_T && IsPlayerAlive( i ) )
						{
							if( g_iPlayersFrags[ i ] == GetClientFrags( i ) )
							{
								new String:szClientName[ 128 ];
								
								GetClientName( i, szClientName, sizeof( szClientName ) );
								StrCat( szMessage, sizeof( szMessage ), szClientName );
								StrCat( szMessage, sizeof( szMessage ), "\x01, \x03" );
								
								SetEntProp( i, Prop_Data, "m_iFrags", g_iPlayersFrags[ i ] + iFragsForWin );
								
								bGiveBonusFrag = true;
							}
						}
					}
					
					if( bGiveBonusFrag )
					{
						new iMessageLen = strlen( szMessage );
						
						szMessage[ iMessageLen - 2 ] = '\0';
						szMessage[ iMessageLen - 3 ] = '.';
						
#if !defined DEBUG_VERSION
						PrintToChatAll( DR_MSG, "who_has_bonus_frag", szMessage );
#else
						PrintToChatAll( "who_has_bonus_frag %s", szMessage );
#endif
					}
				}
				else
				{
#if !defined DEBUG_VERSION
					PrintToChatAll( DR_MSG, "fev_clients" );
#else
					PrintToChatAll( "fev_clients" );
#endif
				}
			}
		}
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame( i ) && IsPlayerAlive( i ) )
			{
				SetEntProp( i, Prop_Data, "m_takedamage", 0, 1 );
			}
		}
		
		g_bFirstRound = false;
		
		CreateTimer( TEAM_SWAP_DELAY, Timer_DR_TeamSwap );
	}
	
	return Plugin_Continue;
}

public Action:EHK_OnWinPannelDisplayed_Pre( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_block_win_pannel ) )
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:EHK_OnPlayerBlinded_Pre( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_block_team_flashing ) )
		{
			new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
			CreateTimer( BLOCK_BLINDING_DELAY, Timer_DR_BlockBlind, client );
		}
	}
	
	return Plugin_Continue;
}

public Action:EHK_OnFlashbangDetonated_Pre( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_block_team_flashing ) )
		{
			g_iFlashbangOwner = GetClientOfUserId( GetEventInt( event, "userid" ) );
		}
	}
}

// Unstoppable hooks
public EHK_OnPlayerSpawn_Post( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
		if( GetConVarBool( dr_bonuses_enabled ) )
		{
			Bonuses_SetClientBonuses( client );
		}
		
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			if( GetClientTeam( client ) == CS_TEAM_CT )
			{
				if( GetConVarBool( dr_auto_dispenser ) )
				{
					CreateTimer( GIVE_SCOUT_DELAY, Timer_Scouts_GiveScout, client );
				}
			}
		}
		
		if( GetConVarBool( dr_block_fall_damage ) )
		{
			SDKHook( client, SDKHook_OnTakeDamage, Hook_OnTakeDamage );
		}
		
		if( GetConVarBool( dr_noblock ) )
		{
			SetEntData( client, FindSendPropOffs( "CBaseEntity", "m_CollisionGroup" ), 2, 4, true );
		}
	}
}

public EHK_OnPlayerDeath_Post( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
		new victim = GetEventInt( event, "userid" );
		new attacker = GetEventInt( event, "attacker" );
		
		if( ( attacker == 0 || attacker == victim ) && !g_bJoiningInTeam[ client ] )
		{
			SetEntProp( client, Prop_Data, "m_iFrags", GetClientFrags( client ) + 1 );
		}
		
		SetEntProp( client, Prop_Data, "m_iDeaths", 0 );
		
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			if( g_iScoutsData[ client ] != SCOUT_FREE_SLOT )
			{
				if( IsValidEntity( g_iScoutsData[ client ] ) )
				{
					Scouts_DissolveScout( client );
				}
				
				g_iScoutsData[ client ] = SCOUT_FREE_SLOT;
			}
		}
		
		if( GetConVarBool( dr_dissolve_after_death ) )
		{
			CreateTimer( RAGDOLL_DISSOLVE_DELAY, Timer_DR_DissolveTimer, client );
		}
		
		g_bJoiningInTeam[ client ] = false;
	}
	
	return;
}

public Action:EHK_OnPlayerTeam_Pre( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( g_bTeamChangeNotice )
		{
			SetEventBroadcast( event, true );
		}
	}
}

public Action:Hook_OnTakeDamage( victim, &attacker, &inflictor, &Float:damage, &damagetype )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_bonuses_enabled) && GetConVarBool( dr_block_frag_trolling ) )
		{
			if( 1 <= attacker <= MaxClients && 1 <= victim <= MaxClients )
			{
				if( IsClientInGame( attacker ) && GetClientFrags( attacker ) >= Bonuses_GetMaxBonus( ) )
				{
					if( GetClientTeam( attacker ) != GetClientTeam( victim ) )
					{
#if !defined DEBUG_VERSION
						PrintToChat( attacker, DR_MSG, "slay_for_kill" );
#else
						PrintToChat( attacker, "slay_for_kill" );
#endif
						ForcePlayerSuicide( attacker );
						
						return Plugin_Handled;
					}
				}
			}
		}
		
		if( GetConVarBool( dr_block_fall_damage ) )
		{
			if( damagetype == DMG_FALL && GetClientTeam( victim ) == CS_TEAM_T )
			{
#if !defined DEBUG_VERSION
				PrintToChat( victim, DR_MSG, "suicide_blocked" );
#else
				PrintToChat( victim, "suicide_blocked" );
#endif
				
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Hook_WeaponCanUse( client, weapon )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			if( IsClientInGame( client ) && IsValidEntity( weapon ) )
			{
				if( Scouts_IsScout( weapon ) && weapon != g_iScoutsData[ client ] )
				{
					return Plugin_Handled;
				}
			}
		}
		
		if( GetConVarBool( dr_prevent_collusion ) )
		{
			new iWeaponOwner = GetEntPropEnt( weapon, Prop_Data, "m_hOwner" );
			
			if( GetClientTeam( client ) == CS_TEAM_T )
			{
				if( 0 < iWeaponOwner <= MaxClients )
				{
					if( IsClientInGame( iWeaponOwner ) && GetClientTeam( iWeaponOwner ) == CS_TEAM_CT && IsPlayerAlive( iWeaponOwner ) )
					{
						return Plugin_Handled;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Hook_PreventTrapBlocking( entity, other )
{
	if( GetConVarBool( dr_enabled ) && GetConVarBool( dr_scouts_enabled ) )
	{
		if( Scouts_IsScout( entity ) )
		{
			new owner = Scouts_GetOwner( entity );
		
			if( other > MAXPLAYERS && !Scouts_InAction( owner ) )
			{
				Scouts_SetAction( true, owner );
			
				Scouts_ReturnToOwner( owner );
			}
		}
	}
	
	return Plugin_Continue;
}