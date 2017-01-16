//FLAGS BITMASK
/*
Cleaned these up a lot. Everything that applies to equipment is in flags_inventory instead of
flags. So I had to manually go through and reset all of the flags. Regular item flags
should all be unique more or less. flags_inventory can double up.
~N
*/

//turf-only flags
#define NOJAUNT		1

//PASS FLAGS
#define PASSTABLE	1
#define PASSGLASS	2
#define PASSGRILLE	4
#define PASSBLOB	8

//FLAGS
#define NOFLAGS					0		//Nothing.

//==========================================================================================
#define NODROP					1		// Cannot be dropped at all, only deleted.
#define NOINTERACT				2		// You can't interact with it, at all. Useful when doing certain animations.
#define NOBLOODY				4		// Don't want a blood overlay on this one.
#define DELONDROP				8		// Deletes on drop instead of falling on the floor.
#define FPRINT					16		// takes a fingerprint
#define CONDUCT					32		// conducts electricity (metal etc.)
#define ON_BORDER				64		// item has priority to check when entering or leaving
#define DIRLOCK					128		// Item won't change direction when Moving()ing. Useful for items that have several dir states.
#define NOPULLPENALTY			256		// Item will not slow down people when pulled, intended for wheeled and floating items
//Reserved space for any general flags here.
//==========================================================================================
#define USEDELAY 				512		// 1 second extra delay on use (Can be used once every 2s)
#define	NOREACT					1024	//Reagents dont' react inside this container.
#define OPENCONTAINER			2048	//is an open container for chemistry purposes
//==========================================================================================
#define NOBLUDGEON  			4096	// when an item has this it produces no "X has been hit by Y with Z" message with the default handler
#define NOSHIELD				8192	// weapon not affected by shield
#define TWOHANDED				16384	// The item is twohanded.
#define WIELDED					32768	// The item is wielded with both hands.
//==========================================================================================
#define RELAY_CLICK				65536	//This is used for /obj/ that relay your clicks via handle_click(), mostly for MGs + Sentries ~Art
//==========================================================================================

//flags_inventory
//Bit flags for the flags_inventory variable, which determine when a piece of clothing hides another. IE a helmet hiding glasses.
//It also determines a few other things now, and doesn't just apply to clothing. ~N
#define CANTSTRIP		32768		// Can't be removed by others. Mostly for donor stuff.
#define BLOCKPHORON 	65536		// Does not get contaminated by phoron.

//SUIT ONLY============================================================================================
#define HIDEGLOVES		1	//APPLIES ONLY TO THE EXTERIOR SUIT!!
#define HIDESUITSTORAGE	2	//APPLIES ONLY TO THE EXTERIOR SUIT!!
#define HIDEJUMPSUIT	4	//APPLIES ONLY TO THE EXTERIOR SUIT!!
#define HIDESHOES		8	//APPLIES ONLY TO THE EXTERIOR SUIT!!
//HIDELOWHAIR			16  //Can do this now.
#define HIDETAIL 		32	//APPLIES ONLY TO THE EXTERIOR SUIT!!
//COVERMOUTH			256 //Can potentially do this.
//SUIT ONLY============================================================================================

//HELMET AND MASK======================================================================================
#define HIDEMASK		1	//APPLIES ONLY TO HELMETS/MASKS!!
#define HIDEEARS		2	//APPLIES ONLY TO HELMETS/MASKS!! (ears means headsets and such)
#define HIDEEYES		4	//APPLIES ONLY TO HELMETS/MASKS!! (eyes means glasses)
#define HIDEFACE		8	//APPLIES ONLY TO HELMETS/MASKS!! Dictates whether we appear as unknown.
#define HIDELOWHAIR		16	// temporarily removes the user's facial hair overlay.
#define HIDETOPHAIR		32	// temporarily removes the user's hair overlay. Leaves facial hair.
#define HIDEALLHAIR		64	// temporarily removes the user's hair, facial and otherwise.
#define COVEREYES		128 // Covers the eyes/protects them.
#define COVERMOUTH		256 // Covers the mouth.
#define ALLOWINTERNALS	512	//mask allows internals
#define ALLOWREBREATH	1024 //Mask allows to breath in really hot or really cold air.
#define BLOCKGASEFFECT	2048 // blocks the effect that chemical clouds would have on a mob --glasses, mask and helmets
//HELMET AND MASK======================================================================================

