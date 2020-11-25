#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	When the bot gets added into the game.
*/
added()
{
	self endon("disconnect");
	
	rankxp = self bot_get_rank();
	self setStat( int(tableLookup( "mp/playerStatsTable.csv", 1, "rankxp", 0 )), rankxp );
	
	self set_diff();
	
	self set_class(rankxp);
}

/*
	When the bot connects to the game.
*/
connected()
{
	self endon("disconnect");
	
	self.killerLocation = undefined;
	
	self thread difficulty();
	self thread teamWatch();
	self thread classWatch();
	self thread onBotSpawned();
	self thread onSpawned();

	// cod4x has a force respawn in the exe
}

/*
	The callback for when the bot gets killed.
*/
onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self.killerLocation = undefined;

	if(!IsDefined( self ) || !isDefined(self.team))
		return;

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;

	if ( iDamage <= 0 )
		return;
	
	if(!IsDefined( eAttacker ) || !isDefined(eAttacker.team))
		return;
		
	if(eAttacker == self)
		return;
		
	if(level.teamBased && eAttacker.team == self.team)
		return;

	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player")
		return;
		
	if(!isAlive(eAttacker))
		return;
	
	self.killerLocation = eAttacker.origin;
}

/*
	The callback for when the bot gets damaged.
*/
onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if(!IsDefined( self ) || !isDefined(self.team))
		return;
		
	if(!isAlive(self))
		return;

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;

	if ( iDamage <= 0 )
		return;
	
	if(!IsDefined( eAttacker ) || !isDefined(eAttacker.team))
		return;
		
	if(eAttacker == self)
		return;
		
	if(level.teamBased && eAttacker.team == self.team)
		return;

	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player")
		return;
		
	if(!isAlive(eAttacker))
		return;
		
	if (!isSubStr(sWeapon, "_silencer_"))
		self bot_cry_for_help( eAttacker );
	
	self SetAttacker( eAttacker );
}

/*
	When the bot gets attacked, have the bot ask for help from teammates.
*/
bot_cry_for_help( attacker )
{
	if ( !level.teamBased )
	{
		return;
	}
	
	theTime = GetTime();
	if ( IsDefined( self.help_time ) && theTime - self.help_time < 1000 )
	{
		return;
	}
	
	self.help_time = theTime;

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];

		if ( !player is_bot() )
		{
			continue;
		}
		
		if(!isDefined(player.team))
			continue;

		if ( !IsAlive( player ) )
		{
			continue;
		}

		if ( player == self )
		{
			continue;
		}

		if ( player.team != self.team )
		{
			continue;
		}

		dist = player.pers["bots"]["skill"]["help_dist"];
		dist *= dist;
		if ( DistanceSquared( self.origin, player.origin ) > dist )
		{
			continue;
		}

		if ( RandomInt( 100 ) < 50 )
		{
			self SetAttacker( attacker );

			if ( RandomInt( 100 ) > 70 )
			{
				break;
			}
		}
	}
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]) || level.oldschool)
			wait .05;
			
		wait 0.5;
		class = "";
		rank = self maps\mp\gametypes\_rank::getRankForXp( self getStat( int(tableLookup( "mp/playerStatsTable.csv", 1, "rankxp", 0 )) ) ) + 1;
		if(rank < 4 || randomInt(100) < 2)
		{
			while(class == "")
			{
				switch(randomInt(5))
				{
					case 0:
						class = "assault_mp";
						break;
					case 1:
						class = "specops_mp";
						break;
					case 2:
						class = "heavygunner_mp";
						break;
					case 3:
						if(rank >= 2)
							class = "demolitions_mp";
						break;
					case 4:
						if(rank >= 3)
							class = "sniper_mp";
						break;
				}
			}
		}
		else
		{
			class = "custom"+(randomInt(5)+1);
		}
		
		self notify("menuresponse", game["menu_changeclass"], class);
		self.bot_change_class = true;
			
		while(isdefined(self.pers["team"]) && isdefined(self.pers["class"]) && isDefined(self.bot_change_class))
			wait .05;
	}
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]))
			wait .05;
			
		wait 0.05;
		self notify("menuresponse", game["menu_team"], getDvar("bots_team"));
			
		while(isdefined(self.pers["team"]))
			wait .05;
	}
}

