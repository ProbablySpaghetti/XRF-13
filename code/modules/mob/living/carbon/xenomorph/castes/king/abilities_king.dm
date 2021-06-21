// ***************************************
// *********** Nightfall
// ***************************************

/datum/action/xeno_action/activable/nightfall
	name = "Nightfall"
	action_icon_state = "nightfall"
	ability_name = "Nightfall"
	mechanics_text = "Shut down all electrical lights for five seconds."
	cooldown_timer = 15 SECONDS //Nightfall buff
	plasma_cost = 150 //Doubled. Expensive.
	/// How far nightfall will have an effect
	var/range = 15 //Buffed range
	/// How long till the lights go on again
	var/duration = 13 SECONDS // 2 Seconds of downtime, enough to make lights consistently flicker
	var/cooldowntext = "<span class='notice'>We gather enough mental strength to shut down lights again.</span>"

/datum/action/xeno_action/activable/nightfall/on_cooldown_finish()
	to_chat(owner, cooldowntext)
	return ..()

/datum/action/xeno_action/activable/nightfall/use_ability()
	playsound(owner, 'sound/magic/nightfall.ogg', 50, 1)
	succeed_activate()
	add_cooldown()
	for(var/atom/light AS in GLOB.nightfall_toggleable_lights)
		if(isnull(light.loc) || (owner.loc.z != light.loc.z) || (get_dist(owner, light) >= range))
			continue
		light.turn_light(null, FALSE, duration, TRUE, TRUE)


/datum/action/xeno_action/activable/nightfall/lesser //Less griefy lightfall.
	name = "Lesser Nightfall"
	action_icon_state = "nightfall"
	ability_name = "Lesser Nightfall"
	mechanics_text = "Shut down all electrical lights for five seconds."
	cooldown_timer = 4 SECONDS //Nightfall buff
	plasma_cost = 50 // Cheap
	/// How far nightfall will have an effect
	range = 8 //Buffed range
	/// How long till the lights go on again
	duration = 2 SECONDS // 2 Seconds of downtime, enough to make lights consistently flicker
	cooldowntext = "<span class='notice'>We gather enough mental strength to flicker lights again.</span>"

// ***************************************
// *********** Gravity Crush
// ***************************************
#define WINDUP_GRAV 2 SECONDS

/datum/action/xeno_action/activable/gravity_crush
	name = "Gravity Crush"
	action_icon_state = "fortify"
	mechanics_text = "Increases the localized gravity in an area and crushes structures."
	ability_name = "Gravity Crush"
	plasma_cost = 100
	cooldown_timer = 30 SECONDS
	keybind_signal = COMSIG_XENOABILITY_GRAVITY_CRUSH
	/// How far can we use gravity crush
	var/king_crush_dist = 5
	/// A list of all things that had a fliter applied
	var/list/filters_applied = list()
	var/cooldowntext = "<span class='warning'>Our psychic aura restores itself. We are ready to gravity crush again.</span>"

/datum/action/xeno_action/activable/gravity_crush/on_cooldown_finish()
	to_chat(owner, cooldowntext)
	return ..()

/datum/action/xeno_action/activable/gravity_crush/can_use_ability(atom/A, silent, override_flags)
	. = ..()
	if(!.)
		return
	if(!owner.line_of_sight(A, king_crush_dist))
		if(!silent)
			to_chat(owner, "<span class='warning'>We must get closer to crush, our mind cannot reach this far.</span>")
		return FALSE

/datum/action/xeno_action/activable/gravity_crush/use_ability(atom/A)
	owner.face_atom(A) //Face towards the target so we don't look silly
	var/list/turfs = RANGE_TURFS(1, A)
	playsound(A, 'sound/effects/bomb_fall.ogg', 75, FALSE)
	apply_filters(turfs)
	if(!do_after(owner, WINDUP_GRAV, FALSE, owner, BUSY_ICON_DANGER))
		remove_all_filters()
		return fail_activate()
	do_grav_crush(turfs)
	remove_all_filters()
	succeed_activate()
	add_cooldown()
	A.visible_message("<span class='warning'>[A] collapses inward as its gravity suddenly increases!</span>")

