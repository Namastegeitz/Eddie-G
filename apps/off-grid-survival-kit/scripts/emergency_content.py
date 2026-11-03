# -*- coding: utf-8 -*-
"""
Off-Grid Survival Kit — Emergency Guide content (single source of truth).

Everything printed in emergency/off-grid-emergency-guide.pdf and shown on
emergency/index.html comes from this file. Edit the text here, then rebuild
both outputs from the app root:

    python3 scripts/build_emergency.py

Inline markup understood by the builder (keep it simple):
    **bold text**              -> bold in the PDF and <strong> in HTML
    [[ref:some-id|Link text]]  -> cross-reference: "Link text (p. N)" in the PDF,
                                  an in-page link (#some-id) in HTML
Characters: the PDF uses the built-in Helvetica font (Windows-1252 glyphs only),
so avoid arrows and maths symbols such as "≈", "≥", "→" in text — write
"about", "at least", "then". The build fails loudly if an unsupported character
sneaks in.

Figures follow the shared CONTENT_BRIEF canonical facts so the PDF agrees with
the rest of the app (CDC, USDA, NWS/NOAA, FEMA, Red Cross/AHA, CAL FIRE, ICAO).
"""

APP_NAME = "Off-Grid Survival Kit"
DOC_TITLE = "Emergency Guide"
EDITION = "Edition 2026-11"
PDF_FILENAME = "off-grid-emergency-guide.pdf"
FOOTER = ("Off-Grid Survival Kit — Emergency Guide — "
          "not a substitute for training or professional care")

CALL_HELP_SHORT = "Life in danger? Call 911 (US/Canada) or 112 (Europe and many other countries)."
CALL_HELP = (
    "**Call 911** (US/Canada) **or 112** (Europe and many other countries) — "
    "on any phone, even with \"No service\" or \"Emergency calls only\" showing. "
    "If a call won't connect, **send a text** (texts often get through on one bar). "
    "Then: STOP, and follow the priorities below."
)

DISCLAIMER_SHORT = (
    "General guidance for emergencies — not medical advice and not a substitute for "
    "first-aid training, professional care or official instructions. Always follow "
    "emergency services and local authorities."
)

# ---------------------------------------------------------------------------
# Priorities (first page)
# ---------------------------------------------------------------------------
STOP = [
    ("S", "Stop", "Stop moving. Sit down, breathe. Don't make it worse."),
    ("T", "Think", "What is the danger now? What do you have? Who knows where you are?"),
    ("O", "Observe", "Surroundings, weather, daylight left, injuries, gear."),
    ("P", "Plan", "Decide the next steps, then act in the order below."),
]

RULE_OF_3S = [
    ("3 minutes", "without air (or in icy water, or with severe bleeding)"),
    ("3 hours", "without shelter in harsh weather"),
    ("3 days", "without water"),
    ("3 weeks", "without food"),
]
RULE_OF_3S_NOTE = "Typical, not absolute — use it to set priorities, not to judge how long someone can last."

PRIORITY_ORDER = [
    ("Safety", "Get away from danger: traffic, fire, water, rockfall, carbon monoxide. Call for help."),
    ("First aid", "Stop severe bleeding; check breathing."),
    ("Shelter", "Out of wind and wet, off cold ground (or out of the sun)."),
    ("Water", "Drink enough; treat water you are not sure of."),
    ("Signalling", "Make it easy to be found: sound, light, colour, threes."),
    ("Food", "Least urgent; helps warmth and morale."),
]
PRIORITY_NOTE = "Adapt to the situation: if you hear an aircraft or searchers, signal now."

