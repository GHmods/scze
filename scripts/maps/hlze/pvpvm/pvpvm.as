//Players VS Players VS Monsters Sven Co-op Zombie Edition
#include "../save-load/base"
#include "../unstuck"

enum PVPVM_Teams_Enum {
	PVPVM_OBSERVER = 0,
	PVPVM_HUMAN,
	PVPVM_HEADCRAB
};

array<string>PVPVM_Teams = {
	"Spectator/Observer",
	"Humans",
	"Headcrabs"
};

const string PVPVM_SYSTEM_TAG="[PvPvM]";

namespace pvpvm {
	array<bool>TeamChosenReminder(33,false); //Just to remind players that they can choose teams
	
	array<int>TeamChosen(33,PVPVM_OBSERVER);
	array<EHandle>Human_SpawnPoints;
	array<EHandle>Headcrab_SpawnPoints;
	
	void Initialize() {
		//Set Default Team
		int default_team = SaveLoad::cvar_pvpvm_team;
		
		if(default_team<PVPVM_OBSERVER) default_team = PVPVM_OBSERVER;
		else if(default_team>PVPVM_HEADCRAB) default_team = PVPVM_HEADCRAB;
		for(uint i=0;i<33;i++) {
			TeamChosen[i] = default_team;
		}
		
		Log(PVPVM_SYSTEM_TAG+" Default Team is:"+PVPVM_Teams[default_team]+".\n");
		
		//Initialize_SpawnPoints();
		int SpawnPointType = SaveLoad::cvar_pvpvm_spawn_system;
		if(SpawnPointType==0) Initialize_SpawnPoints_Type0();
		if(SpawnPointType==1) Initialize_SpawnPoints_Type1();
		if(SpawnPointType==2) Initialize_SpawnPoints_Type2();
		
		//Hooks
		g_Hooks.RegisterHook(Hooks::Player::ClientSay,pvpvm_menu::ClientSay);
		g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink,PlayerThink);
		Log(PVPVM_SYSTEM_TAG+" Hooks...OK.\n");
		
