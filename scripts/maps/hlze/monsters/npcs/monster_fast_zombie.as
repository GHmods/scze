/***
*
*	Copyright (c) 1996-2001, Valve LLC. All rights reserved.
*	
*	This product contains software technology licensed from Id 
*	Software, Inc. ("Id Technology").  Id Technology (c) 1996 Id Software, Inc. 
*	All Rights Reserved.
*
*   This source code contains proprietary and confidential information of
*   Valve LLC and its suppliers.  Access to this code is restricted to
*   persons who have executed a written SDK license with Valve.  Any access,
*   use or distribution of this code by or to any unlicensed person is illegal.
*
****/
//=========================================================
// Fast Zombie
//=========================================================

/* 
* Fast Zombie Monster entity
* Call HLZE_Zombie::Register() to register this entity.
* Entity classname: monster_hlze_zombie
*/
#include "checktracehullattack"
#include "precache_sounds"

namespace HLZE_Fast_Zombie
{
//Gore
array<int>m_iBlood(2);

const array<string>pAttackSounds = {
	"zombie/zo_attack1.wav",
	"zombie/zo_attack2.wav",
};

const array<string>pIdleSounds = 
{
	"zombie/zo_idle1.wav",
	"zombie/zo_idle2.wav",
	"zombie/zo_idle3.wav",
	"zombie/zo_idle4.wav"
};

const array<string>pAlertSounds = {
	"zombie/zo_alert10.wav",
	"zombie/zo_alert20.wav",
	"zombie/zo_alert30.wav"
};

const array<string>pPainSounds = {
	"zombie/zo_pain1.wav",
	"zombie/zo_pain2.wav"
};

const array<string>pAttackHitSounds = {
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav"
};

const array<string>pAttackMissSounds = {
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav"
};

const int ZOMBIE_AE_ATTACK_RIGHT	= 1;
const int ZOMBIE_AE_ATTACK_LEFT		= 2;

const float ZOMBIE_FLINCH_DELAY		= 7.0;
const float ZOMBIE_IDLE_SOUND_DELAY	= 3.5;

const string zombieModel			= "models/hlze/fastzombie.mdl";
const float zombieHealth			= 70.0;
const float zombieSlashDist			= 90.0;
const float zombieDmgOneSlash		= 25.0;
const float zombieDmgBothSlash		= 50.0;

class CHLZE_Fast_Zombie : ScriptBaseMonsterEntity
{
	//Next Flinch Timer
	private float m_flNextFlinch;
	//Next Idle Sound Timer
	private float m_flNextIdleSound;
	
	//=========================================================
	// Classify - indicates this monster's place in the 
	// relationship table.
	//=========================================================
	int Classify()
	{
		return self.GetClassification(CLASS_ALIEN_MONSTER);
	}

	//=========================================================
	// SetYawSpeed - allows each sequence to have a different
	// turn rate associated with it.
	//=========================================================
	void SetYawSpeed()
	{
		int ys = 360;
		self.pev.yaw_speed = ys;
	}

	//Take Damage
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{	
		if( pevAttacker is null )
			return 0;

		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
		
		if( self.CheckAttacker( pAttacker ) )
			return 0;

		// Take 30% damage from bullets
		if(bitsDamageType == DMG_BULLET) {
			Vector vecDir = self.pev.origin - (pevInflictor.absmin + pevInflictor.absmax) * 0.5;
			vecDir = vecDir.Normalize();
			float flForce = self.DamageForce(flDamage);
			self.pev.velocity = self.pev.velocity + vecDir * flForce;
			flDamage *= 0.3;
		}

		// HACK HACK -- until we fix this.
		if(self.IsAlive())
			PainSound();
		
		return BaseClass.TakeDamage(pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}
	//=========================================================
	// TraceAttack
	//=========================================================
	void TraceAttack(entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in traceResult, int bitsDamageType)
	{
		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Hit group:"+traceResult.iHitgroup+".\n");
		float ArmorValue = self.pev.armorvalue;
		if(ArmorValue>0) {
			if(flDamage<=ArmorValue) {
				self.pev.armorvalue -= flDamage/2;
				if(traceResult.iHitgroup==2||traceResult.iHitgroup==3) {
					flDamage=0.01;
					g_Utility.Ricochet(traceResult.vecEndPos,1.0);
					flDamage/=Math.RandomFloat(ArmorValue,ArmorValue/(Math.RandomFloat(0.25,0.75)));
				}
			} else {
				self.pev.armorvalue = 0.0;
			}
		}

		BaseClass.TraceAttack(pevAttacker,flDamage,vecDir,traceResult,bitsDamageType);
	}
	//=========================================================
	// Zombie Sounds
	//=========================================================
	// Pain Sound
	void PainSound() {
		int pitch = 95 + Math.RandomLong(0,9);

		if(Math.RandomLong(0,5) < 2) {
			g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pPainSounds[Math.RandomLong(0,pPainSounds.length()-1)],1,ATTN_NORM,0,pitch);
		}
	}
	// Alert Sound
	void AlertSound() {
		int pitch = 95 + Math.RandomLong(0,9);
		g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pAlertSounds[Math.RandomLong(0,pAlertSounds.length()-1)],1,ATTN_NORM,0,pitch);
	}
	// Idle Sound
	void IdleSound() {
		if(m_flNextIdleSound>g_Engine.time)
			return;
		
		int pitch = 95 + Math.RandomLong(0,9);
		g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pIdleSounds[Math.RandomLong(0,pIdleSounds.length()-1)],1,ATTN_NORM,0,pitch);

