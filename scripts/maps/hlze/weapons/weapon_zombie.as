/*  
* Zombie
*/
#include "..\monsters\monster_infectable"
#include "..\monsters\monster_infected"
#include "..\monsters\monster_infected_dead"
#include "..\entities\multisource"
//Player Animator
#include "..\entities\player_animator"

//Zombie Classes
#include "..\classes\zombie_classes"
//Headcrab Classes
#include "..\classes\headcrab_classes"
//Gene Points
#include "..\classes\gene_points"
//Zombie Ability HUD
#include "zAbilityHud"

array<string>Eatable = {
	"monster_barney_dead",
	"monster_hevsuit_dead",
	"monster_hgrunt_dead",
	"monster_otis_dead",
	"monster_scientist_dead",
	"monster_eatable" // <--- Our Custom Entity
};

array<string>Eatable_Alive = {
	"monster_scientist",
	"monster_barney",
	"monster_hgrunt",
	"monster_human_grunt"
};

enum ZombieAnimations
{
	ZM_IDLE1,
	ZM_DRAW,
	ZM_HOLSTER,
	ZM_ATTACK1,
	ZM_ATTACK1_MISS,
	ZM_ATTACK2_MISS,
	ZM_ATTACK2,
	ZM_ATTACK3_MISS,
	ZM_ATTACK3,
	ZM_IDLE2,
	ZM_IDLE3,
	ZM_EAT,
	ZM_ATTACK1_FAST,
	ZM_ATTACK1_MISS_FAST,
	ZM_ATTACK2_MISS_FAST,
	ZM_ATTACK2_FAST,
	ZM_ATTACK3_MISS_FAST,
	ZM_ATTACK3_FAST,
	ZM_COMMAND_ATTACK,
	ZM_COMMAND_RESSURECT,
	ZM_SHIELD_START,
	ZM_SHIELD_IDLE,
	ZM_SHIELD_END
};

//Breakable Walls
array<string>BreakableZWalls = {
	//targetname
	"dbrkb1",
	"zWall",
	"zWall1",
	"zWall2",
	"zWall3",
	"zWall4",
	"zWall5",
	"zWall6",
	"zWall7",
	"zWall8",
	"zWall9"
};

//Gore
array<int>m_iBlood(2);
int mdl_gib_flesh,mdl_gib_meat;

CBasePlayerWeapon@ Get_Weapon_FromPlayer(CBasePlayer@ pPlayer,string wpnName) {
	//Weapon Holder
	CBasePlayerWeapon@ pWpn = null;
	//Entity Holder
	CBaseEntity@ ent = null;
	int MaxSearches = 33;
	while(MaxSearches > 0) {
		MaxSearches--;
		
		@ent = g_EntityFuncs.FindEntityInSphere(ent, pPlayer.pev.origin, 18.0, wpnName, "classname"); 
		if(ent !is null)
		{
			//Try to Convert it to CBasePlayerWeapon
			CBasePlayerWeapon@ tWpn = cast<CBasePlayerWeapon>(ent);
			if(tWpn !is null) {
				if(tWpn.m_hPlayer.GetEntity() is pPlayer) {
					@pWpn = tWpn;
					//g_PlayerFuncs.ClientPrint(pPlayer,HUD_PRINTTALK,"Found:'"+tWpn.pev.classname+"', Owner:"+tWpn.m_hPlayer.GetEntity().pev.netname+"\n");
					break;
				}
			}
		}
	}
	
	return pWpn;
}

void Zombie_Precache() {
	//Precache Models
	//g_Game.PrecacheModel(V_MODEL_ZOMBIE);
	g_Game.PrecacheModel(P_MODEL);
	g_Game.PrecacheModel(W_MODEL);
	
	//Precache Sprites
	g_Game.PrecacheGeneric( "sprites/weapon_zclaws_01.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_zclaws_02.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws_hud.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_zclaws.txt" );
	
	//Precache Sounds
	g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hit1.wav" );
	g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hit2.wav" );
	g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hitbod1.wav" );
	g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hitbod2.wav" );
	g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hitbod3.wav" );
	g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_miss1.wav" );
	
	g_SoundSystem.PrecacheSound( "bullchicken/bc_bite1.wav" );
	g_SoundSystem.PrecacheSound( "bullchicken/bc_bite2.wav" );
	g_SoundSystem.PrecacheSound( "bullchicken/bc_bite3.wav" );
	
	g_Game.PrecacheGeneric( "sound/hlze/weapons/cbar_hit1.wav" );
	g_Game.PrecacheGeneric( "sound/hlze/weapons/cbar_hit2.wav" );
	g_Game.PrecacheGeneric( "sound/hlze/weapons/cbar_hitbod1.wav" );
	g_Game.PrecacheGeneric( "sound/hlze/weapons/cbar_hitbod2.wav" );
	g_Game.PrecacheGeneric( "sound/hlze/weapons/cbar_hitbod3.wav" );
	g_Game.PrecacheGeneric( "sound/hlze/weapons/cbar_miss1.wav" );
	
	g_SoundSystem.PrecacheSound("hlze/zm_mutate.wav");
	g_Game.PrecacheGeneric("sound/hlze/zm_mutate.wav");
	
	//Gore
	m_iBlood[0] = g_Game.PrecacheModel("sprites/blood.spr");
	m_iBlood[1] = g_Game.PrecacheModel("sprites/bloodspray.spr");
	
	g_Game.PrecacheGeneric("sprites/blood.spr");
	g_Game.PrecacheGeneric("sprites/bloodspray.spr");
	
	mdl_gib_flesh = g_Game.PrecacheModel("models/fleshgibs.mdl");
	mdl_gib_meat = g_Game.PrecacheModel("models/gib_b_gib.mdl");
}

class weapon_zclaws : ScriptBasePlayerWeaponEntity
{
	//private CBasePlayer@ m_pPlayer = null;
	CBasePlayer@ m_pPlayer = null;
	//Player Zombie Class Holder
	Zombie_Class@ ZClass;
	
	TraceResult m_trHit;
	//Fake Attack
	bool b_FakeAttack = false;
	float b_FakeAttackTime = g_Engine.time;
	//Fast Attack
	bool b_FastAttack = false;
	
	float EatingTime = g_Engine.time;
	//Headcrab Regen
	float hc_RegenTime = g_Engine.time;
	float hc_RegenFreq = 2.5;
	
	//Degen our Zombie
	float zm_DegenTime = g_Engine.time;
	float zm_DegenFreq = 8.0;
	float zm_DegenDelay = 25.0;
	
	//Damage
	float zm_Damage = 70.0;
	
	//Ability
	int zm_ability_state = 0;
	float zm_ability_timer = g_Engine.time;
	
	//Darkvision Color
	Vector NVColor(0,0,0);
	
	//Mutation Time
	float zm_MutationTime = g_Engine.time;
	float zm_MutationDelay = 5.0;
	
