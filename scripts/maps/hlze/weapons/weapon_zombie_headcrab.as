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

class weapon_zhcrab : ScriptBasePlayerWeaponEntity
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
		
		//self.SendWeaponAnim(anim_index,0,ZClass.VIEW_MODEL_BODY_ID);
		self.DefaultDeploy(self.GetV_Model(V_MODEL_ZOMBIE_HC),
							self.GetP_Model(P_MODEL_ZOMBIE_HC), anim_index, "shotgun", 0, ZClass.VIEW_MODEL_BODY_ID);
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
		int ammo = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType);
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