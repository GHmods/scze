#include "monster_hlze_zombie"
#include "monster_hlze_barney"
#include "monster_hlze_scientist"
#include "monster_fast_zombie"

void HLZE_MonsterInit() {
	//g_Log.PrintF("Registering Custom NPCS.....\n");
	HLZE_Zombie::Register();
	HLZE_Barney::Register();
	HLZE_Scientist::Register();
	HLZE_Fast_Zombie::Register();
}