	//Take Damage Value
	float zm_LastHealth = 0.0; //This is Used for Armor Actually
	float zm_LastTookedDmg = 0.0;

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model(W_MODEL) );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();

		//g_Game.PrecacheModel( V_MODEL_ZOMBIE );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( W_MODEL );

		g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hit1.wav" );
		g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hit2.wav" );
		g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "hlze/weapons/cbar_miss1.wav" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot		= 0;
		info.iPosition		= 6;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		
		@m_pPlayer = pPlayer;
		
		NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict());
			m.WriteString("-duck;");
		m.End();
		
		CheckMutation();
		
		return true;
	}

	void CheckMutation() {
		if(ZClass_Holder[m_pPlayer.entindex()] == HClass_Holder[m_pPlayer.entindex()]) {
			ZClass_Mutate(HClass_Holder[m_pPlayer.entindex()]);
			ZClass_MutationState[m_pPlayer.entindex()] = ZM_MUTATION_NONE;
		} else {
			//Mutation to Another Class
			ZClass_Mutate(HClass_Holder[m_pPlayer.entindex()]);
			zm_MutationTime = g_Engine.time + 5.0;
			ZClass_MutationState[m_pPlayer.entindex()] = ZM_MUTATION_BEGIN;
		}
	}
	
	bool Deploy()
	{
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;
		
		SetThink(ThinkFunction(this.ZombieProcess));
		self.pev.nextthink = g_Engine.time + 0.1;
		
		//Fast Attack
		b_FastAttack = ZClass.FastAttack;
		//Damage
		zm_Damage = ZClass.Damage;
		
		
		m_pPlayer.KeyValue("$i_isZombie",true);
		m_pPlayer.KeyValue("$i_ZombieWeapon",1);
		
		//Get View Model from Zombie Class
		return self.DefaultDeploy( self.GetV_Model(ZClass.VIEW_MODEL),
							self.GetP_Model(P_MODEL), ZM_DRAW, "python", 0, ZClass.VIEW_MODEL_BODY_ID);
	}

	void DarkVision_Init() {
		//Darkvision Color
		NVColor.x = ZClass.DV_Color.x / 8;
		NVColor.y = ZClass.DV_Color.y / 8;
		NVColor.z = ZClass.DV_Color.z / 8;
	}
	
	void Holster( int skiplocal /* = 0 */ )
	{
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;
		self.m_fInReload = false;// cancel any reload in progress.

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = "";

		b_FakeAttack = false;
		
		m_pPlayer.KeyValue("$i_isZombie",false);
		m_pPlayer.KeyValue("$i_ZombieWeapon",0);
		
		SetThink( null );
		
		m_pPlayer.ResetOverriddenPlayerModel(true,false);
	}
	
	void WeaponIdle() {
		self.pev.animtime = g_Engine.time;
		self.pev.framerate = 1.0;
		
		if(self.m_flNextPrimaryAttack > g_Engine.time)
			return;
		
		if(self.m_flNextSecondaryAttack > g_Engine.time)
			return;
		
		if(self.m_flNextTertiaryAttack > g_Engine.time)
			return;
		
		if(self.m_flTimeWeaponIdle > g_Engine.time)
			return;
		
		//Randomize Idle Animations
		int anim_index = 0;
		int random_anim = Math.RandomLong(0,2);
		switch(random_anim) {
			case 0: {
				anim_index = ZM_IDLE1;
				self.m_flTimeWeaponIdle = g_Engine.time + 6.0;
				break;
			}
			case 1: {
				anim_index = ZM_IDLE2;
				self.m_flTimeWeaponIdle = g_Engine.time + 2.4;
				break;
			}
			case 2: {
				anim_index = ZM_IDLE3;
				self.m_flTimeWeaponIdle = g_Engine.time + 1.44;
				break;
			}
		}
		
		self.SendWeaponAnim(anim_index,0,ZClass.VIEW_MODEL_BODY_ID);
	}
	
	void PrimaryAttack()
	{
		Swing();
	}
	
	void Swing()
	{
		g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_WEAPON,"hlze/weapons/cbar_miss1.wav",1,ATTN_NORM,0,94+Math.RandomLong(0,0xF));
		
		int random_sound = Math.RandomLong(0,1);
		switch(random_sound) {
			case 0: {
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hit1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
				break;
			}
			case 1: {
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hit2.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
				break;
			}
		}
		
		int attack_anim_index = 0;
		
		//Randomize Animations
		int random_anim = Math.RandomLong(0,2);
		
		int FastAttack_seqId_Add = 0;
		float FastAttack_seqId_Divide = 1.0;
		if(b_FastAttack) {
			FastAttack_seqId_Add = 9;
			FastAttack_seqId_Divide = 1.8;
		}
		
		switch(random_anim) {
			case 0: {
				attack_anim_index = ZM_ATTACK1_MISS + FastAttack_seqId_Add;
				self.m_flNextPrimaryAttack = g_Engine.time + (1.5/FastAttack_seqId_Divide);
				break;
			}
			case 1: {
				b_FakeAttack = true;
				b_FakeAttackTime = g_Engine.time + (0.85/FastAttack_seqId_Divide);
				
				attack_anim_index = ZM_ATTACK2_MISS + FastAttack_seqId_Add;
				self.m_flNextPrimaryAttack = g_Engine.time + (2.0/FastAttack_seqId_Divide);
				break;
			}
			case 2: {
				attack_anim_index = ZM_ATTACK3_MISS + FastAttack_seqId_Add;
				self.m_flNextPrimaryAttack = g_Engine.time + (1.5/FastAttack_seqId_Divide);
				break;
			}
		}
		TraceResult tr;
		
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;
		
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}
		// hit
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
		
		if( pEntity !is null )
		{
			// AdamR: Custom damage option
			float flDamage = zm_Damage;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End
			
			g_WeaponFuncs.ClearMultiDamage();
			g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev,m_pPlayer.pev);
			pEntity.TraceAttack(m_pPlayer.pev,1.0,g_Engine.v_forward,tr,DMG_NEVERGIB);
			
			if(pEntity.IsAlive()) {
				Math.MakeVectors(m_pPlayer.pev.angles);
				pEntity.pev.velocity = pEntity.pev.velocity + g_Engine.v_forward*(zm_Damage*2)  + g_Engine.v_up*(zm_Damage*2);
			}

			pEntity.TakeDamage(m_pPlayer.pev,m_pPlayer.pev,flDamage,DMG_NEVERGIB);

			//Try to break walls
			if(ZClass.BreakWalls) {
				for(uint w=0;w<BreakableZWalls.length();w++) {
					if(pEntity.pev.classname=="func_breakable" && pEntity.pev.targetname==BreakableZWalls[w]) {
						pEntity.TakeDamage(m_pPlayer.pev,m_pPlayer.pev,1.0,DMG_SLASH);
						pEntity.pev.health = pEntity.pev.health - flDamage;
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						if(pEntity.pev.health <= 10.0) {
							g_EntityFuncs.FireTargets(pEntity.pev.targetname,m_pPlayer,m_pPlayer,USE_ON);
						}
					}
				}
			}
			
			if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
			{
				// play thwack or smack sound
				random_sound = Math.RandomLong(0,2);
				switch(random_sound) {
					case 0: {
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						break;
					}
					case 1: {
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod2.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						break;
					}
					case 2: {
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod3.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						break;
					}
				}
				
				switch(random_anim) {
					case 0: {
						attack_anim_index = ZM_ATTACK1 + FastAttack_seqId_Add;
						self.m_flNextPrimaryAttack = g_Engine.time + (1.0/FastAttack_seqId_Divide);
						break;
					}
					case 1: {
						attack_anim_index = ZM_ATTACK2 + FastAttack_seqId_Add;
						self.m_flNextPrimaryAttack = g_Engine.time + (1.8/FastAttack_seqId_Divide);
						break;
					}
					case 2: {
						attack_anim_index = ZM_ATTACK3 + FastAttack_seqId_Add;
						self.m_flNextPrimaryAttack = g_Engine.time + (1.0/FastAttack_seqId_Divide);
						break;
					}
				}
			}
		}
		
		// player animation
		if(attack_anim_index == ZM_ATTACK1+FastAttack_seqId_Add || attack_anim_index == ZM_ATTACK1_MISS+FastAttack_seqId_Add) {
			self.DefaultDeploy( self.GetV_Model(self.GetV_Model(ZClass.VIEW_MODEL)),
					self.GetP_Model(P_MODEL), attack_anim_index, "shotgun", 0, ZClass.VIEW_MODEL_BODY_ID);
		} else if(attack_anim_index == ZM_ATTACK2+FastAttack_seqId_Add || attack_anim_index == ZM_ATTACK2_MISS+FastAttack_seqId_Add) {
			self.DefaultDeploy( self.GetV_Model(self.GetV_Model(ZClass.VIEW_MODEL)),
					self.GetP_Model(P_MODEL), attack_anim_index, "python", 0, ZClass.VIEW_MODEL_BODY_ID);
		} else if(attack_anim_index == ZM_ATTACK3+FastAttack_seqId_Add || attack_anim_index == ZM_ATTACK3_MISS+FastAttack_seqId_Add) {
			self.DefaultDeploy( self.GetV_Model(self.GetV_Model(ZClass.VIEW_MODEL)),
					self.GetP_Model(P_MODEL), attack_anim_index, "mp5", 0, ZClass.VIEW_MODEL_BODY_ID);
		}
		
		m_pPlayer.SetAnimation(PLAYER_RELOAD);
		
		self.m_flTimeWeaponIdle = g_Engine.time + (2.0/FastAttack_seqId_Divide);
	}
	
	void FakeAttack()
	{
		if(!b_FakeAttack || b_FakeAttackTime > g_Engine.time)
			return;
		
		g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_WEAPON,"hlze/weapons/cbar_miss1.wav", 1,ATTN_NORM,0,94+Math.RandomLong(0,0xF));
		
		TraceResult tr;
		
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;
		
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}
		// hit
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
		
		if( pEntity !is null )
		{
			// AdamR: Custom damage option
			float flDamage = zm_Damage;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End
			
			g_WeaponFuncs.ClearMultiDamage();
			g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev,m_pPlayer.pev);

			pEntity.TraceAttack(m_pPlayer.pev,1.0,g_Engine.v_forward,tr,DMG_NEVERGIB);
			
			if(pEntity.IsAlive()) {
				Math.MakeVectors(m_pPlayer.pev.angles);
				pEntity.pev.velocity = pEntity.pev.velocity + g_Engine.v_forward*(zm_Damage*2);
			}

			pEntity.TakeDamage(m_pPlayer.pev,m_pPlayer.pev,flDamage,DMG_NEVERGIB);

			//Try to break walls
			if(ZClass.BreakWalls) {
				for(uint w=0;w<BreakableZWalls.length();w++) {
					if(pEntity.pev.classname=="func_breakable" && pEntity.pev.targetname==BreakableZWalls[w]) {
						pEntity.TakeDamage(m_pPlayer.pev,m_pPlayer.pev,1.0,DMG_SLASH);
						pEntity.pev.health = pEntity.pev.health - flDamage;
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						if(pEntity.pev.health <= 10.0) {
							g_EntityFuncs.FireTargets(pEntity.pev.targetname,m_pPlayer,m_pPlayer,USE_ON);
						}
					}
				}
			}
			
			if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
			{
				
				// play thwack or smack sound
				int random_sound = Math.RandomLong(0,2);
				switch(random_sound) {
					case 0: {
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						break;
					}
					case 1: {
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod2.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						break;
					}
					case 2: {
						g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"hlze/weapons/cbar_hitbod3.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
						break;
					}
				}
			}
		}
		
		b_FakeAttack = false;
	}

	void SetupPlayerModel() {
		//Force Player Model
		CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
		if(ZClass.PLAYER_MODEL == "null") {
			int infected_type = atoui(KeyValues.GetKeyvalue("$i_infected_type").GetString());
			int infected_maskless = atoui(KeyValues.GetKeyvalue("$i_infected_type_maskless").GetString());
			
			if(infected_type==INFECTED_SCIENTIST) m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_SCIENTIST]);
			else if(infected_type==INFECTED_GUARD) m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_GUARD]);
			else if(infected_type==INFECTED_HGRUNT) {
				if(infected_maskless==1) m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_HGRUNT_MASKLESS]);
				else m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_HGRUNT]);
			} else m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_SCIENTIST]);
		} else m_pPlayer.SetOverriddenPlayerModel(ZClass.PLAYER_MODEL);
	}

	void Setup_ViewOffset() {
		int flags = m_pPlayer.pev.flags;
		int player_old_buttons = m_pPlayer.pev.oldbuttons;
		int player_buttons = m_pPlayer.pev.button;
		int pId = m_pPlayer.entindex();

		if((flags & FL_DUCKING) != 0) {
			m_pPlayer.pev.flDuckTime = 0.0;
			m_pPlayer.pev.view_ofs = ZClass.ZView_Offset / Vector(2,2,2);
		} else m_pPlayer.pev.view_ofs = ZClass.ZView_Offset;
	}

	void LeaveBody_Process() {
		int flags = m_pPlayer.pev.flags;
		int player_old_buttons = m_pPlayer.pev.oldbuttons;
		int player_buttons = m_pPlayer.pev.button;
		int pId = m_pPlayer.entindex();

		if((player_buttons & IN_RELOAD) != 0 || m_pPlayer.pev.armorvalue <= 0.0) {
			LeaveBody();
		}
	}

	void EatingProcess() {
		int flags = m_pPlayer.pev.flags;
		int player_old_buttons = m_pPlayer.pev.oldbuttons;
		int player_buttons = m_pPlayer.pev.button;
		int pId = m_pPlayer.entindex();

		if((player_buttons & IN_USE) != 0) {
			TraceResult tr;
			
			Math.MakeVectors( m_pPlayer.pev.v_angle );
			Vector vecSrc	= m_pPlayer.GetGunPosition();
			Vector vecEnd	= vecSrc + g_Engine.v_forward * 40;
			
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			
			//Get 1 Monster near the looking point
			array<CBaseEntity@>MonstersAround(150);
			g_EntityFuncs.MonstersInSphere(@MonstersAround,tr.vecEndPos,20.0);
			CBaseEntity@ pEntity;

			for(uint i=0;i<MonstersAround.length();i++)
			{
				CBaseEntity@ tempEnt = MonstersAround[i];
				if(tempEnt !is null
				&& tempEnt.Classify() != CLASS_NONE
				&& tempEnt.Classify() != CLASS_MACHINE
				&& tempEnt.BloodColor() != DONT_BLEED)
				{
					bool brkNow = false;
					for(uint i1=0;i1<Eatable.length();i1++)
					{
						if(tempEnt.pev.classname == Eatable[i1])
						{
							@pEntity = MonstersAround[i];
							brkNow = true;
							break;
						}
					}

					if(brkNow) break;
				}
			}
			
			if( pEntity !is null )
			{
				if(pEntity.IsMonster() && !pEntity.IsPlayer() && !pEntity.IsAlive() && self.m_flNextPrimaryAttack < g_Engine.time)
				{
					CBaseMonster@ eatable_monster = pEntity.MyMonsterPointer();
					//g_Log.PrintF("Trying to Eat: "+pEntity.pev.classname+" with Health:"+eatable_monster.pev.health+".\n");
					
					eatable_monster.TraceBleed(0.1, eatable_monster.pev.origin + Vector(0,0,2), tr, DMG_CLUB);
					eatable_monster.TakeDamage(m_pPlayer.pev, m_pPlayer.edict().vars, 0.75, DMG_CLUB);
						
					//m_pPlayer.pev.armortype = m_pPlayer.pev.armortype + 1;
					m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue + 1;
								
					//Regen our Headcrab
					if(m_pPlayer.pev.health < m_pPlayer.pev.max_health)
						m_pPlayer.pev.health = m_pPlayer.pev.health + 1;
								
					//Gain Gene Points
					//GenePts_Holder[pId]++;
					Gene_Points::AddPoints(pId,Math.RandomLong(0,3));
								
					//if(m_pPlayer.pev.weaponanim != ZM_EAT && EatingTime < g_Engine.time) {
					if(EatingTime < g_Engine.time) {
						self.DefaultDeploy( self.GetV_Model(self.GetV_Model(ZClass.VIEW_MODEL)),
									self.GetP_Model(P_MODEL), ZM_EAT, "rpg", 0, ZClass.VIEW_MODEL_BODY_ID);
						m_pPlayer.SetAnimation(PLAYER_RELOAD);
						EatingTime = g_Engine.time + 0.9;
						zm_DegenTime = g_Engine.time + 2.0;
						self.m_flTimeWeaponIdle = g_Engine.time + 3.0;
					}
							
					int random_sound = Math.RandomLong(0,2);
					switch(random_sound) {
						case 0: {
							g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"bullchicken/bc_bite1.wav",1,ATTN_NORM,0,94+Math.RandomLong(0,0xF));
							break;
						}
						case 1: {
							g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"bullchicken/bc_bite2.wav",1,ATTN_NORM,0,94+Math.RandomLong(0,0xF));
							break;
						}
						case 2: {
							g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"bullchicken/bc_bite3.wav",1,ATTN_NORM,0,94+Math.RandomLong(0,0xF));
							break;
						}
					}
							
					self.m_flNextPrimaryAttack = g_Engine.time + 0.8;
					self.m_flNextSecondaryAttack = g_Engine.time + 0.8;
				}
			}
		} else if((player_buttons & IN_USE) != 0 && (player_old_buttons & IN_USE) != 0) {
			//If not pressing 'USE' Key, Reset Eating Timer
			EatingTime = g_Engine.time;
		}
	}

	void Headcrab_Regen() {
		if(hc_RegenTime < g_Engine.time) {
			if(m_pPlayer.pev.health < m_pPlayer.pev.max_health) {
				m_pPlayer.pev.health = m_pPlayer.pev.health + 1;
				hc_RegenTime = g_Engine.time + hc_RegenFreq;
			}
		}
	}

	void Degen_Zombie() {
		if(zm_DegenTime < g_Engine.time) {
			if(m_pPlayer.pev.armorvalue > 0.0) {
				m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue - 1;
				zm_DegenTime = g_Engine.time + zm_DegenFreq;
			}
		}
	}

	void ZombieProcess() {
		self.pev.nextthink = g_Engine.time + 0.1;
		
		//Something like Nightvision
		DarkVision();

		//Zombie Class process
		ZClass_Process();
		
		//Fake Attack
		FakeAttack();
		
		//Force Player Model
		SetupPlayerModel();
		
		//Set View Offset
		Setup_ViewOffset();

		//Eating Process
		EatingProcess();
		
		//Leave Body Process
		LeaveBody_Process();
		
		//Headcrab Regen
		Headcrab_Regen();
		
		//Degen our Zombie over time
		Degen_Zombie();
	}
	
	void LeaveBody() {
		m_pPlayer.KeyValue("$i_isZombie",false);
		
		if(m_pPlayer.pev.armorvalue >= ZClass.Health)
			m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue - ZClass.Health;
		
		float fUp = 0.0;
		array<Vector>hcTriangle = {
			Vector(0.0,0.0,0.0),
			Vector(40.0,0.0,0.0),
			Vector(40.0,40.0,0.0),
			Vector(-40.0,40.0,0.0),
			Vector(-60.0,80.0,0.0)
		};

		//Drop Headcrabs
		CBasePlayerWeapon@ hcWep = Get_Weapon_FromPlayer(m_pPlayer,"weapon_zhcrab");
		if(hcWep !is null)
		{
			int ammo = m_pPlayer.m_rgAmmo(hcWep.m_iPrimaryAmmoType);
			for(uint c=0;c<uint(ammo);c++)
			{
				Math.MakeVectors(m_pPlayer.pev.v_angle);
				//Vector vecSrc	= m_pPlayer.GetGunPosition();
				Vector vecSrc = m_pPlayer.pev.origin + Vector(0,0,fUp);
				fUp+=9.0;
				float throw_amount = 500.0;
				CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_headcrab");
				CBaseMonster@ hc = entBase.MyMonsterPointer();
				if(hc !is null) {
					g_EntityFuncs.DispatchSpawn(hc.edict());
					hc.SetPlayerAllyDirect(true);
					hc.pev.origin = vecSrc + g_Engine.v_forward * hcTriangle[c].y  + g_Engine.v_right * hcTriangle[c].x;
					hc.pev.angles.y = m_pPlayer.pev.v_angle.y;
					hc.pev.velocity = g_Engine.v_forward * throw_amount;
				}
			}
			m_pPlayer.m_rgAmmo(hcWep.m_iPrimaryAmmoType,0);
			hcWep.DestroyItem();
		}

		//Drop Babycrabs
		CBasePlayerWeapon@ bcWep = Get_Weapon_FromPlayer(m_pPlayer,"weapon_zbcrab");
		if(bcWep !is null)
		{
			int ammo = m_pPlayer.m_rgAmmo(bcWep.m_iPrimaryAmmoType);
			for(uint c=0;c<uint(ammo);c++)
			{
				Math.MakeVectors(m_pPlayer.pev.v_angle);
				//Vector vecSrc	= m_pPlayer.GetGunPosition();
				Vector vecSrc = m_pPlayer.pev.origin + Vector(0,0,fUp);
				fUp+=9.0;
				float throw_amount = 500.0;
				CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_babycrab");
				CBaseMonster@ hc = entBase.MyMonsterPointer();
				if(hc !is null) {
					g_EntityFuncs.DispatchSpawn(hc.edict());
					hc.SetPlayerAllyDirect(true);
					hc.pev.origin = vecSrc + g_Engine.v_forward * hcTriangle[c].y  + g_Engine.v_right * hcTriangle[c].x;
					hc.pev.angles.y = m_pPlayer.pev.v_angle.y;
					hc.pev.velocity = g_Engine.v_forward * throw_amount;
				}
			}
			m_pPlayer.m_rgAmmo(bcWep.m_iPrimaryAmmoType,0);
			bcWep.DestroyItem();
		}

		self.DestroyItem();
		m_pPlayer.RemoveAllItems(false);
		m_pPlayer.SetItemPickupTimes(0);
		
		//Leave Body
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_infected_leaved");
		Infected_Leaved@ ent = cast<Infected_Leaved@>(CastToScriptClass(entBase));
		//ent.pev.origin = m_pPlayer.pev.origin;
		
		Vector createOrigin = m_pPlayer.pev.origin - Vector(0.0,0.0,36.0);
		
		int flags = m_pPlayer.pev.flags;
		if((flags & FL_DUCKING) != 0) {
			createOrigin = m_pPlayer.pev.origin - Vector(0.0,0.0,18.0);
		}
		
		Vector createAngles = m_pPlayer.pev.angles;
		
		g_EntityFuncs.DispatchSpawn(ent.self.edict());
		ent.pev.angles.x = 0.0;
		ent.pev.angles.z = 0.0;
		ent.pev.angles.y = createAngles.y;
		
		ent.pev.origin = Unstuck::GetUnstuckPosition(createOrigin,m_pPlayer);
		
		CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
		ent.infected_type = atoui(KeyValues.GetKeyvalue("$i_infected_type").GetString());
		ent.infected_maskless = atoui(KeyValues.GetKeyvalue("$i_infected_type_maskless").GetString());
		
		ent.BigProcess();
		
		if(m_pPlayer.pev.armorvalue >= ZClass.Health)
			m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue - ZClass.Health;
		
		//Relocate Player
		m_pPlayer.KeyValue("$i_hc_jump",true);
		m_pPlayer.pev.origin = ent.pev.origin + Vector(0.0,0.0,36.0);
		m_pPlayer.GiveNamedItem("weapon_hclaws");
	}
	
	void DarkVision() {
		//Toggle
		CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
		int hc_vision = atoui(KeyValues.GetKeyvalue("$i_hc_vision").GetString());
		
		//Get Player's Light Level
		int player_light_level = m_pPlayer.pev.light_level;
		if(player_light_level <= 40 && hc_vision==1) {
			Vector vecSrc = m_pPlayer.EyePosition();
			
			Vector NVColor_temp = ZClass.DV_Color;
			NVColor_temp.x = NVColor_temp.x / 8;
			NVColor_temp.y = NVColor_temp.y / 8;
			NVColor_temp.z = NVColor_temp.z / 8;
			
			NVColor_temp.x -= player_light_level*3;
			NVColor_temp.y -= player_light_level*3;
			
			//Clamp this value between 0 and 255
			//Minimum
			if(NVColor_temp.x < 0) NVColor_temp.x = 0;
			if(NVColor_temp.y < 0) NVColor_temp.y = 0;
			if(NVColor_temp.z < 0) NVColor_temp.z = 0;
			//Maximum
			if(NVColor_temp.x > 255) NVColor_temp.x = 255;
			if(NVColor_temp.y > 255) NVColor_temp.y = 255;
			if(NVColor_temp.z > 255) NVColor_temp.z = 255;
			
			if(zm_ability_state==0 && ZClass_MutationState[m_pPlayer.entindex()]==ZM_MUTATION_NONE)
				g_PlayerFuncs.ScreenFade(m_pPlayer, Vector(255,128,0), 0.1, 0.2, int(NVColor_temp.Length())*2, FFADE::FFADE_IN);
			
			NetworkMessage nvon( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
				nvon.WriteByte( TE_DLIGHT );
				nvon.WriteCoord( vecSrc.x );
				nvon.WriteCoord( vecSrc.y );
				nvon.WriteCoord( vecSrc.z );
				nvon.WriteByte( int(NVColor_temp.Length()) ); // Radius
				
				nvon.WriteByte( int(NVColor_temp.x) ); //R
				nvon.WriteByte( int(NVColor_temp.y) ); //G
				nvon.WriteByte( int(NVColor_temp.z) ); //B
				
				nvon.WriteByte( 2 ); //Life
				nvon.WriteByte( 0 ); //Decay
			nvon.End();
		}
	}
	
	void TertiaryAttack() {
		ZClass_Ability(this,self,m_pPlayer,ZClass);
	}
	
	//Special Zombie Class Stuff
	void ZClass_Mutate(uint zclass_id=0) {
		//----------------------------------------------------------------------
		if(ZClasses::Zombie_Classes.length() < zclass_id)
			zclass_id=0;
		
		@ZClass = ZClasses::Zombie_Classes[zclass_id];
		HClass_Holder[m_pPlayer.entindex()]=zclass_id;
		HClass_Mutation_Holder[m_pPlayer.entindex()]=zclass_id;
		//Set Health from Headcrab
		uint hcId = HClass_Holder[m_pPlayer.entindex()];
		m_pPlayer.pev.max_health = HClasses::Headcrab_Classes[hcId].Health;
		m_pPlayer.pev.health = HClasses::Headcrab_Classes[hcId].Health;
		
		HClass_Mutation_Holder[m_pPlayer.entindex()] = zclass_id;
		
		zm_DegenTime = g_Engine.time + ZClass.DegenDelay;
		zm_DegenFreq = g_Engine.time + ZClass.DegenRate;

		zm_ability_state = 0;
		zm_ability_timer = g_Engine.time;

		b_FastAttack = ZClass.FastAttack;
		//Damage
		zm_Damage = ZClass.Damage;
		
		m_pPlayer.pev.armortype = 500;
		
		if(zclass_id==0) {
			if(m_pPlayer.pev.armorvalue >= ZClass.Health) m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue + ZClass.Health;
			else m_pPlayer.pev.armorvalue = ZClass.Health;
		} else {
			g_PlayerFuncs.ScreenFade(m_pPlayer, ZClass.DV_Color, 0.1, 0.2, 155, FFADE::FFADE_IN);
			m_pPlayer.pev.armorvalue = ZClass.Health;
		}
		
		self.DefaultDeploy( self.GetV_Model(ZClass.VIEW_MODEL),
							self.GetP_Model(P_MODEL), ZM_DRAW, "python", 0, ZClass.VIEW_MODEL_BODY_ID);
		
		if(ZClass_MutationState[m_pPlayer.entindex()] != ZM_MUTATION_NONE) {
			//Do Blood
			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_STREAM,"hlze/zm_mutate.wav",1,ATTN_NORM,0,94+Math.RandomLong(0,0xF));
			//Blood1
			uint blood_count = 15;
			for(uint i=0;i<=blood_count;i++) {
				Vector blood_location = m_pPlayer.pev.origin + Vector(0.0,0.0,1.5*i);
				
				NetworkMessage blood(MSG_BROADCAST,NetworkMessages::SVC_TEMPENTITY);
					blood.WriteByte(TE_BLOODSPRITE);
					blood.WriteCoord(blood_location.x);
					blood.WriteCoord(blood_location.y);
					blood.WriteCoord(blood_location.z);
					
					blood.WriteShort(int(m_iBlood[1]));
					blood.WriteShort(int(m_iBlood[0]));
					
					blood.WriteByte(0xE5);
					blood.WriteByte(Math.RandomLong(10,17));
				blood.End();
			}
			uint gib_count = 10;
			for(uint i=1;i<=gib_count;i++) {
				Vector gib_location = m_pPlayer.pev.origin + Vector(0.0,0.0,-1.5*i);
				Vector gib_velocity = g_Engine.v_forward*i*Math.RandomLong(0,80) + g_Engine.v_up * 5.0*i;
				
				array<int>flesh(2);
				flesh[0] = mdl_gib_flesh;
				flesh[1] = mdl_gib_meat;
				int gibtime = 400; //40 seconds
				
				NetworkMessage gib(MSG_BROADCAST,NetworkMessages::SVC_TEMPENTITY);
					gib.WriteByte(TE_MODEL);
					gib.WriteCoord(gib_location.x);
					gib.WriteCoord(gib_location.y);
					gib.WriteCoord(gib_location.z);
					
					gib.WriteCoord(gib_velocity.x);
					gib.WriteCoord(gib_velocity.y);
					gib.WriteCoord(gib_velocity.z);
					
					gib.WriteAngle(Math.RandomLong(0,360));
					
					gib.WriteShort(flesh[Math.RandomLong(0,1)]);
					
					gib.WriteByte(1); //Bounce
					gib.WriteByte(gibtime); //Life
				gib.End();
				
				NetworkMessage blood(MSG_BROADCAST,NetworkMessages::SVC_TEMPENTITY);
					blood.WriteByte(TE_BLOODSPRITE);
					blood.WriteCoord(gib_location.x+gib_velocity.x);
					blood.WriteCoord(gib_location.y+gib_velocity.y);
					blood.WriteCoord(gib_location.z+gib_velocity.z);
					
					blood.WriteShort(int(m_iBlood[1]));
					blood.WriteShort(int(m_iBlood[0]));
					
					blood.WriteByte(BLOOD_COLOR_RED);
					blood.WriteByte(Math.RandomLong(10,17));
				blood.End();
				
				g_Utility.BloodStream(gib_location,gib_velocity,BLOOD_COLOR_RED,int(i));
				
				TraceResult tr = g_Utility.GetGlobalTrace();
				Vector decal_start = m_pPlayer.pev.origin;
				
				Vector decal_location = m_pPlayer.pev.origin;
				decal_location = decal_location + g_Engine.v_up*(-10.0*i);
				
				g_Utility.TraceLine(decal_start,decal_location,ignore_monsters,m_pPlayer.edict(),tr);
				g_Utility.BloodDecalTrace(tr, BLOOD_COLOR_RED);
			}

			g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,ZClass.MUTATION_MESSAGE+"\n");
			g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,ZClass.MUTATION_DESCRIPTION+"\n");
		}
		ZClass_MutationState[m_pPlayer.entindex()] = ZM_MUTATION_NONE;
		//----------------------------------------------------------------------
		
		SaveLoad_ZClasses::SaveData(m_pPlayer.entindex());
		SaveLoad_HClasses::SaveData(m_pPlayer.entindex());
		
		//Check if any starting abilities are there
		//Go through the array
		for(uint a=0;a<ZClass.Abilities.length();a++) {
			//"Armor Upgrade (+25)"
			if(ZClass.Abilities[a].Name == "Armor Upgrade (+25)") {
				//Check if unlocked and activated!
				if(ZClass.Abilities[a].Unlocked[m_pPlayer.entindex()] && ZClass.Abilities[a].Active[m_pPlayer.entindex()])
				{
					m_pPlayer.pev.armorvalue += 25.0;
				}
			}
			//"Armor Upgrade (+50)"
			if(ZClass.Abilities[a].Name == "Armor Upgrade (+50)") {
				//Check if unlocked and activated!
				if(ZClass.Abilities[a].Unlocked[m_pPlayer.entindex()] && ZClass.Abilities[a].Active[m_pPlayer.entindex()])
				{
					m_pPlayer.pev.armorvalue += 50.0;
				}
			}
		}

		//Initialize our Last Health
		zm_LastHealth = m_pPlayer.pev.armorvalue;
	}
	
	void ZClass_Process() {
		//----------------------------------------------------------------------
		int flags = m_pPlayer.pev.flags;
		int player_old_buttons = m_pPlayer.pev.oldbuttons;
		int player_buttons = m_pPlayer.pev.button;
		int pId = m_pPlayer.entindex();
		//Mutation
		Zombie_Class@ pZClass = Get_ZombieClass_FromPlayer(m_pPlayer);
		if(zm_MutationTime < g_Engine.time) {
			if(ZClass_MutationState[pId]==ZM_MUTATION_BEGIN) {
				if(ZClass is pZClass) {
					ZClass_MutationState[pId] = ZM_MUTATION_NONE;
					return;
				}
				//g_PlayerFuncs.ScreenFade(m_pPlayer, pZClass.DV_Color, zm_MutationDelay, zm_MutationDelay, 155, FFADE::FFADE_IN);
				g_PlayerFuncs.ScreenShake(m_pPlayer.pev.origin, zm_MutationDelay*50, zm_MutationDelay*0.3, zm_MutationDelay*2, 1.0);
				
				//Hud
				HUDTextParams textParams;
				
				textParams.x = 0.4;
				textParams.y = 0.4;
				textParams.effect = 0;
				textParams.r1 = 255;
				textParams.g1 = 0;
				textParams.b1 = 0;
				textParams.a1 = 0;
				textParams.r2 = 250;
				textParams.g2 = 250;
				textParams.b2 = 250;
				textParams.a2 = 0;
				textParams.fadeinTime = 2.0;
				textParams.fadeoutTime = 1.0;
				textParams.holdTime = 2.0;
				textParams.fxTime = 0.0;
				textParams.channel = 1;
				
				g_PlayerFuncs.HudMessage(m_pPlayer,textParams,"Mutating in "+int(zm_MutationDelay)+" second(s)!\n");
				//Mutating In...
				zm_MutationTime = g_Engine.time + (zm_MutationDelay/100)*80;
				ZClass_MutationState[pId] = ZM_MUTATION_MIDLE;
			} else if(ZClass_MutationState[pId]==ZM_MUTATION_MIDLE) {
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_AUTO,"hlze/player/fz_scream1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
				zm_MutationTime = g_Engine.time + (zm_MutationDelay/100)*20;
				ZClass_MutationState[pId] = ZM_MUTATION_END;
			} else if(ZClass_MutationState[pId]==ZM_MUTATION_END) {
				int pid = m_pPlayer.entindex();
				ZClass_Mutate(ZClass_Holder[pid]);
				ZClass_MutationState[pId] = ZM_MUTATION_NONE;
			}
		} else {
			if(ZClass_MutationState[pId]==ZM_MUTATION_MIDLE || ZClass_MutationState[pId]==ZM_MUTATION_END) {
				g_PlayerFuncs.ScreenFade(m_pPlayer, pZClass.DV_Color, 0.1, 0.2, 155, FFADE::FFADE_IN);
			}
		}
		//----------------------------------------------------------------------
		ZClass_Process_Global(m_pPlayer,ZClass,zm_ability_state);
		//----------------------------------------------------------------------
		
		//Check if there are any abilities
		if(ZClass.Abilities.length() <= 0)
			return;
		
		//Check if unlocked and activated!
		if(!ZClass.Abilities[0].Unlocked[pId] || !ZClass.Abilities[0].Active[pId])
			return;
		
		//Ability Process
		if(ZClass.Abilities[0].Name == "Acid Throw") {
			if(self.m_flNextSecondaryAttack < g_Engine.time) {
				if(zm_ability_state==1) {
					self.SendWeaponAnim(ZM_DRAW,0,ZClass.VIEW_MODEL_BODY_ID);
					self.m_flNextTertiaryAttack = g_Engine.time + 0.6;
					self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
					self.m_flTimeWeaponIdle = g_Engine.time + 10.0;
					zm_ability_state++;
					return;
				} else if(zm_ability_state==2) {
					ZClass_Ability_OFF(this,self,m_pPlayer,ZClass);
					self.m_flNextSecondaryAttack = g_Engine.time + 1.2;
					return;
				} else if(zm_ability_state==3) {
					self.DefaultDeploy( self.GetV_Model(ZClass.VIEW_MODEL),
								self.GetP_Model(P_MODEL), ZM_IDLE1, "python", 0, ZClass.VIEW_MODEL_BODY_ID);
					zm_ability_state=0;
					self.m_flNextSecondaryAttack = g_Engine.time + 1.5;
					self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
					return;
				}
			}
		}
	}
}

