/*  
* Baby Crabs
*/
#include "weapon_zombie"
#include "../projectiles/proj_barnacle_baby"

const string MODEL_BARNACLE = "models/barnacle.mdl";
const string V_MODEL_ZOMBIE_BARNACLE = "models/hlze/v_barnaclegun.mdl";
const string P_MODEL_ZOMBIE_BARNACLE = P_MODEL;
const string P_MODEL_ZOMBIE_BARNACLE_LEFT = "models/hlze/p_barnaclegun.mdl";
const string P_MODEL_ZOMBIE_BARNACLE_RIGHT = "models/hlze/p_barnaclegun2.mdl";
const string W_MODEL_ZOMBIE_BARNACLE = "models/hlze/w_barnaclegun.mdl";

const string ZOMBIE_BARNACLE_PICK_UP = "barnacle/bcl_tongue1.wav";

enum ZombieBarnacleWeapon_Animations
{
	ZMBW_IDLE = 0,
	ZMBW_DRAW,
	ZMBW_HOLSTER,
	ZMBW_ATTACK
};


enum ZombieBarnacleWeapon_ThrowingStates
{
	ZMBW_THROW_NONE,
	ZMBW_THROW_LEFT,
	ZMBW_THROW_RIGHT,
	ZMBW_THROW_THROW
};

void ZombieBarnacleWeapon_Precache() {
	//Precache Models
	g_Game.PrecacheModel(V_MODEL_ZOMBIE_BARNACLE);
	g_Game.PrecacheModel(P_MODEL_ZOMBIE_BARNACLE);
	g_Game.PrecacheModel(P_MODEL_ZOMBIE_BARNACLE_LEFT);
	g_Game.PrecacheModel(P_MODEL_ZOMBIE_BARNACLE_RIGHT);
	g_Game.PrecacheModel(W_MODEL_ZOMBIE_BARNACLE);
	
	//Precache Sounds
	PrecacheSounds({
		"barnacle/bcl_tongue1.wav"
	});

	//Precache Sprites
	g_Game.PrecacheGeneric( "sprites/weapon_bweapon.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_bw_hud.spr" );
	g_Game.PrecacheGeneric( "sprites/hlze/interface.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_zombie_barnacle.txt" );
}

