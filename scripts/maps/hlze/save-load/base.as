//Save/Load System Register file for Sven Co-op Zombie Edition
#include "gene_points" //Gene Points
#include "zclass" //Zombie Classes
#include "hclass" //Headcrab Classes
#include "keyvalues" //KeyValues

#include "global_config" //Global Config

#include "../pvpvm/pvpvm"//PVPVM
#include "../unstuck" //Unstuck

const string SYSTEM_TAG			=	"[Save/Load System]";
const string SYSTEM_NAME		=	"Save/Load System";
const string SYSTEM_BUILD_DATE		=	"12/01/2022";
const string SYSTEM_VERSION		=	"0.3b";

string SYSTEM_PATH			=	"scripts/maps/store/hlze/";

//Save Time
const float SAVE_TIME			=	2.0; // Save players stuff every X.X time

namespace SaveLoad {
	//Global/Map Configuration
	int cvar_SaveLoad_by=0;
	int cvar_load_keyvalues=1;
	int cvar_spawn_as=0;
	int cvar_zclass_onspawn=-1;
	int cvar_zclass_onspawn_once=0;
	int cvar_hclass_onspawn=-1;
	int cvar_hclass_onspawn_once=0;
	
	//Players VS. Players VS. Monsters
	int cvar_pvpvm=0;
	int cvar_pvpvm_team=0;
	int cvar_pvpvm_spawn_system=1;
	string cvar_pvpvm_models="gordon";
	
	//Data
	array<bool>isSpawned(33,false);
	
	bool EverythingIsReady() {
		return (
			SaveLoad_Cfg::Ready &&
			SaveLoad_GenePoints::Ready &&
			SaveLoad_ZClasses::Ready &&
			SaveLoad_HClasses::Ready &&
			SaveLoad_KeyValues::Ready
		);
	}
	
	bool EverythingIsReady4Player(const int& in index) {
		bool ready=false;
		
		ready = (
				SaveLoad_Cfg::Ready &&
				SaveLoad_GenePoints::loaddata[index] &&
				SaveLoad_ZClasses::loaddata[index] &&
				SaveLoad_HClasses::loaddata[index] &&
				SaveLoad_KeyValues::loaddata[index]
		);
		
		return ready;
	}
	