void Register_Zombie()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zclaws", "weapon_zclaws" );
	g_ItemRegistry.RegisterWeapon( "weapon_zclaws", "");
}

void ZClass_Ability(weapon_zclaws@ zclaw, CBasePlayerWeapon@ z_wpn,CBasePlayer@ m_pPlayer, Zombie_Class@ ZClass) {
	int pId = m_pPlayer.entindex();
	//----------------------------------------------------------------------
	//Check if there are any abilities
	if(ZClass.Abilities.length() <= 0)
		return;
	
	//Check if unlocked and activated!
	if(!ZClass.Abilities[0].Unlocked[pId] || !ZClass.Abilities[0].Active[pId])
		return;
	
	//Holding...
	if(ZClass.Abilities[0].Name == "Acid Throw") {
		float throw_amount = g_Engine.time - zclaw.zm_ability_timer;

		if(zclaw.zm_ability_state==2 && throw_amount < 5.0) {
			z_wpn.m_flNextSecondaryAttack = g_Engine.time + 0.1;
		}
	}

	if(z_wpn.m_flNextTertiaryAttack > g_Engine.time)
		return;

	//All toggleable Primary Abilities
	//Check ability state
	if(zclaw.zm_ability_state==0) {
		ZClass_Ability_ON(zclaw,z_wpn,m_pPlayer,ZClass);
	} else {
		if(ZClass.Abilities[0].Name == "Frenzy Mode") {
			ZClass_Ability_OFF(zclaw,z_wpn,m_pPlayer,ZClass);
		}
	}
	//----------------------------------------------------------------------
}

