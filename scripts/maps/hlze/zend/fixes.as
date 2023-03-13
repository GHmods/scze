//Fixes for 'zend' Map for Sven Co-op Zombie Edition
Vector Destination1(-401.0,494.0,-645.0);
Vector Destination2(205.0,1347.0,934.0);
Vector Destination3(-889.0,1412.0,-165.0);
array<EHandle>zEnd_SearchedEntities;

#include "../save-load/base"

void zEnd_FindEnts() {
	//Search for all entities
	array<CBaseEntity@>searchedEntities(500);
	Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
	Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
	g_EntityFuncs.EntitiesInBox(searchedEntities, mins, maxs, 0);
	
	for(uint i=0;i<searchedEntities.length();i++) {
		CBaseEntity@ ent = searchedEntities[i];
		//Check if the entity is not NULL
		if(ent !is null) {
			zEnd_SearchedEntities.insertLast(EHandle(ent));
		}
	}

	g_Scheduler.SetTimeout("ApplyFix", 2.0);
}

void ApplyFix() {
	//Search the Array
	bool wait4trigger = false;
	CBaseMonster@ gman;
	for(uint i=0;i<zEnd_SearchedEntities.length();i++) {
		CBaseEntity@ ent = zEnd_SearchedEntities[i];
		if(ent !is null) {
			if(ent.pev.classname=="monster_gman" && ent.pev.targetname=="gman1") {
				@gman = ent.MyMonsterPointer();
			}
		}
	}

	if(gman !is null) {
		if(gman.m_MonsterState == MONSTERSTATE_SCRIPT) {
			wait4trigger = true;
		}
		
	}
	
	if(!wait4trigger) {
		g_Scheduler.SetTimeout("ApplyFix", 1.0);
	} else {
		float wait_time = 3.0;
		g_Scheduler.SetTimeout("ApplyFix1", 14.0+wait_time);
		g_Scheduler.SetTimeout("ApplyFix2", 33.0+wait_time);
		g_Scheduler.SetTimeout("ApplyFix3", 65.0+wait_time);
	}

	//Debug
	
	if(wait4trigger) AS_Log("Is Triggered = "+"YES"+".\n",LOG_LEVEL_EXTREME);
	else AS_Log("Is Triggered = "+"NO"+".\n",LOG_LEVEL_EXTREME);
}

void ApplyFix1() {RelocatePlayers(Destination1);}
void ApplyFix2() {RelocatePlayers(Destination2);}
void ApplyFix3() {RelocatePlayers(Destination3);}

void RelocatePlayers(Vector Destination,bool relocate_players = false) {
	if(relocate_players)
	{
		for(uint i=0;i<33;i++) {
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null) {
				pPlayer.pev.origin = Destination;
			}
		}
	}
	
	for(uint i=0;i<zEnd_SearchedEntities.length();i++) {
		CBaseEntity@ ent = zEnd_SearchedEntities[i];
		if(ent !is null) {
			if(ent.pev.classname=="info_player_start") {
				ent.pev.origin = Destination;
			}
		}
	}
}