/*
	Updates the bot's difficulty variables.
*/
difficulty()
{
	self endon("disconnect");

	for(;;)
	{
		wait 1;
		
		rankVar = GetDvarInt("bots_skill");
		
		if(rankVar == 9)
			continue;
			
		switch(self.pers["bots"]["skill"]["base"])
		{
			case 1:
				self.pers["bots"]["skill"]["aim_time"] = 0.6;
				self.pers["bots"]["skill"]["init_react_time"] = 1500;
				self.pers["bots"]["skill"]["reaction_time"] = 1000;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 500;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 600;
				self.pers["bots"]["skill"]["remember_time"] = 750;
				self.pers["bots"]["skill"]["fov"] = 0.7;
				self.pers["bots"]["skill"]["dist"] = 1000;
				self.pers["bots"]["skill"]["spawn_time"] = 0.75;
				self.pers["bots"]["skill"]["help_dist"] = 0;
				self.pers["bots"]["skill"]["semi_time"] = 0.9;
				self.pers["bots"]["skill"]["shoot_after_time"] = 1;
				self.pers["bots"]["skill"]["aim_offset_time"] = 1.5;
				self.pers["bots"]["skill"]["aim_offset_amount"] = 4;
				self.pers["bots"]["skill"]["bone_update_interval"] = 2;
				self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_ankle_le,j_ankle_ri";

				self.pers["bots"]["behavior"]["strafe"] = 0;
				self.pers["bots"]["behavior"]["nade"] = 10;
				self.pers["bots"]["behavior"]["sprint"] = 10;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 70;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 0;
				break;
			case 2:
				self.pers["bots"]["skill"]["aim_time"] = 0.55;
				self.pers["bots"]["skill"]["init_react_time"] = 1000;
				self.pers["bots"]["skill"]["reaction_time"] = 800;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 1000;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 1250;
				self.pers["bots"]["skill"]["remember_time"] = 1500;
				self.pers["bots"]["skill"]["fov"] = 0.65;
				self.pers["bots"]["skill"]["dist"] = 1500;
				self.pers["bots"]["skill"]["spawn_time"] = 0.65;
				self.pers["bots"]["skill"]["help_dist"] = 500;
				self.pers["bots"]["skill"]["semi_time"] = 0.75;
				self.pers["bots"]["skill"]["shoot_after_time"] = 0.75;
				self.pers["bots"]["skill"]["aim_offset_time"] = 1;
				self.pers["bots"]["skill"]["aim_offset_amount"] = 3;
				self.pers["bots"]["skill"]["bone_update_interval"] = 1.5;
				self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_ankle_le,j_ankle_ri,j_head";

				self.pers["bots"]["behavior"]["strafe"] = 10;
				self.pers["bots"]["behavior"]["nade"] = 15;
				self.pers["bots"]["behavior"]["sprint"] = 15;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 60;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 10;
				break;
			case 3:
				self.pers["bots"]["skill"]["aim_time"] = 0.4;
				self.pers["bots"]["skill"]["init_react_time"] = 750;
				self.pers["bots"]["skill"]["reaction_time"] = 500;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 1000;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 1500;
				self.pers["bots"]["skill"]["remember_time"] = 2000;
				self.pers["bots"]["skill"]["fov"] = 0.6;
				self.pers["bots"]["skill"]["dist"] = 2250;
				self.pers["bots"]["skill"]["spawn_time"] = 0.5;
				self.pers["bots"]["skill"]["help_dist"] = 750;
				self.pers["bots"]["skill"]["semi_time"] = 0.65;
				self.pers["bots"]["skill"]["shoot_after_time"] = 0.65;
				self.pers["bots"]["skill"]["aim_offset_time"] = 0.75;
				self.pers["bots"]["skill"]["aim_offset_amount"] = 2.5;
				self.pers["bots"]["skill"]["bone_update_interval"] = 1;
				self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_spineupper,j_ankle_le,j_ankle_ri,j_head";

				self.pers["bots"]["behavior"]["strafe"] = 20;
				self.pers["bots"]["behavior"]["nade"] = 20;
				self.pers["bots"]["behavior"]["sprint"] = 20;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 50;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 25;
				break;
			case 4:
				self.pers["bots"]["skill"]["aim_time"] = 0.3;
				self.pers["bots"]["skill"]["init_react_time"] = 600;
				self.pers["bots"]["skill"]["reaction_time"] = 400;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 1000;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 1500;
				self.pers["bots"]["skill"]["remember_time"] = 3000;
				self.pers["bots"]["skill"]["fov"] = 0.55;
				self.pers["bots"]["skill"]["dist"] = 3350;
				self.pers["bots"]["skill"]["spawn_time"] = 0.35;
				self.pers["bots"]["skill"]["help_dist"] = 1000;
				self.pers["bots"]["skill"]["semi_time"] = 0.5;
				self.pers["bots"]["skill"]["shoot_after_time"] = 0.5;
				self.pers["bots"]["skill"]["aim_offset_time"] = 0.5;
				self.pers["bots"]["skill"]["aim_offset_amount"] = 2;
				self.pers["bots"]["skill"]["bone_update_interval"] = 0.75;
				self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_spineupper,j_ankle_le,j_ankle_ri,j_head,j_head";

				self.pers["bots"]["behavior"]["strafe"] = 30;
				self.pers["bots"]["behavior"]["nade"] = 25;
				self.pers["bots"]["behavior"]["sprint"] = 30;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 40;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 35;
				break;
			case 5:
				self.pers["bots"]["skill"]["aim_time"] = 0.25;
				self.pers["bots"]["skill"]["init_react_time"] = 500;
				self.pers["bots"]["skill"]["reaction_time"] = 300;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 1500;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 2000;
				self.pers["bots"]["skill"]["remember_time"] = 4000;
				self.pers["bots"]["skill"]["fov"] = 0.5;
				self.pers["bots"]["skill"]["dist"] = 5000;
				self.pers["bots"]["skill"]["spawn_time"] = 0.25;
				self.pers["bots"]["skill"]["help_dist"] = 1500;
				self.pers["bots"]["skill"]["semi_time"] = 0.4;
				self.pers["bots"]["skill"]["shoot_after_time"] = 0.35;
				self.pers["bots"]["skill"]["aim_offset_time"] = 0.35;
				self.pers["bots"]["skill"]["aim_offset_amount"] = 1.5;
				self.pers["bots"]["skill"]["bone_update_interval"] = 0.5;
				self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_head";

				self.pers["bots"]["behavior"]["strafe"] = 40;
				self.pers["bots"]["behavior"]["nade"] = 35;
				self.pers["bots"]["behavior"]["sprint"] = 40;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 30;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 50;
				break;
			case 6:
				self.pers["bots"]["skill"]["aim_time"] = 0.2;
				self.pers["bots"]["skill"]["init_react_time"] = 250;
				self.pers["bots"]["skill"]["reaction_time"] = 150;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 2000;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 3000;
				self.pers["bots"]["skill"]["remember_time"] = 5000;
				self.pers["bots"]["skill"]["fov"] = 0.45;
				self.pers["bots"]["skill"]["dist"] = 7500;
				self.pers["bots"]["skill"]["spawn_time"] = 0.2;
				self.pers["bots"]["skill"]["help_dist"] = 2000;
				self.pers["bots"]["skill"]["semi_time"] = 0.25;
				self.pers["bots"]["skill"]["shoot_after_time"] = 0.25;
				self.pers["bots"]["skill"]["aim_offset_time"] = 0.25;
				self.pers["bots"]["skill"]["aim_offset_amount"] = 1;
				self.pers["bots"]["skill"]["bone_update_interval"] = 0.25;
				self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_head,j_head";

				self.pers["bots"]["behavior"]["strafe"] = 50;
				self.pers["bots"]["behavior"]["nade"] = 45;
				self.pers["bots"]["behavior"]["sprint"] = 50;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 20;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 75;
				break;
			case 7:
				self.pers["bots"]["skill"]["aim_time"] = 0.1;
				self.pers["bots"]["skill"]["init_react_time"] = 100;
				self.pers["bots"]["skill"]["reaction_time"] = 50;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 2500;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 4000;
				self.pers["bots"]["skill"]["remember_time"] = 7500;
				self.pers["bots"]["skill"]["fov"] = 0.4;
				self.pers["bots"]["skill"]["dist"] = 10000;
				self.pers["bots"]["skill"]["spawn_time"] = 0.05;
				self.pers["bots"]["skill"]["help_dist"] = 3000;
				self.pers["bots"]["skill"]["semi_time"] = 0.1;
				self.pers["bots"]["skill"]["shoot_after_time"] = 0;
				self.pers["bots"]["skill"]["aim_offset_time"] = 0;
				self.pers["bots"]["skill"]["aim_offset_amount"] = 0;
				self.pers["bots"]["skill"]["bone_update_interval"] = 0.05;
				self.pers["bots"]["skill"]["bones"] = "j_head";

				self.pers["bots"]["behavior"]["strafe"] = 65;
				self.pers["bots"]["behavior"]["nade"] = 65;
				self.pers["bots"]["behavior"]["sprint"] = 65;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 5;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 90;
				break;
		}
	}
}

