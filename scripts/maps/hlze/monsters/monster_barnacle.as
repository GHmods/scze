/*
	Barnacle Process
*/
#include "../unstuck"

array<EHandle>BarnacleEntities;
array<EHandle>BarnacleEntities_Dead;
//BarnacleEntities.insertLast(EHandle(ent));

void Barnacle_Process() {
	//Find all monsters
	array<CBaseEntity@>Ents(1000);
	Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
	Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
	g_EntityFuncs.EntitiesInBox(Ents, mins, maxs, 0);
	
	for(uint i=0;i<Ents.length();i++) {
		CBaseEntity@ ent = Ents[i];
		CBaseMonster@ monster;
		//Check if the entity is not NULL
		if(ent !is null) {
			if(ent.pev.classname == "monster_barnacle") {
				UpdateBarnacleArray(ent);
			}
		}
	}
	
	//Performance Fix
	g_Scheduler.SetTimeout("Barnacle_Die_Process", 1.5);
	g_Scheduler.SetTimeout("Barnacle_Process", 3.0);
}

void UpdateBarnacleArray(CBaseEntity@ ent) {
	if(ent is null)
		return;
	
	bool isAvailable = false;
	bool isDead = false;
	//Add to Processing Array
	for(uint i=0;i<BarnacleEntities.length();i++)
	{
		//Make sure is not available in this array
		CBaseEntity@ checkEnt = BarnacleEntities[i];
		if(checkEnt is ent)
		{
			isAvailable = true;
			break;
		}
	}

	//Make sure this Barnacle is not dead
	for(uint d=0;d<BarnacleEntities_Dead.length();d++) {
		CBaseEntity@ checkDeadEnt = BarnacleEntities_Dead[d];
		if(checkDeadEnt is ent) {
			isDead = true;
			break;
		}
	}

	//If not dead
	if(!isDead && !isAvailable) {
		BarnacleEntities.insertLast(EHandle(ent)); //Add it to the array
		AS_Log("Barnacle Detected!\n",LOG_LEVEL_EXTREME);
	}
}

void Barnacle_Die_Process() {
	//Remove invalid Entities
	for(uint d=0;d<BarnacleEntities_Dead.length();d++) {
		CBaseEntity@ checkEnt = BarnacleEntities_Dead[d];
		if(checkEnt is null) {
			BarnacleEntities_Dead.removeAt(d);
			break;
		}
	}
	//Check if these entities are dead
	for(uint d=0;d<BarnacleEntities.length();d++) {
		CBaseEntity@ checkEnt = BarnacleEntities[d];
		if(checkEnt !is null && !checkEnt.IsAlive()) {
			//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "A Barnacle just Died!\n");

			CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("barnacle_baby");
			CBaseMonster@ dropEnt = entBase.MyMonsterPointer();
			if(dropEnt !is null) {
				g_EntityFuncs.DispatchSpawn(dropEnt.edict());
				dropEnt.SetPlayerAllyDirect(true);
				dropEnt.pev.origin = checkEnt.pev.origin - g_Engine.v_up * 25;
				dropEnt.pev.angles.y = checkEnt.pev.v_angle.y;
			}

			AS_Log("A Barnacle just Died!\n",LOG_LEVEL_EXTREME);
			BarnacleEntities_Dead.insertLast(EHandle(checkEnt));
			BarnacleEntities.removeAt(d);
			break;
		}
	}
}