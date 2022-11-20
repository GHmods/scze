//Register file for Sven Co-op Zombie Edition
//Weapons
#include "weapons/register"
//Monsters
#include "monsters/register"
//Entities
#include "entities/register"

//Events
#include "events"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Game Hunter" );
	g_Module.ScriptInfo.SetContactInfo( "gamehunter.modder@gmail.com" );
	
	//Events
	Events_PluginInit();
}

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