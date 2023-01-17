//Teleport Fix Sven Co-op Zombie Edition
#include "../events"
bool isTeleporterActive = false;
Vector Teleporter_Destination(-79.0,-167.0,-260.0);

void zhzm0_fix() {
	int pCount = GetPlayerCount();

	if(pCount>0) g_Scheduler.SetTimeout( "TeleportPlayers_Now", 5.0);
	else g_Scheduler.SetTimeout( "zhzm0_fix", 1.0);
}

void TeleportPlayers_Now() {
	for(uint i=0;i<33;i++) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(pPlayer !is null) {
			pPlayer.pev.origin = Teleporter_Destination;
		}
	}
	
	isTeleporterActive = true;
	Relocate_SpawnPoint();
}

void Relocate_SpawnPoint() {
	CBaseEntity@ spawnPoint;
	@spawnPoint = g_EntityFuncs.FindEntityByClassname(spawnPoint, "info_player_start");
	if(spawnPoint !is null && isTeleporterActive)
		spawnPoint.pev.origin = Teleporter_Destination;
}