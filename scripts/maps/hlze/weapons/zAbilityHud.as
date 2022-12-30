//Baby Crabs HUD for Sven Co-op Zombie Edition
//I Will use this file for 'Mass Ressurection' Zombie Ability
#include "weapon_zombie"

const string BabyCrabs_SignSpr = "hlze/baby_crabs.spr";
const string MassRessurection_SignSpr = "hlze/revive.spr";

namespace zAbilityHud {
	//BabyCrabs Stuff
	array<float>BC_Timer(33,g_Engine.time);
	array<float>BC_GiveDelay(33,g_Engine.time);
	array<bool>BC_GiveNow(33,false);
	float BC_Frequency = 15.0;
	//Mass Ressurection Stuff
	array<bool>MR_State(33,false);
	array<bool>MR_Show4FirstTime(33,true);

	void Precache() {
		g_Game.PrecacheGeneric("sprites/"+BabyCrabs_SignSpr);
		g_Game.PrecacheGeneric("sprites/"+MassRessurection_SignSpr);
	}
	
	HookReturnCode PlayerQuit(CBasePlayer@ pPlayer)
	{
		if( pPlayer is null ) //Null pointer checker
			return HOOK_CONTINUE;
		
		int pId = pPlayer.entindex();
		//Reset
		BC_Timer[pId] = g_Engine.time;
		BC_GiveDelay[pId] = g_Engine.time;
		BC_GiveNow[pId] = false;

		MR_State[pId] = false;
		MR_Show4FirstTime[pId] = true;

		return HOOK_CONTINUE;
	}

	void ShowBabyCrabs(CBasePlayer@ pPlayer, int ammo,int MaxAmmo)
	{
		int pId = pPlayer.entindex();
		// Sprite Display
		HUDSpriteParams HudParams;
		HudParams.channel = 5;
		HudParams.flags = HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_DYNAMIC_ALPHA;
		HudParams.spritename = BabyCrabs_SignSpr;
		HudParams.left = 0; // Offset
		HudParams.top = 0; // Offset
		HudParams.width = 0; // 0: auto; use total width of the sprite
		HudParams.height = 0; // 0: auto; use total height of the sprite
		HudParams.x = 650;
		HudParams.y = -35;
		RGBA clr1 = RGBA(255,0,0,110);
		RGBA clr2 = RGBA(0,255,0,255);
		HudParams.color1 = clr1;
		HudParams.color2 = clr2;
		HudParams.frame = 0;
		HudParams.numframes = 20;
		HudParams.framerate = (HudParams.numframes)/BC_Frequency;
		
		if(MR_State[pId]) {
			HudParams.x = 600;
			HudParams.y = -35;
		}

		HudParams.fxTime = BC_Frequency;
		
		HudParams.effect = HUD_EFFECT_RAMP_UP | HUD_EFFECT_COSINE_UP;
		
		if(ammo >= MaxAmmo) {
			HudParams.effect = HUD_EFFECT_NONE;
			HudParams.color2 = clr1;
			HudParams.frame = 0;
			HudParams.numframes = 0;
		}

		g_PlayerFuncs.HudCustomSprite(pPlayer,HudParams);
	}
	
