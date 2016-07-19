public Action:DR_MovePlayerInTerroristsQueue( client, args )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_allow_set_terrorists ) )
		{
			if( args == 1 )
			{
				new String:szCmdArgs[256], String:szTargets[256], index;
				
				GetCmdArg( 1, szCmdArgs, sizeof(szCmdArgs) );
				BreakString( szCmdArgs, szTargets, sizeof(szTargets) );

				if ( szTargets[0] == '"' )
				{
					index = 1;
					
					if (szTargets[ strlen(szTargets)-1 ] == '"')
					{
						szTargets[ strlen(szTargets)-1 ] = 0;
					}	
				}
				
				new iTargets[ MAXPLAYERS + 1 ];
				new String:notUsed[ 2 ], bool:notUsedToo;
				
				new count = ProcessTargetString(
					szTargets[ index ],
					client,
					iTargets,
					MaxClients,
					0,
					notUsed,
					1,
					notUsedToo
				);
				
				if (count < 1)
				{
					ReplyToCommand(client, "Nobody found.");
					return Plugin_Handled;
				}
				
				for( new i = 0 ; i < count; i++ )
				{
					new player = iTargets[ i ];
				
					if( IsClientInGame( player ) && IsPlayerAlive( player ) )
					{
						new String:szPlayerName[ 128 ];
						
						GetClientName( player, szPlayerName, sizeof( szPlayerName ) );
						
						if( FindValueInArray( g_hPlayersInAdminQueue, player ) == -1 )
						{
							PushArrayCell( g_hPlayersInAdminQueue, player );
							
							ReplyToCommand( client, "%s will be a new terrorist.", szPlayerName );
						}
						else
						{
							ReplyToCommand( client, "%s is already in queue.", szPlayerName );
						}
					}
				}
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:DR_CheckTeamJoining( client, args )
{
	if( GetConVarBool( dr_enabled ) )
	{
		new String:szSelectedTeam[16];
		new String:szTerroristsRelation[64];
		
		GetConVarString( dr_ratio, szTerroristsRelation, sizeof( szTerroristsRelation ) );
		
		new iTerroristsRelation = DR_GetAmountOfTerrorists( DR_GetClientCountEx( ), DR_GetSpawnPoints( CS_TEAM_T ), szTerroristsRelation );
		
		if( GetClientTeam( client ) == CS_TEAM_T )
		{
			if( IsPlayerAlive( client ) || DR_IsTTeamJoiningBlocked( ) )
			{
				if( DR_GetClientCountEx( CS_TEAM_CT, true ) > 0 )
				{
#if !defined DEBUG_VERSION
					PrintToChat( client, DR_MSG, "team_change_blocked_t" );
#else
					PrintToChat( client, "team_change_blocked_t" );
#endif
					return Plugin_Handled;
				}
			}
		}
		
		if( GetCmdArg( 1, szSelectedTeam, sizeof( szSelectedTeam ) ) )
		{
			new iSelectedTeam = StringToInt( szSelectedTeam );
			
			if( iSelectedTeam != 0 )
			{
				if( iSelectedTeam == CS_TEAM_T )
				{
					if( DR_GetClientCountEx( CS_TEAM_T, false ) >= iTerroristsRelation || DR_IsTTeamJoiningBlocked( ) )
					{
					
#if !defined DEBUG_VERSION
						PrintToChat( client, DR_MSG, "terrorists_team_full" );
#else
						PrintToChat( client, "terrorists_team_full" );
#endif
						return Plugin_Handled;
					}
				}
			}
			else
			{
			
#if !defined DEBUG_VERSION
				PrintToChat( client, DR_MSG, "team_change_blocked" );
#else
				PrintToChat( client, "team_change_blocked" );
#endif
				return Plugin_Handled;
			}
		}
		else
		{
		
#if !defined DEBUG_VERSION
			PrintToChat( client, DR_MSG, "team_change_blocked" );
#else
			PrintToChat( client, "team_change_blocked" );
#endif
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:DR_CheckSpectatorCallback( client, args ) // Probably should be rewritten
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetClientTeam( client ) == CS_TEAM_T )
		{
#if !defined DEBUG_VERSION
			PrintToChat( client, DR_MSG, "spectator_blocked" );
#else
			PrintToChat( client, "spectator_blocked" );
#endif
			
			return Plugin_Handled;
		}
		
		if( IsPlayerAlive( client ) )
		{
			g_bJoiningInTeam[ client ] = true;
		}
	}
	
	return Plugin_Continue;
}

public Action:DR_BlockCommandCallback( client, args )
{
	if( GetConVarBool( dr_enabled ) )
	{
		if( GetConVarBool( dr_block_suicide ) && IsPlayerAlive( client ) )
		{
#if !defined DEBUG_VERSION
			PrintToChat( client, DR_MSG, "suicide_blocked" );		
#else
			PrintToChat( client, "suicide_blocked" );
#endif
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

stock DR_GetAmountOfTerrorists( iAmount, iPoints, const String:szCommand[] )
{
	new String:szStringContaner[16][128];
	new iStrCount = ExplodeString( szCommand, "-", szStringContaner, 16, 128 );
	new iRetValue = 0;
	
	if( !iStrCount )
	{
		strcopy( szStringContaner[0], sizeof(szStringContaner), szCommand );
	}
	
	for(new i = 0; i < iStrCount; i++)
	{ 
		if( FindCharInString( szStringContaner[i], ',', true ) != FindCharInString( szStringContaner[i], ',', false ) )
		{
			return -1;
		}
		
		new String:szBreakedCommand[2][128];
		
		if( ExplodeString( szStringContaner[i], ",", szBreakedCommand, 2, 128 ) )
		{
			if(iAmount >= StringToInt( szBreakedCommand[0] ))
			{	
				iRetValue =  StringToInt( szBreakedCommand[1] );
			}
		}
	}
	
	if( iRetValue > iAmount / 2 && iRetValue > 1 )
	{
		iRetValue = iAmount / 2;
	}
	
	if( iRetValue > iPoints )
	{
		while( iRetValue != iPoints)
		{
			iRetValue--;
		}
	}
	
	return iRetValue;
}

stock DR_GetClientCountEx( teamindex = 0, bool:alive = false, bool:ingame = true, bool:notspectator = true )
{
	new iClientCount = 0;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ) )
		{
			if( teamindex == 0 ? true : GetClientTeam( i ) == teamindex )
			{
				if( alive ? IsPlayerAlive( i ) : true )
				{
					if( ingame ? DR_GetPlayerClass( i ) != 0 : true )
					{
						if( notspectator ? GetClientTeam( i ) != CS_TEAM_SPECTATOR : true )
						{
							iClientCount++;
						}
					}
				}
			}
		}
	}
	
	return iClientCount;
}

stock DR_GetSpawnPoints( team = CS_TEAM_T )
{
	if( CS_TEAM_CT < team || team < CS_TEAM_T )
	{
		return 0;
	}
	
	new count, index = -1;
	
	while ( ( index = FindEntityByClassname( index, ( team == CS_TEAM_T ? "info_player_terrorist" : "info_player_counterterrorist" ) ) ) != -1 )
	{
		count++;
	}
	
	return count;
}

stock DR_GetRandomPlayer( team, bool:alive )
{
	new iClients[ MaxClients + 1 ], iClientCount;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame( i ) )
		{
			if( team == 0 && GetClientTeam( i ) != CS_TEAM_SPECTATOR || GetClientTeam( i ) == team )
			{
				if( alive ? IsPlayerAlive( i ) : true )
				{
					iClients[ iClientCount++ ] = i;
				}
			}
		}
	}
	
	return iClientCount == 0 ? -1 : iClients[ GetRandomInt( 0, iClientCount - 1 ) ];
}

