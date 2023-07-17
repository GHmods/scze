/* 
* Custom Scientist monster entity
* Call HLZE_Scientist::Register() to register this entity.
* Entity classname: monster_hlze_scientist
*/
#include "checktracehullattack"

namespace HLZE_Scientist
{
const string NPC_UNARMED_MODEL = "models/hlze/scientist.mdl";
const string NPC_GLOCK_MODEL = "models/hlze/scientist_beretta.mdl";
const string NPC_M16_MODEL = "models/hlze/scientist_m16.mdl";
const string NPC_SPAS12_MODEL = "models/hlze/scientist_shotgun.mdl";

const int SCIENTIST_AE_SHOOT			= 4;
const int SCIENTIST_AE_ATTACK			= 5;

int m_iBrassShell;
int m_iBrassShell_762;
int m_iBrassShell_shotgun;

enum Scientist_Weapons {
	SCIENTIST_WEAPON_UNARMED = 0,
	SCIENTIST_WEAPON_GLOCK = 1,
	SCIENTIST_WEAPON_M16 = 2,
	SCIENTIST_WEAPON_SPAS12 = 3,
	SCIENTIST_WEAPON_RANDOM = 4
};

class CHLZE_Scientist : ScriptBaseMonsterEntity
{
	private bool	m_fGunDrawn;
	private float	m_painTime;
	private int	m_head;
	private int	m_cClipSize;
	private int	m_cBackpackAmmmo;
	private float	m_flNextFearScream;
	
	CHLZE_Scientist()
	{
		@this.m_Schedules = @monster_scientist_schedules;
	}
	
	int ObjectCaps()
	{
		if( self.IsPlayerAlly() )
			return FCAP_IMPULSE_USE;
		else
			return BaseClass.ObjectCaps();
	}
	
	void RunTask( Task@ pTask )
	{
		switch ( pTask.iTask )
		{
		case TASK_RANGE_ATTACK1:
			//if(self.m_hEnemy().IsValid() && (self.m_hEnemy().GetEntity().IsPlayer()))
				self.pev.framerate = 1.5f;

				//m_flThinkDelay = 0.0f;


			//Friendly fire stuff.
			if( !self.NoFriendlyFire() )
			{
				self.ChangeSchedule( self.GetScheduleOfType ( SCHED_FIND_ATTACK_POINT ) );
				return;
			}

			BaseClass.RunTask( pTask );
			break;
		case TASK_RELOAD:
			{
				self.MakeIdealYaw ( self.m_vecEnemyLKP );
				self.ChangeYaw ( int(self.pev.yaw_speed) );

				if(m_cBackpackAmmmo > 0) {
					if( self.m_fSequenceFinished)
					{
						if(m_cBackpackAmmmo>=m_cClipSize) self.m_cAmmoLoaded = m_cClipSize;
						else self.m_cAmmoLoaded = m_cBackpackAmmmo;

						m_cBackpackAmmmo -= self.m_cAmmoLoaded;
						self.ClearConditions(bits_COND_NO_AMMO_LOADED);
						//m_Activity = ACT_RESET;

						self.TaskComplete();
					}
				} else {
					//Drop Weapon
					if(self.pev.weapons > SCIENTIST_WEAPON_UNARMED) {
						DropWeapon();
					}
					//m_Activity = ACT_IDLE_ANGRY;
					self.ClearConditions(bits_COND_NO_AMMO_LOADED);
					self.m_Activity = ACT_IDLE;
					self.TaskFail();
				}
				break;
			}
		default:
			BaseClass.RunTask( pTask );
			break;
		}
	}
	
	int ISoundMask()
	{
		return	bits_SOUND_WORLD	|
				bits_SOUND_COMBAT	|
				bits_SOUND_BULLETHIT|
				bits_SOUND_CARCASS	|
				bits_SOUND_MEAT		|
				bits_SOUND_GARBAGE	|
				bits_SOUND_DANGER	|
				bits_SOUND_PLAYER;
	}
	
