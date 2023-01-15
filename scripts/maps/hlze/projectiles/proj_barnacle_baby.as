//Projectile for Baby Barnacle
//------------------------------
#include "../monsters/monster_barnacle"
#include "../unstuck"

//Acid Bolts
array<string>BarnacleThrow_Sounds = {
	"barnacle/bcl_alert2.wav", //START
	"bullchicken/bc_spithit1.wav", //FAIL
	"barnacle/bcl_chew3.wav" //SUCCEED
};

void proj_baby_barnacle_Init() {
	//Precache this Entity
	g_CustomEntityFuncs.RegisterCustomEntity( "Proj_BabyBarnacle", "proj_baby_barnacle" );
	g_CustomEntityFuncs.RegisterCustomEntity( "Proj_BabyBarnacle_Fx", "proj_baby_barnacle_fx" );
	g_Game.PrecacheOther("proj_baby_barnacle");
	proj_baby_barnacle_Precache();
}

void proj_baby_barnacle_Precache() {
        g_Game.PrecacheModel("sprites/spray.spr");
        g_Game.PrecacheModel("sprites/bhit.spr");
        PrecacheSounds(BarnacleThrow_Sounds);
}

enum Proj_BabyBarnacleThrowingState
{
	BB_PROJ_NONE,
	BB_PROJ_START,
	BB_PROJ_IN_AIR,
	BB_PROJ_FAIL,
	BB_PROJ_SUCCEED
};

class Proj_BabyBarnacle : ScriptBaseMonsterEntity {
	//Timers
        float checkTimer = g_Engine.time;
        float checkFrequence = 0.2;
	//State
	int Throwing_State = BB_PROJ_NONE;

        void Spawn()
	{
		Precache();
               	g_EntityFuncs.SetModel( self, W_MODEL_ZOMBIE_BARNACLE);
		self.pev.scale = 1.0;

                self.pev.movetype = MOVETYPE_TOSS;
                self.pev.gravity = 0.8f;
                self.pev.solid = SOLID_BBOX;
                
                self.pev.dmg = 0.1;
                self.pev.dmgtime = g_Engine.time + 5.0;

                g_EntityFuncs.SetSize(self.pev,Vector(-15.0,-15.0,-15.0),Vector(15.0,15.0,15.0));

		Proj_Begin();
        }

	void Proj_Begin()
	{
		Throwing_State = BB_PROJ_START; //Start
		//Sound
		g_SoundSystem.PlaySound( self.edict(), CHAN_WEAPON, BarnacleThrow_Sounds[0], 1.0f, ATTN_NORM, 0, 120, 0, false, self.pev.origin);
		
		SetTouch(TouchFunction(this.BounceTouch));
                SetThink(ThinkFunction(this.Proj_Think));
		self.pev.nextthink = g_Engine.time + 0.1;
	}

        void Create_Sprite(string sprite="sprites/bhit.spr",array<int>rgba_color={255,255,0,250})
	{
		CSprite@ ourSprite = g_EntityFuncs.CreateSprite(sprite, self.pev.origin + Vector(0,0,5), false, 1.0 );
		ourSprite.SetTransparency(kRenderTransAdd,rgba_color[0],rgba_color[1],rgba_color[2],rgba_color[3],kRenderFxNone);
		
		ourSprite.pev.velocity = self.pev.velocity + Vector(Math.RandomFloat(-50.0,50.0),Math.RandomFloat(-50.0,50.0),Math.RandomFloat(25.0,150.0));
		ourSprite.SetScale(self.pev.scale);
		ourSprite.AnimateAndDie(30);
	}

	void Create_Decal(int DecalNum) {
		TraceResult tr;
		Math.MakeVectors(self.pev.angles);
		g_Utility.TraceLine(self.GetOrigin(),self.GetOrigin()+g_Engine.v_forward*32,ignore_monsters,self.edict(),tr);
                g_Utility.DecalTrace(tr,DecalNum);
		//Up,Down,Left,Right
                g_Utility.TraceLine(self.GetOrigin(),self.GetOrigin()+Vector(0,0,32),ignore_monsters,self.edict(),tr);
                g_Utility.DecalTrace(tr,DecalNum);
		g_Utility.TraceLine(self.GetOrigin(),self.GetOrigin()+Vector(0,0,-32),ignore_monsters,self.edict(),tr);
                g_Utility.DecalTrace(tr,DecalNum);
		g_Utility.TraceLine(self.GetOrigin(),self.GetOrigin()-g_Engine.v_right*32,ignore_monsters,self.edict(),tr);
                g_Utility.DecalTrace(tr,DecalNum);
		g_Utility.TraceLine(self.GetOrigin(),self.GetOrigin()+g_Engine.v_right*32,ignore_monsters,self.edict(),tr);
                g_Utility.DecalTrace(tr,DecalNum);
	}