		m_flNextIdleSound = g_Engine.time + ZOMBIE_IDLE_SOUND_DELAY;
	}
	// Attack Sound
	void AttackSound() {
		int pitch = 95 + Math.RandomLong(0,9);
		g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pAttackSounds[Math.RandomLong(0,pAttackSounds.length()-1)],1,ATTN_NORM,0,pitch);
	}

	//=========================================================
	// HandleAnimEvent - catches the monster-specific messages
	// that occur when tagged animation frames are played.
	//=========================================================
	void HandleAnimEvent(MonsterEvent@ pEvent) {
		switch(pEvent.event)
		{
			case ZOMBIE_AE_ATTACK_LEFT:
			{
				// do stuff for this event.
				CBaseEntity@ pHurt = CheckTraceHullAttack(self,zombieSlashDist,zombieDmgOneSlash,DMG_SLASH);
				if(pHurt !is null) {
					if(pHurt.IsPlayer()) {
						pHurt.pev.punchangle.z = 18;
						pHurt.pev.punchangle.x = 5;
						pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_right * 100;
					}
					g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,pAttackHitSounds[Math.RandomLong(0,pAttackHitSounds.length()-1)],1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
				} else {
					g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,pAttackMissSounds[Math.RandomLong(0,pAttackMissSounds.length()-1)],1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
				}

				if(Math.RandomLong(0,1) == 1)
					AttackSound();
				break;
			}
			case ZOMBIE_AE_ATTACK_RIGHT:
			{
				// do stuff for this event.
				CBaseEntity@ pHurt = CheckTraceHullAttack(self,zombieSlashDist,zombieDmgOneSlash,DMG_SLASH);
				if(pHurt !is null) {
					if(pHurt.IsPlayer()) {
						pHurt.pev.punchangle.z = -18;
						pHurt.pev.punchangle.x = 5;
						pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * 100;
					}
					g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,pAttackHitSounds[Math.RandomLong(0,pAttackHitSounds.length()-1)],1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
				} else {
					g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,pAttackMissSounds[Math.RandomLong(0,pAttackMissSounds.length()-1)],1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
				}

				if(Math.RandomLong(0,1) == 1)
					AttackSound();
				break;
			}
			default: {
				BaseClass.HandleAnimEvent(pEvent);
				break;
			}
		}
	}
	//=========================================================
	// Spawn
	//=========================================================
	void Spawn() {
		Precache();

		g_EntityFuncs.SetModel(self,zombieModel);
		Setup_Monster();

		self.SetPlayerAlly(self.IsPlayerAlly()); //Set as ally/foe upon spawning

		if(string(self.m_FormattedName).IsEmpty()) {
			self.m_FormattedName = "Fast Zombie";
		}

		//Setup_Zombie(Math.RandomLong(INFECTED_SCIENTIST,INFECTED_MASSN));
	}

	void Setup_Monster() {
		g_EntityFuncs.SetSize(self.pev,VEC_HUMAN_HULL_MIN,VEC_HUMAN_HULL_MAX);
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_GREEN;
		self.pev.health = zombieHealth;
		self.pev.view_ofs = VEC_VIEW; //position of the eyes relative to monster's origin.
		self.m_flFieldOfView = 0.9;// indicates the width of this monster's forward view cone ( as a dotproduct result )
		self.m_MonsterState = MONSTERSTATE_NONE;
		self.m_afCapability = bits_CAP_DOORS_GROUP;

		self.MonsterInit();

		self.ChangeYaw(30);

		// Do Not Remove This Monster on Death
		//SF_MONSTER_FADECORPSE = 512;
		self.pev.spawnflags |= 512;
	}
	
	//=========================================================
	// Precache - precaches all resources this monster needs
	//=========================================================
	void Precache() {
		BaseClass.Precache();
		PrecacheInit();
	}
	// No Range Attacks
	bool CheckRangeAttack1(float flDot,float flDist) {return false;}
	bool CheckRangeAttack2(float flDot,float flDist) {return false;}
	
	//=========================================================
	// Schedules Specific to this monster
	//=========================================================
	CHLZE_Fast_Zombie()
	{
		//@this.m_Schedules = @monster_hlze_zombie_schedules;
	}

	Schedule@ GetScheduleOfType( int Type )
	{
		Schedule@ psched;
		
		return BaseClass.GetScheduleOfType(Type);
	}
	Schedule@ GetSchedule()
	{
		SetActivity(self.m_Activity);

		switch(self.m_MonsterState) {
			case MONSTERSTATE_IDLE:
			{
				if(Math.RandomLong(0,10)<4) {
					IdleSound();
				}
			}
		}

		//Pain
		if(m_flNextFlinch < g_Engine.time) {
			if(self.HasConditions(bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE)) {
				return self.GetScheduleOfType(SCHED_SMALL_FLINCH); // flinch if hurt
			}
		}

		return BaseClass.GetSchedule();
	}
	//=========================================================
	// SetActivity 
	//=========================================================
	void SetActivity(Activity NewActivity) {
		int iSequence = -1;
		switch(NewActivity) {
			case ACT_MELEE_ATTACK1: {
				if(m_flNextFlinch > g_Engine.time) {
					m_flNextFlinch += g_Engine.time + ZOMBIE_FLINCH_DELAY;
				}
				break;
			}
			case ACT_SMALL_FLINCH:
			case ACT_BIG_FLINCH: {
				if(m_flNextFlinch < g_Engine.time)
					m_flNextFlinch += g_Engine.time + ZOMBIE_FLINCH_DELAY;
				break;
			}
			//Die
			case ACT_DIE_GUTSHOT:
			case ACT_DIEBACKWARD:
			case ACT_DIESIMPLE:
			case ACT_DIEFORWARD:
			case ACT_DIE_HEADSHOT:
			
			default: {
				iSequence = self.LookupActivity(NewActivity);
				break;
			}
		}
	}
	//=========================================================
	// Start Task Function Specific to this monster
	//=========================================================
	void StartTask(Task@ pTask)
	{
		self.m_iTaskStatus = 1;

		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Starting Task - "+pTask.iTask+".\n");
		
		BaseClass.StartTask(pTask);
	}
	//=========================================================
	// Revive Function Specific to this monster
	//=========================================================
	bool IsRevivable() {
		return true;
	}
}

void Register() {
	PrecacheInit();
	g_CustomEntityFuncs.RegisterCustomEntity("HLZE_Fast_Zombie::CHLZE_Fast_Zombie", "monster_fast_zombie");
	AS_Log("Registered:"+"monster_fast_zombie"+"\n",LOG_LEVEL_EXTREME);
}

void PrecacheInit() {
	g_Game.PrecacheModel(zombieModel);
	PrecacheSounds(pAttackHitSounds);
	PrecacheSounds(pAttackMissSounds);
	PrecacheSounds(pAttackSounds);
	PrecacheSounds(pIdleSounds);
	PrecacheSounds(pAlertSounds);
	PrecacheSounds(pPainSounds);

	//Gore
	m_iBlood[0] = g_Game.PrecacheModel("sprites/blood.spr");
	m_iBlood[1] = g_Game.PrecacheModel("sprites/bloodspray.spr");
	g_Game.PrecacheGeneric("sprites/blood.spr");
	g_Game.PrecacheGeneric("sprites/bloodspray.spr");
}

} // end of namespace