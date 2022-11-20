/*  
* fake_pickup
	* This is used to fake pickups by spawning duplicate entity with same size and model as the real entity
*/

#include "../pvpvm/pvpvm"//PVPVM
//Humans can pickup weapons/ammo/items, right?
#include "../unstuck"//PVPVM

array<string>IgnoreEntities = {
	//classname
	"weapon_hclaws",
	"weapon_zclaws"
};

enum PickupTypes {
	PICKUP_WPN,
	PICKUP_AMMO,
	PICKUP_ITEM
};

int replaced_entities = 0; //Replaced Entities Counter
int ignored_entities = 0; //Ignored Entities Counter

void fake_pickup_Init() {
	//Precache this Entity
	g_CustomEntityFuncs.RegisterCustomEntity( "script_fake_pickup", "fake_pickup" );
	g_Game.PrecacheOther("fake_pickup");
	
	//Do the Big Part
	g_Scheduler.SetTimeout( "fake_pickup_Process", 2.0);
	
	g_Log.PrintF("[Fake Pickup System] Initialized!\n");
}

class script_fake_pickup : ScriptBaseMonsterEntity {	
	string pickup_name = "null";
	int pickup_type = -1;
	
	void Spawn()
	{
		//No need for Precaching Stuff............
		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_BBOX;
		self.pev.gravity = 1.0f;
	}
	
	void Setup_Pickup(string model, Vector mins, Vector maxs, Vector createOrigin, Vector createAngles, string pickName) {
		g_EntityFuncs.SetModel(self,model);
		//g_EntityFuncs.SetSize(self.pev, mins, maxs);
		g_EntityFuncs.SetSize(self.pev, Vector(-10,-10,0), Vector(10,10,5));
		createOrigin.z += 5.0;
		self.pev.origin = createOrigin;
		self.pev.angles = createAngles;
		
		SetTouch(TouchFunction(EntTouch));
		pickup_name = pickName;
		
		string cName = pickup_name;
		string mName = cName.Split("_")[0];
		if(mName=="ammo") pickup_type = PICKUP_WPN;
		else if(mName=="item") pickup_type = PICKUP_ITEM;
		else if(mName=="weapon") pickup_type = PICKUP_WPN;
	}
	
	//When Player touches this, give him item with name: 'pickup_name';
	void EntTouch(CBaseEntity@ pOther) //Work in Progress
	{
		bool debug = false;
		
		if(debug) Log("Touch....");
		if(debug) Log("0%....",false);
		if(pickup_name == "null" || pickup_type <= -1)
		{
			if(debug) Log("\n",false);
			return;
		}
		
		if(debug) Log("2%....",false);
		
		if(pOther is null || !pOther.IsPlayer())
		{
			if(debug) Log("\n",false);
			return;
		}
		
		if(debug) Log("5%....",false);
		
		int pId = pOther.entindex();
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(pId);
		
		if(pPlayer is null)
		{
			if(debug) Log("\n",false);
			return;
		}
		
		if(debug) Log("22%....",false);
		
		bool failed = true;
		
		
		//If this is human, remove this ent, and give 'pickup_name';
		//And if player is pressing +USE key
		int pKey = pPlayer.pev.button;
		
		if(pvpvm::TeamChosen[pId] == PVPVM_HUMAN && (pKey & IN_USE)!=0)
		{
			if(debug) Log("33%....",false);
			//Try and pickup weapon
			if(pickup_type == PICKUP_WPN) {
				if(pPlayer.HasNamedPlayerItem(pickup_name) is null) {
					if(debug) Log("75%....",false);
					pPlayer.GiveNamedItem(pickup_name);
					g_EntityFuncs.Remove(self);
					failed=false;
				}
			} else if(pickup_type == PICKUP_AMMO) { //Try and pickup ammo
				if(debug) Log("50%....",false);
				if(pPlayer.HasNamedPlayerItem(pickup_name) is null) {
					if(debug) Log("60%....",false);
					pPlayer.GiveNamedItem(pickup_name);
					g_EntityFuncs.Remove(self);
					failed=false;
				} else if(pPlayer.GiveAmmo((pPlayer.HasNamedPlayerItem(pickup_name).GetWeaponPtr().m_iDefaultAmmo)/2,pickup_name,pPlayer.GetMaxAmmo(pickup_name))!=-1) {
					if(debug) Log("55%....",false);
					//pPlayer.GiveNamedItem(pickup_name);
					g_EntityFuncs.Remove(self);
					failed=false;
				}
			} else if(pickup_type == PICKUP_ITEM) { //Try and pickup item
				if(debug) Log("65%....",false);
				if(pPlayer.HasNamedPlayerItem(pickup_name) is null) {
					if(debug) Log("70%....",false);
					pPlayer.GiveNamedItem(pickup_name);
					g_EntityFuncs.Remove(self);
					failed=false;
				}
			}
			
			if(debug) Log("90%....",false);
		}
		
		if(failed) {
			if(debug)
				Log("Failed!\n",false);
		} else {
			if(debug)
				Log("100%....Succeeded!\n",false);
		}
	}
}

