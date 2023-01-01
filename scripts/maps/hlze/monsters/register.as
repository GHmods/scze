//Register Monsters File for Sven Co-op Zombie Edition
#include "monster_infectable"
#include "monster_infected"
#include "monster_infected_dead"
#include "monster_eatable"

#include "monster_relationship" //Set Monster Relationship
//NPCS
#include "npcs/npc_register"

void RegisterMonsters() {
	//Register our NPCS
	HLZE_MonsterInit();

	//Monster Relationship
	g_Scheduler.SetTimeout( "RelationshipProcess", 1.0);
	g_Scheduler.SetTimeout( "BarnacleFix", 5.0);

	Register_Infected();
	Register_Infected_Leaved();
	g_Scheduler.SetTimeout("Infectable_Process", 3.0);
	g_Scheduler.SetTimeout("Eatable_Process", 3.0);
}