void ZClass_Ability_ON(weapon_zclaws@ zclaw,CBasePlayerWeapon@ z_wpn,CBasePlayer@ m_pPlayer,Zombie_Class@ ZClass) {
	int pId = m_pPlayer.entindex();
	//----------------------------------------------------------------------
	//Check if there are any abilities
	if(ZClass.Abilities.length() <= 0)
		return;
	
	//Check if unlocked and activated!
	if(!ZClass.Abilities[0].Unlocked[pId] || !ZClass.Abilities[0].Active[pId])
		return;
	
	//"Frenzy Mode" is toggleable and must be primary
	if(ZClass.Abilities[0].Name == "Frenzy Mode") {
		g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,ZClass.Abilities[0].Name+" Activated!\n");
		
		zclaw.b_FastAttack = true;
		zclaw.zm_Damage = ZClass.Damage*3;
		
		zclaw.zm_DegenTime = g_Engine.time;
		zclaw.zm_DegenFreq = ZClass.DegenRate/6.0;
		
		g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_AUTO,"hlze/player/fz_frenzy1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
		
		z_wpn.m_flNextTertiaryAttack = g_Engine.time + ZClass.Ability_ToggleDelay;
		zclaw.zm_ability_state=1;
	} else if(ZClass.Abilities[0].Name == "Acid Throw") {
		//g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,ZClass.Abilities[0].Name+" - Draw!\n");
		z_wpn.DefaultDeploy(z_wpn.GetV_Model(ZClass.VIEW_MODEL),
							z_wpn.GetP_Model(P_MODEL), ZM_HOLSTER,"sniper",0,ZClass.VIEW_MODEL_BODY_ID);
		m_pPlayer.SetAnimation(PLAYER_DEPLOY);
		
		z_wpn.m_flNextSecondaryAttack = g_Engine.time + 0.7;
		z_wpn.m_flNextTertiaryAttack = g_Engine.time + 0.8;
		z_wpn.m_flTimeWeaponIdle = g_Engine.time + 3.0;
		
		zclaw.zm_ability_timer = g_Engine.time;
		zclaw.zm_ability_state = 1;
	} else if(ZClass.Abilities[0].Name == "Move Command") {
		/*
		z_wpn.DefaultDeploy(z_wpn.GetV_Model(ZClass.VIEW_MODEL),
							z_wpn.GetP_Model(P_MODEL), ZM_COMMAND_ATTACK,"shotgun",0,ZClass.VIEW_MODEL_BODY_ID);
		m_pPlayer.SetAnimation(PLAYER_RELOAD);
		*/
		z_wpn.SendWeaponAnim(ZM_COMMAND_ATTACK,0,ZClass.VIEW_MODEL_BODY_ID);
		
		PlayerAnimator::Force_Animation(m_pPlayer,116,1.0);

		z_wpn.m_flNextSecondaryAttack = g_Engine.time + 3.4;
		z_wpn.m_flNextTertiaryAttack = g_Engine.time + 3.4;
		z_wpn.m_flTimeWeaponIdle = g_Engine.time + 3.4;
		
		zclaw.zm_ability_timer = g_Engine.time + 3.4;

		//g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,ZClass.Abilities[0].Name+" - Draw!\n");
		//Find any monster at our looking position
		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 3000;
		
		g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

		//Find Path
		Vector EndPoint = tr.vecEndPos;
		
		//Get All Monsters near the Player
		array<CBaseEntity@>MonstersAround(50);
		g_EntityFuncs.MonstersInSphere(@MonstersAround,m_pPlayer.pev.origin,500.0);

		for(uint i=0;i<MonstersAround.length();i++)
		{
			CBaseMonster@ pMonster;
			if(MonstersAround[i] !is null)
				@pMonster = MonstersAround[i].MyMonsterPointer();

			if(pMonster !is null && pMonster.IsAlive() && !pMonster.IsPlayer()
				&& pMonster.IRelationship(m_pPlayer) == R_AL)
			{
				//pMonster.StopPlayerFollowing(false,false);
				pMonster.FGetNodeRoute(EndPoint);

				pMonster.m_vecMoveGoal = EndPoint;
				pMonster.m_movementGoal = bits_MF_TO_LOCATION;
				pMonster.SetActivity(ACT_RUN);
				pMonster.SetGaitActivity(ACT_RUN);
				pMonster.m_movementActivity = ACT_RUN;
			}
		}
		zclaw.zm_ability_state = 0;
	}
	//----------------------------------------------------------------------
}

