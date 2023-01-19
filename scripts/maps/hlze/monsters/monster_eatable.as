/*
	Eatable Monsters
*/
#include "../weapons/weapon_zombie"
#include "../unstuck"

void Eatable_Process() {
	Register_Eatable();
	Eatable_Process_Loop();
}

void Eatable_Process_Loop() {
	//Find all eatable monsters
	array<CBaseEntity@>Monsters(50);
	g_EntityFuncs.MonstersInSphere(Monsters, Vector(0,0,0), 99999.0);
	
	for(uint i=0;i<Monsters.length();i++) {
		CBaseEntity@ ent = Monsters[i];
		CBaseMonster@ monster;
		//Check if the entity is not NULL
		if(ent !is null) {
			if(ent.IsMonster())
				@monster = ent.MyMonsterPointer();
			//Check if this monster is Eatable
			for(uint i1=0;i1<Eatable_Alive.length();i1++) {
				if(ent.pev.classname == Eatable_Alive[i1] && !ent.IsAlive() && monster.GetIdealState() == MONSTERSTATE_DEAD) {
					//Make sure this monster is dead
					Convert_Eatable(monster);
				}
			}
		}
	}
	
	//Performance Fix
	g_Scheduler.SetTimeout("Eatable_Process_Loop", 0.1);
}

void Convert_Eatable(CBaseMonster@ monster) {
	if(monster is null) {
		return;
	}
	//If Eatable Monster is in 'MONSTERSTATE_DEAD' mode
	//if(monster.m_MonsterState == MONSTERSTATE_DEAD && (monster.pev.flags & FL_ONGROUND) != 0) {
	if(monster.m_MonsterState == MONSTERSTATE_DEAD) {
		//Create Eatable Monster
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("monster_eatable");
		script_monster_eatable@ eatableMonster = cast<script_monster_eatable@>(CastToScriptClass(entBase));
		g_EntityFuncs.DispatchSpawn(eatableMonster.self.edict());
		
		eatableMonster.CopyMonster(monster);
	}
}

//Now here is the entity
void Register_Eatable(const string& in szName = "monster_eatable")
{
	if(g_CustomEntityFuncs.IsCustomEntity(szName))
		return;

	g_CustomEntityFuncs.RegisterCustomEntity("script_monster_eatable",szName);
	g_Game.PrecacheOther(szName);
}

class script_monster_eatable : ScriptBaseMonsterEntity
{
	void Spawn()
	{
		//Monster Stuff
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_GREEN;
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.MonsterInit();
		self.m_FormattedName = "Eatable Monster";
		self.SetClassification(CLASS_ALIEN_MONSTER);
		self.SetPlayerAlly(false);
	}

	int Classify() {
		return CLASS_HUMAN_PASSIVE;
	}
	
	void CopyMonster(CBaseMonster@ monster) {
		//Setup
		Setup_Eatable(monster.pev.model,monster.pev.skin,monster.pev.body,
				monster.pev.origin,monster.pev.velocity,monster.pev.angles,monster.BloodColor());
		//Animate
		self.TakeDamage(self.pev,self.pev,100.0,DMG_SLASH|DMG_NEVERGIB);
		self.pev.health = 7.0;
		self.SetActivity(monster.m_Activity);
		//Animate_Eatable(monster.pev.frame,monster.pev.framerate,monster.pev.animtime);

		//Remove the monster
		g_EntityFuncs.Remove(monster);
	}
	
	void Setup_Eatable(string model,int skin,int body,Vector createOrigin,Vector velocity,Vector createAngles,int bc) {
		g_EntityFuncs.SetModel(self,model);
		g_EntityFuncs.SetSize(self.pev,Vector(-9,-18,0),Vector(9,18,9));
		
		self.pev.skin = skin;
		self.pev.body = body;
		
		//createOrigin.z += 18.0;
		self.pev.origin = createOrigin;
		self.pev.velocity = velocity;
		self.pev.angles = createAngles;
		
		self.m_bloodColor = bc;
		
		self.pev.takedamage = DAMAGE_YES;

		// Do Not Remove This Monster on Death
		//SF_MONSTER_FADECORPSE = 512;
		self.pev.spawnflags |= 512;
		
		self.pev.set_controller(0,125);

		//Set Thinking
		SetThink(ThinkFunction(this.Eatable_Think));
	}
	
	void Animate_Eatable(float frame, float framerate, float animtime) {
		self.pev.frame = frame;
		self.pev.framerate = framerate;
		self.pev.animtime = animtime;
	}
	
	//Thinking
	void Eatable_Think() {
		self.pev.nextthink = g_Engine.time + 0.1;
		self.pev.origin = Unstuck::GetUnstuckPosition(self.pev.origin,self,human_hull,2.0);
		//Unstuck::UnstuckEntity(self);

		//Remove
		if((self.pev.effects & EF_NODRAW) != 0)
			g_EntityFuncs.Remove(self); //Remove the monster
	}
}