/*
	Sets the bot difficulty.
*/
set_diff()
{
	rankVar = GetDvarInt("bots_skill");
	
	switch(rankVar)
	{
		case 0:
			self.pers["bots"]["skill"]["base"] = Round( random_normal_distribution( 3.5, 1.75, 1, 7 ) );
			break;
		case 8:
			break;
		case 9:
			self.pers["bots"]["skill"]["base"] = randomIntRange(1, 7);
			self.pers["bots"]["skill"]["aim_time"] = 0.05 * randomIntRange(1, 20);
			self.pers["bots"]["skill"]["init_react_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["reaction_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["no_trace_ads_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["no_trace_look_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["remember_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["fov"] = randomFloatRange(-1, 1);
			self.pers["bots"]["skill"]["dist"] = randomIntRange(500, 25000);
			self.pers["bots"]["skill"]["spawn_time"] = 0.05 * randomInt(20);
			self.pers["bots"]["skill"]["help_dist"] = randomIntRange(500, 25000);
			self.pers["bots"]["skill"]["semi_time"] = randomFloatRange(0.05, 1);
			self.pers["bots"]["skill"]["shoot_after_time"] = randomFloatRange(0.05, 1);
			self.pers["bots"]["skill"]["aim_offset_time"] = randomFloatRange(0.05, 1);
			self.pers["bots"]["skill"]["aim_offset_amount"] = randomFloatRange(0.05, 1);
			self.pers["bots"]["skill"]["bone_update_interval"] = randomFloatRange(0.05, 1);
			self.pers["bots"]["skill"]["bones"] = "j_head,j_spineupper,j_ankle_ri,j_ankle_le";

			self.pers["bots"]["behavior"]["strafe"] = randomInt(100);
			self.pers["bots"]["behavior"]["nade"] = randomInt(100);
			self.pers["bots"]["behavior"]["sprint"] = randomInt(100);
			self.pers["bots"]["behavior"]["camp"] = randomInt(100);
			self.pers["bots"]["behavior"]["follow"] = randomInt(100);
			self.pers["bots"]["behavior"]["crouch"] = randomInt(100);
			self.pers["bots"]["behavior"]["switch"] = randomInt(100);
			self.pers["bots"]["behavior"]["class"] = randomInt(100);
			self.pers["bots"]["behavior"]["jump"] = randomInt(100);
			break;
		default:
			self.pers["bots"]["skill"]["base"] = rankVar;
			break;
	}
}

/*
	Sets the bot's classes.
*/
set_class(rankxp)
{
	primaryGroups = [];
	primaryGroups[0] = "weapon_lmg";
	primaryGroups[1] = "weapon_smg";
	primaryGroups[2] = "weapon_shotgun";
	primaryGroups[3] = "weapon_sniper";
	primaryGroups[4] = "weapon_assault";
	secondaryGroups = [];
	secondaryGroups[0] = "weapon_pistol";
	
	rank = self maps\mp\gametypes\_rank::getRankForXp( rankxp ) + 1;

	for(i=0; i < 5; i++)
	{
		primary = get_random_weapon(primaryGroups, rank);
		att1 = get_random_attachment(primary, rank);
		
		perk2 = get_random_perk("perk2", rank);
		if(perk2 != "specialty_twoprimaries")
			secondary = get_random_weapon(secondaryGroups, rank);
		else
			secondary = get_random_weapon(primaryGroups, rank);
		att2 = get_random_attachment(secondary, rank);
		perk1 = get_random_perk("perk1", rank, att1, att2);
		
		perk3 = get_random_perk("perk3", rank);
		gren = get_random_grenade(perk1);
		camo = randomInt(8);
	
		self setStat ( 200+(i*10)+1, level.weaponReferenceToIndex[primary] );
		self setStat ( 200+(i*10)+2, level.weaponAttachmentReferenceToIndex[att1] );
		self setStat ( 200+(i*10)+3, level.weaponReferenceToIndex[secondary] );
		self setStat ( 200+(i*10)+4, level.weaponAttachmentReferenceToIndex[att2] );
		self setStat ( 200+(i*10)+5, level.perkReferenceToIndex[perk1] );
		self setStat ( 200+(i*10)+6, level.perkReferenceToIndex[perk2] );
		self setStat ( 200+(i*10)+7, level.perkReferenceToIndex[perk3] );
		self setStat ( 200+(i*10)+8, level.weaponReferenceToIndex[gren] );
		self setStat ( 200+(i*10)+9, camo);
	}
}

/*
	Returns a random attachment for the bot.
*/
get_random_attachment(weapon, rank)
{
	if (RandomFloatRange( 0, 1 ) > (0.1 + ( rank / level.maxRank )))
		return "none";

	reasonable = GetDvarInt("bots_loadout_reasonable");
	
	id = level.tbl_weaponIDs[level.weaponReferenceToIndex[weapon]];
	atts = strtok(id["attachment"], " ");
	atts[atts.size] = "none";

	
	for(;;)
	{
		att = atts[randomInt(atts.size)];
		
		if(reasonable)
		{
			switch(att)
			{
				case "acog":
					if(weapon != "m40a3")
						continue;
					break;
			}
		}
		
		return att;
	}
}

/*
	Returns a random perk for the bot.
*/
get_random_perk(perkslot, rank, att1, att2)
{
	if(isDefined(att1) && isDefined(att2) && (att1 == "grip" || att1 == "gl" || att2 == "grip" || att2 == "gl"))
		return "specialty_null";
	
	reasonable = GetDvarInt("bots_loadout_reasonable");
	op = GetDvarInt("bots_loadout_allow_op");
	
	keys = getArrayKeys(level.tbl_PerkData);
	for(;;)
	{
		id = level.tbl_PerkData[keys[randomInt(keys.size)]];
		
		if(!isDefined(id) || !isDefined(id["perk_num"]))
			continue;
		
		if(perkslot != id["perk_num"])
			continue;
			
		ref = id["reference_full"];
		
		if(ref == "specialty_null" && randomInt(100) < 95)
			continue;
			
		if(reasonable)
		{
			switch(ref)
			{
				case "specialty_parabolic":
				case "specialty_holdbreath":
				case "specialty_weapon_c4":
				case "specialty_explosivedamage":
				case "specialty_twoprimaries":
					continue;
			}
		}
			
		if(!op)
		{
			switch(ref)
			{
				case "specialty_armorvest":
				case "specialty_pistoldeath":
				case "specialty_grenadepulldeath":
					continue;
			}
		}
		
		if(!isItemUnlocked(ref, rank))
			continue;
			
		return ref;
	}
}

/*
	Returns a random grenade for the bot.
*/
get_random_grenade(perk1)
{
	possibles = [];
	possibles[0] = "flash_grenade";
	possibles[1] = "smoke_grenade";
	possibles[2] = "concussion_grenade";
	
	reasonable = GetDvarInt("bots_loadout_reasonable");
	
	for(;;)
	{
		possible = possibles[randomInt(possibles.size)];
		
		if(reasonable)
		{
			switch(possible)
			{
				case "smoke_grenade":
					continue;
			}
		}
		
		if(perk1 == "specialty_specialgrenade" && possible == "smoke_grenade")
			continue;
			
		return possible;
	}
}

/*
	Returns a random weapon for the bot.
*/
get_random_weapon(groups, rank)
{
	reasonable = GetDvarInt("bots_loadout_reasonable");
	
	keys = getArrayKeys(level.tbl_weaponIDs);
	for(;;)
	{
		id = level.tbl_weaponIDs[keys[randomInt(keys.size)]];
		
		if(!isDefined(id))
			continue;
		
		group = id["group"];
		inGroup = false;
		for(i = groups.size - 1; i >= 0; i--)
		{
			if(groups[i] == group)
				inGroup = true;
		}
		
		if(!inGroup)
			continue;
			
		ref = id["reference"];
		
		if(reasonable)
		{
			switch(ref)
			{
				case "skorpion":
				case "uzi":
				case "m21":
				case "dragunov":
				case "saw":
				case "mp44":
				case "m14":
				case "g3":
				case "m1014":
					continue;
			}
		}
		
		if(!isItemUnlocked(ref, rank))
			continue;
			
		return ref;
	}
}

/*
	Gets an exp amount for the bot that is nearish the host's xp.
*/
bot_get_rank()
{
	ranks = [];
	bot_ranks = [];
	human_ranks = [];
	
	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];
	
		if ( player == self )
			continue;
		
		if ( !IsDefined( player.pers[ "rank" ] ) )
			continue;
		
		if ( player is_bot() )
		{
			bot_ranks[ bot_ranks.size ] = player.pers[ "rank" ];
		}
		else
		{
			human_ranks[ human_ranks.size ] = player.pers[ "rank" ];
		}
	}

	if( !human_ranks.size )
		human_ranks[ human_ranks.size ] = Round( random_normal_distribution( 35, 15, 0, level.maxRank ) );

	human_avg = array_average( human_ranks );

	while ( bot_ranks.size + human_ranks.size < 5 )
	{
		// add some random ranks for better random number distribution
		rank = human_avg + RandomIntRange( -10, 10 );
		human_ranks[ human_ranks.size ] = rank;
	}

	ranks = array_combine( human_ranks, bot_ranks );

	avg = array_average( ranks );
	s = array_std_deviation( ranks, avg );
	
	rank = Round( random_normal_distribution( avg, s, 0, level.maxRank ) );

	return maps\mp\gametypes\_rank::getRankInfoMinXP( rank );
}

/*
	When the bot spawns.
*/
onSpawned()
{
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		if(randomInt(100) <= self.pers["bots"]["behavior"]["class"])
			self.bot_change_class = undefined;

		self.bot_lock_goal = false;
		self.help_time = undefined;
		self.bot_was_follow_script_update = undefined;

		if (getDvarInt("bots_play_obj"))
			self thread bot_dom_cap_think();
	}
}

