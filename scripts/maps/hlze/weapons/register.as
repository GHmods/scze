//Register Weapons File for Sven Co-op Zombie Edition
#include "weapon_headcrab"
#include "weapon_zombie"
#include "weapon_zombie_headcrab"
#include "zAbilityHud"
#include "weapon_zombie_babycrab"
#include "weapon_zombie_barnacle"

void RegisterWeapons() {
	Register_Headcrab(); //Headcrab
	Headcrab_Precache(); //Stuff Needed for Headcrab
	
	Register_Zombie(); //Zombie
	Zombie_Precache(); //Stuff Needed for Zombie

	Register_ZombieHeadcrab(); //Headcrab as a weapon for Zombies
	ZombieHC_Precache(); //Stuff Needed for Headcrab Weapon

	//Baby Crabs
	Register_ZombieBabycrab(); //Babycrabs as a weapon for Zombies
	ZombieBC_Precache(); //Stuff Needed for Babycrabs Weapon
	//Barnacle Weapon
	Register_ZombieBarnacleWeapon(); //Barnacle as a weapon for Zombies
	ZombieBarnacleWeapon_Precache(); //Stuff Needed for Barnacle Weapon

	zAbilityHud::Precache();
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, zAbilityHud::PlayerQuit);
	g_Scheduler.SetTimeout("zHudThink", 1.0);
}