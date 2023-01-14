//Zombie Class file for Sven Co-op Zombie Edition
//Note: To do Special Zombie Class Processing,
//Code it yourself in 'weapon_zombie' inside ZClass_Process() Process, it will be processed evey 0.1 second.
//Special Abilities will be Processed in ZClass_Ability(), they will be triggered with '+attack3' command (Midle Click).

//Example: 
/*
....
	void ZClass_Ability(...) { //Triggered when you press '+ATTACK3' or Midle-Click
		if(ZClass.name == "Your Hardcoded name of your zombie class") {
			//...Do Ability...
		}
	}
....
	void ZClass_Process_Global(...) { //Do not use this for input
		if(ZClass.name == "Your Hardcoded name of your zombie class") {
			//...Do things...
		}
	}
....
	void ZClass_Process_PlayerProcess(...) { //Use this to get input
		...
		int flags = m_pPlayer.pev.flags; //<------- Player Flags
		int old_buttons = m_pPlayer.pev.oldbuttons; //<------- The Button that user was pressing in second frame
		int button = m_pPlayer.pev.button; //<------- The Button that user was pressing in first frame
		int pId = m_pPlayer.entindex(); //<------- Player ID
		...
		
		if(ZClass.name == "Your Hardcoded name of your zombie class") {
			//...Do things...
		}
	}
....
*/
//Gene Points
#include "gene_points"
#include "../save-load/zclass" //Save/Load
//Acid Throw
#include "..\projectiles\acid_throw"

const string ZCLASS_SYSTEM_TAG="[Zombie Class System]";

//Every Player has selected ZClass ID (Default 0)
array<int>ZClass_Holder(33);
array<int>ZClass_MutationState(33);

enum ZM_MutationStates {
	ZM_MUTATION_NONE = 0,
	ZM_MUTATION_BEGIN,
	ZM_MUTATION_MIDLE,
	ZM_MUTATION_END
};

Zombie_Class@ Get_ZombieClass_FromPlayer(CBasePlayer@ pPlayer) {
	int index = ZClass_Holder[pPlayer.entindex()];
	return ZClasses::Zombie_Classes[index];
}

bool ZombieClass_PlayerHasAbility(CBasePlayer@ pPlayer,string szName,bool ShouldBeOn=true) {
	bool hasAbility = false;
	//Null Checker
	if(pPlayer is null)
		return false;
	//Gather Information from this Player
	int pId = pPlayer.entindex();
	CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
	int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
	//int ZWeaponId = atoui(KeyValues.GetKeyvalue("$i_ZombieWeapon").GetString());
	Zombie_Class@ pZClass = Get_ZombieClass_FromPlayer(pPlayer);

	//Make sure Player is not Mutating
	if(ZClass_MutationState[pId]!=ZM_MUTATION_NONE)
		return false;
	
	//Go through the array
	for(uint a=0;a<pZClass.Abilities.length();a++) {
		//Check if unlocked
		if(pZClass.Abilities[a].Unlocked[pId] && isZombie==1) {
			bool proceed=true;
			if(ShouldBeOn) {
				proceed = pZClass.Abilities[a].Active[pId];
			}

			if(proceed) {
				if(pZClass.Abilities[a].Name == szName) {
					hasAbility = true;
					break;
				}
			}
		}
	}

	return hasAbility;
}

namespace ZClasses
{
	array<Zombie_Class@>Zombie_Classes;
	
