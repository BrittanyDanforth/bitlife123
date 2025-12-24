--[[
	MedicalActivityEvents.lua
	=========================
	Comprehensive event templates for medical and healthcare activities.
	These events give players immersive BitLife-style event cards for all
	healthcare-related interactions.
	
	Categories:
	- DoctorVisit: General checkups and appointments
	- Therapy: Mental health sessions
	- PlasticSurgery: Cosmetic procedures
	- Dentist: Dental care
	- Emergency: Emergency room visits
	- Specialist: Specialist appointments
	- Fitness: Health consultations
	- AlternativeMedicine: Non-traditional treatments
--]]

local MedicalEvents = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DOCTOR VISIT EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
MedicalEvents.DoctorVisit = {
	-- Event 1: Annual checkup
	{
		id = "doctor_checkup",
		title = "🩺 Annual Checkup",
		texts = {
			"Time for your yearly physical examination.",
			"The doctor calls you in for your checkup.",
			"Regular health screenings are important!",
			"The waiting room is full, but soon you're called in.",
		},
		effects = { Health = {5, 15}, Happiness = {-3, 5} },
		cost = 100,
		choices = {
			{
				text = "Get a full workup",
				feedback = {
					"The doctor runs comprehensive tests.",
					"Better to know everything about your health!",
					"You're being proactive about your wellbeing.",
				},
				effects = { Health = 15, Happiness = 5 },
				cost = 200,
			},
			{
				text = "Just the basics",
				feedback = {
					"A quick check of vitals and general health.",
					"Everything seems fine!",
					"A clean bill of health (probably).",
				},
				effects = { Health = 10 },
			},
			{
				text = "Ask about concerns",
				feedback = {
					"You bring up things that have been worrying you.",
					"The doctor addresses your concerns.",
					"Knowledge is power when it comes to health.",
				},
				effects = { Health = 12, Happiness = 5, Smarts = 3 },
			},
		},
	},
	-- Event 2: Good news
	{
		id = "doctor_good_news",
		title = "✅ Good Health News!",
		texts = {
			"The doctor reviews your results with a smile.",
			"'I have good news,' the doctor begins.",
			"Your test results are in!",
		},
		effects = { Health = {10, 20}, Happiness = {15, 25} },
		choices = {
			{
				text = "Feel relieved",
				feedback = {
					"A wave of relief washes over you!",
					"You're healthy! Time to celebrate!",
					"All that worrying was for nothing!",
				},
				effects = { Happiness = 25, Health = 15 },
			},
			{
				text = "Commit to staying healthy",
				feedback = {
					"This motivates you to keep up the good work!",
					"Your healthy habits are paying off!",
					"Keep doing what you're doing!",
				},
				effects = { Happiness = 20, Health = 20 },
			},
			{
				text = "Ask what you can improve",
				feedback = {
					"The doctor gives you tips for even better health.",
					"There's always room for improvement!",
					"Optimizing your health journey!",
				},
				effects = { Happiness = 18, Health = 18, Smarts = 5 },
			},
		},
	},
	-- Event 3: Minor issue
	{
		id = "doctor_minor_issue",
		title = "⚠️ Minor Health Issue",
		texts = {
			"The doctor found something that needs attention.",
			"'It's not serious, but...' the doctor begins.",
			"A small health concern was discovered.",
		},
		effects = { Health = {-5, 5}, Happiness = {-10, 0} },
		choices = {
			{
				text = "Follow treatment plan",
				feedback = {
					"You commit to following doctor's orders.",
					"With proper care, this will clear up.",
					"Taking charge of your health!",
				},
				effects = { Health = 10, Happiness = -3 },
			},
			{
				text = "Ask lots of questions",
				feedback = {
					"You want to understand everything.",
					"The doctor explains the condition thoroughly.",
					"Informed patients have better outcomes!",
				},
				effects = { Health = 5, Smarts = 8, Happiness = -5 },
			},
			{
				text = "Worry about it",
				feedback = {
					"You can't help but stress about this.",
					"Worrying doesn't help, but emotions happen.",
					"Try to stay positive.",
				},
				effects = { Health = -5, Happiness = -10 },
			},
		},
	},
	-- Event 4: Vaccination
	{
		id = "doctor_vaccine",
		title = "💉 Vaccination Time",
		texts = {
			"The doctor recommends getting vaccinated.",
			"Time for your shots!",
			"Prevention is better than cure!",
		},
		effects = { Health = {8, 15} },
		cost = 50,
		choices = {
			{
				text = "Get vaccinated",
				feedback = {
					"A small pinch, and you're protected!",
					"Your immune system thanks you!",
					"Doing your part for public health!",
				},
				effects = { Health = 15 },
			},
			{
				text = "Ask about side effects",
				feedback = {
					"The doctor explains what to expect.",
					"Minor side effects are normal.",
					"You get the shot after the explanation.",
				},
				effects = { Health = 15, Smarts = 3 },
			},
			{
				text = "Schedule for later",
				feedback = {
					"You're not ready today.",
					"Hopefully you'll follow through.",
					"Prevention delayed...",
				},
				effects = { Health = -3 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- THERAPY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
MedicalEvents.Therapy = {
	-- Event 1: First session
	{
		id = "therapy_first",
		title = "🧠 First Therapy Session",
		texts = {
			"You walk into your first therapy appointment.",
			"The therapist's office is calm and welcoming.",
			"Taking the first step toward mental wellness.",
		},
		effects = { Happiness = {5, 15}, Health = {3, 8} },
		cost = 150,
		choices = {
			{
				text = "Open up completely",
				feedback = {
					"You share everything that's been weighing on you.",
					"The therapist listens without judgment.",
					"A weight lifts from your shoulders.",
				},
				effects = { Happiness = 20, Health = 10 },
			},
			{
				text = "Take it slow",
				feedback = {
					"You share some things but hold back others.",
					"Trust takes time to build. That's okay.",
					"A good start to the journey.",
				},
				effects = { Happiness = 12, Health = 5 },
			},
			{
				text = "Just listen to advice",
				feedback = {
					"The therapist shares some initial strategies.",
					"You take mental notes for later.",
					"Tools for your mental health toolkit.",
				},
				effects = { Happiness = 8, Smarts = 5 },
			},
		},
	},
	-- Event 2: Breakthrough
	{
		id = "therapy_breakthrough",
		title = "💡 Therapy Breakthrough!",
		texts = {
			"Something clicks during today's session!",
			"You have a major realization about yourself.",
			"The pieces finally fall into place.",
		},
		effects = { Happiness = {15, 30}, Health = {5, 15} },
		cost = 150,
		choices = {
			{
				text = "Embrace the insight",
				feedback = {
					"This changes everything!",
					"Understanding yourself is powerful.",
					"Growth is happening!",
				},
				effects = { Happiness = 30, Health = 15, Smarts = 5 },
			},
			{
				text = "Work through the emotions",
				feedback = {
					"Breakthroughs can be emotional.",
					"The therapist helps you process.",
					"Healing isn't always comfortable.",
				},
				effects = { Happiness = 20, Health = 12 },
			},
			{
				text = "Make a plan to change",
				feedback = {
					"Now that you understand, you can act.",
					"Actionable steps toward improvement!",
					"Insight becomes action!",
				},
				effects = { Happiness = 25, Health = 10, Smarts = 8 },
			},
		},
	},
	-- Event 3: Regular session
	{
		id = "therapy_regular",
		title = "🛋️ Therapy Session",
		texts = {
			"Another productive therapy session.",
			"You settle into the familiar office.",
			"Consistent work on mental health.",
		},
		effects = { Happiness = {8, 15}, Health = {5, 10} },
		cost = 150,
		choices = {
			{
				text = "Discuss recent struggles",
				feedback = {
					"You work through what's been hard lately.",
					"The therapist offers helpful perspectives.",
					"Processing difficult emotions.",
				},
				effects = { Happiness = 12, Health = 8 },
			},
			{
				text = "Celebrate progress",
				feedback = {
					"You reflect on how far you've come!",
					"Growth is worth acknowledging!",
					"Pride in your mental health journey!",
				},
				effects = { Happiness = 18, Health = 10 },
			},
			{
				text = "Learn new coping strategies",
				feedback = {
					"The therapist teaches new techniques.",
					"More tools for managing life!",
					"Knowledge for better mental health!",
				},
				effects = { Happiness = 10, Smarts = 8, Health = 5 },
			},
		},
	},
	-- Event 4: Group therapy
	{
		id = "therapy_group",
		title = "👥 Group Therapy Session",
		texts = {
			"You attend a group therapy session.",
			"Others share similar struggles to yours.",
			"Healing in community.",
		},
		effects = { Happiness = {5, 18}, Health = {3, 10} },
		cost = 75,
		choices = {
			{
				text = "Share your story",
				feedback = {
					"You open up to the group.",
					"Others relate and offer support.",
					"Connection through shared experience.",
				},
				effects = { Happiness = 18, Health = 10 },
			},
			{
				text = "Listen and support others",
				feedback = {
					"You're there for your fellow group members.",
					"Helping others helps yourself too.",
					"The power of community.",
				},
				effects = { Happiness = 15, Health = 8 },
			},
			{
				text = "Observe quietly",
				feedback = {
					"You take it all in without speaking.",
					"Sometimes listening is enough.",
					"Still benefiting from being there.",
				},
				effects = { Happiness = 8, Health = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- PLASTIC SURGERY EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
MedicalEvents.PlasticSurgery = {
	-- Event 1: Consultation
	{
		id = "plastic_consult",
		title = "💄 Cosmetic Consultation",
		texts = {
			"You meet with a plastic surgeon for a consultation.",
			"Time to discuss your cosmetic options.",
			"The surgeon shows you what's possible.",
		},
		effects = { Happiness = {0, 10} },
		cost = 200,
		choices = {
			{
				text = "Book the procedure",
				feedback = {
					"You decide to go through with it!",
					"Surgery date is set!",
					"A change is coming!",
				},
				effects = { Happiness = 10 },
			},
			{
				text = "Think about it more",
				feedback = {
					"This is a big decision. No rush.",
					"You'll decide when you're ready.",
					"Taking time is smart.",
				},
				effects = { Happiness = 5 },
			},
			{
				text = "Decide against it",
				feedback = {
					"You're beautiful the way you are.",
					"Self-acceptance is powerful.",
					"Maybe it's not right for you.",
				},
				effects = { Happiness = 8 },
			},
		},
	},
	-- Event 2: Successful surgery
	{
		id = "plastic_success",
		title = "✨ Surgery Success!",
		texts = {
			"Your cosmetic procedure went perfectly!",
			"The results are exactly what you wanted!",
			"The surgeon did amazing work!",
		},
		effects = { Happiness = {20, 35}, Looks = {15, 25} },
		cost = 5000,
		choices = {
			{
				text = "Love the results",
				feedback = {
					"You look amazing! You feel amazing!",
					"This was worth it!",
					"Confidence boosted!",
				},
				effects = { Happiness = 35, Looks = 25 },
			},
			{
				text = "Show off to friends",
				feedback = {
					"Your friends notice the change!",
					"Compliments everywhere!",
					"New look, who dis?",
				},
				effects = { Happiness = 30, Looks = 20 },
			},
			{
				text = "Focus on recovery",
				feedback = {
					"Healing properly is important.",
					"Taking care of yourself post-surgery.",
					"The results will be even better once healed!",
				},
				effects = { Happiness = 22, Looks = 18, Health = 5 },
			},
		},
	},
	-- Event 3: Recovery
	{
		id = "plastic_recovery",
		title = "🩹 Recovery Time",
		texts = {
			"You're recovering from your procedure.",
			"The healing process takes time.",
			"Patience during recovery is key.",
		},
		effects = { Health = {-5, 5}, Happiness = {-5, 10} },
		choices = {
			{
				text = "Rest and heal properly",
				feedback = {
					"You follow all post-op instructions.",
					"Healing goes smoothly.",
					"Results are looking good!",
				},
				effects = { Health = 10, Happiness = 10 },
			},
			{
				text = "Get impatient",
				feedback = {
					"You wish you could fast-forward...",
					"Healing can't be rushed.",
					"Try to stay positive.",
				},
				effects = { Happiness = -5 },
			},
			{
				text = "Document the progress",
				feedback = {
					"You take photos as you heal.",
					"Watching the transformation is exciting!",
					"Soon you'll see the final results!",
				},
				effects = { Happiness = 8 },
			},
		},
	},
	-- Event 4: Botox/Minor procedure
	{
		id = "plastic_minor",
		title = "💉 Quick Touch-Up",
		texts = {
			"Time for a minor cosmetic procedure.",
			"Just a quick touch-up appointment.",
			"Maintenance for your look.",
		},
		effects = { Looks = {5, 12}, Happiness = {5, 15} },
		cost = 500,
		choices = {
			{
				text = "Get the treatment",
				feedback = {
					"Quick and easy! Looking refreshed!",
					"The results are subtle but noticeable.",
					"Refreshed and renewed!",
				},
				effects = { Looks = 12, Happiness = 15 },
			},
			{
				text = "Try something new",
				feedback = {
					"You opt for a different treatment!",
					"Experimenting with your look!",
					"Variety is the spice of life!",
				},
				effects = { Looks = 10, Happiness = 12 },
			},
			{
				text = "Skip it this time",
				feedback = {
					"Not today. Your natural look is fine.",
					"Saving money and embracing yourself.",
					"Maybe next time.",
				},
				effects = { Happiness = 5 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DENTIST EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
MedicalEvents.Dentist = {
	-- Event 1: Regular cleaning
	{
		id = "dentist_cleaning",
		title = "🦷 Dental Cleaning",
		texts = {
			"Time for your dental checkup and cleaning!",
			"The dentist's chair awaits.",
			"Taking care of your teeth!",
		},
		effects = { Health = {5, 12} },
		cost = 100,
		choices = {
			{
				text = "Full cleaning and exam",
				feedback = {
					"Your teeth are sparkling clean!",
					"No cavities found!",
					"Dental health is important!",
				},
				effects = { Health = 12, Happiness = 5 },
			},
			{
				text = "Get teeth whitened too",
				feedback = {
					"Your smile is brighter than ever!",
					"Pearly whites achieved!",
					"Confidence boost with every smile!",
				},
				effects = { Health = 10, Looks = 8, Happiness = 10 },
				cost = 200,
			},
			{
				text = "Just the basics",
				feedback = {
					"Quick clean and you're out!",
					"Good enough!",
					"Dental care: check!",
				},
				effects = { Health = 8 },
			},
		},
	},
	-- Event 2: Cavity found
	{
		id = "dentist_cavity",
		title = "😬 Cavity Found!",
		texts = {
			"The dentist found a cavity.",
			"'We need to fill this,' the dentist says.",
			"Not the news you wanted...",
		},
		effects = { Health = {-3, 5}, Happiness = {-10, -3} },
		cost = 200,
		choices = {
			{
				text = "Get it filled now",
				feedback = {
					"A little drilling and you're good as new!",
					"Problem solved!",
					"Better to fix it now!",
				},
				effects = { Health = 10, Happiness = -5 },
				cost = 150,
			},
			{
				text = "Schedule for later",
				feedback = {
					"You'll come back when you're ready.",
					"Don't wait too long!",
					"Procrastination might make it worse.",
				},
				effects = { Health = -5, Happiness = -8 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- EMERGENCY ROOM EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
MedicalEvents.Emergency = {
	-- Event 1: ER visit
	{
		id = "er_visit",
		title = "🚑 Emergency Room",
		texts = {
			"You're at the emergency room!",
			"Something happened that needed immediate care.",
			"The ER is busy but you need help.",
		},
		effects = { Health = {-20, 10}, Happiness = {-15, 0} },
		cost = 500,
		choices = {
			{
				text = "Get treated immediately",
				feedback = {
					"The medical team takes care of you.",
					"You're in good hands.",
					"Emergency handled!",
				},
				effects = { Health = 20, Happiness = -5 },
			},
			{
				text = "Wait your turn",
				feedback = {
					"The wait is long but eventually you're seen.",
					"Emergency rooms can be overwhelming.",
					"Finally getting care!",
				},
				effects = { Health = 15, Happiness = -10 },
			},
		},
	},
	-- Event 2: Quick recovery
	{
		id = "er_recovery",
		title = "🏥 Released from Hospital",
		texts = {
			"You're being discharged from the hospital!",
			"Recovery was successful!",
			"Time to go home and rest.",
		},
		effects = { Health = {10, 25}, Happiness = {10, 20} },
		choices = {
			{
				text = "Follow discharge instructions",
				feedback = {
					"You carefully follow the doctor's orders.",
					"Proper aftercare ensures full recovery.",
					"Taking care of yourself!",
				},
				effects = { Health = 25, Happiness = 15 },
			},
			{
				text = "Feel grateful to be okay",
				feedback = {
					"Health is precious. You appreciate it more now.",
					"A reminder to take care of yourself.",
					"Grateful for modern medicine!",
				},
				effects = { Health = 20, Happiness = 20 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ALTERNATIVE MEDICINE EVENTS
-- ═══════════════════════════════════════════════════════════════════════════════
MedicalEvents.Alternative = {
	-- Event 1: Acupuncture
	{
		id = "alt_acupuncture",
		title = "📍 Acupuncture Session",
		texts = {
			"You try acupuncture for wellness.",
			"Tiny needles, big relaxation?",
			"An ancient healing practice.",
		},
		effects = { Health = {5, 12}, Happiness = {5, 15} },
		cost = 100,
		choices = {
			{
				text = "Fully relax into it",
				feedback = {
					"You drift into deep relaxation!",
					"The tension melts away!",
					"Surprisingly effective!",
				},
				effects = { Health = 12, Happiness = 15 },
			},
			{
				text = "Focus on the experience",
				feedback = {
					"You're curious about how it works.",
					"An interesting experience!",
					"Different but interesting!",
				},
				effects = { Health = 10, Happiness = 10, Smarts = 3 },
			},
			{
				text = "Feel uncomfortable",
				feedback = {
					"Needles aren't for everyone.",
					"Maybe this isn't your thing.",
					"Not every treatment works for everyone.",
				},
				effects = { Health = 3, Happiness = -3 },
			},
		},
	},
	-- Event 2: Massage therapy
	{
		id = "alt_massage",
		title = "💆 Massage Therapy",
		texts = {
			"Time for a therapeutic massage!",
			"Your muscles need some attention.",
			"Relaxation through touch.",
		},
		effects = { Health = {8, 15}, Happiness = {10, 20} },
		cost = 80,
		choices = {
			{
				text = "Deep tissue massage",
				feedback = {
					"It hurts so good!",
					"Working out all those knots!",
					"You'll feel amazing tomorrow!",
				},
				effects = { Health = 15, Happiness = 12 },
			},
			{
				text = "Relaxation massage",
				feedback = {
					"Pure bliss and relaxation!",
					"Stress melts away!",
					"You almost fall asleep!",
				},
				effects = { Health = 10, Happiness = 20 },
			},
			{
				text = "Hot stone therapy",
				feedback = {
					"The warm stones are heavenly!",
					"Deep warmth and relaxation!",
					"A luxurious experience!",
				},
				effects = { Health = 12, Happiness = 18 },
			},
		},
	},
	-- Event 3: Chiropractic
	{
		id = "alt_chiro",
		title = "🦴 Chiropractor Visit",
		texts = {
			"Your back needs some adjustment.",
			"Time to see the chiropractor.",
			"Spinal alignment awaits!",
		},
		effects = { Health = {8, 15}, Happiness = {5, 12} },
		cost = 75,
		choices = {
			{
				text = "Full adjustment",
				feedback = {
					"CRACK! That felt good (and scary)!",
					"Your spine feels aligned!",
					"Standing taller!",
				},
				effects = { Health = 15, Happiness = 10 },
			},
			{
				text = "Gentle approach",
				feedback = {
					"A more subtle treatment.",
					"Less dramatic but still effective.",
					"Taking it easy on your spine.",
				},
				effects = { Health = 10, Happiness = 12 },
			},
		},
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAPPING TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
MedicalEvents.ActivityMapping = {
	["doctor"] = "DoctorVisit",
	["doctor_visit"] = "DoctorVisit",
	["checkup"] = "DoctorVisit",
	["physical"] = "DoctorVisit",
	["therapy"] = "Therapy",
	["therapist"] = "Therapy",
	["counseling"] = "Therapy",
	["mental_health"] = "Therapy",
	["plastic_surgery"] = "PlasticSurgery",
	["cosmetic"] = "PlasticSurgery",
	["botox"] = "PlasticSurgery",
	["dentist"] = "Dentist",
	["dental"] = "Dentist",
	["teeth"] = "Dentist",
	["emergency"] = "Emergency",
	["hospital"] = "Emergency",
	["er"] = "Emergency",
	["acupuncture"] = "Alternative",
	["massage"] = "Alternative",
	["chiropractic"] = "Alternative",
	["chiropractor"] = "Alternative",
	["alternative"] = "Alternative",
	["spa"] = "Alternative",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
function MedicalEvents.getEventForActivity(activityId)
	local categoryName = MedicalEvents.ActivityMapping[activityId]
	if not categoryName then
		-- Try partial matching
		for key, cat in pairs(MedicalEvents.ActivityMapping) do
			if string.find(activityId:lower(), key) or string.find(key, activityId:lower()) then
				categoryName = cat
				break
			end
		end
	end
	
	if not categoryName then
		return nil
	end
	
	local eventList = MedicalEvents[categoryName]
	if not eventList or #eventList == 0 then
		return nil
	end
	
	-- Return random event from category
	return eventList[math.random(1, #eventList)]
end

function MedicalEvents.getAllCategories()
	return {"DoctorVisit", "Therapy", "PlasticSurgery", "Dentist", "Emergency", "Alternative"}
end

return MedicalEvents