//SUITS AND HELMETS====================================================================================
//To successfully stop taking all pressure damage you must have both a suit and head item with this flag.
#define BLOCKSHARPOBJ 	4096  //From /tg: prevents syringes, parapens and hypos if the external suit or helmet (if targeting head) has this flag. Example: space suits, biosuit, bombsuits, thick suits that cover your body.
#define NOPRESSUREDMAGE 8192 //This flag is used on the flags variable for SUIT and HEAD items which stop pressure damage.
//SUITS AND HELMETS====================================================================================

//SHOES ONLY===========================================================================================
#define NOSLIPPING		1	//prevents from slipping on wet floors, in space etc
//SHOES ONLY===========================================================================================

//===========================================================================================
//Marine armor only, use for flags_marine_armor.
#define ARMOR_SQUAD_OVERLAY		1
#define ARMOR_LAMP_OVERLAY		2
#define ARMOR_LAMP_ON			4
#define ARMOR_IS_REINFORCED		8
//===========================================================================================

//===========================================================================================
//Marine helmet only, use for flags_marine_helmet.
#define HELMET_SQUAD_OVERLAY	1
#define HELMET_GARB_OVERLAY		2
#define HELMET_DAMAGE_OVERLAY	4
#define HELMET_STORE_GARB		8
#define HELMET_IS_DAMAGED		16
//===========================================================================================

//ITEM INVENTORY SLOT BITMASKS
#define SLOT_OCLOTHING 		1
#define SLOT_ICLOTHING 		2
#define SLOT_HANDS 			4
#define SLOT_EYES 			8
#define SLOT_EAR 			16
#define SLOT_FACE 			32
#define SLOT_HEAD 			64
#define SLOT_FEET 			128
#define SLOT_ID 			256
#define SLOT_WAIST			512
#define SLOT_BACK 			1024
#define SLOT_STORE 			2048	//this is to allow items with a w_class of 3 or 4 to fit in pockets.
#define SLOT_NO_STORE		4096	//this is to deny items with a w_class of 2 or 1 to fit in pockets.
#define SLOT_EARS 		8192
#define SLOT_LEGS 			16384
//=================================================

//slots
//Text strings so that the slots can be associated when doing iventory lists.
#define WEAR_ID				"id"
#define WEAR_L_EAR			"l_ear"
#define WEAR_R_EAR			"r_ear"
#define WEAR_BODY			"body"
#define WEAR_LEGS			"legs"
#define WEAR_FEET			"feet"
#define WEAR_HANDS			"hands"
#define WEAR_WAIST			"waist"
#define WEAR_JACKET			"jacket"
#define WEAR_EYES			"eyes"
#define WEAR_FACE			"face"
#define WEAR_HEAD			"head"
#define WEAR_BACK			"back"
#define WEAR_L_STORE		"l_store"
#define WEAR_R_STORE		"r_store"
#define WEAR_ACCESSORY		"accessory"
#define WEAR_J_STORE		"j_store"
#define WEAR_L_HAND			"l_hand"
#define WEAR_R_HAND			"r_hand"
#define WEAR_HANDCUFFS		"handcuffs"
#define WEAR_LEGCUFFS		"legcuffs"
#define WEAR_IN_BACK		"in_back"
#define WEAR_IN_JACKET		"in_jacket"
#define WEAR_IN_ACCESSORY	"in_accessory"
//=================================================

// bitflags for clothing parts
#define HEAD			1
#define FACE			2
#define EYES			4
#define UPPER_TORSO		8
#define LOWER_TORSO		16
#define LEG_LEFT		32
#define LEG_RIGHT		64
#define LEGS			96
#define FOOT_LEFT		128
#define FOOT_RIGHT		256
#define FEET			384
#define ARM_LEFT		512
#define ARM_RIGHT		1024
#define ARMS			1536
#define HAND_LEFT		2048
#define HAND_RIGHT		4096
#define HANDS			6144
#define FULL_BODY		8191
//=================================================