	void Init(bool precache_now = true)
	{
		//Just Register Default Class
		Zombie_Class default_class(Zombie_Classes);
		
		//Rusher
		Zombie_Class rusher(Zombie_Classes,					//Array that is used to register this class
									"Rusher",				//Name
									40,					//Cost
									40.0,					//Health
									350,					//Speed
									300,					//Speed while crouching
									110,					//Voice Pitch
									50.0,					//Damage
									false,					//Start with Fast Attacking?
									false,					//Can Break 'func_breakable' walls
									true,					//Can Use Headcrabs?
									3.5,					//Degen Rate
									3.0,					//Degen Delay
									Vector(255,0,0),			//Darkvision Color --> Vector(r,g,b)
									Vector(0,0,27),				//View Offset
									"v_zclaws.mdl",				//View Model (WITHOUT 'models/....') (it must be stored in 'models/hlze/'
									6,					//View Model Body Number
									"hlze_rusher",				//Player Model (Leave "null" to use default)
									//Message that shows when player mutates to this class
									"You are now 'Rusher' Zombie Class",
									"Fast and Deadly!"
		); //End of this Zombie Class
		//Register abilities to this class
		rusher.Register_Ability("Frenzy Mode",30);//Toggleable Ability(Must be first!), Leave ("Nothing",0) to ignore this
		rusher.Register_Ability("Long Jump",15);
		//----------------------------------------
		//Crasher
		Zombie_Class crasher(Zombie_Classes,				//Array that is used to register this class
									"Crasher",				//Name
									70,					//Cost
									200.0,					//Health
									100,					//Speed
									80,					//Speed while crouching
									80,					//Voice Pitch
									300.0,					//Damage
									false,					//Start with Fast Attacking?
									true,					//Can Break 'func_breakable' walls?
									true,					//Can Use Headcrabs?
									11.0,					//Degen Rate
									50.0,					//Degen Delay
									Vector(255,255,0),			//Darkvision Color --> Vector(r,g,b)
									Vector(0,0,45),				//View Offset
									"v_zclaws.mdl",				//View Model (WITHOUT 'models/....') (it must be stored in 'models/hlze/'
									9,					//View Model Body Number
									"hlze_crasher",				//Player Model (Leave "null" to use default)
									//Message that shows when player mutates to this class
									"You are now 'Crasher' Zombie Class",
									"Strong,Solid and Slow!"
		); //End of this Zombie Class
		//Register abilities to this class
		crasher.Register_Ability("Acid Throw",80);	//+ATTACK3
		acid_throw_Init(); //Register our Entity
		crasher.Register_Ability("Shield [Secondary Attack to Toggle]",80);
		crasher.Register_Ability("Armor Upgrade (+50)",30); //+50 Armor
		//----------------------------------------
		//Breeder
		Zombie_Class breeder(Zombie_Classes,			//Array that is used to register this class
									"Breeder",				//Name
									90,					//Cost
									60.0,					//Health
									80,					//Speed
									160,					//Speed while crouching
									100,					//Voice Pitch
									20.0,					//Damage
									false,					//Start with Fast Attacking?
									false,					//Can Break 'func_breakable' walls?
									true,					//Can Use Headcrabs?
									5.0,					//Degen Rate
									15.0,					//Degen Delay
									Vector(255,255,255),			//Darkvision Color --> Vector(r,g,b)
									Vector(0,0,27),				//View Offset
									"v_zclaws.mdl",				//View Model (WITHOUT 'models/....') (it must be stored in 'models/hlze/'
									3,					//View Model Body Number
									"hlze_breeder",				//Player Model (Leave "null" to use default)
									//Message that shows when player mutates to this class
									"You are now 'Breeder' Zombie Class",
									"Incubator for parasites!"
		); //End of this Zombie Class
		//Register abilities to this class
		breeder.Register_Ability("Move Command",80);	//+ATTACK3
		breeder.Register_Ability("Mass Ressurect - [Secondary Attack to Use]",80);	//+ATTACK2
		breeder.Register_Ability("Baby Crabs",80);
		breeder.Register_Ability("Zombie Orders",30);
		breeder.Register_Ability("Barnacles",80); //Barnacles
		breeder.Register_Ability("Ammo Upgrade",30);
		breeder.Register_Ability("Armor Upgrade (+25)",40); //+25 Armor
		//----------------------------------------
		
		g_Log.PrintF(ZCLASS_SYSTEM_TAG+" "+Zombie_Classes.length());
		
		if(Zombie_Classes.length()==1) g_Log.PrintF(" Zombie Class Registered!\n");
		else g_Log.PrintF(" Zombie Classes Registered!\n");
		
		if(precache_now)
			Precache();
	}
	