# ---------------------------------------------------------------------------
# Scenarios
# Each: id, title, sub (one-line summary), key (the one thing to remember),
#       steps (numbered), dont (bullets), ready (bullets), callouts (kind/title/text)
# kind is one of: danger, warn, info, ok
# ---------------------------------------------------------------------------
SCENARIOS = [
    {
        "id": "sc-lost",
        "title": "Lost while hiking",
        "sub": "STOP · stay put · make yourself easy to find",
        "key": ("If you are lost, **stop moving**. Searchers start from your last known point — "
                "staying put makes you far easier to find."),
        "steps": [
            "**STOP.** Sit down, drink some water, eat a snack. Panic is the biggest danger — calm down before you decide anything.",
            "**Think and observe.** Where did you last know exactly where you were? Look and listen for trails, roads, power lines, traffic or water. Check map, compass, GPS or the app's Map page.",
            "**Call for help early** if you have any signal: **911 / 112**. Give your coordinates, what you're wearing and your battery level. If calls fail, **text** your coordinates to someone who can call for you (or text 911 where available).",
            "**Save battery:** airplane mode between check-ins, screen dim, phone kept warm in an inside pocket.",
            "**Go back only if you are sure** of the way (clear trail, your own footprints, known landmarks). Otherwise **stay where you are** — especially if someone knows your route and return time.",
            "**Be visible:** move only to the nearest open spot (clearing, trail edge). Spread out bright clothing or gear and build ground signals ([[ref:signals|Signalling card]]).",
            "**Make noise:** **3 whistle blasts**, pause, listen, repeat. A whistle carries much farther than shouting and saves your voice.",
            "**Shelter before dark.** Start at least 1–2 hours before sunset: out of wind and wet, a thick layer of branches or leaves under you, all layers on.",
            "**Water and fire, if safe:** treat stream water ([[ref:water|Water card]]); a small fire for warmth and signalling only where it can't spread.",
            "**Keep signalling** at intervals, night and morning. Answer anyone calling your name. Stay put until found.",
        ],
        "dont": [
            "Don't keep walking \"to find the trail\" — most lost people walk farther from where searchers will look.",
            "Don't follow streams or gullies downhill into steep ground — they often end at cliffs, waterfalls or thick brush.",
            "Don't split up a group.",
            "Don't travel at night, in fog or in a whiteout.",
            "Don't drain your phone with constant map checks.",
            "Don't hide from searchers or helicopters — answer them and wave.",
        ],
        "ready": [
            "Trip plan left with someone: route, return time, **when to call for help**.",
            "Map + compass (and the skill to use them); charged phone + power bank.",
            "Whistle, headlamp + spare batteries, signal mirror, something bright.",
            "Extra layers, rain gear, emergency blanket or bivy bag.",
            "Water and a way to treat it; extra food.",
            "Fire starter, knife, small first-aid kit.",
            "In remote areas: a personal locator beacon (PLB) or satellite messenger.",
        ],
        "callouts": [
            ("info", "Children", "Teach kids to **\"hug a tree\"**: stay in one place, blow the whistle, and answer anyone who calls their name — searchers are friends."),
        ],
    },
    {
        "id": "sc-vehicle",
        "title": "Vehicle breakdown in a remote area",
        "sub": "Stay with the vehicle · be visible · beware carbon monoxide",
        "key": ("**Stay with the vehicle.** It is shelter, and it is far easier to spot from the road "
                "or the air than a person on foot."),
        "steps": [
            "**Get safe first:** pull as far off the road as you can, hazard lights on. On a road with traffic, wait away from the vehicle and behind a barrier if there is one; in a remote area with little traffic, the vehicle is your best shelter.",
            "**Call or text for help:** 911 / 112 or roadside assistance. Give the road name, mile marker or coordinates. No signal? Don't walk off to find one unless help is close and visible and the weather is safe.",
            "**Make the vehicle visible:** tie a bright cloth to the antenna or a door; raise the hood once snow stops falling (a common sign of trouble); at night, turn on the inside light while the engine runs.",
            "**Cold weather: clear the exhaust pipe of snow first**, and check it often. Then **run the engine and heater about 10 minutes each hour** with a downwind window cracked open slightly.",
            "**Keep warm:** all extra clothing on; blankets, floor mats or newspaper for insulation; huddle together. Move arms and legs. Take turns sleeping — one person stays awake.",
            "**Hot weather:** rest in shade beside the vehicle, not inside a closed hot car. Cover skin, move little in the heat of the day, and drink your water when thirsty — don't save it.",
            "**Signal:** horn in 3 blasts, mirror flashes at aircraft or distant traffic, ground signals in an open area ([[ref:signals|Signalling card]]). A signal fire only if safe, well away from the vehicle and fuel.",
            "**Drink:** melt snow before drinking it — eating snow chills you. Ration food, not water.",
            "**Walk out only if** you know exactly where help is, it is close, the weather is safe and someone knows your plan. Leave a note on the vehicle: your route and the time you left.",
        ],
        "dont": [
            "Don't leave the vehicle in a storm, whiteout or extreme heat.",
            "Don't run the engine with the exhaust blocked, or in an enclosed space — **carbon monoxide** kills without warning.",
            "Don't use a stove, grill or fuel heater inside the vehicle.",
            "Don't sleep with the engine running.",
            "Don't drain the battery: use lights, hazards and the heater fan sparingly.",
        ],
        "ready": [
            "Fuel tank at least half full on remote or winter trips.",
            "Blankets or sleeping bags, hat, gloves, boots, dry socks.",
            "Water, high-energy food, phone charger cable.",
            "Flashlight + spare batteries, first-aid kit.",
            "Small shovel, ice scraper, sand or cat litter for traction, jumper cables, tow strap.",
            "Bright cloth, whistle, signal mirror, warning triangles.",
            "Paper map; route and arrival time left with someone.",
        ],
        "callouts": [
            ("danger", "Carbon monoxide", "Colourless and odourless. Headache, dizziness, nausea, drowsiness or confusion: **turn the engine off and get fresh air at once.**"),
        ],
    },
    {
        "id": "sc-power",
        "title": "Power grid down (multi-day)",
        "sub": "Food safety · generator CO · water · medical devices · comms · cash",
        "key": ("**Keep the fridge and freezer closed, never run fuel-burning equipment indoors,** "
                "and check on anyone who depends on power for their health."),
        "steps": [
            "**Check and report:** neighbours' lights, your breaker panel; report the outage. Stay at least **60 ft (18 m)** from downed lines — assume they are live.",
            "**Food (USDA):** keep doors **closed**. A closed fridge keeps food safe about **4 hours**; a **full freezer about 48 hours (half-full about 24 hours)**. After 4 hours without power, throw out perishable fridge food (meat, poultry, seafood, milk, eggs, leftovers). Freezer food that still has ice crystals or is at **40 °F (4 °C)** or below can be refrozen or cooked.",
            "**Generator:** outdoors only, **at least 20 ft (6 m) from doors, windows and vents, exhaust pointed away** — never in a home, garage, basement, crawlspace or shed, even with doors open. Let it cool before refuelling. **Never back-feed the house through an outlet** (\"suicide cord\") — it can electrocute line workers and neighbours; use extension cords, or a properly installed transfer switch or interlock.",
            "**Water:** while taps still run, fill containers (and the bathtub for flushing). Aim for **1 gal (3.8 L) per person per day** for at least 3 days. Follow any boil-water notice ([[ref:sc-water|Water contamination]]).",
            "**Medical devices and medicines:** oxygen, CPAP, dialysis, powered wheelchairs, refrigerated medicine such as insulin — backup batteries, a place to go (family with power, hospital, shelter), and ask a pharmacist how long each medicine keeps unrefrigerated.",
            "**Communications:** battery or hand-crank radio for official updates. Save phone battery. **Texts get through when calls don't.** Charge from power banks, or from a car running outdoors — never in a closed garage.",
            "**Stay warm or cool:** cold — live in one room, doors closed, windows covered at night, layers, hats, sleeping bags; **never heat the home with a gas oven or range, grill, camp stove or outdoor heater.** Heat — lowest floor, drink water, wet cloths, cooling centre. Check on older neighbours.",
            "**Cash, roads, lights:** card readers and ATMs fail — keep small bills. Treat dark traffic lights as an all-way stop (check local law). Flashlights, not candles. Unplug electronics; leave one lamp on to know when power returns.",
        ],
        "dont": [
            "Don't run a generator, grill, camp stove or fuel heater indoors, in a garage or near windows.",
            "Don't back-feed the house through an outlet.",
            "Don't open the fridge or freezer \"just to check\".",
            "Don't taste food to decide if it's safe — when in doubt, throw it out.",
            "Don't touch or drive over downed lines.",
        ],
        "ready": [
            "Flashlights or headlamps + batteries; battery or hand-crank radio.",
            "Power banks; car charger; backup power for medical devices.",
            "Water (1 gal / 3.8 L per person per day, 3+ days); food that needs no cooking.",
            "Battery CO alarm; fire extinguisher; fridge/freezer thermometers.",
            "Cash in small bills; paper list of phone numbers.",
            "Spare medication; if you rely on powered medical equipment, register with your utility if it keeps a list.",
        ],
        "callouts": [
            ("danger", "Carbon monoxide", "Generators and fuel heaters kill people in their homes in almost every big outage. Keep battery CO alarms near sleeping areas. Headache, dizziness, weakness, nausea, confusion, or an alarm: **get everyone outside into fresh air and call 911 / 112.**"),
        ],
    },
    {
        "id": "sc-flood",
        "title": "Severe storm or flood",
        "sub": "Turn around, don't drown · go high · avoid floodwater",
        "key": ("**Turn around, don't drown.** Never walk, swim or drive into floodwater — you can't "
                "see how deep or fast it is, or what is in it."),
        "steps": [
            "**Get warnings:** phone alerts, weather radio, local radio. If told to evacuate, **go now** by the recommended route.",
            "**Know the numbers:** **6 in (15 cm)** of moving water can knock you down. **12 in (30 cm)** can float a car. **2 ft (60 cm)** can sweep away most vehicles.",
            "**Water rising at home:** go to the **highest floor**. **Do not climb into a closed attic** — rising water can trap you there. Go onto the roof only if you must, and signal for help from it.",
            "**Driving:** turn around at flooded or washed-out roads and barricades. If your vehicle is trapped in fast-moving water, stay inside; if water rises inside the vehicle, get onto the roof and call for help.",
            "**Thunderstorm:** when thunder roars, go indoors — a solid building or a hard-topped vehicle with windows closed. Keep away from trees, poles, water and high ground. Wait **30 minutes after the last thunder**.",
            "**Tornado warning:** basement, or a small interior room on the lowest floor away from windows. Cover your head and neck.",
            "**Electricity:** turn off power at the main switch only if told to and you are dry and not standing in water. Never touch electrical equipment while wet.",
            "**After:** return only when officials say it is safe. Watch for downed lines, weak floors and stairs, gas smell (leave, call from outside) and animals. Throw out food that touched floodwater. Assume tap water is unsafe until told otherwise.",
        ],
        "dont": [
            "Don't walk, swim or drive through floodwater — not even a few inches of moving water.",
            "Don't touch floodwater if you can avoid it: sewage, chemicals, fuel, debris — and possibly **live wires**.",
            "Don't go into a closed attic to escape rising water.",
            "Don't drive around barricades.",
            "Don't shelter under trees in a thunderstorm.",
            "Don't run a generator indoors to dry the house out.",
        ],
        "ready": [
            "Go-bag: water, food, medicines, documents in a waterproof bag, charger, cash.",
            "Alerts switched on; battery or hand-crank radio.",
            "Know your flood risk, your evacuation route and where higher ground is.",
            "Roof signalling kit: whistle, flashlight, bright cloth, phone in a waterproof bag.",
            "Boots, gloves and bleach for clean-up.",
        ],
        "callouts": [
            ("danger", "Floodwater", "Presume all floodwater is contaminated, and that it may hide **live electrical wires**, open manholes and debris. Wash skin that touches it with soap and clean water."),
        ],
    },
    {
        "id": "sc-wildfire",
        "title": "Wildfire evacuation",
        "sub": "Leave early · go-bag · N95 · if trapped in a vehicle or on foot",
        "key": ("**Leave early.** Don't wait for an order if you feel unsafe — wind-driven fire can move "
                "faster than you can run, and roads jam quickly."),
        "steps": [
            "**Watch alerts and smoke.** Know two ways out. When told to go — or when you feel unsafe — **go immediately**.",
            "**Grab the go-bag**, medicines, documents, phone and charger, pets. Wear long cotton or wool clothes, sturdy shoes and an **N95 (or better) respirator** for smoke.",
            "**Only if time allows:** close all windows and doors but leave them unlocked; shut off gas at the meter; move flammable furniture away from the house; leave outside lights on so firefighters can see the house in smoke.",
            "**Drive out** with headlights on, windows up and air on recirculate. Drive slowly; watch for people, animals and fire crews. Follow official routes.",
            "**Trapped in a vehicle:** park in an area clear of vegetation (wide road, gravel, parking lot). Engine on if it will run, air on recirculate, headlights on. **Close the windows and all vents. Lie on the floor and cover yourself with a wool or cotton blanket or coat.** Call 911 / 112. Stay inside until the fire front passes — it will get hot and smoky, but it is far safer than running.",
            "**Trapped on foot:** get to the best refuge you can reach — a cleared area with little to burn, a body of water, a road, or ground that has already burned once it is safe to cross. **Lie face down**, cover exposed skin, protect your airway, and stay low until the fire front passes.",
            "**Trapped at home:** stay inside, away from outside walls and windows. Fill sinks and tubs with water. Keep doors closed but unlocked. Call 911 / 112.",
            "**Afterwards:** return only when officials say it is safe. Watch for hot spots, ash pits, fallen lines and damaged trees. Wear an N95 and gloves in ash. Follow water notices.",
        ],
        "dont": [
            "Don't wait to see flames before leaving.",
            "Don't try to outrun a fire uphill — fire spreads fastest uphill.",
            "Don't leave a vehicle to run while the fire front passes.",
            "Don't rely on cloth or paper dust masks — they don't stop fine smoke.",
            "Don't wear synthetic fabrics near fire — they can melt onto skin.",
            "Don't go back before officials allow it.",
        ],
        "ready": [
            "Go-bag by the door: water, food, medicines, document copies, chargers, cash, glasses.",
            "N95 (or P100) respirators for everyone; goggles.",
            "Car parked facing out, fuel at least half full, keys in a known place.",
            "Wool or cotton blanket in the car; flashlight.",
            "Two evacuation routes and a meeting place outside the area; plan for pets.",
            "Dead vegetation and flammables cleared from around the house.",
        ],
        "callouts": [
            ("danger", "Smoke and heat", "Smoke and radiant heat kill before flames reach you. Stay low where the air is clearer, protect your airway, and put solid objects between you and the fire."),
        ],
    },
    {
        "id": "sc-winter",
        "title": "Winter: stranded in a vehicle or on foot",
        "sub": "Shelter first · stay dry · off the ground · beware CO and frostbite",
        "key": ("**Shelter comes first:** out of wind and wet, off the cold ground. "
                "In a vehicle, stay with it."),
        "steps": [
            "**In a vehicle: stay with it** ([[ref:sc-vehicle|Vehicle breakdown]]). **Clear the exhaust pipe of snow** and keep checking it. Run engine and heater **about 10 minutes each hour** with a downwind window cracked. Bright cloth on the antenna; inside light on at night while the engine runs.",
            "**In a vehicle: insulate and move.** All layers on, heads covered, blankets, seat covers and floor mats around you; huddle. Exercise arms and legs now and then; one person stays awake.",
            "**On foot: stop early.** Make shelter before you are exhausted or soaked with sweat — at least 1–2 hours before dark, or as soon as the weather turns.",
            "**Pick a safe spot:** out of the wind (lee of trees, rocks or a snow bank). Keep away from slopes of about 30° or steeper and the run-out below them (avalanche paths). Beware deep loose snow around tree trunks (tree wells).",
            "**Insulate from the ground:** a thick layer of branches, your pack or a foam pad — you lose heat fastest to snow and cold ground.",
            "**Stay dry:** open or remove layers before you sweat; change into dry socks and gloves; dry damp items with body heat.",
            "**Snow shelter** (only if you know how): keep a ventilation hole open, keep your digging tool inside, and mark the outside so you can be found. Never use a stove or fire inside.",
            "**Drink and eat:** melt snow before drinking it (warm if you can); eat to fuel shivering. Signal from open ground — dark branches or clothing on snow show up well.",
            "**Watch each other** for hypothermia (shivering, stumbling, slurred speech, fumbling hands, poor judgement) and frostbite ([[ref:fa-hypothermia|Hypothermia card]]).",
        ],
        "dont": [
            "Don't eat snow without melting it — it chills you and costs energy.",
            "Don't drink alcohol — it speeds heat loss.",
            "Don't run a stove, heater or engine in a closed vehicle, tent or snow shelter — **carbon monoxide**.",
            "Don't sit or sleep directly on snow or cold ground.",
            "Don't keep travelling in a whiteout or in the dark.",
        ],
        "ready": [
            "Layers: wool or synthetic base, warm mid-layer, wind/waterproof shell; hat; spare gloves and socks.",
            "Sleeping bag or blankets in the car; emergency bivy; foam pad.",
            "Shovel, scraper, traction aids; fuel at least half full.",
            "Headlamp, fire starter, stove and pot for melting snow (used outside or well ventilated).",
            "High-energy food; thermos of hot drink; water kept from freezing.",
            "Forecast and road conditions checked; route and arrival time left with someone.",
        ],
        "callouts": [
            ("warn", "Frostbite", "Numb, white or grey, hard skin. Protect it from more cold; do **not** rub it. Don't thaw it if it could freeze again. Rewarm gently (body heat or warm — not hot — water) once you are in lasting shelter, then get medical care."),
        ],
    },
    {
        "id": "sc-water",
        "title": "Water contamination",
        "sub": "Boil-water notice vs do-not-drink notice — boiling doesn't fix chemicals",
        "key": ("**Read which notice it is.** Boiling kills germs. It does **not** remove chemicals, "
                "fuel or metals — and it can concentrate them."),
        "steps": [
            "**Boil-water notice (germs):** for drinking, cooking, ice, brushing teeth, washing food and baby formula use only bottled water or water brought to a **rolling boil for 1 minute (3 minutes above 6,500 ft / 2,000 m)**. Let it cool; store covered.",
            "**Can't boil?** Disinfect clear water with plain unscented bleach: **6%: 2 drops per litre, 8 drops per gallon. 8.25%: 2 drops per litre, 6 drops per gallon. Double for cloudy, coloured or very cold water. Wait at least 30 minutes** ([[ref:water|Water card]]). Bleach does not reliably kill Cryptosporidium — boiling does.",
            "**Do-not-drink notice (chemicals, or unknown):** do not drink the tap water **even if boiled**. Use bottled or delivered water for drinking, cooking, ice, brushing teeth and formula. Follow the notice about washing.",
            "**Do-not-use notice:** don't use the tap water for anything — not even washing or bathing.",
            "**Washing under a boil-water notice:** showering is usually fine — don't swallow any; sponge-bathe babies. Wash hands with soap and safe water, or use hand sanitizer. Give pets safe water too.",
            "**Floodwater or an unknown source:** presume it is contaminated. No home method removes fuel, heavy metals, pesticides, industrial chemicals or algae toxins — find another source.",
            "**When the notice ends:** follow your water utility — run the taps to flush the pipes, throw out ice made during the notice, and replace filter cartridges.",
        ],
        "dont": [
            "Don't boil water under a do-not-drink notice expecting it to be safe.",
            "Don't trust fridge or pitcher filters unless the notice says they work for this problem.",
            "Don't use water that smells of fuel or chemicals or has an oily sheen.",
            "Don't use ice made during the notice.",
            "Don't make baby formula with untreated tap water.",
            "Don't count on a sand/charcoal filter — it only improves clarity and taste.",
        ],
        "ready": [
            "Stored water: 1 gal (3.8 L) per person per day for at least 3 days.",
            "Pot and a safe way to heat it (camp stoves outdoors only).",
            "Plain unscented bleach (check strength and date) and a dropper, or purification tablets.",
            "Clean containers with lids; a marker to label \"treated\" and the date.",
            "Hand sanitizer; a filter for germs in clear water (not chemicals).",
        ],
        "callouts": [
            ("warn", "Chemical contamination", "Fuel smell, oily film, unusual colour, dead fish, or an algae bloom: treat the water as chemically contaminated. Boiling, bleach, SODIS and most filters will not make it safe."),
        ],
    },
    {
        "id": "sc-injury",
        "title": "Injury far from help",
        "sub": "Stop bleeding · breathing · call · keep warm · plan the evacuation",
        "key": ("**Deal with what kills first:** severe bleeding, then breathing, then cold. "
                "Get help coming as early as you can."),
        "steps": [
            "**Scene safe?** Rockfall, traffic, water, avalanche, fire — don't create a second casualty. Wear gloves if you have them.",
            "**Severe bleeding:** firm direct pressure or pack the wound. Life-threatening limb bleeding not controlled: **tourniquet 2–3 in (5–7 cm) above the wound, not on a joint** (high and tight if unclear); tighten until bleeding stops; **note the time**; do not loosen ([[ref:fa-bleeding|Bleeding card]]).",
            "**Responsive? Breathing normally?** Not breathing normally: start CPR ([[ref:fa-cpr|CPR card]]). Unresponsive but breathing: recovery position to keep the airway clear.",
            "**Call for help:** 911 / 112; text if calls fail; PLB or satellite messenger. Give location (coordinates), what happened, how many are hurt, and their condition.",
            "**Protect from cold:** insulate from the ground, cover with layers or an emergency blanket, shelter from wind. Injured people get hypothermic even in mild weather.",
            "**Check head to toe and treat:** cover wounds; splint suspected fractures in the position found (pad well, immobilise the joints above and below). Suspected neck or back injury: keep them still unless they are in danger.",
            "**Write it down:** time of injury, what happened, responsiveness, breathing and pulse every 15 minutes, treatment given, tourniquet time, medicines given.",
            "**Decide the plan:** wait for rescue, walk out together (only if the injured person can walk safely), or send for help. Send two people together with a **written note** (location, injuries, condition, what you need); someone stays with the casualty.",
        ],
        "dont": [
            "Don't loosen a tourniquet once applied.",
            "Don't pull out an impaled object — pad around it and secure it.",
            "Don't give food or drink to anyone who is not fully alert.",
            "Don't move a suspected spinal injury unless they are in danger.",
            "Don't give alcohol.",
            "Don't leave a casualty alone if you can avoid it. If you must: sheltered, insulated, with water, a whistle and a note of when you left.",
        ],
        "ready": [
            "First-aid kit: commercial tourniquet, gauze for packing, compression bandage, gloves, tape, splint, triangular bandage, emergency blanket.",
            "Training: first aid and CPR — wilderness first aid if you go remote.",
            "Charged phone and power bank; PLB or satellite messenger.",
            "Pencil and waterproof paper for notes.",
            "Foam pad, extra warm layer, bivy bag.",
        ],
        "callouts": [
            ("info", "Pain relief (adults)", "Follow the package label. Acetaminophen/paracetamol: no more than **3,000 mg a day** without a doctor's advice. Ibuprofen: **200–400 mg every 4–6 hours, max 1,200 mg a day** unless a doctor directs (avoid if dehydrated). No aspirin for under-19s."),
        ],
    },
    {
        "id": "sc-separated",
        "title": "Separated from your group",
        "sub": "Plan before you go · stay put · rendezvous · signal",
        "key": ("**Agree the plan before you start:** anyone who gets separated **stays put** and "
                "signals; the group comes back for them."),
        "steps": [
            "**Before the trip — agree the rule:** if separated, STOP and stay where you are. Searchers and your group look for you near where you were last seen.",
            "**Before the trip — set rendezvous points:** the last junction or landmark you passed together; then the trailhead or vehicle by a set time (\"if we're apart at 4 pm, meet at the car\").",
            "**Before the trip — agree signals:** for example 1 whistle blast = \"where are you?\", 2 = \"come to me\", **3 = help**. Everyone carries a whistle, light, water and a warm layer, and has everyone's phone numbers.",
            "**On the trail:** head count at every junction, break and river crossing. Keep the slowest person in front and a trusted \"sweep\" at the back. Nobody walks ahead or drops behind out of sight.",
            "**If you are the one separated:** stop. Call out, then **3 whistle blasts**, pause, listen. Call or text the group (or 911 / 112). Stay put — move only to the agreed rendezvous if it is close and you are certain of the way.",
            "**Be found:** move into the open nearby, use bright clothing, keep signalling at intervals. Answer anyone calling your name.",
            "**If you are the group:** stop and count. Go back **together** to where you last saw the person; mark that spot. Don't send people off alone.",
            "**Not found quickly — or it's getting dark or the weather is turning? Call 911 / 112 now.** Early calls make searches shorter. Leave a note at the vehicle and don't leave the area until everyone is accounted for.",
        ],
        "dont": [
            "Don't wander off alone to search.",
            "Don't let anyone hike on ahead or fall behind out of sight.",
            "Don't change the plan mid-trip without everyone knowing.",
            "Don't wait too long before calling for help.",
            "Don't drive away from the trailhead until everyone is accounted for.",
        ],
        "ready": [
            "Written trip plan left with someone at home.",
            "Whistle, light and map for every person — children too.",
            "Everyone knows the rendezvous points and the whistle code.",
            "Phone numbers of all members; charged phones.",
            "A photo of everyone (and their shoe soles) at the start — it helps searchers.",
        ],
        "callouts": [
            ("info", "Children", "Give every child a whistle and teach them to **\"hug a tree\"**: stay put, blow 3 blasts, and answer when anyone calls their name."),
        ],
    },
]

