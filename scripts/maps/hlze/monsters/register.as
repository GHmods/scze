//Register Monsters File for Sven Co-op Zombie Edition
#include "monster_infectable"
#include "monster_infected"
#include "monster_infected_dead"
#include "monster_eatable"

void RegisterMonsters() {
	Register_Infected();
	Register_Infected_Leaved();
	g_Scheduler.SetTimeout("Infectable_Process", 3.0);
	g_Scheduler.SetTimeout("Eatable_Process", 3.0);
}