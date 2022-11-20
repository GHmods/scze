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
	
	//Teleporter Fix for this Map
	g_Scheduler.SetTimeout( "TeleportPlayers_Now", 5.0);
	
	//Register Entities
	RegisterEntities();
}