void ZClass_Ability_OFF(weapon_zclaws@ zclaw,CBasePlayerWeapon@ z_wpn,CBasePlayer@ m_pPlayer,Zombie_Class@ ZClass) {
	int pId = m_pPlayer.entindex();
	//----------------------------------------------------------------------
	//Check if there are any abilities
	if(ZClass.Abilities.length() <= 0)
		return;
	
	//Check if unlocked and activated!
	if(!ZClass.Abilities[0].Unlocked[pId] || !ZClass.Abilities[0].Active[pId])
		return;
	
	//"Frenzy Mode" is toggleable and must be primary
	if(ZClass.Abilities[0].Name == "Frenzy Mode") {
		g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,ZClass.Abilities[0].Name+" Deactivated!\n");
		
		zclaw.b_FastAttack = false;
		zclaw.zm_Damage = ZClass.Damage;
		
		zclaw.zm_DegenTime = g_Engine.time;
		zclaw.zm_DegenFreq = ZClass.DegenRate;
		
		g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_AUTO,"hlze/player/fz_scream1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
		z_wpn.m_flNextTertiaryAttack = g_Engine.time + ZClass.Ability_ToggleDelay;
		zclaw.zm_ability_state=0;
	} else if(ZClass.Abilities[0].Name == "Acid Throw") {
		//Calculate Holding
		float throw_amount = g_Engine.time - zclaw.zm_ability_timer;
		
		//Test
		Math.MakeVectors(m_pPlayer.pev.v_angle);
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		throw_amount *= 150.0;
		/*
		g_EntityFuncs.ShootContact(m_pPlayer.pev,
								vecSrc + g_Engine.v_forward * 16 + g_Engine.v_right * 6,
								g_Engine.v_forward * throw_amount);
		*/
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("acid_throw");
		AcidThrow@ acidProjectile = cast<AcidThrow@>(CastToScriptClass(entBase));
		g_EntityFuncs.DispatchSpawn(acidProjectile.self.edict());
		@acidProjectile.pev.owner = m_pPlayer.edict();
		acidProjectile.pev.origin = vecSrc + g_Engine.v_forward * 16 + g_Engine.v_right * 6;
		acidProjectile.pev.velocity = g_Engine.v_forward * throw_amount * 2.0;
		acidProjectile.pev.angles = m_pPlayer.pev.v_angle;

		//----
		
		g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTCENTER,ZClass.Abilities[0].Name+" - Distance:["+throw_amount+"]\n");
		
		z_wpn.DefaultDeploy(z_wpn.GetV_Model(ZClass.VIEW_MODEL),
							z_wpn.GetP_Model(P_MODEL), ZM_ATTACK1_MISS, "sniper", 0, ZClass.VIEW_MODEL_BODY_ID);
		m_pPlayer.SetAnimation(PLAYER_RELOAD);
		
		z_wpn.m_flTimeWeaponIdle = g_Engine.time + 1.5;
		z_wpn.m_flNextSecondaryAttack = g_Engine.time + 1.5;
		z_wpn.m_flNextTertiaryAttack = g_Engine.time + 3.0; //Cooldown
		
		zclaw.zm_ability_state=3;
	}
	//----------------------------------------------------------------------
}

