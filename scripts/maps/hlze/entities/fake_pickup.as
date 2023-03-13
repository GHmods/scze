/*  
* fake_pickup
	* This is used to fake pickups by spawning duplicate entity with same size and model as the real entity
*/

#include "../pvpvm/pvpvm"//PVPVM
//Humans can pickup weapons/ammo/items, right?
#include "../unstuck"//PVPVM
#include "multisource"//Multisource manager

array<string>IgnoreEntities = {
	//classname
	"weapon_hclaws",
	"weapon_zclaws",
	"weapon_zhcrab",
	"ammo_headcrabs",
	"weapon_zbcrab",
	"ammo_babycrabs",
	"weapon_zombie_barnacle",
	"ammo_barnacle"
};

enum PickupTypes {
	PICKUP_WPN,
	PICKUP_AMMO,
	PICKUP_ITEM
};

int replaced_entities = 0; //Replaced Entities Counter
int ignored_entities = 0; //Ignored Entities Counter
float fakepickup_frequency = 0.1; //Optimization

void fake_pickup_Init() {
	//Precache this Entity
	g_CustomEntityFuncs.RegisterCustomEntity( "script_fake_pickup", "fake_pickup" );
	g_Game.PrecacheOther("fake_pickup");
	
	//Do the Big Part
	g_Scheduler.SetTimeout("fake_pickup_Process", 2.0);
	
	AS_Log("[Fake Pickup System] Initialized!\n");
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
	
	void Setup_Pickup(string model, Vector createOrigin, Vector createAngles, string pickName) {
		g_EntityFuncs.SetModel(self,model);
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
		bool debug = (cvar_Log_System>=LOG_LEVEL_EXTREME);
		
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
	//Search for all entities
	array<CBaseEntity@>searchedEntities(800);
	Vector mins = Vector(-99999999.0,-99999999.0,-99999999.0);
	Vector maxs = Vector(99999999.0,99999999.0,99999999.0);
	g_EntityFuncs.EntitiesInBox(searchedEntities, mins, maxs, 0);
	
	int found_ents = 0;
	for(uint i=0;i<searchedEntities.length();i++)
	{
		CBaseEntity@ ent = searchedEntities[i];
		bool brk = false;

		for(uint w=0;w<IgnoreEntities.length();w++) {
			if(ent is null || ent.pev.classname == IgnoreEntities[w]) {
				brk = true;
				break;
			}
		}
		//Check if the entity is not NULL
		//if(ent !is null && brk)
		if(!brk)
		{
			found_ents++;
			string cName = ent.pev.classname;
			string mName = cName.Split("_")[0];

			CBasePlayerWeapon@ pWpn = cast<CBasePlayerWeapon>(ent);
			CBasePlayerAmmo@ pAmmo = cast<CBasePlayerAmmo>(ent);
			CBasePlayerItem@ pItem = cast<CBasePlayerItem>(ent);

			CBaseEntity@ pOwner = g_EntityFuncs.Instance(ent.pev.owner);
			CBasePlayer@ pPlayer = cast<CBasePlayer>(pOwner);

			if(mName=="weapon"||mName=="ammo"||mName=="item" && !brk) {
				if(pOwner is null || pPlayer is null)
				{
					CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("fake_pickup");
					script_fake_pickup@ fakePickup = cast<script_fake_pickup@>(CastToScriptClass(entBase));
					g_EntityFuncs.DispatchSpawn(fakePickup.self.edict());
					
					fakePickup.Setup_Pickup(ent.pev.model, ent.pev.origin, ent.pev.angles,ent.pev.classname);

					g_EntityFuncs.Remove(ent);
				}
			}
		}
	}

	AS_Log("[Fake Pickup System] Found:"+found_ents+" Weapons/Ammo/Items.\n",LOG_LEVEL_EXTREME);

	g_Scheduler.SetTimeout("fake_pickup_Process", fakepickup_frequency);
}