//Register Weapons File for Sven Co-op Zombie Edition
#include "multisource"
#include "fake_pickup"
#include "info_player_start"

void RegisterEntities() {
	//Initialize our 'multisource' manager
	multisource_Init();
	
	//Initialize 'fake_pickup' entity
	fake_pickup_Init();
}