//Use this only for toggleable ability
void ZClass_Process_Global(CBasePlayer@ m_pPlayer,Zombie_Class@ ZClass,int zm_ability_state) {
	CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
	int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
	if(isZombie!=1)
		return;
	//----------------------------------------------------------------------
	int flags = m_pPlayer.pev.flags;
	int player_old_buttons = m_pPlayer.pev.oldbuttons;
	int player_buttons = m_pPlayer.pev.button;
	bool crouching = ((flags & FL_DUCKING) != 0);
	int pId = m_pPlayer.entindex();
	
	int ZClass_Speed = ZClass.Get_MaxSpeed(crouching);
	
	if(ZClass.Name == "Default") { //"Default"
		if(zm_ability_state==0) {
			//Limit Zombie Speed
			m_pPlayer.SetMaxSpeed(ZClass_Speed);
		}
	} else if(ZClass.Name == "Rusher") { //"Rusher"
		//Toggleable ability
		if(zm_ability_state==1) {
			m_pPlayer.SetMaxSpeed(ZClass_Speed);
			g_PlayerFuncs.ScreenFade(m_pPlayer, Vector(255,0,0), 0.1, 0.2, 100, FFADE::FFADE_IN);
		} else {
			m_pPlayer.SetMaxSpeed(ZClass_Speed/2);
		}
	} else {
		m_pPlayer.SetMaxSpeed(ZClass_Speed);
	}
	//----------------------------------------------------------------------
}

HookReturnCode ZClass_Think(CBasePlayer@ pPlayer, uint& out dummy )
{
	int index = pPlayer.entindex();
	
	CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_zclaws");
	weapon_zclaws@ zclaws = cast<weapon_zclaws@>(CastToScriptClass(pWpn));
	
	if(zclaws !is null) {
		ZClass_Process_PlayerProcess(zclaws,pWpn,pPlayer,zclaws.ZClass);
		ZClass_Process_PlayerProcess_Off(zclaws,pWpn,pPlayer,zclaws.ZClass);
	}
	
	return HOOK_CONTINUE;
}

