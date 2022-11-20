/*  
* Headcrab
*/
#include "..\monsters\monster_infectable"
//Player Animator
#include "..\entities\player_animator"
//Zombie Claws
#include "weapon_zombie"
//Headcrab Classes
#include "..\classes\headcrab_classes"
//Zombie Classes
#include "..\classes\zombie_classes"
//Gene Points
#include "..\classes\gene_points"

//Saves
#include "..\save-load\hclass"
#include "..\save-load\keyvalues"

enum HeadcrabAnimations
{
	HC_IDLE = 0,
	HC_ATTACK,
};

string W_MODEL  	= "models/hlze/null.mdl";
//string V_MODEL  	= "models/hlze/v_hclaws.mdl";
string P_MODEL  	= "models/hlze/null.mdl";

void Headcrab_Precache() {
	//Precache Models
	//g_Game.PrecacheModel(V_MODEL);
	g_Game.PrecacheModel(P_MODEL);
	g_Game.PrecacheModel(W_MODEL);
	
	//Precache Sprites
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws_01.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws_02.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws_hud.spr" );
	g_Game.PrecacheGeneric( "sprites/weapon_hclaws.txt" );
	
	//Precache Sounds
	g_SoundSystem.PrecacheSound( "headcrab/hc_attack1.wav" );
	g_SoundSystem.PrecacheSound( "headcrab/hc_attack2.wav" );
	g_SoundSystem.PrecacheSound( "headcrab/hc_attack3.wav" );
	g_SoundSystem.PrecacheSound( "headcrab/hc_headbite.wav" );
	g_Game.PrecacheGeneric( "sound/headcrab/hc_attack1.wav" );
	g_Game.PrecacheGeneric( "sound/headcrab/hc_attack2.wav" );
	g_Game.PrecacheGeneric( "sound/headcrab/hc_attack3.wav" );
	g_Game.PrecacheGeneric( "sound/headcrab/hc_headbite.wav" );
}