		Log(PVPVM_SYSTEM_TAG+" Initialized!\n");
	}
	
	HookReturnCode PlayerThink(CBasePlayer@ pPlayer, uint& out dummy )
	{
		int index = pPlayer.entindex();
		
		Unstuck::UnstuckPlayer(pPlayer);
		
		return HOOK_CONTINUE;
	}
	
	void TeamProcess(const int& in index) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(index);
		
		if(pPlayer !is null) {
			if(TeamChosen[index] == PVPVM_OBSERVER) {
				if(pPlayer.m_flRespawnDelayTime <= g_Engine.time)
					pPlayer.m_flRespawnDelayTime+=2.0;
			} else if(TeamChosen[index] == PVPVM_HUMAN) {
				pPlayer.SetMaxSpeedOverride(270);
			}
		}
		
		g_Scheduler.SetTimeout("TeamProcess",0.1, index);
	}
	
	void Initialize_SpawnPoints_Type0() {
		//Search for all entities
		array<CBaseEntity@>searchedEntities(1000);
		Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
		Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
		g_EntityFuncs.EntitiesInBox(searchedEntities, mins, maxs, 0);
		
		int found_ents = 0;
		for(uint i=0;i<searchedEntities.length();i++) {
			CBaseEntity@ ent = searchedEntities[i];
			//Check if the entity is not NULL
			if(ent !is null) {
				if(ent.pev.classname=="info_target" && ent.pev.targetname=="info_human_spawn") {
					Human_SpawnPoints.insertLast(EHandle(ent));
					found_ents++;
				} else if(ent.pev.classname=="info_player_start") {
					Headcrab_SpawnPoints.insertLast(EHandle(ent));
					found_ents++;
				}
			}
		}
		
		Log(PVPVM_SYSTEM_TAG+" Found "+found_ents+" Spawn Points!\n");
	}
	
	void Initialize_SpawnPoints_Type1() {
		//Search for all entities
		array<CBaseEntity@>searchedEntities(1000);
		Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
		Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
		g_EntityFuncs.EntitiesInBox(searchedEntities, mins, maxs, 0);
		
		int found_ents = 0;
		for(uint i=0;i<searchedEntities.length();i++) {
			CBaseEntity@ ent = searchedEntities[i];
			//Check if the entity is not NULL
			if(ent !is null) {
				if(ent.pev.classname=="info_player_start") {
					Human_SpawnPoints.insertLast(EHandle(ent));
					found_ents++;
				} else if(ent.pev.classname=="monster_headcrab") {
					Headcrab_SpawnPoints.insertLast(EHandle(ent));
					found_ents++;
				}
			}
		}
		
		Log(PVPVM_SYSTEM_TAG+" Found "+found_ents+" Spawn Points!\n");
	}
	
	void Initialize_SpawnPoints_Type2() {
		//Search for all entities
		array<CBaseEntity@>searchedEntities(1000);
		Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
		Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
		g_EntityFuncs.EntitiesInBox(searchedEntities, mins, maxs, 0);
		
		int found_ents = 0;
		for(uint i=0;i<searchedEntities.length();i++) {
			CBaseEntity@ ent = searchedEntities[i];
			//Check if the entity is not NULL
			if(ent !is null) {
				if(ent.pev.classname=="info_player_start") {
					Human_SpawnPoints.insertLast(EHandle(ent));
					found_ents++;
				} else if(ent.pev.classname=="monster_zombie") {
					Headcrab_SpawnPoints.insertLast(EHandle(ent));
					found_ents++;
				}
			}
		}
		
		Log(PVPVM_SYSTEM_TAG+" Found "+found_ents+" Spawn Points!\n");
	}
	
	Vector Get_HumanSpawnPoint() {
		CBaseEntity@ SpawnPoint = Human_SpawnPoints[Math.RandomLong(0,Human_SpawnPoints.length()-1)];
		Vector Location(0.0,0.0,0.0);
		
		if(SpawnPoint !is null)
			Location = SpawnPoint.pev.origin;
		
		return Location;
	}
	
	Vector Get_HeadcrabSpawnPoint() {
		CBaseEntity@ SpawnPoint = Headcrab_SpawnPoints[Math.RandomLong(0,Headcrab_SpawnPoints.length()-1)];
		Vector Location(0.0,0.0,0.0);
		
		if(SpawnPoint !is null)
			Location = SpawnPoint.pev.origin + Vector(0.0,0.0,18.0);
		
		return Location;
	}
	
	void PlayerSpawn(CBasePlayer@ pPlayer) {
		int index = pPlayer.entindex();
		
		g_Scheduler.SetTimeout("PvPvM_Reminder",3.5, index);
		
		NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict());
			m.WriteString("-duck;");
		m.End();
		
		int player_team = TeamChosen[index];
		if(player_team == PVPVM_OBSERVER) {
			//Force Observer Mode
			Observer@ pObserver = pPlayer.GetObserver();
			pObserver.StartObserver(pPlayer.pev.origin, pPlayer.pev.v_angle, false);
			pObserver.SetMode(OBS_ENTERING);
		} else if(player_team == PVPVM_HUMAN) {
			SpawnHuman(pPlayer);
		} else if(player_team == PVPVM_HEADCRAB) {
			SpawnHeadcrab(pPlayer);
		}
		
		g_Scheduler.SetTimeout("TeamProcess",1.0, index);
	}
	
	void SetRespawnTime(CBasePlayer@ pPlayer)
	{
		//pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
		Observer@ pObserver = pPlayer.GetObserver();
		pObserver.SetMode(OBS_ENTERING);
	}
	
	void SetObserver(CBasePlayer@ pPlayer)
	{
		int index = pPlayer.entindex();
		TeamChosen[index] = PVPVM_OBSERVER;
		pPlayer.SetClassification(CLASS_PLAYER);
		
		pPlayer.pev.team = PVPVM_OBSERVER;
		Observer@ pObserver = pPlayer.GetObserver();
		pObserver.StartObserver(pPlayer.pev.origin, pPlayer.pev.v_angle, false);
		pObserver.SetMode(OBS_ENTERING);
		//g_Scheduler.SetTimeout("SetRespawnTime", .75f, @pPlayer);
		
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, PVPVM_SYSTEM_TAG+"You are now spectator/observer!\n");
		
		pPlayer.RemoveAllItems(false);
		pPlayer.SetItemPickupTimes(0);
		
		pPlayer.m_flRespawnDelayTime = 5.0;
	}
	
	void SetHuman(CBasePlayer@ pPlayer)
	{
		int index = pPlayer.entindex();
		TeamChosen[index] = PVPVM_HUMAN;
		
		pPlayer.pev.team = PVPVM_HUMAN;
		pPlayer.SetClassification(CLASS_TEAM1);
		
		Observer@ pObserver = pPlayer.GetObserver();
		pObserver.StartObserver(pPlayer.pev.origin, pPlayer.pev.v_angle, false);
		
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, PVPVM_SYSTEM_TAG+" Human team selected!\n");
		
		pPlayer.RemoveAllItems(false);
		pPlayer.SetItemPickupTimes(0);
		
		pPlayer.m_flRespawnDelayTime = 5.0;
	}
	
	void SetHeadcrab(CBasePlayer@ pPlayer)
	{
		int index = pPlayer.entindex();
		TeamChosen[index] = PVPVM_HEADCRAB;
		
		pPlayer.SetClassification(CLASS_PLAYER);
		
		Observer@ pObserver = pPlayer.GetObserver();
		pObserver.StartObserver(pPlayer.pev.origin, pPlayer.pev.v_angle, false);
		
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, PVPVM_SYSTEM_TAG+" Headcrab team selected!\n");
		
		pPlayer.RemoveAllItems(false);
		pPlayer.SetItemPickupTimes(0);
		
		pPlayer.m_flRespawnDelayTime = 5.0;
	}
	
	void SpawnHuman(CBasePlayer@ pPlayer)
	{
		int index = pPlayer.entindex();
		
		pPlayer.SetClassification(CLASS_TEAM1);
		pPlayer.pev.team = PVPVM_HUMAN;
		pPlayer.SetMaxSpeedOverride(270);
		
		//Relocate Player
		if(Human_SpawnPoints.length() != 0) {
			Vector Location = Get_HumanSpawnPoint();
			pPlayer.pev.origin = Location;
		}
		
		//Set Player Models
		array<string>@ playerModels = SaveLoad::cvar_pvpvm_models.Split(';');
		/*
		Log(PVPVM_SYSTEM_TAG+" Player Models Config:"+SaveLoad::cvar_pvpvm_models+".\n");
		Log(PVPVM_SYSTEM_TAG+" Found "+playerModels.length()+" Player Models!\n");
		Log(PVPVM_SYSTEM_TAG+" Player Models:");
		for(uint i=0;i<playerModels.length();i++) {
			Log(playerModels[i],false);
			if(i<playerModels.length()-1)
				Log(",",false);
		}
		Log("\n",false);
		*/
		pPlayer.SetOverriddenPlayerModel(playerModels[Math.RandomLong(0,playerModels.length()-1)]);
	}
	
	void SpawnHeadcrab(CBasePlayer@ pPlayer)
	{
		int index = pPlayer.entindex();
		
		pPlayer.SetClassification(CLASS_PLAYER);
		pPlayer.pev.team = PVPVM_HEADCRAB;
		
		//Relocate Player
		//Log(PVPVM_SYSTEM_TAG+" Headcrab Spawn Points:"+Headcrab_SpawnPoints.length()+".\n");
		if(Headcrab_SpawnPoints.length() != 0) {
			Vector Location = Get_HeadcrabSpawnPoint();
			pPlayer.pev.origin = Location;
		}
	}
	
	void PvPvM_Reminder(const int& in index) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		
		if(!TeamChosenReminder[index] && pPlayer !is null) {
			
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"Players vs Players vs Monsters is Activated on this map!\n");
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"Say:/choose_team,/team,/t or /ct to choose team!\n");
			TeamChosenReminder[index] = true;
		}
	}
}