	void Precache()
	{
		//Precache
		for(uint i=0;i<Zombie_Classes.length();i++)
			Zombie_Classes[i].Precache();
		
		//Precache Rusher
		PrecacheSounds({
			"hlze/player/fz_frenzy1.wav",
			"hlze/player/fz_scream1.wav",
			"hlze/player/leap1.wav"
		});
	}
	
	void ResetPlayer(CBasePlayer@ pPlayer) {
		int pId = pPlayer.entindex();
		
		ZClass_Holder[pId]=0;
		ZClass_MutationState[pId]=ZM_MUTATION_NONE;
	}
	
	//Hooks
	HookReturnCode PlayerQuit(CBasePlayer@ pPlayer)
	{
		//Reset Player Slot on Quit
		ResetPlayer(pPlayer);
		
		return HOOK_CONTINUE;
	}
};
//Zombie Ability
final class Zombie_Ability {
	string Name = "Nothing";
	int Cost = 0;
	array<bool>Unlocked(33);
	array<bool>Active(33,true);
	
	Zombie_Ability(string zName="Nothing",int cost=0) {
		bool unlocked=false;
		
		if(cost<=0) unlocked=true;
		
		Name=zName;
		Cost=cost;
		for(uint i=0;i<Unlocked.length();i++) {
			Unlocked[i]=unlocked;
		}
	}
	
	//Try to Unlock/Buy
	void TryToUnlock(int pId) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(pId);
		if(pPlayer is null)
			return;
		
		int pGenePts = GenePts_Holder[pId];
		bool unlocked = Unlocked[pId];
		
		if(unlocked) {
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,ZCLASS_SYSTEM_TAG+" '"+Name+"' is already unlocked!\n");
			return;
		}
		
		if(pGenePts>=Cost) {
			//GenePts_Holder[pId] -= Cost;
			Gene_Points::RemovePoints(pId,Cost);
			Unlocked[pId] = true;
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,ZCLASS_SYSTEM_TAG+" '"+Name+"' Ability Unlocked!\n");
		} else {
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,ZCLASS_SYSTEM_TAG+" Not enough gene points to unlock '"+Name+"'!\n");
		}
		
		SaveLoad_ZClasses::SaveData(pId);
	}
}
//Zombie Class
final class Zombie_Class {
	//Is Class Unlocked
	array<bool>ZClass_Unlocked(33);
	int ZClass_Cost = 0;
	
	//Info
	string Name = "Default";
	
	//Settings
		//Health (Ingame Armor)
	float Health = 80.0;
		//Speed
	int Speed = 80;
	int Speed_crouch = 160;
		//Voice Pitch
	int VoicePitch = 100;
		//Damage
	float Damage = 30.0;
		//Start with Fast Attack?
	bool FastAttack = false;
		//Can Break Walls?
	bool BreakWalls = false;
		//Can Use Headcrabs?
	bool UseHeadcrabs = true;
		//Degen
	float DegenRate = 8.0; // -1 Health(Armor) Every [n] second(s)
	float DegenDelay = 25.0; // [n] second(s) Delay before degen starts.
		//Darkvision Color
	Vector DV_Color(255,128,0); // use 'darkvision' command to toggle Darkvision
		//View Offset
	Vector ZView_Offset(0,0,27);
	//Models
		//View Models
	string VIEW_MODEL = "models/hlze/v_zclaws.mdl";
	int VIEW_MODEL_BODY_ID = 0;
		//Player Model
	string PLAYER_MODEL = "null"; //'null' means default or based on the infection type(ex: scientist, guard or hgrunt...)
	
