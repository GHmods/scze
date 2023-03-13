//Set Monster Relationship Sven Co-op Zombie Edition
//Code for our Custom Entities
#include "npcs/npc_register"

array<string>Enemies = {
	"monster_apache",
	"monster_assassin_repel",
	//"monster_barney",
	//"monster_barney_dead",
	"monster_blkop_osprey",
	"monster_blkop_apache",
	"monster_bodyguard",
	//"monster_cleansuit_scientist",
	"monster_grunt_ally_repel",
	"monster_grunt_repel",
	"monster_hevsuit_dead",
	//"monster_hgrunt_dead",
	"monster_human_assassin",
	//"monster_human_grunt",
	"monster_male_assassin",
	//"monster_miniturret",
	"monster_osprey",
	//"monster_otis",
	//"monster_otis_dead",
	"monster_robogrunt",
	"monster_robogrunt_repel",
	//"monster_scientist",
	//"monster_scientist_dead",
	"monster_sentry",
	//"monster_sitting_scientist",
	"monster_tripmine",
	//"monster_turret",
	"monster_bullchicken"
};

array<string>Allies = {
	"monster_alien_babyvoltigore",
	"monster_alien_controller",
	"monster_alien_grunt",
	"monster_alien_slave",
	"monster_alien_tor",
	"monster_alien_voltigore",
	"monster_babycrab",
	"monster_babygarg",
	"monster_barnacle",
	"monster_bigmomma",
	"monster_chumtoad",
	"monster_flyer_flock",
	"monster_gargantua",
	"monster_gman",
	"monster_gonome",
	"monster_headcrab",
	"monster_houndeye",
	"monster_ichthyosaur",
	"monster_kingpin",
	"monster_leech",
	"monster_nihilanth",
	"monster_pitdrone",
	"monster_shockroach",
	"monster_shocktrooper",
	"monster_snark",
	"monster_sqknest",
	"monster_stukabat",
	"monster_tentacle",
	"monster_zombie",
	"monster_zombie_barney",
	"monster_zombie_soldier",
	"monster_hlze_zombie" //Our Custom NPC
};

array<string>Team1 = {
	"monster_miniturret",
	"monster_turret",
	"monster_scientist",
	"monster_scientist_dead",
	"monster_barney",
	"monster_barney_dead",
	"monster_otis",
	"monster_otis_dead",
	"monster_cleansuit_scientist",
	"monster_sitting_scientist",
	"monster_hlze_barney", //Our Custom NPC
};

array<string>Team2 = {
	"monster_human_grunt",
	"monster_hgrunt_dead"
};