/*
	When the bot spawned, after the difficulty wait. Start the logic for the bot.
*/
onBotSpawned()
{
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill("bot_spawned");
		
		self thread start_bot_threads();
	}
}

start_bot_threads()
{
	self endon("disconnect");
	level endon("game_ended");
	self endon("death");

	while(level.inPrematchPeriod)
		wait 0.05;

	// inventory usage
	if (getDvarInt("bots_play_killstreak"))
		self thread bot_killstreak_think();

	self thread bot_weapon_think();

	// script targeting
	if (getDvarInt("bots_play_target_other"))
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
	}

	// awareness
	self thread bot_revenge_think();
	self thread bot_uav_think();
	self thread bot_listen_to_steps();
	self thread follow_target();

	// camp and follow
	if (getDvarInt("bots_play_camp"))
	{
		self thread bot_think_follow();
		self thread bot_think_camp();
	}

	// nades
	if (getDvarInt("bots_play_nade"))
	{
		self thread bot_use_tube_think();
		self thread bot_use_grenade_think();
		self thread bot_use_equipment_think();
	}

	// obj
	if (getDvarInt("bots_play_obj"))
	{
		self thread bot_dom_def_think();
		self thread bot_dom_spawn_kill_think();

		self thread bot_hq();

		self thread bot_sab();

		self thread bot_sd_defenders();
		self thread bot_sd_attackers();
	}
}

