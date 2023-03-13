//Player Spawn Relocator for Sven Co-op Zombie Edition
void SpawnPoint_SetPosition(Vector Teleporter_Destination) {
	CBaseEntity@ spawnPoint;
	@spawnPoint = g_EntityFuncs.FindEntityByClassname(spawnPoint, "info_player_start");
	if(spawnPoint !is null) {
		spawnPoint.pev.origin = Teleporter_Destination;
		AS_Log("------ Relocating Spawnpoint to ("+Teleporter_Destination.ToString()+")\n",LOG_LEVEL_HIGH);
	}
}