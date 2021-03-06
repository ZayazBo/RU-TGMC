//ATTENTION
//Due numerous changes related only to tank, some of which are, apparently, cannot be moved to tank.dm
//this file will be only for tank
//I will make cm_transport for APC, coping content of this file and editing it. A lot.

//NOT bitflags, just global constant values
#define HDPT_PRIMARY "primary"
#define HDPT_SECDGUN "secondary"
#define HDPT_SUPPORT "support"
#define HDPT_ARMOR "armor"
#define HDPT_TREADS "treads"
#define WEIGHT_LIGHT "light"
#define WEIGHT_MEDIUM "medium"
#define WEIGHT_HEAVY "heavy"

//Percentages of what hardpoints take what damage, e.g. armor takes 37.5% of the damage
var/list/tank_dmg_distributions = list(
	HDPT_PRIMARY = 0.15,
	HDPT_SECDGUN = 0.125,
	HDPT_SUPPORT = 0.075,
	HDPT_ARMOR = 0.5,
	HDPT_TREADS = 0.15)

//Currently unused, I thought I was gonna need to fuck with stuff but we good
/*
var/list/TANK_HARDPOINT_OFFSETS = list(
	HDPT_MAINGUN = "0,0",
	HDPT_SECDGUN = "0,0",
	HDPT_SUPPORT = "0,0",
	HDPT_ARMOR = "0,0",
	HDPT_TREADS = "0,0")*/

/client/proc/remove_players_from_tank()
	set name = "Eject TCs from tank (emergency only)"
	set category = "Admin"

	for(var/obj/vehicle/multitile/root/cm_armored/CA in view())
		CA.remove_all_players()
		log_admin("[src] forcibly removed all players from [CA]")
		message_admins("[src] forcibly removed all players from [CA]")

//The main object, should be an abstract class
/obj/vehicle/multitile/root/cm_armored
	name = "Armored Vehicle"
	desc = "Get inside to operate the vehicle."
	hitbox_type = /obj/vehicle/multitile/hitbox/cm_armored //Used for emergencies and respawning hitboxes

	//What slots the vehicle can have
	var/list/hardpoints = list(HDPT_SUPPORT, HDPT_TREADS, HDPT_ARMOR, HDPT_SECDGUN, HDPT_PRIMARY)

	//The next world.time when the tank can move
	var/next_move = 0

	//smoke deploy system
	var/smoke_ammo_max = 10		//one use consumes 2 smoke nades, so always put even number
	var/smoke_ammo_current = 0
	var/smoke_next_use
	var/obj/item/hardpoint/tank/support/smoke_launcher/SML	//literally inbuilt smoke launcher.
	//needed to be referenced in firing proc as gun we fire from(for some reason, I couldn't use tank itself), that's why it's here


	//Below are vars that can be affected by hardpoints, generally used as ratios or decisecond timers

	move_delay = 70 //treads-less tank barely moves. Fix those damn treads, marine!
	var/speed
	unacidable = 1
	var/active_hp
	var/vehicle_weight = 0		//tank mass = summarized mass of all installed hardpoints, very important for new weight system
	var/vehicle_class = WEIGHT_LIGHT			//tank class. Depends on vehicle_weight. Xenos behaviour after tank bumps into them depends on tank class

	//list of damag distribution among all installed AND not broken hardpoint modules
	var/list/dmg_distribs = list()

	//weight buffs/debuffs
	var/list/w_ratios = list(
		"w_prim_acc" = 1.0,
		"w_secd_acc" = 1.0,
		"w_supp_acc" = 1.0)

	//Changes cooldowns and accuracies
	var/list/misc_ratios = list(
		"OD_buff" = FALSE,
		"prim_acc" = 1.0,
		"secd_acc" = 1.0,
		"supp_acc" = 1.0,
		"prim_cool" = 1.0,
		"secd_cool" = 1.0,
		"supp_cool" = 1.0)

	//Percentage accuracies for slot
	var/list/accuracies = list(
		"primary" = 0.97,
		"secondary" = 0.67,
		"support" = 0.5)

	//Changes how much damage the tank takes
	var/list/dmg_multipliers = list(
		"all" = 1.0,	//for when you want to make it invincible
		"acid" = 1.5,	//tank without armor will be quite fast, so it needs some serious weak spot, the most obvious thing is acid resistance.
		"slash" = 1.0,	//full slash damage without armor seems fair
		"bullet" = 0.67,	//it's a huge metal box, it has basic bullet protection
		"explosive" = 1.0,
		"blunt" = 0.9,
		"abstract" = 1.0) //abstract for when you just want to hurt it

	//Decisecond cooldowns for the slots
	var/list/cooldowns = list(
		"primary" = 300,
		"secondary" = 200,
		"support" = 150)

	//Which hardpoints need to be repaired before the module can be replaced
	var/list/damaged_hps = list()

	//Placeholders
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "cargo_engine"
/obj/vehicle/multitile/root/cm_armored/Destroy()
	for(var/i in linked_objs)
		var/obj/O = linked_objs[i]
		if(O == src) continue
		qdel(O, 1) //Delete all of the hitboxes etc

	. = ..()

//What to do if all ofthe installed modules have been broken
/obj/vehicle/multitile/root/cm_armored/proc/handle_all_modules_broken()
	return

/obj/vehicle/multitile/root/cm_armored/proc/deactivate_all_hardpoints()
	var/list/slots = get_activatable_hardpoints()
	for(var/slot in slots)
		var/obj/item/hardpoint/tank/HP = hardpoints[slot]
		if(!HP) continue
		HP.deactivate()

/obj/vehicle/multitile/root/cm_armored/proc/remove_all_players()
	return


	//proc to calculate new speed, class and accuracy modificators depending on current weight
	//speed_min = 3 - if vehicle_weight below 8
	//speed_max = 17.5 - heaviest possible build
	//speed_delay = 30 - broken treads (OD won't affect speed with broken speed anymore)
	//numbers in vehicle_weight represent relative weight of tank - summary of tank modules weight
	//less than 8 vehicle_weight means tank lacks modules. To discourage going commando on the tank
	//AND to prevent serious debuff on already not fully functioning tank, below 8 has the same stats
/obj/vehicle/multitile/root/cm_armored/proc/vehicle_class_update()

	switch (vehicle_weight)
		if(8)
			speed = 3.5 * ( (misc_ratios["OD_buff"]) ? 0.9 : 1 )	//this is needed for tweaking OD buff for different classes of tank
			vehicle_class = WEIGHT_LIGHT
			w_ratios["w_prim_acc"] = 0.91
			w_ratios["w_secd_acc"] = 0.93
			//w_ratios["w_supp_acc"] = 0.92
		if(9)
			speed = 4.2 * ( (misc_ratios["OD_buff"]) ? 0.8 : 1 )
			vehicle_class = WEIGHT_LIGHT
			w_ratios["w_prim_acc"] = 0.93
			w_ratios["w_secd_acc"] = 0.96
			//w_ratios["w_supp_acc"] = 0.95
		if(10)
			speed = 5 * ( (misc_ratios["OD_buff"]) ? 0.7 : 1 )
			vehicle_class = WEIGHT_LIGHT
			w_ratios["w_prim_acc"] = 0.96
			w_ratios["w_secd_acc"] = 0.99
			//w_ratios["w_supp_acc"] = 0.97
		if(11)
			speed = 5.5 * ( (misc_ratios["OD_buff"]) ? 0.65 : 1 )
			vehicle_class = WEIGHT_MEDIUM
			w_ratios["w_prim_acc"] = 1.0
			w_ratios["w_secd_acc"] = 1.0
			//w_ratios["w_supp_acc"] = 1.0
		if(12)
			speed = 6 * ( (misc_ratios["OD_buff"]) ? 0.7 : 1 )
			vehicle_class = WEIGHT_MEDIUM
			w_ratios["w_prim_acc"] = 1.0
			w_ratios["w_secd_acc"] = 1.0
			//w_ratios["w_supp_acc"] = 1.0
		if(13)
			speed = 7 * ( (misc_ratios["OD_buff"]) ? 0.75 : 1 )
			vehicle_class = WEIGHT_MEDIUM
			w_ratios["w_prim_acc"] = 1.0
			w_ratios["w_secd_acc"] = 1.0
			//w_ratios["w_supp_acc"] = 1.0
		if(14)
			speed = 7.5 * ( (misc_ratios["OD_buff"]) ? 0.8 : 1 )
			vehicle_class = WEIGHT_MEDIUM
			w_ratios["w_prim_acc"] = 1.0
			w_ratios["w_secd_acc"] = 1.0
			//w_ratios["w_supp_acc"] = 1.0
		if(15)
			speed = 8 * ( (misc_ratios["OD_buff"]) ? 0.85 : 1 )
			vehicle_class = WEIGHT_MEDIUM
			w_ratios["w_prim_acc"] = 1.0
			w_ratios["w_secd_acc"] = 1.0
			//w_ratios["w_supp_acc"] = 1.0
		if(16)
			speed = 10 * ( (misc_ratios["OD_buff"]) ? 0.7 : 1 )
			vehicle_class = WEIGHT_HEAVY
			w_ratios["w_prim_acc"] = 1.02
			w_ratios["w_secd_acc"] = 1.01
			//w_ratios["w_supp_acc"] = 1.01
		if(17)
			speed = 11.5 * ( (misc_ratios["OD_buff"]) ? 0.74 : 1 )
			vehicle_class = WEIGHT_HEAVY
			w_ratios["w_prim_acc"] = 1.03
			w_ratios["w_secd_acc"] = 1.02
			//w_ratios["w_supp_acc"] = 1.02
		if(18)
			vehicle_class = WEIGHT_HEAVY
			w_ratios["w_prim_acc"] = 1.04
			w_ratios["w_secd_acc"] = 1.03
			//w_ratios["w_supp_acc"] = 1.03
		if(19)
			speed = 14.5 * ( (misc_ratios["OD_buff"]) ? 0.82 : 1 )
			vehicle_class = WEIGHT_HEAVY
			w_ratios["w_prim_acc"] = 1.05
			w_ratios["w_secd_acc"] = 1.04
			//w_ratios["w_supp_acc"] = 1.04

		else
			speed = 3.0 * ( (misc_ratios["OD_buff"]) ? 0.95 : 1 )
			vehicle_class = WEIGHT_LIGHT
			w_ratios["w_prim_acc"] = 0.9
			w_ratios["w_secd_acc"] = 0.9
			//w_ratios["w_supp_acc"] = 0.90


