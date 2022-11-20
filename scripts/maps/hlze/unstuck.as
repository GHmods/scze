//Unstuck System file for Sven Co-op Zombie Edition
//Thanks to AMX Mod Dev
namespace Unstuck {
	array<float>stuck(33);
	array<array<float>>pSize =
	{
		{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
		{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
		{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
		{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
		{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
	};
	
	void UnstuckPlayer(CBasePlayer@ pPlayer) {
		if(pPlayer.pev.movetype != MOVETYPE_NOCLIP && pPlayer.pev.solid != SOLID_NOT) {
			Vector origin = pPlayer.pev.origin;
			Vector mins = pPlayer.pev.mins;
			Vector vec;
			
			HULL_NUMBER hull = (pPlayer.pev.flags & FL_DUCKING != 0) ? head_hull : human_hull;
			if(stuck[pPlayer.entindex()] < g_Engine.time) {
				
				bool stucked = is_hull_vacant(origin,hull,pPlayer);
				
				if(stucked) {
					bool unstucked = false;
					
					for(uint i = 0; i < stuck.length(); i++ ){
						Vector new_origin;
						new_origin = origin + mins * Vector(pSize[i][0],pSize[i][1],pSize[i][2]);
						
						if(!is_hull_vacant(new_origin,hull,pPlayer)) {
							pPlayer.pev.origin = new_origin;
							unstucked = true;
							break;
						}
					}
				}
				
				//g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Stucked? "+(stucked?"Yes":"No")+"\n");
				
				stuck[pPlayer.entindex()] = g_Engine.time + 0.1;
			}
		}
	}
	
	void UnstuckEntity(CBaseEntity@ pEntity) {
		if(pEntity.pev.movetype != MOVETYPE_NOCLIP && pEntity.pev.solid != SOLID_NOT) {
			Vector origin = pEntity.pev.origin;
			Vector mins = pEntity.pev.mins;
			Vector vec;
			
			HULL_NUMBER hull = head_hull;
			bool stucked = is_hull_vacant_DontIgnoreMonsters(origin,point_hull,pEntity);
			
			if(stucked) {
				bool unstucked = false;
				
				for(uint i = 0; i < stuck.length(); i++ ){
					Vector new_origin;
					new_origin = origin + mins * Vector(pSize[i][0],pSize[i][1],pSize[i][2]);
					
					if(!is_hull_vacant_DontIgnoreMonsters(new_origin,hull,pEntity)) {
						pEntity.pev.origin = new_origin;
						unstucked = true;
						break;
					}
				}
				
				if(!unstucked) {
					float UNSTUCK_START_DISTANCE = 1.0;
					uint UNSTUCK_MAX_ATTEMPTS = 25;
					float distance = UNSTUCK_START_DISTANCE;
					
					float u_calc = 1.0;
					
					for(uint i=0;i<UNSTUCK_MAX_ATTEMPTS;i++) {
						Vector new_origin = origin + mins * Vector(distance*u_calc,distance*u_calc,distance*u_calc);
						
						if(!is_hull_vacant_DontIgnoreMonsters(new_origin,hull,pEntity)) {
							pEntity.pev.origin = new_origin;
							unstucked = true;
						}
						
						if(u_calc==-1.0) u_calc=1.0;
						else {
							u_calc=-1.0;
							distance += UNSTUCK_START_DISTANCE;
						}
						
						if(unstucked)
							break;
					}
				}
			}
		}
	}
	
	bool is_hull_vacant_DontIgnoreMonsters(Vector origin,HULL_NUMBER hull,CBaseEntity@ pPlayer) {
		TraceResult tr;
		g_Utility.TraceHull(origin,origin,dont_ignore_monsters,hull,pPlayer.edict(),tr);
		if (tr.fStartSolid != 0 || tr.fAllSolid != 0) //tr.fInOpen
			return true;
		
		return false;
	}
	
	bool is_hull_vacant(Vector origin,HULL_NUMBER hull,CBaseEntity@ pPlayer) {
		TraceResult tr;
		g_Utility.TraceHull(origin,origin,dont_ignore_monsters,hull,pPlayer.edict(),tr);
		
		CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);
		if(pHit !is null) {
			string cName = pHit.pev.classname;
			string mName = cName.Split("_")[0];
			//g_Log.PrintF("Coliding with:"+mName+"\n");
			if("monster" == mName) {
				g_Utility.TraceHull(origin,origin,ignore_monsters,hull,pPlayer.edict(),tr);
			}
		}
		
		if (tr.fStartSolid != 0 || tr.fAllSolid != 0) //tr.fInOpen
			return true;
		
		return false;
	}
}