# ---------------------------------------------------------------------------
# Reference card: water purification (canonical facts — keep in sync with the Water page)
# ---------------------------------------------------------------------------
WATER = {
    "intro": ("Filter or settle cloudy water first, then disinfect. Store treated water covered, "
              "in clean containers. **Floodwater is presumed contaminated.**"),
    # (method, how, works against / limits)
    "methods": [
        ("Boil",
         "Rolling boil for **1 minute**; **3 minutes above 6,500 ft (2,000 m)**. Let cool; store covered.",
         "Best method. Kills bacteria, viruses and protozoa, including Cryptosporidium. Does nothing for chemicals."),
        ("Bleach",
         "Plain, unscented household bleach (no scented, \"splash-less\" or cleaner additives). Dose: table below. Stir, **wait at least 30 minutes**.",
         "Does **not** reliably kill Cryptosporidium. Needs a slight chlorine smell after 30 min — if none, repeat the dose and wait another 15 min."),
        ("Chlorine dioxide tablets",
         "Follow the product label.",
         "Up to **4 hours** contact time for Cryptosporidium."),
        ("Iodine",
         "Follow the product label.",
         "Not for pregnancy, thyroid problems, iodine allergy, or use longer than a few weeks."),
        ("SODIS (sunlight)",
         "Clear PET bottle, 2 L or smaller, clear (low-turbidity) water, full sun for **6 hours**; **2 consecutive days** if the sky is more than 50% cloudy.",
         "Not for rainy days. Does nothing for chemicals."),
        ("Portable filter",
         "Follow the maker's instructions; pre-filter murky water.",
         "Most remove bacteria and protozoa but **not viruses** unless rated as a purifier — add a disinfectant if in doubt. Freezing can crack hollow-fibre filters. Doesn't make chemically polluted water safe."),
        ("Sand / charcoal filter (improvised)",
         "Layers of cloth, sand, gravel and charcoal.",
         "**Improves clarity and taste only — it does NOT make water safe.** Always disinfect afterwards."),
    ],
    # bleach table: (strength, per 1 litre, per 1 gallon)
    "bleach_head": ("Bleach strength (sodium hypochlorite)", "1 litre (1 quart)", "1 gallon (3.8 L)"),
    "bleach": [
        ("6%", "2 drops", "8 drops (about 1/8 tsp)"),
        ("8.25%", "2 drops", "6 drops"),
    ],
    "bleach_notes": [
        "**Double the dose** if the water is cloudy, coloured or very cold.",
        "Stir, then **wait at least 30 minutes**. It should smell slightly of chlorine; if not, repeat the dose and wait another 15 minutes.",
        "Check the strength on the label. Bleach slowly loses strength in storage — rotate your supply.",
    ],
    "callouts": [
        ("danger", "Chemicals", "No home method removes fuel, heavy metals, pesticides, industrial chemicals or toxic algae toxins — boiling can concentrate some of them. Find another source."),
        ("info", "Solar still", "Realistic yield is small — often a few hundred mL per day per pit. Not a primary water source."),
    ],
}

