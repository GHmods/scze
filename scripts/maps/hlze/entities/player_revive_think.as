//Player Revive Fix for Sven Co-op Zombie Edition
#include "../save-load/base"

namespace PlayerReviver{
	array<int>lastDeadflag(33);

	
	HookReturnCode PlayerJoin(CBasePlayer@ pPlayer)
	{
		int pId = pPlayer.entindex();
		
		lastDeadflag[pId] = 123;

		return HOOK_CONTINUE;
	}

	HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer)
	{
		int pId = pPlayer.entindex();
		
		int deadflag = pPlayer.pev.deadflag;
		if(deadflag == 0 && lastDeadflag[pId] > 0) {
			SaveLoad::SpawnAsDelay(pId);
		}
		
		lastDeadflag[pId] = deadflag;
		
		return HOOK_CONTINUE;
	}
};