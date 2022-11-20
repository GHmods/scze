/*  
* multisource manager
	* This is used to take control over doors and invisible walls
*/

// Settings
const string multisource_name = "hlze_multisource";
const int multisource_default_state = 1; //Lock Everything
const int multisource_max_SearchEnts = 750; //Maximum Entities that an array can have
const float multisource_interval_walls = 0.10;
const float multisource_interval_doors = 0.25;
const float multisource_velocity_limit = 15.0;

//Optimization
array<EHandle>multisource_SearchedEntities;
array<EHandle>multisource_WallEntities;
array<EHandle>multisource_DoorEntities;
array<EHandle>multisource_DoorEntities_Master;

array<array<string>>DoorEntities = {
	//classname				targetname
	{"func_door_rotating",	"ds1"},
	{"func_door_rotating",	"d1"},
	{"func_door_rotating",	"d2"},
	{"func_door_rotating",	"d3"},
	{"func_door_rotating",	"d4"},
	{"func_door_rotating",	"d5"},
	{"func_door_rotating",	"d6"},
	{"func_door_rotating",	"d7"},
	{"func_door_rotating",	"d8"},
	{"func_door_rotating",	"d9"}
};

array<array<string>>WallEntities = {
	//classname				targetname
	{"func_wall_toggle",	"togg1"},
	{"func_wall_toggle",	"toggle1"},
	{"func_wall_toggle",	"hcwall1"},
	{"func_wall_toggle",	"hcwall2"},
	{"func_wall_toggle",	"hcwall3"},
	{"func_wall_toggle",	"hcwall4"},
	{"func_wall_toggle",	"hcwall5"},
	{"func_wall_toggle",	"hcwall6"},
	{"func_wall_toggle",	"hcwall7"},
	{"func_wall_toggle",	"hcwall8"},
	{"func_wall_toggle",	"hcwall9"},
	{"func_wall_toggle",	"hcwall10"},
	{"func_wall_toggle",	"hcwall11"},
	{"func_wall_toggle",	"hcwall12"},
	{"func_wall_toggle",	"hcwall13"},
	{"func_wall_toggle",	"hcwall14"},
	{"func_wall_toggle",	"hcwall15"},
	{"func_breakable",		"flr_brk"}
};

array<array<int>>WallEntities_Settings = {
	//(Headcrab/Zombie)[1/0]	STATE: https://baso88.github.io/SC_AngelScript/docs/USE_TYPE.htm
	{1, USE_OFF, USE_ON}, //togg1
	{1, USE_OFF, USE_ON}, //toggle1
	{1, USE_OFF, USE_ON}, //hcwall1
	{1, USE_OFF, USE_ON}, //hcwall2
	{1, USE_OFF, USE_ON}, //hcwall3
	{1, USE_OFF, USE_ON}, //hcwall4
	{1, USE_OFF, USE_ON}, //hcwall5
	{1, USE_OFF, USE_ON}, //hcwall6
	{1, USE_OFF, USE_ON}, //hcwall7
	{1, USE_OFF, USE_ON}, //hcwall8
	{1, USE_OFF, USE_ON}, //hcwall9
	{1, USE_OFF, USE_ON}, //hcwall10
	{1, USE_OFF, USE_ON}, //hcwall11
	{1, USE_OFF, USE_ON}, //hcwall12
	{1, USE_OFF, USE_ON}, //hcwall13
	{1, USE_OFF, USE_ON}, //hcwall14
	{1, USE_OFF, USE_ON}, //hcwall15
	{0, USE_ON}
};

void multisource_Init() {
	g_Scheduler.SetTimeout( "multisource_FindEnts", 1.0);
	
	g_Log.PrintF("-------- multisource entity - Initialized! --------\n");
}