//defense zones for selecting them via the hud.
#define DEFENSE_ZONES_LIVING list("head","chest","mouth","eyes","groin","l_leg","l_foot","r_leg","r_foot","l_arm","l_hand","r_arm","r_hand")

// bitflags for the percentual amount of protection a piece of clothing which covers the body part offers.
// Used with human/proc/get_flags_heat_protection() and human/proc/get_flags_cold_protection()
// The values here should add up to 1.
// Hands and feet have 2.5%, arms and legs 7.5%, each of the torso parts has 15% and the head has 30%
#define THERMAL_PROTECTION_HEAD			0.3
#define THERMAL_PROTECTION_UPPER_TORSO	0.15
#define THERMAL_PROTECTION_LOWER_TORSO	0.15
#define THERMAL_PROTECTION_LEG_LEFT		0.075
#define THERMAL_PROTECTION_LEG_RIGHT	0.075
#define THERMAL_PROTECTION_FOOT_LEFT	0.025
#define THERMAL_PROTECTION_FOOT_RIGHT	0.025
#define THERMAL_PROTECTION_ARM_LEFT		0.075
#define THERMAL_PROTECTION_ARM_RIGHT	0.075
#define THERMAL_PROTECTION_HAND_LEFT	0.025
#define THERMAL_PROTECTION_HAND_RIGHT	0.025
//=================================================

//=================================================
#define SPACE_HELMET_min_cold_protection_temperature 	2.0 //what min_cold_protection_temperature is set to for space-helmet quality headwear. MUST NOT BE 0.
#define SPACE_SUIT_min_cold_protection_temperature 		2.0 //what min_cold_protection_temperature is set to for space-suit quality jumpsuits or suits. MUST NOT BE 0.
#define SPACE_SUIT_max_heat_protection_temperature 		5000	//These need better heat protect, but not as good heat protect as firesuits.
#define FIRESUIT_max_heat_protection_temperature 		30000 //what max_heat_protection_temperature is set to for firesuit quality headwear. MUST NOT BE 0.
#define FIRE_HELMET_max_heat_protection_temperature 	30000 //for fire helmet quality items (red and white hardhats)
#define HELMET_min_cold_protection_temperature 			250	//For normal helmets
#define HELMET_max_heat_protection_temperature 			600	//For normal helmets
#define ARMOR_min_cold_protection_temperature 			250	//For armor
#define ARMOR_max_heat_protection_temperature 			600	//For armor

#define GLOVES_min_cold_protection_temperature 			200	//For some gloves (black and)
#define GLOVES_max_heat_protection_temperature 			650	//For some gloves
#define SHOE_min_cold_protection_temperature 			200	//For gloves
#define SHOE_max_heat_protection_temperature 			650	//For gloves

#define ICE_PLANET_min_cold_protection_temperature 		220 //For the ice planet map protection from the elements.
//=================================================

//Slowdown from various armors.
#define SHOES_SLOWDOWN -1.0			// How much shoes slow you down by default. Negative values speed you up
#define SLOWDOWN_UNDER_UNFITTING	0.5

#define SLOWDOWN_ARMOR_VERY_LIGHT	0.20
#define SLOWDOWN_ARMOR_LIGHT		0.35
#define SLOWDOWN_ARMOR_MEDIUM		0.55
#define SLOWDOWN_ARMOR_HEAVY		1
#define SLOWDOWN_ARMOR_VERY_HEAVY	1.15

#define SLOWDOWN_ADS_SHOTGUN		0.75
#define SLOWDOWN_ADS_RIFLE			0.75
#define SLOWDOWN_ADS_SCOPE			0.5
#define SLOWDOWN_ADS_SPECIALIST		1.5
#define SLOWDOWN_ADS_SUPERWEAPON	2
//=================================================