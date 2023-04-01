//Events file for Sven Co-op Zombie Edition
#include "entities/player_animator"
#include "classes/zombie_classes"
#include "classes/headcrab_classes"
#include "weapons/weapon_headcrab"
#include "weapons/weapon_zombie"
#include "classes/gene_points"
//Save/Load System
#include "save-load/base"

array<bool>Reminder(33,false);

void Events_PluginInit()
{
	//Save/Load
	SaveLoad::Initialize_Plugin();
}

void Events_MapInit()
{
	AS_Log("This Server is Running Half-Life:Zombie Edition Ported to Sven Co-Op by Game Hunter.\n");

	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @PlayerQuit);
	g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink,@Event_PlayerThink);

	//Headcrab PreThink
	g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink, HC_Think);
	//ZClass PreThink
	g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink, ZClass_Think);
	g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, ZC_TakeDamage);
	
	//Gene Points
	Gene_Points::Precache();
	g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, Gene_Points::PlayerJoin);
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, Gene_Points::PlayerQuit);
	g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, Gene_Points::PlayerThink);
	
	//Zombie Classes
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,ZClasses::PlayerQuit);
	g_Hooks.RegisterHook(Hooks::Player::ClientSay,ZClass_Menu::ClientSay);
	ZClasses::Init();
	//Headcrab Classes
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect,HClasses::PlayerQuit);
	g_Hooks.RegisterHook(Hooks::Player::ClientSay,HClass_Menu::ClientSay);
	HClasses::Init();
	
	//Player Animation Scheduler
	g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, PlayerAnimator::PlayerThink);
	
	//Save/Load
	SaveLoad::Initialize();

	//Event Client Say
	g_Hooks.RegisterHook(Hooks::Player::ClientSay, Event_ClientSay);

}

HookReturnCode PlayerQuit(CBasePlayer@ pPlayer)
{
	int index = pPlayer.entindex();
	pPlayer.ResetOverriddenPlayerModel(true, true);
	Reminder[index] = false;

	return HOOK_CONTINUE;
}

void PlayerReminder(int index) {
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
	
	if(!Reminder[index] && pPlayer !is null) {
		g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"This is Half-Life:Zombie Edition Ported to Sven Co-Op by Game Hunter.\n");
		g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"Read Console[~] for possible bugs and fixes.\n");
		g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"[BUG 01] Type:'-duck' in your console[~] and press Enter to Fix Ducking problem.\n");
		g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"More Info About the MOD: say '/hlze_info','/hi' or '/info'.\n");
		Reminder[index] = true;
	}
}

HookReturnCode Event_PlayerThink(CBasePlayer@ pPlayer, uint& out dummy )
{
	int index = pPlayer.entindex();
	
	Unstuck::UnstuckPlayer(pPlayer);
	
	return HOOK_CONTINUE;
}

int GetPlayerCount() {
	int count = 0;

	for(uint i=0;i<uint(g_Engine.maxClients);i++) {
		CBasePlayer@ findPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(findPlayer !is null)
			count++;
	}

	return count;
}

HookReturnCode Event_ClientSay( SayParameters@ pParams ) {
		ClientSayType type = pParams.GetSayType();
		if ( type == CLIENTSAY_SAY ) {
			CBasePlayer@ pPlayer = pParams.GetPlayer();
			string text = pParams.GetCommand();
			text.ToLowercase();
			
			if ( text == '/hi' || text == '/info' || text == '/hlze_info')
			{
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"=================================================\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"MOD Info is Printed in Console. (Read Console[~])\n");
				//Gameplay
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"=========================\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"Gameplay:\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"-As a Headcrab,find a victim and infect it.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"Once infected, it will take some time to turn the victim into a zombie.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"-As a zombie, you need to find food(human bodies) and press your 'USE' key to eat.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"When eating,you gain GENE POINTS and regenerate host's body and your headcrab's health.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"Spent gene points in Zombie Class Menu to unlock new classes and abilities.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"If you reach 0 Armor(Host's body health) you will leave that body and play as a headcrab.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"To manually leave body, press 'RELOAD' key.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"=========================\n");
				//Mutation Guide
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"Mutation Guide:\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"say /zc,/zclass or /zombie_class - visit Zombie Class Menu.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"say /za, /upgrades,/ability or /abilities - visit Zombie Ability Menu.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"say /hc or /hclass - visit Headcrab Class Menu.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"say /ha,/hca,/hc_ability or /hc_upgrades - visit Headcrab Ability Menu.\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"Example: bind tab \"say /zc\";\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"=========================\n");
				//Other
					//PvPvM
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"PvPvM: (");
				if(SaveLoad::cvar_pvpvm!=0) g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"its available on this map)\n");
				else g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"not available on this map)\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"say:/choose_team,/team,/t or /ct to choose team!\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"=========================\n");
					//Github
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"Visit Official Github Page:\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"https://github.com/GHmods/scze\n");
				g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"=================================================\n");
				pParams.ShouldHide = true;
				return HOOK_HANDLED;
			}
		}
		
		return HOOK_CONTINUE;
	}