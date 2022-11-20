//Register file for Sven Co-op Zombie Edition with Fixes for 'zhzm0' Map
//Weapons
#include "weapons/register"
//Monsters
#include "monsters/register"
//Entities
#include "entities/register"

//Events
#include "events"

void MapInit()
{
	//Events
	Events_MapInit();
	
	//Register Weapons
	RegisterWeapons();
	//Register Monsters
	RegisterMonsters();
	
	//Spawn Fix for this Map
	g_Scheduler.SetTimeout("Sched_RelocateSpawnPoint", 5.0);
	
	//Register Entities
	RegisterEntities();
}

void Sched_RelocateSpawnPoint() {
	SpawnPoint_SetPosition(Vector(-512.0,128.0,-253.0));
}