	int Classify()
	{
		return self.GetClassification(CLASS_HUMAN_MILITARY);
	}
	
	void SetYawSpeed()
	{
		int ys = 0;

		/*
		switch ( m_Activity )
		{
		case ACT_TURN_LEFT:
		case ACT_TURN_RIGHT:
			ys = 180;
			break;

		case ACT_IDLE:
		case ACT_WALK: 
			ys = 70;	
			break;
		case ACT_RUN:  
			ys = 90;	
			break;

		default:       
			ys = 70;	
			break;
		}
		*/

		ys = 360; //270 seems to be an ideal speed, which matches most animations

		self.pev.yaw_speed = ys;
	}
	
	bool CheckRangeAttack1( float flDot, float flDist )
	{	
		if( flDist <= 2048 && flDot >= 0.5 && self.NoFriendlyFire())
		{
			CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();
			TraceResult tr;
			Vector shootOrigin = self.pev.origin + Vector( 0, 0, 55 );
			Vector shootTarget = (pEnemy.BodyTarget( shootOrigin ) - pEnemy.Center()) + self.m_vecEnemyLKP;
			g_Utility.TraceLine( shootOrigin, shootTarget, dont_ignore_monsters, self.edict(), tr );
						
			if( tr.flFraction == 1.0 || tr.pHit is pEnemy.edict() )
				return true;
		}

		return false;
	}
	
