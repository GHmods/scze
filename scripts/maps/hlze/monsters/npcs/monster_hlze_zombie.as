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
// Zombie
//=========================================================

/* 
* Custom Zombie Monster entity
* Call HLZE_Zombie::Register() to register this entity.
* Entity classname: monster_hlze_zombie
*/
#include "checktracehullattack"
#include "precache_sounds"

namespace HLZE_Zombie
{
//Gore
array<int>m_iBlood(2);

const array<string>pAttackSounds = {
	"zombie/zo_attack1.wav",
	"zombie/zo_attack2.wav",
};
const array<string>pAttackSounds_grunt = {
	"zombie/zo_nade_attack1.wav",
	"zombie/zo_nade_attack2.wav",
};

const array<string>pIdleSounds = 
{
	"zombie/zo_idle1.wav",
	"zombie/zo_idle2.wav",
	"zombie/zo_idle3.wav",
	"zombie/zo_idle4.wav"
};

const array<string>pIdleSounds_grunt = 
{
	"zombie/zo_nade_idle1.wav",
	"zombie/zo_nade_idle2.wav",
	"zombie/zo_nade_idle3.wav",
	"zombie/zo_nade_idle4.wav"
};

const array<string>pAlertSounds = {
	"zombie/zo_alert10.wav",
	"zombie/zo_alert20.wav",
	"zombie/zo_alert30.wav"
};

const array<string>pAlertSounds_grunt = {
	"zombie/zo_nade_alert10.wav",
	"zombie/zo_nade_alert20.wav",
	"zombie/zo_nade_alert30.wav"
};

const array<string>pPainSounds = {
	"zombie/zo_pain1.wav",
	"zombie/zo_pain2.wav"
};

const array<string>pPainSounds_grunt = {
	"zombie/zo_nade_pain1.wav",
	"zombie/zo_nade_pain1.wav"
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
const int ZOMBIE_AE_ATTACK_BOTH		= 3;
const int ZOMBIE_AE_CHEST_BLOOD		= 5;
const int ZOMBIE_AE_DEPLOY_GRENADE	= 10;

const float ZOMBIE_FLINCH_DELAY		= 2.0;
const float ZOMBIE_IDLE_SOUND_DELAY	= 3.5;

const string zombieModel		= "models/hlze/zombie.mdl";
const bool zombie_CanBeLimped		= true; //Can be limped?
const string zombieModel_limped		= "models/hlze/zombie_limping.mdl";
const float zombieHealth		= 100.0;
const float zombieSlashDist		= 70.0;
const float zombieDmgOneSlash		= 25.0;
const float zombieDmgBothSlash		= 50.0;

const int INFECTED_ID_MASK		= 3;

class CHLZE_Zombie : ScriptBaseMonsterEntity
{
	//Zombie Type
	int zombie_type = INFECTED_NONE;
	//Next Flinch Timer
	private float m_flNextFlinch;
	//Next Idle Sound Timer
	private float m_flNextIdleSound;
	//Used for 'Getting Up!' Task
	private bool getUp = false;
	private bool deadOnStomach = false;
	//Grenade Attack
	private bool ThrowGrenade = false;
	private float NextGrenadeCheck; //Grenade Processing Timer
	float GrenadeThrowFrequency = 15.0; //Throw Grenade every x.x seconds
	private float NextGrenadeThrow; //Throw Grenade Timer
	int GrenadeCount = 0; //Grenade Ammo
	float GrenadeSpeed = 100.0; //Grenade Forward Throw
	//Limping
	bool zombie_IsLimped = false;
	bool zombie_LimpNow = false;
	
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
		int ys = 120;
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
			if(HasMask()) g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pPainSounds_grunt[Math.RandomLong(0,pPainSounds_grunt.length()-1)],1,ATTN_NORM,0,pitch);
			else g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pPainSounds[Math.RandomLong(0,pPainSounds.length()-1)],1,ATTN_NORM,0,pitch);
		}
	}
	// Alert Sound
	void AlertSound() {
		int pitch = 95 + Math.RandomLong(0,9);
		if(HasMask()) g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pAlertSounds_grunt[Math.RandomLong(0,pAlertSounds_grunt.length()-1)],1,ATTN_NORM,0,pitch);
		else g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pAlertSounds[Math.RandomLong(0,pAlertSounds.length()-1)],1,ATTN_NORM,0,pitch);
	}
	// Idle Sound
	void IdleSound() {
		if(m_flNextIdleSound>g_Engine.time)
			return;
		
		int pitch = 95 + Math.RandomLong(0,9);
		if(HasMask()) g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pIdleSounds_grunt[Math.RandomLong(0,pIdleSounds_grunt.length()-1)],1,ATTN_NORM,0,pitch);
		else g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pIdleSounds[Math.RandomLong(0,pIdleSounds.length()-1)],1,ATTN_NORM,0,pitch);

		m_flNextIdleSound = g_Engine.time + ZOMBIE_IDLE_SOUND_DELAY;
	}
	// Attack Sound
	void AttackSound() {
		int pitch = 95 + Math.RandomLong(0,9);
		if(HasMask()) g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pAttackSounds_grunt[Math.RandomLong(0,pAttackSounds_grunt.length()-1)],1,ATTN_NORM,0,pitch);
		else g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_VOICE,pAttackSounds[Math.RandomLong(0,pAttackSounds.length()-1)],1,ATTN_NORM,0,pitch);
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
			case ZOMBIE_AE_ATTACK_BOTH: {
				// do stuff for this event.
				CBaseEntity@ pHurt = CheckTraceHullAttack(self,zombieSlashDist,zombieDmgBothSlash,DMG_SLASH);
				if(pHurt !is null) {
					if(pHurt.IsPlayer()) {
						pHurt.pev.punchangle.x = 5;
						pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * -100;
					}
					g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,pAttackHitSounds[Math.RandomLong(0,pAttackHitSounds.length()-1)],1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
				} else {
					g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_WEAPON,pAttackMissSounds[Math.RandomLong(0,pAttackMissSounds.length()-1)],1,ATTN_NORM,0,100+Math.RandomLong(-5,5));
				}

				if(Math.RandomLong(0,1) == 1)
					AttackSound();
				break;
			}
			case ZOMBIE_AE_CHEST_BLOOD: {
				//Do blood sprite only if zombie is eating
				if(self.m_Activity==ACT_VICTORY_DANCE) {
					//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"EATING...\n");
					//Vector blood_location = self.pev.origin + g_Engine.v_forward * -5.0 + g_Engine.v_up * 25.0;
					Vector blood_location,blood_angles;
					int ChestBoneID = 11;
					self.GetBonePosition(ChestBoneID,blood_location,blood_angles);
					Math.MakeVectors(self.pev.angles);
					blood_location = blood_location + g_Engine.v_forward * 5.0;

					//Try to obtain enemy blood color
					int blood_color = BLOOD_COLOR_RED;
					CBaseMonster@ enemyMonster;
					Vector search_location = self.pev.origin + g_Engine.v_forward * 50.0;
					array<CBaseEntity@>pMonsters(25);
					g_EntityFuncs.MonstersInSphere(pMonsters, search_location, 50.0);
					for(uint i=0;i<pMonsters.length();i++) {
						if(pMonsters[i] !is null) {
							//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Found:"+pMonsters[i].pev.classname+"\n");
							CBaseMonster@ monster = pMonsters[i].MyMonsterPointer(); 
							if(!monster.IsAlive() && monster.m_MonsterState==MONSTERSTATE_DEAD) {
								@enemyMonster = monster;
								break;
							}
						}
					}

					if(enemyMonster !is null) {
						//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Custom Blood Color!\n");
						blood_color = enemyMonster.m_bloodColor;
					}

					NetworkMessage blood(MSG_BROADCAST,NetworkMessages::SVC_TEMPENTITY);
						blood.WriteByte(TE_BLOODSPRITE);
						blood.WriteCoord(blood_location.x);
						blood.WriteCoord(blood_location.y);
						blood.WriteCoord(blood_location.z);
						
						blood.WriteShort(int(m_iBlood[1]));
						blood.WriteShort(int(m_iBlood[0]));
						
						blood.WriteByte(blood_color);
						blood.WriteByte(Math.RandomLong(10,17));
					blood.End();
				}
				break;
			}
			case ZOMBIE_AE_DEPLOY_GRENADE: {
				self.SetBodygroup(2,1); //Grenade
				ThrowGrenade=true;
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
			self.m_FormattedName = "Zombie";
		}

		Setup_Zombie(Math.RandomLong(INFECTED_SCIENTIST,INFECTED_MASSN));
	}

	void Setup_Monster() {
		g_EntityFuncs.SetSize(self.pev,VEC_HUMAN_HULL_MIN,VEC_HUMAN_HULL_MAX);
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_GREEN;
		self.pev.health = zombieHealth;
		self.pev.view_ofs = VEC_VIEW; //position of the eyes relative to monster's origin.
		self.m_flFieldOfView = 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
		self.m_MonsterState = MONSTERSTATE_NONE;
		self.m_afCapability = bits_CAP_DOORS_GROUP;

		self.MonsterInit();

		self.ChangeYaw(30);

		// Do Not Remove This Monster on Death
		//SF_MONSTER_FADECORPSE = 512;
		self.pev.spawnflags |= 512;
	}
	void Monster_Limping() {
		//Recreate this NPC
		CBaseEntity@ zombieEnt = g_EntityFuncs.CreateEntity("monster_hlze_zombie");
		CBaseMonster@ zombieMonster = zombieEnt.MyMonsterPointer();
		CHLZE_Zombie@ zombie = cast<CHLZE_Zombie@>(CastToScriptClass(zombieEnt));
		g_EntityFuncs.DispatchSpawn(zombieMonster.edict());
		zombie.Setup_Monster();
		
		zombieMonster.pev.origin = self.pev.origin;
		zombieMonster.pev.angles = self.pev.angles;
		//zombieMonster.pev.body = self.pev.body;
		zombieMonster.pev.health = zombieHealth/2;

		zombieMonster.SetPlayerAlly(self.IsPlayerAlly());
		g_EntityFuncs.SetModel(zombieMonster,zombieModel);

		zombie.Setup_ZombieByType(zombie_type,GrenadeCount,false);
		zombie.getUp = false;
		zombie.deadOnStomach = true;
		zombie.zombie_LimpNow = true;

		g_EntityFuncs.Remove(self);
		
		zombieMonster.ResetSequenceInfo();
		zombieMonster.SetSequenceByName("diesimple");
		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Limping Started!\n");

		zombieMonster.pev.solid=SOLID_NOT;
		zombieMonster.m_MonsterState=MONSTERSTATE_IDLE;
	}
	void Setup_Monster_Limped() {
		//Recreate this NPC
		CBaseEntity@ zombieEnt = g_EntityFuncs.CreateEntity("monster_hlze_zombie");
		CBaseMonster@ zombieMonster = zombieEnt.MyMonsterPointer();
		CHLZE_Zombie@ zombie = cast<CHLZE_Zombie@>(CastToScriptClass(zombieEnt));
		g_EntityFuncs.DispatchSpawn(zombieMonster.edict());
		zombie.Setup_Monster();
		
		zombieMonster.pev.origin = self.pev.origin;
		zombieMonster.pev.angles = self.pev.angles;
		//zombieMonster.pev.body = self.pev.body;
		zombieMonster.pev.health = zombieHealth/2;

		zombieMonster.SetPlayerAlly(self.IsPlayerAlly());
		g_EntityFuncs.SetModel(zombieMonster,zombieModel_limped);
		g_EntityFuncs.SetSize(zombieMonster.pev,VEC_HUMAN_HULL_MIN+Vector(0,-18,0),VEC_HUMAN_HULL_MAX/2+Vector(0,18,0));

		zombie.Setup_ZombieByType(zombie_type,GrenadeCount,false);
		zombie.getUp = false;
		zombie.deadOnStomach = true;
		zombie.zombie_LimpNow = false;
		zombie.zombie_IsLimped = true;

		g_EntityFuncs.Remove(self);
		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Limping....Initialized!\n");
	}
	void Setup_Monster_FromLimped() {
		//Recreate this NPC
		CBaseEntity@ zombieEnt = g_EntityFuncs.CreateEntity("monster_hlze_zombie");
		CBaseMonster@ zombieMonster = zombieEnt.MyMonsterPointer();
		CHLZE_Zombie@ zombie = cast<CHLZE_Zombie@>(CastToScriptClass(zombieEnt));
		g_EntityFuncs.DispatchSpawn(zombieMonster.edict());
		
		zombieMonster.pev.origin = self.pev.origin;
		zombieMonster.pev.angles = self.pev.angles;
		//zombieMonster.pev.body = self.pev.body;

		zombieMonster.SetPlayerAlly(self.IsPlayerAlly());
		zombie.Setup_Monster();
		zombieMonster.pev.health = zombieHealth;

		zombie.Setup_ZombieByType(zombie_type,GrenadeCount,false);
		zombie.deadOnStomach = true;
		zombie.getUp = true;

		g_EntityFuncs.Remove(self);
		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Healed!\n");

		zombieMonster.ResetSequenceInfo();
		zombieMonster.SetSequenceByName("limp_leg_idle");
	}

	void Setup_Zombie(int custom_id=-1, bool byBody=false) {
		if(custom_id!=-1) {
			zombie_type = custom_id;
		}

		if(byBody) {
			if(self.GetBodygroup(0)==0) zombie_type = INFECTED_SCIENTIST;
			else if(self.GetBodygroup(0)==1) zombie_type = INFECTED_GUARD;
			else if(self.GetBodygroup(0)==2) zombie_type = INFECTED_HGRUNT_MASKLESS;
			else if(self.GetBodygroup(0)==3) zombie_type = INFECTED_HGRUNT;
			else if(self.GetBodygroup(0)==4) zombie_type = INFECTED_MASSN;
			else {
				zombie_type = INFECTED_NONE;
			}
		}
		//Now Set Up Values
		self.pev.skin=0;
		if(zombie_type == INFECTED_NONE) {
			self.SetBodygroup(1,4); //Headcrab
			GrenadeCount = 0; //Grenade Ammo
		} else if(zombie_type == INFECTED_SCIENTIST) {
			self.SetBodygroup(0,0); //Body
			self.SetBodygroup(1,0); //Headcrab
			GrenadeCount = 0; //Grenade Ammo
		} else if(zombie_type == INFECTED_GUARD) {
			self.SetBodygroup(0,1); //Body
			self.SetBodygroup(1,1); //Headcrab
			GrenadeCount = 0; //Grenade Ammo
			self.pev.armorvalue = 45;
		} else if(zombie_type == INFECTED_HGRUNT_MASKLESS) {
			self.SetBodygroup(0,2); //Body
			self.SetBodygroup(1,2); //Headcrab
			GrenadeCount = 3; //Grenade Ammo
			self.pev.armorvalue = 100;
		} else if(zombie_type == INFECTED_HGRUNT) {
			self.SetBodygroup(0,2); //Body
			self.SetBodygroup(1,3); //Headcrab
			GrenadeCount = 3; //Grenade Ammo
			self.pev.armorvalue = 100;
		} else if(zombie_type == INFECTED_MASSN) {
			self.SetBodygroup(0,4); //Body
			self.SetBodygroup(1,0); //Headcrab
			GrenadeCount = 2; //Grenade Ammo
			self.pev.armorvalue = 80;
		}
	}

	void Setup_ZombieByType(int custom_id=-1,int gCount=0,bool firstTime=false) {
		if(custom_id!=-1) {
			zombie_type = custom_id;
		} else {
			return;
		}
		//Now Set Up Values
		self.pev.skin=0;
		if(zombie_type == INFECTED_NONE) {
			self.SetBodygroup(1,4); //Headcrab
			GrenadeCount = gCount; //Grenade Ammo
		} else if(zombie_type == INFECTED_SCIENTIST) {
			self.SetBodygroup(0,0); //Body
			self.SetBodygroup(1,0); //Headcrab
			GrenadeCount = gCount; //Grenade Ammo
		} else if(zombie_type == INFECTED_GUARD) {
			self.SetBodygroup(0,1); //Body
			self.SetBodygroup(1,1); //Headcrab
			GrenadeCount = gCount; //Grenade Ammo
			if(firstTime) {
				self.pev.armorvalue = 45;
			}
		} else if(zombie_type == INFECTED_HGRUNT_MASKLESS) {
			self.SetBodygroup(0,2); //Body
			self.SetBodygroup(1,2); //Headcrab
			GrenadeCount = gCount; //Grenade Ammo
			if(firstTime) {
				self.pev.armorvalue = 100;
			}
		} else if(zombie_type == INFECTED_HGRUNT) {
			self.SetBodygroup(0,2); //Body
			self.SetBodygroup(1,3); //Headcrab
			GrenadeCount = gCount; //Grenade Ammo
			if(firstTime) {
				self.pev.armorvalue = 100;
			}
		} else if(zombie_type == INFECTED_MASSN) {
			self.SetBodygroup(0,4); //Body
			self.SetBodygroup(1,0); //Headcrab
			GrenadeCount = gCount; //Grenade Ammo
			if(firstTime) {
				self.pev.armorvalue = 80;
			}
		}
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
	// Grenade Attack
	//=========================================================
	int ThrowGrenadeFunction() {
		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Processing........\n");
		// assume things haven't changed too much since last time
		if(g_Engine.time < NextGrenadeCheck)
			return 0;
		
		Vector vecTarget;

		if(HasGrenade() && ThrowGrenade && GrenadeCount > 0) {
			// find feet
			if(Math.RandomLong(0,1)==1)
			{
				// magically know where they are
				vecTarget = Vector(self.m_hEnemy.GetEntity().pev.origin.x, self.m_hEnemy.GetEntity().pev.origin.y, self.m_hEnemy.GetEntity().pev.absmin.z);
			} else {
				// toss it to where you last saw them
				vecTarget = self.m_vecEnemyLKP;
			}
			//Check Distance
			float dist2Enemy = (self.pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length();
			if(dist2Enemy < 256.0) {
				//Throw The Grenade
				Vector vecSrc = self.pev.origin + self.pev.view_ofs + g_Engine.v_forward * 16;
				Math.MakeVectors(self.pev.angles);
				Vector vecThrow = g_Engine.v_forward * GrenadeSpeed + g_Engine.v_up * 75.0 + self.pev.velocity;
				CGrenade@ pGrenade = g_EntityFuncs.ShootTimed(self.pev,vecSrc,vecThrow,3.0);
				pGrenade.pev.dmg = 150;
				//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Throwing!!!\n");
				//The End
				ThrowGrenade=false;
				NextGrenadeThrow = g_Engine.time + GrenadeThrowFrequency;
				self.SetBodygroup(2,0); //Grenade
				//Take 1 Grenade Ammo
				GrenadeCount--;
				return 2;
			}
			return 1;
		}

		return 0;
	}

	bool HasGrenade() {
		if(self.GetBodygroup(2)==1)
			return true;
		
		return false;
	}
	bool HasHeadcrab() {
		if(self.GetBodygroup(1)!=4)
			return true;
		
		return false;
	}
	//=========================================================
	// Check if this Zombie has Mask (HGrunt)
	//=========================================================
	bool HasMask() {
		if(self.GetBodygroup(1)==INFECTED_ID_MASK)
			return true;
		
		return false;
	}

	//=========================================================
	// Schedules Specific to this monster
	//=========================================================
	CHLZE_Zombie()
	{
		@this.m_Schedules = @monster_hlze_zombie_schedules;
	}

	Schedule@ GetScheduleOfType( int Type )
	{
		Schedule@ psched;
		switch(Type)
		{
			case SCHED_VICTORY_DANCE: {
				return slEating;
			}
			case SCHED_RESTORE_HEALTH:{
				self.pev.health = self.pev.max_health;
				
				//Recreate if limping
				if(zombie_IsLimped) {
					//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Healing Limped Zombie....\n");
					//Recreate this NPC
					Setup_Monster_FromLimped();
				}
				return psched;
			}
			case SCHED_GET_UP: {
				//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Getting Up!\n");
				self.ResetSequenceInfo();
				if(deadOnStomach) self.SetSequenceByName("getup_simple");
				else self.SetSequenceByName("getup_headshot");
				return slGetUp;
			}
			case SCHED_THROW_GRENADE: {
				//self.ResetSequenceInfo();
				//self.SetSequenceByName("arm_grenade");
				if(HasGrenade()) return slThrowGrenadeInHand;
				else return slThrowGrenade;
			}
			case SCHED_KAMIKAZE_CHASE: {
				return slKamikazeChase;
			}
			case SCHED_LIMPING: {
				return slLimping;
			}
		}

		return BaseClass.GetScheduleOfType(Type);
	}
	Schedule@ GetSchedule()
	{
		if(zombie_LimpNow) {
			return self.GetScheduleOfType(SCHED_LIMPING);
		}

		if(getUp) {
			return self.GetScheduleOfType(SCHED_GET_UP);
		}

		SetActivity(self.m_Activity);

		switch(self.m_MonsterState) {
			case MONSTERSTATE_IDLE:
			{
				if(Math.RandomLong(0,10)<4) {
					IdleSound();
				}
			}
			case MONSTERSTATE_ALERT:
			{
				if(self.HasConditions(bits_COND_ENEMY_DEAD)
				&& (self.pev.health < self.pev.max_health))
				{
					return self.GetScheduleOfType(SCHED_VICTORY_DANCE);
				}
			}
			case MONSTERSTATE_COMBAT:
			{
				CBaseEntity@ enemyEnt = self.m_hEnemy;
				if(enemyEnt is null)
					return BaseClass.GetSchedule();
				
				if(!enemyEnt.IsAlive())
					return BaseClass.GetSchedule();
				
				//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Grenade Count:"+GrenadeCount+".\n");

				//Check Ammo and Timer
				if(!zombie_IsLimped && GrenadeCount > 0 && NextGrenadeThrow < g_Engine.time) {
					if((self.pev.origin - enemyEnt.pev.origin).Length() < 128.0)
					{
						if(!ThrowGrenade && g_Engine.time > NextGrenadeCheck) {
							NextGrenadeCheck = g_Engine.time + 0.5;
							//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Grenade Throw: 1.\n");
							return self.GetScheduleOfType(SCHED_THROW_GRENADE);
						}
					} else if(HasGrenade() && !ThrowGrenade) {
						//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Grenade Throw: 2.\n");
						return self.GetScheduleOfType(SCHED_CHASE_ENEMY);
					}
				}
			}
		}

		//Pain
		if(m_flNextFlinch < g_Engine.time && !zombie_IsLimped) {
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
			{
				deadOnStomach=true;
				getUp=true;
				break;
			}

			case ACT_DIE_HEADSHOT:
			{
				deadOnStomach=false;
				getUp=true;
				break;
			}

			default: {
				iSequence = self.LookupActivity(NewActivity);
				break;
			}
		}
		if(!zombie_IsLimped) {
			self.m_Activity = NewActivity;
			if(iSequence > -1) {
				if(self.pev.sequence != iSequence || !self.m_fSequenceLoops )
				{
					self.pev.frame = 0;
					self.pev.sequence = iSequence;
					self.ResetSequenceInfo();
				}
			} else {
				self.pev.sequence = 0;
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

		switch (pTask.iTask) {
			case TASK_WALK_PATH:
			case TASK_RUN_PATH:
			{
				//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Run/Walk Task....\n");
				BaseClass.StartTask(pTask);
				break;
			}
			case TASK_DIE: {
				SetActivity(self.m_Activity);

				if(self.m_LastHitGroup != 1
				&& self.m_LastHitGroup != 6
				&& self.m_LastHitGroup != 7
				&& !self.IsAlive()) {
					//Disable monster collision
					self.pev.solid = SOLID_NOT;

					//Headshot!
					//Remove Headcrab
					self.SetBodygroup(1,4);
					//Spawn Headcrab
					Math.MakeVectors(self.pev.angles);
					Vector vecSrc = self.pev.origin + Vector(0,0,30.0);
					CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_headcrab");
					CBaseMonster@ hc = entBase.MyMonsterPointer();
					if(hc !is null) {
						g_EntityFuncs.DispatchSpawn(hc.edict());
						hc.pev.solid = SOLID_SLIDEBOX;
						hc.pev.movetype = MOVETYPE_STEP;
						hc.SetPlayerAlly(self.IsPlayerAlly());
						hc.pev.origin = vecSrc;
						hc.pev.angles.y = self.pev.angles.y;
						hc.pev.velocity = g_Engine.v_up * 100.0 + g_Engine.v_forward * 50.0;
					}
				} else if(self.m_LastHitGroup != 1
					&& (self.m_LastHitGroup == 6 || self.m_LastHitGroup == 7)
					&& !self.IsAlive()
					&& zombie_CanBeLimped
					&& !zombie_IsLimped)
				{
						//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Leg Shot!\n");
						Monster_Limping();
				}

				BaseClass.StartTask(pTask);
				break;
			}
			default: {
				BaseClass.StartTask(pTask);
				break;
			}
		}
	}
	//=========================================================
	// Run Task Function Specific to this monster
	//=========================================================
	void RunTask(Task@ pTask)
	{
		switch (pTask.iTask) {
			case TASK_STAND:
			{
				if(self.m_fSequenceFinished) {
					getUp = false;
					//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Getting Up! - Done!\n");
					self.TaskComplete();
				}
				BaseClass.RunTask(pTask);
				break;
			}
			case TASK_RANGE_ATTACK1:
			{
				//Deploy Grenade
				if(HasGrenade()) {
					self.ResetSequenceInfo();
					self.SetSequenceByName("idle_grenade");
					ThrowGrenade=true;
					self.TaskComplete();
				} else {
					self.TaskFail();
				}
				break;
			}
			case TASK_RANGE_ATTACK2:
			{
				int result = ThrowGrenadeFunction();
				//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"ThrowGrenadeFunction() Result - "+result+"!\n");

				if(result==2) {
					self.ResetSequenceInfo();
					self.SetSequenceByName("idle_grenade");
					if(self.m_fSequenceFinished) {
						self.TaskComplete();
					}
				} else if(result==1) {
					ThrowGrenade = false;
					self.TaskFail();
				} else {
					if(g_Engine.time > NextGrenadeCheck)
						self.TaskFail();
				}

				BaseClass.RunTask(pTask);
				break;
			}
			//Limping
			case TASK_CROUCH:
			{
				zombie_IsLimped=true;
				//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Limping......\n");
				int iSequence1 = self.LookupSequence("diesimple");
				int iSequence2 = self.LookupSequence("limp_leg_idle");
				if(self.pev.sequence != iSequence1 && zombie_LimpNow) {
					zombie_LimpNow=false;
					self.ResetSequenceInfo();
					self.pev.frame = 0;
					self.pev.sequence = iSequence1;
					g_EntityFuncs.SetModel(self,zombieModel_limped);
				}
				
				if(self.m_fSequenceFinished && self.pev.sequence == iSequence1) {
					self.ResetSequenceInfo();
					self.pev.frame = 0;
					self.pev.sequence = iSequence2;
					Setup_Monster_Limped();
					//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Limping - Done!\n");
					self.TaskComplete();
				}
				BaseClass.RunTask(pTask);
				break;
			}
			default: {
				BaseClass.RunTask(pTask);
				break;
			}
		}
	}
	//=========================================================
	// Revive Function Specific to this monster
	//=========================================================
	bool IsRevivable() {
		if(!self.IsAlive()) {
			return HasHeadcrab();
		} else if(self.IsAlive() && zombie_IsLimped) {
			return HasHeadcrab();
		}
		
		return false;
	}
	void EndRevive(float flTimeUntilRevive) {
		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Custom 'Revive()' Function;\n");
		if(self.IsAlive() && zombie_IsLimped) {
			//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Healing Limped Zombie....\n");
			//Recreate this NPC
			Setup_Monster_FromLimped();
			return;
		}

		Setup_Monster();
		self.pev.health = zombieHealth/2;
		self.ClearSchedule();
		getUp=true;
		self.GetSchedule();
		self.ChangeSchedule(self.GetScheduleOfType(SCHED_GET_UP));
	}
}

//=========================================================
// AI Schedules Specific to this monster
//=========================================================
array<ScriptSchedule@>@ monster_hlze_zombie_schedules;

ScriptSchedule slEating( 
	bits_COND_NEW_ENEMY	|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE,
	0,
	"Eating Process"
);

ScriptSchedule slGetUp(
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER,
	"Get Up/Revive");

ScriptSchedule slThrowGrenade(
	bits_COND_NEW_ENEMY,
	bits_SOUND_DANGER, 
	"Throw Grenade");

ScriptSchedule slThrowGrenadeInHand(
	bits_COND_NEW_ENEMY,
	bits_SOUND_DANGER, 
	"Throw Grenade");

ScriptSchedule slKamikazeChase(
	bits_COND_NEW_ENEMY	|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_HEAR_SOUND,
	bits_SOUND_DANGER, 
	"Kamikaze Chase");

ScriptSchedule slLimping(
	bits_COND_NEW_ENEMY,
	0,
	"Limping Process");

enum monsterScheds
{
	SCHED_RESTORE_HEALTH = LAST_COMMON_SCHEDULE + 1,
	SCHED_GET_UP = LAST_COMMON_SCHEDULE + 2,
	SCHED_THROW_GRENADE = LAST_COMMON_SCHEDULE + 3,
	SCHED_KAMIKAZE_CHASE = LAST_COMMON_SCHEDULE + 4,
	SCHED_LIMPING = LAST_COMMON_SCHEDULE + 5,
}

void InitSchedules()
{	
	slEating.AddTask(ScriptTask(TASK_STOP_MOVING));
	slEating.AddTask(ScriptTask(TASK_FACE_ENEMY));
	slEating.AddTask(ScriptTask(TASK_GET_PATH_TO_ENEMY_CORPSE));
	slEating.AddTask(ScriptTask(TASK_WALK_PATH));
	slEating.AddTask(ScriptTask(TASK_WAIT_FOR_MOVEMENT));
	slEating.AddTask(ScriptTask(TASK_FACE_ENEMY));
	slEating.AddTask(ScriptTask(TASK_PLAY_SEQUENCE,float(ACT_VICTORY_DANCE)));
	slEating.AddTask(ScriptTask(TASK_WAIT,5.0));
	slEating.AddTask(ScriptTask(TASK_SET_SCHEDULE,float(SCHED_RESTORE_HEALTH)));
	slEating.AddTask(ScriptTask(TASK_PLAY_SEQUENCE,float(ACT_STAND)));
	slEating.AddTask(ScriptTask(TASK_SET_SCHEDULE,float(SCHED_IDLE_STAND)));

	slGetUp.AddTask(ScriptTask(TASK_STOP_MOVING));
	slGetUp.AddTask(ScriptTask(TASK_STAND));
	slGetUp.AddTask(ScriptTask(TASK_SET_SCHEDULE,float(SCHED_IDLE_STAND)));

	slThrowGrenade.AddTask(ScriptTask(TASK_STOP_MOVING));
	slThrowGrenade.AddTask(ScriptTask(TASK_FACE_ENEMY));
	slThrowGrenade.AddTask(ScriptTask(TASK_PLAY_SEQUENCE,float(ACT_SPECIAL_ATTACK1)));
	slThrowGrenade.AddTask(ScriptTask(TASK_RANGE_ATTACK1));
	slThrowGrenade.AddTask(ScriptTask(TASK_SET_FAIL_SCHEDULE,float(SCHED_IDLE_STAND)));
	slThrowGrenade.AddTask(ScriptTask(TASK_RANGE_ATTACK2));
	slThrowGrenade.AddTask(ScriptTask(TASK_FIND_COVER_FROM_ORIGIN));
	slThrowGrenade.AddTask(ScriptTask(TASK_RUN_PATH));
	slThrowGrenade.AddTask(ScriptTask(TASK_WAIT,2.5));
	slThrowGrenade.AddTask(ScriptTask(TASK_SET_SCHEDULE,float(SCHED_IDLE_STAND)));

	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_STOP_MOVING));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_FACE_ENEMY));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_RANGE_ATTACK1));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_SET_FAIL_SCHEDULE,float(SCHED_IDLE_STAND)));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_RANGE_ATTACK2));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_FIND_COVER_FROM_ORIGIN));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_RUN_PATH));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_WAIT,2.5));
	slThrowGrenadeInHand.AddTask(ScriptTask(TASK_SET_SCHEDULE,float(SCHED_IDLE_STAND)));

	//slKamikazeChase.AddTask(ScriptTask(TASK_GET_PATH_TO_ENEMY));
	//slKamikazeChase.AddTask(ScriptTask(TASK_RUN_PATH));
	slKamikazeChase.AddTask(ScriptTask(TASK_MOVE_TO_TARGET_RANGE,128.0f));
	slKamikazeChase.AddTask(ScriptTask(TASK_SET_SCHEDULE,SCHED_TARGET_FACE));

	slLimping.AddTask(ScriptTask(TASK_STOP_MOVING));
	slLimping.AddTask(ScriptTask(TASK_CROUCH));
	//slLimping.AddTask(ScriptTask(TASK_SET_SCHEDULE,float(SCHED_IDLE_STAND)));
	slLimping.AddTask(ScriptTask(TASK_SET_SCHEDULE,float(SCHED_WAKE_ANGRY)));
	
	array<ScriptSchedule@> scheds = {slEating,slGetUp,slThrowGrenade,slThrowGrenadeInHand,slKamikazeChase,slLimping};
	
	@monster_hlze_zombie_schedules = @scheds;
}