//The basic vehicle code that moves the tank, with movement delay implemented
/obj/vehicle/multitile/root/cm_armored/relaymove(var/mob/user, var/direction)
	if(world.time < next_move) return
	if(hardpoints[HDPT_TREADS] && hardpoints[HDPT_TREADS].health > 0)	//OD doesn't affect moving without treads anymore
		next_move = world.time + src.speed
	else
		next_move = world.time + move_delay


	return ..()

//Same thing but for rotations
/obj/vehicle/multitile/root/cm_armored/try_rotate(var/deg, var/mob/user, var/force = 0)
	if(world.time < next_move && !force) return

	if(hardpoints[HDPT_TREADS] && hardpoints[HDPT_TREADS].health > 0)	//same goes for turning
		next_move = world.time + src.speed * (force ? 2 : 3) //3 for a 3 point turn, idk
	else
		next_move = world.time + move_delay * (force ? 2 : 3)

	return ..()

/obj/vehicle/multitile/root/cm_armored/proc/can_use_hp(var/mob/M)
	return 1

//No one but the gunner can gun
//And other checks to make sure you aren't breaking the law
/obj/vehicle/multitile/root/cm_armored/tank/handle_click(var/mob/living/user, var/atom/A, var/list/mods)

//sadly, point-to requires mob to give message in chat and probably is the reason why it doesn't work from inside of a tank
//	if (mods["shift"] && mods["middle"])
//		user.point_to(A)
//		return

	if(usr.in_throw_mode)
		usr.drop_held_item()
		return

	if (mods["shift"])		//finally fixed shift-clicking in tank.
		user.examine()
		return

	if(!can_use_hp(user)) return

	if(!hardpoints.Find(active_hp))
		to_chat(user, "<span class='warning'>Please select an active hardpoint first.</span>")
		return

	var/obj/item/hardpoint/tank/HP = hardpoints[active_hp]

	if(!HP)
		return

	if(!HP.is_ready())
		return

	if(!HP.firing_arc(A))
		to_chat(user, "<span class='warning'>The target is not within your firing arc.</span>")
		return

	HP.active_effect(get_turf(A))

//Used by the gunner to swap which module they are using
//e.g. from the minigun to the smoke launcher
//Only the active hardpoint module can be used
/obj/vehicle/multitile/root/cm_armored/verb/switch_active_hp()
	set name = "Change Active Weapon"
	set category = "Vehicle"	//changed verb category to new one, because Object category is bad.
	set src = usr.loc

	if(!can_use_hp(usr))
		return

	var/mob/living/carbon/human/M = usr
	var/obj/item/card/id/I = M.wear_id
	if(I && I.rank == "Synthetic" && I.registered_name == M.real_name)
		to_chat(usr, "<span class='notice'>Your programm doesn't allow operating tank weapons.</span>")
		return

	var/list/slots = get_activatable_hardpoints()

	if(!slots.len)
		to_chat(usr, "<span class='warning'>All of the modules can't be activated or are broken.</span>")
		return

	var/slot = input("Select a slot.") in slots

	var/obj/item/hardpoint/tank/HP = hardpoints[slot]
	if(!HP)
		to_chat(usr, "<span class='warning'>There's nothing installed on that hardpoint.</span>")

	deactivate_binos(usr)
	active_hp = slot
	to_chat(usr, "<span class='notice'>You select the [HP.name].</span>")
	if(isliving(usr))
		M.set_interaction(src)



//anti-binoculars exploit fix
/obj/vehicle/multitile/root/cm_armored/proc/deactivate_binos(var/mob/user)
	for(var/obj/item/device/binoculars/BN in user.contents)
		if(BN.zoom)
			to_chat(usr, "<span class='warning'>You realize using [BN.name] and operating tank weapons at the same time is impossible!</span>")
			BN.zoom(user)

//proc to actually shoot smoke grenades
/obj/vehicle/multitile/root/cm_armored/proc/smoke_shot()

	if(world.time < smoke_next_use)
		to_chat(usr, "<span class='warning'>Smoke Deploy System is not ready!</span>")
		return

	//need to figure out better way to locate needed turfs to fire at
	var/turf/F
	var/turf/S
	var/right_dir
	var/left_dir
	F = get_step(src.loc, src.dir)
	F = get_step(F, src.dir)
	F = get_step(F, src.dir)
	F = get_step(F, src.dir)
	F = get_step(F, src.dir)
	left_dir = turn(src.dir, -90)
	S = get_step(F, left_dir)
	S = get_step(S, left_dir)
	right_dir = turn(src.dir, 90)
	F = get_step(F, right_dir)
	F = get_step(F, right_dir)

	//this is basically a copypasta from Hardpoints shooting proc with a modifcations
	var/obj/item/ammo_magazine/tank/tank_slauncher/A = new
	smoke_next_use = world.time + 150
	var/obj/item/projectile/P = new
	P.generate_bullet(new A.default_ammo)
	P.fire_at(F, src, SML, 6, P.ammo.shell_speed)
	//playsound(get_turf(src), 'sound/weapons/tank_smokelauncher_fire2.ogg', 60, 1)
	smoke_ammo_current--
	sleep (10)
	var/obj/item/projectile/G = new
	G.generate_bullet(new A.default_ammo)
	G.fire_at(S, src, SML, 6, G.ammo.shell_speed)
	//playsound(get_turf(src), 'sound/weapons/tank_smokelauncher_fire2.ogg', 60, 1)
	smoke_ammo_current--

	if(smoke_ammo_current <= 0)
		to_chat(usr, "<span class='warning'>Ammo depleted. Ejecting empty magazine.</span>")
		A.Move(entrance.loc)
		A.current_rounds = 0
		A.update_icon()


//verb shows only to TCs status update on their tank including: ammo and backup clips in weapons and combined health of all modules showed in %
/obj/vehicle/multitile/root/cm_armored/verb/tank_status()
	set name = "Check Vehicle Status"
	set category = "Vehicle"	//changed verb category to new one, because Object category is bad.
	set src = usr.loc

	var/obj/item/hardpoint/tank/HP1 = hardpoints[HDPT_ARMOR]
	var/obj/item/hardpoint/tank/HP2 = hardpoints[HDPT_TREADS]
	var/obj/item/hardpoint/tank/HP3 = hardpoints[HDPT_SUPPORT]
	var/obj/item/hardpoint/tank/HP4 = hardpoints[HDPT_SECDGUN]
	var/obj/item/hardpoint/tank/HP5 = hardpoints[HDPT_PRIMARY]
	var divider = 0
	var tank_health = 0
	//if(HP1 != null && HP2 != null && HP3 != null && HP4 != null && HP5 != null))
	//	tank_health = round((HP1.health + HP2.health + HP3.health + HP4.health + HP5.health) * 100 / (HP1.maxhealth + HP2.maxhealth + HP3.maxhealth + HP4.maxhealth + HP5.maxhealth))
	//First version of formula. Doesn't work if any of modules is absent or took too much damage (admin magic)
	if (HP1)
		if(HP1.health > 0)
			tank_health += HP1.health
		divider += abs(HP1.maxhealth)
	if (HP2)
		if(HP2.health > 0)
			tank_health += HP2.health
		divider += abs(HP2.maxhealth)
	if (HP3)
		if(HP3.health > 0)
			tank_health += HP3.health
		divider += abs(HP3.maxhealth)
	if (HP4)
		if(HP4.health > 0)
			tank_health += HP4.health
		divider += abs(HP4.maxhealth)
	if (HP5)
		if(HP5.health > 0)
			tank_health += HP5.health
		divider += abs(HP5.maxhealth)

	if(divider == 0)
		tank_health = round(tank_health * 100 / (divider + 1))
	else
		tank_health = round(tank_health * 100 / (divider))

	if(tank_health <= 5)
		to_chat(usr, "<span class='warning'>Warning! Systems failure, eject!</span><br>")
		return

	to_chat(usr, "<span class='warning'>Vehicle Status:</span><br>")
	to_chat(usr, "<span class='warning'>Overall vehicle integrity: [tank_health] percent.</span>")
	to_chat(usr, "<span class='warning'>M75 Smoke Deploy System: [smoke_ammo_current / 2] uses left.</span>")

	if(HP5 == null || HP5.health <= 0)
		to_chat(usr, "<span class='warning'>Primary weapon: Unavailable.</span>")
	else
		if(HP5.clips.len <= 0)
			to_chat(usr, "<span class='warning'>Primary weapon: [HP5.name]. Ammo: 0/0. 0/0 spare magazines available.</span>")
		else
			to_chat(usr, "<span class='warning'>Primary weapon: [HP5.name]. Ammo: [HP5.clips[1].current_rounds]/[HP5.clips[1].max_rounds]. [HP5.clips.len - 1]/[HP5.max_clips - 1] spare magazines available.</span>")
	if(HP4 == null || HP4.health <= 0)
		to_chat(usr, "<span class='warning'>Secondary weapon: Unavailable.</span>")
	else
		if(HP4.clips.len <= 0)
			to_chat(usr, "<span class='warning'>Secondary weapon: [HP4.name]. Ammo: 0/0. 0/0 spare magazines available.</span>")
		else
			to_chat(usr, "<span class='warning'>Secondary weapon: [HP4.name]. Ammo: [HP4.clips[1].current_rounds]/[HP4.clips[1].max_rounds]. [HP4.clips.len - 1]/[HP4.max_clips - 1] spare magazines available.</span><br>")