class weapon_zombie_barnacle : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	//Player Zombie Class Holder
	Zombie_Class@ ZClass;

	//Headcrab Regen (Not the one we are holding)
	float hc_RegenTime = g_Engine.time;
	float hc_RegenFreq = 2.5;
	
	//Degen our Zombie
	float zm_DegenTime = g_Engine.time;
	float zm_DegenFreq = 8.0;
	float zm_DegenDelay = 25.0;
	
	//Darkvision Color
	Vector NVColor(0,0,0);
	
	//Mutation Time
	float zm_MutationTime = g_Engine.time;
	float zm_MutationDelay = 5.0;

	//Ability
	int zm_ability_state = 0;
	float zm_ability_timer = g_Engine.time;

	//Barnacle Throwing State
	int barnacle_throwing_state = ZMBW_THROW_NONE;
	float barnacle_throwing_state_Timer = g_Engine.time;

	//Barnacle Functions
	void BarnacleReset() {
		barnacle_throwing_state = ZMBW_THROW_NONE;
		barnacle_throwing_state_Timer = g_Engine.time;
		self.pev.animtime = g_Engine.time;
		self.pev.framerate = 1.0;
	}
	void BarnacleThrow() {
		barnacle_throwing_state_Timer=g_Engine.time;
		barnacle_throwing_state=ZMBW_THROW_LEFT;
		BarnacleProcess();
	}
	void BarnacleProcess() {
		if(barnacle_throwing_state_Timer<g_Engine.time) {
			if(barnacle_throwing_state==ZMBW_THROW_LEFT) {
				barnacle_throwing_state_Timer=g_Engine.time+0.5;
				m_pPlayer.pev.weaponmodel=P_MODEL_ZOMBIE_BARNACLE_LEFT;
				barnacle_throwing_state=ZMBW_THROW_RIGHT;
			} else if(barnacle_throwing_state==ZMBW_THROW_RIGHT) {
				barnacle_throwing_state_Timer=g_Engine.time+0.63; //1.13-0.5
				m_pPlayer.pev.weaponmodel=P_MODEL_ZOMBIE_BARNACLE_RIGHT;
				barnacle_throwing_state=ZMBW_THROW_THROW;
			} else if(barnacle_throwing_state==ZMBW_THROW_THROW) {
				self.pev.animtime = g_Engine.time;
				self.pev.framerate = 1.0;
				barnacle_throwing_state_Timer=g_Engine.time+1.13;
				barnacle_throwing_state=ZMBW_THROW_NONE;
				//Throw Barnacle Here
				Math.MakeVectors(m_pPlayer.pev.v_angle);
				Vector vecSrc	= m_pPlayer.GetGunPosition();
				float throw_amount = 500.0;
				CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("proj_baby_barnacle");
				Proj_BabyBarnacle@ Projectile = cast<Proj_BabyBarnacle@>(CastToScriptClass(entBase));
				g_EntityFuncs.DispatchSpawn(Projectile.self.edict());
				@Projectile.pev.owner = m_pPlayer.edict();
				entBase.SetClassification(m_pPlayer.GetClassification(CLASS_ALIEN_MONSTER));
				Projectile.pev.origin = vecSrc + g_Engine.v_forward * 16 + g_Engine.v_right * 6;
				Projectile.pev.velocity = g_Engine.v_forward * throw_amount * 2.0;
				Projectile.pev.angles = m_pPlayer.pev.v_angle;
				//Take Away Ammo/Weapon
				if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 1)
				{
					m_pPlayer.pev.weaponmodel=P_MODEL_ZOMBIE_BARNACLE;
					m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType,0);
					//self.DestroyItem();
				} else {
					m_pPlayer.pev.weaponmodel=P_MODEL_ZOMBIE_BARNACLE_LEFT;
					m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType,m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType)-1);
				}
			}
		}
	}

	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model(W_MODEL_ZOMBIE_BARNACLE) );
		self.m_iDefaultAmmo 		= 1;
		self.m_iClip 			= 1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();

		ZombieBarnacleWeapon_Precache();
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= 5;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= -1;
		info.iSlot		= 3;
		info.iPosition		= 8;
		info.iFlags		= 0;
		info.iWeight		= 0;

		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		
		@m_pPlayer = pPlayer;
		g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_ITEM,ZOMBIE_BARNACLE_PICK_UP, 1, ATTN_NORM, 0, 130);

		if(ZClass_Holder[m_pPlayer.entindex()] == HClass_Holder[m_pPlayer.entindex()]) {
			ZClass_Mutate(HClass_Holder[m_pPlayer.entindex()]);
			ZClass_MutationState[m_pPlayer.entindex()] = ZM_MUTATION_NONE;
		} else {
			//Mutation to Another Class
			ZClass_Mutate(HClass_Holder[m_pPlayer.entindex()]);
			zm_MutationTime = g_Engine.time + 5.0;
			ZClass_MutationState[m_pPlayer.entindex()] = ZM_MUTATION_BEGIN;
		}
		
		return true;
	}
	
	bool Deploy()
	{
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;
		
		SetThink(ThinkFunction(this.ZombieProcess));
		self.pev.nextthink = g_Engine.time + 0.1;
		
		//Darkvision Color
		NVColor.x = ZClass.DV_Color.x / 8;
		NVColor.y = ZClass.DV_Color.y / 8;
		NVColor.z = ZClass.DV_Color.z / 8;
		
		m_pPlayer.KeyValue("$i_isZombie",true);

		//Set View Model from v_zheadcrab and body id from Zombie Class
		self.DefaultDeploy( self.GetV_Model(V_MODEL_ZOMBIE_BARNACLE),
							self.GetP_Model(P_MODEL_ZOMBIE_BARNACLE_LEFT), ZMBW_DRAW, "gren", 0, ZClass.VIEW_MODEL_BODY_ID);
		
		self.m_flNextPrimaryAttack = g_Engine.time + 1.2;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.2;

		//Reset Barnacle Variables
		BarnacleReset();

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

		//Reset Barnacle Variables
		BarnacleReset();
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
		
		self.SendWeaponAnim(ZMBW_IDLE,0,ZClass.VIEW_MODEL_BODY_ID);
		/*
		self.DefaultDeploy(self.GetV_Model(V_MODEL_ZOMBIE_BARNACLE),
							self.GetP_Model(P_MODEL_ZOMBIE_BARNACLE_LEFT), ZMBW_IDLE, "gren", 0, ZClass.VIEW_MODEL_BODY_ID);
		*/
		self.m_flTimeWeaponIdle =  2.5;
	}
	
	void PrimaryAttack()
	{
		if(self.m_flNextPrimaryAttack > g_Engine.time)
			return;
		
		if(m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0)
			return;

		self.DefaultDeploy(self.GetV_Model(V_MODEL_ZOMBIE_BARNACLE),
							self.GetP_Model(P_MODEL_ZOMBIE_BARNACLE_LEFT), ZMBW_ATTACK, "gren", 0, ZClass.VIEW_MODEL_BODY_ID);
		
		m_pPlayer.SetAnimation(PLAYER_IDLE);
		m_pPlayer.pev.frame = 0;
		PlayerAnimator::Force_Animation(m_pPlayer, 35, 0.3);
		self.m_flNextPrimaryAttack = g_Engine.time + 2.0;

		//Throw Schedule
		BarnacleThrow();
	}
	
	void ZombieProcess() {
		self.pev.nextthink = g_Engine.time + 0.1;
		
		//Force Player Model
		CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
		if(ZClass.PLAYER_MODEL == "null") {
			int infected_type = atoui(KeyValues.GetKeyvalue("$i_infected_type").GetString());
			int infected_maskless = atoui(KeyValues.GetKeyvalue("$i_infected_type_maskless").GetString());
			
			if(infected_type==INFECTED_SCIENTIST) m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_SCIENTIST+1]);
			else if(infected_type==INFECTED_GUARD) m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_GUARD+1]);
			else if(infected_type==INFECTED_HGRUNT) {
				if(infected_maskless==1) m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_HGRUNT+2]);
				else m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_HGRUNT+1]);
			} else m_pPlayer.SetOverriddenPlayerModel(InfectedPlayerModels[INFECTED_SCIENTIST+1]);
		} else m_pPlayer.SetOverriddenPlayerModel(ZClass.PLAYER_MODEL);

		int flags = m_pPlayer.pev.flags;
		int player_old_buttons = m_pPlayer.pev.oldbuttons;
		int player_buttons = m_pPlayer.pev.button;
		int pId = m_pPlayer.entindex();
		
		if((flags & FL_DUCKING) != 0) {
			m_pPlayer.pev.flDuckTime = 0.0;
			m_pPlayer.pev.view_ofs = ZClass.ZView_Offset / Vector(2,2,2);
		} else m_pPlayer.pev.view_ofs = ZClass.ZView_Offset;
		
		if((player_buttons & IN_RELOAD) != 0 || m_pPlayer.pev.armorvalue <= 0.0) {
			LeaveBody();
		}
		
		//Headcrab Regen
		if(hc_RegenTime < g_Engine.time) {
			if(m_pPlayer.pev.health < m_pPlayer.pev.max_health) {
				m_pPlayer.pev.health = m_pPlayer.pev.health + 1;
				hc_RegenTime = g_Engine.time + hc_RegenFreq;
			}
		}
		
		//Degen our Zombie over time
		if(zm_DegenTime < g_Engine.time) {
			if(m_pPlayer.pev.armorvalue > 0.0) {
				m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue - 1;
				zm_DegenTime = g_Engine.time + zm_DegenFreq;
			}
		}
		
		//Something like Nightvision
		DarkVision();

		//Barnacle Process
		BarnacleProcess();
	}
	
	void LeaveBody() {
		m_pPlayer.KeyValue("$i_isZombie",false);
		
		if(m_pPlayer.pev.armorvalue >= ZClass.Health)
			m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue - ZClass.Health;

		float fUp = 0.0;
		array<Vector>bwTriangle = {
			Vector(0.0,0.0,0.0),
			Vector(15.0,0.0,0.0),
			Vector(0.0,15.0,0.0),
			Vector(-15.0,15.0,0.0),
			Vector(-15.0,-15.0,0.0)
		};
		int ammo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
		for(uint c=0;c<uint(ammo);c++)
		{
			Math.MakeVectors(m_pPlayer.pev.v_angle);
			//Vector vecSrc	= m_pPlayer.GetGunPosition();
			Vector vecSrc = m_pPlayer.pev.origin + Vector(0,0,fUp);
			fUp+=9.0;
			float throw_amount = 500.0;
			CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_babycrab");
			CBaseMonster@ bc = entBase.MyMonsterPointer();
			if(bc !is null) {
				g_EntityFuncs.DispatchSpawn(bc.edict());
				bc.SetPlayerAllyDirect(true);
				bc.pev.origin = vecSrc + g_Engine.v_forward * bwTriangle[c].y + g_Engine.v_right * bwTriangle[c].x;
				bc.pev.angles.y = m_pPlayer.pev.v_angle.y;
				bc.pev.velocity = g_Engine.v_forward * throw_amount;
			}
		}
		m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType,0);

		self.DestroyItem();
		m_pPlayer.RemoveAllItems(false);
		m_pPlayer.SetItemPickupTimes(0);

		//Leave Body
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_infected_leaved");
		Infected_Leaved@ ent = cast<Infected_Leaved@>(CastToScriptClass(entBase));
		
		//Vector createOrigin = m_pPlayer.pev.origin - Vector(0.0,0.0,36.0);
		Vector createOrigin = m_pPlayer.pev.origin - Vector(0.0,0.0,36.0);
		
		int flags = m_pPlayer.pev.flags;
		if((flags & FL_DUCKING) != 0) {
			createOrigin = m_pPlayer.pev.origin - Vector(0.0,0.0,18.0);
		}
		
		Vector createAngles = m_pPlayer.pev.angles;
		
		g_EntityFuncs.DispatchSpawn( ent.self.edict() );
		ent.pev.angles.x = 0.0;
		ent.pev.angles.z = 0.0;
		ent.pev.angles.y = createAngles.y;
		
		ent.pev.origin = createOrigin;
		
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
	
	//Special Zombie Class Stuff
	void ZClass_Mutate(uint zclass_id=0) {
		//----------------------------------------------------------------------
		if(ZClasses::Zombie_Classes.length() < zclass_id)
			zclass_id=0;
		
		@ZClass = ZClasses::Zombie_Classes[zclass_id];

		zm_DegenTime = g_Engine.time + ZClass.DegenDelay;
		zm_DegenFreq = g_Engine.time + ZClass.DegenRate;

		zm_ability_state = 0;
		zm_ability_timer = g_Engine.time;
	}
}