	void BarneyFire()
	{
		int weapon = self.pev.weapons;

		Math.MakeVectors( self.pev.angles );
		Vector vecShootOrigin = self.pev.origin + Vector( 0, 0, 55 );
		Vector vecShootDir = self.ShootAtEnemy( vecShootOrigin );
		Vector angDir = Math.VecToAngles( vecShootDir ) * -1;

		if(weapon != SCIENTIST_WEAPON_GLOCK) {
			vecShootOrigin = self.pev.origin + Vector( 0, 0, 55 ) + g_Engine.v_right * 10.0;
		}
		vecShootDir = self.ShootAtEnemy( vecShootOrigin );

		int pitchShift = Math.RandomLong( 0, 20 );
		// Only shift about half the time
		if( pitchShift > 10 ) pitchShift = 0;
		else pitchShift -= 5;
		
		self.SetBlending( 0, angDir.x );
		self.pev.effects = EF_MUZZLEFLASH;

		if(weapon == SCIENTIST_WEAPON_GLOCK) {
			self.SetBlending( 0, angDir.x );

			self.FireBullets(1, vecShootOrigin, vecShootDir, VECTOR_CONE_2DEGREES, 1024, BULLET_MONSTER_9MM );
			Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40,90) + g_Engine.v_up * Math.RandomFloat(75,200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
			g_EntityFuncs.EjectBrass( vecShootOrigin - vecShootDir * -17, vecShellVelocity, self.pev.angles.y, m_iBrassShell, TE_BOUNCE_SHELL); 

			GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, self.pev.origin, NORMAL_GUN_VOLUME, 0.3, self );
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/pl_gun3.wav", 1, ATTN_NORM, 0, PITCH_NORM + pitchShift );
		} else if(weapon == SCIENTIST_WEAPON_M16) {
			self.FireBullets(1, vecShootOrigin, vecShootDir, VECTOR_CONE_5DEGREES, 4096, BULLET_PLAYER_MP5 );
			Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40,90) + g_Engine.v_up * Math.RandomFloat(75,200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
			g_EntityFuncs.EjectBrass( vecShootOrigin - vecShootDir * -17, vecShellVelocity, self.pev.angles.y, m_iBrassShell_762, TE_BOUNCE_SHELL); 

			GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, self.pev.origin, NORMAL_GUN_VOLUME, 0.3, self );
			int rand = Math.RandomLong(0,2);
			if(rand==0) g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "hlze/weapons/hks1.wav", 1, ATTN_NORM, 0, PITCH_NORM + pitchShift );
			else if(rand==1) g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "hlze/weapons/hks2.wav", 1, ATTN_NORM, 0, PITCH_NORM + pitchShift );
			else g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "hlze/weapons/hks3.wav", 1, ATTN_NORM, 0, PITCH_NORM + pitchShift );
		} else if(weapon == SCIENTIST_WEAPON_SPAS12) {
			self.FireBullets(3, vecShootOrigin, vecShootDir, VECTOR_CONE_5DEGREES, 2048, BULLET_PLAYER_BUCKSHOT );
			Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40,90) + g_Engine.v_up * Math.RandomFloat(75,200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
			g_EntityFuncs.EjectBrass( vecShootOrigin - vecShootDir * -17, vecShellVelocity, self.pev.angles.y, m_iBrassShell_shotgun, TE_BOUNCE_SHELL); 

			GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, self.pev.origin, NORMAL_GUN_VOLUME, 0.3, self );
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "hlze/weapons/shotgun_npc.wav", 1, ATTN_NORM, 0, PITCH_NORM + pitchShift );
		}

		if( self.pev.movetype != MOVETYPE_FLY && self.m_MonsterState != MONSTERSTATE_PRONE )
		{
			if(weapon == SCIENTIST_WEAPON_SPAS12) self.m_flAutomaticAttackTime = g_Engine.time + 1.0;
			else self.m_flAutomaticAttackTime = g_Engine.time + Math.RandomFloat(0.2, 0.5);
		}
		--self.m_cAmmoLoaded;// take away a bullet/shell!
	}
	
	void CheckAmmo()
	{
		if( self.m_cAmmoLoaded <= 0 )
			self.SetConditions( bits_COND_NO_AMMO_LOADED );
	}
	
	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
		case SCIENTIST_AE_SHOOT:
			BarneyFire();
			break;
		case SCIENTIST_AE_ATTACK:
		{
			int dmg = 25;
			int weapon = self.pev.weapons;
			if(weapon > SCIENTIST_WEAPON_GLOCK) dmg *= 2;

			CBaseEntity@ pHurt = CheckTraceHullAttack(self,70.0,dmg,DMG_CLUB);
			if(pHurt !is null)
			{
				if(pHurt.IsPlayer()) {
					pHurt.pev.punchangle.x = 5;
					if(pHurt.pev.size.z < 60) pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 300 + g_Engine.v_up * 80.0;
					else pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * -100;
				}
				g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,"weapons/cbar_hitbod2.wav",1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
			} else {
				g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,"zombie/claw_miss1.wav",1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
			}
			break;
		}

		default:
			BaseClass.HandleAnimEvent( pEvent );
		}
	}
	
	void Precache()
	{
		BaseClass.Precache();
		
		PrecacheInit();
	}
	
	void Spawn()
	{
		Precache();

		self.SetPlayerAlly(!self.IsPlayerAlly()); //Set Scientist as ally/foe upon spawning

		//Weapon Init
		SetupWeapon();

		g_EntityFuncs.SetSize(self.pev,VEC_HUMAN_HULL_MIN,VEC_HUMAN_HULL_MAX);

		pev.solid				= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		if( self.pev.health == 0.0f )
			self.pev.health  = 100.0f;
		self.pev.view_ofs			= Vector(0,0,50);// position of the eyes relative to monster's origin.
		self.m_flFieldOfView			= VIEW_FIELD_WIDE; // NOTE: we need a wide field of view so npc will notice player and say hello
		self.m_MonsterState			= MONSTERSTATE_NONE;
		//self.pev.body				= 0; // gun in holster
		m_fGunDrawn				= true;
		self.m_afCapability			= bits_CAP_HEAR | bits_CAP_TURN_HEAD | bits_CAP_DOORS_GROUP | bits_CAP_USE_TANK;
		self.m_fCanFearCreatures 		= true; // Can attempt to run away from things like zombies
		m_flNextFearScream			= g_Engine.time;
		//self.m_afMoveShootCap()		= bits_MOVESHOOT_RANGE_ATTACK1;

		if( string( self.m_FormattedName ).IsEmpty() )
		{
			self.m_FormattedName = "Scientist";
		}

		SetUse(UseFunction(this.FollowerUse));

		self.MonsterInit();
	}
	
	void SetupWeapon()
	{
		int weapon = self.pev.weapons;
		self.m_fCanFearCreatures = true;

		if(weapon == SCIENTIST_WEAPON_UNARMED) {
			self.SetBodygroup(3,0);
			dictionary keys;
			keys["origin"] = ""+self.pev.origin.ToString();
			keys["angles"] = ""+self.pev.angles.ToString();
			keys["spawnflags"] = ""+self.pev.flags;
			keys["body"] = ""+self.pev.body;
			keys["skin"] = ""+self.pev.skin;
			keys["health"] = ""+self.pev.health;
			keys["targetname"] = ""+self.pev.targetname;
			keys["weapons"] = ""+0;
			CBaseEntity@ NormalScientist = g_EntityFuncs.CreateEntity("monster_scientist", keys);
			g_EntityFuncs.Remove(self);
			return;
		} if(weapon == SCIENTIST_WEAPON_M16) {
			self.SetBodygroup(3,1);
			m_cClipSize = 50;
			m_cBackpackAmmmo = m_cClipSize * Math.RandomLong(0,2);
			g_EntityFuncs.SetModel(self,NPC_M16_MODEL);
		} else if(weapon == SCIENTIST_WEAPON_SPAS12) {
			self.SetBodygroup(3,1);
			m_cClipSize = 8;
			m_cBackpackAmmmo = m_cClipSize * Math.RandomLong(0,1);
			g_EntityFuncs.SetModel(self,NPC_SPAS12_MODEL);
		} else if(weapon == SCIENTIST_WEAPON_GLOCK) {
			self.SetBodygroup(3,1);
			g_EntityFuncs.SetModel(self,NPC_GLOCK_MODEL);
			m_cClipSize = 17;
			m_cBackpackAmmmo = m_cClipSize * Math.RandomLong(1,3);
		} else if(weapon == SCIENTIST_WEAPON_RANDOM) {
			self.pev.weapons = Math.RandomLong(0,SCIENTIST_WEAPON_RANDOM-1);
			SetupWeapon();
		} else {
			g_EntityFuncs.SetModel(self,NPC_GLOCK_MODEL);
			self.pev.weapons = SCIENTIST_WEAPON_GLOCK;
			SetupWeapon();
		}
		self.SetBodygroup(3,1);
		self.m_cAmmoLoaded = m_cClipSize;
		
		g_EntityFuncs.SetSize(self.pev,VEC_HUMAN_HULL_MIN,VEC_HUMAN_HULL_MAX);
		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_STEP;
		
		self.GetScheduleOfType(SCHED_IDLE_STAND);
		
		self.m_flAutomaticAttackTime = g_Engine.time;
	}

	void DropWeapon()
	{
		int weapon = self.pev.weapons;
		//Create Weapon
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("proj_barney_helmet");
		Proj_BarneyHelmet@ Projectile = cast<Proj_BarneyHelmet@>(CastToScriptClass(entBase));
		Projectile.Do_Blood = false;
		g_EntityFuncs.DispatchSpawn(Projectile.self.edict());
		if(weapon == SCIENTIST_WEAPON_M16) {
			g_EntityFuncs.SetModel(entBase,"models/hlze/w_9mmar.mdl");
		} else if(weapon == SCIENTIST_WEAPON_SPAS12) {
			g_EntityFuncs.SetModel(entBase,"models/hlze/w_shotgun.mdl");
		}else if(weapon == SCIENTIST_WEAPON_GLOCK) {
			g_EntityFuncs.SetModel(entBase,"models/hlze/w_9mmhandgun.mdl");
		}
		Math.MakeVectors(self.pev.angles);
		Projectile.pev.origin = self.pev.origin + g_Engine.v_forward * 20.0 + Vector(0,0,50);
		Projectile.pev.angles.y = self.pev.angles.y;
		//Remove Weapon
		self.pev.weapons = SCIENTIST_WEAPON_UNARMED;
		SetupWeapon();
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{	
		if( pevAttacker is null )
			return 0;

		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );

		if( self.CheckAttacker( pAttacker ) )
			return 0;

		// make sure friends talk about it if player hurts talkmonsters...
		int ret = BaseClass.TakeDamage(pevInflictor, pevAttacker, flDamage, bitsDamageType);
		if( ( !self.IsAlive() || self.pev.deadflag == DEAD_DYING) && (!self.IsPlayerAlly()))	// evils dont alert friends!
			return ret;

		if( self.m_MonsterState != MONSTERSTATE_PRONE && (pevAttacker.flags & FL_CLIENT) != 0 )
		{
			// This is a heurstic to determine if the player intended to harm me
			// If I have an enemy, we can't establish intent (may just be crossfire)
			if( !self.m_hEnemy.IsValid() )
			{		
				if( self.pev.deadflag == DEAD_NO )
				{
					// If the player was facing directly at me, or I'm already suspicious, get mad
					if( (self.m_afMemory & bits_MEMORY_SUSPICIOUS) != 0 || pAttacker.IsFacing( self.pev, 0.96f ) )
					{
						// Alright, now I'm pissed!
						//PlaySentence( "BA_MAD", 4, VOL_NORM, ATTN_NORM );

						self.Remember( bits_MEMORY_PROVOKED );
						self.StopPlayerFollowing( true, false );
					}
					else
					{
						// Hey, be careful with that
						//PlaySentence( "BA_SHOT", 4, VOL_NORM, ATTN_NORM );
						self.Remember( bits_MEMORY_SUSPICIOUS );
					}
				}
			}
			else if( (!self.m_hEnemy.GetEntity().IsPlayer()) && self.pev.deadflag == DEAD_NO )
			{
				//PlaySentence( "BA_SHOT", 4, VOL_NORM, ATTN_NORM );
			}
		}

		return ret;
	}
	
	void FearScream()
	{
		if( m_flNextFearScream < g_Engine.time )
		{
			switch (Math.RandomLong(0,2))
			{
			case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/scream06.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/scream02.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			case 2: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/scream05.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			}

			m_flNextFearScream = g_Engine.time + Math.RandomLong(2,5);
		}
	}
	
	void PainSound()
	{
		if(g_Engine.time < m_painTime)
			return;
		
		m_painTime = g_Engine.time + Math.RandomFloat(0.5, 0.75);
		switch (Math.RandomLong(0,9))
		{
		case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain1.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain2.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 2: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain3.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 3: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain4.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 4: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain5.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 5: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain6.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 6: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain7.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 7: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain8.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 8: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain9.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 9: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_pain10.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		}
	}
	
	void DeathSound()
	{
		switch (Math.RandomLong(0,3))
		{
		case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_die1.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_die2.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 2: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_die3.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		case 3: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/sci_die4.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
		}
	}
	
	void TraceAttack( entvars_t@ pevAttacker, float flDamage, Vector vecDir, TraceResult& in ptr, int bitsDamageType)
	{
		switch( ptr.iHitgroup)
		{
		case HITGROUP_CHEST:
		case HITGROUP_STOMACH:
			if( ( bitsDamageType & ( DMG_BULLET | DMG_SLASH | DMG_BLAST) ) != 0 )
			{
				if(flDamage >= 2)
					flDamage -= 2;

				flDamage *= 0.5;
			}
			break;
		case 10:
			if( ( bitsDamageType & (DMG_SNIPER | DMG_BULLET | DMG_SLASH | DMG_CLUB) ) != 0 )
			{
				flDamage -= 20;
				if( flDamage <= 0 )
				{
					g_Utility.Ricochet( ptr.vecEndPos, 1.0 );
					flDamage = 0.01;
				}
			}
			// always a head shot
			ptr.iHitgroup = HITGROUP_HEAD;
			break;
		}

		BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
	}
	
	Schedule@ GetScheduleOfType( int Type )
	{		
		Schedule@ psched;

		switch( Type )
		{
		case SCHED_ARM_WEAPON:
			if( self.m_hEnemy.IsValid() )
				return slBarneyEnemyDraw;// face enemy, then draw.
			break;

		// Hook these to make a looping schedule
		case SCHED_TARGET_FACE:
			// call base class default so that barney will talk
			// when 'used' 
			@psched = BaseClass.GetScheduleOfType( Type );
			
			if( psched is Schedules::slIdleStand )
				return slBaFaceTarget;	// override this for different target face behavior
			else
				return psched;


		case SCHED_RELOAD:
			return slBaReloadQuick; //Immediately reload.

		case SCHED_SCIENTIST_RELOAD:
			return slBaReload;

		case SCHED_TARGET_CHASE:
			return slBaFollow;

		case SCHED_IDLE_STAND:
			// call base class default so that scientist will talk
			// when standing during idle
			@psched = BaseClass.GetScheduleOfType( Type );

			if( psched is Schedules::slIdleStand )		
				return slIdleBaStand;// just look straight ahead.
			else
				return psched;
		}

		return BaseClass.GetScheduleOfType( Type );
	}
	
	Schedule@ GetSchedule()
	{
		if( self.HasConditions( bits_COND_HEAR_SOUND ) )
		{
			CSound@ pSound = self.PBestSound();

			if( pSound !is null && (pSound.m_iType & bits_SOUND_DANGER) != 0 )
			{
				FearScream(); //AGHH!!!!
				return self.GetScheduleOfType( SCHED_TAKE_COVER_FROM_BEST_SOUND );
			}
		}

		if( self.HasConditions( bits_COND_ENEMY_DEAD ) ) {
			switch (Math.RandomLong(0,4))
			{
			case 0: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/dontwantdie.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			case 1: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/ipredictedthis.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			case 2: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/getoutalive.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			case 3: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/scream17.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			case 4: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "scientist/nooo.wav", 1, ATTN_NORM, 0, VoicePitch()); break;
			}
		}

		switch( self.m_MonsterState )
		{
		case MONSTERSTATE_COMBAT:
			{
				// dead enemy
				if( self.HasConditions( bits_COND_ENEMY_DEAD ) )				
					return BaseClass.GetSchedule();// call base class, all code to handle dead enemies is centralized there.

				// always act surprized with a new enemy
				if( self.HasConditions( bits_COND_NEW_ENEMY ) && self.HasConditions( bits_COND_LIGHT_DAMAGE) )
					return self.GetScheduleOfType( SCHED_SMALL_FLINCH );
					
				// wait for one schedule to draw gun
				if( !m_fGunDrawn && self.pev.weapons == SCIENTIST_WEAPON_GLOCK )
					return self.GetScheduleOfType( SCHED_ARM_WEAPON );

				if( self.HasConditions( bits_COND_HEAVY_DAMAGE ) )
					return self.GetScheduleOfType( SCHED_TAKE_COVER_FROM_ENEMY );
				
				//Scientist reloads now.
				if( self.HasConditions ( bits_COND_NO_AMMO_LOADED ) )
					return self.GetScheduleOfType ( SCHED_SCIENTIST_RELOAD );
				
				//Check Enemy
				CBaseEntity@ ent = self.m_hEnemy;
				if(ent !is null)
				{
					float Distance = (self.pev.origin - ent.pev.origin).Length();
					if(Distance < 70.0) {
						if(ent.pev.size.z < 60) return self.GetScheduleOfType ( SCHED_MELEE_ATTACK1 ); //2
						else return self.GetScheduleOfType ( SCHED_MELEE_ATTACK1 );
					}
				}
			}
			break;

		case MONSTERSTATE_IDLE:
				//Barney reloads now.
				if( self.m_cAmmoLoaded != m_cClipSize )
					return self.GetScheduleOfType( SCHED_SCIENTIST_RELOAD );

		case MONSTERSTATE_ALERT:	
			{
				if( self.HasConditions(bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE) )
					return self.GetScheduleOfType( SCHED_SMALL_FLINCH ); // flinch if hurt

				//The player might have just +used us, immediately follow and dis-regard enemies.
				//This state gets set (alert) when the monster gets +used
				if( (!self.m_hEnemy.IsValid() || !self.HasConditions( bits_COND_SEE_ENEMY)) && self.IsPlayerFollowing() )	//Start Player Following
				{
					if( !self.m_hTargetEnt.GetEntity().IsAlive() )
					{
						self.StopPlayerFollowing( false, false );// UNDONE: Comment about the recently dead player here?
						break;
					}
					else
					{
						return self.GetScheduleOfType( SCHED_TARGET_FACE );
					}
				}
			}
			break;
		}
		
		return BaseClass.GetSchedule();
	}
	
	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if(self.IRelationship(pActivator) >= R_NO)
			return;

		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
		
		CBaseEntity@ pTarget = self.m_hTargetEnt;

		if( pTarget is pActivator )
		{
			g_SoundSystem.PlaySentenceGroup(self.edict(),  "SC_OK", 1.0, ATTN_NORM, 0, VoicePitch());
		}
		else {
			g_SoundSystem.PlaySentenceGroup(self.edict(), "SC_WAIT", 1.0, ATTN_NORM, 0, VoicePitch());
		}
	}

	//Voice Pith based on Head ID
	int VoicePitch() {
		// get voice for head
		int m_voicePitch = 100;
		switch (self.GetBodygroup(1))
		{
			case 0:	m_voicePitch = 105; break;	//glasses
			case 1: m_voicePitch = 100; break;	//einstein
			case 2:	m_voicePitch = 95;  break;	//luther
			case 3:	m_voicePitch = 100;  break;	//slick
		}
		return m_voicePitch;
	}
}

