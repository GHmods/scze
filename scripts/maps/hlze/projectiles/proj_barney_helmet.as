//Projectile for Baby Barnacle
//------------------------------
#include "proj_barnacle_baby"
#include "../unstuck"

const string MODEL_BARNEY_HELMET = "models/hlze/barney_helmet.mdl";
array<string>BHelmet_Sounds = {
	"debris/metal7.wav", //START
	"debris/metal1.wav",
	"debris/metal2.wav",
	"debris/metal3.wav",
	"debris/metal4.wav",
	"debris/metal6.wav"
};

void proj_barney_helmet_Init() {
	//Precache this Entity
	g_CustomEntityFuncs.RegisterCustomEntity( "Proj_BarneyHelmet", "proj_barney_helmet" );
	g_Game.PrecacheOther("proj_barney_helmet");
	proj_barney_helmet_Precache();
}

void proj_barney_helmet_Precache() {
	g_Game.PrecacheModel(MODEL_BARNEY_HELMET);
        PrecacheSounds(BHelmet_Sounds);
}

class Proj_BarneyHelmet : Proj_BabyBarnacle {
        void Spawn()
	{
		Precache();
               	g_EntityFuncs.SetModel(self, MODEL_BARNEY_HELMET);
		self.pev.scale = 1.0;

                self.pev.movetype = MOVETYPE_TOSS;
                self.pev.gravity = 1.0f;
                self.pev.solid = SOLID_NOT;

                g_EntityFuncs.SetSize(self.pev,Vector(-8.0,-8.0,0.0),Vector(8.0,8.0,8.0));

		Proj_Begin();
        }

	void Proj_Begin()
	{
		Throwing_State = BB_PROJ_START; //Start
		//Sound
		g_SoundSystem.PlaySound( self.edict(), CHAN_WEAPON, BHelmet_Sounds[0], 1.0f, ATTN_NORM, 0, 120, 0, false, self.pev.origin);
		Launch();
	}

	void Launch() {
		self.pev.movetype = MOVETYPE_TOSS;
		Math.MakeVectors(self.pev.angles);
		self.pev.velocity = self.pev.velocity + g_Engine.v_up * 200.0 + Vector(Math.RandomFloat(-80.0,80.0),Math.RandomFloat(-80.0,80.0),0.0);
		Throwing_State = BB_PROJ_IN_AIR;

		SetTouch(TouchFunction(this.My_BounceTouch));
                SetThink(ThinkFunction(this.My_Think));
		self.pev.nextthink = g_Engine.time + 0.1;
	}

  	void My_Think() {
		self.pev.nextthink = g_Engine.time + 0.1;
               	self.pev.angles = Math.VecToAngles(self.pev.velocity) + Vector(90,0,0);

                //FadeOut if this entity stopped
                if(self.pev.velocity.Length() < 0.5)
                {
			if(Throwing_State == BB_PROJ_IN_AIR) {
				//Unstuck
				self.pev.origin = Unstuck::GetUnstuckPosition(self.pev.origin,self);
				
				Create_Decal(Math.RandomLong(DECAL_BLOOD1,DECAL_BLOOD6));

				self.pev.movetype = MOVETYPE_TOSS;
				Throwing_State = BB_PROJ_FAIL;

				self.pev.rendermode = kRenderTransAlpha;
				self.pev.renderfx = kRenderFxNone;
				self.pev.rendercolor = Vector(255,255,255);
				self.pev.renderamt = 255;

				self.pev.nextthink = g_Engine.time + 15.0;
			}
			if(Throwing_State == BB_PROJ_FAIL) {
				if(self.pev.renderamt-10 > 0) {
					self.pev.renderamt-=10;
				} else RemoveEntity();
			}
			return;
                } else {
			if(checkTimer<g_Engine.time) {
				checkTimer = g_Engine.time + checkFrequence;
				Create_Decal(Math.RandomLong(DECAL_BLOOD1,DECAL_BLOOD6));
			}
		}
        }

        void RemoveEntity()
	{
		self.pev.effects |= EF_NODRAW;
		g_EntityFuncs.Remove(self);
	}

        void My_BounceTouch(CBaseEntity@ pOther)
	{
		// don't hit the guy that launched this grenade
		if(@pOther.edict() == @self.pev.owner)
			return;

		if(Throwing_State == BB_PROJ_IN_AIR) {
			DoDamage(self.pev.origin,self.pev.size.Length(),0.1,DMG_CRUSH|DMG_NEVERGIB);
			g_Utility.Ricochet(self.pev.origin,self.pev.size.Length());
			g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, BHelmet_Sounds[1], 1.0f, ATTN_NORM, 0, PITCH_NORM, 0, false, self.pev.origin);
		}
	}

        void Precache()
	{
		BaseClass.Precache();
		proj_barney_helmet_Precache();
	}
}