class ammo_barnacle : ScriptBasePlayerAmmoEntity
{	
	bool CommonAddAmmo( CBaseEntity& inout pOther, int& in iAmmoClip, int& in iAmmoCarry, string& in iAmmoType )
	{
		if( pOther.GiveAmmo( iAmmoClip, iAmmoType, iAmmoCarry ) != -1 )
		{
			g_SoundSystem.EmitSoundDyn(self.edict(),CHAN_ITEM,ZOMBIE_BARNACLE_PICK_UP, 1, ATTN_NORM, 0, 130);
			return true;
		}
		return false;
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, W_MODEL_ZOMBIE_BARNACLE);
		self.pev.body = 0;
		BaseClass.Spawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel(W_MODEL_ZOMBIE_BARNACLE);
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo(pOther, 1, 5,"ammo_barnacle");
	}
}

class script_barnacle_baby : ScriptBaseMonsterEntity {
	void Precache()
	{
		g_Game.PrecacheModel(W_MODEL_ZOMBIE_BARNACLE);
	}

	void Spawn()
	{
		//No need for Precaching Stuff............
		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_BBOX;
		self.pev.gravity = 1.0f;

		g_EntityFuncs.SetModel(self,W_MODEL_ZOMBIE_BARNACLE);
		g_EntityFuncs.SetSize(self.pev, Vector(-2,-2,-2), Vector(2,2,2));

		SetTouch(TouchFunction(EntTouch));
	}

