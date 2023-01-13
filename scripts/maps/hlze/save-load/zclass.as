//Zombie Classes for Save/Load System
#include "base" //Base
#include "../classes/zombie_classes" //Zombie Classes
#include "../weapons/weapon_zombie" //Mutate on Load

namespace SaveLoad_ZClasses {	
	const string SAVE_FILE = "zombie_classes.ini";
	
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
			
			Log("Loaded Zombie Classes for "+iArraySize+" Player(s).\n");
		} else {
			Log("Failed!\n", false);
		}
		
		Ready = true;
	}
	
	void SaveData( const int& in index , bool log_now = true ) {
		if(log_now)
			Log("Saving Zombie Classes for Player with ID:"+index+".[0%..");
		
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
				stuff += string(ZClass_Holder[index])+"#"; //Selected Class
				//Save Every Zombie Class
				for(uint i=0;i<ZClasses::Zombie_Classes.length();i++) {
					Zombie_Class@ pZClass = ZClasses::Zombie_Classes[i];
					stuff += string(pZClass.ZClass_Unlocked[index])+"#"; //Is ZClass Unlocked?
					//Abilities
					for(uint a=0;a<pZClass.Abilities.length();a++) {
						Zombie_Ability@ zAbility = pZClass.Abilities[a];
						stuff += string(zAbility.Unlocked[index])+"#"; //Is Z-Ability Unlocked?
						stuff += string(zAbility.Active[index])+"#"; //Is Z-Ability Active?
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
						stuff += string(ZClass_Holder[index])+"#"; //Selected Class
						//Save Every Zombie Class
						for(uint i=0;i<ZClasses::Zombie_Classes.length();i++) {
							Zombie_Class@ pZClass = ZClasses::Zombie_Classes[i];
							stuff += string(pZClass.ZClass_Unlocked[index])+"#"; //Is ZClass Unlocked?
							//Abilities
							for(uint a=0;a<pZClass.Abilities.length();a++) {
								Zombie_Ability@ zAbility = pZClass.Abilities[a];
								stuff += string(zAbility.Unlocked[index])+"#"; //Is Z-Ability Unlocked?
								stuff += string(zAbility.Active[index])+"#"; //Is Z-Ability Active?
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
					CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
					int isZM = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
					
					int offset = 0;
					int config_length = int(config.length());
					if(config_length>offset) {
						ZClass_Holder[index] = atoi(config[offset]);offset++;//Selected Class
						ZClass_MutationState[index] = ZM_MUTATION_NONE;
						//HClass_Holder[index]=ZClass_Holder[index];
						//HClass_Mutation_Holder[index]=ZClass_Holder[index];
					}
					
					//Load Every Zombie Class
					for(uint i=0;i<ZClasses::Zombie_Classes.length();i++) {
						if(config_length>offset) {
							Zombie_Class@ pZClass = ZClasses::Zombie_Classes[i];
							int unlocked1 = atoi(config[offset]);offset++; //Is ZClass Unlocked?
							if(unlocked1==1) pZClass.ZClass_Unlocked[index] = true;
							else pZClass.ZClass_Unlocked[index] = false;
							//Abilities
							for(uint a=0;a<pZClass.Abilities.length();a++) {
								if(config_length>offset) {
									Zombie_Ability@ zAbility = pZClass.Abilities[a];
									//INT to Bool
									int unlocked2 = atoi(config[offset]);offset++; //Is Z-Ability Unlocked?
									if(unlocked2==1) zAbility.Unlocked[index] = true;
									else zAbility.Unlocked[index] = false;
									
									if(config_length>offset) {
										int unlocked3 = atoi(config[offset]);offset++; //Is Z-Ability Active?
										if(unlocked3==1) zAbility.Active[index] = true;
										else zAbility.Active[index] = false;
										
										@pZClass.Abilities[a] = zAbility;
									}
								}
							}
							
							@ZClasses::Zombie_Classes[i] = pZClass; //Class Loaded!
						}
					}
					
					//Found Player's claw and call the Mutate function
					CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_zclaws");
					weapon_zclaws@ zclaws = cast<weapon_zclaws@>(CastToScriptClass(pWpn));
					if(zclaws !is null)
						zclaws.ZClass_Mutate(ZClass_Holder[index]);
					
					DataExists[index] = true;
					loaddata[index] = true;
					Log("Zombie Classes Found for Player "+szSaveBy+".\n");
					break;
				}
			}
			
			if(!DataExists[index])
			{
				Log("Zombie Classes not Found for Player "+szSaveBy+".\n");
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
			fData.Write( ";[This is used to Save/Load Zombie Classes for Players]\n" );
			
			fData.Write( ";NAME - Player's Name\n" );
			fData.Write( ";Delete this File if you add/remove Zombie Classes!\n" );
			
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