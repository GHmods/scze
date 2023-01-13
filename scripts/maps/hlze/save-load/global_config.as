//Config System for Save/Load System
#include "base" //Base

namespace SaveLoad_Cfg {	
	string CONFIG_PATH = "scripts/maps/";
	const string CONFIG_GLOBAL = "hlze_global.ini";
	const string CONFIG_EXT = ".hlze.ini";
	
	//Data
	bool Ready;
	
	void Load(bool isGlobal = false, bool isReady = true) {
		Ready = false;
		
		string szDataPath = CONFIG_PATH+string(g_Engine.mapname)+CONFIG_EXT;
		string PathShort = string(g_Engine.mapname)+CONFIG_EXT;
		if(isGlobal) {
			szDataPath = CONFIG_PATH+CONFIG_GLOBAL;
			PathShort = CONFIG_GLOBAL;
		}
		
		Log("Loading '"+PathShort+"'....");

		File@ fData = g_FileSystem.OpenFile(szDataPath, OpenFile::READ );
		
		if (fData !is null && fData.IsOpen())
		{
			Log("Succeeded!\n", false);
			
			int iArraySize = 0;
			string szLine;
			
			while(!fData.EOFReached()) {
				fData.ReadLine(szLine);
				if( szLine.Length() > 0 && szLine[ 0 ] != ';' )
				{
					//szLine.Trim();
					array<string>@ configData = szLine.Split('=');
					configData[0].Trim();
					configData[1].Trim();
					string config = configData[0];
					int value = atoi(configData[1]);
					
					//Log(config+" = "+value+"\n");
					
					if(configData[0] == "SaveLoad_by") {
						SaveLoad::cvar_SaveLoad_by = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "load_keyvalues") {
						SaveLoad::cvar_load_keyvalues = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "spawn_as") {
						SaveLoad::cvar_spawn_as = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "zclass_onspawn") {
						SaveLoad::cvar_zclass_onspawn = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "zclass_onspawn_for_first_time") {
						SaveLoad::cvar_zclass_onspawn_once = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "hclass_onspawn") {
						SaveLoad::cvar_hclass_onspawn = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "hclass_onspawn_for_first_time") {
						SaveLoad::cvar_hclass_onspawn_once = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "pvpvm") {
						SaveLoad::cvar_pvpvm = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "pvpvm_team") {
						SaveLoad::cvar_pvpvm_team = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "pvpvm_spawn_system") {
						SaveLoad::cvar_pvpvm_spawn_system = atoi(configData[1]);
						iArraySize++;
					} else if(configData[0] == "pvpvm_human_models") {
						SaveLoad::cvar_pvpvm_models = configData[1];
						iArraySize++;
					}
				}
			}
			
			fData.Close();
			
			Log("Loaded "+iArraySize+" Config Values from Config File,'"+PathShort+"'.\n");
		} else {
			Log("Failed!\n", false);
		}
		Ready = isReady;
	}
};