	//Mutation
		//Message
	string MUTATION_MESSAGE = "You are now Default Zombie Class\n";
	string MUTATION_DESCRIPTION = "You same as NPC Zombies!\n";
	
	//Special Abilities
	array<Zombie_Ability@>Abilities;
	
	float Ability_ToggleDelay = 2.0;
	array<float>Ability_Timer(33);
	
	Zombie_Class(array<Zombie_Class@>@zc_array,
				string zName="Default",int cost=0,float hp=80.0,int spd=80,int spd_c=160,int vp=100,
				float dmg=30.0,bool fast_attack=false, bool breakWalls=false,bool useHc=true,
				float dgRate=8.0,float dgDelay=25.0,Vector dvClr = Vector(255,128,0),Vector viewOfs = Vector(0,0,27),string v_mdl="v_zclaws.mdl",
				int vmd_bodyId=0,string player_mdl="null",string mut_message="",string mut_desc=""
		) {
		Name = zName;
		ZClass_Cost = cost;
		Health = hp;
		Damage = dmg;
		Speed = spd;
		Speed_crouch = spd_c;
		VoicePitch = vp;
		FastAttack = fast_attack;
		BreakWalls = breakWalls;
		UseHeadcrabs = useHc;
		DegenRate = dgRate;
		DegenDelay = dgDelay;
		DV_Color = dvClr;
		ZView_Offset = viewOfs;
		VIEW_MODEL = "models/hlze/" + v_mdl;
		VIEW_MODEL_BODY_ID = vmd_bodyId;
		PLAYER_MODEL = player_mdl;
		MUTATION_MESSAGE = mut_message;
		MUTATION_DESCRIPTION = mut_desc;
		
		//If cost is <=0, Unlock this class for all players
		if(ZClass_Cost<=0) {
			for(uint i=0;i<ZClass_Unlocked.length();i++) {
				ZClass_Unlocked[i]=true; //Unlocked!
			}
		}
		
		g_Log.PrintF(ZCLASS_SYSTEM_TAG+" '"+Name+"' is Registered!\n");
		zc_array.insertLast(this);
	}
	
	void Precache() {
		g_Game.PrecacheModel(VIEW_MODEL);
		if(PLAYER_MODEL != "null") {
			g_Game.PrecacheGeneric( "models/player/"+PLAYER_MODEL+"/"+PLAYER_MODEL+".bmp" );
			g_Game.PrecacheGeneric( "models/player/"+PLAYER_MODEL+"/"+PLAYER_MODEL+".mdl" );
			g_Game.PrecacheModel( "models/player/"+PLAYER_MODEL+"/"+PLAYER_MODEL+".mdl" );
		}
		g_Log.PrintF(ZCLASS_SYSTEM_TAG+" Zombie Class with Name: "+Name+" Precached!\n");
	}
	
	//Return Values
	string Get_Name() { return Name; }
	float Get_Health() { return Health; }
	
	int Get_MaxSpeed(bool crouching = false) {
		if(crouching)
			return Speed_crouch;
		
		return Speed;
	}
	
	bool Is_FastAttacking() { return FastAttack; }
	float Get_DegenRate() { return DegenRate; }
	float Get_DegenDelay() { return DegenDelay; }
	Vector Get_DVColor() { return DV_Color; }
	string Get_VModel() { return VIEW_MODEL; }
	int Get_VModel_BodyID() { return VIEW_MODEL_BODY_ID; }
	string Get_Player_Model() { return PLAYER_MODEL; }
	
	//Append Ability
	void Store_Ability(string abName,int abcost) {
		Zombie_Ability ability(abName,abcost);
		
		Abilities.insertLast(ability);
		g_Log.PrintF(ZCLASS_SYSTEM_TAG+"["+Name+"]["+Abilities.length()+"] Ability[Name:'"+abName+"'|Cost:"+abcost+"] Registered!\n");
	}
	