void multisource_FindEnts() {
	//Search for all entities
	array<CBaseEntity@>searchedEntities(multisource_max_SearchEnts);
	Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
	Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
	g_EntityFuncs.EntitiesInBox(searchedEntities, mins, maxs, 0);
	
	int found_ents = 0;
	for(uint i=0;i<searchedEntities.length();i++) {
		CBaseEntity@ ent = searchedEntities[i];
		//Check if the entity is not NULL
		if(ent !is null) {
			found_ents++;
			multisource_SearchedEntities.insertLast(EHandle(ent));
		}
	}
	
	g_Log.PrintF("------ Found:"+found_ents+" Entities!\n");
	
	//Now look for walls and doors
	g_Scheduler.SetTimeout( "multisource_StoreWallsAndDoors", 0.5);
}

void multisource_remove(uint ms_index) {
	if(multisource_DoorEntities_Master.length() < ms_index)
		return;
	
	CBaseEntity@ multisourceEnt = multisource_DoorEntities_Master[ms_index].GetEntity();
	
	if(multisourceEnt !is null) {
		//g_Log.PrintF("------ Removed:"+multisourceEnt.pev.targetname+"!\n");
		g_EntityFuncs.Remove(multisourceEnt);
	}
}

void multisource_recreate(uint ms_index) {
	if(multisource_DoorEntities_Master.length() < ms_index)
		return;
	
	multisource_remove(ms_index);
	
	dictionary keys;
	keys["targetname"] = multisource_name+ms_index;
	keys["globalstate"] = ""+multisource_default_state;
	CBaseEntity@ multisourceEnt = g_EntityFuncs.CreateEntity("multisource", keys);
	
	multisource_DoorEntities_Master[ms_index] = EHandle(multisourceEnt);
	//g_Log.PrintF("------ Created:"+multisource_DoorEntities_Master[ms_index].GetEntity().pev.targetname+"!\n");
}

void multisource_StoreWallsAndDoors() {
	int found_walls = 0;
	int found_doors = 0;
	
	//Go through the array
	for(uint i=0;i<multisource_SearchedEntities.length();i++) {
		CBaseEntity@ ent = multisource_SearchedEntities[i];
		//Check if the entity is not NULL
		if(ent !is null) {
			//Look for walls
			for(uint w=0;w<WallEntities.length();w++) {
				if(ent.pev.classname == WallEntities[w][0] && ent.pev.targetname == WallEntities[w][1]) {
					multisource_WallEntities.insertLast(EHandle(ent));
					found_walls++;
				}
			}
			//Look for doors
			for(uint w=0;w<DoorEntities.length();w++) {
				if(ent.pev.classname == DoorEntities[w][0] && ent.pev.targetname == DoorEntities[w][1]) {
					//Convert this entity to CBaseDoor
					CBaseDoor@ stupidDoor = cast<CBaseDoor@>(ent);
					
					if(stupidDoor !is null) {
						stupidDoor.m_sMaster = multisource_name+found_doors;
						g_Log.PrintF("------ Locking Door[ID:"+found_doors+"] with [multisource with targetname:"+stupidDoor.m_sMaster+"]\n");
						multisource_DoorEntities.insertLast(EHandle(ent));
						found_doors++;
					}
				}
			}
		}
	}
	
	g_Log.PrintF("------ Found:"+found_walls+" Headcrab Walls!\n");
	g_Log.PrintF("------ Found:"+found_doors+" Zombie Doors!\n");
	multisource_DoorEntities_Master.resize(found_doors);
	
	g_Scheduler.SetInterval("multisource_Wall_Process", multisource_interval_walls, g_Scheduler.REPEAT_INFINITE_TIMES );
	g_Scheduler.SetInterval("multisource_Door_Process", multisource_interval_doors, g_Scheduler.REPEAT_INFINITE_TIMES );
}

