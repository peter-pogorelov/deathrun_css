stock void:Bonuses_SetClientBonuses( client )
{
	if( !IsClientInGame( client ) || IsFakeClient( client ) || DR_GetPlayerClass( client ) == 0 )
	{
		return;
	}
	
	if( GetClientTeam( client ) == CS_TEAM_T )
	{
		Bonuses_Reset( client );
		
		return;
	}
	
	new Handle:hKv = CreateKeyValues( "bonuses" );
	
	FileToKeyValues( hKv, g_szPathToBonuses );
	
	if( !KvGotoFirstSubKey( hKv ) )
	{
		LogError( "Error in KV structure or file bonuses.txt isn't exists, disabling bonuses!" );
		SetConVarBool( dr_bonuses_enabled, false );
		
		CloseHandle( hKv );
		return;
	}
	
	do
	{
		new String:szSectionName[32];
		new String:szNextSection[32];
		
		new bool:bLastSection;
		
		new iCurrentAmount;
		new iNextAmount;
				
		KvGetSectionName( hKv, szSectionName, sizeof( szSectionName ) );
		KvSavePosition( hKv );
		
		if( KvGotoNextKey( hKv ) )
		{
			bLastSection = false;
		
			KvGetSectionName( hKv, szNextSection, sizeof( szNextSection ) );
			KvGoBack( hKv );
		}
		else
		{
			bLastSection = true;
		}
		
		iCurrentAmount = StringToInt( szSectionName );
		
		if( !bLastSection )
		{
			iNextAmount = StringToInt( szNextSection );
		}
		else
		{
			iNextAmount = GetClientFrags( client ) + 1;
		}
		
		if( iCurrentAmount <= GetClientFrags( client ) < iNextAmount )
		{
			if( KvGetDataType( hKv, "default" ) == KvData_None ) //if this is default section
			{
				if( bLastSection )
				{
#if !defined DEBUG_VERSION
					PrintToChat( client, DR_MSG, "bonuse_max", iCurrentAmount );
#else
					PrintToChat( client, "bonuse_max %d", iCurrentAmount );
#endif
				}
				else
				{
#if !defined DEBUG_VERSION
					PrintToChat( client, DR_MSG, "bonuse_normal", iCurrentAmount, iNextAmount );
#else
					PrintToChat( client, "bonuse_normal %d %d", iCurrentAmount, iNextAmount );
#endif
				}
			}
		
			if( KvGetDataType( hKv, "default" ) != KvData_None )
			{
				Bonuses_Reset( client );
			}
			
			if( KvGetDataType( hKv, "color" ) != KvData_None )
			{
				new iRed, iGreen, iBlue, iAlpha;
				
				KvGetColor( hKv, "color", iRed, iGreen, iBlue, iAlpha );
				SetEntityRenderMode( client, RENDER_TRANSCOLOR );
				SetEntityRenderColor( client, iRed, iGreen, iBlue, iAlpha );
			}
			else
			{
				SetEntityRenderMode( client, RENDER_TRANSCOLOR );
				SetEntityRenderColor( client, 255, 255, 255, 255 );
			}
			
			if( KvGetDataType( hKv, "health" ) != KvData_None )
			{
				new iHealth = KvGetNum( hKv, "health", 100 );
				
				SetEntityHealth( client, iHealth );
			}
			
			if( KvGetDataType( hKv, "speed" ) != KvData_None )
			{
				new Float:fSpeed = KvGetFloat( hKv, "speed", 1.0 );
				
				SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", fSpeed );
			}
			
			if( KvGetDataType( hKv, "gravity" ) != KvData_None )
			{
				g_fPlayerGravity[ client ] = KvGetFloat( hKv, "gravity", 1.0 );
				
				SetEntityGravity( client, g_fPlayerGravity[ client ] );
			}
			
			break;
		}
		
	} while( KvGotoNextKey( hKv ) );
	
	CloseHandle( hKv );
	
	return;
}

stock Bonuses_GetMaxBonus( )
{
	new String:szSectionName[ 32 ];
	new Handle:hKv = CreateKeyValues( "bonuses" );
	
	FileToKeyValues( hKv, g_szPathToBonuses );
	
	if( !KvGotoFirstSubKey( hKv ) )
	{
		LogError( "Error in KV structure or file bonuses.txt isn't exists, disabling bonuses!" );
		SetConVarBool( dr_bonuses_enabled, false );
		
		CloseHandle( hKv );
		return -1;
	}
	
	do
	{
		KvGetSectionName( hKv, szSectionName, sizeof( szSectionName ) );
	} while( KvGotoNextKey( hKv ) );
	
	CloseHandle( hKv );
	
	return StringToInt( szSectionName );
}

stock void:Bonuses_Reset( client )
{
	SetEntityRenderMode( client, RENDER_TRANSCOLOR );
	SetEntityRenderColor( client, 255, 255, 255, 255 );
	SetEntityHealth( client, 100 );
	SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0 );
	SetEntityGravity( client, g_fPlayerGravity[ client ] = 1.0 );
}