# ---------------------------------------------------------------------------
# Reference card: signalling
# ---------------------------------------------------------------------------
# Ground-to-air emergency code (ICAO Annex 12 survivor signals). Symbol keys are
# drawn by the builder: V, X, N, Y, ARROW.
GROUND_TO_AIR = [
    ("V", "Require assistance"),
    ("X", "Require medical assistance"),
    ("N", "No / negative"),
    ("Y", "Yes / affirmative"),
    ("ARROW", "Proceeding in this direction (point it the way you are going)"),
]
GROUND_TO_AIR_NOTES = [
    "Make each symbol **at least 10 ft (3 m) tall** — bigger is better — with thick, straight lines.",
    "Use **strong contrast**: dark branches or rocks on snow or sand, bright fabric on dark ground, or trenches that cast shadows.",
    "Build in the most open place nearby, away from tree cover. Straight lines and sharp angles rarely occur in nature, so they catch the eye.",
    "**SOS** or **HELP** in large letters is also widely understood.",
]
BODY_SIGNALS = (
    "**To a helicopter or aircraft:** both arms raised in a **Y** = \"Yes, we need help\". "
    "One arm up and one down (like an **N**) = \"No, we don't need help\". "
    "Don't wave casually at aircraft — it can be misread."
)

DISTRESS_THREES = (
    "**Three of anything = distress:** 3 fires (in a triangle or a line), 3 whistle blasts, "
    "3 horn blasts, 3 flashes of light, 3 shots, 3 piles of rocks."
)
WHISTLE = [
    "**3 blasts = help.** Blow 3 long blasts, pause about a minute, listen, repeat.",
    "In European mountains you may hear the alpine distress signal: **6 blasts in a minute, a minute's pause, repeat**; the reply is 3 blasts a minute. Answer either one.",
    "A whistle carries much farther than a voice and uses far less energy.",
]
LIGHT_SOS = [
    "**SOS = 3 short, 3 long, 3 short**, then a pause; repeat.",
    "Timing: short flash about **1 count**, long flash **3 counts**, **1 count** dark between flashes, **3 counts** between letters, **7 counts or more** before repeating. A count is about half a second.",
    "Slow and steady is easier to read than fast. Aim at the aircraft, boat or distant observer.",
]
MIRROR_STEPS = [
    "Hold the mirror close under your eye. Stretch your other arm toward the target (aircraft, ship, vehicle) and make a **V with two fingers**, with the target in the V.",
    "Tilt the mirror until the spot of sunlight it reflects lands on your fingers.",
    "Keep the light spot on your fingers and the target inside the V — the flash is now hitting the target.",
    "**Rock the mirror slightly** so the flash sweeps across the target. A signal mirror with a sighting hole: look through the hole and put its bright aiming spot on the target.",
    "Sweep the horizon now and then even when you see nothing — a flash can be seen from many miles away. Once they have seen you, stop flashing directly at the cockpit.",
]
PHONE_RADIO = [
    "**Phones:** in many places, dialling **911** or **112** works on any phone with any network in range — not just your own — and in many countries even without a SIM card. Try it even when the phone shows \"No service\" or \"Emergency calls only\".",
    "**Texts** often get through when calls don't. In the US you can text 911 in many areas (you get a bounce-back message if not). Some newer phones can send emergency messages by satellite — learn how before you go.",
    "**PLB / satellite messenger:** extend the antenna, keep a clear view of the sky, activate and leave it on.",
    "**Marine VHF:** **channel 16** (156.8 MHz) is the distress, safety and calling channel. On a DSC radio, hold the red DISTRESS button for a few seconds first.",
    "**\"MAYDAY, MAYDAY, MAYDAY\"** = grave and imminent danger to life or vessel. **\"PAN-PAN, PAN-PAN, PAN-PAN\"** = urgent, but not immediately life-threatening.",
    "Then: \"This is\" + vessel/name 3 times; your **position**; **what is wrong**; **help needed**; **number of people**; \"Over\". Repeat if no answer.",
    "**Other radios:** in the US, CB channel 9 is for emergencies and traveller assistance. 121.5 MHz is the aviation emergency frequency.",
]