void multisource_Wall_Process() {
	//Go through the array
	for(uint i=0;i<multisource_WallEntities.length();i++) {
		CBaseEntity@ ent = multisource_WallEntities[i];
		//Check if the entity is not NULL
		if(ent !is null) {
			//Look for walls
			for(uint w=0;w<WallEntities.length();w++) {
				if(ent.pev.classname == WallEntities[w][0] && ent.pev.targetname == WallEntities[w][1]) {
					//Look for all players that are near this wall
					for(int p=1;p<=g_Engine.maxClients;p++)
					{
						CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(p);
						
						if (pPlayer !is null && pPlayer.IsConnected()) {
						
							Vector bmin = ent.pev.mins + ent.pev.origin;
							Vector bmax = ent.pev.maxs + ent.pev.origin;
							Vector final_origin = bmax + bmin;
							
							Vector player_origin = (pPlayer.pev.maxs + pPlayer.pev.origin) + (pPlayer.pev.mins + pPlayer.pev.origin);
							
							float dist = (player_origin - final_origin).Length();
							
							//g_Log.PrintF("------ Classname:"+ent.pev.classname+" | Targetname:"+ent.pev.targetname+" | Size:("+ent.pev.size.ToString()+")");
							//g_Log.PrintF(" | Origin:("+final_origin.ToString()+") | Distance To:"+dist+"  ------\n");
							
							CustomKeyvalues@ KeyValues = pPlayer.GetCustomKeyvalues();
							int key_value1 = atoui(KeyValues.GetKeyvalue("$i_isHeadcrab").GetString());
							
							if(ent.pev.classname == "func_breakable") {
								if(dist <= ent.pev.size.Length()) {
									if(key_value1==WallEntities_Settings[w][0]) {
										g_EntityFuncs.FireTargets(ent.pev.targetname, ent, ent, USE_TYPE(WallEntities_Settings[w][1]));
									}
								}
							} else {
								if(dist <= ent.pev.size.Length()) {
									if(key_value1==WallEntities_Settings[w][0]) {
										g_EntityFuncs.FireTargets(ent.pev.targetname, ent, ent, USE_TYPE(WallEntities_Settings[w][1]));
									} else if(dist <= ent.pev.size.Length()*2) {
										g_EntityFuncs.FireTargets(ent.pev.targetname, ent, ent, USE_TYPE(WallEntities_Settings[w][2]));
										
										float pVecLen = pPlayer.pev.velocity.Length();
										Vector Vec = (player_origin - final_origin) * (dist/5);
										float VecLen = Vec.Length();
										
										if(Vec.x > multisource_velocity_limit) Vec.x = multisource_velocity_limit;
										if(Vec.y > multisource_velocity_limit) Vec.y = multisource_velocity_limit;
										if(Vec.z > multisource_velocity_limit) Vec.z = multisource_velocity_limit;
										
										if(pVecLen <= multisource_velocity_limit)
											pPlayer.pev.velocity = Vec;
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

void multisource_Door_Process() {
	//Go through the array
	for(uint i=0;i<multisource_DoorEntities.length();i++) {
		CBaseEntity@ ent = multisource_DoorEntities[i];
		//Check if the entity is not NULL
		if(ent !is null) {
			//Look for doors
			for(uint w=0;w<DoorEntities.length();w++) {
				if(ent.pev.classname == DoorEntities[w][0] && ent.pev.targetname == DoorEntities[w][1]) {
					//Convert this entity to CBaseDoor
					CBaseDoor@ stupidDoor = cast<CBaseDoor@>(ent);
					
					if(stupidDoor !is null) {
						//Look for nearby players
						array<CBaseEntity@>nearbyMonsters(5);
						g_EntityFuncs.MonstersInSphere(nearbyMonsters, stupidDoor.pev.origin, stupidDoor.pev.size.Length());
						for(uint m=0;m<nearbyMonsters.length();m++) {
							CBaseEntity@ monster = nearbyMonsters[m];
							if(monster !is null && monster.IsPlayer()) {
								CustomKeyvalues@ KeyValues = monster.GetCustomKeyvalues();
								int key_value1 = atoui(KeyValues.GetKeyvalue("$i_isHeadcrab").GetString());
								if(key_value1 == 0) {
									//g_Log.PrintF("------ Found Zombie  ------\n");
									multisource_remove(i);
								} else {
									//g_Log.PrintF("------ Found Headcrab  ------\n");
									multisource_recreate(i);
								}
								
								break;
							}
						}
					}
				}
			}
		}
	}
}