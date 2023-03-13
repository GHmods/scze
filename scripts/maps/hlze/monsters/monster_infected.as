/*
	Infected Monster
*/
#include "../classes/headcrab_classes"
#include "register"

array<string>Infect_Sounds = {
	"vox/zombie_pain1.wav",
	"vox/zombie_pain2.wav",
	"vox/zombie_pain3.wav",
	"vox/zombie_pain4.wav",
	"vox/zombie_pain5.wav",
	"vox/zombie_pain6.wav",
	"vox/zombie_pain7.wav"
};

array<string>Infectable = {
	"",
	"monster_scientist",
	//"monster_barney",
	"monster_hlze_barney",
	"monster_human_grunt"
};

enum InfectionType {
	INFECTED_NONE = 0,
	INFECTED_SCIENTIST,
	INFECTED_GUARD,
	INFECTED_HGRUNT,
	INFECTED_HGRUNT_MASKLESS,
	INFECTED_MASSN
};

array<string>InfectedModels = {
	"models/hlze/null.mdl",
	"models/hlze/scientist.mdl",
	"models/hlze/barney.mdl",
	"models/hlze/hgrunt.mdl"
};


//ZOMBIE BODY ID
array<int>InfectedZombieData = {
	0, //None
	0, //Scientist
	6, //Guard
	18, //Human Grunt With Mask
	12, //Human Grunt Without Mask
	4 //MASSN
};

array<string>InfectedPlayerModels = {
	"hlze_headcrab",
	"hlze_zombie_sci",
	"hlze_zombie_guard",
	"hlze_zombie_hgrunt",
	"hlze_zombie_hgrunt1"
};

void Register_Infected(const string& in szName = "monster_infected")
{
	if( g_CustomEntityFuncs.IsCustomEntity( szName ) )
		return;

	g_CustomEntityFuncs.RegisterCustomEntity( "Infected", szName );
	g_Game.PrecacheOther( szName );
	
	for(uint i=0;i<InfectedModels.length();i++)
		g_Game.PrecacheModel(InfectedModels[i]);
	
	for(uint i=0;i<InfectedPlayerModels.length();i++) {
		g_Game.PrecacheGeneric( "models/player/"+InfectedPlayerModels[i]+"/"+InfectedPlayerModels[i]+".bmp" );
		g_Game.PrecacheGeneric( "models/player/"+InfectedPlayerModels[i]+"/"+InfectedPlayerModels[i]+".mdl" );
		g_Game.PrecacheModel( "models/player/"+InfectedPlayerModels[i]+"/"+InfectedPlayerModels[i]+".mdl" );
	}
	
	g_Game.PrecacheModel( "models/hlze/zombie.mdl" );
	PrecacheSounds(Infect_Sounds);
}

class Infected : ScriptBaseMonsterEntity
{
	CBaseEntity@ Infector = null;
	private int Infection_State = 0;
	private float Infection_Timer = g_Engine.time;
	bool isInfectedByPlayer = false;
	CBasePlayer@ InfectorPlayer = null;
	
	//What Type?
	string infected_class = "nothing";
	int infected_type = -1;
	int zombie_body = -1;
	int infected_first_body = 0;
	
	//For Human Grunts
	bool zombie_isMaskLess = false;
	
	void Spawn()
	{
		//Precache Stuff
		Precache();
		
		//Bare Minimum for 1 Entity
		g_EntityFuncs.SetSize( self.pev, Vector( 0, 0, 0 ), Vector( 36, 36, 70 ) );
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
		self.pev.gravity = 1.0f;
		
		//BigProcess();
		
		//Used for Animation
		self.pev.animtime = g_Engine.time;
		self.pev.framerate = 1.0;
	}
	