/*
	Bot logic for detecting nearby players.
*/
bot_listen_to_steps()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		wait 1;
		
		if(self HasScriptGoal() || self.bot_lock_goal)
			continue;
			
		if(self.pers["bots"]["skill"]["base"] < 3)
			continue;
			
		dist = level.bots_listenDist;
		if(self hasPerk("specialty_parabolic"))
			dist *= 1.4;
		
		dist *= dist;
		
		heard = undefined;
		for(i = level.players.size-1 ; i >= 0; i--)
		{
			player = level.players[i];
			
			if(!isDefined(player.bot_model_fix))
				continue;
			
			if(player == self)
				continue;
			if(level.teamBased && self.team == player.team)
				continue;
			if(player.sessionstate != "playing")
				continue;
			if(!isAlive(player))
				continue;
			if(player hasPerk("specialty_quieter"))
				continue;
				
			if(lengthsquared( player getVelocity() ) < 20000)
				continue;
				
			if(distanceSquared(player.origin, self.origin) > dist)
				continue;
				
			heard = player;
			break;
		}
		
		if(!IsDefined(heard))
			continue;
		
		if(bulletTracePassed(self getEyePos(), heard getTagOrigin( "j_spineupper" ), false, heard))
		{
			self setAttacker(heard);
			continue;
		}
		
		self SetScriptGoal( heard.origin, 64 );

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearScriptGoal();
	}
}