class weapon_hclaws : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	//Player Headcrab Class Holder
	Headcrab_Class@ HClass;
	
	bool attacking = false;
	
	//Ability
	bool hc_ability_state = false;
	
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

		//g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( W_MODEL );

		g_SoundSystem.PrecacheSound( "headcrab/hc_attack1.wav" );
		g_SoundSystem.PrecacheSound( "headcrab/hc_attack2.wav" );
		g_SoundSystem.PrecacheSound( "headcrab/hc_attack3.wav" );
		g_SoundSystem.PrecacheSound( "headcrab/hc_headbite.wav" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		
		@m_pPlayer = pPlayer;
		NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict());
				m.WriteString("-duck;");
		m.End();
		
		HClass_Mutate(HClass_Holder[pPlayer.entindex()]);
		
		return true;
	}
	
	bool Deploy()
	{
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;
		
		SetThink(ThinkFunction(this.HeadcrabProcess));
		self.pev.nextthink = g_Engine.time + 0.1;
		
		if((m_pPlayer.pev.flags & FL_ONGROUND) != 0) {
			NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict());
				m.WriteString("+duck;");
			m.End();
		}
		
		m_pPlayer.KeyValue("$i_isHeadcrab",true);
		
		return self.DefaultDeploy(self.GetV_Model(HClass.VIEW_MODEL),
				self.GetP_Model(P_MODEL),HC_IDLE,0,HClass.VIEW_MODEL_BODY_ID);
	}
	
	void Holster( int skiplocal /* = 0 */ )
	{
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;
		self.m_fInReload = false;// cancel any reload in progress.
		
		m_pPlayer.KeyValue("$i_isHeadcrab",false);
		
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = "";
		
		SetThink( null );
		
		NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict());
				m.WriteString("-duck;");
		m.End();
		
		m_pPlayer.ResetOverriddenPlayerModel(true,false);
	}
	
	void HeadcrabProcess() {
		self.pev.nextthink = g_Engine.time + 0.1;
		
		//Force Player Model
		m_pPlayer.SetOverriddenPlayerModel(HClass.PLAYER_MODEL);
		
		m_pPlayer.SetMaxSpeed(HClass.Get_MaxSpeed());
		
		//Wait for attack
		if(attacking) {
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
						g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict());
					vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
				}
			}
			
			// hit
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			
			if( pEntity !is null )
			{
				// AdamR: Custom damage option
				float flDamage = HClass.Damage;
				if ( self.m_flCustomDmg > 0 )
					flDamage = self.m_flCustomDmg;
				// AdamR: End
				
				g_WeaponFuncs.ClearMultiDamage();
				pEntity.TraceAttack(m_pPlayer.pev,flDamage,g_Engine.v_forward,tr,DMG_NEVERGIB);
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				
				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
		// aone
					if( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
		// end aone
					// play thwack or smack sound
					g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"headcrab/hc_headbite.wav",1,ATTN_NORM,0,HClass.VoicePitch);
					attacking = false;
					
					//Infect
					for(uint i=0;i<Infectable.length();i++) {
						if(pEntity.pev.classname == Infectable[i] && pEntity.IsAlive()) {
							CBaseMonster@ monster;
							if(pEntity.IsMonster()) {
								@monster = pEntity.MyMonsterPointer();
								
								Infected_Process_Player(monster,m_pPlayer);
								
								monster.KeyValue("$i_infected",true);
								self.DestroyItem();
							}
						}
					}
				}
			}
		}
		
		int flags = m_pPlayer.pev.flags;
		
		//Check if Player is not ducking
		if((flags & FL_DUCKING) == 0 && (flags & FL_ONGROUND) != 0) {
			//Force Duck
			m_pPlayer.pev.flDuckTime = 0;
			NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict());
				m.WriteString("+duck;");
			m.End();
		} else {
			m_pPlayer.pev.view_ofs = Vector(0,0,-2);
		}
		
		if((flags & FL_ONGROUND) != 0) {
			attacking = false;
		}
		
		//Do a Jump when we leave body
		CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
		int shouldJump = atoui(KeyValues.GetKeyvalue("$i_hc_jump").GetString());
		if(shouldJump==1) {
			m_pPlayer.KeyValue("$i_hc_jump",false);
			//Reset Attack Time
			self.m_flTimeWeaponIdle = g_Engine.time - 1.0;
			self.m_flNextPrimaryAttack = g_Engine.time - 1.0;
			self.m_flNextSecondaryAttack = g_Engine.time - 1.0;
			
			Swing();
		}
		
		//Something like Nightvision
		DarkVision();
	}
	
	void DarkVision() {
		//Toggle
		CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
		int hc_vision = atoui(KeyValues.GetKeyvalue("$i_hc_vision").GetString());
		
		//Get Player's Light Level
		int player_light_level = m_pPlayer.pev.light_level;
		if(player_light_level <= 40 && hc_vision==1) {
			Vector vecSrc = m_pPlayer.EyePosition();
			
			Vector NVColor_temp = HClass.DV_Color;
			
			Vector NVColor;
			NVColor.x = NVColor_temp.x / 8;
			NVColor.y = NVColor_temp.y / 8;
			NVColor.z = NVColor_temp.z / 8;
			
			NVColor.x -= player_light_level;
			NVColor.y -= player_light_level;
			
			//Clamp this value between 0 and 255
			//Minimum
			if(NVColor.x < 0) NVColor.x = 0;
			if(NVColor.y < 0) NVColor.y = 0;
			if(NVColor.z < 0) NVColor.z = 0;
			//Maximum
			if(NVColor.x > 255) NVColor.x = 255;
			if(NVColor.y > 255) NVColor.y = 255;
			if(NVColor.z > 255) NVColor.z = 255;
			
			g_PlayerFuncs.ScreenFade(m_pPlayer, Vector(255,128,0), 0.1, 0.2, int(NVColor.x)*3, FFADE::FFADE_IN);
			NetworkMessage nvon( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
				nvon.WriteByte( TE_DLIGHT );
				nvon.WriteCoord( vecSrc.x );
				nvon.WriteCoord( vecSrc.y );
				nvon.WriteCoord( vecSrc.z );
				nvon.WriteByte( int(NVColor.x) ); // Radius
				
				nvon.WriteByte( int(NVColor.x) ); //R
				nvon.WriteByte( int(NVColor.y) ); //G
				nvon.WriteByte( int(NVColor.z) ); //B
				
				nvon.WriteByte( 2 ); //Life
				nvon.WriteByte( 0 ); //Decay
			nvon.End();
		}
	}
	
	void PrimaryAttack()
	{
		if(!attacking) {
			attacking = true;
			Swing();
		}
	}
	
	void Swing()
	{
		g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_WEAPON,"headcrab/hc_attack1.wav",1,ATTN_NORM,0,94 + Math.RandomLong(0,0xF));
		
		self.SendWeaponAnim(HC_ATTACK);
		self.m_flNextPrimaryAttack = g_Engine.time + HClass.JumpFreq;
		m_pPlayer.pev.punchangle.x = m_pPlayer.pev.punchangle.x - 5.0 * HClass.JumpFreq;
		
		//Apply Velocity
		m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + g_Engine.v_forward * 400 + g_Engine.v_up * 200;
		
		int random_sound = Math.RandomLong(0,1);
		switch(random_sound) {
			case 0: {
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"headcrab/hc_attack2.wav",1,ATTN_NORM,0,HClass.VoicePitch);
				break;
			}
			case 1: {
				g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_BODY,"headcrab/hc_attack3.wav",1,ATTN_NORM,0,HClass.VoicePitch);
				break;
			}
		}
		// player animation
		PlayerAnimator::Schedule_Animation(m_pPlayer,PLAYER_JUMP,0.01);
		//PlayerAnimator::Schedule_Animation(m_pPlayer,PLAYER_SUPERJUMP,0.01);
	}
	
	void TertiaryAttack() {
		if(self.m_flNextTertiaryAttack > g_Engine.time)
			return;
		
		HClass_Ability(this,self,m_pPlayer,HClass);
	}
	
	//Special Zombie Class Stuff
	void HClass_Mutate(uint hclass_id=0) {
		//----------------------------------------------------------------------
		if(HClasses::Headcrab_Classes.length() < hclass_id)
			hclass_id=0;
		
		int pId = m_pPlayer.entindex();
		
		float zHealth = ZClasses::Zombie_Classes[hclass_id].Health;
		if(m_pPlayer.pev.armorvalue >= zHealth)
			m_pPlayer.pev.armorvalue = m_pPlayer.pev.armorvalue - zHealth;
		//m_pPlayer.pev.armorvalue = 0;
		
		if(HClass_Holder[pId] != HClass_Mutation_Holder[pId]) {
			//Do Blood
			g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(),CHAN_STREAM,"squeek/sqk_blast1.wav",1,ATTN_NORM,0,94+Math.RandomLong(0,0xF));
			//Do Blood
			//Blood1
			uint blood_count = 10;
			for(uint i=0;i<=blood_count;i++) {
				Vector blood_location = m_pPlayer.pev.origin + Vector(0.0,0.0,1.5*i);
				
				NetworkMessage blood(MSG_BROADCAST,NetworkMessages::SVC_TEMPENTITY);
					blood.WriteByte(TE_BLOODSPRITE);
					blood.WriteCoord(blood_location.x);
					blood.WriteCoord(blood_location.y);
					blood.WriteCoord(blood_location.z);
					
					blood.WriteShort(int(m_iBlood[1]));
					blood.WriteShort(int(m_iBlood[0]));
					
					blood.WriteByte(BLOOD_COLOR_YELLOW);
					blood.WriteByte(Math.RandomLong(10,17));
				blood.End();
			}
			uint gib_count = 2;
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
					
					blood.WriteByte(BLOOD_COLOR_YELLOW);
					blood.WriteByte(Math.RandomLong(10,17));
				blood.End();
				
				g_Utility.BloodStream(gib_location,gib_velocity,BLOOD_COLOR_YELLOW,int(i));
				
				TraceResult tr = g_Utility.GetGlobalTrace();
				Vector decal_start = m_pPlayer.pev.origin;
				
				Vector decal_location = m_pPlayer.pev.origin;
				decal_location = decal_location + g_Engine.v_up*(-10.0*i);
				
				g_Utility.TraceLine(decal_start,decal_location,ignore_monsters,m_pPlayer.edict(),tr);
				g_Utility.BloodDecalTrace(tr,BLOOD_COLOR_YELLOW);
			}
			
			//Mutate to this
			HClass_Holder[pId] = HClass_Mutation_Holder[pId];
			//Next time you mutate to this zombie
			ZClass_Holder[pId] = HClass_Mutation_Holder[pId];
		}
		
		@HClass = HClasses::Headcrab_Classes[HClass_Holder[pId]];
		
		m_pPlayer.pev.max_health = HClass.Health;
		m_pPlayer.pev.health = HClass.Health;
		
		g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,HClass.MESSAGE);
		g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,HClass.DESCRIPTION);
		
		self.DefaultDeploy( self.GetV_Model(HClass.VIEW_MODEL),
							self.GetP_Model(P_MODEL), HC_IDLE, "crowbar", 0, HClass.VIEW_MODEL_BODY_ID);
		//----------------------------------------------------------------------
		
		//Check if any starting abilities are there
		//Go through the array
		for(uint a=0;a<HClass.Abilities.length();a++) {
			//"Armor Upgrade"
			if(HClass.Abilities[a].Name == "Armor Upgrade") {
				//Check if unlocked and activated!
				if(HClass.Abilities[a].Unlocked[pId] && HClass.Abilities[a].Active[pId])
				{
					m_pPlayer.pev.armorvalue += 25.0;
				}
			}
		}
		
		SaveLoad_HClasses::SaveData(m_pPlayer.entindex());
	}
}

