/*
	This Entity creates when you leave infected body
*/

#include "monster_infected"

void Register_Infected_Leaved(const string& in szName = "monster_infected_leaved")
{
	if( g_CustomEntityFuncs.IsCustomEntity( szName ) )
		return;

	g_CustomEntityFuncs.RegisterCustomEntity( "Infected_Leaved", szName );
	g_Game.PrecacheOther( szName );
	
	g_Game.PrecacheModel("models/hlze/zombie_body.mdl");
}

class Infected_Leaved : ScriptBaseMonsterEntity {
	//Process
	private int Infection_State = 0;
	float InfectionTimer = g_Engine.time;
	//What Type?
	int infected_type = -1;
	int infected_maskless = -1;
	
	void Spawn()
	{
		//Precache Stuff
		Precache();
		
		//Bare Minimum for 1 Entity
		g_EntityFuncs.SetModel(self,"models/hlze/zombie_body.mdl");
		g_EntityFuncs.SetSize(self.pev,VEC_HUMAN_HULL_MIN,VEC_HUMAN_HULL_MAX);
		
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = BLOOD_COLOR_GREEN;
		self.pev.health = 100.0;
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.MonsterInit();
		self.m_FormattedName = "Infected Corpse";
		self.SetClassification(CLASS_ALIEN_MONSTER);
	}
	
	void BigProcess() {
		//Validate stuff before doing anything
		if(infected_type == -1) {
			g_EntityFuncs.Remove(self);
			return;
		}
		
		//Body ID Depends on Infected Type
		if(infected_type==INFECTED_SCIENTIST) {
			self.pev.body=0;
		} else if(infected_type==INFECTED_GUARD) {
			self.pev.body=1;
		} else if(infected_type==INFECTED_HGRUNT || infected_type==INFECTED_HGRUNT_MASKLESS) {
			if(infected_maskless==1) self.pev.body=2;
			else self.pev.body=3;
		} else {
			//g_EntityFuncs.Remove(self);
			self.pev.body=0;
		}
		
		self.pev.origin = Unstuck::GetUnstuckPosition(self.pev.origin,self,human_hull,1.0);

		//Try to kill this "Monster"
		self.SetActivity(ACT_DIE_HEADSHOT);
		self.TakeDamage(self.pev.owner.vars,self.pev.owner.vars,100.0,DMG_SLASH|DMG_NEVERGIB);
	}
	
	void Precache()
	{
		g_Game.PrecacheModel("models/hlze/zombie_body.mdl");
	}
}