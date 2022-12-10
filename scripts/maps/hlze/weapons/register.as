//Register Weapons File for Sven Co-op Zombie Edition
#include "weapon_headcrab"
#include "weapon_zombie"
#include "weapon_zombie_headcrab"
#include "baby_crabs"
#include "weapon_zombie_babycrab"

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
	BabyCrabs::Precache();
	g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, BabyCrabs::PlayerJoin);
	g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, BabyCrabs::PlayerThink);
}