namespace pvpvm_menu {
	dictionary pmenu_state;
	class MenuHandler
	{
		CTextMenu@ menu;
		
		void InitMenu( CBasePlayer@ pPlayer, TextMenuPlayerSlotCallback@ callback )
		{
			CTextMenu temp( @callback );
			@menu = @temp;
		}
		
		void OpenMenu( CBasePlayer@ pPlayer, int& in time, int& in page )
		{
			menu.Register();
			menu.Open( time, page, pPlayer );
		}
	}
	
	//Say
	HookReturnCode ClientSay( SayParameters@ pParams ) {
		ClientSayType type = pParams.GetSayType();
		if ( type == CLIENTSAY_SAY ) {
			CBasePlayer@ pPlayer = pParams.GetPlayer();
			string text = pParams.GetCommand();
			text.ToLowercase();
			
			if ( text == '/team' || text == '/choose_team' || text == '/t' || text == '/ct')
			{
				ChooseTeam_Menu(pPlayer.entindex());
				pParams.ShouldHide = true;
				return HOOK_HANDLED;
			}
		}
		
		return HOOK_CONTINUE;
	}
	
	MenuHandler@ MenuGetPlayer( CBasePlayer@ pPlayer )
	{
		string steamid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
		if ( steamid == 'STEAM_ID_LAN' )
		{
			steamid = pPlayer.pev.netname;
		}
		
		if ( !pmenu_state.exists( steamid ) )
		{
			MenuHandler state;
			pmenu_state[ steamid ] = state;
		}
		return cast< MenuHandler@ >( pmenu_state[ steamid ] );
	}
	