///Remove all filters of items in filters_applied
/datum/action/xeno_action/activable/gravity_crush/proc/remove_all_filters()
	for(var/atom/thing AS in filters_applied)
		if(QDELETED(thing))
			continue
		thing.remove_filter("crushblur")
	filters_applied.Cut()

///Apply a filter on all items in the list of turfs
/datum/action/xeno_action/activable/gravity_crush/proc/apply_filters(list/turfs)
	for(var/turf/targetted AS in turfs)
		targetted.add_filter("crushblur", 1, radial_blur_filter(0.3))
		filters_applied += targetted
		for(var/atom/movable/item AS in targetted.contents)
			item.add_filter("crushblur", 1, radial_blur_filter(0.3))
			filters_applied += item

///Will crush every item on the turfs (unless they are a friendly xeno or dead)
/datum/action/xeno_action/activable/gravity_crush/proc/do_grav_crush(list/turfs)
	var/mob/living/carbon/xenomorph/xeno_owner = owner
	for(var/turf/targetted AS in turfs)
		for(var/atom/movable/item AS in targetted.contents)
			if(isliving(item))
				var/mob/living/mob_crushed = item
				if(mob_crushed.stat == DEAD)//No abuse of that mechanic for some permadeath
					continue
				var/armor_block = mob_crushed.run_armor_check(BODY_ZONE_CHEST, "melee")
				var/damage = rand(20,50) //Decently high, with the chance to be lethal (hitting your head hard)
				mob_crushed.apply_damage(2*damage, BRUTE, "head", armor_block) //Head takes much more damage, you're falling flat
				mob_crushed.apply_damage(1*damage, BRUTE, "chest", armor_block)
				mob_crushed.apply_damage(1.5*damage, BRUTE, "l_leg", armor_block) // Ankles = broken
				mob_crushed.apply_damage(1.5*damage, BRUTE, "r_leg", armor_block) // Same here
				mob_crushed.apply_damage(0.5*damage, BRUTE, "l_arm", armor_block) // Arms are pretty safe
				mob_crushed.apply_damage(0.5*damage, BRUTE, "r_arm", armor_block)// Arms are pretty safe
				if(isxeno(mob_crushed))
					var/mob/living/carbon/xenomorph/xeno = mob_crushed
					if(xeno.hive == xeno_owner.hive)
						continue
			if(!isliving(item))
				item.ex_act(EXPLODE_HEAVY)	//crushing without damaging the nearby area

/datum/action/xeno_action/activable/gravity_crush/ai_should_start_consider()
	return TRUE

/datum/action/xeno_action/activable/gravity_crush/ai_should_use(target)
	if(!iscarbon(target))
		return ..()
	if(!can_use_ability(target, override_flags = XACT_IGNORE_SELECTED_ABILITY))
		return ..()
	return TRUE


/datum/action/xeno_action/activable/gravity_crush/lesser
	name = "Lesser Gravity Crush"
	action_icon_state = "fortify"
	mechanics_text = "Increases the localized gravity in an area; weakening targets"
	ability_name = "Lesser Gravity Crush"
	plasma_cost = 50
	cooldown_timer = 5 SECONDS //Much lower
	keybind_signal = COMSIG_XENOABILITY_GRAVITY_CRUSH
	/// How far can we use gravity crush
	king_crush_dist = 8 //Further range, smaller crush
	/// A list of all things that had a fliter applied
	filters_applied = list()
	cooldowntext = "<span class='warning'>Our psychic aura restores itself. We are ready to lesser gravity crush again.</span>"

/datum/action/xeno_action/activable/gravity_crush/lesser/use_ability(atom/A)
	owner.face_atom(A) //Face towards the target so we don't look silly
	var/list/turfs = RANGE_TURFS(0, A) //If for some reason this is ever occurring, run.
	playsound(A, 'sound/effects/bomb_fall.ogg', 75, FALSE)
	apply_filters(turfs)
	if(!do_after(owner, WINDUP_GRAV, FALSE, owner, BUSY_ICON_DANGER))
		remove_all_filters()
		return fail_activate()
	remove_all_filters()
	do_grav_crush_lesser(turfs)
	succeed_activate()
	add_cooldown()
	A.visible_message("<span class='warning'>[A] crumples as its gravity unexpectedly fluxes!</span>")