array<ScriptSchedule@>@ monster_scientist_schedules;

ScriptSchedule slBaFollow( 
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER, 
	"Follow" );
		
ScriptSchedule slBaFaceTarget(
	//bits_COND_CLIENT_PUSH	|
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND ,
	bits_SOUND_DANGER,
	"FaceTarget" );
	
ScriptSchedule slIdleBaStand(
	bits_COND_NEW_ENEMY		|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND	|
	bits_COND_SMELL,

	bits_SOUND_COMBAT		|// sound flags - change these, and you'll break the talking code.	
	bits_SOUND_DANGER		|
	bits_SOUND_MEAT			|// scents
	bits_SOUND_CARCASS		|
	bits_SOUND_GARBAGE,
	"IdleStand" );
	
ScriptSchedule slBaReload(
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER,
	"Scientist Reload");
	
ScriptSchedule slBaReloadQuick(
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER,
	"Scientist Reload Quick");
		
ScriptSchedule slBarneyEnemyDraw( 0, 0, "Scientist Enemy Draw" );

void InitSchedules()
{
		
	slBaFollow.AddTask( ScriptTask(TASK_MOVE_TO_TARGET_RANGE, 128.0f) );
	slBaFollow.AddTask( ScriptTask(TASK_SET_SCHEDULE, SCHED_TARGET_FACE) );
	
	slBarneyEnemyDraw.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slBarneyEnemyDraw.AddTask( ScriptTask(TASK_FACE_ENEMY) );
	//slBarneyEnemyDraw.AddTask( ScriptTask(TASK_PLAY_SEQUENCE_FACE_ENEMY, float(ACT_ARM)) );
	slBarneyEnemyDraw.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
		
	slBaFaceTarget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slBaFaceTarget.AddTask( ScriptTask(TASK_FACE_TARGET) );
	slBaFaceTarget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slBaFaceTarget.AddTask( ScriptTask(TASK_SET_SCHEDULE, float(SCHED_TARGET_CHASE)) );
		
	slIdleBaStand.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slIdleBaStand.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );
	slIdleBaStand.AddTask( ScriptTask(TASK_WAIT, 2) );
	//slIdleBaStand.AddTask( ScriptTask(TASK_TLK_HEADRESET) );
		
	slBaReload.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slBaReload.AddTask( ScriptTask(TASK_SET_FAIL_SCHEDULE, float(SCHED_RELOAD)) );
	slBaReload.AddTask( ScriptTask(TASK_FIND_COVER_FROM_ENEMY) );
	slBaReload.AddTask( ScriptTask(TASK_RUN_PATH) );
	slBaReload.AddTask( ScriptTask(TASK_REMEMBER, float(bits_MEMORY_INCOVER)) );
	slBaReload.AddTask( ScriptTask(TASK_WAIT_FOR_MOVEMENT_ENEMY_OCCLUDED) );
	slBaReload.AddTask( ScriptTask(TASK_RELOAD) );
	slBaReload.AddTask( ScriptTask(TASK_FACE_ENEMY) );
			
	slBaReloadQuick.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slBaReloadQuick.AddTask( ScriptTask(TASK_RELOAD) );
	slBaReloadQuick.AddTask( ScriptTask(TASK_FACE_ENEMY) );
	
	array<ScriptSchedule@> scheds = {slBaFollow, slBarneyEnemyDraw, slBaFaceTarget, slIdleBaStand, slBaReload, slBaReloadQuick};
	
	@monster_scientist_schedules = @scheds;
}

