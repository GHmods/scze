//Headcrab Class file for Sven Co-op Zombie Edition
//Gene Points
#include "zombie_classes"
//Gene Points
#include "gene_points"

const string HCLASS_SYSTEM_TAG="[Headcrab Class System]";

//Every Player has selected HClass ID (Default 0)
array<int>HClass_Holder(33);
array<int>HClass_Mutation_Holder(33);

Headcrab_Class@ Get_HeadcrabClass_FromPlayer(CBasePlayer@ pPlayer) {
	int index = HClass_Holder[pPlayer.entindex()];
	return HClasses::Headcrab_Classes[index];
}

namespace HClasses
{
	array<Headcrab_Class@>Headcrab_Classes;
	
	void Init(bool precache_now = true)
	{
		//Just Register Default Class
		Headcrab_Class default_class(Headcrab_Classes);
		//Rushcrab
		//Build Infection Information
		InfectionInfo rushcrab_infectInfo = InfectionInfo();
		rushcrab_infectInfo.BodyScientist={{1,4},{4,2}};
		rushcrab_infectInfo.BodyGuard={{2,2},{3,2}};
		rushcrab_infectInfo.BodyHGruntMaskless={{1,4},{2,3},{3,2}};
		rushcrab_infectInfo.BodyHGrunt={{1,4},{2,4},{3,2}};
		Headcrab_Class rushcrab(Headcrab_Classes,		//Array that is used to register this class
									"Rushcrab",					//Name
									0,						//Cost (Useless)
									20.0,						//Health
									400,						//Speed
									140,						//Voice Pitch
									5.0,						//Damage
									Vector(255,0,0),				//Darkvision Color --> Vector(r,g,b)
									0.5,						//Jump Frequency
									"v_rhclaws.mdl",				//View Model (WITHOUT 'models/....') (it must be stored in 'models/hlze/'
									0,						//View Model Body Number
									"hlze_rushcrab",				//Player Model
									//Message that shows when player mutates to this class
									"You are now 'Rusher' Headcrab Class",
									"Fast and Deadly!",
									rushcrab_infectInfo //Information Used for Models upon Infection
		); //End of this Headcrab Class
		//Crashercrab
		InfectionInfo crashercrab_infectInfo = InfectionInfo();
		crashercrab_infectInfo.BodyScientist={{1,4},{4,3}};
		crashercrab_infectInfo.BodyGuard={{2,2},{3,3}};
		crashercrab_infectInfo.BodyHGruntMaskless={{1,4},{2,5},{3,2}};
		crashercrab_infectInfo.BodyHGrunt={{1,4},{2,6},{3,2}};
		Headcrab_Class crashercrab(Headcrab_Classes,		//Array that is used to register this class
									"Crasher-crab",					//Name
									0,						//Cost (Useless)
									65.0,						//Health
									200,						//Speed
									85,						//Voice Pitch
									20.0,						//Damage
									Vector(255,255,0),				//Darkvision Color --> Vector(r,g,b)
									2.0,						//Jump Frequency
									"v_crasher_hclaws.mdl",				//View Model (WITHOUT 'models/....') (it must be stored in 'models/hlze/'
									0,						//View Model Body Number
									"hlze_crasher_crab",				//Player Model
									//Message that shows when player mutates to this class
									"You are now 'Crasher-crab' Headcrab Class",
									"Strong,Solid and Slow!",
									crashercrab_infectInfo //Information Used for Models upon Infection
		); //End of this Headcrab Class
		//Register abilities to this class
		crashercrab.Register_Ability("Nothing",0);//Toggleable Ability(Must be first!), Leave ("Nothing",0) to ignore this
		crashercrab.Register_Ability("Armor Upgrade",50);
		//----------------------------------------
		//Breeder-crab
		Headcrab_Class breedercrab(Headcrab_Classes,		//Array that is used to register this class
									"Breeder-crab",					//Name
									0,						//Cost (Useless)
									30.0,						//Health
									270,						//Speed
									100,						//Voice Pitch
									8.0,						//Damage
									Vector(255,255,255),				//Darkvision Color --> Vector(r,g,b)
									0.8,						//Jump Frequency
									"v_hclaws.mdl",					//View Model (WITHOUT 'models/....') (it must be stored in 'models/hlze/'
									0,						//View Model Body Number
									"hlze_headcrab",				//Player Model
									//Message that shows when player mutates to this class
									"You are now 'Breeder-crab' Headcrab Class",
									"Intelligent Headcrab."
									//Information Used for Models upon Infection - Same as Default
		); //End of this Headcrab Class
		
		g_Log.PrintF(HCLASS_SYSTEM_TAG+" "+Headcrab_Classes.length());
		
		if(Headcrab_Classes.length()==1) g_Log.PrintF(" Headcrab Class Registered!\n");
		else g_Log.PrintF(" Headcrab Classes Registered!\n");
		
		if(precache_now)
			Precache();
	}
	
