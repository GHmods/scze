//Register file for Sven Co-op Zombie Edition with Fixes for 'zhzm0' Map
#include "zhzm0/teleport_fix" //Teleporter Fix

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
	
	//Register Entities
	RegisterEntities();
}

void MapActivate()
{
	//Fixes for this Map
	g_Scheduler.SetTimeout( "zhzm0_fix", 1.0);
}