# Morse code (A–Z, 0–9). "." = short (dot), "-" = long (dash).
MORSE = [
    ("A", ".-"), ("B", "-..."), ("C", "-.-."), ("D", "-.."), ("E", "."), ("F", "..-."),
    ("G", "--."), ("H", "...."), ("I", ".."), ("J", ".---"), ("K", "-.-"), ("L", ".-.."),
    ("M", "--"), ("N", "-."), ("O", "---"), ("P", ".--."), ("Q", "--.-"), ("R", ".-."),
    ("S", "..."), ("T", "-"), ("U", "..-"), ("V", "...-"), ("W", ".--"), ("X", "-..-"),
    ("Y", "-.--"), ("Z", "--.."),
    ("0", "-----"), ("1", ".----"), ("2", "..---"), ("3", "...--"), ("4", "....-"),
    ("5", "....."), ("6", "-...."), ("7", "--..."), ("8", "---.."), ("9", "----."),
]
MORSE_NOTE = ("Dot = 1 unit, dash = 3 units; 1 unit gap inside a letter, 3 between letters, "
              "7 between words. SOS is sent as one run with no letter gaps: 3 short, 3 long, 3 short.")

# ---------------------------------------------------------------------------
# Reference card: knots
# ---------------------------------------------------------------------------
KNOTS = [
    {
        "id": "knot-bowline",
        "name": "Bowline",
        "use": "A fixed loop that won't slip or jam — around a tree, a post, a person in a rescue.",
        "steps": [
            "Make a small loop in the standing part, with the working end side lying **on top**.",
            "Pass the working end **up through** the small loop from underneath.",
            "Take it **around behind** the standing part.",
            "Bring it back **down through** the small loop.",
            "Hold the working end against the big loop and pull the standing part to tighten. Leave a tail at least 10–12 rope-widths long.",
        ],
        "caution": "Can shake loose when not under load — back it up with a stopper knot.",
    },
    {
        "id": "knot-taut-line",
        "name": "Taut-line hitch",
        "use": "An adjustable loop for tent and tarp guy-lines; slides to tighten, holds under load.",
        "steps": [
            "Pass the working end around the stake or anchor.",
            "Wrap it **twice** around the standing part, working **inside the loop** toward the anchor.",
            "Bring it out past the two wraps and make **one more turn** around the standing part, outside the loop.",
            "Tuck the end under that last turn and pull snug.",
            "Slide the knot along the line to adjust the tension.",
        ],
        "caution": "Can slip on slick or stiff modern cord — test it before trusting it.",
    },
    {
        "id": "knot-clove",
        "name": "Clove hitch",
        "use": "Quick hitch to a post, pole or tree; starting point for lashings.",
        "steps": [
            "Wrap the working end once around the post.",
            "Cross it **over** the standing part and wrap around the post again, forming an X.",
            "Tuck the end **under** the second wrap, so both ends come out of the middle of the X, in opposite directions.",
            "Pull both ends to tighten.",
        ],
        "caution": "Slips when the load changes direction or the post rotates — add two half hitches for security.",
    },
    {
        "id": "knot-square",
        "name": "Square (reef) knot",
        "use": "Binding knot: tying off bandages, slings and bundles.",
        "steps": [
            "**Right over left** and under.",
            "**Left over right** and under.",
            "Check: both loops lie flat and match, and each end lies alongside its own standing part. (If not, it's a granny knot — retie.)",
        ],
        "caution": "**Not** for joining two ropes that will carry a load — it can spill apart.",
    },
    {
        "id": "knot-prusik",
        "name": "Prusik",
        "use": "A friction hitch that grips a rope under load and slides when loose — ascending, hauling, tensioning lines.",
        "steps": [
            "Make a closed loop of cord **thinner** than the main rope.",
            "Lay the loop behind the main rope and pass it **through itself** around the rope.",
            "Repeat so the cord wraps the rope **3 times**, each pass going through the loop.",
            "Dress the wraps neat and parallel, with no crossings; the loop comes out of the middle.",
            "Load the loop to make it grip; push the knot (not the loop) to slide it.",
        ],
        "caution": "Climbing, rescue or any life-safety use needs proper training and equipment.",
    },
]
KNOTS_NOTE = "Practise each knot with real cord at home, until you can tie it with cold hands and your eyes closed."