	void Precache()
	{
		//Precache
		for(uint i=0;i<Headcrab_Classes.length();i++)
			Headcrab_Classes[i].Precache();
		
		//Precache Mutating
		g_SoundSystem.PrecacheSound("squeek/sqk_blast1.wav");
		g_Game.PrecacheGeneric("sound/squeek/sqk_blast1.wav");
	}
	
	void ResetPlayer(CBasePlayer@ pPlayer) {
		int pId = pPlayer.entindex();
		
		HClass_Holder[pId]=0;
		HClass_Mutation_Holder[pId]=0;
	}
	
	//Hooks
	HookReturnCode PlayerQuit(CBasePlayer@ pPlayer)
	{
		//Reset Player Slot on Quit
		ResetPlayer(pPlayer);
		
		return HOOK_CONTINUE;
	}
};

final class Headcrab_Ability {
	string Name = "Nothing";
	int Cost = 0;
	array<bool>Unlocked(33);
	array<bool>Active(33,true);
	
	Headcrab_Ability(string zName="Nothing",int cost=0) {
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
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,HCLASS_SYSTEM_TAG+" '"+Name+"' is already unlocked!\n");
			return;
		}
		
		if(pGenePts>=Cost) {
			//GenePts_Holder[pId] -= Cost;
			Gene_Points::RemovePoints(pId,Cost);
			Unlocked[pId] = true;
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,HCLASS_SYSTEM_TAG+" '"+Name+"' Ability Unlocked!\n");
		} else {
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,HCLASS_SYSTEM_TAG+" Not enough gene points to unlock '"+Name+"'!\n");
		}
	}
}

final class InfectionInfo {
	//Scientist
	int SkinId_Scientist;
	//<Body Id> will be set to this <Value>
	array<array<int>>BodyScientist;
	//Security Guard
	int SkinId_Guard;
	array<array<int>>BodyGuard;
	//Human Grunt - Maskless
	int SkinId_HGruntMaskless;
	array<array<int>>BodyHGruntMaskless;
	//Human Grunt
	int SkinId_HGrunt;
	array<array<int>>BodyHGrunt;

	InfectionInfo() {
		SkinId_Scientist = 2;
		BodyScientist = {{1,4},{4,1}};
		SkinId_Guard = 1;
		BodyGuard = {{2,2},{3,1}};
		SkinId_HGruntMaskless = 2;
		BodyHGruntMaskless = {{1,4},{2,1},{3,2}};
		SkinId_HGrunt = 2;
		BodyHGrunt = {{1,4},{2,2},{3,2}};
	}
}

final class Headcrab_Class {
	//Is Class Unlocked
	array<bool>HClass_Unlocked(33);
	int HClass_Cost = 0;
	
	//Info
	string Name = "Default";
	
	//Settings
		//Health
	float Health = 35.0;
		//Speed
	int Speed = 80;
		//Voice Pitch
	int VoicePitch = 100;
		//Damage
	float Damage = 10.0;
		//Darkvision Color
	Vector DV_Color(255,128,0); // +ATTACK2 to toggle Darkvision
		//Jump Delay
	float JumpFreq = 1.0;
	//Models
		//View Models
	string VIEW_MODEL = "v_hclaws.mdl";
	int VIEW_MODEL_BODY_ID = 0;
		//Player Model
	string PLAYER_MODEL = "hlze_headcrab";
	
	//Mutation
		//Message
	string MESSAGE = "You are now Default Headcrab Class\n";
	string DESCRIPTION = "You same as NPC Headcrabs!\n";
	
	//Special Abilities
	array<Headcrab_Ability@>Abilities;
	
	float Ability_ToggleDelay = 2.0;
	array<float>Ability_Timer(33);

	//Information used for Victim's Model
	InfectionInfo@ infection_info;
	