	//Welcome Message for Every Player
	HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer) {
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "********************************************************************\n");
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "This Server is using ["+SYSTEM_NAME+" v"+SYSTEM_VERSION+" created on "+SYSTEM_BUILD_DATE+"]\n");
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "********************************************************************\n");
		
		int index = pPlayer.entindex();
		
		isSpawned[index]=false;
		
		SaveLoad_GenePoints::LoadData(index);
		SaveLoad_ZClasses::LoadData(index);
		SaveLoad_HClasses::LoadData(index);
		//Load KeyValues?
		if(cvar_load_keyvalues==1) SaveLoad_KeyValues::LoadData(index);
		else SaveLoad_KeyValues::loaddata[index]=true;
		
		return HOOK_CONTINUE;
	}
	
	HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer)
	{
		int index = pPlayer.entindex();
		
		isSpawned[index]=false;
		
		SaveLoad_GenePoints::LoadEmpty(index);
		SaveLoad_ZClasses::LoadEmpty(index);
		SaveLoad_HClasses::LoadEmpty(index);
		SaveLoad_KeyValues::LoadEmpty(index);
		
		return HOOK_CONTINUE;
	}
	
	HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
	{
		int index = pPlayer.entindex();
		
		//ZClass
		if(cvar_zclass_onspawn!=-1) {
			if(cvar_zclass_onspawn_once==0) {
				ZClass_Holder[index] = cvar_zclass_onspawn;
				ZClass_MutationState[index] = ZM_MUTATION_NONE;
			} else if(cvar_zclass_onspawn_once==1 && !isSpawned[index]) {
				ZClass_Holder[index] = cvar_zclass_onspawn;
				ZClass_MutationState[index] = ZM_MUTATION_NONE;
			}
		}
		//HClass
		if(cvar_hclass_onspawn!=-1) {
			if(cvar_hclass_onspawn_once==0) {
				HClass_Holder[index] = cvar_hclass_onspawn;
				HClass_Mutation_Holder[index] = cvar_hclass_onspawn;
			} else if(cvar_hclass_onspawn_once==1 && !isSpawned[index]) {
				HClass_Holder[index] = cvar_hclass_onspawn;
				HClass_Mutation_Holder[index] = cvar_hclass_onspawn;
			}
		}
		
		//On Spawn For First Time
		if(!isSpawned[index] && EverythingIsReady4Player(index)) {
			isSpawned[index]=true;
		} else if(!EverythingIsReady4Player(index)){
			g_Scheduler.SetTimeout("SpawnAsDelay", 0.2, index);
			return HOOK_CONTINUE;
		}
		
		//If PVPVM is Enabled and Observer/Human Selected, don't used this, use function in pvpvm.as instead.
		if(cvar_pvpvm!=0) pvpvm::PlayerSpawn(pPlayer);
		else {
			//Fix for headcrabs
			pvpvm::TeamChosen[index]=PVPVM_HEADCRAB;
			pvpvm::TeamProcess(index);
		}

		if(pvpvm::TeamChosen[index]!=PVPVM_HUMAN) {
			g_Scheduler.SetTimeout("SpawnAs", 0.01, index);
		}
		
		return HOOK_CONTINUE;
	}
	
	void SpawnAsDelay(const int& in index)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		if(pPlayer !is null)
			PlayerSpawn(pPlayer);
	}

	void SpawnAs(const int& in index) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		
		if(!EverythingIsReady4Player(index)) {
			pPlayer.RemoveAllItems(false);
			g_Scheduler.SetTimeout("SpawnAsDelay", 0.2, index);
			return;
		}
		
		//Spawn As?
		int spawn_as = cvar_spawn_as;
		
		//Remove All Weapons from Player
		pPlayer.RemoveAllItems(false);
		pPlayer.SetItemPickupTimes(0);
		pPlayer.SetClassification(CLASS_PLAYER);
		
		if(spawn_as==2) {
			//Give 'weapon_zclaws'
			pPlayer.GiveNamedItem("weapon_zclaws");
		} else if(spawn_as==1) {
			//Turn this player into headcrab
			pPlayer.GiveNamedItem("weapon_hclaws");
		} else {
			//Else Load From Previous (From KeyValue '$i_isZombie')
			//Get Player KeyValues
			CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
			int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
			//If this player is a zombie
			if(isZombie==1) {
				//Give 'weapon_zclaws'
				pPlayer.GiveNamedItem("weapon_zclaws");
				HClass_Holder[index] = ZClass_Holder[index];
				HClass_Mutation_Holder[index] = ZClass_Holder[index];
			} else {
				//Turn this player into headcrab
				pPlayer.GiveNamedItem("weapon_hclaws");
			}
		}
	}
	
	void Initialize_Plugin() {
		SYSTEM_PATH = "scripts/plugins/store/hlze/";
		SaveLoad_Cfg::CONFIG_PATH = "scripts/plugins/";
		
		Log("[Plugin Init] Initializing as Plugin!\n");
	}
	
	void Initialize() {
		//Start
		string mapname = string(g_Engine.mapname);
		Log( "----------Starting Save/Load System on MAP:"+mapname+".bsp ----------\n" );
		//Hooks
		g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer,ClientPutInServer);
		g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,ClientDisconnect);
		g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn,PlayerSpawn);
		Log("Hooks...OK!\n");
		//Schedules
		g_Scheduler.SetInterval("DumpVaults",SAVE_TIME,g_Scheduler.REPEAT_INFINITE_TIMES ); //Save Every X.X Seconds
		Log( "Schedules...OK!\n");
		
		//Load
		Log( "Loading Global Config...Requested!\n");
		SaveLoad_Cfg::Load(true,false);
		Log( "Loading Gene Points...Requested!\n");
		SaveLoad_GenePoints::Load();
		Log( "Loading KeyValues...Requested!\n");
		SaveLoad_KeyValues::Load();
		Log( "Loading Headcrab Classes...Requested!\n");
		SaveLoad_HClasses::Load();
		Log( "Loading Zombie Classes...Requested!\n");
		SaveLoad_ZClasses::Load();
		Log( "Loading Per Map Config...Requested!\n");
		SaveLoad_Cfg::Load(false,true);

		//Make Sure everything is Ready
		g_Scheduler.SetTimeout("Initialize_Ready", 0.1);
	}
	
	void Initialize_Ready() {
		if(!EverythingIsReady()) {
			g_Scheduler.SetTimeout("Initialize_Ready", 0.1);
			return;
		}

		//Initialize PvPvM
		if(cvar_pvpvm!=0) {
			pvpvm::Initialize();
		}
		
		//End
		Log( "---------- Save/Load System Initialized! ----------\n" );
	}
	
	void DumpVaults() {
		SaveLoad_GenePoints::Save2File();
		SaveLoad_ZClasses::Save2File();
		SaveLoad_HClasses::SaveDataAll();
		SaveLoad_HClasses::Save2File();
		SaveLoad_KeyValues::SaveDataAll();
		SaveLoad_KeyValues::Save2File();
	}
};

//Custom Log System
void Log(const string& in szMessage, const bool append_time = true) {
	DateTime thetime( UnixTimestamp() );
	int year = thetime.GetYear();
	int month = thetime.GetMonth();
	int day = thetime.GetDayOfMonth();
	int hour = thetime.GetHour();
	int minutes = thetime.GetMinutes();
	int seconds = thetime.GetSeconds();
	
	// Fix for one digit month/day/hour/minute/second
	string szMonths;
	string szDays;
	string szHours;
	string szMinutes;
	string szSeconds;
	if ( month < 10 ) szMonths = "0" + month;
	else szMonths = month;
	if ( day < 10 ) szDays = "0" + day;
	else szDays = day;
	if ( hour < 10 ) szHours = "0" + hour;
	else szHours = hour;
	if ( minutes < 10 ) szMinutes = "0" + minutes;
	else szMinutes = minutes;
	if ( seconds < 10 ) szSeconds = "0" + seconds;
	else szSeconds = seconds;
	
	string fullpath = SYSTEM_PATH + "LOG_" + year + "-" + szMonths + "-" + szDays + ".log";
	
	File@ logfile;
	@logfile = g_FileSystem.OpenFile(fullpath,OpenFile::APPEND);
	if(logfile is null) g_Log.PrintF("Writing to:'"+fullpath+"', FAILED!\n");
	
	if (logfile !is null && logfile.IsOpen())
	{
		if(append_time)
			logfile.Write("["+szHours+":"+szMinutes+":"+szSeconds+"]");
		
		logfile.Write(szMessage);
		logfile.Close();
	}
}