	void DoDamage(Vector Location,float Radius=30.0,float damage=5.0,int dmgType=DMG_POISON) {
		entvars_t@ pevOwner;
		if(self.pev.owner !is null)
			@pevOwner = @self.pev.owner.vars;
		else
			@pevOwner = self.pev;
                
                //g_WeaponFuncs.RadiusDamage(Location,self.pev,pevOwner,damage,Radius,CLASS_NONE,DMG_CRUSH);
                array<CBaseEntity@>pArray(10);
		g_EntityFuncs.MonstersInSphere(pArray, Location, Radius);

		for(uint i=0;i<pArray.length();i++) {
			CBaseEntity@ ent = pArray[i];
			//Check if the entity is not NULL
			if(ent !is null) {
				//Check if is Monster
				if(ent.IsMonster()) {
					CBaseEntity@ owner = g_EntityFuncs.Instance(pevOwner);
					if(ent.IRelationship(owner) != R_AL) {
						if( ent.pev.classname == "monster_cleansuit_scientist" || ent.IsMachine() )
							ent.TakeDamage(self.pev,pevOwner,damage * 0.30, DMG_SLOWBURN | DMG_NEVERGIB);
						else if( ent.pev.classname == "monster_gargantua" || ent.pev.classname == "monster_babygarg" )
							ent.TakeDamage(self.pev,pevOwner,damage * 0.50, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB);
						else ent.TakeDamage(self.pev,pevOwner,damage * 0.40, dmgType | DMG_NEVERGIB);
						
						pevOwner.frags += int(damage * 0.20);
					}
				}
			}
		}
	}

        void Fail()
        {
		Throwing_State = BB_PROJ_FAIL; //Failed

                g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, BarnacleThrow_Sounds[1], 1.0f, ATTN_NORM, 0, PITCH_NORM, 0, false, self.pev.origin);

                for(uint i=0;i<4;i++)
                {
                	Create_Sprite("sprites/bhit.spr",{0,255,0,200});
                }
		Create_Decal((Math.RandomLong(0,10)<5)?DECAL_SPIT1:DECAL_SPIT2);
        }

	void Succeed()
	{
		Throwing_State = BB_PROJ_SUCCEED; //Succeed
		g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, BarnacleThrow_Sounds[2], 1.0f, ATTN_NORM, 0, PITCH_NORM, 0, false, self.pev.origin);
		//Create Barnacle
		TraceResult tr;
		g_Utility.TraceLine(self.pev.origin,self.pev.origin+Vector(0,0,100),ignore_monsters,self.edict(),tr);

		Proj_BabyBarnacle_Fx@ fx1 = CreateFx(tr.vecEndPos,MODEL_BARNACLE,"monster_barnacle",0,255,2,0.1,kRenderNormal,125);
		fx1.pev.set_controller(0,int8(255));
		Proj_BabyBarnacle_Fx@ fx2 = CreateFx(tr.vecEndPos,W_MODEL_ZOMBIE_BARNACLE,"",255,0,2,0.1,kRenderTransAlpha,40);
		fx2.pev.angles.z += 180.0;
		fx2.pev.rendermode = kRenderNormal;

		RemoveEntity();
	}

	Proj_BabyBarnacle_Fx@ CreateFx(Vector Location,string model,string szName="",float rStart = 0,float rTarget = 255,float rAmount = 1.0,
					float rFreq = 0.1,int rMode=kRenderTransAlpha,int rModePoint=255) {
		CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("proj_baby_barnacle_fx");
		Proj_BabyBarnacle_Fx@ Effect = cast<Proj_BabyBarnacle_Fx@>(CastToScriptClass(entBase));
		g_EntityFuncs.DispatchSpawn(Effect.self.edict());
		@Effect.pev.owner = self.pev.owner;
		Effect.pev.origin = Location;
		Effect.pev.angles.y = self.pev.angles.y;
		Effect.SetupRender(model,szName,rStart,rTarget,rAmount,rFreq,rMode,rModePoint);

		return Effect;
	}

  	void Proj_Think() {
		self.pev.nextthink = g_Engine.time + 0.1;
                self.pev.angles = Math.VecToAngles(self.pev.velocity) + Vector(90,0,0);

                //Remove if this entity stopped
                if(self.pev.velocity.Length() < 0.5)
                {
			if(Throwing_State == BB_PROJ_IN_AIR) Fail();
			if(Throwing_State==BB_PROJ_FAIL) {
				CBaseEntity@ entBase = g_EntityFuncs.CreateEntity("barnacle_baby");
				CBaseMonster@ dropEnt = entBase.MyMonsterPointer();
				if(dropEnt !is null) {
					g_EntityFuncs.DispatchSpawn(dropEnt.edict());
					dropEnt.SetPlayerAllyDirect(true);
					dropEnt.pev.origin = Unstuck::GetUnstuckPosition(self.pev.origin,self);
					dropEnt.pev.angles.y = self.pev.v_angle.y;
				}
				RemoveEntity();
			}
			return;
                } else {
			if(Throwing_State == BB_PROJ_IN_AIR) {
				DoDamage(self.pev.origin,50.0,self.pev.dmg,DMG_RADIATION|DMG_NEVERGIB);

				if(checkTimer<g_Engine.time) {
					checkTimer = g_Engine.time + checkFrequence;
					Create_Sprite("sprites/bhit.spr",{0,255,0,200});
					Create_Decal((Math.RandomLong(0,10)<5)?DECAL_SPIT1:DECAL_SPIT2);
				}
			}
		}
        }

        void RemoveEntity()
	{
		self.pev.effects |= EF_NODRAW;
		g_EntityFuncs.Remove(self);
	}

        void BounceTouch(CBaseEntity@ pOther)
	{
		// don't hit the guy that launched this grenade
		if(@pOther.edict() == @self.pev.owner)
			return;

		DoDamage(self.pev.origin,50.0,self.pev.dmg,DMG_POISON);

		//If There is a wall above, create growing barnacle
		//and enough space below the baby barnacle(3x the size)
		if(Unstuck::is_wall_between_points(self.pev.origin,self.pev.origin+Vector(0,0,self.pev.maxs.z+self.pev.maxs.z*0.5),self)
		&& !Unstuck::is_wall_between_points(self.pev.origin-Vector(0,0,self.pev.maxs.z+self.pev.maxs.z*3.0),self.pev.origin,self))
		{
			Succeed();
		} else {
			Throwing_State = BB_PROJ_IN_AIR; //In Air
		}
	}

        void Precache()
	{
		BaseClass.Precache();
		proj_baby_barnacle_Precache();
	}
}

