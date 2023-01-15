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
		g_EntityFuncs.SetSize( self.pev,Vector(0,0,0),Vector(36,36,70));
		self.pev.movetype = MOVETYPE_TOSS;
		//self.pev.solid = SOLID_BBOX;
		self.pev.solid = SOLID_NOT;
		self.pev.gravity = 1.0f;
	}
	
	void BigProcess() {
		//Validate stuff before doing anything
		if(infected_type == -1) {
			g_EntityFuncs.Remove(self);
			return;
		}
		
		//Body ID Depends on Infected Type
		if(infected_type==INFECTED_SCIENTIST||infected_type==INFECTED_NONE) {
			self.pev.body=0;
		} else if(infected_type==INFECTED_GUARD) {
			self.pev.body=1;
		} else if(infected_type==INFECTED_HGRUNT || infected_type==INFECTED_HGRUNT_MASKLESS) {
			if(infected_maskless==1) self.pev.body=2;
			else self.pev.body=3;
		} else {
			g_EntityFuncs.Remove(self);
			return;
		}
		
		//Fake Monster
		self.MonsterInit();
		self.m_MonsterState = MONSTERSTATE_PLAYDEAD;
		//Used for Animation
		self.pev.sequence = self.LookupSequence("dieheadshot");
		self.pev.frame = 0;
		self.pev.framerate = 1.0;
		self.pev.effects = self.pev.effects | EF_NOINTERP;
		self.pev.animtime = g_Engine.time;
		self.ResetSequenceInfo();
		//Think
		self.pev.nextthink = g_Engine.time + 0.1;
	}
	
	void Think() {
		self.pev.nextthink = g_Engine.time + 0.1;

		//States
		if(InfectionTimer<g_Engine.time) {
			if(Infection_State==0) {
				Infection_State++;
				InfectionTimer = g_Engine.time + 1.0;
			} else if(Infection_State==1) {
				Infection_State++;
				self.pev.solid = SOLID_NOT;
			}
		}
	}
	
	void Precache()
	{
		g_Game.PrecacheModel("models/hlze/zombie_body.mdl");
	}
}