/*
	Bot logic for switching weapons.
*/
bot_weapon_think()
{
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill_any_timeout(randomIntRange(2, 4), "bot_force_check_switch");

		if(self BotIsFrozen())
			continue;
			
		if(self isDefusing() || self isPlanting() || self InLastStand())
			continue;
		
		hasTarget = self hasThreat();
		curWeap = self GetCurrentWeapon();
		
		if(hasTarget)
		{
			threat = self getThreat();
			
			if(threat.classname == "script_vehicle" && self getAmmoCount("rpg_mp"))
			{
				if (curWeap != "rpg_mp")
					self thread ChangeToWeapon("rpg_mp");
				continue;
			}
		}
		
		if(curWeap != "none" && self getAmmoCount(curWeap))
		{
			if(randomInt(100) > self.pers["bots"]["behavior"]["switch"])
				continue;
				
			if(hasTarget)
				continue;
		}
		
		weaponslist = self getweaponslist();
		weap = "";
		while(weaponslist.size)
		{
			weapon = weaponslist[randomInt(weaponslist.size)];
			weaponslist = array_remove(weaponslist, weapon);
			
			if(!self getAmmoCount(weapon))
				continue;
					
			if (maps\mp\gametypes\_weapons::isHackWeapon( weapon ))
				continue;
				
			if (maps\mp\gametypes\_weapons::isGrenade( weapon ))
				continue;
				
			if(curWeap == weapon || weapon == "c4_mp" || weapon == "none" || weapon == "")//c4 no work
				continue;
				
			weap = weapon;
			break;
		}
		
		if(weap == "")
			continue;
		
		self thread ChangeToWeapon(weap);
	}
}