	//When Zombie Player with Barnacles Ability touches this, give him barnacle weapon;
	void EntTouch(CBaseEntity@ pOther) //Work in Progress
	{
		if(pOther is null || !pOther.IsPlayer())
			return;
		
		int pId = pOther.entindex();
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(pId);
		
		if(pPlayer is null)
			return;
		
		bool hasBarnacles = ZombieClass_PlayerHasAbility(pPlayer,"Barnacles",true);
		//g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK,"Has Barnacles?|"+(hasBarnacles?"Yes":"No")+"\n");
		if(hasBarnacles) {
			CBasePlayerWeapon@ bWep = Get_Weapon_FromPlayer(pPlayer,"weapon_zombie_barnacle");
			if(bWep !is null)
			{
				if(pPlayer.GiveAmmo((pPlayer.HasNamedPlayerItem("weapon_zombie_barnacle").GetWeaponPtr().m_iDefaultAmmo),"ammo_barnacle",pPlayer.GetMaxAmmo("ammo_barnacle"))!=-1) {
					pPlayer.GiveNamedItem("ammo_barnacle");
					g_EntityFuncs.Remove(self);
				}
			} else {
				pPlayer.GiveNamedItem("weapon_zombie_barnacle");
				g_EntityFuncs.Remove(self);
			}
		}
	}
}

void Register_ZombieBarnacleWeapon()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zombie_barnacle", "weapon_zombie_barnacle" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_barnacle", "ammo_barnacle" ); // Register the ammo entity
	g_ItemRegistry.RegisterWeapon( "weapon_zombie_barnacle", "", "ammo_barnacle");
	g_CustomEntityFuncs.RegisterCustomEntity( "script_barnacle_baby", "barnacle_baby" );
	proj_baby_barnacle_Init();
}