void Register() {
	PrecacheInit();
	InitSchedules();
	g_CustomEntityFuncs.RegisterCustomEntity("HLZE_Zombie::CHLZE_Zombie", "monster_hlze_zombie");
	//g_Log.PrintF("Registered:"+"monster_hlze_zombie"+"\n");
}

void PrecacheInit() {
	g_Game.PrecacheModel(zombieModel);
	g_Game.PrecacheModel(zombieModel_limped);
	PrecacheSounds(pAttackHitSounds);
	PrecacheSounds(pAttackMissSounds);
	PrecacheSounds(pAttackSounds);
	PrecacheSounds(pIdleSounds);
	PrecacheSounds(pAlertSounds);
	PrecacheSounds(pPainSounds);
	PrecacheSounds(pAttackSounds_grunt);
	PrecacheSounds(pIdleSounds_grunt);
	PrecacheSounds(pAlertSounds_grunt);
	PrecacheSounds(pPainSounds_grunt);

	//Gore
	m_iBlood[0] = g_Game.PrecacheModel("sprites/blood.spr");
	m_iBlood[1] = g_Game.PrecacheModel("sprites/bloodspray.spr");
	g_Game.PrecacheGeneric("sprites/blood.spr");
	g_Game.PrecacheGeneric("sprites/bloodspray.spr");
}

} // end of namespace

/*
TODO:
1. Koga Revive() - Zombito da stanue u Kavadarci i da go izede Mitko Janchev.
2. Joke - Drivable Buss that chases and pickups Mitko Janchev and puts him in 'Idrizovo'.
https://baso88.github.io/SC_AngelScript/docs/bits_CAPABILITY.htm
*/