/*
	Bot logic for killstreaks.
*/
bot_killstreak_think()
{
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		wait randomIntRange(1, 3);
		
		if(self BotIsFrozen())
			continue;
		
		if(!isDefined(self.pers["hardPointItem"]))
			continue;
			
		if(self HasThreat())
			continue;
			
		if(self isDefusing() || self isPlanting() || self InLastStand())
			continue;

		curWeap = self GetCurrentWeapon();
			
		targetPos = undefined;
		switch(self.pers["hardPointItem"])
		{
			case "radar_mp":
				if(self.bot_radar && self.pers["bots"]["skill"]["base"] > 3)
					continue;
				break;
		
			case "helicopter_mp":
				chopper = level.chopper;

				if (isDefined(chopper) && !isEntity(chopper))
					chopper = level.chopper[self.team];

				if (isDefined(chopper))
					continue;

				if (isDefined( level.mannedchopper ))
					continue;

				break;
		
			case "airstrike_mp":
				if(isDefined( level.airstrikeInProgress ))
					continue;
					
				players = [];
				for(i = level.players.size - 1; i >= 0; i--)
				{
					player = level.players[i];
				
					if(player == self)
						continue;
					if(!isDefined(player.team))
						continue;
					if(level.teamBased && self.team == player.team)
						continue;
					if(player.sessionstate != "playing")
						continue;
					if(!isAlive(player))
						continue;
					if(player hasPerk("specialty_gpsjammer"))
						continue;
					if(!bulletTracePassed(player.origin, player.origin+(0,0,512), false, player) && self.pers["bots"]["skill"]["base"] > 3)
						continue;
						
					players[players.size] = player;
				}
				
				target = random(players);
				
				if(isDefined(target))
					targetPos = target.origin + (randomIntRange((8-self.pers["bots"]["skill"]["base"])*-75, (8-self.pers["bots"]["skill"]["base"])*75), randomIntRange((8-self.pers["bots"]["skill"]["base"])*-75, (8-self.pers["bots"]["skill"]["base"])*75), 0);
				else if(self.pers["bots"]["skill"]["base"] <= 3)
					targetPos = self.origin + (randomIntRange(-512, 512), randomIntRange(-512, 512), 0);
				break;

			default:
				continue;
		}
		
		isAirstrikePos = isDefined(targetPos);
		if(self.pers["hardPointItem"] == "airstrike_mp" && !isAirstrikePos)
			continue;

		self BotStopMoving(true);
						
		if (self changeToWeapon(self.pers["hardPointItem"]))
		{
			wait 1;

			if (isAirstrikePos && !isDefined( level.airstrikeInProgress ))
			{
				self notify( "confirm_location", targetPos );
				wait 1;
			}

			self thread changeToWeapon(curWeap);
		}

		self BotStopMoving(false);
	}
}

