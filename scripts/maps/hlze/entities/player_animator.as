//Player Animation Scheduler for Sven Co-op Zombie Edition
namespace PlayerAnimator{
	array<bool>ScheduleNow(33);
	array<PLAYER_ANIM>Animation(33);
	array<float>AnimationTimer(33);
	
	void Schedule_Animation(CBasePlayer@ pPlayer, PLAYER_ANIM animationId, float delay)
	{
		int pId = pPlayer.entindex();
		ScheduleNow[pId] = true;
		Animation[pId] = animationId;
		AnimationTimer[pId] = g_Engine.time + delay;
	}
	
	void Force_Animation(CBasePlayer@ pPlayer, int animId, float frameRate = 1.0)
	{
		pPlayer.m_Activity = ACT_RELOAD;
		pPlayer.pev.sequence = animId;
		pPlayer.pev.frame = 0.0000001f;
		pPlayer.ResetSequenceInfo();
		pPlayer.pev.framerate = frameRate;
	}

	HookReturnCode PlayerThink(CBasePlayer@ pPlayer)
	{
		int pId = pPlayer.entindex();
		
		if(ScheduleNow[pId] && AnimationTimer[pId]<g_Engine.time) {
			pPlayer.SetAnimation(Animation[pId]);
			ScheduleNow[pId] = false;
		}
		
		return HOOK_CONTINUE;
	}
};