	int Get_Ability_Count() {
		return Abilities.length();
	}
	
	int Get_RealAbility_Count() {
		int counter=0;
		for(uint i=0;i<Abilities.length();i++) {
			if(Abilities[i].Name != "Nothing")
				counter++;
		}
		
		return counter;
	}
	
	//Register/Add Ability
	void Register_Ability(string abName,int abCost) {
		Store_Ability(abName,abCost);
	}
	
	//Try to Unlock/Buy
	void TryToUnlock(int pId) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(pId);
		if(pPlayer is null)
			return;
		
		int pGenePts = GenePts_Holder[pId];
		bool unlocked=ZClass_Unlocked[pId];
		
		if(unlocked) {
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,ZCLASS_SYSTEM_TAG+" "+Name+" is already unlocked!\n");
			return;
		}
		
		if(pGenePts>=ZClass_Cost) {
			//GenePts_Holder[pId] -= ZClass_Cost;
			Gene_Points::RemovePoints(pId,ZClass_Cost);
			ZClass_Unlocked[pId] = true;
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,ZCLASS_SYSTEM_TAG+" "+Name+" Unlocked!\n");
		} else {
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,ZCLASS_SYSTEM_TAG+" Not enough gene points to unlock "+Name+"!\n");
		}
		
		SaveLoad_ZClasses::SaveData(pId);
	}
};

namespace ZClass_Menu {
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
			
			if ( text == '/zclass' || text == '/zombie_class' || text == '/zc')
			{
				Show_Menu(pPlayer.entindex());
				pParams.ShouldHide = true;
				return HOOK_HANDLED;
			}
			
