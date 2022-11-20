//Gene Points for Save/Load System
#include "base" //Base
#include "../classes/gene_points" //Gene Points

namespace SaveLoad_GenePoints {	
	const string SAVE_FILE = "gene_points.ini";
	
	//Load?
	array<bool>loaddata(33);
	//Data
	array<bool>DataExists(33);
	array<string>Data;
	bool Ready;
	
	void Load() {
		Log("Loading '"+SAVE_FILE+"'....");
		Ready = false;
		
		string szDataPath = SYSTEM_PATH + SAVE_FILE;
		File@ fData = g_FileSystem.OpenFile(szDataPath, OpenFile::READ );
		
		if (fData !is null && fData.IsOpen())
		{
			Log("Succeeded!\n", false);
			
			int iArraySize = 0;
			string szLine;
			
			while ( !fData.EOFReached() ) {
				fData.ReadLine( szLine );
				if ( szLine.Length() > 0 && szLine[ 0 ] != ';' )
				{
					iArraySize++;
					Data.resize( iArraySize );
					Data[iArraySize - 1] = szLine;
				}
			}
			
			fData.Close();
			
			Log("Loaded Gene Points for "+iArraySize+" Player(s).\n");
		} else {
			Log("Failed!\n", false);
		}
		
		Ready = true;
	}
	
	void SaveData( const int& in index , bool log_now = true ) {
		if(log_now)
			Log("Saving Gene Points for Player with ID:"+index+".[0%..");
		
		// Do not write into this vault unless it is absolutely safe to do so!
		if (!loaddata[index]) {
			if(log_now)
				Log("Failed!]\n", false);
				
			return;
		}
		
		if(log_now)
			Log("18%..", false);
		
		if ( !Ready ) {
			if(log_now)
				Log("Failed!]\n", false);
			
			return;
		}
		
		if(log_now)
			Log("25%..", false);
		
		if(log_now)
			Log("47%..", false);
		
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			if(log_now)
				Log("63%..", false);
			
			//string szSteamID = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			string szName = pPlayer.pev.netname;
			
			if(log_now)
				Log("86%..", false);
			
			// The fewer the I/O file operations it has to do the better, right?
			
			// Main data for this player does not exist, add it
			if ( !DataExists[ index ] ) {
				string stuff;
				stuff = szName + "\t";
				
				//Data is Here!
				stuff += string(GenePts_Holder[index])+"#";
				
				Data.insertLast(stuff);
				DataExists[index] = true;
				if(log_now) Log("91%..", false);
			} else {
				// Go through the vault
				for(uint uiVaultIndex = 0;uiVaultIndex < Data.length();uiVaultIndex++ ) {
					// Update our data?
					if (Data[uiVaultIndex].StartsWith(szName)) {
						string stuff;
						stuff = szName + "\t";
						//Data is Here!
						stuff += string(GenePts_Holder[index])+"#";
						
						Data[uiVaultIndex] = stuff;
						
						if(log_now) Log("93%..", false);
						break;
					}
					if(log_now) Log("95%..", false);
				}
				
				if(log_now) Log("97%..", false);
			}
			
			if(log_now)
				Log("100%].\n", false);
		} else {
			if(log_now)
				Log("Failed!]\n", false);
		}
	}
	
	void LoadData( const int& in index ) {
		if(!Ready) {
			g_Scheduler.SetTimeout("LoadData", SAVE_TIME, index);
			return;
		}
		
		// Prepare to go through the vaults
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		if(pPlayer !is null && pPlayer.IsConnected()) {
			string szName = pPlayer.pev.netname;
			
			// Main data
			for(uint uiVaultIndex = 0;uiVaultIndex < Data.length();uiVaultIndex++ )
			{
				array< string >@ key = Data[uiVaultIndex].Split( '\t' );
				// This is our name?
				string szCheck = key[ 0 ];
				szCheck.Trim();
				
				if(szName == szCheck) {
					// It is, retrieve data
					string data = key[ 1 ];
					data.Trim();
					array< string >@ config = data.Split( '#' );
					
					for ( uint uiDataLength = 0; uiDataLength < config.length(); uiDataLength++ )
						config[ uiDataLength ].Trim();
					
					//Load from Data
					int offset = 0;
					GenePts_Holder[index] = atoi(config[offset]);offset++;
					
					DataExists[index] = true;
					loaddata[index] = true;
					Log("Gene Points Found for Player "+szName+".\n");
					break;
				}
			}
			
			if(!DataExists[index])
			{
				Log("Gene Points not Found for Player "+szName+".\n");
				// No data found, assume new player
				LoadEmpty( index );
				loaddata[index] = true;
			}
		}
	}
	
	void LoadEmpty(const int& in index)
	{
		GenePts_Holder[index] = 0;
		loaddata[index] = false;
	}
	
	//Update all data contents
	void Save2File()
	{
		//Data must be initialized!
		if (!Ready)
			return;
		
		// Main data
		string szDataPath = SYSTEM_PATH + SAVE_FILE;
		
		File@ fData = g_FileSystem.OpenFile(szDataPath, OpenFile::WRITE);
		if(fData !is null && fData.IsOpen())
		{
			fData.Write( ";[Sven Co-op System v"+SYSTEM_VERSION+" created on "+SYSTEM_BUILD_DATE+"]\n" );
			fData.Write( ";[This is used to Save/Load Gene Points for Players]\n" );
			
			fData.Write( ";NAME - Player's Name\n" );
			fData.Write( ";GENE_PTS - Player's Gene Points\n" );
			
			fData.Write( ";[NAME]\t\t\t[GENE_PTS]" );
			uint uiVaultIndex = 0;
			for (uiVaultIndex = 0; uiVaultIndex < Data.length(); uiVaultIndex++ )
			{
				fData.Write( "\n" + Data[uiVaultIndex]);
			}
			
			fData.Close();
		}
	}
};