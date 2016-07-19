public Action:Scouts_BlockMessageCallback( client, args )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			new String:szArg[32];
			
			if( GetCmdArg( 1, szArg, sizeof( szArg ) ) )
			{
				if( StrEqual( szArg, "!scout" ) || StrEqual( szArg, "!getback" ) )
				{
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Scouts_ReturnScoutsCallback( client, args )
{
	for( new i = 1; i < MaxClients; i++ )
	{
		Scouts_ReturnToOwner( i );
	}
}

public Action:Scouts_MakeScoutCallback( client, args )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_scouts_enabled ) )
		{
			if( args == 0 )
			{
				if( GetClientTeam( client ) != CS_TEAM_SPECTATOR )
				{
					if( IsPlayerAlive( client ) )
					{
						Scouts_GiveScout( client );
					}
				}
			}
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock void:Scouts_GiveScout( client )
{
	if( GetConVarBool( dr_scouts_enabled ) )
	{
		if( IsClientInGame( client ) && IsPlayerAlive( client ) )
		{
			if( GetClientTeam( client ) == CS_TEAM_T && g_iScoutsData[ client ] == SCOUT_FREE_SLOT)
			{
#if !defined DEBUG_VERSION
				PrintToChat( client, DR_MSG, "scout_invalid_team" );
#else
				PrintToChat( client, "scout_invalid_team" );
#endif
			}
			else if( GetPlayerWeaponSlot( client, 0 ) == SCOUT_FREE_SLOT )
			{
				if( g_iScoutsData[ client ] == SCOUT_FREE_SLOT )
				{
					g_iScoutsData[ client ] = Client_GiveWeaponAndAmmo( client, "weapon_scout", true, 0, 0, 0, 0 );
					
					if( g_iScoutsData[ client ] != SCOUT_FREE_SLOT )
					{
						if( GetConVarBool( dr_scouts_colored ) )
						{
							new iRed, iGreen, iBlue, iAlpha;
							
							iRed = GetRandomInt( 0, 255 );
							iGreen = GetRandomInt( 0, 255 );
							iBlue = GetRandomInt( 0, 255 );
							
							iAlpha = ( GetUserFlagBits( client ) != 0 ? GetRandomInt( 50, 255 ) : 255 );
						
							SetEntityRenderMode( g_iScoutsData[ client ], RENDER_TRANSCOLOR );
							SetEntityRenderColor( g_iScoutsData[ client ], iRed, iGreen, iBlue, iAlpha );
						}
						
						if( GetConVarBool( dr_scouts_block_protect ) )
						{
							SDKHook( g_iScoutsData[ client ], SDKHook_StartTouch, Hook_PreventTrapBlocking );
						}
					}
				}
				else
				{
					Scouts_ReturnToOwner( client );
				}
			}
			else
			{
#if !defined DEBUG_VERSION
				PrintHintText( client, DR_MSG, "already_have_weapon" );
#else
				PrintHintText( client, "already_have_weapon" );
#endif
			}
		}
	}
}

stock void:Scouts_ReturnToOwner( client )
{
	if( IsValidEntity( client ) && IsClientInGame( client ) )
	{
		if( g_iScoutsData[ client ] != SCOUT_FREE_SLOT && IsValidEntity( g_iScoutsData[ client ] ) )
		{
			CreateTimer( SCOUT_RETURN_DELAY, Timer_Scouts_ReturnScout, client );
		}
		else
		{
			Scouts_SetAction( false, client );
		}
	}
	else
	{
		Scouts_SetAction( false, client );
	}
}

stock void:Scouts_DissolveScout( client )
{
	if( g_iScoutsData[ client ] != SCOUT_FREE_SLOT )
	{
		DR_Dissolve( g_iScoutsData[ client ] );
	}
}

stock void:Scouts_ResetScouts( )
{
	for( new i = 0; i <= MAXPLAYERS; i++ )
	{
		g_iScoutsData[ i ] = SCOUT_FREE_SLOT;
	}
}

stock void:Scouts_SetAction( bool:val, index )
{
	if( 0 <= index <= MaxClients )
	{
		g_bScoutsInAction[ index ] = val;
	}
}

stock bool:Scouts_InAction( id )
{
	if( 0 <= id <= MaxClients )
	{
		return g_bScoutsInAction[ id ];
	}
	
	return false;
}

stock Scouts_GetOwner( scout )
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( g_iScoutsData[ i ] == scout )
		{
			return i;
		}
	}
	
	return -1;
}

stock bool:Scouts_IsScout( entity )
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( g_iScoutsData[ i ] == entity )
		{
			return true;
		}
	}
	
	return false;
}