	void UpdateBabyCrabs(CBasePlayer@ pPlayer) {
		int pId = pPlayer.entindex();
		CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
		int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
		int ZWeaponId = atoui(KeyValues.GetKeyvalue("$i_ZombieWeapon").GetString());
		//ZClass must have 'Baby Crabs' Ability
		bool hasBCAbility = false;
		bool hasExtraAmmoAbility = false;
		CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_zclaws");
		weapon_zclaws@ zclaw = cast<weapon_zclaws@>(CastToScriptClass(pWpn));

		if(pWpn is null || zclaw is null)
			return;
		
		for(uint a=0;a<zclaw.ZClass.Abilities.length();a++) {
			if(zclaw.ZClass.Abilities[a].Unlocked[pId] && zclaw.ZClass.Abilities[a].Active[pId]) {
				if(zclaw.ZClass.Abilities[a].Name == "Baby Crabs") {
					hasBCAbility = true;
				}
				if(zclaw.ZClass.Abilities[a].Name == "Ammo Upgrade") {
					hasExtraAmmoAbility = true;
				}
			}
		}
		
		if(isZombie==1 && hasBCAbility && ZClass_MutationState[pId]==ZM_MUTATION_NONE)
		{
			g_PlayerFuncs.HudToggleElement(pPlayer,5,true);
			//Process
			int ammo = 0;
			int MaxAmmo = 5;
			if(hasExtraAmmoAbility)
				MaxAmmo+=5;

			if(BC_GiveNow[pId] && BC_GiveDelay[pId] < g_Engine.time) {
				CBasePlayerWeapon@ hcWep = Get_Weapon_FromPlayer(pPlayer,"weapon_zbcrab");
				if(hcWep !is null)
				{
					if(pPlayer.m_rgAmmo(hcWep.m_iPrimaryAmmoType) < MaxAmmo)
					{
						if(pPlayer.GiveAmmo((pPlayer.HasNamedPlayerItem("weapon_zbcrab").GetWeaponPtr().m_iDefaultAmmo),"ammo_headcrabs",MaxAmmo)!=-1) {
							pPlayer.GiveNamedItem("ammo_babycrabs");
						}
					}
				} else {
					pPlayer.GiveNamedItem("weapon_zbcrab");
				}
				BC_GiveNow[pId] = false;
			}

			//Get Ammo
			CBasePlayerWeapon@ hcWep = Get_Weapon_FromPlayer(pPlayer,"weapon_zbcrab");
			if(hcWep !is null)
			{
				ammo = pPlayer.m_rgAmmo(hcWep.m_iPrimaryAmmoType);
			}

			if(BC_Timer[pId] < g_Engine.time) {
				ShowBabyCrabs(pPlayer,ammo,MaxAmmo);
				if(ammo < MaxAmmo) {
					BC_Timer[pId] = g_Engine.time + BC_Frequency;
					BC_GiveDelay[pId] = g_Engine.time + BC_Frequency;
					BC_GiveNow[pId] = true;
				} else {
					BC_Timer[pId] = g_Engine.time + 0.1;
					BC_GiveDelay[pId] = g_Engine.time + 0.1;
					BC_GiveNow[pId] = false;
				}
			}
		} else {
			g_PlayerFuncs.HudToggleElement(pPlayer,5,false);
			BC_Timer[pId] = g_Engine.time;
			BC_GiveDelay[pId] = g_Engine.time;
			BC_GiveNow[pId] = false;
		}
	}

	void ShowMassRessurectionEmpty(CBasePlayer@ pPlayer)
	{
		int pId = pPlayer.entindex();
		// Sprite Display
		HUDSpriteParams HudParams;
		HudParams.channel = 6;
		HudParams.flags = HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_DYNAMIC_ALPHA;
		HudParams.spritename = MassRessurection_SignSpr;
		HudParams.left = 0; // Offset
		HudParams.top = 0; // Offset
		HudParams.width = 0; // 0: auto; use total width of the sprite
		HudParams.height = 0; // 0: auto; use total height of the sprite

		HudParams.x = 650;
		HudParams.y = -35;
		RGBA clr1 = RGBA(255,0,0,100);
		HudParams.color1 = clr1;
		HudParams.color2 = clr1;
		HudParams.frame = 0;
		HudParams.numframes = 2;
		HudParams.framerate = 0.0;
		
		HudParams.fxTime = BC_Frequency;
		
		HudParams.effect = HUD_EFFECT_NONE;
		
		if(MR_State[pId]) {
			HudParams.x = 700;
			HudParams.y = -35;
		}

		g_PlayerFuncs.HudCustomSprite(pPlayer,HudParams);
	}