# ---------------------------------------------------------------------------
# Reference card: first aid (canonical facts — keep in sync with the First Aid page)
# ---------------------------------------------------------------------------
FIRST_AID = [
    {
        "id": "fa-bleeding",
        "title": "Severe bleeding / tourniquet",
        "steps": [
            "Protect yourself (gloves if you have them). Call or send for help: 911 / 112.",
            "Press **firmly and directly** on the wound with a dressing or cloth. Pack deep wounds with gauze or cloth and keep pressing hard.",
            "Life-threatening limb bleeding not controlled by pressure: apply a **tourniquet 2–3 in (5–7 cm) above the wound, not on a joint** (\"high and tight\" on the limb if you can't see where it is coming from).",
            "**Tighten until the bleeding stops.** It will hurt — that is expected.",
            "**Note the time** (write it on the tourniquet or skin). **Do NOT loosen it** once applied. Get to emergency care.",
            "Keep the person warm and lying down; treat for shock.",
        ],
        "note": "Improvised tourniquet: a wide band (not wire or thin cord) tightened with a stick as a windlass, then the stick secured.",
    },
    {
        "id": "fa-cpr",
        "title": "CPR (adult)",
        "steps": [
            "Safe to approach? Not responsive and **not breathing normally** (gasping is not normal)?",
            "Call 911 / 112 (speaker on) and send someone for an **AED**.",
            "Push **hard and fast** in the centre of the chest: **100–120 per minute**, **at least 2 in (5 cm) but not more than 2.4 in (6 cm)** deep, letting the chest fully recoil.",
            "If trained and willing: **30 compressions : 2 breaths**. Otherwise **hands-only** — keep pushing without stopping.",
            "**Use the AED as soon as it arrives:** switch it on and follow its voice prompts.",
            "Keep going until help takes over, the person starts breathing normally, or you are too exhausted or in danger.",
        ],
        "note": "",
    },
    {
        "id": "fa-choking",
        "title": "Choking",
        "steps": [
            "Can they cough or speak? Encourage them to keep coughing.",
            "Adult or child over 1 year who can't cough, speak or breathe: **5 back blows** between the shoulder blades, then **5 abdominal thrusts**. Repeat.",
            "**Infant under 1 year:** 5 back blows + **5 chest thrusts** (two fingers, centre of chest). **Never abdominal thrusts.**",
            "Becomes unresponsive: call 911 / 112 and **start CPR**.",
            "Anyone who received abdominal thrusts should be checked by a doctor afterwards.",
        ],
        "note": "",
    },
    {
        "id": "fa-burns",
        "title": "Burns",
        "steps": [
            "Stop the burning. **Cool with cool running water for 20 minutes** as soon as possible.",
            "Remove jewellery and clothing near the burn unless it is stuck to the skin.",
            "**No ice, butter or toothpaste.**",
            "Cover loosely with cling film or a clean, non-fluffy dressing. Keep the person warm.",
            "Get medical care for burns that are large or deep; on the face, hands, genitals or airway; or electrical or chemical burns.",
        ],
        "note": "",
    },
    {
        "id": "fa-hypothermia",
        "title": "Hypothermia",
        "steps": [
            "Signs: shivering, clumsiness, slurred speech, confusion. Shivering that stops while they are still cold is a bad sign — get help.",
            "**Handle gently.** Get out of wind and wet; **remove wet clothing** and replace with dry layers.",
            "**Insulate from the ground** and cover the head.",
            "**Warm the core** — armpits, chest, groin — with warm packs, warm bottles wrapped in cloth, or body-to-body contact.",
            "Warm sweet drinks **only if fully alert and able to swallow**. **No alcohol. Don't rub the limbs.**",
        ],
        "note": "",
    },
    {
        "id": "fa-heat",
        "title": "Heat stroke",
        "steps": [
            "**Hot + confused, collapsed or very drowsy = heat stroke — an emergency.** Call 911 / 112.",
            "**Cool immediately and aggressively.** Cold-water immersion (up to the neck) is best.",
            "If you can't immerse: soak with water and fan hard; cold packs to neck, armpits and groin; shade.",
            "Give sips of cool water only if fully alert. Keep cooling until help arrives or they are clearly recovering.",
        ],
        "note": "Heat exhaustion (heavy sweating, weakness, headache, nausea, still thinking clearly): rest in shade, cool down, sip water. Getting confused? Treat it as heat stroke.",
    },
    {
        "id": "fa-shock",
        "title": "Shock",
        "steps": [
            "Signs: pale, cold, clammy skin; fast weak pulse; fast breathing; anxious, confused or drowsy.",
            "Call 911 / 112. **Treat the cause** — stop the bleeding.",
            "Lay them flat. If there is no injury to the legs, hips, spine or head, you may raise the legs about 12 in (30 cm).",
            "**Keep them warm** — insulate from the ground; loosen tight clothing.",
            "Nothing to eat or drink unless fully alert and help is many hours away (then small sips of water). Reassure them; check breathing often.",
        ],
        "note": "",
    },
    {
        "id": "fa-recovery",
        "title": "Recovery position",
        "steps": [
            "For someone **unresponsive but breathing normally**. Kneel beside them.",
            "Place the arm nearest you at a right angle to the body, palm up.",
            "Bring the far arm across the chest and hold the back of that hand against their near cheek.",
            "With your other hand, lift the far knee so the foot is flat, then pull on the knee to roll them toward you onto their side.",
            "Bend the top leg so hip and knee are at right angles. Tilt the head back gently so the airway stays open and fluids can drain.",
            "Check breathing continuously. If it stops or becomes abnormal: call and start CPR. Keep them warm.",
        ],
        "note": "",
    },
]
OTC_MEDS = (
    "**Pain relief (adults):** follow the package label. Acetaminophen/paracetamol: no more than "
    "**3,000 mg a day** without a doctor's advice (label max 4,000 mg; liver risk, avoid alcohol). "
    "Ibuprofen: **200–400 mg every 4–6 hours, max 1,200 mg a day** unless a doctor directs "
    "(stomach bleeding and kidney risk; avoid when dehydrated). No aspirin for under-19s (Reye's syndrome)."
)

