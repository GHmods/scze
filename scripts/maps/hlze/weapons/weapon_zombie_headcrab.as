/*  
* Zombie
*/
#include "weapon_zombie"

const string V_MODEL_ZOMBIE_HC = "models/hlze/v_zheadcrab.mdl";
const string P_MODEL_ZOMBIE_HC = "models/hlze/p_zheadcrab.mdl";
const string W_MODEL_ZOMBIE_HC = "models/hlze/headcrab.mdl";

enum ZombieHC_Animations
{
	ZMHC_IDLE1,
	ZMHC_IDLE2,
	ZMHC_IDLE3,
	ZMHC_HOLSTER,
	ZMHC_DRAW,
	ZMHC_THROW
};

void ZombieHC_Precache() {
	//Precache Models
	g_Game.PrecacheModel(V_MODEL_ZOMBIE_HC);
	g_Game.PrecacheModel(P_MODEL_ZOMBIE_HC);
	g_Game.PrecacheModel(W_MODEL_ZOMBIE_HC);
	
	//Precache Sprites
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws_01.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws_02.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws_hud.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_zhcrab.txt" );
}

class weapon_zhcrab : weapon_zclaws
{
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model(W_MODEL_ZOMBIE_HC) );
		self.m_iDefaultAmmo 		= 1;
		self.m_iClip 			= 1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();

		//Precache Models
		g_Game.PrecacheModel(V_MODEL_ZOMBIE_HC);
		g_Game.PrecacheModel(P_MODEL_ZOMBIE_HC);
		g_Game.PrecacheModel(W_MODEL_ZOMBIE_HC);
		
		//Precache Sprites
		g_Game.PrecacheGeneric( "sprites/weapon_hclaws_01.spr" );
		g_Game.PrecacheGeneric( "sprites/weapon_hclaws_02.spr" );
		g_Game.PrecacheGeneric( "sprites/weapon_hclaws_hud.spr" );
		g_Game.PrecacheGeneric( "sprites/hlze/interface.spr" );
		g_Game.PrecacheGeneric( "sprites/weapon_zhcrab.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= 5;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= -1;
		info.iSlot		= 4;
		info.iPosition		= 6;
		info.iFlags		= 0;
		info.iWeight		= 0;

		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		
		@m_pPlayer = pPlayer;
		g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_ITEM,"headcrab/hc_attack3.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0xa ));

		//Zombie must mutate only when claws are selected
		//CheckMutation();
		
		return true;
	}
	
	bool Deploy()
	{
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;
		
		SetThink(ThinkFunction(this.ZombieWeaponProcess));
		self.pev.nextthink = g_Engine.time + 0.1;
		
		//Darkvision Color
		DarkVision_Init();
		
		m_pPlayer.KeyValue("$i_isZombie",true);

		//Set View Model from v_zheadcrab and body id from Zombie Class
		self.DefaultDeploy( self.GetV_Model(V_MODEL_ZOMBIE_HC),
							self.GetP_Model(P_MODEL_ZOMBIE_HC), ZMHC_DRAW, "shotgun", 0, ZClass.VIEW_MODEL_BODY_ID);
		
		self.m_flNextPrimaryAttack = g_Engine.time + 0.8;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.8;
		return true;
	}
	
	void Holster( int skiplocal /* = 0 */ )
	{
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;
		self.m_fInReload = false;// cancel any reload in progress.

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = "";
		
		m_pPlayer.KeyValue("$i_isZombie",false);
		
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
		float idle_time = 0.0;
		int random_anim = Math.RandomLong(0,2);
		switch(random_anim) {
			case 0: {
				anim_index = ZMHC_IDLE1;
				idle_time = g_Engine.time + 6.0;
				break;
			}
			case 1: {
				anim_index = ZMHC_IDLE2;
				idle_time = g_Engine.time + 2.4;
				break;
			}
			case 2: {
				anim_index = ZMHC_IDLE3;
				idle_time = g_Engine.time + 2.4;
				break;
			}
		}
		
		self.SendWeaponAnim(anim_index,0,ZClass.VIEW_MODEL_BODY_ID);
		//self.DefaultDeploy(self.GetV_Model(V_MODEL_ZOMBIE_HC),
		//					self.GetP_Model(P_MODEL_ZOMBIE_HC), anim_index, "shotgun", 0, ZClass.VIEW_MODEL_BODY_ID);
		self.m_flTimeWeaponIdle = idle_time;
	}
	
	void PrimaryAttack()
	{
		if(self.m_flNextPrimaryAttack > g_Engine.time)
			return;
		
		if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0)
			return;

		Math.MakeVectors(m_pPlayer.pev.v_angle);
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		float throw_amount = 500.0;
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_headcrab");
		CBaseMonster@ hc = entBase.MyMonsterPointer();
		if(hc !is null) {
			g_EntityFuncs.DispatchSpawn(hc.edict());
			hc.SetPlayerAllyDirect(true);
			hc.pev.origin = vecSrc + g_Engine.v_forward * 70 + g_Engine.v_right * 6;
			hc.pev.velocity = g_Engine.v_forward * throw_amount + g_Engine.v_up * 36.0;
			hc.pev.angles.y = m_pPlayer.pev.v_angle.y;
		}

		//self.SendWeaponAnim(ZMHC_THROW,0,ZClass.VIEW_MODEL_BODY_ID);
		self.DefaultDeploy(self.GetV_Model(V_MODEL_ZOMBIE_HC),
							self.GetP_Model(P_MODEL), ZMHC_THROW, "shotgun", 0, ZClass.VIEW_MODEL_BODY_ID);
		m_pPlayer.SetAnimation(PLAYER_RELOAD);
		self.m_flNextPrimaryAttack = g_Engine.time + 0.5;

		if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 1)
		{
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType,0);
			//self.DestroyItem();
		} else {
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType,m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType)-1);
		}
	}

	void ZombieWeaponProcess() {
		self.pev.nextthink = g_Engine.time + 0.1;

		//Something like Nightvision
		DarkVision();

		//Zombie Class process
		ZClass_Process();
		
		//Fake Attack
		//FakeAttack();
		
		//Force Player Model
		SetupPlayerModel();
		
		//Set View Offset
		Setup_ViewOffset();

		//Eating Process
		//EatingProcess();
		
		//Leave Body Process
		LeaveBody_Process();
		
		//Headcrab Regen
		Headcrab_Regen();
		
		//Degen our Zombie over time
		Degen_Zombie();
	}
}

class ammo_headcrabs : ScriptBasePlayerAmmoEntity
{	
	bool CommonAddAmmo( CBaseEntity& inout pOther, int& in iAmmoClip, int& in iAmmoCarry, string& in iAmmoType )
	{
		if( pOther.GiveAmmo( iAmmoClip, iAmmoType, iAmmoCarry ) != -1 )
		{
			g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_ITEM,"headcrab/hc_attack3.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 0xa ));
			return true;
		}
		return false;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, W_MODEL_ZOMBIE_HC);
		self.pev.body = 0;
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel(W_MODEL_ZOMBIE_HC);
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo(pOther, 1, 5,"ammo_headcrabs");
	}
}

void Register_ZombieHeadcrab()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zhcrab", "weapon_zhcrab" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_headcrabs", "ammo_headcrabs" ); // Register the ammo entity
	g_ItemRegistry.RegisterWeapon( "weapon_zhcrab", "", "ammo_headcrabs");
}