/obj/vehicle/multitile/root/cm_armored/verb/reload_hp()
	set name = "Reload Weapon"
	set category = "Vehicle"	//changed verb category to new one, because Object category is bad.
	set src = usr.loc

	if(!can_use_hp(usr)) return

	//TODO: make this a proc so I don't keep repeating this code
	var/list/slots = get_activatable_hardpoints()

	if(!slots.len)
		to_chat(usr, "<span class='warning'>All of the modules can't be reloaded or are broken.</span>")
		return

	var/answer = alert(usr, "Are you sure you want to reload?", , "Yes", "No") // added confirmation window, because you can't cancel reload once list of modules shows up
	if(answer == "No")
		return

	var/slot = input("Select a slot.") in slots

	var/obj/item/hardpoint/tank/HP = hardpoints[slot]
	if(HP.clips.len < 1)
		to_chat(usr, "<span class='warning'>[HP.name] has no clips left in it!</span>")
		return

	//if(!A)
	//	to_chat(usr, "<span class='danger'>Something went wrong! PM a staff member! Code: T_RHPN</span>")
	//	return

	to_chat(usr, "<span class='notice'>You begin emptying [HP.name].</span>")

	sleep(20)
	var/obj/item/ammo_magazine/A = HP.clips[1]
	HP.clips[1].Move(entrance.loc)	//LISTS START AT 1 REEEEEEEEEEEE
	HP.clips[1].update_icon()
	HP.clips.Remove(A)
	if(HP.clips.len > 0)
		to_chat(usr, "<span class='notice'>You reload the [HP.name].</span>")
	else
		to_chat(usr, "<span class='notice'>You empty the [HP.name].</span>")
	playsound(src, 'sound/weapons/gun_mortar_unpack.ogg', 40, 1)

/obj/vehicle/multitile/root/cm_armored/proc/get_activatable_hardpoints()
	var/list/slots = list()
	if(hardpoints.len)
		for(var/slot in hardpoints)
			var/obj/item/hardpoint/tank/HP = hardpoints[slot]
			if(!HP) continue
			if(HP.health <= 0) continue
			if(!HP.is_activatable) continue
			slots += slot
	return slots

//Specialness for armored vics
/obj/vehicle/multitile/root/cm_armored/load_hitboxes(var/datum/coords/dimensions, var/datum/coords/root_pos)

	var/start_x = -1 * root_pos.x_pos
	var/start_y = -1 * root_pos.x_pos
	var/end_x = start_x + dimensions.x_pos - 1
	var/end_y = start_y + dimensions.y_pos - 1

	for(var/i = start_x to end_x)

		for(var/j = start_y to end_y)

			if(i == 0 && j == 0)
				continue

			var/datum/coords/C = new
			C.x_pos = i
			C.y_pos = j
			C.z_pos = 0

			var/obj/vehicle/multitile/hitbox/cm_armored/H = new(locate(src.x + C.x_pos, src.y + C.y_pos, src.z))
			H.dir = dir
			H.root = src
			linked_objs[C] = H

/obj/vehicle/multitile/root/cm_armored/load_entrance_marker(var/datum/coords/rel_pos)

	entrance = new(locate(src.x + rel_pos.x_pos, src.y + rel_pos.y_pos, src.z))
	entrance.master = src
	linked_objs[rel_pos] = entrance

//Returns 1 or 0 if the slot in question has a broken installed hardpoint or not
/obj/vehicle/multitile/root/cm_armored/proc/is_slot_damaged(var/slot)
	var/obj/item/hardpoint/tank/HP = hardpoints[slot]

	if(!HP) return 0

	if(HP.health <= 0) return 1

//Normal examine() but tells the player what is installed and if it's broken
/obj/vehicle/multitile/root/cm_armored/examine(var/mob/user)
	..()
	for(var/i in hardpoints)
		var/obj/item/hardpoint/tank/HP = hardpoints[i]
		if(!HP)
			to_chat(user, "There is nothing installed on the [i] hardpoint slot.")
		else
			if(isXeno(user))
				if(HP.health <= 0)
					to_chat(user, "There is a broken module installed on [i] hardpoint slot.")
				if(HP.health > 0 && (HP.health < (HP.maxhealth / 3)))
					to_chat(user, "There is a heavily damaged module installed on [i] hardpoint slot.")
				if((HP.health > (HP.maxhealth / 3)) && (HP.health < (HP.maxhealth * (2/3))))
					to_chat(user, "There is a damaged module installed on [i] hardpoint slot.")			//removed modules' names for aliens.
				if((HP.health > (HP.maxhealth * (2/3))) && (HP.health < HP.maxhealth))
					to_chat(user, "There is a lightly damaged module installed on [i] hardpoint slot.")
				if(HP.health == HP.maxhealth)
					to_chat(user, "There is a non-damaged module installed on [i] hardpoint slot.")
			else
				if(HP.health <= 0)
					to_chat(user, "There is a broken [HP] installed on [i] hardpoint slot.")
				if(HP.health > 0 && (HP.health < (HP.maxhealth / 3)))
					to_chat(user, "There is a heavily damaged [HP] installed on [i] hardpoint slot.")
				if((HP.health > (HP.maxhealth / 3)) && (HP.health < (HP.maxhealth * (2/3))))
					to_chat(user, "There is a damaged [HP] installed on [i] hardpoint slot.")			//removed skills check, because any baldie PFC can tell if module is unscratched or will fall apart from touching it
				if((HP.health > (HP.maxhealth * (2/3))) && (HP.health < HP.maxhealth))
					to_chat(user, "There is a lightly damaged [HP] installed on [i] hardpoint slot.")
				if(HP.health == HP.maxhealth)
					to_chat(user, "There is a non-damaged [HP] installed on [i] hardpoint slot.")
			//else
			//	to_chat(user, "There is a [HP.health <= 0 ? "broken" : "working"] [HP] installed on the [i] hardpoint slot.")


//Special armored vic healthcheck that mainly updates the hardpoint states
/obj/vehicle/multitile/root/cm_armored/healthcheck()
	health = maxhealth //The tank itself doesn't take damage
	var/i
	var/remove_person = 1 //Whether or not to call handle_all_modules_broken()
	for(i in hardpoints)
		var/obj/item/hardpoint/tank/H = hardpoints[i]
		if(!H) continue
		if(H.health <= 0)
			H.remove_buff()
			if(H.slot != HDPT_TREADS) damaged_hps |= H.slot //Not treads since their broken module overlay is the same as the broken hardpoint overlay
		else remove_person = 0 //if something exists but isnt broken

	if(remove_person)
		handle_all_modules_broken()

	update_icon()


//Since the vics are 3x4 we need to swap between the two files with different dimensions
//Also need to offset to center the tank about the root object
/obj/vehicle/multitile/root/cm_armored/update_icon()

	overlays.Cut()

	//Assuming 3x3 with half block overlaps in the tank's direction
	if(dir in list(NORTH, SOUTH))
		pixel_x = -32
		pixel_y = -48
		icon = 'icons/obj/tank_NS.dmi'

	else if(dir in list(EAST, WEST))
		pixel_x = -48
		pixel_y = -32
		icon = 'icons/obj/tank_EW.dmi'

	//Basic iteration that snags the overlay from the hardpoint module object
	var/i
	for(i in hardpoints)
		var/obj/item/hardpoint/tank/H = hardpoints[i]

		if(i == HDPT_TREADS && (!H || H.health <= 0)) //Treads not installed or broken
			var/image/I = image(icon, icon_state = "damaged_hardpt_[i]")
			overlays += I
			continue

		if(H)
			var/image/I = H.get_icon_image(0, 0, dir)
			overlays += I

		if(damaged_hps.Find(i))
			var/image/I = image(icon, icon_state = "damaged_hardpt_[i]")
			overlays += I