stock DR_GetPlayerClass( client )
{
	new iClass = GetEntData( client, FindSendPropInfo( "CCSPlayer", "m_iClass" ) );
	new iTrueClass = iClass - ( GetClientTeam( client ) == CS_TEAM_CT ? 4 : 0 );
	
	return iTrueClass;
} 

stock DR_BlockTTeamJoining( )
{
	g_bForceBlockTeamJoining = true;
}

stock DR_AllowTTeamJoining( )
{
	g_bForceBlockTeamJoining = false;
}

stock DR_IsTTeamJoiningBlocked( )
{
	return g_bForceBlockTeamJoining;
}

stock DR_DissolveClient( client )
{
	if( 0 < client <= MaxClients && IsClientInGame( client ) )
	{
		new ragdoll = GetEntPropEnt( client, Prop_Send, "m_hRagdoll" );
		
		DR_Dissolve( ragdoll );
	}
}

stock DR_Dissolve( entity )
{
	if( IsValidEntity( entity ) )
	{
		new String:szTargetName[32];
		new iDissolver = CreateEntityByName( "env_entity_dissolver" );
		
		Format( szTargetName, sizeof( szTargetName ), "trg_", entity );
		
		if( iDissolver > -1 )
		{
			DispatchKeyValue( entity, "targetname", szTargetName );
			DispatchKeyValue( iDissolver, "dissolvetype", "3" );
			DispatchKeyValue( iDissolver, "target", szTargetName );
			
			AcceptEntityInput( iDissolver, "Dissolve" );
			AcceptEntityInput( iDissolver, "Kill" );
		}
	}
}