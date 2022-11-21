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
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		//Monster Stuff
		self.MonsterInitDead();
		
		self.SetPlayerAlly(false);
	}
	
	int	Classify()
	{
		return self.GetClassification(CLASS_HUMAN_MILITARY);
	}
	
	void CopyMonster(CBaseMonster@ monster) {
		//Copy PEV
		self.pev.origin = monster.pev.origin;
		self.pev.oldorigin = monster.pev.oldorigin;
		self.pev.velocity = monster.pev.velocity;
		self.pev.basevelocity = monster.pev.velocity;
		self.pev.movedir = monster.pev.movedir;
		self.pev.angles = monster.pev.angles;
		self.pev.avelocity = monster.pev.avelocity;
		self.pev.impacttime = monster.pev.impacttime;
		self.pev.starttime = monster.pev.starttime;
		self.pev.fixangle = monster.pev.fixangle;
		self.pev.model = monster.pev.model;
		self.pev.absmin = monster.pev.absmin;
		self.pev.absmax = monster.pev.absmax;
		self.pev.mins = monster.pev.mins;
		self.pev.maxs = monster.pev.maxs;
		//self.pev.solid = monster.pev.solid;
		self.pev.skin = monster.pev.skin;
		self.pev.body = monster.pev.body;
		self.pev.effects = monster.pev.effects;
		self.pev.gravity = monster.pev.gravity;
		//self.pev.friction = monster.pev.friction;
		self.pev.sequence = monster.pev.sequence;
		self.pev.gaitsequence = monster.pev.gaitsequence;
		self.pev.frame = monster.pev.frame;
		self.pev.animtime = monster.pev.animtime;
		self.pev.framerate = monster.pev.framerate;
		self.pev.scale = monster.pev.scale;
		self.pev.rendermode = monster.pev.rendermode;
		self.pev.renderamt = monster.pev.renderamt;
		self.pev.rendercolor = monster.pev.rendercolor;
		self.pev.renderfx = monster.pev.renderfx;
		self.pev.flags = monster.pev.flags;
		
		//Setup
		Setup_Eatable(monster.pev.model,monster.pev.mins,monster.pev.maxs,monster.pev.skin,monster.pev.body,
										monster.pev.origin,monster.pev.velocity,monster.pev.angles,monster.BloodColor());
		//Animate
		Animate_Eatable(monster.pev.frame,monster.pev.framerate,monster.pev.animtime,monster.pev.sequence);
		
		//Remove the monster
		g_EntityFuncs.Remove(monster);
	}
	
	void Setup_Eatable(string model,Vector mins,Vector maxs,int skin,int body,Vector createOrigin,Vector velocity,Vector createAngles,int bc) {
		g_EntityFuncs.SetModel(self,model);
		//g_EntityFuncs.SetSize(self.pev,mins,maxs);
		g_EntityFuncs.SetSize(self.pev,Vector(-2,-2,0),Vector(2,2,18));
		
		self.pev.skin = skin;
		self.pev.body = body;
		
		//createOrigin.z += 18.0;
		self.pev.origin = createOrigin;
		self.pev.velocity = velocity;
		self.pev.angles = createAngles;
		
		self.m_bloodColor = bc;
		
		//self.SetObjectCollisionBox();
		
		self.pev.health = 1.5;
		self.pev.takedamage = DAMAGE_YES;
		
		if(string(self.m_FormattedName).IsEmpty())
		{
			self.m_FormattedName = "Eatable";
		}
		
		self.pev.set_controller(0,125);
		
		//Set Thinking
		SetThink(ThinkFunction(this.Eatable_Think));
	}
	
	void Animate_Eatable(float frame, float framerate, float animtime, int sequence) {
		self.pev.frame = frame;
		self.pev.framerate = framerate;
		//self.pev.animtime = animtime;
		self.pev.animtime = g_Engine.time + 0.1;
		self.pev.sequence = sequence;
	}
	
	//Thinking
	void Eatable_Think() {
		self.pev.nextthink = g_Engine.time + 0.1;
		
		Unstuck::UnstuckEntity(self);
	}
}