string GetWeaponName()
{
	return "weapon_hclaws";
}

void Register_Headcrab()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hclaws", GetWeaponName() );
	g_ItemRegistry.RegisterWeapon( GetWeaponName(), "");
}

HookReturnCode HC_Think(CBasePlayer@ pPlayer, uint& out dummy )
{
	int index = pPlayer.entindex();
	
	HC_VisionProcess(pPlayer);
	
	CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_hclaws");
	weapon_hclaws@ hclaws = cast<weapon_hclaws@>(CastToScriptClass(pWpn));
	
	if(hclaws !is null) {
		HClass_Process(pPlayer,hclaws.HClass);
	}
	
	return HOOK_CONTINUE;
}

void HC_VisionProcess(CBasePlayer@ m_pPlayer) {
	//Toggle
	CustomKeyvalues@ KeyValues = m_pPlayer.GetCustomKeyvalues();
	int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
	int isHeadcrab = atoui(KeyValues.GetKeyvalue("$i_isHeadcrab").GetString());
	
	if(isZombie == 1 || isHeadcrab == 1) {
		m_pPlayer.m_iFlashBattery = 0;
		
		if(m_pPlayer.FlashlightIsOn())
			m_pPlayer.FlashlightTurnOff();
		
		int hc_vision = atoui(KeyValues.GetKeyvalue("$i_hc_vision").GetString());
		
		//Get User Input
		int old_buttons = m_pPlayer.pev.oldbuttons;
		int button = m_pPlayer.pev.button;
		
		if((button & IN_ATTACK2) != 0 && (old_buttons & IN_ATTACK2) == 0) {
			if(hc_vision==0) {
				m_pPlayer.KeyValue("$i_hc_vision",true);
				g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTTALK, "Darkvision Activated!\n");
			} else {
				m_pPlayer.KeyValue("$i_hc_vision",false);
				g_PlayerFuncs.ClientPrint(m_pPlayer, HUD_PRINTTALK, "Darkvision Deactivated!\n");
			}
			
			SaveLoad_KeyValues::SaveData(m_pPlayer.entindex()); //Save KeyValues
		}
	}
}