void ZClass_Process_PlayerProcess(weapon_zclaws@ zclaw,CBasePlayerWeapon@ z_wpn,CBasePlayer@ m_pPlayer,Zombie_Class@ ZClass) {
	//g_Log.PrintF("Player: "+m_pPlayer.pev.netname+" is with AnimExt:'"+m_pPlayer.get_m_szAnimExtension()+"'\n");
	
	CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
	int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
	int ZWeaponId = atoui(KeyValues.GetKeyvalue("$i_ZombieWeapon").GetString());
	//----------------------------------------------------------------------
	int flags = m_pPlayer.pev.flags;
	int old_buttons = m_pPlayer.pev.oldbuttons;
	int button = m_pPlayer.pev.button;
	int pId = m_pPlayer.entindex();
	
	//Pickup Headcrabs
	if(isZombie != 0 && (button & IN_USE) != 0 && (old_buttons & IN_USE) == 0 && ZClass.UseHeadcrabs)
	{
		TraceResult tr;
		
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 50;
		
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);
		
		// hit
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

		if(pEntity !is null && pEntity.pev.classname == "monster_headcrab" && pEntity.IsAlive())
		{
			CBasePlayerWeapon@ hcWep = Get_Weapon_FromPlayer(m_pPlayer,"weapon_zhcrab");
			if(hcWep !is null)
			{
				if(m_pPlayer.GiveAmmo((m_pPlayer.HasNamedPlayerItem("weapon_zhcrab").GetWeaponPtr().m_iDefaultAmmo),"ammo_headcrabs",m_pPlayer.GetMaxAmmo("ammo_headcrabs"))!=-1) {
					m_pPlayer.GiveNamedItem("ammo_headcrabs");
					g_EntityFuncs.Remove(pEntity);
				}
			} else {
				m_pPlayer.GiveNamedItem("weapon_zhcrab");
				g_EntityFuncs.Remove(pEntity);
			}
		}
	}

	//Make sure Player is not Mutating
	if(ZClass_MutationState[pId]!=ZM_MUTATION_NONE)
		return;

	//Go through the array
	for(uint a=0;a<ZClass.Abilities.length();a++)
	{
		//Check if unlocked and activated!
		if(ZClass.Abilities[a].Unlocked[pId] && ZClass.Abilities[a].Active[pId] && (isZombie==1 && ZWeaponId!=0))
		{
			//"Long Jump"
			if(ZClass.Abilities[a].Name == "Long Jump")
			{
				if(ZClass.Ability_Timer[pId] < g_Engine.time) {
					if((flags & FL_ONGROUND) != 0 &&(button & IN_DUCK) != 0 && (button & IN_JUMP) != 0
						&& (old_buttons & IN_JUMP) == 0) {
						
						int sRand = Math.RandomLong(0,1);
						switch(sRand) {
							case 0: {
								g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_AUTO,"hlze/player/fz_scream1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
								break;
							}
							case 1: {
								g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_AUTO,"hlze/player/leap1.wav",1,ATTN_NORM,0,ZClass.VoicePitch);
								break;
							}
						}
						//g_PlayerFuncs.ScreenFade(m_pPlayer, ZClass.DV_Color, 1.0, 1.0, 100, FFADE::FFADE_IN);
						g_PlayerFuncs.ScreenShake(m_pPlayer.pev.origin, 3.5, 0.5, 1.5, 2.0);
						
						Vector LongJump(0.0,0.0,200.0);
						Math.MakeVectors(m_pPlayer.pev.angles);
						LongJump = LongJump + g_Engine.v_forward * 600.0;
						
						m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + LongJump;
						m_pPlayer.pev.punchangle.x = m_pPlayer.pev.punchangle.x - 15.0;
						
						ZClass.Ability_Timer[pId] = g_Engine.time + ZClass.Ability_ToggleDelay;
						PlayerAnimator::Schedule_Animation(m_pPlayer,PLAYER_JUMP,0.01);
					}
				}
			} else if(ZClass.Abilities[a].Name == "Shield [Secondary Attack to Toggle]")
			{
				if((flags & FL_ONGROUND) != 0
				&& (button & IN_ATTACK2) != 0 && (old_buttons & IN_ATTACK2) == 0) {
					if(ZClass.Ability_Timer[pId] < g_Engine.time && z_wpn.m_flNextSecondaryAttack < g_Engine.time) {
						g_PlayerFuncs.ScreenShake(m_pPlayer.pev.origin, 3.5, 0.5, 1.5, 2.0);
						ZClass.Ability_Timer[pId] = g_Engine.time + ZClass.Ability_ToggleDelay;
						//Toggle
						if(zclaw.zm_ability_state == 4) {
							zclaw.zm_ability_state = 0;
							zclaw.zm_LastHealth = m_pPlayer.pev.armorvalue;
							z_wpn.SendWeaponAnim(ZM_SHIELD_END,0,ZClass.VIEW_MODEL_BODY_ID);
							m_pPlayer.set_m_szAnimExtension("python");
							PlayerAnimator::Force_Animation(m_pPlayer,111,0.8);
							z_wpn.m_flTimeWeaponIdle = g_Engine.time + 1.2;
							z_wpn.m_flNextPrimaryAttack = g_Engine.time + 1.2;
							z_wpn.m_flNextSecondaryAttack = g_Engine.time + 1.2;
							z_wpn.m_flNextTertiaryAttack = g_Engine.time + 1.2;

							m_pPlayer.pev.rendermode = kRenderNormal;
							m_pPlayer.pev.renderfx = kRenderFxNone;
						} else {
							zclaw.zm_ability_state = 4;
							zclaw.zm_LastHealth = m_pPlayer.pev.armorvalue;
							//z_wpn.SendWeaponAnim(ZM_SHIELD_START,0,ZClass.VIEW_MODEL_BODY_ID);
							z_wpn.DefaultDeploy(z_wpn.GetV_Model(ZClass.VIEW_MODEL),
								z_wpn.GetP_Model(P_MODEL), ZM_SHIELD_START, "saw", 0, ZClass.VIEW_MODEL_BODY_ID);
							PlayerAnimator::Force_Animation(m_pPlayer,169,0.7);
							z_wpn.m_flTimeWeaponIdle = g_Engine.time + 1.2;
							z_wpn.m_flNextPrimaryAttack = g_Engine.time + 1.2;
							z_wpn.m_flNextSecondaryAttack = g_Engine.time + 1.2;
							z_wpn.m_flNextTertiaryAttack = g_Engine.time + 1.2;
						}
					}
				} else {
					//Process
					if(zclaw.zm_ability_state == 4)
					{
						//Prevent Idling/Attacking
						z_wpn.m_flTimeWeaponIdle = g_Engine.time + 0.5;
						z_wpn.m_flNextPrimaryAttack = g_Engine.time + 0.5;
						//z_wpn.m_flNextSecondaryAttack = g_Engine.time + 1.0;
						z_wpn.m_flNextTertiaryAttack = g_Engine.time + 0.5;

						m_pPlayer.pev.rendermode = kRenderNormal;
						m_pPlayer.pev.renderfx = kRenderFxGlowShell;
						m_pPlayer.pev.rendercolor = Vector(25,25,25);
						m_pPlayer.pev.renderamt = 10;

						if(zclaw.zm_LastTookedDmg > 0.0) {
							if(m_pPlayer.pev.armorvalue > 0.0 && m_pPlayer.pev.armorvalue <= zclaw.zm_LastHealth) {
								float resistance = zclaw.zm_LastTookedDmg/3.0;
								m_pPlayer.pev.armorvalue += (m_pPlayer.pev.armorvalue+resistance <= zclaw.zm_LastHealth)?resistance:zclaw.zm_LastHealth-m_pPlayer.pev.armorvalue;
							}

							//Reset Damage
							zclaw.zm_LastHealth = m_pPlayer.pev.armorvalue;
							zclaw.zm_LastTookedDmg = 0.0;
						}
					}
				}
			} else if(ZClass.Abilities[a].Name == "Mass Ressurect - [Secondary Attack to Use]")
			{
				if((flags & FL_ONGROUND) != 0
				&& (button & IN_ATTACK2) != 0 && (old_buttons & IN_ATTACK2) == 0) {
					if(ZClass.Ability_Timer[pId] < g_Engine.time && z_wpn.m_flNextSecondaryAttack < g_Engine.time) {
						ZClass.Ability_Timer[pId] = g_Engine.time + ZClass.Ability_ToggleDelay;
						//Start
						zclaw.zm_ability_state = 6;
						
						z_wpn.DefaultDeploy(z_wpn.GetV_Model(ZClass.VIEW_MODEL),
							z_wpn.GetP_Model(P_MODEL), ZM_COMMAND_RESSURECT, "sniper", 0, ZClass.VIEW_MODEL_BODY_ID);
						
						PlayerAnimator::Force_Animation(m_pPlayer, 162, 0.7);

						ZClass.Ability_Timer[pId] = g_Engine.time + 15.0;
						z_wpn.m_flTimeWeaponIdle = g_Engine.time + 3.1;
						z_wpn.m_flNextPrimaryAttack = g_Engine.time + 3.1;
						z_wpn.m_flNextTertiaryAttack = g_Engine.time + 2.0;
						//Ability Hud
						zAbilityHud::ShowMassRessurection(m_pPlayer,15.0);

						m_pPlayer.m_flEffectSpeed = 0.0;
						m_pPlayer.m_flFallVelocity = 100.0;
						m_pPlayer.m_flEffectGravity = 100.0;

						//Find any monster at our looking position
						TraceResult tr;
						Math.MakeVectors(m_pPlayer.pev.v_angle);
						Vector vecSrc = m_pPlayer.GetGunPosition();
						Vector vecEnd = vecSrc + g_Engine.v_forward * 80;
						
						g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);
						
						m_pPlayer.pev.vuser1 = tr.vecEndPos;
					}
				}


				if(z_wpn.m_flNextTertiaryAttack < g_Engine.time
					&& zclaw.zm_ability_state == 6)
				{
					zclaw.zm_ability_state = 7;

					z_wpn.m_flNextTertiaryAttack = g_Engine.time + 1.1;

					//Do Ressurect
					g_PlayerFuncs.ScreenShake(m_pPlayer.pev.origin, 3.5, 0.5, 1.5, 2.0);
					
					//Get 1 Monster near the looking point
					array<CBaseEntity@>MonstersAround(800);
					g_EntityFuncs.MonstersInSphere(@MonstersAround,m_pPlayer.pev.vuser1,50.0);

					for(uint i=0;i<MonstersAround.length();i++)
					{
						CBaseMonster@ pMonster;
						if(MonstersAround[i] !is null) {
							@pMonster = MonstersAround[i].MyMonsterPointer();

							//if(pMonster !is null && !pMonster.IsAlive()
							if(pMonster !is null
							&& pMonster.IRelationship(m_pPlayer) == R_AL
							&& pMonster.IsRevivable())
							{
								//Give weapons if this is player
								if(pMonster.IsPlayer()) {
									pMonster.Revive();
									//Convert it to CBasePlayer
									CBasePlayer@ revPlayer = cast<CBasePlayer@>(pMonster);
									int rev_pId = revPlayer.entindex();
									if(revPlayer.HasNamedPlayerItem("weapon_zclaws") !is null) {
										SaveLoad::Give_HLZE_Weapons(rev_pId,0);
									} else {
										SaveLoad::Give_HLZE_Weapons(rev_pId);
									}
								} else {
									pMonster.BeginRevive(0.01);
									pMonster.EndRevive(0.5);
								}
								break;
							}
						}
					}
					//......
				} else if(z_wpn.m_flNextTertiaryAttack < g_Engine.time
					&& zclaw.zm_ability_state == 7)
				{
					zclaw.zm_ability_state = 0;
					m_pPlayer.ResetEffects();
				}
			}
		}
		if(ZClass.Abilities[a].Unlocked[pId] && ZClass.Abilities[a].Active[pId] && isZombie==1) {
			if(ZClass.Abilities[a].Name == "Zombie Orders")
			{
				if((button & IN_USE) != 0 && (old_buttons & IN_USE) == 0)
				{
					TraceResult tr;
		
					Math.MakeVectors( m_pPlayer.pev.v_angle );
					Vector vecSrc	= m_pPlayer.GetGunPosition();
					Vector vecEnd	= vecSrc + g_Engine.v_forward * 500;
					
					g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);
					
					//Get 1 Monster near the looking point
					array<CBaseEntity@>MonstersAround(50);
					g_EntityFuncs.MonstersInSphere(@MonstersAround,tr.vecEndPos,50.0);

					for(uint i=0;i<MonstersAround.length();i++)
					{
						CBaseMonster@ pMonster;
						if(MonstersAround[i] !is null)
						{
							@pMonster = MonstersAround[i].MyMonsterPointer();

							if(pMonster.IsAlive() && pMonster.pev.classname=="monster_hlze_zombie") {
								if(!pMonster.IsPlayerFollowing()) {
									pMonster.StartPlayerFollowing(m_pPlayer,false);
									g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTCENTER,ZClass.Abilities[a].Name+" - Now Following!\n");
								} else {
									pMonster.StopPlayerFollowing(false,false);
									g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTCENTER,ZClass.Abilities[a].Name+" - Now Stand Still!\n");
								}
							}
						}
					}
				}
			}
		}
		if(ZClass.Abilities[a].Unlocked[pId] && !ZClass.Abilities[a].Active[pId] && isZombie==1)
		{
			if(ZClass.Abilities[a].Name == "Shield [Secondary Attack to Toggle]") {
				if(ZClass.Ability_Timer[pId] < g_Engine.time) {
					//Toggle
					if(zclaw.zm_ability_state == 4) {
						g_PlayerFuncs.ScreenShake(m_pPlayer.pev.origin, 3.5, 0.5, 1.5, 2.0);
						ZClass.Ability_Timer[pId] = g_Engine.time + ZClass.Ability_ToggleDelay;
						
						zclaw.zm_ability_state = 0;
						z_wpn.SendWeaponAnim(ZM_SHIELD_END,0,ZClass.VIEW_MODEL_BODY_ID);
						m_pPlayer.set_m_szAnimExtension("python");
						PlayerAnimator::Force_Animation(m_pPlayer,111,0.8);
						z_wpn.m_flTimeWeaponIdle = g_Engine.time + 1.2;
						z_wpn.m_flNextPrimaryAttack = g_Engine.time + 1.2;
						z_wpn.m_flNextSecondaryAttack = g_Engine.time + 1.2;
						z_wpn.m_flNextTertiaryAttack = g_Engine.time + 1.2;

						m_pPlayer.pev.rendermode = kRenderNormal;
						m_pPlayer.pev.renderfx = kRenderFxNone;
						m_pPlayer.pev.renderamt = 255;
					}
				}
			} else if(ZClass.Abilities[a].Name == "Mass Ressurect - [Secondary Attack to Use]")
			{
				zclaw.zm_ability_state = 0;
				m_pPlayer.ResetEffects();
			}
		}
	}

	//Reset Abilities if we leave body or something
	//Aquire ZClass from HClass ID
	Zombie_Class@ zc = ZClasses::Zombie_Classes[HClass_Holder[pId]];
	if(zc.Abilities.length() <= 0)
		return;
	
	for(uint a=0;a<zc.Abilities.length();a++)
	{
		if(zc.Abilities[a].Unlocked[pId] && isZombie!=1)
		{
			if(zc.Abilities[a].Name == "Shield [Secondary Attack to Toggle]")
			{
				m_pPlayer.pev.rendermode = kRenderNormal;
				m_pPlayer.pev.renderfx = kRenderFxNone;
				m_pPlayer.pev.renderamt = 255;
			} else if(ZClass.Abilities[a].Name == "Mass Ressurect - [Secondary Attack to Use]")
			{
				zclaw.zm_ability_state = 0;
				m_pPlayer.ResetEffects();
			}
		}
	}
	//----------------------------------------------------------------------
}

