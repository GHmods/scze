//Events file for Sven Co-op Zombie Edition
#include "entities/player_animator"
#include "classes/zombie_classes"
#include "classes/headcrab_classes"
#include "weapons/weapon_headcrab"
#include "weapons/weapon_zombie"
#include "classes/gene_points"
//Save/Load System
#include "save-load/base"

array<bool>Reminder(33);

void Events_PluginInit()
{
	//Save/Load
	SaveLoad::Initialize_Plugin();
}

void Events_MapInit()
{
	g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @PlayerJoin);
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
}

HookReturnCode PlayerQuit(CBasePlayer@ pPlayer)
{
	int index = pPlayer.entindex();
	pPlayer.ResetOverriddenPlayerModel(true, true);
	
	return HOOK_CONTINUE;
}

HookReturnCode PlayerJoin(CBasePlayer@ pPlayer)
{
	int index = pPlayer.entindex();
	pPlayer.ResetOverriddenPlayerModel(true, true);
	g_Scheduler.SetTimeout( "PlayerReminder", 2.0, index );
	
	return HOOK_CONTINUE;
}

void PlayerReminder(const int& in index) {
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( index );
	
	if(!Reminder[index] && pPlayer !is null) {
		g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"This is Half-Life:Zombie Edition Ported to Sven Co-Op by Game Hunter.\n");
		g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"Read Console[~] for possible bugs and fixes.\n");
		g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTCONSOLE,"[BUG 01] Type:'-duck' in your console[~] and press Enter to Fix Ducking problem.\n");
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