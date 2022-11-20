//Projectile for Acid Throw Ability

//Acid Bolts
array<string>AcidThrow_Sounds = {
	"bullchicken/bc_attack1.wav",
	"bullchicken/bc_spithit1.wav",
	"bullchicken/bc_spithit2.wav",
	"bullchicken/bc_spithit3.wav"
};

void acid_throw_Init() {
	//Precache this Entity
	g_CustomEntityFuncs.RegisterCustomEntity( "AcidThrow", "acid_throw" );
	g_Game.PrecacheOther("acid_throw");

        g_Game.PrecacheModel("sprites/spray.spr");
        g_Game.PrecacheModel("sprites/bhit.spr");
        PrecacheSounds(AcidThrow_Sounds);
}

class AcidThrow : ScriptBaseMonsterEntity {
        int framePerSecond = 8;
	int frameMax = 4;
        float frameTimer = g_Engine.time;

        void Spawn()
	{
		Precache();
                //Sound
		g_SoundSystem.PlaySound( self.edict(), CHAN_WEAPON, AcidThrow_Sounds[0], 1.0f, ATTN_NORM, 0, PITCH_NORM, 0, false, self.pev.origin );

                g_EntityFuncs.SetModel( self, "sprites/spray.spr");

                self.pev.rendermode = kRenderTransAdd;
		self.pev.rendercolor.x = 0;
		self.pev.rendercolor.y = 255;
		self.pev.rendercolor.z = 0;
		self.pev.renderamt = 250;

                self.pev.scale = 0.6;

                self.pev.movetype = MOVETYPE_TOSS;
                self.pev.gravity = 0.8f;
                self.pev.solid = SOLID_BBOX;

                //Sprite Stuff
		self.pev.frame = 0;
		self.pev.framerate = 15;
                
                self.pev.dmg = 25.0;
                self.pev.dmgtime = g_Engine.time + 5.0;

                g_EntityFuncs.SetSize(self.pev,Vector(-0.2,-0.2,-0.2),Vector(0.2,0.2,0.2));

                SetTouch(TouchFunction(this.BounceTouch));
                SetThink(ThinkFunction(this.AcidThink));
		self.pev.nextthink = g_Engine.time + 0.1;
        }

        void Spawn_Acid()
	{
		string sprite="sprites/bhit.spr";
		
		CSprite@ ourSprite = g_EntityFuncs.CreateSprite(sprite, self.pev.origin + Vector(0,0,5), false, 1.0 );
		ourSprite.SetTransparency(kRenderTransAdd,255,255,0,250,kRenderFxNone);
		
		ourSprite.pev.velocity = self.pev.velocity + Vector(Math.RandomFloat(-50.0,50.0),Math.RandomFloat(-50.0,50.0),Math.RandomFloat(25.0,150.0));
		ourSprite.SetScale(self.pev.scale);
		ourSprite.AnimateAndDie(30);
	}

        void Explode()
        {
                entvars_t@ pevOwner;
		if( self.pev.owner !is null )
			@pevOwner = @self.pev.owner.vars;
		else
			@pevOwner = self.pev;
                
                //g_WeaponFuncs.RadiusDamage(self.pev.origin,self.pev,pevOwner,self.pev.dmg,self.pev.dmg*self.pev.size,CLASS_NONE,DMG_ACID);
                array<CBaseEntity@>pArray(10);
		g_EntityFuncs.MonstersInSphere(pArray, self.pev.origin, 80.0);
		
		for(uint i=0;i<pArray.length();i++) {
			CBaseEntity@ ent = pArray[i];
			//Check if the entity is not NULL
			if(ent !is null) {
				//Check if is Player
				if(ent.IsMonster()) {
					if(self.IRelationship(ent) != R_AL) {
						if( ent.pev.classname == "monster_cleansuit_scientist" || ent.IsMachine() )
							ent.TakeDamage(self.pev,pevOwner,self.pev.dmg * 0.30, DMG_SLOWBURN | DMG_NEVERGIB);
						else if( ent.pev.classname == "monster_gargantua" || ent.pev.classname == "monster_babygarg" )
							ent.TakeDamage(self.pev,pevOwner,self.pev.dmg * 0.50, DMG_BURN | DMG_SLOWBURN | DMG_NEVERGIB);
						else ent.TakeDamage(self.pev,pevOwner,self.pev.dmg * 0.40, DMG_POISON | DMG_NEVERGIB);
						
						pevOwner.frags += int(self.pev.dmg * 0.20);
					}
				}
			}
		}

                g_SoundSystem.PlaySound(self.edict(), CHAN_WEAPON, AcidThrow_Sounds[Math.RandomLong(1,2)], 1.0f, ATTN_NORM, 0, PITCH_NORM, 0, false, self.pev.origin);

                TraceResult tr;
                g_Utility.TraceLine(self.GetOrigin(),self.GetOrigin()+Vector(0,0,-32),ignore_monsters,self.pev.pContainingEntity,tr);
                g_Utility.DecalTrace(tr,(Math.RandomLong(0,1)<0.5) ? DECAL_SPORESPLAT1:DECAL_SPORESPLAT2);
                g_Utility.TraceLine(self.GetOrigin(),self.GetOrigin()+g_Engine.v_forward*32,ignore_monsters,self.pev.pContainingEntity,tr);
                g_Utility.DecalTrace(tr,(Math.RandomLong(0,1)<0.5) ? DECAL_SPORESPLAT2:DECAL_SPORESPLAT3);

                for(uint i=0;i<8;i++)
                {
                        Spawn_Acid();
                }

                RemoveEntity();
        }

        void AcidThink() {
		self.pev.nextthink = g_Engine.time + 0.01;
                //self.pev.angles = Math.VecToAngles(self.pev.velocity);

                //Sprite Stuff
		if(frameTimer<g_Engine.time) {
			frameTimer=g_Engine.time + (60/self.pev.framerate)/framePerSecond;
			if(self.pev.frame<frameMax) self.pev.frame++;
			else {
                                self.pev.frame=0;
                                for(uint i=0;i<3;i++)
                                {
                                        Spawn_Acid();
                                }
                        }
		}

                //Remove if this entity stopped
                if(self.pev.velocity.Length() < 3.0)
                {
                        Explode();
			return;
                }

                //Remove after some time
                if(self.pev.dmgtime < g_Engine.time)
                {
                        Explode();
			return;
                }
        }

        void RemoveEntity()
	{
		self.pev.effects |= EF_NODRAW;
		g_EntityFuncs.Remove(self);
	}

        void BounceTouch( CBaseEntity@ pOther )
	{
		// don't hit the guy that launched this grenade
		if(@pOther.edict() == @self.pev.owner)
			return;

		Explode();
	}

        void Precache()
	{
		g_Game.PrecacheModel("sprites/spray.spr");
                g_Game.PrecacheModel("sprites/bhit.spr");
                PrecacheSounds(AcidThrow_Sounds);
		
		BaseClass.Precache();
	}
}