void ZClass_Process_PlayerProcess_Off(weapon_zclaws@ zclaw,CBasePlayerWeapon@ z_wpn,CBasePlayer@ m_pPlayer,Zombie_Class@ ZClass) {
	//g_Log.PrintF("Player: "+m_pPlayer.pev.netname+" is with AnimExt:'"+m_pPlayer.get_m_szAnimExtension()+"'\n");
	
	CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
	int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
	int ZWeaponId = atoui(KeyValues.GetKeyvalue("$i_ZombieWeapon").GetString());
	//----------------------------------------------------------------------
	int flags = m_pPlayer.pev.flags;
	int old_buttons = m_pPlayer.pev.oldbuttons;
	int button = m_pPlayer.pev.button;
	int pId = m_pPlayer.entindex();
	
	//Make sure Player is not Mutating
	if(ZClass_MutationState[pId]!=ZM_MUTATION_NONE)
		return;
	
	//Reset Abilities if we leave body or something
	//Aquire ZClass from HClass ID
	Zombie_Class@ zc = ZClasses::Zombie_Classes[HClass_Holder[pId]];
	for(uint a=0;a<zc.Abilities.length();a++)
	{
		if(zc.Abilities[a].Unlocked[pId] && (isZombie!=1||ZWeaponId==0))
		{
			if(zc.Abilities[a].Name == "Shield [Secondary Attack to Toggle]")
			{
				m_pPlayer.pev.rendermode = kRenderNormal;
				m_pPlayer.pev.renderfx = kRenderFxNone;
				if(zclaw !is null) {
					zclaw.zm_ability_state = 0;
				}
			}
		}
	}
	//----------------------------------------------------------------------
}

HookReturnCode ZC_TakeDamage(DamageInfo@ info) {
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(info.pVictim.pev));

	if(pPlayer !is null)
	{
		int index = pPlayer.entindex();
		float dmgAmount = info.flDamage;
		
		CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_zclaws");
		weapon_zclaws@ zclaw = cast<weapon_zclaws@>(CastToScriptClass(pWpn));
		if(pWpn !is null && zclaw !is null) {
			zclaw.zm_LastTookedDmg = dmgAmount;
		}
	}

	return HOOK_CONTINUE;
}