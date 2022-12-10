//Baby Crabs HUD for Sven Co-op Zombie Edition
#include "weapon_zombie"

const string BabyCrabs_SignSpr = "hlze/baby_crabs.spr";

namespace BabyCrabs {
	void Precache() {
		g_Game.PrecacheGeneric( "sprites/"+BabyCrabs_SignSpr );
	}
	
	HookReturnCode PlayerJoin(CBasePlayer@ pPlayer)
	{
		if( pPlayer is null ) //Null pointer checker
			return HOOK_CONTINUE;
		
		//ShowPoints(pPlayer);

		return HOOK_CONTINUE;
	}
	
	HookReturnCode PlayerThink(CBasePlayer@ pPlayer)
	{
		if( pPlayer is null ) //Null pointer checker
			return HOOK_CONTINUE;
		
		UpdatePoints(pPlayer);

		return HOOK_CONTINUE;
	}

	void ShowPoints(CBasePlayer@ pPlayer)
	{
		// Numeric Display
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
		RGBA clr1 = RGBA(255,0,0,175);
		RGBA clr2 = RGBA(255,255,0,255);
		HudParams.color1 = clr1;
		HudParams.color2 = clr2;
		HudParams.frame = 1;
		HudParams.numframes = 1;
		HudParams.framerate = 1;
		
		HudParams.fxTime = 5.0;
		
		HudParams.effect = HUD_EFFECT_RAMP_UP | HUD_EFFECT_COSINE_UP;
		
		g_PlayerFuncs.HudCustomSprite(pPlayer,HudParams);
	}
	
	void UpdatePoints(CBasePlayer@ pPlayer) {
		int pId = pPlayer.entindex();
		CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
		int isZombie = atoui(KeyValues.GetKeyvalue("$i_isZombie").GetString());
		int ZWeaponId = atoui(KeyValues.GetKeyvalue("$i_ZombieWeapon").GetString());
		//ZClass must have 'Baby Crabs' Ability
		bool hasBCAbility = false;
		CBasePlayerWeapon@ pWpn = Get_Weapon_FromPlayer(pPlayer,"weapon_zclaws");
		weapon_zclaws@ zclaw = cast<weapon_zclaws@>(CastToScriptClass(pWpn));

		if(pWpn is null || zclaw is null)
			return;
		
		for(uint a=0;a<zclaw.ZClass.Abilities.length();a++) {
			if(zclaw.ZClass.Abilities[a].Unlocked[pId] && zclaw.ZClass.Abilities[a].Active[pId]) {
				if(zclaw.ZClass.Abilities[a].Name == "Baby Crabs") {
					hasBCAbility = true;
					break;
				}
			}
		}
		
		if(isZombie==1 && hasBCAbility)
		{
			ShowPoints(pPlayer);
			g_PlayerFuncs.HudToggleElement(pPlayer,5,true);
		} else {
			g_PlayerFuncs.HudToggleElement(pPlayer,5,false);
		}
	}
}