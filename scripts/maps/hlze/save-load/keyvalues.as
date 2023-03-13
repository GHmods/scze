//Player's Keyvalues for Save/Load System
#include "base" //Base

namespace SaveLoad_KeyValues {	
	string SAVE_FILE = "keyvalues_ByName.ini";
	
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
			
			Log("Loaded KeyValues for "+iArraySize+" Player(s).\n");
		} else {
			Log("Failed!\n", false);
		}
		
		Ready = true;
	}
	
	void SaveDataAll(bool log_now=false) {
		for(uint i=0;i<33;i++) {
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected()) {
				SaveData(i,log_now);
			}
		}
	}
	
	void SaveData( const int& in index , bool log_now = true ) {
		log_now = (log_now && cvar_Log_System>=LOG_LEVEL_HIGH);
		
		if(log_now)
			Log("Saving KeyValues for Player with ID:"+index+".[0%..");
		
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
			
			string szSaveBy = pPlayer.pev.netname;
			if(SaveLoad::cvar_SaveLoad_by==1) { //Load by Steam ID
				szSaveBy = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
			}
			
			if(log_now)
				Log("86%..", false);
			
			// The fewer the I/O file operations it has to do the better, right?
			
			//Get Player KeyValues
			CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
			int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
			
			int isZM = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
			int isHC = atoui(KeyValues.GetKeyvalue("$i_isHeadcrab").GetString());
			
			if(isZM == isHC) {
				isZombie = isHC;
			} else isZombie = isZM;
			
			int zType = atoui(KeyValues.GetKeyvalue("$i_infected_type").GetString());
			int zTypeMaskless = atoui(KeyValues.GetKeyvalue("$i_infected_type_maskless").GetString());
			int hcVision = atoui(KeyValues.GetKeyvalue("$i_hc_vision").GetString());
			
			// Main data for this player does not exist, add it
			if ( !DataExists[ index ] ) {
				string stuff;
				stuff = szSaveBy + "\t";
				
				//Data is Here!
				stuff += string(isZombie)+"#";
				stuff += string(zType)+"#";
				stuff += string(zTypeMaskless)+"#";
				stuff += string(hcVision)+"#";
				
				Data.insertLast(stuff);
				DataExists[index] = true;
				if(log_now) Log("91%..", false);
			} else {
				// Go through the vault
				for(uint uiVaultIndex = 0;uiVaultIndex < Data.length();uiVaultIndex++ ) {
					// Update our data?
					if (Data[uiVaultIndex].StartsWith(szSaveBy)) {
						string stuff;
						stuff = szSaveBy + "\t";
						//Data is Here!
						stuff += string(isZombie)+"#";
						stuff += string(zType)+"#";
						stuff += string(zTypeMaskless)+"#";
						stuff += string(hcVision)+"#";
						
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
			string szSaveBy = pPlayer.pev.netname;
			if(SaveLoad::cvar_SaveLoad_by==1) { //Load by Steam ID
				szSaveBy = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
			}
			
			// Main data
			for(uint uiVaultIndex = 0;uiVaultIndex < Data.length();uiVaultIndex++ )
			{
				array< string >@ key = Data[uiVaultIndex].Split( '\t' );
				// This is our name?
				string szCheck = key[ 0 ];
				szCheck.Trim();
				
				if(szSaveBy == szCheck) {
					// It is, retrieve data
					string data = key[ 1 ];
					data.Trim();
					array< string >@ config = data.Split( '#' );
					
					for ( uint uiDataLength = 0; uiDataLength < config.length(); uiDataLength++ )
						config[ uiDataLength ].Trim();
					
					//Load from Data
					int offset = 0;
					
					//Store Player's KeyValues
					int isZombie = atoi(config[offset]);offset++;
					int zType = atoi(config[offset]);offset++;
					int zTypeMaskless = atoi(config[offset]);offset++;
					int hcVision = atoi(config[offset]);offset++;
					//Set Player's KeyValues
					pPlayer.KeyValue("$i_isZombie",isZombie);
					pPlayer.KeyValue("$i_infected_type",zType);
					pPlayer.KeyValue("$i_infected_type_maskless",zTypeMaskless);
					pPlayer.KeyValue("$i_hc_vision",hcVision);
					
					DataExists[index] = true;
					loaddata[index] = true;
					Log("KeyValues Found for Player "+szSaveBy+".\n");
					break;
				}
			}
			
			if(!DataExists[index])
			{
				Log("KeyValues not Found for Player "+szSaveBy+".\n");
				// No data found, assume new player
				LoadEmpty( index );
				loaddata[index] = true;
			}
		}
	}
	
	void LoadEmpty(const int& in index)
	{
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
			fData.Write( ";[This is used to Save/Load KeyValues for Players]\n" );
			
			fData.Write( ";NAME - Player's Name\n" );
			fData.Write( ";IS_ZM - Is Player a Zombie?\n" );
			fData.Write( ";ZM_IT - Zombie Infected Type\n" );
			fData.Write( ";IT_MSK - Is Zombie Maskless (Used for Human Grunt Type)\n" );
			fData.Write( ";HC_VIS - Is DarkVision Activated?\n" );
			
			fData.Write( ";[NAME]\t\t\t[IS_ZM][ZM_IT][IT_MSK][HC_VIS]" );
			uint uiVaultIndex = 0;
			for (uiVaultIndex = 0; uiVaultIndex < Data.length(); uiVaultIndex++ )
			{
				fData.Write( "\n" + Data[uiVaultIndex]);
			}
			
			fData.Close();
		}
	}
};