//Headcrab Classes for Save/Load System
#include "base" //Base
#include "../classes/headcrab_classes" //Headcrab Classes
#include "../weapons/weapon_headcrab" //Mutate on Load (Used for 'Get_Weapon_FromPlayer' function)
#include "../weapons/weapon_headcrab" //Mutate on Load

namespace SaveLoad_HClasses {	
	string SAVE_FILE = "headcrab_classes_ByName.ini";
	
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
			
			Log("Loaded Headcrab Classes for "+iArraySize+" Player(s).\n");
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
			Log("Saving Headcrab Classes for Player with ID:"+index+".[0%..");
		
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
			
			// Main data for this player does not exist, add it
			if ( !DataExists[ index ] ) {
				string stuff;
				stuff = szSaveBy + "\t";
				
				//Data is Here!
				stuff += string(HClass_Holder[index])+"#";
				//Save Every Headcrab Class
				for(uint i=0;i<HClasses::Headcrab_Classes.length();i++) {
					Headcrab_Class@ pHClass = HClasses::Headcrab_Classes[i];
					stuff += string(pHClass.HClass_Unlocked[index])+"#";
					//Abilities
					for(uint a=0;a<pHClass.Abilities.length();a++) {
						Headcrab_Ability@ hAbility = pHClass.Abilities[a];
						stuff += string(hAbility.Unlocked[index])+"#";
						stuff += string(hAbility.Active[index])+"#";
					}
				}
				
				
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
						stuff += string(HClass_Holder[index])+"#";
						//Save Every Headcrab Class
						for(uint i=0;i<HClasses::Headcrab_Classes.length();i++) {
							Headcrab_Class@ pHClass = HClasses::Headcrab_Classes[i];
							stuff += string(pHClass.HClass_Unlocked[index])+"#";
							//Abilities
							for(uint a=0;a<pHClass.Abilities.length();a++) {
								Headcrab_Ability@ hAbility = pHClass.Abilities[a];
								stuff += string(hAbility.Unlocked[index])+"#";
								stuff += string(hAbility.Active[index])+"#";
							}
						}
						
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
					int config_length = int(config.length());
					if(config_length>offset) {
						HClass_Holder[index] = atoi(config[offset]);offset++;//Selected Class
						HClass_Mutation_Holder[index] = HClass_Holder[index];
					}
					
					//Load Every Headcrab Class
					for(uint i=0;i<HClasses::Headcrab_Classes.length();i++) {
						Headcrab_Class@ pHClass = HClasses::Headcrab_Classes[i];
						if(config_length>offset) {
							if(config_length>offset) {
								int unlocked1 = atoi(config[offset]);offset++; //Is ZClass Unlocked?
								if(unlocked1==1) pHClass.HClass_Unlocked[index] = true;
								else pHClass.HClass_Unlocked[index] = false;
							}
							//Abilities
							for(uint a=0;a<pHClass.Abilities.length();a++) {
								if(config_length>offset) {
									Headcrab_Ability@ hAbility = pHClass.Abilities[a];
									//INT to Bool
									int unlocked2 = atoi(config[offset]);offset++; //Is Z-Ability Unlocked?
									if(unlocked2==1) hAbility.Unlocked[index] = true;
									else hAbility.Unlocked[index] = false;
									
									if(config_length>offset) {
										int unlocked3 = atoi(config[offset]);offset++; //Is Z-Ability Active?
										if(unlocked3==1) hAbility.Active[index] = true;
										else hAbility.Active[index] = false;
										
										@pHClass.Abilities[a] = hAbility;
									}
								}
							}
						
							@HClasses::Headcrab_Classes[i] = pHClass; //Class Loaded!
						}
					}
					
					//Found Player's claw and call the Mutate function
					CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_hclaws");
					weapon_hclaws@ hclaws = cast<weapon_hclaws@>(CastToScriptClass(pWpn));
					if(hclaws !is null)
						hclaws.HClass_Mutate(HClass_Holder[index]);
					
					DataExists[index] = true;
					loaddata[index] = true;
					Log("Headcrab Classes Found for Player "+szSaveBy+".\n");
					break;
				}
			}
			
			if(!DataExists[index])
			{
				Log("Headcrab Classes not Found for Player "+szSaveBy+".\n");
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
			fData.Write( ";[This is used to Save/Load Headcrab Classes for Players]\n" );
			
			fData.Write( ";NAME - Player's Name\n" );
			fData.Write( ";Delete this File if you add/remove Headcrab Classes!\n" );
			
			fData.Write( ";[NAME]" );
			uint uiVaultIndex = 0;
			for (uiVaultIndex = 0; uiVaultIndex < Data.length(); uiVaultIndex++ )
			{
				fData.Write( "\n" + Data[uiVaultIndex]);
			}
			
			fData.Close();
		}
	}
};