	void ChooseTeam_Menu(const int& in index)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		
		MenuHandler@ state = MenuGetPlayer(pPlayer);
		
		state.InitMenu(pPlayer,ChooseTeam_MenuChoice);
		state.menu.SetTitle( PVPVM_SYSTEM_TAG+" Choose Team:\n\n" );
		
		state.menu.AddItem(PVPVM_Teams[PVPVM_OBSERVER]+"\n", any("team_obsrv"));
		state.menu.AddItem(PVPVM_Teams[PVPVM_HUMAN]+"\n", any("team_hm"));
		state.menu.AddItem(PVPVM_Teams[PVPVM_HEADCRAB]+"\n", any("team_hc"));
		
		state.OpenMenu( pPlayer, 0, 0 );
	}
	
	void ChooseTeam_MenuChoice( CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item )
	{
		int index = pPlayer.entindex();
		if ( page == 10 ) return;
		
		string selection;
		item.m_pUserData.retrieve( selection );
		
		int pid = pPlayer.entindex();
		uint zclass_count = ZClasses::Zombie_Classes.length();
		
		if(selection == "team_obsrv") {
			if(pvpvm::TeamChosen[index] != PVPVM_OBSERVER) {
				pvpvm::SetObserver(pPlayer);
			} else {
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, PVPVM_SYSTEM_TAG+"You already are spectator/observer!\n");
				g_Scheduler.SetTimeout("ChooseTeam_Menu", 0.01, index);
			}
		} else if(selection == "team_hm") {
			if(pvpvm::TeamChosen[index] != PVPVM_HUMAN) {
				pvpvm::SetHuman(pPlayer);
			} else {
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, PVPVM_SYSTEM_TAG+"You already are on human team!\n");
				g_Scheduler.SetTimeout("ChooseTeam_Menu", 0.01, index);
			}
		} else if(selection == "team_hc") {
			if(pvpvm::TeamChosen[index] != PVPVM_HEADCRAB) {
				pvpvm::SetHeadcrab(pPlayer);
			} else {
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, PVPVM_SYSTEM_TAG+"You already are on headcrab team!\n");
				g_Scheduler.SetTimeout("ChooseTeam_Menu", 0.01, index);
			}
		}
	}
}