class Proj_BabyBarnacle_Fx : ScriptBaseMonsterEntity {
	private float RenderTarget = 255;
	private float RenderFreq = 0.1;
	private float RenderAmount = 5;
	private string CreateEntName = "";

	private int RenderMode = kRenderTransAlpha;
	private int RenderModePoint = 255;
	private bool RenderDone = false;

	bool RenderAdd = true;

	void Spawn()
	{
		self.pev.scale = 1.0;

                self.pev.movetype = MOVETYPE_NONE;
                self.pev.gravity = 0.0f;
                self.pev.solid = SOLID_BBOX;

                g_EntityFuncs.SetSize(self.pev,Vector(-15.0,-15.0,-15.0),Vector(15.0,15.0,30.0));
		self.pev.rendermode = RenderMode;
		self.pev.renderfx = kRenderFxNone;
		self.pev.rendercolor = Vector(255,255,255);
		self.pev.renderamt = 0;
        }

	void SetupRender(string model,string szName="monster_barnacle",float rStart = 0,float rTarget = 255,float rAmount = 1.0,float rFreq = 0.1,int rMode=kRenderTransAlpha,int rModePoint=255) {
		
		CreateEntName = szName;
		RenderTarget = rTarget;
		RenderAmount = rAmount;
		RenderFreq = rFreq;

		RenderMode = rMode;
		RenderModePoint = rModePoint;

		self.pev.renderamt = rStart;
		//self.pev.rendermode = rMode;

		RenderAdd = (rStart<=rTarget);

		g_EntityFuncs.SetModel(self, model);

		SetThink(ThinkFunction(this.EntThink));
		self.pev.nextthink = g_Engine.time + RenderFreq;
	}

	void EntThink() {
		self.pev.nextthink = g_Engine.time + RenderFreq;
		if(RenderAdd) {
			if(self.pev.renderamt+RenderAmount<RenderTarget) self.pev.renderamt+=RenderAmount;
			else self.pev.renderamt=RenderTarget;

			self.pev.scale = self.pev.renderamt/255;

			if(self.pev.renderamt>RenderModePoint && !RenderDone) {
				RenderDone = true;
				self.pev.rendermode = RenderMode;
			}
		} else {
			if(self.pev.renderamt-RenderAmount>RenderTarget) self.pev.renderamt-=RenderAmount;
			else self.pev.renderamt=RenderTarget;

			self.pev.scale = 1.0+((255-self.pev.renderamt)/100);

			if(self.pev.renderamt<RenderModePoint && !RenderDone) {
				RenderDone = true;
				self.pev.rendermode = RenderMode;
			}
		}
			

		if(self.pev.renderamt==RenderTarget) {
			if(!CreateEntName.IsEmpty()) {
				dictionary keys;
				keys["origin"] = ""+self.pev.origin.ToString();
				keys["angles"] = "0 "+self.pev.angles.y+" 0";
				//!self.IsPlayerAlly() because Zombies are not ally to Humans(Players)
				if(!self.IsPlayerAlly()) keys["is_player_ally"] = "1";
				else keys["is_player_ally"] = "0";
				g_EntityFuncs.CreateEntity(CreateEntName, keys);
			}

			g_EntityFuncs.Remove(self);
		}
	}
}