# ---------------------------------------------------------------------------
# Fill-in pages (PDF only)
# ---------------------------------------------------------------------------
FILL_IN_PERSONAL = [
    # two labelled boxes per row: (left label, right label, row height in inches)
    ("Name", "Date of birth", 0.36),
    ("Blood type", "Allergies", 0.36),
    ("Medications (name, dose, when)", "Medical conditions / implants / devices", 0.5),
    ("Emergency contact 1 — name and phone", "Emergency contact 2 — name and phone", 0.5),
]
CONTACTS_COLUMNS = ("Name", "Phone", "Relationship")
CONTACTS_ROWS = 6
MEETING_COLUMNS = ("Meeting point", "Where it is / how to get there")
MEETING_ROWS = 3
WAYPOINT_COLUMNS = ("Name", "Lat/Lon or MGRS", "Notes")
WAYPOINT_ROWS = 9
WAYPOINT_NOTE = ("Write coordinates in the same format your map or GPS uses (for example decimal degrees, "
                 "or MGRS such as 18T WK 12345 67890) and note the datum (usually WGS84).")

# ---------------------------------------------------------------------------
# How to use (last page) and disclaimer
# ---------------------------------------------------------------------------
HOW_TO_USE = [
    "**Print it now**, before you need it. It is laid out for US Letter and also fits A4 (choose \"Actual size\" or \"Fit to page\"). Black-and-white printing is fine.",
    "**Fill in page 1 and the contacts and waypoints page by hand**, in pencil or waterproof pen. Update them once a year.",
    "**Keep copies where emergencies happen:** go-bag, vehicle glovebox, first-aid kit, near your home's main water and power shut-offs. Store each in a zip-top bag.",
    "**In an emergency:** start at page 1 — call for help, STOP, follow the priorities — then turn to your scenario using the quick-action index.",
    "Steps are numbered in the order that usually matters most. Adapt them to what you see — your own safety comes first.",
    "**Read it through once now, and practise:** knots, mirror signalling, map and compass. Take a first-aid and CPR course.",
    "The app's Emergency page has the same content, works offline, and may have a newer edition.",
]
DISCLAIMER = (
    "This guide gives general information for emergencies. It is not medical advice and is not a "
    "substitute for training, professional medical care, or instructions from emergency services "
    "and local authorities — always follow official orders. Situations differ: use your judgement. "
    "Figures are typical values from the sources below; always check product labels and local rules. "
    "Use at your own risk."
)
SOURCES = (
    "Based on public guidance from: CDC (drinking water, carbon monoxide, generators), USDA (food safety "
    "in power outages), NWS/NOAA (floods, lightning, winter travel), FEMA / Ready.gov, American Red Cross "
    "and American Heart Association (first aid, CPR), CAL FIRE (wildfire evacuation), ICAO Annex 12 "
    "(ground-to-air signals) and international marine radio procedures."
)
