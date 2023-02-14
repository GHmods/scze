//Register file for Sven Co-op Zombie Edition with Fixes for 'zend' Map
//Weapons
#include "weapons/register"
//Monsters
#include "monsters/register"
//Entities
#include "entities/register"

//Events
#include "events"

//Fixes for this map
#include "zend/fixes"

void MapInit()
{
	//Events
	Events_MapInit();
	
	//Register Weapons
	RegisterWeapons();
	//Register Monsters
	//RegisterMonsters(); //This is Last Map, don't need to modify Monsters
	
	//Register Entities
	RegisterEntities();

	//Apply Fixes
	g_Scheduler.SetTimeout("zEnd_FindEnts", 2.0);
}