	void BigProcess()
	{
		//Validate stuff before doing anything
		AS_Log("Trying to Infect: "+infected_class+"\n",LOG_LEVEL_HIGH);
		
		if(infected_class != "nothing") {
			for(uint i=0;i<Infectable.length();i++) {
				if(infected_class==Infectable[i]) {
					infected_type=i;
					break;
				}
			}
		} else {
			g_EntityFuncs.Remove(self);
			return;
		}
		
		if(infected_type == -1) {
			g_EntityFuncs.Remove(self);
			return;
		}
		
		//Set Model
		if(infected_type==INFECTED_SCIENTIST) {
			g_EntityFuncs.SetModel(self, InfectedModels[INFECTED_SCIENTIST]);
		} else if(infected_type==INFECTED_GUARD) {
			g_EntityFuncs.SetModel(self, InfectedModels[INFECTED_GUARD]);
		} else if(infected_type==INFECTED_HGRUNT) {
			g_EntityFuncs.SetModel(self, InfectedModels[INFECTED_HGRUNT]);
		} else {
			g_EntityFuncs.Remove(self);
			return;
		}
		
		//Body ID Depends on Infected Type
		//Get 'InfectionInfo' from Player's HClass
		Headcrab_Class@ pHClass = HClasses::Headcrab_Classes[0];

		if(isInfectedByPlayer && InfectorPlayer !is null) //Check if Infector is Player
		{
			@pHClass = Get_HeadcrabClass_FromPlayer(InfectorPlayer);
		}

		InfectionInfo@ infection_info = @pHClass.infection_info;

		AS_Log("Infected by: '"+pHClass.Name+"'.\n",LOG_LEVEL_HIGH);
		
		if(infected_type==INFECTED_SCIENTIST) {
			self.pev.skin = infection_info.SkinId_Scientist;
			for(uint b=0;b<infection_info.BodyScientist.length();b++) {
				self.SetBodygroup(
					infection_info.BodyScientist[b][0],
					infection_info.BodyScientist[b][1]
				);
			}
		} else if(infected_type==INFECTED_GUARD) {
			self.pev.skin = infection_info.SkinId_Guard;
			for(uint b=0;b<infection_info.BodyGuard.length();b++) {
				self.SetBodygroup(
					infection_info.BodyGuard[b][0],
					infection_info.BodyGuard[b][1]
				);
			}

			//Create Helmet
			CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("proj_barney_helmet");
			Proj_BarneyHelmet@ Projectile = cast<Proj_BarneyHelmet@>(CastToScriptClass(entBase));
			g_EntityFuncs.DispatchSpawn(Projectile.self.edict());
			Projectile.pev.origin = self.pev.origin + Vector(0,0,50);
			Projectile.pev.angles.y = self.pev.angles.y;
		} else if(infected_type==INFECTED_HGRUNT) {
			int dataID = INFECTED_HGRUNT;
			if(zombie_isMaskLess)
				dataID = INFECTED_HGRUNT_MASKLESS;
			
			if(dataID==INFECTED_HGRUNT) {
				self.pev.skin = infection_info.SkinId_HGrunt;
				for(uint b=0;b<infection_info.BodyHGrunt.length();b++) {
					self.SetBodygroup(
						infection_info.BodyHGrunt[b][0],
						infection_info.BodyHGrunt[b][1]
					);
				}
			} else {
				self.pev.skin = infection_info.SkinId_HGruntMaskless;
				for(uint b=0;b<infection_info.BodyHGruntMaskless.length();b++) {
					self.SetBodygroup(
						infection_info.BodyHGruntMaskless[b][0],
						infection_info.BodyHGruntMaskless[b][1]
					);
				}
			}
			infected_type = dataID;
		} else {
			g_EntityFuncs.Remove(self);
			return;
		}

		zombie_body = InfectedZombieData[infected_type];
		
		self.pev.set_controller(0,125);
		
		//Think
		SetThink(ThinkFunction(this.Infected_Think));
		self.pev.nextthink = g_Engine.time + 0.1;
	}
	
	void Infected_Think() {
		self.pev.nextthink = g_Engine.time + 0.1;
		
		if(isInfectedByPlayer) {
			//Make Player Invisible
			InfectorPlayer.pev.rendermode = kRenderTransAlpha;
			InfectorPlayer.pev.renderamt = 0;
			InfectorPlayer.pev.velocity = Vector(0.0,0.0,0.0);
			
			if(Infection_State==2) {
				if(InfectorPlayer !is null && !InfectorPlayer.IsAlive()) {
					InfectorPlayer.pev.flags &= ~FL_FROZEN;
					//Reset Player
					InfectorPlayer.ResetOverriddenPlayerModel(false,false);
					
					NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, InfectorPlayer.edict());
						m.WriteString("firstperson;");
					m.End();
					
					//Restore Player's Render Mode
					InfectorPlayer.pev.rendermode = kRenderNormal;
					InfectorPlayer.pev.renderfx = kRenderFxNone;
					InfectorPlayer.pev.renderamt = 255;

					//Remove GodMode
					InfectorPlayer.m_iEffectInvulnerable = 0;
					
					self.pev.framerate = 0.0;
					self.pev.body = infected_first_body;
					//g_EntityFuncs.Remove(self);
					SetThink(null);
					
					//Relocate Player
					Math.MakeVectors(self.pev.angles);
					Vector createOrigin = self.pev.origin;
					Vector createOrigin_fw = g_Engine.v_forward * 36.0;
					createOrigin_fw = createOrigin_fw - (g_Engine.v_right * 5.0);
					createOrigin = createOrigin + createOrigin_fw;
					InfectorPlayer.SetOrigin(Vector(createOrigin.x,createOrigin.y,createOrigin.z+36.0));
					
					return;
				}
			}
		}
		