void HClass_Ability(weapon_hclaws@ hclaw, CBasePlayerWeapon@ h_wpn,CBasePlayer@ m_pPlayer, Headcrab_Class@ HClass) {
	int pId = m_pPlayer.entindex();
	//----------------------------------------------------------------------
	//Check if there are any abilities
	if(HClass.Abilities.length() <= 0)
		return;
	
	//Check if unlocked and activated!
	if(!HClass.Abilities[0].Unlocked[pId] || !HClass.Abilities[0].Active[pId])
		return;
	
	h_wpn.m_flNextTertiaryAttack = g_Engine.time + HClass.Ability_ToggleDelay;
	hclaw.hc_ability_state = !hclaw.hc_ability_state;
	
	//All toggleable Primary Abilities
	//Check if toggled
	if(hclaw.hc_ability_state) {
		HClass_Ability_ON(hclaw,m_pPlayer,HClass);
	} else {
		HClass_Ability_OFF(hclaw,m_pPlayer,HClass);
	}
	//----------------------------------------------------------------------
}

void HClass_Ability_ON(weapon_hclaws@ hclaw,CBasePlayer@ m_pPlayer,Headcrab_Class@ HClass) {
	int pId = m_pPlayer.entindex();
	//----------------------------------------------------------------------
	//This Ability must be primary
	if(HClass.Abilities[0].Name == "Triggerable") {
		g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,HClass.Abilities[0].Name+" Activated!");
	}
	//----------------------------------------------------------------------
}

void HClass_Ability_OFF(weapon_hclaws@ hclaw,CBasePlayer@ m_pPlayer,Headcrab_Class@ HClass) {
	int pId = m_pPlayer.entindex();
	//----------------------------------------------------------------------
	//This Ability must be primary
	if(HClass.Abilities[0].Name == "Triggerable") {
		g_PlayerFuncs.ClientPrint(m_pPlayer,HUD_PRINTTALK,HClass.Abilities[0].Name+" Deactivated!");
	}
	//----------------------------------------------------------------------
}

void HClass_Process(CBasePlayer@ m_pPlayer, Headcrab_Class@ HClass) {
	//----------------------------------------------------------------------
	int flags = m_pPlayer.pev.flags;
	int old_buttons = m_pPlayer.pev.oldbuttons;
	int button = m_pPlayer.pev.button;
	int pId = m_pPlayer.entindex();
	
	//Make sure Player is not Mutating
	if(HClass_Holder[pId]!=HClass_Mutation_Holder[pId])
		return;
	
	//Go through the array
	for(uint a=0;a<HClass.Abilities.length();a++) {
		//"Long Jump"
		if(HClass.Abilities[a].Name == "Nothing") {
			//Check if unlocked and activated!
			if(HClass.Abilities[a].Unlocked[pId] && HClass.Abilities[a].Active[pId])
			{
				//Do Nothing.......
			}
		}
	}
	//----------------------------------------------------------------------
}