//Hitboxes but with new names
/obj/vehicle/multitile/hitbox/cm_armored
	name = "Armored Vehicle"
	desc = "Get inside to operate the vehicle."
	luminosity = 7
	throwpass = 1 //You can lob nades over tanks, and there's some dumb check somewhere that requires this
	var/lastsound = 0

//If something want to delete this, it's probably either an admin or the shuttle
//If it's an admin, they want to disable this
//If it's the shuttle, it should do damage
//If fully repaired and moves at least once, the broken hitboxes will respawn according to multitile.dm
/obj/vehicle/multitile/hitbox/cm_armored/Destroy()
	var/obj/vehicle/multitile/root/cm_armored/C = root
	if(C) C.take_damage_type(1000000, "abstract")
	..()

//Tramplin' time, but other than that identical
/obj/vehicle/multitile/hitbox/cm_armored/Bump(var/atom/A)
	. = ..()
	var/obj/vehicle/multitile/root/cm_armored/CA = root
	if(isliving(A))
		var/mob/living/M = A
		if(isXeno(M))
			var/mob/living/carbon/Xenomorph/XEN = M
			switch(CA.vehicle_class)
				if(WEIGHT_LIGHT)
					switch(XEN.upgrade)
						if(0)
							M.KnockDown(5)
						if(1)
							var/facing = get_dir(src, M)
							var/turf/T = loc
							var/turf/temp = loc
							for(var/i=0;i<3;i++)
								temp = get_step(temp, facing)
							T = get_step(temp, pick(cardinal))
							M.throw_at(T, 4, 1, src, 1)
							M.KnockDown(1)
							M.apply_damage(5 + rand(5, 10), BRUTE)
							if(istype(CA.hardpoints[HDPT_ARMOR], /obj/item/hardpoint/tank/armor/snowplow))
								M.apply_damage(10 + rand(5, 10), BRUTE)
						if(2)
							if(istype(CA.hardpoints[HDPT_ARMOR], /obj/item/hardpoint/tank/armor/snowplow))
								M.apply_damage(10 + rand(5, 10), BRUTE)
							step_away(M,root,0)
							step_away(M,root,0)
						if(3)
							//M.visible_message("<span class='danger'>[M] pushes against the [src], holding it in place with ease!</span>", "<span class='xenodanger'>You stopped [src]! It's no match to you!</span>")
							return
				if(WEIGHT_MEDIUM)
					switch(XEN.upgrade)
						if(0)
							M.KnockDown(5)
						if(1)
							var/facing = get_dir(src, M)
							var/turf/T = loc
							var/turf/temp = loc
							temp = get_step(temp, facing)
							temp = get_step(temp, facing)
							T = get_step(temp, pick(cardinal))
							M.throw_at(T, 2, 1, src, 1)
							M.KnockDown(1)
							M.apply_damage(5 + rand(5, 10), BRUTE)
							if(istype(CA.hardpoints[HDPT_ARMOR], /obj/item/hardpoint/tank/armor/snowplow))
								M.apply_damage(5 + rand(5, 10), BRUTE)
						if(2)
							step_away(M,root,0)
							M.KnockDown(2)
							M.apply_damage(5 + rand(5, 10), BRUTE)
							if(istype(CA.hardpoints[HDPT_ARMOR], /obj/item/hardpoint/tank/armor/snowplow))
								M.apply_damage(5 + rand(5, 10), BRUTE)
						if(3)
							//M.visible_message("<span class='danger'>[M] pushes against the [src], holding it in place with effort!</span>", "<span class='xenodanger'>You stopped [src]!</span>")
							return
				if(WEIGHT_HEAVY)
					switch(XEN.upgrade)
						if(0)
							M.KnockDown(5)
						if(1)
							M.KnockDown(4)
							M.apply_damage(5 + rand(5, 10), BRUTE)
						if(2)
							step_away(M,root,0)
							M.KnockDown(4)
							M.apply_damage(5 + rand(5, 10), BRUTE)
						if(3)
							step_away(M,root,0)
							//M.visible_message("<span class='danger'>[M] pushes against the [src], trying to hold it in place, but fails!</span>", "<span class='danger'>[src] is much heavier, you can't hold it in place!</span>")
							return
		if (!isXeno(M))
			if(M.buckled)
				M.buckled.unbuckle()
			step_away(M,root,0,0)
			M.KnockDown(3)
			M.apply_damage(10 + rand(0, 10), BRUTE)
			if(istype(CA.hardpoints[HDPT_ARMOR], /obj/item/hardpoint/tank/armor/snowplow))
				M.apply_damage(10 + rand(5, 10), BRUTE)
		M.visible_message("<span class='danger'>[src] runs over [M]!</span>", "<span class='danger'>[src] runs you over! Get out of the way!</span>")
		log_attack("[src] drove over/bumped into [M]([M.client ? M.client.ckey : "disconnected"]).")
	else if(istype(A, /obj/structure/fence))
		var/obj/structure/fence/F = A
		F.visible_message("<span class='danger'>[root] smashes through [F]!</span>")
		F.health = 0
		F.healthcheck()
	else if(istype(A, /turf/closed/wall) && !istype(A, /turf/closed/wall/resin))
		var/turf/closed/wall/W = A
		W.take_damage(30)
		CA.take_damage_type(20, "blunt", W)
		if(world.time > lastsound + 10)
			playsound(W, 'sound/effects/metal_crash.ogg', 35)
			lastsound = world.time
		W.visible_message("<span class='danger'>[root] crushes into [W]!</span>")
	else if(istype(A, /turf/closed/wall/resin) && !istype(A, /turf/closed/wall/resin/thick))
		var/turf/closed/wall/RW = A
		RW.take_damage(250)
		CA.take_damage_type(10, "blunt", RW)
		playsound(RW, 'sound/effects/alien_resin_break1.ogg', 35)
		RW.visible_message("<span class='danger'>[root] crushes through [RW]!</span>")
	else if(istype(A, /turf/closed/wall/resin/thick))
		var/turf/closed/wall/RT = A
		RT.take_damage(500)
		CA.take_damage_type(20, "blunt", RT)
		playsound(RT, 'sound/effects/alien_resin_break2.ogg', 20)
		RT.visible_message("<span class='danger'>[root] crushes through [RT]!</span>")
	else if(istype(A, /obj/structure/mineral_door/resin))
		var/obj/structure/mineral_door/resin/R = A
		R.health = 0
		R.healthcheck()
	else if(istype(A, /obj/structure/table))
		var/obj/structure/table/T = A
		T.visible_message("<span class='danger'>[root] crushes [T]!</span>")
		T.Destroy(1)
	else if(istype(A, /obj/structure/rack))
		var/obj/structure/rack/RK = A
		RK.visible_message("<span class='danger'>[root] crushes [RK]!</span>")
		RK.Destroy(1)
	else if(istype(A, /obj/structure/girder))
		var/obj/structure/girder/G = A
		G.dismantle()
		CA.take_damage_type(15, "blunt", G)
		if(world.time > lastsound + 10)
			playsound(G, 'sound/effects/metal_crash.ogg', 35)
			lastsound = world.time
	else if (istype(A, /obj/structure/reagent_dispensers/watertank))
		var/obj/structure/reagent_dispensers/watertank/WT = A
		WT.visible_message("<span class='danger'>[root] crushes [WT]!</span>")
		new /obj/item/stack/sheet/metal(WT.loc, 1)
		qdel(WT)
	else if (istype(A, /obj/structure/reagent_dispensers/beerkeg))
		var/obj/structure/reagent_dispensers/beerkeg/BT = A
		BT.visible_message("<span class='danger'>[root] crushes [BT]!</span>")
		qdel(BT)
	else if (istype(A, /obj/structure/reagent_dispensers/fueltank))
		var/obj/structure/reagent_dispensers/fueltank/FT = A
		FT.visible_message("<span class='danger'>[root] crushes [FT]!</span>")
		FT.explode()
	else if (istype(A, /obj/structure/window_frame))
		var/obj/structure/window_frame/WF = A
		new /obj/item/stack/sheet/metal(WF.loc, 2)
		new /obj/item/stack/sheet/glass(WF.loc, 2)
		WF.visible_message("<span class='danger'>[root] crushes through [WF]!</span>")
		CA.take_damage_type(10, "blunt", WF)
		if(world.time > lastsound + 10)
			playsound(WF, 'sound/effects/metal_crash.ogg', 35)
			lastsound = world.time
		qdel(WF)
	else if (istype(A, /obj/structure/window))
		var/obj/structure/window/WN = A
		WN.visible_message("<span class='danger'>[root] smashes through [WN]!</span>")
		if(!WN.damageable)
			return
		WN.health = 0
		WN.healthcheck(0, 1)
	else if (istype(A, /obj/machinery/computer))
		var/obj/machinery/computer/CP = A
		if(CP.exproof)
			return
		CP.visible_message("<span class='danger'>[root] crushes [CP]!</span>")
		new /obj/item/stack/sheet/metal(CP.loc, 1)
		qdel(CP)