		if(Infection_Timer < g_Engine.time) {
			if(Infection_State==0) {
				if(isInfectedByPlayer) {
					if(InfectorPlayer !is null && InfectorPlayer.IsAlive()) {
						InfectorPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;
					}
				}
				
				self.pev.animtime = g_Engine.time;
				self.pev.sequence = self.LookupSequence("zombify_begin");
				self.ResetSequenceInfo();
				Infection_State++;
				Infection_Timer = g_Engine.time + 3.1;
			} else if(Infection_State==1) {
				self.pev.animtime = g_Engine.time;
				self.pev.sequence = self.LookupSequence("zombify_continues");
				self.ResetSequenceInfo();
				Infection_State++;
				Infection_Timer = g_Engine.time + 15.0;
				return;
			} else if(Infection_State==2) {
				Vector createOrigin = self.pev.origin;
				Vector createOrigin_fw = g_Engine.v_forward * 10.0;
				createOrigin_fw = createOrigin_fw - g_Engine.v_right * 5.0;
				createOrigin = createOrigin - createOrigin_fw;
				
				self.pev.origin.x = createOrigin.x;
				self.pev.origin.y = createOrigin.y;
				
				g_EntityFuncs.SetModel( self, "models/hlze/zombie.mdl");
				self.pev.skin = 0;
				self.pev.body = zombie_body;
				
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, Infect_Sounds[Math.RandomLong(0,Infect_Sounds.length()-1)], 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
				self.pev.animtime = g_Engine.time;
				self.pev.sequence = self.LookupSequence("getup");
				self.ResetSequenceInfo();
				
				Infection_State++;
				Infection_Timer = g_Engine.time + 1.4;
				if(isInfectedByPlayer) {
					//Set GodMode
					InfectorPlayer.m_iEffectInvulnerable = 1;
				}

				return;
			} else if(Infection_State==3) {
				Vector createOrigin = self.pev.origin;
				Vector createOrigin_fw = g_Engine.v_forward * 10.0 - g_Engine.v_right * 5.0;
				
				createOrigin.x = createOrigin.x + createOrigin_fw.x;
				createOrigin.y = createOrigin.y + createOrigin_fw.y;
				
				Vector createAngles = self.pev.angles;
				
				if(Infector !is null) {
					if(isInfectedByPlayer) {
						if(InfectorPlayer !is null) {
							InfectorPlayer.pev.flags &= ~FL_FROZEN;
							//Reset Player
							InfectorPlayer.ResetOverriddenPlayerModel(false,false);
							
							NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, InfectorPlayer.edict());
								m.WriteString("firstperson;");
							m.End();
							
							InfectorPlayer.GiveNamedItem("weapon_zclaws");
							
							//Restore Player's Render Mode
							InfectorPlayer.pev.rendermode = kRenderNormal;
							InfectorPlayer.pev.renderfx = kRenderFxNone;
							InfectorPlayer.pev.renderamt = 255;
							
							//Remove GodMode
							InfectorPlayer.m_iEffectInvulnerable = 0;

							if(InfectorPlayer.IsAlive()) {
								InfectorPlayer.KeyValue("$i_infected_type",infected_type);
								InfectorPlayer.KeyValue("$i_infected_type_maskless",zombie_isMaskLess);
								SaveLoad_KeyValues::SaveData(InfectorPlayer.entindex()); //Save KeyValues
								InfectorPlayer.SetAnimation(PLAYER_IDLE);
								
								//Relocate Player
								InfectorPlayer.SetOrigin(Vector(createOrigin.x,createOrigin.y,createOrigin.z+36.0));
								InfectorPlayer.pev.angles = createAngles;
								InfectorPlayer.pev.v_angle = createAngles;
								InfectorPlayer.pev.fixangle = 0;
								InfectorPlayer.pev.velocity = Vector(0.0,0.0,0.0);
							}
						}
					} else {
						
						CBaseEntity@ zombieEnt = g_EntityFuncs.CreateEntity("monster_hlze_zombie");
						CBaseMonster@ zombieMonster = zombieEnt.MyMonsterPointer();
						HLZE_Zombie::CHLZE_Zombie@ zombie = cast<HLZE_Zombie::CHLZE_Zombie@>(CastToScriptClass(zombieEnt));
						
						zombie.pev.origin = createOrigin;
						zombie.pev.angles = createAngles;

						zombieMonster.SetPlayerAllyDirect(true);
						zombieMonster.StartPlayerFollowing(Infector, false);
						
						if(infected_type==INFECTED_SCIENTIST) zombieMonster.m_FormattedName = "Infected Scientist";
						else if(infected_type==INFECTED_GUARD) zombieMonster.m_FormattedName = "Infected Guard";
						else if(infected_type==INFECTED_HGRUNT) zombieMonster.m_FormattedName = "Infected Human Grunt";
						
						zombie.pev.body = zombie_body;
						zombie.Setup_Zombie(-1,true);
					}
				}
				g_EntityFuncs.Remove(self);
				return;
			}
		}
	}
	
	void Precache()
	{
		for(uint i=0;i<InfectedModels.length();i++)
			g_Game.PrecacheModel(InfectedModels[i]);
		
		g_Game.PrecacheModel( "models/hlze/zombie.mdl" );
		PrecacheSounds(Infect_Sounds);
		
		//Just in case the game not precaches this
		g_Game.PrecacheModel( "models/zombie.mdl" );
		g_Game.PrecacheModel( "models/zombie_barney.mdl" );
		g_Game.PrecacheModel( "models/zombie_soldier.mdl" );
	}
}