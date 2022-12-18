/*
	Infected Monster
*/

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
	"monster_scientist",
	"monster_barney",
	"monster_human_grunt"
};

enum InfectedType
{
	INFECTED_SCIENTIST = 0,
	INFECTED_GUARD,
	//INFECTED_MASSN,
	INFECTED_HGRUNT
};

array<string>InfectedModels = {
	"models/hlze/scientist.mdl",
	"models/hlze/barney.mdl",
	"models/hlze/hgrunt.mdl"
};

array<array<int>>InfectedData = {
	//BODY, SKIN, ZOMBIE BODY ID
		{4,2,0}, //Scientist
		{10,1,6}, //Guard
		{16,2,12}, //Human Grunt Without Mask
		{17,2,17} //Human Grunt With Mask
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

class Infected : ScriptBaseMonsterEntity {
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
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.solid = SOLID_NOT;
		self.pev.gravity = 1.0f;
		
		//BigProcess();
		
		//Used for Animation
		self.pev.animtime = g_Engine.time;
		self.pev.framerate = 1.0;
	}
	
	void BigProcess() {
		//Validate stuff before doing anything
		g_Log.PrintF("Trying to Infect: "+infected_class+"\n");
		
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
		if(infected_type==INFECTED_SCIENTIST) {
			self.pev.body = InfectedData[INFECTED_SCIENTIST][0];
			self.pev.skin = InfectedData[INFECTED_SCIENTIST][1];
			zombie_body = InfectedData[INFECTED_SCIENTIST][2];
		} else if(infected_type==INFECTED_GUARD) {
			self.pev.body = InfectedData[INFECTED_GUARD][0];
			self.pev.skin = InfectedData[INFECTED_GUARD][1];
			zombie_body = InfectedData[INFECTED_GUARD][2];
		} else if(infected_type==INFECTED_HGRUNT) {
			int dataID = INFECTED_HGRUNT+1;
			if(zombie_isMaskLess)
				dataID = INFECTED_HGRUNT;
			
			self.pev.body = InfectedData[dataID][0];
			self.pev.skin = InfectedData[dataID][1];
			zombie_body = InfectedData[dataID][2];
		} else {
			g_EntityFuncs.Remove(self);
			return;
		}
		
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
				Infection_State++;
				Infection_Timer = g_Engine.time + 3.1;
			} else if(Infection_State==1) {
				self.pev.animtime = g_Engine.time;
				self.pev.sequence = self.LookupSequence("zombify_continues");
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
				self.pev.sequence = self.LookupSequence("getup");;
				
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
						
						CBaseEntity@ zombie;
						@zombie = g_EntityFuncs.CreateEntity("monster_zombie");
						
						zombie.MyMonsterPointer().SetPlayerAllyDirect(true);
						
						zombie.pev.origin = createOrigin;
						zombie.pev.angles = createAngles;
						zombie.MyMonsterPointer().StartPlayerFollowing(Infector, false);
						
						if(infected_type==INFECTED_SCIENTIST) zombie.MyMonsterPointer().m_FormattedName = "Infected Scientist";
						else if(infected_type==INFECTED_GUARD) zombie.MyMonsterPointer().m_FormattedName = "Infected Guard";
						else if(infected_type==INFECTED_HGRUNT) zombie.MyMonsterPointer().m_FormattedName = "Infected Human Grunt";
						
						zombie.MyMonsterPointer().pev.body = zombie_body;
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

// Precaches an array of sounds
void PrecacheSounds( const array<string> pSound )
{
	for( uint i = 0; i < pSound.length(); i++ )
	{
		g_SoundSystem.PrecacheSound( pSound[i] );
		g_Game.PrecacheGeneric( "sound/" + pSound[i] );
		//g_Game.AlertMessage( at_console, "Precached: sound/" + pSound[i] + "\n" );
	}
}