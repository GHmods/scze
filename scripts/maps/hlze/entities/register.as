//Register Weapons File for Sven Co-op Zombie Edition
#include "multisource"
#include "fake_pickup"
#include "info_player_start"
#include "player_revive_think"

void RegisterEntities() {
	//Initialize our 'multisource' manager
	multisource_Init();
	
	//Initialize 'fake_pickup' entity
	fake_pickup_Init();

	//Player Revive Think
	g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, PlayerReviver::PlayerJoin);
	g_Hooks.RegisterHook(Hooks::Player::PlayerPreThink, PlayerReviver::PlayerPreThink);
}