void fake_pickup_Process() {
	//Our Entity Holder
	CBaseEntity@ wpn = g_EntityFuncs.FindEntityInSphere(wpn, Vector(0,0,0), 999999.0, "weapon_*", "classname"); 
	if(wpn !is null)
	{
		//Ignore Entities if the weapon is used by player or use the data from this array
		for(uint i=0;i<IgnoreEntities.length();i++) {
			//Try to Convert it to CBasePlayerWeapon
			CBasePlayerWeapon@ pWpn = cast<CBasePlayerWeapon>(wpn);
			if(pWpn !is null) {
				CBaseEntity@ pEnt = pWpn.m_hPlayer.GetEntity();
				CBasePlayer@ pPlayer = cast<CBasePlayer>(pEnt);
				
				if(pWpn.m_hPlayer.GetEntity() is null && wpn.pev.classname != IgnoreEntities[i]) {
				//if(pPlayer !is null && wpn.pev.classname != IgnoreEntities[i]) {
					CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("fake_pickup");
					script_fake_pickup@ fakePickup = cast<script_fake_pickup@>(CastToScriptClass(entBase));
					g_EntityFuncs.DispatchSpawn(fakePickup.self.edict());
				
					fakePickup.Setup_Pickup(wpn.pev.model, wpn.pev.mins, wpn.pev.maxs, wpn.pev.origin, wpn.pev.angles,wpn.pev.classname);
				
					g_EntityFuncs.Remove(wpn);
					replaced_entities++;
					break;
				} else ignored_entities++;
			}
		}
	}
	
	//Search for Ammo
	CBaseEntity@ ammo = g_EntityFuncs.FindEntityInSphere(ammo, Vector(0,0,0), 999999.0, "ammo_*", "classname"); 
	if(ammo !is null)
	{
		//Create The Fake Pickup
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("fake_pickup");
		script_fake_pickup@ fakePickup = cast<script_fake_pickup@>(CastToScriptClass(entBase));
		g_EntityFuncs.DispatchSpawn(fakePickup.self.edict());
		
		fakePickup.Setup_Pickup(ammo.pev.model, ammo.pev.mins, ammo.pev.maxs, ammo.pev.origin, ammo.pev.angles,ammo.pev.classname);
		
		g_EntityFuncs.Remove(ammo);
		replaced_entities++;
	}
	//Search for Items
	CBaseEntity@ item = g_EntityFuncs.FindEntityInSphere(item, Vector(0,0,0), 999999.0, "item_*", "classname"); 
	if(item !is null)
	{
		//Create The Fake Pickup
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("fake_pickup");
		script_fake_pickup@ fakePickup = cast<script_fake_pickup@>(CastToScriptClass(entBase));
		g_EntityFuncs.DispatchSpawn(fakePickup.self.edict());
		
		fakePickup.Setup_Pickup(item.pev.model, item.pev.mins, item.pev.maxs,item.pev.origin,item.pev.angles,item.pev.classname);
		
		g_EntityFuncs.Remove(item);
		replaced_entities++;
	}
	
	if(wpn is null && ammo is null && item is null) {
		//Debug
		//g_Log.PrintF("[Fake Pickup System] Replaced: "+replaced_entities+" Weapons/Ammo/Items --------\n");
		//g_Log.PrintF("[Fake Pickup System] Ignored: "+ignored_entities+" Weapons/Ammo/Items --------\n");
	}
	
	g_Scheduler.SetTimeout("fake_pickup_Process", 0.1);
}