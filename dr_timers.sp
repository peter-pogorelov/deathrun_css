public Action:Timer_Scouts_ReturnScout( Handle:hTimer, any:client )
{
	if( IsClientInGame( client ) )
	{
		if( g_iScoutsData[ client ] != SCOUT_FREE_SLOT && IsValidEntity( g_iScoutsData[ client ] ) )
		{
			new Float:fClientOrigin[3];
			
			GetClientAbsOrigin( client, fClientOrigin );
			TeleportEntity( g_iScoutsData[ client ], fClientOrigin, NULL_VECTOR, NULL_VECTOR );

#if !defined DEBUG_VERSION
			PrintToChat( client, DR_MSG, "scout_returned" );
#else
			PrintToChat( client, "scout_returned" );
#endif
		}
	}
	
	Scouts_SetAction( false, client );
	
	return Plugin_Continue;
}

public Action:Timer_Scouts_GiveScout( Handle:hTimer, any:client )
{
	Scouts_GiveScout( client );
}

public Action:Timer_DR_TeamSwap( Handle:hTimer )
{
	if( DR_GetClientCountEx( ) > 1 )
	{
		new iOldTerroristsTeam[ MAXPLAYERS + 1 ];
		new iNewTerroristsTeam[ MAXPLAYERS + 1 ];
		new iTerroristsFromQueue;
		
		new String:szCommand[32];
		GetConVarString( dr_ratio, szCommand, sizeof( szCommand ) );
		
		new iTerroristsAmount = DR_GetAmountOfTerrorists( DR_GetClientCountEx( ), DR_GetSpawnPoints( CS_TEAM_T ), szCommand );
		
		if( DR_GetClientCountEx( ) < iTerroristsAmount * 2 )
		{
#if defined DEBUG_VERSION
			LogMessage( "There is no clients for current settings.\n" );
#endif
			return Plugin_Continue;
		}
		
		for( new i = 1, k = 0; i <= MaxClients; i++ )
		{
			if( IsClientInGame( i ) && GetClientTeam( i ) == CS_TEAM_T )
			{
				iOldTerroristsTeam[ k++ ] = i;
			}
		}
		
		if( GetArraySize( g_hPlayersInAdminQueue ) != 0 )
		{
			for( new i = 0; i < iTerroristsAmount; i++ )
			{
				if( GetArraySize( g_hPlayersInAdminQueue ) > i )
				{
					iNewTerroristsTeam[ iTerroristsFromQueue++ ] = GetArrayCell( g_hPlayersInAdminQueue, i );
				}
			}
		}
		
		if( iTerroristsFromQueue < iTerroristsAmount )
		{
			for( new i = iTerroristsFromQueue; i < iTerroristsAmount; i++ )
			{
				new client;
#if defined DEBUG_VERSION
				new debug_counter;
#endif
				
				do
				{
					client = DR_GetRandomPlayer( 0, false );
					
					if( Array_FindValue( iOldTerroristsTeam, sizeof( iOldTerroristsTeam ), client, 0 ) != -1
					|| Array_FindValue( iNewTerroristsTeam, sizeof( iNewTerroristsTeam ), client, 0 ) != -1 
					|| !DR_GetPlayerClass( client ) )
					{
						client = 0;
					}
					
#if defined DEBUG_VERSION
					if( debug_counter++ > 200 )
					{
						LogError( "Debug counter is over 200!" );
						return Plugin_Handled;
					}
#endif
					
				} while( client == 0 );
				
				iNewTerroristsTeam[ i ] = client;
			}
		}
		
		DR_BlockTTeamJoining( );
		
		ClearArray( g_hPlayersInAdminQueue );
		
		for( new i = 0, Float:fTimerDelay = TEAM_CHANGE_DELAY; i <= MAXPLAYERS; i++ )
		{
			if( !iOldTerroristsTeam[ i ] && !iNewTerroristsTeam[ i ] )
			{
				break;
			}
		
			if( iOldTerroristsTeam[ i ] )
			{
				CreateTimer( fTimerDelay += TEAM_CHANGE_DELAY, Timer_DR_ChangeTeam, ( iOldTerroristsTeam[ i ] << 16 ) | CS_TEAM_CT );
			}
			
			if( iNewTerroristsTeam[ i ] )
			{
				CreateTimer( fTimerDelay += TEAM_CHANGE_DELAY, Timer_DR_ChangeTeam, ( iNewTerroristsTeam[ i ] << 16 ) | CS_TEAM_T );
			}
		}
	}
#if defined DEBUG_VERSION
	else
	{
		LogMessage( "Not enough players by calling DR_GetClientCountEx!\n" );
	}
#endif
	
	return Plugin_Continue;
}

public Action:Timer_DR_ChangeTeam( Handle:hTimer, any:data )
{
	if( IsClientInGame( data >> 16 ) )
	{
		g_bTeamChangeNotice = true;
		
		CS_SwitchTeam( data >> 16, data & 0xFFFF);
		
		g_bTeamChangeNotice = false;
	}
	
	return Plugin_Continue;
}

public Action:Timer_DR_TeleportTimer( Handle:hTimer, Handle:hDataPack )
{	
	new client;
	new Float:fPlayerPos[3];
	new Float:fPlayerAngles[3];
	
	ResetPack( hDataPack );
	
	client = ReadPackCell( hDataPack );
	
	fPlayerPos[ 0 ] = ReadPackFloat( hDataPack );
	fPlayerPos[ 1 ] = ReadPackFloat( hDataPack );
	fPlayerPos[ 2 ] = ReadPackFloat( hDataPack );
	
	fPlayerAngles[ 0 ] = ReadPackFloat( hDataPack );
	fPlayerAngles[ 1 ] = ReadPackFloat( hDataPack );
	fPlayerAngles[ 2 ] = ReadPackFloat( hDataPack );
	
	if( IsClientInGame( client ) )
	{
		TeleportEntity( client, fPlayerPos, fPlayerAngles, NULL_VECTOR );
		
		Bonuses_Reset( client );
	}
	
	DR_AllowTTeamJoining( );
	
	return Plugin_Continue;
}

public Action:Timer_DR_BlockBlind( Handle:hTimer, any:client )
{
	if( IsClientInGame( client ) && IsClientInGame( g_iFlashbangOwner ) )
	{
		if( GetClientTeam( client ) == GetClientTeam( g_iFlashbangOwner ) )
		{
			SetEntDataFloat( client, FindSendPropOffs( "CCSPlayer", "m_flFlashMaxAlpha" ), 0.5 );
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_DR_DissolveTimer( Handle:hTimer, any:client )
{
	DR_DissolveClient( client );
}