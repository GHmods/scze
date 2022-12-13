# Sven Co-op: Zombie Edition
![](https://i.imgur.com/ee9K4AJ.png)
> Half-Life: Zombie Edition Port for Sven Co-op

- This mod is in early stages, don't expect proficiency in code since im not a professional coder.
- I will try to update this mod more frequently.


# Want to support my work?
- ☕ <a href="https://www.buymeacoffee.com/GHmods">You can buy me a coffee!</a>
---
### Short Gameplay Video of this Mod: (Version used on video: v0.3)
<a href="https://youtu.be/mcpfW0ufbQM">
	<img src="https://i.imgur.com/DDoAp4R.png" alt="Watch Sven Co-op Zombie Edition Gameplay Video on YouTube" width=768>
</a>
<br>
by fErMangan tuU!!

### How to Install?
#### Instalation Instructions:
1. Download Latest Release from <a href="https://github.com/GHmods/scze/releases/latest">here</a>.
2. Open 'scze-x.x.zip' and select:
> maps,models,scripts,sound,sprites and zombie.wad
3. Extract it inside 'svencoop_addon' folder.
4. Now start Sven Co-op on: <br>
- Training map is: hlze_betamap <br>
- First Story Map is: hlze_zem1 <br>
5. Good Luck :smile:.
#### Aditional Information:
- Scripts can be found inside 'scripts/maps/hlze/' folder.
### Configuration:
- Configuration Files are stored inside 'scripts/maps'.
- Global Configuration File is: 'hlze_global.ini'
- Per Map Configuration File is loaded as: '[map_name].hlze.ini'
#### The mod is not starting ?!?!?!
Its probably because of Save/Load System.
##### Make sure to create some aditional folders to match this path 'svencoop/scripts/maps/store/hlze'
##### !!! Not inside 'svencoop_addon' folder,..., IT MUST BE IN 'svencoop' Folder!
#### The mod still won't start ?!?!!
I don't know, email me.
#### How to add new class?
#### If you want to add new classes:
1. You must have 1 class for zombie, and 1 for headcrab and they must be in the same order.
2. You can add them in 'scripts/maps/hlze/classes/' folder
- 'headcrab_classes.as' is for headcrabs.
- 'zombie_classes.as' is for zombies.
  - If you add a class for headcrab, headcrab will try to mutate to zombie class with same id as headcrab class.This means you must add your zombie class in the same order as your headcrab class.
#### I have problems after adding new Zombie/Headcrab class.
- Save/Load System will store data from players for these classes inside 'svencoop/scripts/maps/store/hlze/' folder.
##### Fix:
- Delete these files inside 'svencoop/scripts/maps/store folder and retry:
  - 'headcrab_classes.ini'
  - 'zombie_classes.ini'
- I know that by deleting these files, players will loose progress.You can try changing numbers from 0# to 1# and see what will happend.
#### I will try to fix this as well.
##### Note for Mappers:
- Headcrab Players can unlock 'func_wall_toggle' with targetnames:
  - 'togg1','toggle1' <-- Not Recommended.
  - Use 'hcwall1','hcwall2',...,'hcwall9','hcwall10',...,'hcwall15';
- Zombie Players can trigger 'func_breakable' with targetname: 'flr_brk';
- Zombie Players can use all rotating doors('func_door_rotating') with targetnames: 'ds1', 'd1', 'd2', 'd3',...,'d9';
- To make Zombie Players open rotating doors('func_door_rotating'), use 'trigger_multiple'; (See Examples Folder)
- More defines can be defined in 'entities/multisource.as'
For More Doors:
```
array<array<string>>DoorEntities = { ... };
```
For More Walls:
```
array<array<string>>WallEntities = { ... };
```
For More Walls Settings:
```
array<array<string>>WallEntities_Settings = {
		....,
		{(Headcrab/Zombie)<1/0>, <Triggered when Player is Nearby>,<Triggered when Player is  Away>(Not Needed for 'func_breakable') },
  ....
};
```
- (Only defined in Crasher Class) To make Zombie Players break walls('func_breakable'), set targetnames: 'zWall', 'zWall1', 'zWall2',...,'zWall9'; (See Examples Folder)
- More defines can be defined in 'weapons/weapon_zombie.as' --->
For More Walls: 
```
  array<string>BreakableZWalls = { ... };
```
- Every door is locked with 'multisource' entity; (To block Headcrabs from opening them).
-Examples are in 'Examples' folder.
- If PvPvM Feature is Enabled, use 'info_target' with targetname: 'info_human_spawn' to create multiple spawn
points for Humans.
---

#### Tasks Part 1: ![100%](https://progress-bar.dev/100)
  - ~~Upload all resources.~~
  - ~~Upload my private code.~~
  - ~~Do my first release.~~
#### Tasks Part 2: ![100%](https://progress-bar.dev/100)
  - ~~Do a fixes for some maps.~~
  - ~~Fix/Improve uploaded code.~~
  - ~~Fix Crasher class.~~
  - ~~Add Acid Projectile.~~
  - ~~Fixes for PvPvM Feature.~~
  - ~~Add Breeder class.~~
  - ~~Add usable headcrabs.~~
  - ~~Add Save by Steam ID or Name Option.~~
  - ~~Add Installation Instructions.~~
  - ~~Do a Second Release.~~
#### Tasks Part 3: ![1%](https://progress-bar.dev/1)
  - ~~Work In Progress.~~

## Tools I've used:
* <a href="https://github.com/wootguy/bspguy/releases/tag/v4">bspguy v4</a>
* <a href="https://baso88.github.io/SC_AngelScript/docs/">Sven Co-op AngelScript Documentation</a>
---
### Original Half-Life Mod <a href="https://www.moddb.com/mods/half-life-zombie-edition">Here</a>
* Q: Can you add multiplayer?
* A: Na-ah.
* Me: I'm trying!