///Will crush every item on the turfs (unless they are a friendly xeno or dead)
/datum/action/xeno_action/activable/gravity_crush/lesser/proc/do_grav_crush_lesser(list/turfs)
	var/mob/living/carbon/xenomorph/xeno_owner = owner
	for(var/turf/targetted AS in turfs)
		for(var/atom/movable/item AS in targetted.contents)
			if(isliving(item))
				var/mob/living/mob_crushed = item
				if(mob_crushed.stat == DEAD)//No abuse of that mechanic for some permadeath
					continue
				var/armor_block = mob_crushed.run_armor_check(BODY_ZONE_CHEST, "melee")
				var/damage = rand(2,7) //This is a very minor crush
				mob_crushed.apply_damage(0.5*damage, BRUTE, "head", armor_block) //Head takes much more damage, you're falling flat
				mob_crushed.apply_damage(0.2*damage, BRUTE, "chest", armor_block)
				mob_crushed.apply_damage(1*damage, BRUTE, "l_leg", armor_block) // Ankles = broken
				mob_crushed.apply_damage(1*damage, BRUTE, "r_leg", armor_block) // Same here
				mob_crushed.apply_damage(0.2*damage, BRUTE, "l_arm", armor_block) // Arms are pretty safe
				mob_crushed.apply_damage(0.2*damage, BRUTE, "r_arm", armor_block)// Arms are pretty safe
				mob_crushed.apply_damage(80, STAMINA, BODY_ZONE_CHEST, armor_block) //REALLY winds a target.
				if(isxeno(mob_crushed))
					var/mob/living/carbon/xenomorph/xeno = mob_crushed
					xeno.apply_damage(20, BRUTE)  //Xeno = btfo
					if(xeno.hive == xeno_owner.hive)
						continue

// ***************************************
// *********** Psychic Summon
// ***************************************

/datum/action/xeno_action/psychic_summon
	name = "Psychic Summon"
	action_icon_state = "stomp"
	mechanics_text = "Summons all xenos in a hive to the caller's location, uses all plasma to activate."
	ability_name = "Psychic summon"
	plasma_cost = 1100 //uses all an elder kings plasma
	cooldown_timer = 10 MINUTES
	keybind_flags = XACT_KEYBIND_USE_ABILITY
	keybind_signal = COMSIG_XENOABILITY_HIVE_SUMMON

/datum/action/xeno_action/activable/psychic_summon/on_cooldown_finish()
	to_chat(owner, "<span class='warning'>The hives power swells. We may summon our sisters again.</span>")
	return ..()

/datum/action/xeno_action/psychic_summon/can_use_action(silent, override_flags)
	. = ..()
	var/mob/living/carbon/xenomorph/X = owner
	if(length(X.hive.get_all_xenos()) <= 1)
		if(!silent)
			to_chat(owner, "<span class='notice'>We have no hive to call. We are alone on our throne of nothing.</span>")
		return FALSE

/datum/action/xeno_action/psychic_summon/action_activate()
	var/mob/living/carbon/xenomorph/X = owner

	log_game("[key_name(owner)] has begun summoning hive in [AREACOORD(owner)]")
	xeno_message("King: \The [owner] has begun a psychic summon in <b>[get_area(owner)]</b>!", "xenoannounce", 3, X.hivenumber)
	var/list/allxenos = X.hive.get_all_xenos()
	for(var/mob/living/carbon/xenomorph/sister AS in allxenos)
		sister.add_filter("summonoutline", 2, outline_filter(1, COLOR_VIOLET))

	if(!do_after(X, 15 SECONDS, FALSE, X, BUSY_ICON_HOSTILE))
		for(var/mob/living/carbon/xenomorph/sister AS in allxenos)
			sister.remove_filter("summonoutline")
		return fail_activate()

	for(var/mob/living/carbon/xenomorph/sister AS in allxenos)
		sister.remove_filter("summonoutline")
		sister.forceMove(get_turf(X))
	log_game("[key_name(owner)] has summoned hive ([length(allxenos)] Xenos) in [AREACOORD(owner)]")
	X.emote("roar")

	add_cooldown()
	succeed_activate()