			if ( text == '/upgrades' || text == '/ability' || text == '/abilities' || text == '/za')
			{
				Show_Ability_Menu(pPlayer.entindex());
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
	
	void Show_Menu(const int& in index)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		
		uint zclass_count = ZClasses::Zombie_Classes.length();
		
		if(zclass_count==1) {
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, ZCLASS_SYSTEM_TAG+"There is only 1 Zombie Class at the moment!\n");
			return;
		} else if(zclass_count<1) {
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, ZCLASS_SYSTEM_TAG+"There are no Zombie Classes at the moment!\n");
			return;
		}
		
		MenuHandler@ state = MenuGetPlayer(pPlayer);
		
		state.InitMenu(pPlayer,MenuChoice);
		state.menu.SetTitle( ZCLASS_SYSTEM_TAG+" Choose Zombie Class:\n\n" );
		
		for(uint i=0;i<zclass_count;i++) {
			string ZC_Name = ZClasses::Zombie_Classes[i].Name;
			string ZC_Desc = ZClasses::Zombie_Classes[i].MUTATION_DESCRIPTION;
			int ZC_Cost = ZClasses::Zombie_Classes[i].ZClass_Cost;
			bool unlocked=ZClasses::Zombie_Classes[i].ZClass_Unlocked[index];
			
			string ZC_Num = ""+i;
			string ZClass_String = ZC_Name;
			if(ZC_Desc!="") ZClass_String +=" - ["+ZC_Desc+"]";
			if(!unlocked) {
				if(ZC_Cost>0)
					ZClass_String +="[Cost:"+ZC_Cost+"]";
				ZClass_String +="[LOCKED!]";
			}
			state.menu.AddItem(ZClass_String+"\n", any(ZC_Num));
		}
		
		state.OpenMenu( pPlayer, 0, 0 );
	}
	
	void MenuChoice( CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item )
	{
		int index = pPlayer.entindex();
		if ( page == 10 ) return;
		
		string selection;
		item.m_pUserData.retrieve( selection );
		
		int pid = pPlayer.entindex();
		uint zclass_count = ZClasses::Zombie_Classes.length();
		
		for(uint i=0;i<zclass_count;i++) {
			string ZC_Name = ZClasses::Zombie_Classes[i].Name;
			string ZC_Desc = ZClasses::Zombie_Classes[i].MUTATION_DESCRIPTION;
			int ZC_Cost = ZClasses::Zombie_Classes[i].ZClass_Cost;
			bool unlocked=ZClasses::Zombie_Classes[i].ZClass_Unlocked[index];
			
			string ZC_Num = ""+i;
			if(selection == ZC_Num) {
				if(unlocked) {
					ZClass_Holder[pid] = i;
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, ZCLASS_SYSTEM_TAG+"'"+ZC_Name+"' Selected!\n");
					SaveLoad_ZClasses::SaveData(pid);
				} else {
					ZClasses::Zombie_Classes[i].TryToUnlock(pid);
					g_Scheduler.SetTimeout("Show_Menu", 0.01, index);
				}
			}
		}
	}
	
	void Show_Ability_Menu(const int& in index)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		
		Zombie_Class@ pZClass = Get_ZombieClass_FromPlayer(pPlayer);
		uint zclass_ability_count = pZClass.Get_Ability_Count();
		
		if(pZClass.Get_RealAbility_Count()<1) {
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, ZCLASS_SYSTEM_TAG+" Sorry, this zombie class doesn't have any specific abilities!\n");
			return;
		}
		
		MenuHandler@ state = MenuGetPlayer(pPlayer);
		
		state.InitMenu(pPlayer,MenuChoice_Ability);
		state.menu.SetTitle( ZCLASS_SYSTEM_TAG+" Zombie Class Upgrades/Abilities:\n\n" );
		
		for(uint i=0;i<zclass_ability_count;i++) {
			string AB_Name = pZClass.Abilities[i].Name;
			int AB_Cost = pZClass.Abilities[i].Cost;
			bool unlocked= pZClass.Abilities[i].Unlocked[index];
			
			string AB_Num = ""+i;
			string Ability_String = AB_Name;
			if(i==0) { //Primary Ability
				Ability_String +=" - [Tertiary Attack to Use]";
			}
			if(!unlocked) {
				if(AB_Cost>0) Ability_String +="[Cost:"+AB_Cost+"]";
				Ability_String +="[LOCKED!]";
			} else {
				bool active = pZClass.Abilities[i].Active[index];
				if(active) Ability_String +="[ON]";
				else Ability_String +="[OFF]";
			}
			
			if(AB_Name!="Nothing")
				state.menu.AddItem(Ability_String+"\n", any(AB_Num));
		}
		
		state.OpenMenu(pPlayer,0,0);
	}
	
	void MenuChoice_Ability(CTextMenu@ menu,CBasePlayer@ pPlayer,int page,const CTextMenuItem@ item)
	{
		int index = pPlayer.entindex();
		if ( page == 10 ) return;
		
		string selection;
		item.m_pUserData.retrieve( selection );
		
		int pid = pPlayer.entindex();
		Zombie_Class@ pZClass = Get_ZombieClass_FromPlayer(pPlayer);
		uint zclass_ability_count = pZClass.Get_Ability_Count();
		
		for(uint i=0;i<zclass_ability_count;i++) {
			string AB_Name = pZClass.Abilities[i].Name;
			int AB_Cost = pZClass.Abilities[i].Cost;
			bool unlocked=pZClass.Abilities[i].Unlocked[index];
			
			string AB_Num = ""+i;
			if(selection == AB_Num) {
				if(unlocked) {
					//Toggle ON/OFF
					pZClass.Abilities[i].Active[pid] = !pZClass.Abilities[i].Active[pid];
				} else {
					pZClass.Abilities[i].TryToUnlock(pid);
				}
				SaveLoad_ZClasses::SaveData(pid);
			}
		}
		
		g_Scheduler.SetTimeout("Show_Ability_Menu", 0.01, index);
	}
}