--[[
	SchoolActivityEvents.lua
	========================
	Comprehensive event templates for school and education activities.
	These events give players immersive BitLife-style event cards for all
	school-related interactions and experiences.
	
	Categories:
	- StudyHard: Focused studying
	- ClassEvent: Things that happen in class
	- ExamEvent: Tests and exams
	- ClubActivity: Extracurricular clubs
	- SportsTeam: School sports
	- SocialEvent: School social events
	- TeacherInteraction: Interactions with teachers
	- PeerInteraction: Interactions with classmates
	- Detention: Getting in trouble
	- Graduation: Completing school
--]]

local SchoolEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- STUDY HARD EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.StudyHard = {
	-- Event 1: Library study session
	{
		id = "study_library",
		title = "📚 Library Study Session",
		texts = {
			"You find a quiet corner in the school library to study.",
			"Books spread out before you, it's time to hit the books!",
			"The library is your sanctuary for learning.",
			"Focus. Concentrate. You've got this.",
		},
		effects = { Smarts = {5, 12} },
		choices = {
			{
				text = "Study intensely for hours",
				feedback = {
					"You're in the zone! The material finally clicks!",
					"Hours fly by as you absorb knowledge.",
					"Your brain hurts, but in a good way!",
				},
				effects = { Smarts = 12, Happiness = -2 },
			},
			{
				text = "Take organized notes",
				feedback = {
					"Your color-coded notes are works of art!",
					"Future you will thank present you.",
					"Organized notes make exam time easier.",
				},
				effects = { Smarts = 10 },
			},
			{
				text = "Study with friends",
				feedback = {
					"Group study is productive AND fun!",
					"You help each other understand tough concepts.",
					"Learning is better together!",
				},
				effects = { Smarts = 8, Happiness = 5 },
			},
			{
				text = "Get distracted by your phone",
				feedback = {
					"'Just 5 minutes' turns into an hour...",
					"You scroll through social media instead of studying.",
					"Not your most productive study session.",
				},
				effects = { Smarts = 2, Happiness = 3 },
			},
		},
	},
	-- Event 2: Late night cram
	{
		id = "study_cram",
		title = "🌙 Late Night Cramming",
		texts = {
			"Big test tomorrow! Time to cram!",
			"Coffee and desperation fuel your late-night study session.",
			"Why didn't you start studying earlier? Too late now!",
		},
		effects = { Smarts = {3, 8}, Health = {-5, -2} },
		choices = {
			{
				text = "Pull an all-nighter",
				feedback = {
					"Sleep is for the weak! You study through the night!",
					"You're exhausted but know the material cold.",
					"Let's hope you can stay awake during the test...",
				},
				effects = { Smarts = 10, Health = -8 },
			},
			{
				text = "Study then get some sleep",
				feedback = {
					"Balance is key. You study hard then rest.",
					"Your brain needs sleep to consolidate memories.",
					"Smart approach to test prep!",
				},
				effects = { Smarts = 7 },
			},
			{
				text = "Give up and hope for the best",
				feedback = {
					"Whatever happens, happens. You go to bed.",
					"Maybe you'll remember more than you think?",
					"Good luck tomorrow...",
				},
				effects = { Smarts = 2, Happiness = -3 },
			},
		},
	},
	-- Event 3: Tutoring
	{
		id = "study_tutor",
		title = "👨‍🏫 Getting Tutored",
		texts = {
			"You've arranged for a tutoring session.",
			"Extra help with your studies could make the difference.",
			"The tutor sits down with you to go over the material.",
		},
		effects = { Smarts = {8, 15} },
		choices = {
			{
				text = "Ask lots of questions",
				feedback = {
					"No question is too dumb! You ask everything.",
					"The tutor appreciates your enthusiasm.",
					"Understanding grows with each answer.",
				},
				effects = { Smarts = 15 },
			},
			{
				text = "Focus on weakest areas",
				feedback = {
					"You tackle the topics you struggle with most.",
					"Targeted practice improves your weak spots.",
					"Your understanding deepens significantly.",
				},
				effects = { Smarts = 12 },
			},
			{
				text = "Zone out occasionally",
				feedback = {
					"You're here but not fully present.",
					"Some information gets through at least.",
					"Could have been more productive.",
				},
				effects = { Smarts = 6 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLASS EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.ClassEvent = {
	-- Event 1: Called on in class
	{
		id = "class_called_on",
		title = "✋ Called On In Class",
		texts = {
			"The teacher calls your name. Everyone looks at you.",
			"'Can you answer this question?' the teacher asks, looking at you.",
			"Suddenly all eyes in the classroom are on you.",
		},
		effects = { Smarts = {-3, 8}, Happiness = {-5, 5} },
		choices = {
			{
				text = "Answer confidently (you know it)",
				feedback = {
					"'The answer is...' You nail it perfectly!",
					"The teacher nods approvingly. Well done!",
					"Your classmates look impressed.",
				},
				effects = { Smarts = 5, Happiness = 8 },
			},
			{
				text = "Take a guess",
				feedback = {
					"You're not sure, but you give it a shot!",
					"Sometimes you guess right, sometimes you don't.",
					"At least you tried!",
				},
				effects = { Smarts = 3, Happiness = 2 },
			},
			{
				text = "Admit you don't know",
				feedback = {
					"'I'm not sure, sorry.' Honest at least.",
					"The teacher moves on to someone else.",
					"Better than making up a wrong answer.",
				},
				effects = { Happiness = -3 },
			},
			{
				text = "Make a joke instead",
				feedback = {
					"Your witty response gets laughs from classmates!",
					"The teacher is less amused but moves on.",
					"Class clown status confirmed.",
				},
				effects = { Happiness = 5 },
			},
		},
	},
	-- Event 2: Pop quiz
	{
		id = "class_pop_quiz",
		title = "📝 Pop Quiz!",
		texts = {
			"'Clear your desks, pop quiz time!' the teacher announces.",
			"A surprise quiz catches everyone off guard!",
			"No warning, no prep time. This is a true test of knowledge!",
		},
		effects = { Smarts = {-5, 10}, Happiness = {-8, 5} },
		choices = {
			{
				text = "You actually studied!",
				feedback = {
					"All that studying pays off! You know this material!",
					"You breeze through the questions confidently.",
					"Preparation meets opportunity!",
				},
				effects = { Smarts = 10, Happiness = 8 },
			},
			{
				text = "Do your best",
				feedback = {
					"You recall what you can and hope for the best.",
					"Some questions are easy, some are tough.",
					"A solid effort under pressure.",
				},
				effects = { Smarts = 5, Happiness = 2 },
			},
			{
				text = "Panic and guess everything",
				feedback = {
					"Your mind goes blank! Random guessing it is!",
					"Statistically, you might get some right?",
					"Next time, maybe review the material...",
				},
				effects = { Smarts = -5, Happiness = -5 },
			},
		},
	},
	-- Event 3: Interesting lesson
	{
		id = "class_interesting",
		title = "🌟 Fascinating Lesson",
		texts = {
			"Today's lesson is actually really interesting!",
			"The teacher makes the subject come alive!",
			"You find yourself genuinely engaged with the material.",
		},
		effects = { Smarts = {5, 12}, Happiness = {3, 8} },
		choices = {
			{
				text = "Take detailed notes",
				feedback = {
					"You write down everything important!",
					"These notes will be valuable later.",
					"Engaged learning is the best learning!",
				},
				effects = { Smarts = 12, Happiness = 5 },
			},
			{
				text = "Ask to learn more",
				feedback = {
					"Your curiosity impresses the teacher!",
					"They recommend additional resources.",
					"Learning beyond the curriculum is rewarding.",
				},
				effects = { Smarts = 15, Happiness = 8 },
			},
			{
				text = "Just enjoy the lecture",
				feedback = {
					"You sit back and absorb the knowledge.",
					"Not everything needs to be written down.",
					"A pleasant learning experience!",
				},
				effects = { Smarts = 8, Happiness = 6 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- EXAM EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.ExamEvent = {
	-- Event 1: Big exam
	{
		id = "exam_big",
		title = "📊 Important Exam",
		texts = {
			"It's the day of the big exam. Your future depends on this!",
			"Months of studying have led to this moment.",
			"You enter the exam room with your heart pounding.",
		},
		effects = { Smarts = {-5, 15}, Happiness = {-10, 10} },
		choices = {
			{
				text = "Stay calm and focused",
				feedback = {
					"Deep breaths. You've got this!",
					"Your preparation shows as you work through questions.",
					"Calm confidence leads to success!",
				},
				effects = { Smarts = 15, Happiness = 10 },
			},
			{
				text = "Rush through quickly",
				feedback = {
					"Fast but sloppy. You finish early though!",
					"Maybe you should have double-checked...",
					"Speed isn't everything on exams.",
				},
				effects = { Smarts = 8, Happiness = 3 },
			},
			{
				text = "Overthink every question",
				feedback = {
					"Second-guessing makes everything harder.",
					"Time runs out before you finish!",
					"Analysis paralysis is real.",
				},
				effects = { Smarts = 5, Happiness = -8 },
			},
		},
	},
	-- Event 2: Exam results
	{
		id = "exam_results",
		title = "📄 Exam Results",
		texts = {
			"The teacher hands back the graded exams.",
			"Your exam results are in. Time to see how you did!",
			"Heart racing, you flip over your test paper...",
		},
		effects = { Happiness = {-15, 20} },
		choices = {
			{
				text = "Check your grade",
				feedback = {
					"You look at the score... whatever it is, you learned from this.",
					"Grades don't define you, but they do open doors.",
					"Time to move forward, whatever the result.",
				},
				effects = {},
			},
		},
	},
	-- Event 3: Final exams
	{
		id = "exam_finals",
		title = "🎓 Final Exams Week",
		texts = {
			"Finals week has arrived. Multiple exams ahead!",
			"The most stressful week of the semester is here.",
			"Everything you've learned this semester is on the line.",
		},
		effects = { Smarts = {5, 20}, Happiness = {-15, 5}, Health = {-10, 0} },
		choices = {
			{
				text = "Study strategically",
				feedback = {
					"You prioritize subjects and manage your time well.",
					"Strategic studying maximizes your results.",
					"Work smarter, not just harder!",
				},
				effects = { Smarts = 20, Happiness = 3 },
			},
			{
				text = "Cram everything last minute",
				feedback = {
					"Sleep? What's that? You cram non-stop!",
					"Your brain is stuffed with information.",
					"Exhausting but maybe effective?",
				},
				effects = { Smarts = 15, Health = -10, Happiness = -8 },
			},
			{
				text = "Balance study with self-care",
				feedback = {
					"You study hard but also take breaks.",
					"A healthy approach to exam stress.",
					"Your body and mind will thank you.",
				},
				effects = { Smarts = 12, Happiness = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLUB ACTIVITY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.ClubActivity = {
	-- Event 1: Join a club
	{
		id = "club_join",
		title = "🎭 Joining a Club",
		texts = {
			"There's a club fair at school. Time to find your people!",
			"Extracurricular activities look great on applications!",
			"What club should you join?",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{
				text = "Drama club",
				feedback = {
					"The stage calls to you! Theater kid life begins!",
					"You discover a passion for performance.",
					"Drama club becomes your second family.",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Science club",
				feedback = {
					"Experiments and discoveries await!",
					"Your inner scientist is unleashed!",
					"Science club is surprisingly fun.",
				},
				effects = { Smarts = 10, Happiness = 8 },
			},
			{
				text = "Debate team",
				feedback = {
					"Time to argue professionally!",
					"Your persuasion skills will grow immensely.",
					"Debate sharpens your mind and voice.",
				},
				effects = { Smarts = 12, Happiness = 8 },
			},
			{
				text = "Art club",
				feedback = {
					"Express yourself through creativity!",
					"Art is therapy and self-expression.",
					"Your artistic side flourishes!",
				},
				effects = { Happiness = 15 },
			},
		},
	},
	-- Event 2: Club competition
	{
		id = "club_competition",
		title = "🏆 Club Competition",
		texts = {
			"Your club is competing against other schools!",
			"It's time to show what your club can do!",
			"Weeks of practice lead to this moment.",
		},
		effects = { Happiness = {-5, 20}, Smarts = {3, 10} },
		choices = {
			{
				text = "Give it your all",
				feedback = {
					"You perform at your absolute best!",
					"Win or lose, you're proud of your effort.",
					"Competition brings out your best!",
				},
				effects = { Happiness = 15, Smarts = 8 },
			},
			{
				text = "Support your teammates",
				feedback = {
					"You cheer on your clubmates enthusiastically!",
					"Team spirit is what it's all about.",
					"Together you're stronger!",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Let nerves get to you",
				feedback = {
					"Performance anxiety strikes! You're off your game.",
					"It's a learning experience at least.",
					"Next time will be better.",
				},
				effects = { Happiness = -5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SPORTS TEAM EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.SportsTeam = {
	-- Event 1: Tryouts
	{
		-- CRITICAL FIX: Renamed to school_sports_tryouts for unique ID
		id = "school_sports_tryouts",
		title = "🏃 Sports Tryouts",
		texts = {
			"Today is the day of sports tryouts!",
			"Time to show the coach what you've got!",
			"Making the team would be amazing!",
		},
		effects = { Health = {5, 10}, Happiness = {-5, 15} },
		choices = {
			{
				text = "Give 110%",
				feedback = {
					"You push yourself to the absolute limit!",
					"The coach notices your dedication.",
					"Whether you make it or not, you gave everything.",
				},
				effects = { Health = 10, Happiness = 15 },
			},
			{
				text = "Show off your skills",
				feedback = {
					"You demonstrate your best moves!",
					"Flashy but effective. The team needs players like you.",
					"Confidence is key!",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Focus on teamwork",
				feedback = {
					"You show how well you work with others.",
					"Coaches love team players!",
					"Sports aren't just about individual talent.",
				},
				effects = { Happiness = 10 },
			},
		},
	},
	-- Event 2: Big game
	{
		-- CRITICAL FIX: Renamed to school_sports_game for unique ID
		id = "school_sports_game",
		title = "🏆 The Big Game",
		texts = {
			"It's game day! The whole school is watching!",
			"The championship game is today!",
			"Everything has led to this moment!",
		},
		effects = { Health = {5, 15}, Happiness = {-10, 25} },
		choices = {
			{
				text = "Be the MVP",
				feedback = {
					"You're on fire! Making plays left and right!",
					"The crowd chants your name!",
					"This is your moment to shine!",
				},
				effects = { Health = 10, Happiness = 25 },
			},
			{
				text = "Support the team",
				feedback = {
					"You do your job and help the team succeed.",
					"Not every hero needs the spotlight.",
					"Team victory is what matters!",
				},
				effects = { Health = 8, Happiness = 18 },
			},
			{
				text = "Choke under pressure",
				feedback = {
					"The pressure gets to you. Not your best game.",
					"Everyone has off days. You'll bounce back.",
					"Use this as motivation to improve.",
				},
				effects = { Happiness = -10 },
			},
		},
	},
	-- Event 3: Practice
	{
		-- CRITICAL FIX: Renamed to school_sports_practice for unique ID
		id = "school_sports_practice",
		title = "💪 Team Practice",
		texts = {
			"Practice makes perfect! Time to train!",
			"The coach runs you through drills.",
			"Another day of hard work at practice.",
		},
		effects = { Health = {5, 12} },
		choices = {
			{
				text = "Train hard",
				feedback = {
					"You push through the pain and get stronger!",
					"No shortcuts to greatness!",
					"Your skills improve noticeably.",
				},
				effects = { Health = 12 },
			},
			{
				text = "Focus on technique",
				feedback = {
					"Quality over quantity. You refine your form.",
					"Proper technique prevents injury and improves performance.",
					"Smart training pays off.",
				},
				effects = { Health = 10, Smarts = 3 },
			},
			{
				text = "Coast through practice",
				feedback = {
					"You put in minimum effort today.",
					"The coach notices. Not impressed.",
					"You get out what you put in.",
				},
				effects = { Health = 3 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SOCIAL EVENT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.SocialEvent = {
	-- Event 1: School dance
	{
		id = "social_dance",
		title = "💃 School Dance",
		texts = {
			"The school dance is tonight!",
			"The gym is decorated and the music is pumping!",
			"Time to dance the night away!",
		},
		effects = { Happiness = {10, 25} },
		choices = {
			{
				text = "Dance your heart out",
				feedback = {
					"You hit the dance floor and have a blast!",
					"Who cares what you look like? You're having fun!",
					"Best night ever!",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Hang with friends",
				feedback = {
					"You stick with your crew and have a good time.",
					"Taking photos and making memories!",
					"Friends make everything better.",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Ask someone to dance",
				feedback = {
					"Heart pounding, you ask your crush to dance!",
					"They say yes! This is amazing!",
					"A magical moment you'll never forget.",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Stand by the wall awkwardly",
				feedback = {
					"You watch others have fun from the sidelines.",
					"Social events are tough sometimes.",
					"At least the snacks are good?",
				},
				effects = { Happiness = 5 },
			},
		},
	},
	-- Event 2: Pep rally
	{
		id = "social_pep_rally",
		title = "📣 Pep Rally",
		texts = {
			"The whole school gathers for the pep rally!",
			"School spirit is at an all-time high!",
			"Cheerleaders, music, and excitement fill the gym!",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{
				text = "Cheer loudly",
				feedback = {
					"You scream until you're hoarse! GO TEAM!",
					"School spirit is contagious!",
					"What a rush!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Enjoy the show",
				feedback = {
					"The performances are actually pretty entertaining!",
					"Nice break from classes.",
					"School events can be fun!",
				},
				effects = { Happiness = 10 },
			},
			{
				text = "Use it as free time",
				feedback = {
					"You zone out and think about other things.",
					"Not super engaged but whatever.",
					"A break is a break.",
				},
				effects = { Happiness = 5 },
			},
		},
	},
	-- Event 3: Field trip
	{
		id = "social_field_trip",
		title = "🚌 School Field Trip",
		texts = {
			"Field trip day! No regular classes!",
			"The bus takes your class somewhere exciting!",
			"Learning outside the classroom is the best!",
		},
		effects = { Happiness = {10, 20}, Smarts = {3, 8} },
		choices = {
			{
				text = "Actually learn something",
				feedback = {
					"You pay attention and absorb knowledge!",
					"The educational part is genuinely interesting!",
					"Field trips are learning adventures!",
				},
				effects = { Happiness = 15, Smarts = 10 },
			},
			{
				text = "Goof off with friends",
				feedback = {
					"The learning is secondary to the fun!",
					"You and your friends have a blast!",
					"Memories made!",
				},
				effects = { Happiness = 20 },
			},
			{
				text = "Get the perfect photo",
				feedback = {
					"Social media needs to know you were here!",
					"The 'gram is blessed with your content.",
					"Aesthetic!",
				},
				effects = { Happiness = 12 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- TEACHER INTERACTION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.TeacherInteraction = {
	-- Event 1: Teacher's pet
	{
		id = "teacher_favorite",
		title = "⭐ Teacher Notices You",
		texts = {
			"Your teacher pulls you aside after class.",
			"'I've noticed your hard work,' the teacher says.",
			"It seems like you're a teacher favorite!",
		},
		effects = { Happiness = {8, 15}, Smarts = {3, 8} },
		choices = {
			{
				text = "Accept the praise humbly",
				feedback = {
					"'Thank you, I really try!' you say.",
					"Humility is a virtue.",
					"The teacher respects your attitude.",
				},
				effects = { Happiness = 12, Smarts = 5 },
			},
			{
				text = "Ask for extra challenges",
				feedback = {
					"You want to push yourself even further!",
					"The teacher loves your ambition.",
					"Advanced work coming your way!",
				},
				effects = { Smarts = 12, Happiness = 8 },
			},
			{
				text = "Downplay your effort",
				feedback = {
					"'It's nothing, really,' you shrug.",
					"False modesty doesn't help anyone.",
					"The teacher seems slightly disappointed.",
				},
				effects = { Happiness = 5 },
			},
		},
	},
	-- Event 2: Asking for help
	{
		id = "teacher_help",
		title = "🙋 Asking the Teacher",
		texts = {
			"You don't understand something. Time to ask for help.",
			"After class, you approach the teacher with questions.",
			"The teacher seems happy you want to learn more.",
		},
		effects = { Smarts = {5, 12} },
		choices = {
			{
				text = "Ask detailed questions",
				feedback = {
					"Your specific questions get specific answers!",
					"The teacher walks you through everything.",
					"Understanding achieved!",
				},
				effects = { Smarts = 12 },
			},
			{
				text = "Ask for general guidance",
				feedback = {
					"The teacher points you in the right direction.",
					"Now you know where to focus your studying.",
					"Helpful advice received!",
				},
				effects = { Smarts = 8 },
			},
			{
				text = "Get too intimidated to ask",
				feedback = {
					"You chicken out at the last second.",
					"The question remains unanswered.",
					"Maybe next time...",
				},
				effects = { Smarts = 2 },
			},
		},
	},
	-- Event 3: Recommendation letter
	{
		id = "teacher_recommendation",
		title = "📝 Recommendation Letter",
		texts = {
			"You need a teacher to write you a recommendation.",
			"College applications require references from educators.",
			"Which teacher should you ask?",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{
				text = "Ask your favorite teacher",
				feedback = {
					"They know you best and are happy to help!",
					"A glowing recommendation is written.",
					"Having good relationships pays off!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Ask the teacher of your best subject",
				feedback = {
					"They can speak to your academic strengths!",
					"A factual, impressive recommendation.",
					"Your grades speak for themselves!",
				},
				effects = { Happiness = 12 },
			},
			{
				text = "Ask the most prestigious teacher",
				feedback = {
					"Their name carries weight!",
					"It might be a more generic letter though...",
					"Prestige vs. personal connection.",
				},
				effects = { Happiness = 8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PEER INTERACTION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.PeerInteraction = {
	-- Event 1: Making friends
	{
		id = "peer_friends",
		title = "👋 Making New Friends",
		texts = {
			"Someone new sits next to you in class.",
			"You notice someone eating lunch alone.",
			"There's a new student at school today.",
		},
		effects = { Happiness = {5, 15} },
		choices = {
			{
				text = "Introduce yourself",
				feedback = {
					"'Hi, I'm [name]! Nice to meet you!'",
					"They seem happy to make a new friend!",
					"A new friendship begins!",
				},
				effects = { Happiness = 15 },
			},
			{
				text = "Invite them to hang out",
				feedback = {
					"'Want to sit with us at lunch?'",
					"Being inclusive feels good!",
					"You've made someone's day better.",
				},
				effects = { Happiness = 18 },
			},
			{
				text = "Stay in your bubble",
				feedback = {
					"You stick with your existing friends.",
					"Safe but you miss an opportunity.",
					"Maybe another time.",
				},
				effects = { Happiness = 3 },
			},
		},
	},
	-- Event 2: Dealing with a bully
	{
		id = "peer_bully",
		title = "😠 Facing a Bully",
		texts = {
			"Someone is giving you a hard time at school.",
			"A bully targets you in the hallway.",
			"Cruel words are thrown your way by a classmate.",
		},
		effects = { Happiness = {-15, 5} },
		choices = {
			{
				text = "Stand up for yourself",
				feedback = {
					"You face them with confidence.",
					"Bullies often back down when confronted.",
					"You feel stronger for standing your ground.",
				},
				effects = { Happiness = 5 },
			},
			{
				text = "Report to a teacher",
				feedback = {
					"Adults should handle this. You report them.",
					"The school takes action against bullying.",
					"You did the right thing.",
				},
				effects = { Happiness = 3 },
			},
			{
				text = "Walk away",
				feedback = {
					"You're better than them. You don't engage.",
					"Sometimes not reacting is the best response.",
					"You keep your dignity intact.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Fight back",
				feedback = {
					"You've had enough! Fists fly!",
					"Both of you end up in trouble.",
					"Violence isn't the answer, but...",
				},
				effects = { Happiness = -10 },
				triggersCombat = true,
			},
		},
	},
	-- Event 3: Group project
	{
		id = "peer_group_project",
		title = "👥 Group Project",
		texts = {
			"Your teacher assigns a group project.",
			"Time to work with classmates on an assignment.",
			"Collaboration is key to this project's success.",
		},
		effects = { Smarts = {3, 10}, Happiness = {-5, 10} },
		choices = {
			{
				text = "Take the lead",
				feedback = {
					"You organize the group and delegate tasks.",
					"Leadership skills developing!",
					"The project runs smoothly under your guidance.",
				},
				effects = { Smarts = 10, Happiness = 8 },
			},
			{
				text = "Do your fair share",
				feedback = {
					"You complete your part reliably.",
					"Being dependable is valuable.",
					"Good teamwork from everyone!",
				},
				effects = { Smarts = 8, Happiness = 5 },
			},
			{
				text = "Let others carry you",
				feedback = {
					"You do the bare minimum...",
					"Your group members notice.",
					"Not cool, but you got through it.",
				},
				effects = { Smarts = 3, Happiness = -5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DETENTION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.Detention = {
	-- Event 1: Getting detention
	{
		id = "detention_get",
		title = "😬 You Got Detention!",
		texts = {
			"'Detention. After school. Don't be late.' says the teacher.",
			"Your behavior has earned you time in detention.",
			"Looks like you're staying after school today.",
		},
		effects = { Happiness = {-15, -5} },
		choices = {
			{
				text = "Accept it quietly",
				feedback = {
					"You did the crime, you'll do the time.",
					"No point arguing. Just get through it.",
					"Lesson learned... maybe.",
				},
				effects = { Happiness = -8 },
			},
			{
				text = "Try to argue out of it",
				feedback = {
					"'But that's not fair!' Arguing makes it worse.",
					"Now you have extra detention. Great job.",
					"Know when to quit.",
				},
				effects = { Happiness = -15 },
			},
			{
				text = "Own what you did",
				feedback = {
					"'You're right, I was wrong. I'll be there.'",
					"Taking responsibility impresses the teacher.",
					"Maturity points earned.",
				},
				effects = { Happiness = -5 },
			},
		},
	},
	-- Event 2: In detention
	{
		id = "detention_during",
		title = "⏰ Serving Detention",
		texts = {
			"You sit in the detention room, clock ticking slowly.",
			"An hour of your life you'll never get back.",
			"The detention supervisor watches everyone like a hawk.",
		},
		effects = { Happiness = {-10, 0} },
		choices = {
			{
				text = "Do homework",
				feedback = {
					"Might as well be productive!",
					"At least you're getting stuff done.",
					"Making lemonade out of lemons.",
				},
				effects = { Smarts = 5, Happiness = -3 },
			},
			{
				text = "Reflect on your choices",
				feedback = {
					"Why are you here? What led to this?",
					"Self-reflection is healthy.",
					"Maybe you'll make better choices next time.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Stare at the clock",
				feedback = {
					"Time moves so slowly when you're miserable.",
					"Each minute feels like an hour.",
					"Finally, it's over.",
				},
				effects = { Happiness = -8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- GRADUATION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.Graduation = {
	-- Event 1: Graduation ceremony
	{
		id = "graduation_ceremony",
		title = "🎓 Graduation Day!",
		texts = {
			"You did it! Graduation day is finally here!",
			"The cap and gown feel surreal. You're actually graduating!",
			"Years of hard work have led to this moment!",
		},
		effects = { Happiness = {20, 40}, Smarts = {5, 10} },
		choices = {
			{
				text = "Celebrate with pride",
				feedback = {
					"You throw your cap in the air with joy!",
					"All those late nights studying paid off!",
					"You are officially a graduate!",
				},
				effects = { Happiness = 40, Smarts = 10 },
			},
			{
				text = "Thank your teachers",
				feedback = {
					"You find your favorite teachers to say goodbye.",
					"They're proud of how far you've come.",
					"Gratitude is a beautiful thing.",
				},
				effects = { Happiness = 35 },
			},
			{
				text = "Savor the moment",
				feedback = {
					"You take it all in - the ceremony, the people, the feeling.",
					"This is a once-in-a-lifetime moment.",
					"Memories to last forever.",
				},
				effects = { Happiness = 38 },
			},
		},
	},
	-- Event 2: Graduation party
	{
		id = "graduation_party",
		title = "🎉 Graduation Party!",
		texts = {
			"Time to celebrate your graduation properly!",
			"Friends and family gather to congratulate you!",
			"The party is in full swing!",
		},
		effects = { Happiness = {15, 30} },
		choices = {
			{
				text = "Party all night",
				feedback = {
					"This is your night! You earned it!",
					"Dancing, laughing, celebrating life!",
					"Best. Night. Ever!",
				},
				effects = { Happiness = 30 },
			},
			{
				text = "Give a thank-you speech",
				feedback = {
					"You thank everyone who helped you succeed.",
					"Heartfelt words bring tears to some eyes.",
					"A moment of gratitude amidst celebration.",
				},
				effects = { Happiness = 25 },
			},
			{
				text = "Take tons of photos",
				feedback = {
					"These memories need to be documented!",
					"Your camera roll is full of smiling faces.",
					"Photos to look back on forever!",
				},
				effects = { Happiness = 22 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
SchoolEvents.ActivityMapping = {
	["study"] = "StudyHard",
	["study_hard"] = "StudyHard",
	["homework"] = "StudyHard",
	["class"] = "ClassEvent",
	["attend_class"] = "ClassEvent",
	["lesson"] = "ClassEvent",
	["exam"] = "ExamEvent",
	["test"] = "ExamEvent",
	["finals"] = "ExamEvent",
	["club"] = "ClubActivity",
	["join_club"] = "ClubActivity",
	["extracurricular"] = "ClubActivity",
	["sports"] = "SportsTeam",
	["team"] = "SportsTeam",
	["tryout"] = "SportsTeam",
	["dance"] = "SocialEvent",
	["pep_rally"] = "SocialEvent",
	["field_trip"] = "SocialEvent",
	["teacher"] = "TeacherInteraction",
	["ask_teacher"] = "TeacherInteraction",
	["classmate"] = "PeerInteraction",
	["friend"] = "PeerInteraction",
	["project"] = "PeerInteraction",
	["detention"] = "Detention",
	["trouble"] = "Detention",
	["graduate"] = "Graduation",
	["graduation"] = "Graduation",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
function SchoolEvents.getEventForActivity(activityId)
	local categoryName = SchoolEvents.ActivityMapping[activityId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(SchoolEvents.ActivityMapping) do
			if string.find(activityId, key) or string.find(key, activityId) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		return nil
	end
	
	local eventList = SchoolEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil
	end
	
	-- Return random event from category
	return eventList[math.random(1, #eventList)]
end

function SchoolEvents.getAllCategories()
	return {"StudyHard", "ClassEvent", "ExamEvent", "ClubActivity", "SportsTeam", "SocialEvent", "TeacherInteraction", "PeerInteraction", "Detention", "Graduation"}
end

return SchoolEvents