	void ShowMassRessurection(CBasePlayer@ pPlayer,float FXTime)
	{
		int pId = pPlayer.entindex();
		// Sprite Display
		HUDSpriteParams HudParams;
		HudParams.channel = 7;
		HudParams.flags = HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_DYNAMIC_ALPHA | HUD_ELEM_EFFECT_ONCE;
		HudParams.spritename = MassRessurection_SignSpr;
		HudParams.left = 0; // Offset
		HudParams.top = 0; // Offset
		HudParams.width = 0; // 0: auto; use total width of the sprite
		HudParams.height = 0; // 0: auto; use total height of the sprite

		HudParams.x = 650;
		HudParams.y = -35;
		RGBA clr1 = RGBA(255,0,0,0);
		RGBA clr2 = RGBA(255,0,0,100);
		HudParams.color1 = clr1;
		HudParams.color2 = clr2;
		HudParams.frame = 1;
		HudParams.numframes = 2;
		HudParams.framerate = 0.0;
		
		HudParams.fxTime = FXTime;
		
		HudParams.effect = HUD_EFFECT_RAMP_UP | HUD_EFFECT_COSINE_UP;
		
		if(MR_State[pId]) {
			HudParams.x = 700;
			HudParams.y = -35;
		}

		g_PlayerFuncs.HudCustomSprite(pPlayer,HudParams);
	}

	void UpdateMassRessurection(CBasePlayer@ pPlayer) {
		int pId = pPlayer.entindex();
		CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
		int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
		int ZWeaponId = atoui(KeyValues.GetKeyvalue("$i_ZombieWeapon").GetString());
		//ZClass must have 'Mass Ressurection' Ability
		bool hasMRAbility = false;
		float MR_AbilityTimer = g_Engine.time;
		CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_zclaws");
		weapon_zclaws@ zclaw = cast<weapon_zclaws@>(CastToScriptClass(pWpn));

		if(pWpn is null || zclaw is null)
			return;
		
		for(uint a=0;a<zclaw.ZClass.Abilities.length();a++) {
			if(zclaw.ZClass.Abilities[a].Unlocked[pId] && zclaw.ZClass.Abilities[a].Active[pId]) {
				if(zclaw.ZClass.Abilities[a].Name == "Mass Ressurect - [Secondary Attack to Use]") {
					hasMRAbility = true;
					MR_AbilityTimer = zclaw.ZClass.Ability_Timer[pId];
				}
			}
		}
		
		MR_State[pId] = hasMRAbility;

		if(isZombie==1 && hasMRAbility && ZClass_MutationState[pId]==ZM_MUTATION_NONE)
		{
			g_PlayerFuncs.HudToggleElement(pPlayer,6,true);
			g_PlayerFuncs.HudToggleElement(pPlayer,7,true);
			ShowMassRessurectionEmpty(pPlayer);
			//Show For The First time
			//Ability Hud
			if(MR_Show4FirstTime[pId]) {
				MR_Show4FirstTime[pId] = false;
				ShowMassRessurection(pPlayer,0.1);
			}
		} else {
			g_PlayerFuncs.HudToggleElement(pPlayer,6,false);
			g_PlayerFuncs.HudToggleElement(pPlayer,7,false);
			MR_State[pId] = false;
		}
	}
}

void zHudThink()
{
	for(uint i=0;i<33;i++) {
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(pPlayer !is null) {
			zAbilityHud::UpdateBabyCrabs(pPlayer);
			zAbilityHud::UpdateMassRessurection(pPlayer);
			//Hide HUD if this player is not Zombie
			CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
			int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
			if(isZombie!=1) {
				g_PlayerFuncs.HudToggleElement(pPlayer,5,false);
				g_PlayerFuncs.HudToggleElement(pPlayer,6,false);
				g_PlayerFuncs.HudToggleElement(pPlayer,7,false);
			}
		}
	}

	g_Scheduler.SetTimeout("zHudThink", 1.0);
}