//from here goes list of newly added objects and machinery that tank should've drive over or through, but for some reason couldn't
	else if(istype(A, /obj/structure/bed) && !istype(A, /obj/structure/bed/chair/dropship) && !istype(A, /obj/structure/bed/medevac_stretcher) && !istype(A, /obj/structure/bed/roller) && !istype(A, /obj/structure/bed/chair/janicart))
		var/obj/structure/bed/BE = A
		BE.visible_message("<span class='danger'>[root] crushes [BE]!</span>")
		BE.Destroy()
		new /obj/item/stack/sheet/metal(BE.loc, 1)
	else if(istype(A, /obj/structure/bed/chair/janicart))
		var/obj/structure/bed/JC = A
		JC.visible_message("<span class='danger'>[root] crushes [JC]!</span>")
		qdel(JC)
	else if (istype(A, /obj/structure/filingcabinet))
		var/obj/structure/filingcabinet/FC = A
		FC.visible_message("<span class='danger'>[root] crushes [FC]!</span>")
		new /obj/item/stack/sheet/metal(FC.loc, 1)
		qdel(FC)
	else if (istype(A, /obj/machinery/autolathe))
		var/obj/machinery/autolathe/AL = A
		AL.visible_message("<span class='danger'>[root] crushes [AL]!</span>")
		new /obj/item/stack/sheet/metal(AL.loc, 2)
		new /obj/item/stack/sheet/metal(AL.loc, round(AL.stored_material["metal"] / 3750))
		new /obj/item/stack/sheet/glass(AL.loc, round(AL.stored_material["glass"] / 3750))
		qdel(AL)
	else if (istype(A, /obj/structure/filingcabinet))
		var/obj/structure/filingcabinet/FC = A
		FC.visible_message("<span class='danger'>[root] crushes [FC]!</span>")
		new /obj/item/stack/sheet/metal(FC.loc, 1)
		qdel(FC)
	else if (istype(A, /obj/machinery/autodoc))
		var/obj/machinery/autodoc/AD = A
		AD.visible_message("<span class='danger'>[root] crushes [AD]!</span>")
		new /obj/item/stack/sheet/plasteel(AD.loc, 2)
		qdel(AD)
	else if (istype(A, /obj/machinery/biogenerator))
		var/obj/machinery/biogenerator/BI = A
		BI.visible_message("<span class='danger'>[root] crushes [BI]!</span>")
		new /obj/item/stack/sheet/metal(BI.loc, 2)
		qdel(BI)
	else if (istype(A, /obj/machinery/seed_extractor))
		var/obj/machinery/seed_extractor/SE = A
		SE.visible_message("<span class='danger'>[root] crushes [SE]!</span>")
		new /obj/item/stack/sheet/metal(SE.loc, 2)
		qdel(SE)
	else if (istype(A, /obj/machinery/chem_dispenser))
		var/obj/machinery/chem_dispenser/DS = A
		DS.visible_message("<span class='danger'>[root] crushes [DS]!</span>")
		new /obj/item/stack/sheet/metal(DS.loc, 2)
		qdel(DS)
	else if (istype(A,	/obj/machinery/smartfridge))
		var	/obj/machinery/smartfridge/chemistry/SF = A
		SF.visible_message("<span class='danger'>[root] crushes [SF]!</span>")
		new /obj/item/stack/sheet/metal(SF.loc, 2)
		qdel(SF)
	else if (istype(A, /obj/machinery/photocopier))
		var/obj/machinery/photocopier/PC = A
		PC.visible_message("<span class='danger'>[root] crushes [PC]!</span>")
		new /obj/item/stack/sheet/metal(PC.loc, 1)
		qdel(PC)
	else if (istype(A, /obj/machinery/cryopod))
		var/obj/machinery/cryopod/CD = A
		CD.visible_message("<span class='danger'>[root] crushes [CD]!</span>")
		new /obj/item/stack/sheet/plasteel(CD.loc, 2)
		new /obj/item/stack/sheet/metal(CD.loc, 2)
		qdel(CD)
	else if (istype(A, /obj/machinery/optable))
		var/obj/machinery/optable/OT = A
		OT.visible_message("<span class='danger'>[root] crushes [OT]!</span>")
		new /obj/item/stack/sheet/plasteel(OT.loc, 2)
		qdel(OT)
	else if (istype(A, /obj/machinery/marine_selector))
		var/obj/machinery/marine_selector/MS = A
		MS.visible_message("<span class='danger'>[root] crushes [MS]!</span>")
		new /obj/item/stack/sheet/metal(MS.loc, 2)
		qdel(MS)
	else if (istype(A, /obj/machinery/vending))
		var/obj/machinery/vending/VD = A
		VD.visible_message("<span class='danger'>[root] crushes [VD]!</span>")
		new /obj/item/stack/sheet/metal(VD.loc, 2)
		qdel(VD)
	else if (istype(A, /obj/machinery/bodyscanner))
		var/obj/machinery/bodyscanner/BS = A
		BS.visible_message("<span class='danger'>[root] crushes [BS]!</span>")
		new /obj/item/stack/sheet/metal(BS.loc, 2)
		qdel(BS)
	else if (istype(A, /obj/machinery/sleeper))
		var/obj/machinery/sleeper/SL = A
		SL.visible_message("<span class='danger'>[root] crushes [SL]!</span>")
		new /obj/item/stack/sheet/metal(SL.loc, 2)
		qdel(SL)
	else if (istype(A, /obj/structure/largecrate))
		var/obj/structure/largecrate/LC = A
		LC.visible_message("<span class='danger'>[root] crushes [LC]!</span>")
		new /obj/item/stack/sheet/wood(LC.loc, 2)
		var/turf/T = get_turf(LC)
		for(var/obj/O in contents)
			O.loc = T
		qdel(LC)
	else if (istype(A, /obj/structure/showcase))
		var/obj/structure/showcase/SW = A
		SW.visible_message("<span class='danger'>[root] crushes [SW]!</span>")
		qdel(SW)
	else if (istype(A, /obj/structure/inflatable) && !istype(A, /obj/structure/inflatable/door))
		var/obj/structure/inflatable/IW = A
		IW.visible_message("<span class='danger'>[root] crushes [IW]!</span>")
		playsound(loc, 'sound/machines/hiss.ogg', 25, 1)
		visible_message("[IW] rapidly deflates!")
		flick("wall_popping", IW)
		new /obj/structure/inflatable/popped(IW.loc)
		qdel(IW)
	else if (istype(A, /obj/structure/inflatable/door))
		var/obj/structure/inflatable/ID = A
		ID.visible_message("<span class='danger'>[root] crushes [ID]!</span>")
		playsound(loc, 'sound/machines/hiss.ogg', 25, 1)
		visible_message("[ID] rapidly deflates!")
		flick("wall_popping", ID)
		new /obj/structure/inflatable/popped/door(ID.loc)
		qdel(ID)
	else if (istype(A, /obj/structure/closet))
		var/obj/structure/closet/crate/CL = A
		CL.break_open()
		CL.open()
		CL.visible_message("<span class='danger'>[root] crushes [CL]!</span>")
		new /obj/item/stack/sheet/metal(CL.loc, 1)
		qdel(CL)
	else if (istype(A, /obj/machinery/marine_turret))
		var/obj/machinery/marine_turret/MT = A
		MT.visible_message("<span class='danger'>[root] drives over [MT]!</span>")
		MT.stat = 1
		MT.density = 0
		MT.health = MT.health - 15
		MT.update_icon()
	else if (istype(A, /obj/structure/dropship_equipment/mg_holder))
		var/obj/structure/dropship_equipment/mg_holder/MGH = A
		MGH.visible_message("<span class='danger'>[root] crushes [MGH]!</span>")
		qdel(MGH)
	else if (istype(A, /obj/structure/mortar))
		var/obj/structure/mortar/MR = A
		var/turf/T = get_turf(MR)
		new /obj/item/mortar_kit(T)
		qdel(MR)
	else if(istype(A, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/FD = A
		FD.visible_message("<span class='danger'>[root] crushes through[FD]!</span>")
		new /obj/item/stack/sheet/metal(FD.loc, 2)
		qdel(FD)
	else if(istype(A, /obj/machinery/door/airlock) && !istype(A, /obj/machinery/door/airlock/multi_tile/almayer/dropshiprear/ds1) && !istype(A, /obj/machinery/door/airlock/multi_tile/almayer/dropshiprear/ds2))
		var/obj/machinery/door/airlock/AR = A
		CA.take_damage_type(20, "blunt", AR)
		if(world.time > lastsound + 10)
			playsound(AR, 'sound/effects/metal_crash.ogg', 35)
			lastsound = world.time
		AR.visible_message("<span class='danger'>[root] crushes through[AR]!</span>")
		new /obj/item/stack/sheet/metal(AR.loc, 2)
		qdel(AR)
	else if(istype(A, /obj/machinery/door/airlock/multi_tile/almayer/dropshiprear/ds1) || istype(A, /obj/machinery/door/airlock/multi_tile/almayer/dropshiprear/ds2))
		var/obj/machinery/door/airlock/multi_tile/almayer/dropshiprear/DR = A
		if(DR.locked)
			if(z == 4)
				return
			else
				CA.take_damage_type(20, "blunt", DR)
				if(world.time > lastsound + 10)
					playsound(DR, 'sound/effects/metal_crash.ogg', 35)
					lastsound = world.time
				DR.visible_message("<span class='danger'>[root] crushes through[DR]!</span>")
				new /obj/item/stack/sheet/metal(DR.loc, 2)
				qdel(DR)
		else
			DR.open()	//2/3 rounds TCs destroy reardoor in firstdeployment, this should fix it
	else if(istype(A, /obj/structure/bed/roller))
		var/obj/structure/bed/roller/RL = A
		RL.visible_message("<span class='danger'>[root] crushes [RL]!</span>")
		new /obj/item/stack/sheet/metal(RL.loc, 2)
		RL.manual_unbuckle()
		qdel(RL)
	else if(istype(A, /obj/structure/bed/medevac_stretcher))
		var/obj/structure/bed/medevac_stretcher/MES = A
		MES.visible_message("<span class='danger'>[root] crushes through[MES]!</span>")
		MES.manual_unbuckle()
		new /obj/item/roller/medevac(MES.loc)
		qdel(MES)
	else if(istype(A, /obj/machinery/door/poddoor/almayer))
		var/obj/machinery/door/poddoor/almayer/PA = A
		CA.take_damage_type(50, "blunt", PA)
		if(world.time > lastsound + 10)
			playsound(PA, 'sound/effects/metal_crash.ogg', 35)
			lastsound = world.time
		PA.visible_message("<span class='danger'>[root] crushes through[PA]!</span>")
		new /obj/item/stack/sheet/metal(PA.loc, 3)
		qdel(PA)
	else if(istype(A, /obj/machinery/door/poddoor/shutters) && !istype(A, /obj/machinery/door/poddoor/shutters/transit) && !istype(A, /obj/machinery/door/poddoor/shutters/almayer/pressure))
		var/obj/machinery/door/poddoor/almayer/SH = A
		CA.take_damage_type(30, "blunt", SH)
		playsound(SH, 'sound/effects/metal_crash.ogg', 35)
		SH.visible_message("<span class='danger'>[root] crushes through[SH]!</span>")
		qdel(SH)
	else if (istype(A, /obj/structure/ship_ammo))
		var/obj/structure/ship_ammo/SA = A
		SA.visible_message("<span class='danger'>[root] crushes [SA]!</span>")
		qdel(SA)
	else if (istype(A, /obj/structure/dropship_equipment) && !istype(A, /obj/structure/dropship_equipment/medevac_system))
		var/obj/structure/dropship_equipment/DE = A
		DE.visible_message("<span class='danger'>[root] crushes [DE]!</span>")
		qdel(DE)
	else if (istype(A, /obj/machinery/microwave))
		var/obj/machinery/microwave/MW = A
		MW.visible_message("<span class='danger'>[root] crushes [MW]!</span>")
		qdel(MW)
	else if (istype(A, /obj/machinery/processor))
		var/obj/machinery/processor/PR = A
		PR.visible_message("<span class='danger'>[root] crushes [PR]!</span>")
		qdel(PR)
	else if (istype(A, /obj/structure/ore_box))
		var/obj/structure/ore_box/OB = A
		OB.visible_message("<span class='danger'>[root] crushes [OB]!</span>")
		qdel(OB)
	else if (istype(A, /obj/structure/mopbucket))
		var/obj/structure/mopbucket/MB = A
		MB.visible_message("<span class='danger'>[root] crushes [MB]!</span>")
		qdel(MB)
	else if (istype(A, /obj/machinery/portable_atmospherics/hydroponics))
		var/obj/machinery/portable_atmospherics/hydroponics/HY = A
		new /obj/item/stack/sheet/metal(HY.loc, 1)
		HY.visible_message("<span class='danger'>[root] crushes [HY]!</span>")
		qdel(HY)
	else if (istype(A, /obj/structure/door_assembly))
		var/obj/structure/door_assembly/DA = A
		new /obj/item/stack/sheet/metal(DA.loc, 2)
		DA.visible_message("<span class='danger'>[root] crushes through[DA]!</span>")
		qdel(DA)
	else if (istype(A,/obj/structure/grille))
		var/obj/structure/grille/GR = A
		new /obj/item/stack/rods(GR.loc, 2)
		GR.visible_message("<span class='danger'>[root] crushes through[GR]!</span>")
		qdel(GR)
	else if (istype(A, /obj/structure/foamedmetal))
		var/obj/structure/foamedmetal/FM = A
		FM.visible_message("<span class='danger'>[root] crushes through[FM]!</span>")
		qdel(FM)
	else if (istype(A, /obj/structure/device))
		var/obj/structure/device/DV = A
		new /obj/item/stack/sheet/wood(DV.loc, 1)
		DV.visible_message("<span class='danger'>[root] crushes [DV]!</span>")
		qdel(DV)
	else if (istype(A, /obj/machinery/disposal))
		var/obj/machinery/disposal/DI = A
		new /obj/item/stack/sheet/metal(DI.loc, 2)
		DI.visible_message("<span class='danger'>[root] crushes [DI]!</span>")
		qdel(DI)
	else if (istype(A, /obj/vehicle/train))
		var/obj/vehicle/train/TR = A
		TR.visible_message("<span class='danger'>[root] crushes [TR]!</span>")
		TR.explode()
	else if (istype(A, /obj/machinery/door/window))
		var/obj/machinery/door/window/WD = A
		WD.visible_message("<span class='danger'>[root] smashes through[WD]!</span>")
		WD.take_damage(350)

	healthcheck()

/obj/vehicle/multitile/hitbox/cm_armored/Move(var/atom/A, var/direction)
	var/obj/vehicle/multitile/root/cm_armored/CA = root
	for(var/mob/living/M in get_turf(src))
		M.sleeping = 3 //Not 0, they just got driven over by a giant ass whatever and that hurts
		M.apply_damage(1, BRUTE)
	for(var/obj/effect/alien/egg/Eg in get_turf(src))
		Eg.Burst(1)
	for(var/obj/item/clothing/mask/facehugger/FG in get_turf(src))
		FG.Die()

	. = ..()

	if(.)
		for(var/obj/structure/bed/BD in get_turf(A))
			if(!istype(BD, /obj/structure/bed/chair/dropship) && !istype(BD, /obj/structure/bed/medevac_stretcher) && !istype(BD, /obj/structure/bed/roller) && !istype(BD, /obj/structure/bed/chair/janicart))
				BD.visible_message("<span class='danger'>[root] crushes [BD]!</span>")
				BD.Destroy()
		for(var/mob/living/M in get_turf(A))
			//I don't call Bump() otherwise that would encourage trampling for infinite unpunishable damage
			M.sleeping = 1 //Maintain their lying-down-ness
		for(var/obj/effect/alien/egg/Eg in get_turf(src))
			Eg.Burst(1)
		for(var/obj/item/clothing/mask/facehugger/FG in get_turf(src))
			FG.Die()
		for(var/obj/effect/xenomorph/spray/SR in get_turf(src))
			if(istype(CA.hardpoints[HDPT_TREADS], /obj/item/hardpoint/tank/treads/standard) && CA.hardpoints[HDPT_TREADS].health > 0)
				CA.hardpoints[HDPT_TREADS].health -= 10
				healthcheck()
			else
				if(istype(CA.hardpoints[HDPT_TREADS], /obj/item/hardpoint/tank/treads/heavy) && CA.hardpoints[HDPT_TREADS].health > 0)
					CA.hardpoints[HDPT_TREADS].health -= 5
					healthcheck()

/obj/vehicle/multitile/hitbox/cm_armored/Uncrossed(var/atom/movable/A)
	if(isliving(A))
		var/mob/living/M = A
		M.sleeping = 2

	return ..()

//Can't hit yourself with your own bullet
/obj/vehicle/multitile/hitbox/cm_armored/get_projectile_hit_chance(var/obj/item/projectile/P)
	if(P.firer == root) //Don't hit our own hitboxes
		return 0

	. = ..(P)

//For the next few, we're just tossing the handling up to the rot object
/obj/vehicle/multitile/hitbox/cm_armored/bullet_act(var/obj/item/projectile/P)
	return root.bullet_act(P)

/obj/vehicle/multitile/hitbox/cm_armored/ex_act(var/severity)
	return root.ex_act(severity)

/obj/vehicle/multitile/hitbox/cm_armored/attackby(var/obj/item/O, var/mob/user)
	return root.attackby(O, user)

/obj/vehicle/multitile/hitbox/cm_armored/attack_alien(var/mob/living/carbon/Xenomorph/M, var/dam_bonus)
	return root.attack_alien(M, dam_bonus)

//A bit icky, but basically if you're adjacent to the tank hitbox, you are then adjacent to the root object
/obj/vehicle/multitile/root/cm_armored/Adjacent(var/atom/A)
	for(var/i in linked_objs)
		var/obj/vehicle/multitile/hitbox/cm_armored/H = linked_objs[i]
		if(!H) continue
		if(get_dist(H, A) <= 1) return 1 //Using get_dist() to avoid hidden code that recurs infinitely here
	. = ..()

//Returns the ratio of damage to take, just a housekeeping thing
/obj/vehicle/multitile/root/cm_armored/proc/get_dmg_multi(var/type)
	if(!dmg_multipliers.Find(type)) return 0
	return dmg_multipliers[type] * dmg_multipliers["all"]

//Generic proc for taking damage
//ALWAYS USE THIS WHEN INFLICTING DAMAGE TO THE VEHICLES
/obj/vehicle/multitile/root/cm_armored/proc/take_damage_type(var/damage, var/type, var/atom/attacker)
	var/i
	for(i in hardpoints)
		var/obj/item/hardpoint/tank/HP = hardpoints[i]
		if(!istype(HP)) continue
		HP.health -= damage * dmg_distribs[i] * get_dmg_multi(type)

	if(istype(attacker, /mob))
		var/mob/M = attacker
		log_attack("[src] took [damage] [type] damage from [M] ([M.client ? M.client.ckey : "disconnected"]).")
	else
		log_attack("[src] took [damage] [type] damage from [attacker].")

/obj/vehicle/multitile/root/cm_armored/get_projectile_hit_chance(var/obj/item/projectile/P)
	if(P.firer == src) //Don't hit our own hitboxes
		return 0

	. = ..(P)

//Differentiates between damage types from different bullets
//Applies a linear transformation to bullet damage that will generally decrease damage done
/obj/vehicle/multitile/root/cm_armored/bullet_act(var/obj/item/projectile/P)

	var/dam_type = "bullet"


	if(istype(P, /datum/ammo/xeno/boiler_gas/corrosive))
		dam_type = "acid"
		take_damage_type(P.damage * 4, dam_type, P.firer)
		healthcheck()
		return
	if(P.ammo.flags_ammo_behavior & AMMO_XENO_ACID)
		dam_type = "acid"
		take_damage_type(P.damage * (0.75 + P.ammo.penetration/100), dam_type, P.firer)
		healthcheck()
		return
	if(istype(P, /datum/ammo/rocket/ap))
		dam_type = "explosive"
		take_damage_type(P.damage * (1.2 + P.ammo.penetration/100), dam_type, P.firer)
		healthcheck()
		return
	/*if(istype(P, /datum/ammo/rocket/tow))
		dam_type = "explosive"
		take_damage_type(P.damage * (1.5 + P.ammo.penetration/100), dam_type, P.firer)
		healthcheck()
		return*/
	if(istype(P, /datum/ammo/rocket/ltb))
		dam_type = "explosive"
		take_damage_type(P.damage * (3 + P.ammo.penetration/100), dam_type, P.firer)
		healthcheck()
		return

	take_damage_type(P.damage * (0.75 + P.ammo.penetration/100), dam_type, P.firer)
	playsound(src.loc, pick('sound/bullets/bullet_ricochet2.ogg', 'sound/bullets/bullet_ricochet3.ogg', 'sound/bullets/bullet_ricochet4.ogg', 'sound/bullets/bullet_ricochet5.ogg'), 25, 1)

	healthcheck()

//severity 1.0 explosions never really happen so we're gonna follow everyone else's example
/obj/vehicle/multitile/root/cm_armored/ex_act(var/severity)

	switch(severity)
		if(1.0)
			take_damage_type(rand(100, 150), "explosive")
			take_damage_type(rand(20, 40), "slash")

		if(2.0)
			take_damage_type(rand(60,80), "explosive")
			take_damage_type(rand(10, 15), "slash")

		if(3.0)
			take_damage_type(rand(20, 25), "explosive")

	healthcheck()

//Honestly copies some code from the Xeno files, just handling some special cases
/obj/vehicle/multitile/root/cm_armored/attack_alien(var/mob/living/carbon/Xenomorph/M, var/dam_bonus)

	var/damage = rand(M.melee_damage_lower, M.melee_damage_upper) + dam_bonus

	//Frenzy auras stack in a way, then the raw value is multipled by two to get the additive modifier
	if(M.frenzy_aura > 0)
		damage += (M.frenzy_aura * 2)

	//Somehow we will deal no damage on this attack
	if(!damage)
		playsound(M.loc, 'sound/weapons/alien_claw_swipe.ogg', 25, 1)
		M.animation_attack_on(src)
		M.visible_message("<span class='danger'>\The [M] lunges at [src]!</span>", \
		"<span class='danger'>You lunge at [src]!</span>")
		return 0

	M.animation_attack_on(src)
	playsound(M.loc, pick('sound/weapons/alien_claw_metal1.ogg', 'sound/weapons/alien_claw_metal2.ogg', 'sound/weapons/alien_claw_metal3.ogg'), 25, 1)
	M.visible_message("<span class='danger'>\The [M] slashes [src]!</span>", \
	"<span class='danger'>You slash [src]!</span>")

	take_damage_type(damage * ( (isXenoRavager(M)) ? 2 : 1 ), "slash", M) //Ravs do a bitchin double damage

	healthcheck()

//used when entrance is blocked by something awful
/obj/vehicle/multitile/root/cm_armored/tank/proc/get_new_exit_point()
	var dir = pick(1, 2, 4, 5, 6, 8, 9, 10)
	var/turf/T
	T = get_step(src, dir)
	T = get_step(T, dir)
	return T

//checks entrance tile for closed turfs and un-passable objects and returns TRUE if it is so
/obj/vehicle/multitile/root/cm_armored/proc/tile_blocked_check(var/turf/Location)
	if(!isturf(Location))
		return TRUE
	var/turf/T = Location
	if(T.density)
		return TRUE
	for(var/atom/A in T.contents)
		if(A.density)
			return TRUE
	return FALSE

//Special case for entering the vehicle without using the verb
/obj/vehicle/multitile/root/cm_armored/attack_hand(var/mob/user)

	if(user.a_intent == "hurt")
		handle_harm_attack(user)
		return

	if(user.loc == entrance.loc)
		handle_player_entrance(user)
		return


	if(tile_blocked_check(get_turf(entrance)))		//vehicle entrance cannot be blocked to prevent TCs getting in
		handle_player_entrance(user)
		return

	. = ..()

/obj/vehicle/multitile/root/cm_armored/Entered(var/atom/movable/A)
	if(istype(A, /obj) && !istype(A, /obj/item/ammo_magazine/tank))
		A.forceMove(src.loc)
		return

	return ..()

//Need to take damage from crushers, probably too little atm
/obj/vehicle/multitile/root/cm_armored/Bumped(var/atom/A)
	..()

	if(istype(A, /mob/living/carbon/Xenomorph/Crusher))

		var/mob/living/carbon/Xenomorph/Crusher/C = A

		if(C.charge_speed < C.charge_speed_max/(1.1)) //Arbitrary ratio here, might want to apply a linear transformation instead
			return

		take_damage_type(100, "blunt", C)

//Redistributes damage ratios based off of what things are attached (no armor means the armor doesn't mitigate any damage)
/obj/vehicle/multitile/root/cm_armored/proc/update_damage_distribs()
	dmg_distribs = tank_dmg_distributions.Copy() //Assume full installs
	for(var/slot in hardpoints)
		var/obj/item/hardpoint/tank/HP = hardpoints[slot]
		if(!HP) dmg_distribs[slot] = 0.0 //Remove empty slots' damage mitigation
	var/acc = 0
	for(var/slot in dmg_distribs)
		var/ratio = dmg_distribs[slot]
		acc += ratio //Get total current ratio applications
	if(acc == 0)
		return
	for(var/slot in dmg_distribs)
		var/ratio = dmg_distribs[slot]
		dmg_distribs[slot] = ratio/acc //Redistribute according to previous ratios for full damage taking, but ignoring empty slots

//Special cases abound, handled below or in subclasses
/obj/vehicle/multitile/root/cm_armored/attackby(var/obj/item/O, var/mob/user)

	if(istype(O, /obj/item/hardpoint/tank)) //Are we trying to install stuff?
		var/obj/item/hardpoint/tank/HP = O
		install_hardpoint(HP, user)
		update_damage_distribs()
		return

	if(istype(O, /obj/item/ammo_magazine)) //Are we trying to reload?
		var/obj/item/ammo_magazine/AM = O
		if(istype(O, /obj/item/ammo_magazine/tank/tank_slauncher))
			if(smoke_ammo_current == 0)
				smoke_ammo_current = smoke_ammo_max
				user.temp_drop_inv_item(O, 0)
				to_chat(user, "<span class='notice'>You load smoke system magazine into [src].</span>")
				return
			else
				to_chat(user, "<span class='notice'>You can't load new magazine until smoke launcher system automatically unload emptied one.</span>")
				return
		else
			handle_ammomag_attackby(AM, user)
		return

	if(iswelder(O) || iswrench(O)) //Are we trying to repair stuff?
		handle_hardpoint_repair(O, user)
		update_damage_distribs()
		return

	if(iscrowbar(O)) //Are we trying to remove stuff?
		uninstall_hardpoint(O, user)
		update_damage_distribs()
		return

	take_damage_type(O.force * 0.05, "blunt", user) //Melee weapons from people do very little damage

	. = ..()

/obj/vehicle/multitile/root/cm_armored/proc/handle_hardpoint_repair(var/obj/item/O, var/mob/user)

	//Need to the what the hell you're doing
	if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_MT)
		to_chat(user, "<span class='warning'>You don't know what to do with [O] on [src].</span>")
		return

	if(!damaged_hps.len)
		to_chat(user, "<span class='notice'>All of the hardpoints are in working order.</span>")
		return

	//Pick what to repair
	var/slot = input("Select a slot to try and repair") in damaged_hps

	var/obj/item/hardpoint/tank/old = hardpoints[slot] //Is there something there already?

	if(old) //If so, fuck you get it outta here
		to_chat(user, "<span class='warning'>Please remove the attached hardpoint module first.</span>")
		return

	//Determine how many 3 second intervals to wait and if you have the right tool
	var/num_delays = 1
	switch(slot)
		if(HDPT_PRIMARY)
			num_delays = 5
			if(!iswelder(O))
				to_chat(user, "<span class='warning'>That's the wrong tool. Use a welder.</span>")
				return
			var/obj/item/tool/weldingtool/WT = O
			if(!WT.isOn())
				to_chat(user, "<span class='warning'>You need to light your [WT] first.</span>")
				return
			WT.remove_fuel(num_delays, user)

		if(HDPT_SECDGUN)
			num_delays = 3
			if(!iswrench(O))
				to_chat(user, "<span class='warning'>That's the wrong tool. Use a wrench.</span>")
				return

		if(HDPT_SUPPORT)
			num_delays = 2
			if(!iswrench(O))
				to_chat(user, "<span class='warning'>That's the wrong tool. Use a wrench.</span>")
				return

		if(HDPT_ARMOR)
			num_delays = 10
			if(!iswelder(O))
				to_chat(user, "<span class='warning'>That's the wrong tool. Use a welder.</span>")
				return
			var/obj/item/tool/weldingtool/WT = O
			if(!WT.isOn())
				to_chat(user, "<span class='warning'>You need to light your [WT] first.</span>")
				return
			WT.remove_fuel(num_delays, user)

	user.visible_message("<span class='notice'>[user] starts repairing the [slot] slot on [src].</span>",
		"<span class='notice'>You start repairing the [slot] slot on [src].</span>")

	if(!do_after(user, 30*num_delays, TRUE, num_delays, BUSY_ICON_FRIENDLY))
		user.visible_message("<span class='notice'>[user] stops repairing the [slot] slot on [src].</span>",
			"<span class='notice'>You stop repairing the [slot] slot on [src].</span>")
		return

	if(!Adjacent(user))
		user.visible_message("<span class='notice'>[user] stops repairing the [slot] slot on [src].</span>",
			"<span class='notice'>You stop repairing the [slot] slot on [src].</span>")
		return

	user.visible_message("<span class='notice'>[user] repairs the [slot] slot on [src].</span>",
		"<span class='notice'>You repair the [slot] slot on [src].</span>")

	damaged_hps -= slot //We repaired it, good job

	update_icon()

//Relaoding stuff, pretty bare-bones and basic
/obj/vehicle/multitile/root/cm_armored/proc/handle_ammomag_attackby(var/obj/item/ammo_magazine/AM, var/mob/user)

	//No skill checks for reloading
	//Maybe I should delineate levels of skill for reloading, installation, and repairs?
	//That would make it easier to differentiate between the two for skills
	//Instead of using MT skills for these procs and TC skills for operation
	//Oh but wait then the MTs would be able to drive fuck that
	var/slot = input("Select a slot to try and refill") in hardpoints
	var/obj/item/hardpoint/tank/HP = hardpoints[slot]

	if(!HP)
		to_chat(user, "<span class='warning'>There is nothing installed on that slot.</span>")
		return

	HP.try_add_clip(AM, user)

//Putting on hardpoints
//Similar to repairing stuff, down to the time delay
/obj/vehicle/multitile/root/cm_armored/proc/install_hardpoint(var/obj/item/hardpoint/tank/HP, var/mob/user)

	if(!user.mind || !user.mind.cm_skills || user.mind.cm_skills.engineer < SKILL_ENGINEER_ENGI)
		to_chat(user, "<span class='warning'>You don't know what to do with [HP] on [src].</span>")
		return

	if(HP.slot != HDPT_TREADS && user.mind.cm_skills.engineer < SKILL_ENGINEER_MT)
		to_chat(user, "<span class='warning'>You only know how to remove, install and field repair treads.</span>")
		return

	if(damaged_hps.Find(HP.slot))
		to_chat(user, "<span class='warning'>You need to fix the hardpoint first.</span>")
		return

	var/obj/item/hardpoint/tank/old = hardpoints[HP.slot]

	if(old)
		to_chat(user, "<span class='warning'>Remove the previous hardpoint module first.</span>")
		return

	user.visible_message("<span class='notice'>[user] begins installing [HP] on the [HP.slot] hardpoint slot on [src].</span>",
		"<span class='notice'>You begin installing [HP] on the [HP.slot] hardpoint slot on [src].</span>")

	var/num_delays = 1

	switch(HP.slot)
		if(HDPT_PRIMARY) num_delays = 5
		if(HDPT_SECDGUN) num_delays = 3
		if(HDPT_SUPPORT) num_delays = 2
		if(HDPT_ARMOR) num_delays = 10
		if(HDPT_TREADS) num_delays = 7

	if(!do_after(user, 30*num_delays, TRUE, num_delays, BUSY_ICON_FRIENDLY))
		user.visible_message("<span class='warning'>[user] stops installing \the [HP] on [src].</span>", "<span class='warning'>You stop installing \the [HP] on [src].</span>")
		return

	user.visible_message("<span class='notice'>[user] installs \the [HP] on [src].</span>", "<span class='notice'>You install \the [HP] on [src].</span>")

	user.temp_drop_inv_item(HP, 0)

	add_hardpoint(HP, user)

//User-orientated proc for taking of hardpoints
//Again, similar to the above ones
/obj/vehicle/multitile/root/cm_armored/proc/uninstall_hardpoint(var/obj/item/O, var/mob/user)

	if(!user.mind || !user.mind.cm_skills || user.mind.cm_skills.engineer < SKILL_ENGINEER_ENGI)
		to_chat(user, "<span class='warning'>You don't know what to do with [O] on [src].</span>")
		return

	var/slot = input("Select a slot to try and remove") in hardpoints

	if(slot != HDPT_TREADS && user.mind.cm_skills.engineer < SKILL_ENGINEER_MT)
		to_chat(user, "<span class='warning'>You only know how to remove, install and field repair treads.</span>")
		return

	var/obj/item/hardpoint/tank/old = hardpoints[slot]

	if(!old)
		to_chat(user, "<span class='warning'>There is nothing installed there.</span>")
		return

	user.visible_message("<span class='notice'>[user] begins removing [old] on the [old.slot] hardpoint slot on [src].</span>",
		"<span class='notice'>You begin removing [old] on the [old.slot] hardpoint slot on [src].</span>")

	var/num_delays = 1

	switch(slot)
		if(HDPT_PRIMARY) num_delays = 5
		if(HDPT_SECDGUN) num_delays = 3
		if(HDPT_SUPPORT) num_delays = 2
		if(HDPT_ARMOR) num_delays = 10
		if(HDPT_TREADS) num_delays = 7


	if(!do_after(user, 30*num_delays, TRUE, num_delays, BUSY_ICON_FRIENDLY))
		user.visible_message("<span class='warning'>[user] stops removing \the [old] on [src].</span>", "<span class='warning'>You stop removing \the [old] on [src].</span>")
		return

	if((old == hardpoints[HDPT_PRIMARY] || old == hardpoints[HDPT_SECDGUN]) && old.health > 0)
		if(old.clips.len > 0)
			var i
			var/obj/item/ammo_magazine/A
			for(i = 0; i <= old.clips.len; i++)
				A = old.clips[1]
				old.clips[1].Move(entrance.loc)
				old.clips[1].update_icon()
				old.clips.Remove(A)
			user.visible_message("<span class='notice'>[user] removes ammunition from \the [old].</span>", "<span class='notice'>You remove ammunition from \the [old].</span>")


	user.visible_message("<span class='notice'>[user] removes \the [old] on [src].</span>", "<span class='notice'>You remove \the [old] on [src].</span>")

	remove_hardpoint(old, user)

//General proc for putting on hardpoints
//ALWAYS CALL THIS WHEN ATTACHING HARDPOINTS
/obj/vehicle/multitile/root/cm_armored/proc/add_hardpoint(var/obj/item/hardpoint/tank/HP, var/mob/user)

	HP.owner = src
	HP.apply_buff()
	HP.loc = src
	src.vehicle_weight += HP.hp_weight
	src.vehicle_class_update()

	hardpoints[HP.slot] = HP

	update_icon()

//General proc for taking off hardpoints
//ALWAYS CALL THIS WHEN REMOVING HARDPOINTS
/obj/vehicle/multitile/root/cm_armored/proc/remove_hardpoint(var/obj/item/hardpoint/tank/old, var/mob/user)
	if(user)
		old.loc = user.loc
	else
		old.loc = entrance.loc
	old.remove_buff()

	src.vehicle_weight -= old.hp_weight
	src.vehicle_class_update()

	//if(old.health <= 0)
	//	cdel(old)

	hardpoints[old.slot] = null
	update_icon()