enum monsterScheds
{
	SCHED_SCIENTIST_RELOAD = LAST_COMMON_SCHEDULE + 1,
}

void PrecacheInit() {
	g_SoundSystem.PrecacheSound("scientist/sci_pain1.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain2.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain3.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain4.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain5.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain6.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain7.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain8.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain9.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_pain10.wav");

	g_SoundSystem.PrecacheSound("scientist/sci_die1.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_die2.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_die3.wav");
	g_SoundSystem.PrecacheSound("scientist/sci_die4.wav");

	g_SoundSystem.PrecacheSound("scientist/scream06.wav");
	g_SoundSystem.PrecacheSound("scientist/scream02.wav");
	g_SoundSystem.PrecacheSound("scientist/scream05.wav");

	g_SoundSystem.PrecacheSound("scientist/dontwantdie.wav");
	g_SoundSystem.PrecacheSound("scientist/ipredictedthis.wav");
	g_SoundSystem.PrecacheSound("scientist/getoutalive.wav");
	g_SoundSystem.PrecacheSound("scientist/scream17.wav");
	g_SoundSystem.PrecacheSound("scientist/nooo.wav");

	//Weapons
	g_Game.PrecacheModel(NPC_UNARMED_MODEL);
	g_Game.PrecacheModel(NPC_GLOCK_MODEL);
	g_Game.PrecacheModel(NPC_M16_MODEL);
	g_Game.PrecacheModel(NPC_SPAS12_MODEL);
	m_iBrassShell = g_Game.PrecacheModel("models/shell.mdl");
	m_iBrassShell_762 = g_Game.PrecacheModel("models/shell_762.mdl");
	m_iBrassShell_shotgun = g_Game.PrecacheModel("models/shotgunshell.mdl");
	g_Game.PrecacheModel("models/hlze/w_9mmar.mdl");
	g_Game.PrecacheModel("models/hlze/w_shotgun.mdl");
	g_Game.PrecacheModel("models/hlze/w_9mmhandgun.mdl");
	g_SoundSystem.PrecacheSound("weapons/pl_gun3.wav");
	g_SoundSystem.PrecacheSound("hlze/weapons/hks1.wav");
	g_SoundSystem.PrecacheSound("hlze/weapons/hks2.wav");
	g_SoundSystem.PrecacheSound("hlze/weapons/hks3.wav");
	g_SoundSystem.PrecacheSound("hlze/weapons/shotgun_npc.wav");
	g_SoundSystem.PrecacheSound("weapons/cbar_hitbod2.wav");
	g_SoundSystem.PrecacheSound("zombie/claw_miss1.wav");
}

void Register()
{
	InitSchedules();
	PrecacheInit();
	g_CustomEntityFuncs.RegisterCustomEntity("HLZE_Scientist::CHLZE_Scientist", "monster_hlze_scientist");
}

} // end of namespace
