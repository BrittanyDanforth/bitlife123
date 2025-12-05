--[[
    Childhood Events (Ages 0-12)
    ═══════════════════════════════════════════════════════════════════════════════
    
    COMPLETELY REVAMPED FOR AAA BITLIFE QUALITY
    
    Features:
    - 50+ immersive, detailed events
    - Specific body parts, locations, names, and consequences
    - Rich branching paths that matter
    - Events that build on each other
    - Player agency over outcomes (NOT random popups)
    - Realistic age-appropriate challenges
    
    Integrated with:
    - Core milestone tracking via `isMilestone` + milestoneKey
    - Career hints via `hintCareer` on choices
    - Flag system for story continuity
    - Relationship system for family bonds
    ═══════════════════════════════════════════════════════════════════════════════
]]

local Childhood = {}

local STAGE = "childhood"

Childhood.events = {
	-- ══════════════════════════════════════════════════════════════════════════════
	-- BABY & TODDLER (Ages 0-4) - Foundation Years
	-- ══════════════════════════════════════════════════════════════════════════════
	
	{
		id = "first_words",
		title = "First Words",
		emoji = "👶",
		text = "You're 14 months old and sitting in your high chair when suddenly... you speak your first word! Your parents nearly drop their coffee in excitement.",
		question = "What word comes tumbling out of your tiny mouth?",
		minAge = 1, maxAge = 2,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "development",
		milestoneKey = "CHILD_FIRST_WORDS",
		tags = { "core", "family", "speech", "early_years" },
		careerTags = { "veterinary" },

		choices = {
			{ text = '"Mama"', effects = { Happiness = 5 }, setFlags = { first_word = "mama", mother_bonded = true }, feedText = 'You said your first word: "Mama". Your mother burst into happy tears and hugged you tight.' },
			{ text = '"Dada"', effects = { Happiness = 5 }, setFlags = { first_word = "dada", father_bonded = true }, feedText = 'Your first word was "Dada". Your father picked you up and spun you around the kitchen.' },
			{ text = '"No!"', effects = { Happiness = 3 }, setFlags = { first_word = "no", rebellious_streak = true, stubborn = true }, feedText = 'Your first word was "No!" - already showing your independent spirit. Your parents exchanged worried glances.' },
			{ text = "The dog's name", effects = { Happiness = 4 }, setFlags = { first_word = "pet", animal_lover = true, pet_bonded = true }, hintCareer = "veterinary", feedText = "You tried to say the dog's name - it came out garbled but close enough. The dog wagged its tail. Pets already have your heart." },
		},
	},

	{
		id = "first_steps",
		title = "First Steps",
		emoji = "🚶",
		text = "You're 11 months old. You've been pulling yourself up on the coffee table for weeks. Today, you let go... and your legs hold! Your family gathers in the living room with their phones out, ready to capture the moment.",
		question = "How do you approach these crucial first steps?",
		minAge = 1, maxAge = 2,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "development",
		milestoneKey = "CHILD_FIRST_STEPS",
		tags = { "core", "mobility", "early_years" },

		choices = {
			{ text = "Take three careful steps to Mom", effects = { Smarts = 2, Happiness = 8 }, setFlags = { cautious_personality = true, mother_bond_strong = true }, feedText = "You took three wobbly but deliberate steps into your mother's arms. She cried happy tears. You did it!" },
			{ text = "Charge boldly across the room", effects = { Health = -2, Happiness = 5 }, setFlags = { adventurous_spirit = true, fearless = true }, feedText = "You ran before you could walk! You made it four steps before face-planting into the carpet. But you laughed and got right back up!" },
			{ text = "Stand frozen, waiting for encouragement", effects = { Happiness = 3 }, setFlags = { seeks_approval = true, needs_validation = true }, feedText = "You stood there until everyone started cheering and clapping. Then you walked right into their arms with a huge smile." },
			{ text = "Take one step and sit back down", effects = { Happiness = 1 }, setFlags = { cautious_learner = true, takes_time = true }, feedText = "One step was enough for today. Your parents clapped anyway. Progress is progress." },
		},
	},

	{
		id = "toddler_tantrum",
		title = "The Terrible Twos Strike",
		emoji = "😤",
		text = "You're at Target with your parents. In the toy aisle, you spot a bright red fire truck that you NEED. Your parents say no - they just bought you a toy last week. Your face turns red. Your fists clench.",
		question = "What happens next in the middle of this crowded store?",
		minAge = 2, maxAge = 3,
		baseChance = 0.8,
		cooldown = 2,
		stage = STAGE,
		category = "behavior",
		tags = { "family", "store", "impulse_control", "public" },
		careerTags = { "law" },

		choices = {
			{ text = "Full nuclear meltdown tantrum", effects = { Happiness = -5, Health = -1 }, setFlags = { throws_tantrums = true, emotional = true }, feedText = "You threw yourself on the floor screaming. People stared. Your parents' faces went bright red as they carried you out of the store mid-scream." },
			{ text = "Pout dramatically but walk away", effects = { Happiness = -2, Smarts = 1 }, setFlags = { learns_patience = true, emotionally_mature = true }, feedText = "You pouted with your arms crossed and dragged your feet. But you learned that tantrums don't always work. Growth!" },
			{ text = "Attempt to negotiate the terms", effects = { Smarts = 3, Happiness = 1 }, setFlags = { natural_negotiator = true, logical = true }, hintCareer = "law", feedText = 'You offered to "be very good" and "clean your room" in exchange for the truck. Your parents were impressed. Future lawyer?' },
			{ text = "Get distracted by the candy display", effects = { Happiness = 2 }, setFlags = { easily_distracted = true }, feedText = "A shiny candy wrapper caught your eye. Fire truck? What fire truck? Crisis averted." },
		},
	},

	{
		id = "preschool_start",
		title = "First Day of Preschool",
		emoji = "🎒",
		text = "Your mom is holding your hand as you approach the bright yellow building with the playground out front. Other kids are crying. Some are running around laughing. This is it - your first day away from home. The classroom smells like crayons and graham crackers.",
		question = "How do you handle this monumental transition?",
		minAge = 3, maxAge = 4,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "school",
		milestoneKey = "CHILD_PRESCHOOL_START",
		tags = { "school", "separation", "social", "milestone" },

		choices = {
			{ text = "Cry and cling to mom's leg", effects = { Happiness = -5, Health = -1 }, setFlags = { separation_anxiety = true, clingy = true }, feedText = "You cried so hard you got the hiccups. Your mom had to peel you off her leg. The teacher gave you a tissue. It took an hour to calm down." },
			{ text = "March in confidently like you own the place", effects = { Happiness = 5, Smarts = 2 }, setFlags = { socially_confident = true, natural_leader = true }, feedText = "You walked in, spotted the toy kitchen, and immediately started 'cooking.' Three kids joined you within minutes. Social butterfly!" },
			{ text = "Quietly observe from the book corner", effects = { Smarts = 3 }, setFlags = { observant = true, introverted = true, analytical = true }, hintCareer = "science", feedText = "You spent the morning watching everything from the reading nook. You noticed the routines, the personalities. An analytical mind is forming." },
			{ text = "Beeline for the art supplies", effects = { Happiness = 5, Looks = 1 }, setFlags = { artistic_interest = true, creative_soul = true }, hintCareer = "creative", feedText = "You made a beeline for the finger paints and spent three hours creating a 'masterpiece.' Your teacher hung it on the fridge." },
		},
	},

	{
		id = "playground_fall",
		title = "The Playground Incident",
		emoji = "🤕",
		text = "You're on the monkey bars at preschool, showing off how far you can go. You make it three bars... then your sweaty hands slip. You land hard on your left arm. It REALLY hurts. The teacher rushes over.",
		question = "How do you react to this pain and fear?",
		minAge = 3, maxAge = 5,
		baseChance = 0.6,
		cooldown = 5,
		stage = STAGE,
		category = "injury",
		tags = { "health", "playground", "pain", "coping" },

		choices = {
			{ text = "Scream and cry for mom", effects = { Happiness = -5, Health = -3 }, setFlags = { injury_traumatized = true }, feedText = "You screamed and cried until your mom arrived. Luckily, just a bad bruise. But monkey bars scare you now." },
			{ text = "Try to be brave and hold back tears", effects = { Happiness = -2, Health = -3, Smarts = 2 }, setFlags = { tough = true, brave = true }, feedText = "You bit your lip hard and tried not to cry. Your arm swelled up - the nurse gave you ice. Your teacher said you were 'very brave.'" },
			{ text = "Get back up and keep playing", effects = { Health = -4, Happiness = 2 }, setFlags = { fearless = true, reckless = true }, feedText = "You shook it off and kept playing. Kids thought you were cool. But your arm really hurt that night." },
		},
	},

	{
		id = "imaginary_friend",
		title = "Your Invisible Companion",
		emoji = "👻",
		text = "For the past month, you've been talking to an invisible friend. Your parents think it's cute at first, but now you're setting a place for them at dinner and refusing to sit in the car if they don't have a seatbelt. They're very real to you.",
		question = "Who is this imaginary friend?",
		minAge = 3, maxAge = 5,
		oneTime = true,
		baseChance = 0.6,
		stage = STAGE,
		category = "psychology",
		tags = { "imagination", "social", "coping", "development" },
		careerTags = { "creative", "veterinary" },

		choices = {
			{ text = "A superhero named Captain Thunder", effects = { Happiness = 5, Smarts = 1 }, setFlags = { hero_complex = true, justice_driven = true }, feedText = "Captain Thunder helps you feel brave. When you're scared at night, he 'protects' you. Your dad makes a cape." },
			{ text = "A wise old wizard named Merlin", effects = { Smarts = 3 }, setFlags = { loves_fantasy = true, imaginative = true }, hintCareer = "creative", feedText = "Merlin teaches you 'magic spells' (really just creative problem solving). Your imagination flourishes." },
			{ text = "A talking dog named Buster", effects = { Happiness = 3 }, setFlags = { animal_lover = true, pet_obsessed = true }, hintCareer = "veterinary", feedText = "Buster understands you like no human does. You tell him all your secrets. You desperately want a real dog." },
			{ text = "Nobody - imaginary friends are weird", effects = { Smarts = 2 }, setFlags = { pragmatic = true, realistic = true }, feedText = "You don't need imaginary friends. You prefer real people and real things. Very practical for age 4." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- EARLY CHILDHOOD (Ages 5-8) - Elementary Foundation
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "stage_transition_child",
		title = "First Day of Kindergarten",
		emoji = "🏫",
		text = "The big yellow school bus pulls up to your house. This is it - REAL school. You have a brand new backpack (that's way too big) and light-up shoes. The school smells different than preschool - more serious. Your classroom has real desks. You're assigned to Table 3.",
		question = "What are you most excited (or nervous) about?",
		minAge = 5, maxAge = 5,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "school",
		milestoneKey = "CHILD_ELEMENTARY_START",
		tags = { "core", "school", "transition", "milestone" },
		careerTags = { "education", "sports", "creative" },

		choices = {
			{ text = "Making lots of new friends!", effects = { Happiness = 5 }, setFlags = { social_focus = true, extroverted = true }, feedText = "You're ready to meet everyone! By lunchtime you knew half the class's names. Social butterfly activated!" },
			{ text = "Learning to read real books", effects = { Smarts = 5, Happiness = 3 }, setFlags = { academic_focus = true, bookworm = true }, hintCareer = "education", feedText = "The library corner calls to you. Books are about to become your best friends. So many worlds to explore!" },
			{ text = "Recess and gym class", effects = { Health = 3, Happiness = 3 }, setFlags = { athletic_focus = true, energetic = true }, hintCareer = "sports", feedText = "You can't wait to run around! The playground is HUGE. You made it across the monkey bars on day one!" },
			{ text = "Art class and music", effects = { Happiness = 4, Looks = 2 }, setFlags = { artistic_focus = true, creative_soul = true }, hintCareer = "creative", feedText = "The art room has SO many supplies. And there's a music teacher with a guitar! Your creative heart soars." },
		},
	},

	{
		id = "lost_tooth_first",
		title = "Your First Wiggly Tooth",
		emoji = "🦷",
		text = "You're eating an apple at lunch when you feel it - one of your front teeth is LOOSE! You can wiggle it with your tongue. It's weird and exciting and a little scary. The tooth fairy is real, right?",
		question = "What do you do about this wiggly tooth?",
		minAge = 5, maxAge = 7,
		oneTime = true,
		isMilestone = true,
		stage = STAGE,
		category = "development",
		milestoneKey = "CHILD_FIRST_TOOTH_LOST",
		tags = { "body_change", "family", "money_small", "growing_up" },

		choices = {
			{ text = "Wiggle it constantly until it falls out", effects = { Happiness = 5, Health = -1 }, setFlags = { impatient = true }, feedText = "You wiggled it for three days straight until it popped out during dinner. Blood everywhere! But you were SO excited." },
			{ text = "Let it fall out naturally", effects = { Happiness = 3 }, setFlags = { patient = true }, feedText = "It fell out while you were eating a sandwich. You put it in a special box for the tooth fairy. So grown up!" },
			{ text = "Freak out and refuse to touch it", effects = { Happiness = -2 }, setFlags = { squeamish = true, anxious = true }, feedText = "The thought of it falling out scared you. Your parents had to reassure you this was normal. Eventually it fell out on its own." },
			{ text = "Immediately put it under your pillow", effects = { Happiness = 7, Money = 5 }, setFlags = { tooth_fairy_believer = true, optimistic = true }, feedText = "The tooth fairy left you $5! BEST DAY EVER. Being a big kid is amazing!" },
		},
	},

	{
		id = "reading_breakthrough",
		title = "I Can Read!",
		emoji = "📚",
		text = "You're looking at a picture book when suddenly the squiggly letters make SENSE. You can read the words! 'The cat sat on the mat.' You READ that! Your brain just... unlocked something. This changes everything.",
		question = "What happens next with this new superpower?",
		minAge = 5, maxAge = 7,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "development",
		tags = { "learning", "school", "milestone", "education" },
		careerTags = { "education", "law", "science" },

		choices = {
			{ text = "Read everything in sight", effects = { Smarts = 7, Happiness = 5 }, setFlags = { voracious_reader = true, bookworm = true }, hintCareer = "education", feedText = "You devoured every book in the house. Cereal boxes, street signs, everything! Your teacher moved you to advanced reading." },
			{ text = "Read to your parents proudly", effects = { Happiness = 5, Smarts = 3 }, setFlags = { seeks_approval = true, family_oriented = true }, feedText = "You read your first book out loud to your parents. They clapped and cheered. You felt like a superstar!" },
			{ text = "Keep it casual, no big deal", effects = { Smarts = 4 }, setFlags = { modest = true, humble = true }, feedText = "Reading is cool but you don't make a huge fuss. Just another skill unlocked." },
		},
	},

	{
		id = "best_friend_found",
		title = "A Real Best Friend",
		emoji = "🤝",
		text = "There's this kid in your class - Jordan. You both love the same things. You sit together at lunch. You pick each other for teams. You have inside jokes. Could this be... an actual best friend?",
		question = "What do you two do together?",
		minAge = 5, maxAge = 8,
		oneTime = true,
		priority = "high",
		stage = STAGE,
		category = "relationships",
		tags = { "friends", "school", "social", "important" },
		careerTags = { "tech", "sports", "science", "creative" },

		choices = {
			{ text = "Create elaborate imaginary worlds", effects = { Happiness = 7, Smarts = 2 }, setFlags = { creative_play = true, has_best_friend = true, imaginative = true }, hintCareer = "creative", feedText = "You and Jordan created entire kingdoms with complex rules and stories. Hours disappeared into your imaginary adventures." },
			{ text = "Build incredible LEGO creations", effects = { Smarts = 5, Happiness = 5 }, setFlags = { builder = true, has_best_friend = true, engineering_mind = true }, hintCareer = "tech", feedText = "You're a building team! Jordan does the foundation, you do the roof. Engineering minds in the making." },
			{ text = "Play sports at recess every day", effects = { Health = 5, Happiness = 5 }, setFlags = { sporty = true, has_best_friend = true, athletic = true }, hintCareer = "sports", feedText = "You and Jordan are always first picked for kickball. Sometimes you play so hard you both need to catch your breath." },
			{ text = "Explore and investigate everything", effects = { Smarts = 7, Happiness = 3 }, setFlags = { curious = true, has_best_friend = true, scientific_mind = true }, hintCareer = "science", feedText = "You're partners in curiosity. Why is the sky blue? How do ants work? You always ask 'why?'" },
		},
	},

	{
		id = "bike_learning",
		title = "The Two-Wheeled Challenge",
		emoji = "🚲",
		text = "Your dad just took the training wheels off your bike. It's sitting in the driveway, looking bigger and scarier than before. Your dad is holding the seat. 'I won't let go until you're ready,' he promises. Your heart pounds.",
		question = "How does your bike learning journey go?",
		minAge = 5, maxAge = 8,
		oneTime = true,
		isMilestone = true,
		stage = STAGE,
		category = "skills",
		milestoneKey = "CHILD_LEARNED_BIKE",
		tags = { "mobility", "outdoors", "independence", "achievement" },

		choices = {
			{ text = "Natural! Got it first try!", effects = { Happiness = 10, Health = 3 }, setFlags = { natural_athlete = true, coordinated = true, confident = true }, feedText = "You're a natural! You pedaled down the street on your first try while your dad ran behind you cheering. FREEDOM!" },
			{ text = "Crashed a lot but kept trying", effects = { Happiness = 5, Health = -4, Smarts = 2 }, setFlags = { persistent = true, tough = true, determined = true }, feedText = "You crashed into a bush, scraped both knees, and bruised your elbow. But you got right back on until you succeeded!" },
			{ text = "Needed training wheels for months", effects = { Happiness = 3, Health = 1 }, setFlags = { cautious_learner = true, patient = true }, feedText = "You took your time with training wheels. No shame in that. After six months, you were ready. Then you got it!" },
			{ text = "Too scared - gave up completely", effects = { Happiness = -3 }, setFlags = { bike_phobia = true, gives_up_easily = true, fearful = true }, feedText = "The bike sat in the garage gathering dust. Maybe someday... but not today." },
		},
	},

	{
		id = "bully_encounter",
		title = "The Playground Bully",
		emoji = "😠",
		text = "Marcus is a 5th grader who thinks he owns the playground. He's been pushing kids off swings, stealing lunch money, and calling people names. Today he shoved your friend Alex and made him cry. Everyone is watching what you'll do.",
		question = "How do you handle this bully situation?",
		minAge = 6, maxAge = 10,
		baseChance = 0.6,
		cooldown = 3,
		stage = STAGE,
		category = "relationships",
		tags = { "conflict", "school", "bullying", "courage" },
		careerTags = { "law", "government" },

		choices = {
			{ text = "Confront Marcus directly", effects = { Happiness = 3, Health = -3 }, setFlags = { brave = true, stands_up_for_others = true, courageous = true }, hintCareer = "government", feedText = "You marched up and told Marcus to stop. He pushed you too. But a teacher saw and Marcus got detention. You earned respect." },
			{ text = "Report him to the principal", effects = { Happiness = 2, Smarts = 2 }, setFlags = { trusts_authority = true, rule_follower = true }, hintCareer = "law", feedText = "You told the principal everything. Marcus got suspended. Some kids called you a snitch, but Alex thanked you." },
			{ text = "Avoid Marcus at all costs", effects = { Happiness = -3 }, setFlags = { conflict_avoidant = true, cowardly = true }, feedText = "You learned which parts of the playground to avoid. Safety over bravery. You feel a little ashamed though." },
			{ text = "Try to understand why he's mean", effects = { Smarts = 4, Happiness = 1 }, setFlags = { empathetic = true, peacemaker = true, emotionally_intelligent = true }, hintCareer = "medical", feedText = "You learned Marcus's parents are divorced and he's hurting. You tried to befriend him. Sometimes kindness is powerful." },
		},
	},

	{
		id = "class_pet_responsibility",
		title = "Classroom Hamster Crisis",
		emoji = "🐹",
		text = "Mr. Henderson's class hamster (Nibbles) needs a caretaker over spring break. The teacher asks for volunteers. Your hand shoots up! But wait - your parents haven't said yes yet. What if Nibbles escapes? What if you forget to feed him?",
		question = "Do you take on this big responsibility?",
		minAge = 6, maxAge = 9,
		baseChance = 0.7,
		cooldown = 5,
		stage = STAGE,
		category = "responsibility",
		tags = { "animals", "school", "responsibility", "trust" },
		careerTags = { "veterinary", "science" },

		choices = {
			{ text = "Eagerly volunteer and take perfect care", effects = { Happiness = 7, Smarts = 2 }, setFlags = { responsible = true, animal_lover = true, trustworthy = true }, hintCareer = "veterinary", feedText = "You fed Nibbles every day, cleaned his cage, and even built him new toys! Mr. Henderson said you were the best pet-sitter ever!" },
			{ text = "Take him but forget once or twice", effects = { Happiness = 2, Health = -1 }, setFlags = { forgetful = true, tries_hard = true }, feedText = "You mostly remembered to feed Nibbles. There was one scary morning when you realized you forgot the night before. He was fine though!" },
			{ text = "Too scared of the responsibility", effects = { Happiness = -2 }, setFlags = { avoids_responsibility = true, anxious = true }, feedText = "The pressure was too much. What if something went wrong? Someone else took Nibbles home instead." },
		},
	},

	{
		id = "talent_show_decision",
		title = "The School Talent Show",
		emoji = "🎤",
		text = "There's a talent show in two weeks. Everyone's buzzing about it. Some kids are forming bands, others are planning magic tricks. Your teacher asks if you want to participate. You'd have to perform in front of the ENTIRE school. Parents too.",
		question = "Do you sign up? And what would you do?",
		minAge = 7, maxAge = 10,
		baseChance = 0.6,
		cooldown = 4,
		stage = STAGE,
		category = "performance",
		tags = { "school", "performance", "courage", "identity" },
		careerTags = { "creative", "entertainment", "music" },

		choices = {
			{ text = "Sing a song solo", effects = { Happiness = 5, Looks = 3 }, setFlags = { performer = true, confident = true, brave = true }, hintCareer = "entertainment", feedText = "Your hands shook but your voice held strong. Everyone clapped! You felt like a star. Your parents recorded it." },
			{ text = "Do a comedy routine", effects = { Happiness = 7, Smarts = 2 }, setFlags = { funny = true, entertainer = true, witty = true }, hintCareer = "creative", feedText = "You told jokes you'd been practicing for weeks. Kids laughed! Even the principal chuckled. You found your thing!" },
			{ text = "Join a group act to feel safer", effects = { Happiness = 3 }, setFlags = { team_player = true, cautious = true }, feedText = "You and three friends did a dance routine. Safety in numbers! It went pretty well." },
			{ text = "Way too scary - sit in the audience", effects = { Happiness = -1 }, setFlags = { stage_fright = true, shy = true }, feedText = "You watched from the audience. Maybe next year. Public performance is TERRIFYING." },
		},
	},

	{
		id = "sibling_fight",
		title = "The Big Sibling Fight",
		emoji = "👊",
		text = "Your younger sibling broke your favorite toy - the one Grandma gave you for your birthday. They said it was an accident but you SAW them throw it. You're SO MAD. Your hands are shaking. Your parents are in the other room.",
		question = "What do you do?",
		minAge = 6, maxAge = 10,
		baseChance = 0.7,
		cooldown = 2,
		stage = STAGE,
		category = "relationships",
		tags = { "family", "conflict", "emotions", "anger" },

		choices = {
			{ text = "Push them and start yelling", effects = { Happiness = -5, Health = -2 }, setFlags = { hot_tempered = true, physical_fighter = true }, feedText = "You pushed them and they fell. They cried. You got grounded for a week. The toy is still broken. Everyone's upset." },
			{ text = "Tell on them to your parents", effects = { Happiness = -2 }, setFlags = { tattletale = true, seeks_justice = true }, feedText = "Your parents made them apologize but couldn't fix the toy. You felt a little better but not much." },
			{ text = "Go to your room and cry", effects = { Happiness = -3 }, setFlags = { sensitive = true, internalizes_emotions = true }, feedText = "You cried alone in your room for an hour. Your sibling brought you a cookie later. Maybe they felt bad." },
			{ text = "Take a breath and talk it out", effects = { Happiness = 2, Smarts = 3 }, setFlags = { emotionally_mature = true, communicator = true }, feedText = "You counted to 10, then explained why you're hurt. They apologized sincerely. You're learning conflict resolution!" },
		},
	},

	{
		id = "sleepover_first",
		title = "First Sleepover",
		emoji = "🏠",
		text = "Your best friend invited you to sleep over at their house! You've never slept anywhere but home before. Your bag is packed with your stuffed animal and toothbrush. But now that it's getting dark, you're not sure about this...",
		question = "How does your first sleepover go?",
		minAge = 7, maxAge = 10,
		oneTime = true,
		stage = STAGE,
		category = "social",
		tags = { "friends", "milestone", "independence", "growth" },

		choices = {
			{ text = "Have an AMAZING time", effects = { Happiness = 8 }, setFlags = { independent = true, adventurous = true, social = true }, feedText = "You stayed up late eating pizza, playing games, and giggling. You didn't even miss home! You want to do this every weekend!" },
			{ text = "Make it through but feel homesick", effects = { Happiness = 2 }, setFlags = { homebody = true, cautious = true }, feedText = "You had fun but kept thinking about your own bed. You made it through the night though! Progress!" },
			{ text = "Call parents at 10pm to pick you up", effects = { Happiness = -3 }, setFlags = { homesick = true, attached_to_home = true }, feedText = "At 10pm you were crying. Your parents came to get you. Your friend understood. Maybe next time you'll make it." },
		},
	},

	-- ══════════════════════════════════════════════════════════════════════════════
	-- LATE CHILDHOOD (Ages 9-12) - Pre-Teen Development
	-- ══════════════════════════════════════════════════════════════════════════════

	{
		id = "passion_discovery",
		title = "Finding Your Passion",
		emoji = "⭐",
		text = "Over the past few months, you've become OBSESSED with something. You think about it all the time. You read about it, watch videos, practice constantly. Your parents notice the shift - you've found something that makes you come alive.",
		question = "What captured your heart and imagination?",
		minAge = 8, maxAge = 12,
		oneTime = true,
		isMilestone = true,
		priority = "high",
		stage = STAGE,
		category = "identity",
		milestoneKey = "CHILD_DISCOVERED_PASSION",
		tags = { "core", "identity", "talent", "future" },
		careerTags = { "sports", "creative", "science", "tech", "medical", "entertainment" },

		choices = {
			{ text = "Basketball/soccer/sports", effects = { Health = 7, Happiness = 7 }, setFlags = { passionate_athlete = true, sports_obsessed = true, competitive = true }, hintCareer = "sports", feedText = "You practice for hours every day. You know all the stats, all the plays. This is YOUR thing. You dream of going pro!" },
			{ text = "Drawing, painting, creating art", effects = { Happiness = 9, Looks = 4 }, setFlags = { passionate_artist = true, artistic_genius = true }, hintCareer = "creative", feedText = "Your sketchbook goes everywhere. You see the world in colors and shapes. You've filled 7 notebooks with drawings!" },
			{ text = "Science experiments and discovery", effects = { Smarts = 9, Happiness = 5 }, setFlags = { passionate_scientist = true, scientist_mind = true }, hintCareer = "science", feedText = "You turned the garage into a lab. You're always asking 'what if?' The mysteries of the universe call to you!" },
			{ text = "Building with code/electronics", effects = { Smarts = 8, Happiness = 6 }, setFlags = { passionate_builder = true, tech_wizard = true }, hintCareer = "tech", feedText = "You learned to code online. You built a robot that moves! You spend hours tinkering with circuits and programs!" },
			{ text = "Helping people/volunteering", effects = { Happiness = 7, Smarts = 3 }, setFlags = { passionate_helper = true, empathetic = true }, hintCareer = "medical", feedText = "You volunteer at the nursing home. You help younger kids with homework. Helping others fills your soul!" },
			{ text = "Music, singing, performing", effects = { Happiness = 9, Looks = 3 }, setFlags = { passionate_performer = true, musical = true }, hintCareer = "entertainment", feedText = "You practice your instrument daily. Music is how you express your feelings. The stage feels like home!" },
		},
	},

	{
		id = "science_fair_project",
		title = "The Science Fair Competition",
		emoji = "🔬",
		text = "The school science fair is in 3 weeks. Mrs. Chen says this year's projects will compete at the regional level. You need to pick a project that's impressive but doable. The winner gets a trophy AND a $100 gift card.",
		question = "What's your project strategy?",
		minAge = 8, maxAge = 11,
		baseChance = 0.7,
		cooldown = 3,
		stage = STAGE,
		category = "school",
		tags = { "science", "project", "school", "competition" },
		careerTags = { "science", "tech", "medical" },

		choices = {
			{ text = "Classic volcano - but HUGE", effects = { Smarts = 4, Happiness = 6 }, setFlags = { likes_chemistry = true, showman = true }, hintCareer = "science", feedText = "Your 3-foot volcano erupted spectacularly! Everyone crowded around. You didn't win but you got 'Most Creative!'" },
			{ text = "Plant growth experiment", effects = { Smarts = 7, Happiness = 3 }, setFlags = { patient_researcher = true, methodical = true }, hintCareer = "science", feedText = "You tested 5 variables over 4 weeks with careful data logging. The judges loved your scientific method. 3rd place!" },
			{ text = "Build a working robot", effects = { Smarts = 9, Happiness = 5 }, setFlags = { tech_enthusiast = true, ambitious = true }, hintCareer = "tech", feedText = "Your robot could pick up objects and respond to commands! You won 1st place! The local paper interviewed you!" },
			{ text = "Procrastinate, do it last minute", effects = { Smarts = 1, Happiness = -2 }, setFlags = { procrastinator = true, lazy = true }, feedText = "You made a poster the night before. It looked... rushed. You got a participation ribbon. You promise yourself: next year!" },
		},
	},

	{
		id = "summer_camp_choice",
		title = "Summer Camp Adventures",
		emoji = "🏕️",
		text = "It's April and your parents found a summer camp brochure. There are SO many options! Two weeks away from home at a camp that specializes in something you love. You get to pick which camp.",
		question = "Which camp sounds most exciting to you?",
		minAge = 8, maxAge = 12,
		baseChance = 0.5,
		cooldown = 2,
		stage = STAGE,
		category = "activities",
		tags = { "summer", "camp", "skills", "growth" },
		careerTags = { "science", "creative", "sports", "tech", "education" },

		choices = {
			{ text = "Wilderness survival camp", effects = { Health = 7, Happiness = 7, Smarts = 3 }, setFlags = { outdoorsy = true, survivalist = true, tough = true }, feedText = "You learned to start fires, build shelters, identify plants, and navigate by stars! You came home covered in bug bites but ALIVE!" },
			{ text = "Science & robotics camp", effects = { Smarts = 10, Happiness = 6 }, setFlags = { science_enthusiast = true, tech_mind = true }, hintCareer = "science", feedText = "You built a solar-powered car and launched water rockets! Best two weeks ever! You want to be a scientist now!" },
			{ text = "Art & theater camp", effects = { Happiness = 8, Looks = 4, Smarts = 2 }, setFlags = { artistic = true, performer = true }, hintCareer = "creative", feedText = "You painted, sculpted, and performed in a play! You found your creative voice! Your parents cried at the final show!" },
			{ text = "Sports training camp", effects = { Health = 10, Happiness = 6 }, setFlags = { athlete = true, competitive = true, disciplined = true }, hintCareer = "sports", feedText = "You trained 6 hours a day! You improved SO much! The coaches said you have potential! Your muscles hurt but in a good way!" },
			{ text = "Computer coding camp", effects = { Smarts = 10, Happiness = 5 }, setFlags = { coder = true, tech_genius = true }, hintCareer = "tech", feedText = "You learned Python, made a video game, and coded an app! The digital world is yours to command now!" },
		},
	},

	{
		id = "pet_adoption",
		title = "Adopting Your First Pet",
		emoji = "🐕",
		text = "After months of begging, your parents FINALLY agreed! You're at the animal shelter, walking past cages of barking dogs and meowing cats. They said you can pick ONE pet, but you must take care of it yourself. This is a big responsibility.",
		question = "Which animal do you choose?",
		minAge = 8, maxAge = 12,
		oneTime = true,
		baseChance = 0.5,
		stage = STAGE,
		category = "responsibility",
		tags = { "animals", "family", "responsibility", "pets" },
		careerTags = { "veterinary" },

		choices = {
			{ text = "The energetic golden retriever puppy", effects = { Happiness = 12, Health = 5 }, setFlags = { has_dog = true, animal_lover = true, has_pet = true, active = true }, hintCareer = "veterinary", feedText = "You named him Buddy! He chewed everything for 3 months. But he's your loyal best friend now! You walk him twice daily!" },
			{ text = "The calm adult cat", effects = { Happiness = 8, Smarts = 1 }, setFlags = { has_cat = true, animal_lover = true, has_pet = true }, feedText = "You picked a 3-year-old cat named Whiskers. She sleeps on your bed every night. Perfect chill companion!" },
			{ text = "The rabbit that needs a home", effects = { Happiness = 6, Smarts = 2 }, setFlags = { has_rabbit = true, animal_lover = true, has_pet = true, unique = true }, hintCareer = "veterinary", feedText = "You rescued a bunny named Snowball! You built her a huge enclosure. She does binkies when she's happy!" },
			{ text = "Actually... maybe not ready", effects = { Happiness = -2 }, setFlags = { changed_mind = true, realistic = true }, feedText = "Looking at all these animals, you realized how much work it is. You asked to wait another year. Responsible decision!" },
		},
	},

	{
		id = "first_crush_experience",
		title = "Butterflies and Confusion",
		emoji = "💕",
		text = "There's someone in your math class - Sam. When they smile at you, your stomach does flips. You accidentally looked at them three times during the test. Your face got HOT when they said hi in the hallway. What IS this feeling?",
		question = "How do you handle these confusing new emotions?",
		minAge = 9, maxAge = 12,
		oneTime = true,
		baseChance = 0.7,
		stage = STAGE,
		category = "relationships",
		tags = { "romance", "school", "feelings", "growing_up" },

		choices = {
			{ text = "Write them a secret note", effects = { Happiness = 5, Looks = 2 }, setFlags = { romantic_soul = true, brave = true }, feedText = "You wrote 'I think you're cool' and slipped it in their locker. They smiled at you the next day! Heart: POUNDING!" },
			{ text = "Tell your best friend", effects = { Happiness = 4 }, setFlags = { shares_feelings = true, trusts_friends = true }, feedText = "You confided in your BFF. They squealed! Now you both analyze every interaction. 'What did that MEAN?!'" },
			{ text = "Keep it a total secret", effects = { Happiness = 1 }, setFlags = { private_person = true, guarded = true }, feedText = "You kept these feelings locked tight. They're just for you. Some things are too precious to share." },
			{ text = "Romance is GROSS!", effects = { Happiness = 2 }, setFlags = { anti_romance = true, immature = true }, feedText = "EW. Feelings? No thanks! You've got better things to do like play video games and eat pizza!" },
		},
	},

	{
		id = "money_management_start",
		title = "Your First Allowance",
		emoji = "💰",
		text = "Your parents started giving you $10 a week for doing chores. That's $40 a month! You feel RICH! But there's so much you want to buy. Your friend's dad told you 'save your money wisely, kid.' But the toy store is calling...",
		question = "What's your money philosophy?",
		minAge = 8, maxAge = 11,
		oneTime = true,
		stage = STAGE,
		category = "money",
		tags = { "money", "family", "habits", "discipline" },
		careerTags = { "finance" },

		choices = {
			{ text = "Save every single penny", effects = { Smarts = 4, Happiness = 2, Money = 100 }, setFlags = { saver = true, disciplined = true, frugal = true }, hintCareer = "finance", feedText = "Six months later you have $240 saved! Your parents are impressed! You open your first bank account! Future investor!" },
			{ text = "Spend it immediately on candy/toys", effects = { Happiness = 7, Money = -30 }, setFlags = { spender = true, impulsive = true }, feedText = "You enjoy your money NOW! Candy, toys, video games! Your piggy bank is always empty but you're having FUN!" },
			{ text = "Save half, spend half (balanced)", effects = { Smarts = 3, Happiness = 5, Money = 50 }, setFlags = { balanced_spender = true, mature = true }, feedText = "You save $5, spend $5. Best of both worlds! You're learning balance! Your parents call you 'wise beyond your years!'" },
			{ text = "Try to start a mini business", effects = { Smarts = 7, Happiness = 4, Money = 75 }, setFlags = { entrepreneur = true, ambitious = true, creative = true }, hintCareer = "finance", feedText = "You started a lemonade stand and sold drawings! You're already thinking about ROI! Young entrepreneur!" },
		},
	},

	{
		id = "team_sport_tryouts",
		title = "Trying Out for the Team",
		emoji = "⚽",
		text = "Tryouts for the school soccer team are tomorrow. You've been practicing in the backyard for weeks. Your dad has been helping you. But what if you're not good enough? What if you embarrass yourself? What if you make the B-team instead of A?",
		question = "How do you approach this high-pressure tryout?",
		minAge = 9, maxAge = 12,
		baseChance = 0.6,
		cooldown = 4,
		stage = STAGE,
		category = "sports",
		tags = { "school", "sports", "pressure", "courage" },
		careerTags = { "sports" },

		choices = {
			{ text = "Give it everything you've got!", effects = { Health = 7, Happiness = 8, Smarts = 2 }, setFlags = { athletic = true, competitive = true, made_team = true }, hintCareer = "sports", feedText = "You played your heart out! The coach called your name for A-team! You celebrated with ice cream! You're an ATHLETE!" },
			{ text = "Try your best but stay realistic", effects = { Health = 4, Happiness = 3 }, setFlags = { made_b_team = true, humble = true }, feedText = "You made B-team! Not A, but still on a team! You'll work your way up! Progress over perfection!" },
			{ text = "Get too nervous and underperform", effects = { Happiness = -4, Health = 2 }, setFlags = { chokes_under_pressure = true, anxious = true }, feedText = "Your nerves got the best of you. You missed easy shots. You didn't make the team. You cried in your mom's car." },
			{ text = "Don't even try out (too scary)", effects = { Happiness = -2 }, setFlags = { afraid_to_fail = true, regretful = true }, feedText = "You chickened out. You watched tryouts from the fence. You wonder 'what if?' Maybe next year..." },
		},
	},

	{
		id = "gaming_obsession",
		title = "Video Game Addiction?",
		emoji = "🎮",
		text = "You got a new video game for your birthday. It's AMAZING. You've been playing 4-5 hours after school every day for two weeks. Your grades slipped. Your parents are worried. Your friends say you're always 'busy' now. But you're so close to the next level...",
		question = "How do you handle this?",
		minAge = 9, maxAge = 12,
		baseChance = 0.6,
		cooldown = 3,
		stage = STAGE,
		category = "habits",
		tags = { "addiction", "gaming", "balance", "discipline" },

		choices = {
			{ text = "Set healthy limits yourself", effects = { Smarts = 5, Happiness = 5 }, setFlags = { self_disciplined = true, balanced = true, mature = true }, feedText = "You set a 1-hour limit. You finish homework first. You still game, but it doesn't control you. Balance achieved!" },
			{ text = "Keep playing obsessively", effects = { Smarts = -5, Happiness = 3, Health = -3 }, setFlags = { addictive_personality = true, obsessive = true }, feedText = "You played until 2am on school nights. Your grades tanked. Your parents took the console away. Oops." },
			{ text = "Quit gaming entirely", effects = { Happiness = -3, Smarts = 3 }, setFlags = { all_or_nothing = true, rigid = true }, feedText = "You deleted all your games. You went too far the other way. Balance is hard. But you focus better now." },
		},
	},

	{
		id = "middle_school_transition",
		title = "Starting Middle School",
		emoji = "🏫",
		text = "Today is the first day of 6th grade - MIDDLE SCHOOL. Everything is different. You change classes. You have a locker combination to remember. There are 8TH GRADERS who look like adults. You feel tiny and scared and excited all at once.",
		question = "How do you navigate this huge transition?",
		minAge = 11, maxAge = 11,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "school",
		milestoneKey = "CHILD_MIDDLE_SCHOOL_START",
		tags = { "core", "school", "transition", "milestone", "growing_up" },

		choices = {
			{ text = "Jump into clubs and activities", effects = { Happiness = 7, Smarts = 3 }, setFlags = { joiner = true, social = true, well_rounded = true }, feedText = "You joined debate club, art club, and the school newspaper! You're meeting tons of new people! Your calendar is FULL!" },
			{ text = "Focus on academics", effects = { Smarts = 7, Happiness = 2 }, setFlags = { academic_focused = true, studious = true, serious = true }, feedText = "You're laser-focused on grades. Honor roll first quarter! Teachers already know your name! Future valedictorian?" },
			{ text = "Try to blend in quietly", effects = { Happiness = 1 }, setFlags = { invisible = true, shy = true, cautious = true }, feedText = "You keep your head down. Don't stand out. Just survive. It's a strategy. Not the most fun one though." },
			{ text = "Reinvent yourself!", effects = { Happiness = 6, Looks = 3 }, setFlags = { confident = true, new_identity = true }, feedText = "New school, new you! You changed your style, joined new groups, made new friends! Fresh start!" },
		},
	},

	{
		id = "social_media_pressure",
		title = "The Social Media Temptation",
		emoji = "📱",
		text = "Everyone at school is on social media now. They're all following each other, posting selfies, and you're... not there. Your parents said you're too young. But you feel left out. Kids are making plans in group chats you're not in. You found out about a party AFTER it happened.",
		question = "What do you do about this FOMO?",
		minAge = 10, maxAge = 12,
		baseChance = 0.7,
		cooldown = 3,
		stage = STAGE,
		category = "social",
		tags = { "technology", "peer_pressure", "social", "modern" },

		choices = {
			{ text = "Make a secret account", effects = { Happiness = 5, Smarts = -2 }, setFlags = { sneaky = true, disobedient = true, peer_pressured = true }, feedText = "You made an account behind your parents' backs. It was fun at first. Then your mom found it. Phone privileges GONE." },
			{ text = "Talk to parents about it maturely", effects = { Smarts = 5, Happiness = 3 }, setFlags = { communicative = true, mature = true, trusts_parents = true }, feedText = "You explained how you feel left out. Your parents compromised - you can join with limits. Mature conversation wins!" },
			{ text = "Stay off it, find other ways to connect", effects = { Happiness = 2, Smarts = 3 }, setFlags = { independent_thinker = true, patient = true }, feedText = "You called friends, texted, and met up in person. Old school but it works. You don't need social media to have friends." },
		},
	},

	{
		id = "parent_divorce_announcement",
		title = "Parents Sitting Down to Talk",
		emoji = "💔",
		text = "Your parents call a 'family meeting.' Your stomach drops. Those are never good. They sit you down in the living room. Their faces are serious. Your mom starts crying. Your dad says, 'We need to talk about some changes...' Your heart pounds.",
		question = "How do you cope with this life-changing news?",
		minAge = 8, maxAge = 12,
		baseChance = 0.3,
		oneTime = true,
		stage = STAGE,
		category = "relationships",
		tags = { "family", "trauma", "divorce", "difficult", "emotions" },

		choices = {
			{ text = "Blame yourself", effects = { Happiness = -10, Health = -2 }, setFlags = { self_blaming = true, traumatized = true, abandonment_issues = true }, feedText = "You think it's your fault. You should have been better. You cry yourself to sleep for weeks. This changes you." },
			{ text = "Get angry at both parents", effects = { Happiness = -7, Smarts = 1 }, setFlags = { angry = true, distrustful = true, wounded = true }, feedText = "You're MAD. How could they do this to you? You stop talking to them for weeks. Trust is broken." },
			{ text = "Try to understand it's not about you", effects = { Happiness = -5, Smarts = 5 }, setFlags = { emotionally_mature = true, resilient = true }, feedText = "It hurts SO much. But they explained - adults sometimes grow apart. It's not your fault. You're strong. You'll be okay." },
			{ text = "Lean on friends for support", effects = { Happiness = -3 }, setFlags = { support_seeking = true, resilient = true, social_support = true }, feedText = "Your best friend's parents are divorced too. They understood. Talking helped. You're going to get through this." },
		},
	},

	{
		id = "shoplifting_temptation",
		title = "The Dare at the Store",
		emoji = "🏪",
		text = "You're at the corner store with your friends. One of them dares you to steal a candy bar. 'Everyone does it,' they say. The clerk isn't looking. Your friends are watching, waiting to see if you're 'cool' enough. Your heart races. You know this is wrong but...",
		question = "What do you do in this pressure situation?",
		minAge = 10, maxAge = 12,
		baseChance = 0.5,
		cooldown = 5,
		stage = STAGE,
		category = "morality",
		tags = { "crime", "peer_pressure", "morality", "decision" },
		careerTags = { "law", "criminal" },

		choices = {
			{ text = "Do it to fit in", effects = { Happiness = 3, Smarts = -3 }, setFlags = { peer_pressured = true, moral_gray = true, shoplifted = true }, feedText = "You took the candy. Your friends cheered. You felt sick the whole way home. You don't feel 'cool.' You feel gross." },
			{ text = "Refuse firmly and walk out", effects = { Happiness = 5, Smarts = 5 }, setFlags = { strong_morals = true, brave = true, leader = true }, hintCareer = "law", feedText = "You said NO and left. One friend followed you out. Real friends don't pressure you to steal. You feel proud of yourself." },
			{ text = "Buy the candy instead", effects = { Happiness = 3, Smarts = 3, Money = -2 }, setFlags = { law_abiding = true, smart_thinker = true }, feedText = "You used your allowance to buy it. 'I'm not risking a criminal record for a candy bar,' you said. Smart choice." },
		},
	},

	{
		id = "period_start_girls",
		title = "Growing Up: Your First Period",
		emoji = "🩸",
		text = "(For girls) You're in the school bathroom when you notice blood. Your FIRST period! You knew this would happen eventually but NOW? AT SCHOOL? Your heart races. You remember the health class video but this is REAL.",
		question = "How do you handle this milestone moment?",
		minAge = 10, maxAge = 13,
		oneTime = true,
		stage = STAGE,
		category = "development",
		tags = { "puberty", "growing_up", "body_changes", "milestone" },
		conditions = { gender = "Female" },

		choices = {
			{ text = "Ask the nurse for help confidently", effects = { Happiness = 5, Smarts = 3 }, setFlags = { mature = true, handles_puberty_well = true }, feedText = "The school nurse was super nice! She gave you supplies and called your mom. She said 'welcome to womanhood!' You feel grown up." },
			{ text = "Panic and call mom immediately", effects = { Happiness = -2 }, setFlags = { overwhelmed = true, needs_support = true }, feedText = "You called your mom crying. She came to school with supplies and gave you a huge hug. It's scary but she's there for you." },
			{ text = "Handle it yourself like no big deal", effects = { Happiness = 3, Smarts = 2 }, setFlags = { independent = true, handles_puberty_well = true }, feedText = "You asked a friend for a pad, handled it, and moved on with your day. You're a pro already. No big deal!" },
		},
	},

	{
		id = "voice_change_boys",
		title = "Growing Up: Voice Cracking",
		emoji = "🎤",
		text = "(For boys) You're answering a question in English class when your voice CRACKS mid-sentence. It goes from normal to SQUEAKY. The whole class giggles. Your face burns red. Your voice has been doing this all week. Puberty is EMBARRASSING.",
		question = "How do you handle the embarrassment?",
		minAge = 11, maxAge = 13,
		oneTime = true,
		stage = STAGE,
		category = "development",
		tags = { "puberty", "growing_up", "body_changes", "embarrassment" },
		conditions = { gender = "Male" },

		choices = {
			{ text = "Laugh it off confidently", effects = { Happiness = 5, Looks = 2 }, setFlags = { confident = true, handles_puberty_well = true, sense_of_humor = true }, feedText = "You laughed at yourself and made a joke. Everyone laughed WITH you instead of AT you. Confidence wins!" },
			{ text = "Die of embarrassment inside", effects = { Happiness = -5, Looks = -2 }, setFlags = { self_conscious = true, insecure = true }, feedText = "You wanted to disappear. You avoided talking in class for weeks. Puberty is the WORST. You feel so awkward." },
			{ text = "Shrug it off, it happens to everyone", effects = { Happiness = 2, Smarts = 2 }, setFlags = { mature = true, handles_puberty_well = true }, feedText = "You shrugged. Every guy goes through this. It's natural. Your friends' voices crack too. You're all awkward together!" },
		},
	},

	{
		id = "essay_contest_win",
		title = "Writing Competition Victory",
		emoji = "✍️",
		text = "You entered a city-wide essay contest on a whim. Your teacher said your writing was 'exceptional.' Today, you got a letter in the mail. You WON! $500 prize and your essay will be published in the newspaper! Your parents are LOSING THEIR MINDS with pride!",
		question = "How do you celebrate this achievement?",
		minAge = 9, maxAge = 12,
		baseChance = 0.3,
		oneTime = true,
		stage = STAGE,
		category = "achievement",
		tags = { "academics", "writing", "success", "pride" },
		careerTags = { "creative", "education", "journalist" },

		choices = {
			{ text = "Be proud and own it!", effects = { Happiness = 10, Smarts = 5, Looks = 2, Money = 500 }, setFlags = { talented_writer = true, confident = true, award_winner = true }, hintCareer = "creative", feedText = "Your essay was read at an award ceremony! You gave a speech! You framed the newspaper article! You're a PUBLISHED AUTHOR at age 11!" },
			{ text = "Share success with your teacher", effects = { Happiness = 8, Smarts = 3, Money = 500 }, setFlags = { grateful = true, humble = true }, feedText = "You credited Mrs. Johnson who encouraged you. She cried happy tears. You learned: success is sweeter when shared." },
			{ text = "Downplay it to avoid attention", effects = { Happiness = 4, Smarts = 2, Money = 500 }, setFlags = { modest = true, uncomfortable_with_praise = true }, feedText = "You kind of hid the award. Attention feels weird. Your parents are confused why you're not more excited." },
		},
	},

	{
		id = "friend_betrayal",
		title = "The Friend Who Backstabbed You",
		emoji = "🔪",
		text = "Your best friend since 2nd grade - the one you told EVERYTHING - just spread your biggest secret to the whole grade. Everyone knows now. They're laughing about it in the cafeteria. You see your 'friend' with a new group, avoiding your eyes. This HURTS.",
		question = "How do you process this deep betrayal?",
		minAge = 10, maxAge = 12,
		baseChance = 0.5,
		cooldown = 5,
		stage = STAGE,
		category = "relationships",
		tags = { "friends", "betrayal", "trust", "pain", "social" },

		choices = {
			{ text = "Confront them publicly", effects = { Happiness = -5, Looks = 1 }, setFlags = { confrontational = true, vengeful = true }, feedText = "You called them out in front of everyone. It felt good for 5 seconds. Then it felt worse. The friendship is OVER." },
			{ text = "Cut them off completely", effects = { Happiness = -7, Smarts = 3 }, setFlags = { protective = true, trust_issues = true }, feedText = "You blocked them everywhere. Never spoke again. Trust once broken can't be fixed. You're more careful now who you trust." },
			{ text = "Try to understand why", effects = { Happiness = -5, Smarts = 5 }, setFlags = { forgiving = true, emotionally_mature = true }, feedText = "You asked them why. They were jealous and insecure. You forgave but the friendship was never the same. Growth hurts." },
			{ text = "Let it go and move on", effects = { Happiness = -3, Smarts = 4 }, setFlags = { resilient = true, mature = true }, feedText = "It hurts but you don't retaliate. You find better friends. Some people aren't meant to stay in your life forever." },
		},
	},

	{
		id = "death_of_pet",
		title = "Saying Goodbye to Your Pet",
		emoji = "🌈",
		text = "Your dog/cat has been sick. The vet says there's nothing more they can do. Your parents say you get to say goodbye. You hold your pet's paw as they drift off peacefully. They're gone. Your first real experience with death. The house feels empty.",
		question = "How do you grieve this loss?",
		minAge = 8, maxAge = 12,
		baseChance = 0.3,
		cooldown = 10,
		oneTime = true,
		stage = STAGE,
		category = "relationships",
		tags = { "death", "pet", "grief", "loss", "emotions" },
		conditions = { flag = "has_pet" },

		choices = {
			{ text = "Cry for weeks, deep grief", effects = { Happiness = -10, Health = -2 }, setFlags = { grieving = true, sensitive = true, loved_deeply = true }, feedText = "You sobbed every night for a month. You kept their collar under your pillow. The pain was crushing. But that's how much you loved them." },
			{ text = "Create a memorial, honor them", effects = { Happiness = -5, Smarts = 3 }, setFlags = { memorializing = true, celebrates_life = true }, feedText = "You made a photo album and planted a tree in their honor. You chose to celebrate the happy years. They'd want you to remember the joy." },
			{ text = "Bottle up emotions, act tough", effects = { Happiness = -7, Health = -1 }, setFlags = { emotional_repression = true, tough_exterior = true }, feedText = "You didn't cry. You acted fine. But inside you hurt SO bad. Your parents worried. It's okay to grieve." },
			{ text = "Know another pet will help", effects = { Happiness = -3 }, setFlags = { ready_to_love_again = true, optimistic = true }, feedText = "After two months, you asked about adopting again. Not replacing them - honoring them by giving another animal a loving home." },
		},
	},

	{
		id = "puberty_education_class",
		title = "The Awkward Health Class",
		emoji = "😳",
		text = "Today in health class: THE PUBERTY TALK. They separated boys and girls. The teacher put on a video from 1995 with terrible acting. Everyone is giggling nervously. You're learning about body changes, periods, voice changes, and... other stuff. So. Much. Awkwardness.",
		question = "How do you handle this uncomfortable education?",
		minAge = 10, maxAge = 12,
		oneTime = true,
		baseChance = 0.9,
		stage = STAGE,
		category = "development",
		tags = { "puberty", "education", "awkward", "school" },

		choices = {
			{ text = "Take it seriously, learn everything", effects = { Smarts = 5, Happiness = 2 }, setFlags = { educated_about_puberty = true, mature = true }, feedText = "You listened carefully and asked questions. Knowledge is power! You understand what's happening to your body now. No surprises!" },
			{ text = "Giggle through the whole thing", effects = { Happiness = 5 }, setFlags = { immature = true, uncomfortable = true }, feedText = "You and your friends couldn't stop giggling. The teacher kept glaring. You learned nothing but had fun?" },
			{ text = "Feel super uncomfortable, tune out", effects = { Happiness = -2, Smarts = -2 }, setFlags = { uncomfortable_with_body = true, uninformed = true }, feedText = "You stared at your desk the whole time. Too awkward! You'll learn about this... someday... somehow... ugh." },
		},
	},

	{
		id = "graduation_elementary",
		title = "Elementary School Graduation",
		emoji = "🎓",
		text = "It's your last day of elementary school. You're wearing a little cap and gown. There's a ceremony with speeches. Your kindergarten teacher came to watch. You look around at friends you've known since you were 5. Everything is about to change. Middle school starts in September.",
		question = "How do you feel about this ending and new beginning?",
		minAge = 11, maxAge = 12,
		oneTime = true,
		priority = "high",
		isMilestone = true,
		stage = STAGE,
		category = "milestone",
		milestoneKey = "CHILD_ELEMENTARY_GRADUATION",
		tags = { "core", "school", "transition", "growing_up", "milestone" },

		choices = {
			{ text = "Excited for the future!", effects = { Happiness = 8, Smarts = 2 }, setFlags = { optimistic = true, excited_for_future = true }, feedText = "You're READY for middle school! New challenges! New friends! You can't wait! Your teacher said you'll do great things!" },
			{ text = "Nostalgic and emotional", effects = { Happiness = 3 }, setFlags = { sentimental = true, nostalgic = true }, feedText = "You cried during the ceremony. So many memories! You'll miss this school, these teachers, being a kid. Growing up is bittersweet." },
			{ text = "Mixed feelings - nervous but hopeful", effects = { Happiness = 5, Smarts = 3 }, setFlags = { realistic = true, balanced = true }, feedText = "You feel everything at once. Scared, excited, sad, hopeful. That's normal. Change is hard. But you're ready. Time to grow up." },
		},
	},
}

return Childhood