/*
	Bot logic for UAV detection here. Checks for UAV and players who are shooting.
*/
bot_uav_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	for(;;)
	{
		wait 0.75;
			
		if(self.pers["bots"]["skill"]["base"] <= 1)
			continue;
		
		if( level.hardcoreMode && !self.bot_radar )
			continue;
			
		dist = self.pers["bots"]["skill"]["help_dist"];
		dist *= dist * 8;
		
		for ( i = level.players.size - 1; i >= 0; i-- )
		{
			player = level.players[i];
			
			if(player == self)
				continue;
				
			if(!isDefined(player.team))
				continue;
				
			if(player.sessionstate != "playing")
				continue;
			
			if(level.teambased && player.team == self.team)
				continue;
			
			if(!isAlive(player))
				continue;
			
			distFromPlayer = DistanceSquared(self.origin, player.origin);
			if(distFromPlayer > dist)
				continue;
			
			if((!isSubStr(player getCurrentWeapon(), "_silencer_") && player.bots_firing) || (self.bot_radar && !player hasPerk("specialty_gpsjammer")))
			{
				distSq = self.pers["bots"]["skill"]["help_dist"] * self.pers["bots"]["skill"]["help_dist"];
				if (distFromPlayer < distSq && bulletTracePassed(self getEyePos(), player getTagOrigin( "j_spineupper" ), false, player))
				{
					self SetAttacker(player);
				}

				if (!self HasScriptGoal() && !self.bot_lock_goal)
				{
					self thread stop_go_target_on_death(player);
					self SetScriptGoal( player.origin, 128 );

					if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
						self ClearScriptGoal();
				}
				break;
			}
		}
	}
}

/*
	Bot logic for detecting the chopper as an enemy.
*/
bot_target_vehicle()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	for(;;)
	{
		wait( RandomIntRange( 2, 4 ) );

		if(self.pers["bots"]["skill"]["base"] <= 1)
			continue;
		
		if(self HasScriptEnemy())
			continue;
			
		if(!self getAmmoCount("rpg_mp") && self BotGetRandom() < 90)
			continue;

		chopper = level.chopper;

		if(isDefined(chopper) && !isEntity(chopper))
		{
			chopper = level.chopper[ level.otherTeam[self.team] ];
		}

		if (!isdefined(chopper))
			continue;
		
		if(!isDefined(level.bot_chopper) || !level.bot_chopper)//must be crashing or leaving
			continue;
			
		if(isDefined(chopper.owner) && chopper.owner == self)
			continue;
			
		if(chopper.team == self.team && level.teamBased)
			continue;
			
		if(!bulletTracePassed( self getEyePos(), chopper.origin + (0, 0, -5), false, chopper ))
			continue;
			
		self SetScriptEnemy( chopper, (0, 0, -5) );
		self bot_attack_vehicle(chopper);
		self ClearScriptEnemy();
		self notify("bot_force_check_switch");
	}
}

/*
	Bot logic for how long to keep targeting chopper.
*/
bot_attack_vehicle(chopper)
{
	chopper endon( "death" );
	chopper endon( "crashing" );
	chopper endon( "leaving" );
	
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		self notify("bot_force_check_switch");
		wait( 1 );

		if ( !IsDefined( chopper ) )
		{
			return;
		}
	}
}

/*
	Bot logic for targeting equipment.
*/
bot_equipment_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	for(;;)
	{
		wait( RandomIntRange( 1, 3 ) );
		
		if(self HasScriptEnemy())
			continue;

		if(self.pers["bots"]["skill"]["base"] <= 1)
			continue;
		
		grenades = GetEntArray( "grenade", "classname" );
		myEye = self getEyePos();
		myAngles = self getPlayerAngles();
		target = undefined;
		hasDetectExp = self hasPerk("specialty_detectexplosive");

		for ( i = grenades.size - 1; i >= 0; i-- )
		{
			item = grenades[i];

			if ( !IsDefined( item.name ) )
			{
				continue;
			}

			if ( IsDefined( item.owner ) && ((level.teamBased && item.owner.team == self.team) || item.owner == self) )
			{
				continue;
			}
			
			if (item.name != "c4_mp" && item.name != "claymore_mp")
				continue;
				
			if(!hasDetectExp && !bulletTracePassed(myEye, item.origin+(0, 0, 0), false, item))
				continue;
				
			if(getConeDot(item.origin, self.origin, myAngles) < 0.6)
				continue;
			
			if ( DistanceSquared( item.origin, self.origin ) < 512 * 512 )
			{
				target = item;
				break;
			}
		}
		
		if(isDefined(target))
		{
			self SetScriptEnemy( target, (0, 0, 0) );
			self bot_equipment_attack(target);
			self ClearScriptEnemy();
		}
	}
}

/*
	How long to keep targeting the equipment.
*/
bot_equipment_attack(equ)
{
	equ endon("death");
	
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !IsDefined( equ ) )
		{
			return;
		}
	}
}