void RelationshipProcess()
{
	//Find all monsters
	array<CBaseEntity@>Monsters(1000);
	g_EntityFuncs.MonstersInSphere(Monsters, Vector(0,0,0), 999999.0);
	
	for(uint i=0;i<Monsters.length();i++) {
		CBaseEntity@ ent = Monsters[i];
		//Check if the entity is not NULL
		if(ent !is null)
		{
			//Check if is Monster and not Player
			if(ent.IsMonster() && !ent.IsPlayer())
			{
				AS_Log("["+i+"] Found: "+ent.pev.classname,LOG_LEVEL_EXTREME);
				//Get Monster Base from this Entity
				CBaseMonster@ ent_monster = ent.MyMonsterPointer();
				if(ent_monster !is null)
				{
					for(uint i1=0;i1<Enemies.length();i1++) {
						if(ent_monster.pev.classname == Enemies[i1]) {
							if(ent_monster.IsPlayerAlly())
								ent_monster.SetPlayerAllyDirect(ent_monster.IsPlayerAlly());
						}
					}
					for(uint i1=0;i1<Allies.length();i1++) {
						if(ent_monster.pev.classname == Allies[i1]) {
							ent_monster.SetClassification(CLASS_PLAYER_ALLY);
							ent_monster.SetPlayerAllyDirect(true);
						}
					}

					//Replace Some Monsters (Used for HLZE Custom NPCS)
					if(ent_monster.pev.classname == "monster_zombie")
					{
						dictionary keys;
						keys["origin"] = ""+ent_monster.pev.origin.ToString();
						keys["angles"] = ""+ent_monster.pev.angles.ToString();
						keys["spawnflags"] = ""+ent_monster.pev.flags;
						keys["body"] = ""+ent_monster.pev.body;
						keys["skin"] = ""+ent_monster.pev.skin;
						keys["health"] = ""+ent_monster.pev.health;
						keys["targetname"] = ""+ent_monster.pev.targetname;
						CBaseEntity@ replacedEnt = g_EntityFuncs.CreateEntity("monster_hlze_zombie", keys);
						HLZE_Zombie::CHLZE_Zombie@ replacedMonster = cast<HLZE_Zombie::CHLZE_Zombie@>(CastToScriptClass(replacedEnt));
						g_EntityFuncs.Remove(ent_monster);
						replacedMonster.Setup_Zombie(-1,true);
						AS_Log("Replaced....["+ent_monster.pev.classname+"]with["+replacedMonster.pev.classname+"].\n",LOG_LEVEL_EXTREME);
					} else if(ent_monster.pev.classname == "monster_barney")
					{
						dictionary keys;
						keys["origin"] = ""+ent_monster.pev.origin.ToString();
						keys["angles"] = ""+ent_monster.pev.angles.ToString();
						keys["spawnflags"] = ""+ent_monster.pev.flags;
						keys["body"] = ""+ent_monster.pev.body;
						keys["skin"] = ""+ent_monster.pev.skin;
						keys["health"] = ""+ent_monster.pev.health;
						keys["targetname"] = ""+ent_monster.pev.targetname;
						keys["weapons"] = ""+ent_monster.pev.weapons;
						CBaseEntity@ replacedEnt = g_EntityFuncs.CreateEntity("monster_hlze_barney", keys);
						HLZE_Barney::CHLZE_Barney@ replacedMonster = cast<HLZE_Barney::CHLZE_Barney@>(CastToScriptClass(replacedEnt));
						g_EntityFuncs.Remove(ent_monster);
						AS_Log("Replaced....["+ent_monster.pev.classname+"]with["+replacedMonster.pev.classname+"].\n",LOG_LEVEL_EXTREME);
					}
				}
				
				Set_Team(ent);
				
				//if(ent_monster.IsPlayerAlly()) g_Log.PrintF(" is now : Ally!\n");
				//else g_Log.PrintF(" is now : Enemy!\n");
			}
		}
	}
	
	g_Scheduler.SetTimeout( "RelationshipProcess", 1.0);
}

void Set_Team(CBaseEntity@ ent)
{
	//Check if the entity is not NULL
	if(ent !is null) {
		//Check if is Monster and not Player
		if(ent.IsMonster() && !ent.IsPlayer())
		{
			//Get Monster Base from this Entity
			CBaseMonster@ ent_monster = ent.MyMonsterPointer();
			for(uint i1=0;i1<Team1.length();i1++) {
				if(ent_monster.pev.classname == Team1[i1]) {
					ent_monster.SetClassification(CLASS_TEAM1);
					ent_monster.SetupFriendly();
				}
			}
			for(uint i1=0;i1<Team2.length();i1++) {
				if(ent_monster.pev.classname == Team2[i1]) {
					ent_monster.SetClassification(CLASS_TEAM2);
				}
			}
		}
	}
}

void BarnacleFix()
{
	//Find all entities
	array<CBaseEntity@>Ents(1000);
	Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
	Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
	g_EntityFuncs.EntitiesInBox(Ents, mins, maxs, 0);
	
	for(uint i=0;i<Ents.length();i++)
	{
		CBaseEntity@ ent = Ents[i];
		//Check if the entity is not NULL
		if(ent !is null)
		{
			//Get Monster Base from this Entity
			CBaseMonster@ ent_monster = ent.MyMonsterPointer();
			if(ent_monster !is null)
			{
				if(ent_monster.pev.classname=="monster_barnacle")
				{
					//If this is barnacle, try to recreate it as ally
					dictionary keys;
					keys["origin"] = ""+ent_monster.pev.origin.ToString();
					keys["angles"] = ""+ent_monster.pev.angles.ToString();
					keys["spawnflags"] = ""+ent_monster.pev.flags;
					keys["body"] = ""+ent_monster.pev.body;
					keys["skin"] = ""+ent_monster.pev.skin;
					keys["health"] = ""+ent_monster.pev.health;
					keys["is_player_ally"] = "1";
					g_EntityFuncs.CreateEntity("monster_barnacle", keys);
					g_EntityFuncs.Remove(ent_monster);
				}
			}
		}
	}
}