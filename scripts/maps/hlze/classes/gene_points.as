//Gene Point File for Sven Co-op Zombie Edition
#include "../save-load/gene_points" //Save/Load
array<int>GenePts_Holder(33);
const string GenePts_SignSpr = "hlze/gene_pts.spr";

namespace Gene_Points {
	void Precache() {
		g_Game.PrecacheGeneric( "sprites/"+GenePts_SignSpr );
	}
	
	HookReturnCode PlayerJoin(CBasePlayer@ pPlayer)
	{
		if( pPlayer is null ) //Null pointer checker
			return HOOK_CONTINUE;
		
		ShowPoints(pPlayer);

		return HOOK_CONTINUE;
	}
	
	HookReturnCode PlayerQuit(CBasePlayer@ pPlayer)
	{
		if( pPlayer is null ) //Null pointer checker
			return HOOK_CONTINUE;
		
		GenePts_Holder[pPlayer.entindex()] = 0;
		
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
		HUDNumDisplayParams NumDisplayParams;
		NumDisplayParams.channel = 0;
		NumDisplayParams.flags = HUD_ELEM_ABSOLUTE_X | HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_DYNAMIC_ALPHA | HUD_ELEM_EFFECT_ONCE;
		NumDisplayParams.x = 5;
		NumDisplayParams.y = -35;
		NumDisplayParams.spritename = GenePts_SignSpr;
		NumDisplayParams.defdigits = 0;
		NumDisplayParams.maxdigits = 5;
		NumDisplayParams.left = 0; // Offset
		NumDisplayParams.top = 0; // Offset
		NumDisplayParams.width = 24; // 0: auto; use total width of the sprite
		NumDisplayParams.height = 31; // 0: auto; use total height of the sprite
		NumDisplayParams.color1 = RGBA_SVENCOOP; // Default Sven HUD colors
		NumDisplayParams.color2 = RGBA_SVENCOOP; // Default Sven HUD colors
		
		NumDisplayParams.fxTime = 0.5;
		
		NumDisplayParams.effect = HUD_EFFECT_RAMP_DOWN;
		
		NumDisplayParams.value = uint(GenePts_Holder[pPlayer.entindex()]);
		
		g_PlayerFuncs.HudNumDisplay(pPlayer,NumDisplayParams);
	}
	
	void UpdatePoints(CBasePlayer@ pPlayer) {
		ShowPoints(pPlayer);
	}
	
	void AddPoints(int index, int amount) {
		GenePts_Holder[index] += amount;
		SaveLoad_GenePoints::SaveData(index);
	}
	
	void RemovePoints(int index, int amount) {
		GenePts_Holder[index] -= amount;
		
		if(GenePts_Holder[index] < 0)
			GenePts_Holder[index]=0;
		
		SaveLoad_GenePoints::SaveData(index);
	}
}