	Headcrab_Class(array<Headcrab_Class@>@hc_array,
				string zName="Default",int cost=0,float hp=35.0,int spd=270,int vp=100,
				float dmg=10.0,Vector dvClr = Vector(255,128,0),float jf=1.0,
				string v_mdl="v_hclaws.mdl",int vmd_bodyId=0,string player_mdl="hlze_headcrab",
				string mut_message="",string mut_desc="",
				//Infection Info
				InfectionInfo infectInfo = InfectionInfo()
		) {
		
		Name = zName;
		HClass_Cost = cost;
		Health = hp;
		Speed = spd;
		VoicePitch = vp;
		Damage = dmg;
		DV_Color = dvClr;
		JumpFreq = jf;
		
		VIEW_MODEL = "models/hlze/" + v_mdl;
		VIEW_MODEL_BODY_ID = vmd_bodyId;
		PLAYER_MODEL = player_mdl;
		
		MESSAGE = mut_message;
		DESCRIPTION = mut_desc;

		//Infection Info
		@infection_info = infectInfo;
		
		//If cost is <=0, Unlock this class for all players
		if(HClass_Cost<=0) {
			for(uint i=0;i<HClass_Unlocked.length();i++) {
				HClass_Unlocked[i]=true; //Unlocked!
			}
		}
		
		g_Log.PrintF(HCLASS_SYSTEM_TAG+" '"+Name+"' is Registered!\n");
		hc_array.insertLast(this);
	}
	
	void Precache() {
		g_Game.PrecacheModel(VIEW_MODEL);
		if(PLAYER_MODEL != "null") {
			g_Game.PrecacheGeneric( "models/player/"+PLAYER_MODEL+"/"+PLAYER_MODEL+".bmp" );
			g_Game.PrecacheGeneric( "models/player/"+PLAYER_MODEL+"/"+PLAYER_MODEL+".mdl" );
			g_Game.PrecacheModel( "models/player/"+PLAYER_MODEL+"/"+PLAYER_MODEL+".mdl" );
		}
		g_Log.PrintF(HCLASS_SYSTEM_TAG+" Headcrab Class with Name: "+Name+" Precached!\n");
	}
	
	//Return Values
	string Get_Name() { return Name; }
	float Get_Health() { return Health; }
	
	int Get_MaxSpeed() { return Speed; }
	
	Vector Get_DVColor() { return DV_Color; }
	string Get_VModel() { return VIEW_MODEL; }
	int Get_VModel_BodyID() { return VIEW_MODEL_BODY_ID; }
	string Get_Player_Model() { return PLAYER_MODEL; }
	
	//Append Ability
	void Store_Ability(string abName,int abcost) {
		Headcrab_Ability ability(abName,abcost);
		
		Abilities.insertLast(ability);
		g_Log.PrintF(HCLASS_SYSTEM_TAG+"["+Name+"]["+Abilities.length()+"] Ability[Name:'"+abName+"'|Cost:"+abcost+"] Registered!\n");
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
		bool unlocked=HClass_Unlocked[pId];
		
		if(unlocked) {
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,HCLASS_SYSTEM_TAG+" "+Name+" is already unlocked!\n");
			return;
		}
		
		if(pGenePts>=HClass_Cost) {
			//GenePts_Holder[pId] -= HClass_Cost;
			Gene_Points::RemovePoints(pId,HClass_Cost);
			HClass_Unlocked[pId] = true;
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,HCLASS_SYSTEM_TAG+" "+Name+" Unlocked!\n");
		} else {
			g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,HCLASS_SYSTEM_TAG+" Not enough gene points to unlock "+Name+"!\n");
		}
	}
};

namespace HClass_Menu {
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
			
			if ( text == '/hclass' || text == '/hc')
			{
				HShow_Menu(pPlayer.entindex());
				pParams.ShouldHide = true;
				return HOOK_HANDLED;
			}
			
			if ( text == '/hc_upgrades' || text == '/hc_ability' || text == '/ha' || text == '/hca')
			{
				HShow_Ability_Menu(pPlayer.entindex());
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
	
	void HShow_Menu(const int& in index)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		
		//Only Zombies can choose headcrab class
		CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
		int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
		if(isZombie!=1) {
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, HCLASS_SYSTEM_TAG+"You must be zombie to choose headcrab class!\n");
			return;
		}
		
		uint hclass_count = HClasses::Headcrab_Classes.length();
		
		if(hclass_count==1) {
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, HCLASS_SYSTEM_TAG+"There is only 1 Headcrab Class at the moment!\n");
			return;
		} else if(hclass_count<1) {
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, HCLASS_SYSTEM_TAG+"There are no Headcrab Classes at the moment!\n");
			return;
		}
		
		MenuHandler@ state = MenuGetPlayer(pPlayer);
		
		state.InitMenu(pPlayer,HMenuChoice);
		state.menu.SetTitle( HCLASS_SYSTEM_TAG+" Choose Headcrab Class:\n\n" );
		
		for(uint i=0;i<hclass_count;i++) {
			string HC_Name = HClasses::Headcrab_Classes[i].Name;
			string HC_Desc = HClasses::Headcrab_Classes[i].DESCRIPTION;
			int HC_Cost = HClasses::Headcrab_Classes[i].HClass_Cost;
			bool unlocked=HClasses::Headcrab_Classes[i].HClass_Unlocked[index];
			
			string HC_Num = ""+i;
			string HClass_String = HC_Name;
			if(HC_Desc!="") HClass_String +=" - ["+HC_Desc+"]";
			if(!unlocked) {
				if(HC_Cost>0)
					HClass_String +="[Cost:"+HC_Cost+"]";
				HClass_String +="[LOCKED!]";
			}
			
			if(ZClasses::Zombie_Classes[i].ZClass_Unlocked[index])
				state.menu.AddItem(HClass_String+"\n", any(HC_Num));
		}
		
		state.OpenMenu(pPlayer,0,0);
	}
	
	void HMenuChoice( CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item )
	{
		int index = pPlayer.entindex();
		if ( page == 10 ) return;
		
		string selection;
		item.m_pUserData.retrieve( selection );
		
		int pid = pPlayer.entindex();
		uint hclass_count = HClasses::Headcrab_Classes.length();
		
		for(uint i=0;i<hclass_count;i++) {
			string HC_Name = HClasses::Headcrab_Classes[i].Name;
			string HC_Desc = HClasses::Headcrab_Classes[i].DESCRIPTION;
			int HC_Cost = HClasses::Headcrab_Classes[i].HClass_Cost;
			bool unlocked=HClasses::Headcrab_Classes[i].HClass_Unlocked[index];
			
			string HC_Num = ""+i;
			if(selection == HC_Num) {
				if(unlocked) {
					HClass_Mutation_Holder[pid] = i;
					g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, HCLASS_SYSTEM_TAG+" Leave body to mutate to '"+HC_Name+"'!\n");
				} else {
					HClasses::Headcrab_Classes[i].TryToUnlock(pid);
					g_Scheduler.SetTimeout("HShow_Menu", 0.01, index);
				}
			}
		}
	}
	
	void HShow_Ability_Menu(const int& in index)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
		
		Headcrab_Class@ pHClass = Get_HeadcrabClass_FromPlayer(pPlayer);
		uint hclass_ability_count = pHClass.Get_Ability_Count();
		
		if(pHClass.Get_RealAbility_Count()<1) {
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, HCLASS_SYSTEM_TAG+" Sorry, this headcrab class doesn't have any specific abilities!\n");
			return;
		}
		
		MenuHandler@ state = MenuGetPlayer(pPlayer);
		
		state.InitMenu(pPlayer,HMenuChoice_Ability);
		state.menu.SetTitle( HCLASS_SYSTEM_TAG+" Headcrab Class Upgrades/Abilities:\n\n" );
		
		for(uint i=0;i<hclass_ability_count;i++) {
			string AB_Name = pHClass.Abilities[i].Name;
			int AB_Cost = pHClass.Abilities[i].Cost;
			bool unlocked= pHClass.Abilities[i].Unlocked[index];
			
			string AB_Num = ""+i;
			string Ability_String = AB_Name;
			if(i==0) { //Primary Ability
				Ability_String +=" - [+ATTACK3 to Toggle]";
			}
			if(!unlocked) {
				if(AB_Cost>0) Ability_String +="[Cost:"+AB_Cost+"]";
				Ability_String +="[LOCKED!]";
			} else {
				bool active = pHClass.Abilities[i].Active[index];
				if(active) Ability_String +="[ON]";
				else Ability_String +="[OFF]";
			}
			
			if(AB_Name!="Nothing")
				state.menu.AddItem(Ability_String+"\n", any(AB_Num));
		}
		
		state.OpenMenu(pPlayer,0,0);
	}
	
	void HMenuChoice_Ability(CTextMenu@ menu,CBasePlayer@ pPlayer,int page,const CTextMenuItem@ item)
	{
		int index = pPlayer.entindex();
		if ( page == 10 ) return;
		
		string selection;
		item.m_pUserData.retrieve( selection );
		
		int pid = pPlayer.entindex();
		Headcrab_Class@ pHClass = Get_HeadcrabClass_FromPlayer(pPlayer);
		uint hclass_ability_count = pHClass.Get_Ability_Count();
		
		for(uint i=0;i<hclass_ability_count;i++) {
			string AB_Name = pHClass.Abilities[i].Name;
			int AB_Cost = pHClass.Abilities[i].Cost;
			bool unlocked= pHClass.Abilities[i].Unlocked[index];
			
			string AB_Num = ""+i;
			if(selection == AB_Num) {
				if(unlocked) {
					//Toggle ON/OFF
					pHClass.Abilities[i].Active[pid] = !pHClass.Abilities[i].Active[pid];
				} else {
					pHClass.Abilities[i].TryToUnlock(pid);
				}
			}
		}
		
		g_Scheduler.SetTimeout("HShow_Ability_Menu", 0.01, index);
	}
}