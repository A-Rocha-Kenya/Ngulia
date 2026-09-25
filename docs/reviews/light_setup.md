# Ngulia light attraction: mechanisms, evidence and measurement

**Working review — 18 September 2026**  
**Scope:** how artificial light can affect nocturnally migrating birds at Ngulia, and what must be measured for a defensible LED transition or experiment. The dated history of lamps, geometry, outages and other operational conditions is consolidated in [daily covariate configuration](../daily_covariates.md) and its source table.

## Executive summary

Ngulia's light attraction is not produced by a lamp alone. It is an interaction among a strong isolated light source, its direction and beam, low cloud or mist at lodge level, little moonlight, the number and altitude of migrants, topography, and the positions of nets and vegetation. Clear nights can carry substantial migration with almost no grounding, whereas low mist around bright lights can bring thousands of birds down.

The literature supports four robust conclusions and one major uncertainty:

1. Turning a strong light on can rapidly aggregate and alter the flight of nocturnal migrants; turning it off can rapidly release them.
2. Cloud, fog and poor visibility usually amplify the response. Ngulia's much stronger requirement for ground-level mist is therefore biologically credible and locally distinctive.
3. Continuous light generally attracts more than flashing light in comparable field tests, although flash rate and duty cycle matter.
4. Light colour matters, but studies disagree on the safest or most attractive wavelength. Some experiments find blue/green/white more attractive than red; one influential metal-halide experiment found white/red more disruptive than green/blue. Spectrum cannot be inferred adequately from the words “LED,” “halogen,” or even from correlated colour temperature alone.
5. There is no published conversion factor from historical Ngulia halogen watts or lumens to an LED arrangement that will reproduce attraction and catch.

Power reliability is a sampling constraint. The generator rating, available spare capacity, circuit protection, cable sizes and voltage stability must be measured before choosing new lamps.

**Recommended direction:** do not make an undocumented permanent swap. Preserve the 2013–2015 three-position geometry as the operational reference, inventory and photograph the surviving equipment, measure the power supply and actual light field, then run a controlled transition with independently switched/dimmable LEDs. Professional fixtures bought and supported in Kenya are preferable if they meet the required optical and spectral specification; import from Europe only if comparable warm-white, dimmable units and documentation cannot be sourced locally. A seasonal loan or sponsorship should be explored before purchase.

## 1. What the lighting terms mean

These quantities answer different questions and should not be used interchangeably.

| Quantity | Unit | What it describes | Relevance at Ngulia |
|---|---:|---|---|
| Electrical power | watt (W) or kilowatt (kW) | Electricity consumed by the lamp | Important for the generator, wiring, heat and cost. It does **not** state brightness across lamp technologies. |
| Luminous flux | lumen (lm) | Total visible output weighted for the average human daylight eye | Better than watts for a first engineering comparison, but still not a bird-effective dose. |
| Luminous efficacy | lm/W | Human-visible output per electrical watt | Explains why a 250 W LED can emit as many human-weighted lumens as several kW of halogen. |
| Illuminance | lux (lx = lm/m²) | Human-weighted light arriving at a surface | Useful for mapping the light field at fixed locations and distances. It changes with beam, angle and distance. |
| Luminous intensity | candela (cd) | Human-weighted output in a particular direction | Useful for comparing narrow and broad beams and estimating how far a beam remains conspicuous. |
| Irradiance | W/m² | Radiant energy arriving at a surface, without human spectral weighting | Better for cross-colour physical comparison, but still needs spectral information for avian perception. |
| Spectral power distribution | SPD; power by wavelength | How much ultraviolet, blue, green, yellow, red and infrared radiation is emitted | The most informative description of colour for biological work. |
| Correlated colour temperature | kelvin (K) | A one-number description of how warm/yellow or cool/blue a white light appears to humans | Useful shorthand, but two 5000 K lamps can have different spectra. It is not a wavelength and not a biological effect size. |
| Beam angle and upward-light fraction | degrees and % | Where the light goes | Critical: a broad or upward-directed beam illuminates more mist and sky than the same lumens aimed steeply downward. |
| Temporal pattern | Hz, flashes/min, duty cycle | Whether output is steady, flickering or flashing, and how long it is on | Birds can perceive temporal modulation differently from humans. “No visible flicker” is not enough; driver flicker should be measured. |

For reference, the European Commission gives typical tungsten-halogen efficacy as **12–20 lm/W**. White LEDs are generally much more efficient, which is why electrical wattage is a poor conversion basis. Luminous flux itself is formally weighted by human visual sensitivity, so it is also incomplete for avian work ([European Commission light-source overview](https://energy-efficient-products.ec.europa.eu/product-list/light-sources_en); [definition in EU Regulation 244/2009](https://eur-lex.europa.eu/legal-content/EN/ALL/?uri=CELEX%3A32009R0244)).

## 2. Ngulia setting

Ngulia Safari Lodge is near the top of an east-facing escarpment, below the Ngulia ridge. Its north-facing floodlights make an isolated illuminated volume where low cloud frequently descends to lodge level during the short rains. The original lights illuminated game-drinking pools on the northern side of the lodge; night nets and, later, dawn nets were positioned within this broader setting.

The early observations establish the field mechanism: birds often appear within an hour of mist arriving; rain is not required, but attraction is weak on clear nights and near full moon. In very thick mist, illuminated walls can create collision or exhaustion risk. Catch remains an index of a fall, because birds can remain aloft, settle outside nets, escape capture, or overwhelm handling capacity. These statements come from [Pearson & Backhurst (1976)](<../../data/02_reference/publications/pdfs/Pearson_Backhurst___1976___The_Southward_Migration_of_Palaearctic_Birds_Over_Ngulia_Kenya.pdf>) and [Pearson, Backhurst & Jackson (2014)](<../../data/02_reference/publications/pdfs/149917_394216_1_SM.pdf>). The dated operational history and its catch implications are in the [daily covariate configuration](../daily_covariates.md) and `operations_history.csv`.

## 3. Evidence from experiments and comparative studies

The table emphasises studies that manipulate light or offer an unusually informative on/off comparison. Outcomes differ—calls, visual reactions, thermal-camera tracks, mist-net captures or carcasses—so effect sizes are not directly comparable.

| Study and setting | Light setup | Design and response | Main result | Relevance/caveat for Ngulia |
|---|---|---|---|---|
| [Evans et al. 2007](https://sora.unm.edu/sites/default/files/journals/nab/v060n04/p00476-p00488.pdf), rural New York, migrants flying in ground-level cloud | Pair of commercial tungsten-halogen work luminaires, **1,500 W total** (each luminaire had 250 + 500 W lamps), UV-filtering glass; white or red/green/blue filters; skyward, ~20° from zenith | Alternating 10–35 min treatments and darkness; acoustic flight calls plus visual observation. Flashing white was compared with steady white; the paper reports approximately 24 flashes/min with short on-time. | Aggregation under steady white, blue and green; not under red or flashing white in the tested conditions. | Strong environmental analogy to Ngulia and similar halogen power. Filters changed both spectrum and physical output; calls are an activity index and miss silent species. The authors caution elsewhere that stronger red sources may still attract. |
| [Poot et al. 2008](https://tethys.pnnl.gov/sites/default/files/publications/Poot-et-al-2008.pdf), Ameland, Netherlands | Two identical **1,000 W metal-halide** lamps on a 4.8 m post, directed NE at 110° toward sky; red, green, blue and opaque white Perspex filters | 45 min colour periods separated by 15 min darkness over 41 autumn nights; visual classification of reaction at ~10–100 m | White and red produced the strongest reactions; green less; blue least. Effects strongest under overcast. | Often cited for “bird-friendly green,” but conflicts with Evans, Rebke and Zhao. Metal-halide plus filters is not equivalent to narrow-band LEDs, and visible observations excluded higher birds. |
| Platform manipulation reported within [Poot et al. 2008](https://tethys.pnnl.gov/sites/default/files/publications/Poot-et-al-2008.pdf), North Sea gas platform L5 | Partial groups from 300 W safety lights to full **30 kW**, mostly fluorescent tubes and sodium floodlights; different directions | Opportunistic two-night on/off and partial-light observations | About 200–250 birds after 7 min on, 4,000–5,000 after 30 min; all dispersed within 15 min off. More power and upward-directed light were associated with more birds; estimated full-light influence 3–5 km. | Strong demonstration of rapid reversibility and combined power/direction effect, but not a replicated randomized experiment and much brighter than Ngulia. |
| [Gehring et al. 2009](https://doi.org/10.1890/07-1708.1), 24 Michigan communication towers | Red or white flashing-only systems versus towers combining flashing and steady red obstruction lights | Simultaneous carcass searches during two 20-day migration periods | 3.7 fatalities/tower/season with flashing-only versus 13.0 with steady + flashing at 116–146 m towers; estimated 50–71% reduction by removing steady lights. | Supports eliminating steady components where the objective is conservation. Tower height and guy wires create collision mechanisms unlike Ngulia's low floodlights and nets, so mortality ratios should not be transferred directly. |
| [Van Doren et al. 2017](https://doi.org/10.1073/pnas.1708574114), New York “Tribute in Light” | Two intense vertical arrays, 88 xenon searchlights in total | Weather radar, acoustic monitoring and 22 short shutdowns over seven nights in seven years | Illumination increased local density, slowed and circularised flight and increased calling; responses disappeared during shutdowns. Effects extended up to 4 km altitude, including under clear skies. | Establishes that sufficiently intense upward beams can alter migration even without fog. Installation is orders of magnitude brighter and embedded in an urban lightscape. |
| [Rebke et al. 2019](https://doi.org/10.1016/j.biocon.2019.02.029), Sylt, North Sea | Two Futurelight OFL-72 K2 RGB **LED** spotlights <1 m apart; 50° beam aimed 45° upward toward sea. Treatments matched to **6,800 lx** full or **3,400 lx** half at 1 m | Twenty randomized treatments: red/yellow/green/blue/white × full/half × continuous/flashing; 15 min treatment + 15 min dark; flashing 1 s on/1 s off (30/min); thermal cameras | Under starless/overcast conditions, continuous green, blue and white attracted more birds than continuous red. Continuous generally exceeded flashing. No detectable full-versus-half difference and no blinking colour differed from darkness. | Best factorial field test separating colour, intensity and flashing. Only a twofold intensity contrast was tested, the beam was narrow/upward, and equal lux does not mean equal avian-effective brightness across colours. |
| [Zhao et al. 2020](https://doi.org/10.1093/condor/duaa002), two fog-prone mountain passes in Yunnan | Directional LED, 0.5 m behind a 12 m mist net; each **100 W**: red 620 nm, yellow polychromatic 2000 K, green 520 nm, blue 455 nm | One colour continuously for 1 h in rotated order, 20:00–24:00; mist-net captures in 2017–2018 | Relative to red, catches were 3.5× under yellow, 4.7× green and 7.8× blue. Fog and headwind had very large positive effects. | Closest published biological/operational analogy to Ngulia: isolated mountain light, fog and nets. Equal electrical watts did not equalise photons, radiance, lux or bird-effective brightness; capture combines attraction, flight height and net interception. |
| [Cabrera-Cruz et al. 2021](https://doi.org/10.1093/icb/icab154), rural Maryland | Low-rise, **downcast LED floodlights** in the blue-green portion of the spectrum | Repeated light-on/off design in spring/autumn; 1,501 reconstructed 3-D tracks and daytime captures | Turning reactions were more likely close to lights (~35 m in spring, ~50 m in autumn), especially with interactions involving poor visibility; daytime capture rates did not differ on/off. | Shows that even downcast low-rise lights can alter nearby flight. Subtle track changes did not translate into greater daytime capture, so flight response and grounding/catch must be measured separately. |
| [Horton et al. 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10696060/), contiguous United States | Satellite-derived **skyglow**, rather than a single experimental lamp | Radar-derived stopover density from 142 weather radars in 2016–2020; 49 environmental predictors and 2,500 spatial models | Skyglow was among the strongest predictors and was positively associated with stopover density in more than 70% of models. | Large-scale association, not proof that a particular lamp caused birds to land. It nevertheless shows that illuminated landscapes can redistribute stopover density and may act as ecological traps. |
| [Osterhaus et al. 2025](https://pubs.usgs.gov/publication/70273994), White Sands Missile Range, New Mexico | Ordinary pole and floodlighting at lit sites, averaging **30.44 lx** at recorders versus **0.06 lx** at dark sites; sites varied in shielding and dominant wavelength | 103,424 recording hours and 2.85 million nocturnal flight calls over three autumn migrations during non-inclement weather | Call rates were lower at lit sites, especially early in the season, and increased more rapidly through the night there. Lit sites with more shielded fixtures or longer dominant wavelengths (warmer light) resembled dark sites more closely. | Extends evidence beyond spectacular beams and bad weather. Calls are behaviour, not bird counts or tracks, and ground-level lux does not quantify what an airborne bird sees. Shielding and upward exposure need explicit measurement. |
| [Jimenez et al. 2026](https://doi.org/10.1002/jwmg.70279), remote northern Colorado | Two **800 W LED floodlights**; white, red, amber and blue treatments | 31 autumn nights in 2023–2024; vertical-looking radar compared paired dark and illuminated periods for traffic rate, flight height and direction | No detectable effect on migration traffic rate and only weak directional effects. Broad-spectrum white light (emission across 400–600 nm) reduced mean flight height by **22.57 m ± 10.53 SE** relative to darkness; this response was stronger than under red and blue. | The most recent controlled spectral experiment from the group and directly relevant to LED choice. It shows behavioural descent without an increase in passage rate. The high-output, point-source rural installation and North American species assemblage still differ from Ngulia. |
| [Alaasam et al. 2018](https://pmc.ncbi.nlm.nih.gov/articles/PMC6205889/), captive zebra finches | White LED **3000 K** or **5000 K**, both held at **0.3 lx** at perch level, versus dark control | Two weeks of nightly exposure; activity and corticosterone | 5000 K increased nocturnal activity and corticosterone; 3000 K did not differ from dark controls for nocturnal activity in this experiment. | Not an attraction experiment, but warns that equal lux at cool versus warm CCT can have different physiological effects. Exposure was dim and chronic, unlike Ngulia's short, bright field use. |

Three synthesis papers set the broader context. [Adams et al. (2021)](https://doi.org/10.1186/s13750-021-00246-8) screened 26,208 records and mapped 490 eligible studies of bird movement/distribution, finding strong concentration in northern locations, selected taxa and red/white light, plus highly heterogeneous outcomes and reporting. [Burt et al. (2023)](https://www.sciencedirect.com/science/article/pii/S0169534722003329) review effects across spatial scales and emphasise that attraction, orientation, altitude, collision and stopover are related but distinct responses. A 2026 meta-analysis of 675 effect sizes from 36 studies and 30 species found consistent changes in avian physiology and behaviour, stronger effects in migratory species and stronger sleep/activity effects at brighter exposures, while effects on life-history traits were not consistently detected ([Diaz-Palma et al. 2026](https://doi.org/10.1111/ele.70382)). The meta-analysis is broader than migration attraction and its literature search ended in February 2023.

## 4. What the evidence says about each light variable

### 4.1 Presence, duration and switching

This is the clearest variable. Strong isolated light can cause rapid aggregation; switching off can produce rapid dispersal. This is seen at the L5 platform, Tribute in Light and in the alternating field experiments. At Ngulia, electrical failures and the 2023 generator delays also demonstrate that “light available” is part of nightly sampling effort.

Implications:

- record exact on/off times, not merely “lights used”;
- use separate switches and energy meters for each fixture;
- define emergency shutdown rules for unsafe aggregations, collisions, heavy rain, overwhelmed nets or insufficient staff;
- avoid leaving experimental attraction lighting on when nets/observers are not operating unless that exposure is an explicit, ethically approved treatment.

### 4.2 Power, lumens, intensity and dose

Evidence that more light produces more response exists, but the shape of the dose-response curve is unknown and may saturate. Ngulia's 1984 experience and the platform observations point in the same direction. Rebke et al. found no difference between 3,400 and 6,800 lx at 1 m, but that twofold contrast may have fallen on a saturated part of the response curve. Jimenez et al. (2026) also show that a light can alter flight height without changing migration traffic rate, so the response being measured must always be stated.

Four levels should be kept distinct:

1. **Input:** electrical watts and voltage at the lamp.
2. **Output:** lumens, spectral radiant flux and beam distribution at the fixture.
3. **Exposure:** lux and spectral irradiance in the field at relevant heights/distances and in mist.
4. **Biological dose:** the light received by a bird over time as it approaches, circles, descends or rests.

At minimum Ngulia should measure a fixed lux grid, for example at each lamp and along north/northeast transects at 5, 10, 25, 50 and 70 m, at ground level and approximately 1.5–2 m height. Measurements should be repeated for each light combination, with lamp aim and height recorded. A spectrometer measurement at one or more standard locations is needed at commissioning and after lamp replacement.

### 4.3 Colour and spectrum

There is no defensible universal ranking such as “green is bird-friendly” or “red is always safe.” The field evidence splits:

- Poot et al. found strongest reactions to white/red and least to blue.
- Evans et al., Rebke et al. and Zhao et al. found little response to red and greater response to blue/green/white under their tested conditions.
- Jimenez et al. found no colour effect on traffic rate, but broad-spectrum white light spanning 400–600 nm lowered mean flight height by about 23 m relative to darkness and produced a stronger altitude response than red or blue.
- Magnetic-compass experiments show that wavelength and intensity interact: European robins can orient under dim blue-green light, may become disoriented under yellow/red, and can show abnormal fixed directions under brighter blue-green light. These are orientation-cage results, not direct attraction tests ([Wiltschko & Wiltschko 1995](https://doi.org/10.1007/BF00192425); [Wiltschko et al. 2007](https://pmc.ncbi.nlm.nih.gov/articles/PMC1810254/)).

Possible reasons for disagreement include species composition, lamp/filter spectra, unequal photon flux, different beam geometry, weather, background light, outcome measurement and nonlinear intensity effects.

For Ngulia:

- record or measure full SPD from at least 350–750 nm; include UV if the cover/optic transmits it;
- do not treat CCT as spectrum;
- do not compare colours at equal electrical watts only;
- if testing colour, report lux, irradiance or photon flux, beam and an avian-vision-weighted metric alongside raw SPD;
- test warm versus cool **white** first if the operational goal requires people to see and handle birds safely; narrow monochromatic treatments can answer mechanism questions but are less direct operational replacements.

### 4.4 Halogen versus LED

“Halogen versus LED” bundles several differences:

| Property | Tungsten-halogen | Typical phosphor-converted white LED | Consequence for Ngulia |
|---|---|---|---|
| Spectrum | Smooth warm continuum, much energy in red/infrared; some UV may be blocked by glass | Blue pump peak plus broader phosphor band; amount of short-wave light generally increases with CCT | White LED is not a spectral replica of historical halogen. |
| Efficiency | Roughly 12–20 lm/W | Substantially higher than halogen for most modern white LEDs | LEDs greatly reduce generator load and heat for the same human-visible output. |
| Directionality | Bulb plus reflector; output and beam depend on housing/glass | Emitters and optics can make broad, asymmetric or tightly controlled beams | LEDs can reproduce geometry well only if the photometric distribution is chosen deliberately. |
| Dimming/switching | Simple but inefficient; colour becomes warmer when dimmed | Easy rapid control with a compatible driver; spectrum and flicker can change with dimming method | Independently dimmable fixtures are valuable experimentally; verify dimming behaviour and flicker. |
| Maintenance | Replaceable hot bulb; fragile; glass/filter condition matters | Long life, lower heat; some integrated sources/driver failures require whole-unit replacement | Prefer serviceable drivers or keep a compatible spare fixture. |

No experiment located here compares a historically matched Ngulia-like halogen array directly against white LED while holding spectrum, light field and temporal pattern constant. A technology label is therefore not a treatment definition.

### 4.5 Flashing, flicker and duty cycle

Field studies broadly agree that flashing-only light produces less aggregation or mortality than continuous light, especially under overcast conditions. But “flashing” spans very different exposures:

- Evans: brief flashes roughly two dozen times per minute;
- Rebke: 1 s on/1 s off, 30 flashes/min and 50% duty cycle;
- communication towers: aviation strobes or flashing incandescent beacons, compared with systems that also had steady-burning lamps.

For an attraction-and-ringing programme, flashing may reduce the phenomenon the project is trying to observe and could alter capture safety. It is therefore a useful experimental or emergency-reduction treatment, not an automatic operational recommendation. Separately, many LEDs have rapid driver flicker invisible to people. Measure flicker percentage/modulation depth and frequency with a flicker meter or photodiode; do not infer “continuous” from appearance.

### 4.6 Beam, direction, height and illuminated surfaces

Beam geometry may be as important as total output. Upward-directed light can influence migrants over long distances, while Cabrera-Cruz et al. show that downcast light can still alter flight nearby. Osterhaus et al. found that lit sites with more shielding produced flight-call patterns closer to dark sites. At Ngulia, mist scatters light in many directions, so a nominally horizontal or downcast beam can create a diffuse glow.

The historical placement north of the lodge should be treated as part of the sampling design. Avoid illuminating pale walls, windows, railings or other collision surfaces. Map the beam in both clear and misty conditions, photograph each lamp from fixed ground points, and also document the installation from an **aerial bird's perspective** where safe and permitted—for example with an elevated camera, drone or tethered balloon. Record mounting coordinates, height, compass bearing, tilt, beam type, shielding and nearby vegetation every season. A ground lux map alone can miss upward radiation visible to migrants.

### 4.7 Weather, moon and migration traffic are effect modifiers, not nuisances

Ngulia's archive and external studies agree that cloud/fog and moon/starlight modify attraction. Headwinds also had a large effect in Zhao et al. The same light treatment can therefore produce no catch on a clear night and a major fall in low mist without any change in lamp performance.

Light evaluation must be conditional on:

- objective visibility or meteorological optical range, cloud base and observer mist category;
- rainfall and humidity;
- wind speed/direction relative to expected migration;
- moon altitude, illuminated fraction and whether obscured;
- time since sunset and time within the migration season;
- independent migration activity aloft, ideally radar, thermal video or nocturnal flight calls.

Without an independent measure of passage, a small catch cannot distinguish “few birds migrating” from “many birds present but weakly attracted.”

## 5. Recommended direction for Ngulia

### 5.1 Immediate priority: establish the actual baseline

Before buying or standardising lamps, complete a one-page inventory for every fixture and driver:

- stable lamp ID and photographs of front, rear, label, driver and plug;
- manufacturer, model/item number, serial number and acquisition year;
- rated and measured watts, lumens, CCT, CRI, SPD, beam angle and photometric file;
- dimming/control method and measured flicker;
- mounting position, height, bearing and tilt;
- cable, circuit and generator assignment;
- observed faults, replacement dates and hours used.

Also search non-digitised team material—field notebooks, old photographs, purchase records and emails—for 2016–2026 lamp changes. The current gap is documentary, not necessarily operational.

### 5.2 Procurement options and indicative budget

The figures below are market indications checked in September 2026, not quotations. They exclude delivery to Ngulia, mounting, cables, controls, protection, installation, tax and import charges. Many inexpensive lamps advertise watts and IP rating but provide no reliable photometry, spectrum, dimming behaviour or flicker data.

| Route | Published price indication | Advantages | Main limitations for Ngulia |
|---|---:|---|---|
| **Buy commodity LED in Kenya** | Published 200–300 W examples range from **KSh 2,400 to KSh 9,495 each**, or approximately **KSh 7,200–28,500 for three heads** ([ATTA 200 W](https://skywave.co.ke/atta-200w-led-flood-light-ip66/); [Tronic 200 W](https://www.tronic.co.ke/products/200w-led-floodlight-ultra-bright-water-proof-day-light); [Liper 300 W](https://myredrhino.com/products/liper-300w-led-floodlight-6500k-daylight-ip66)). | Cheap, locally replaceable and easy to transport; typically IP66 and 220–240 V. | Examples are cool white, often non-dimmable, and may lack verified SPD, IES/LDT files, low-flicker data or long warranties. Suitable for preliminary engineering tests, not automatically for the scientific standard. |
| **Buy professional LED in Kenya** | **Quotation required.** [Nairobi Power Engineers](https://nairobipower.co.ke/products/lighting-luminaires/index.html) lists 50–1000 W IP66 floodlights, photometric design and optional 0–10 V/DALI control but does not publish prices. | Local warranty, installation support, easier spares and no international freight; potential to arrange a demonstration. | The published range starts at 4000 K; availability of 2700–3000 K, full SPD and suitable broad-beam optics must be confirmed. |
| **Buy professional LED in Europe** | Published 150–300 W, 3000 K, IP66 professional examples are roughly **€378–€1,580 each**, or **€1,130–€4,740 for three**, before freight and import costs ([MAS Lighting price list](https://maslighting.com/wp-content/themes/base/catalogos/TARIFA-GENERAL-CAT%C3%81LOGO-V1-MASLIGHTINGLED-24-25.pdf); [Integratech 300 W DALI](https://integratech.be/fr/produits/projecteurs-led/integrasports-2/itsp2-300w-45gr-3000k-ip66-ik10-dali-gris)). | Better access to warm-white, DALI/0–10 V control, documented optics, surge ratings and manufacturer photometry. | Higher landed cost, customs and freight uncertainty, harder warranty service in Kenya, and the risk of dependence on European spares. |
| **Retain or refurbish halogen for overlap** | European 1.5 kW R7s replacement lamps are advertised from about **€5 to €90 each**; complete specialist 1 kW IP65 fittings can be about **€322 each** ([France Lampes](https://www.francelampes.com/en/518-r7s-quartz-double-based-230v-1500w-254mm-halogen-2000h-8421389815054.html); [Multi-Lite](https://www.multi-lite.com/de/15030r-1500w-240v-r7s/item-1-12127.html); [Zevtex fitting](https://www.zevtex.nl/product/zevtex-1000-watt-halogen-floodlight/)). | Best continuity with the historical series and valuable as a one-season calibration reference. | Very high load and heat, short lamp life, fragile bulbs and declining availability. It does not solve the generator constraint and should not be the preferred long-term system. |
| **Rent in Kenya** | Monthly scientific-equipment price not published; obtain quotations. As a non-comparable event-market reference, Sherehe advertises generic floodlights at **KSh 3,000 each for eight hours** ([listing](https://shereheevents.co.ke/hire/pacan-lighting/flood-lights)). | Avoids ownership and storage; rental firms can supply cables, stands, spares and generators. | Event-day pricing becomes uneconomic over a month unless a seasonal rate is negotiated. Film/event lights may lack weather protection, suitable spectrum or unattended-duty approval. |
| **Annual loan or sponsored partnership** | Potentially little or no equipment charge; transport, installation, insurance and damage responsibilities still need a budget. | A manufacturer or supplier can provide matched demonstration units, technical files and replacements while gaining a credible conservation/research partnership. | Requires advance negotiation, a written loan agreement and assurance that the same model remains available in future years. Sponsorship must not determine the scientific comparison or interpretation. |

Potential Kenyan contacts, in suggested order, are:

1. **[Signify Kenya / Philips Lighting](https://www.signify.com/en-ke/contact)** — strongest manufacturer-level prospect for a demonstration loan or sponsorship; `Customercare.africa.lighting@philips.com`, +254 20 4214000 / +254 724421400.
2. **[Nairobi Power Engineers](https://nairobipower.co.ke/products/lighting-luminaires/index.html)** — strongest local technical prospect for professional IP66 floodlights, dimming and photometric design; `sales@nairobipower.co.ke`, +254 737 944014.
3. **[Kenya Grip & Sparks Lighting](https://grip-sparks.com/about-us/)** — established East African lighting and generator rental company; `hires@gripandsparks.co.ke`, +254 721 247423. Ask specifically about IP-rated continuous-duty fixtures rather than film lights generally.
4. **[LEDCO Kenya](https://www.ledco.co.ke/)** — Nairobi and Mombasa industrial/outdoor-lighting distributor; +254 722 206061 / +254 736 613711. Ask for a demonstration set and manufacturer photometric files.
5. **[Masterpiece Electricals](https://www.masterpiece.co.ke/services/lighting-security)** — experienced in high-power outdoor and high-mast installations, including BATUK projects; `info@masterpiece.co.ke`, +254 705 935858. More likely to support sourcing and installation than short-term rental.

The preferred sequence is: request a **six-week renewable annual loan** from Signify and Nairobi Power; request a parallel monthly rental quotation from Grip & Sparks; then compare those offers with a Kenyan professional purchase. Buy from Europe only if the Kenyan offers cannot provide three matched, independently dimmable, IP65/IP66 fixtures with suitable warm-white output, documented beam files and serviceable spares.

Budget separately for three stable mounts, outdoor cable and connectors, distribution and protection, individual switching/dimming, one spare fixture or driver, a power logger, delivery to Tsavo and electrician time. These supporting items are required whichever procurement route is chosen and should not be hidden inside the lamp price.

### 5.3 Preferred strategy: a measured, reversible LED transition

Use **three independently controlled positions** corresponding as closely as practical to the 2013–2015 array. This preserves source number and geometry while allowing gradual substitution.

Suggested commissioning sequence:

1. **Historical reference:** reassemble the 1.5 + 1 + 1 kW halogen array if the equipment remains safe and legally obtainable. Measure its electrical load, clear-night lux grid, SPD, flicker and beam photographs. It need not remain the long-term operational system; it is the calibration reference.
2. **Warm-white LED treatment:** procure or borrow dimmable outdoor floodlights, preferably 2700–3000 K with documented low short-wave output, in three units with suitable beam control. Warm-white is a conservative starting point for physiological disturbance, not a proven best attractant. Osterhaus et al. (2025) provide field support that warmer, better-shielded installations can behave more like dark sites, but that study did not test Ngulia-style attraction or catches.
3. **Cool-white comparison:** compare a documented cool-white LED treatment at the same measured light field so that output is not confounded with spectrum.
4. **Match the field, not the watts:** tune output to minimise differences from the reference lux grid and illuminated footprint. Retain raw differences where exact matching is impossible and include them in analysis.
5. **Keep changes reversible:** separate switches, logged dimming values, fixed mounts and a complete spare unit. Do not mix lamp types without logging each lamp's state.

### 5.4 A realistic first experiment

A useful first experiment should estimate operational performance without sacrificing an entire season to too many treatments. One possible hierarchy is:

- **Primary comparison:** historical halogen reference versus field-matched warm-white LED.
- **Secondary comparison:** warm-white versus cool-white LED at a matched measured light field.
- **Exploratory comparison:** continuous versus a pre-defined flashing regime, only after continuous LED performance and extraction safety are understood.

Randomising short blocks within mist events is efficient but has carry-over risk because birds accumulated by one treatment may remain nearby during the next. A defensible design would use randomized 15–30 min treatment blocks separated by dark or low-light washout periods, while directly observing aerial birds with thermal cameras or flight calls. Catch should be analysed as a downstream response, not the sole attraction measure. Alternatively, use longer randomized night-level treatments across many comparable mist events; this reduces within-night carry-over but needs more seasons and stronger control of migration intensity. Jimenez et al. (2026) reinforce the value of recording an aerial response as well as catch because flight height changed even though traffic rate did not.

Minimum interval log, preferably every 15 minutes and at every state change:

- lamp IDs, on/off state, dimming, faults and measured power;
- visibility/MOR, cloud base/category, rain, humidity, wind and temperature;
- moon altitude/fraction/obscuration;
- aerial birds or flight calls, circling/landing/collisions and insects;
- net IDs open, net-metre-hours, closures and extraction capacity;
- captures by species and net/time interval;
- safety interventions and reason.

The causal sequence to keep explicit is:

> migration aloft → exposure to illuminated mist → attraction/flight change → descent and grounding → encounter with habitat and nets → capture and processing.

### 5.5 Safety and ethics

The purpose of Ngulia differs from a normal light-pollution mitigation project: attraction is deliberately used to study and ring migrants. That makes proportionality, monitoring and shutdown criteria especially important.

- Point beams away from pale lodge walls, windows and hard obstacles.
- Retain a rapid all-off control at the ringing station.
- Define maximum safe bird density/capture rate based on team capacity.
- Stop or reduce attraction if birds are striking structures, accumulating without safe landing habitat, becoming soaked/exhausted, or if extraction queues grow.
- Treat insects and non-target birds as monitored outcomes.
- Include the lighting experiment and response rules in permits and ethical review.

## 6. Practical questions for the Ngulia team

These questions determine whether the next step should be historical replication, operational replacement or a formal experiment.

### Purpose

1. Is the primary objective to maximise safe ringing catch, maintain comparability with the long time series, understand attraction mechanisms, reduce bird impacts, or balance all four?
2. What outcome would define a “good” replacement: similar aerial aggregation, similar grounding footprint, similar catch per mist event, lower collision rate, lower generator load, or some combination?
3. Is there appetite and permit coverage for randomized light treatments, including temporary darkness?

### Existing equipment and site

4. Which halogen lamps, tripods, reflectors, bulbs, glass covers and cables still exist, and can the 2013–2015 array be safely reconstructed for calibration?
5. Can the exact three historical coordinates, bearings and tilts be recovered from photographs or experienced team members?
6. What are the generator's continuous and peak kVA ratings, normal non-lighting load, fuel use, voltage stability and recent outage history?
7. Which breaker, cable and connector supplies each historical lamp position, and can each position be protected, metered and switched independently?
8. Can the proposed LED drivers be dimmed without introducing severe flicker, nuisance tripping or excessive inrush current?

### Measurement and design

9. Can the project obtain or borrow a calibrated lux meter, portable spectrometer, flicker meter, power logger and thermal camera for one commissioning season?
10. Can an independent passage index—vertical radar, thermal imaging or nocturnal flight-call recording—run whenever light treatments are compared?
11. Should comparison aim to match total lumens, lux at selected points, illuminated mist volume, or catch? The recommendation here is a measured spatial light field plus spectrum, with catch kept as an outcome.
12. What warm-white/low-blue fixture with suitable IP rating, beam control, dimming and locally serviceable spare parts is realistically procurable in Kenya or Switzerland?

### Operations, welfare and continuity

13. What are the explicit thresholds for reducing or extinguishing lights when nets or teams approach capacity?
14. How will lamp failures, partial arrays and generator outages be encoded in the long-term dataset?
15. Is at least one season of overlap between historical halogen and the proposed LED standard feasible? Without overlap, future catch trends will confound population change with an unmeasured observation-process change.
16. Who will own the annual light inventory and ensure that bulbs, drivers, mounting and calibration changes enter the session report?

## 7. Proposed decision rule

Until field measurements are available:

- **Do not call any LED a direct replacement for the 3.5 kW halogen array.**
- Do not order lamps until generator headroom, voltage stability, circuits, cables, protection and earthing have been documented.
- Prefer three controllable fixtures over one or two very bright fixtures when continuity of geometry matters.
- Seek a Kenyan demonstration loan or professional quotation before importing; require identical models, photometric files, spectral information, dimming details and local spare support.
- If equipment must be chosen immediately, three dimmable, broad-beam, IP65-or-better warm-white LED floodlights with documented SPD and field-replaceable drivers are a more defensible starting architecture than a single integrated high-bay unit.
- Retain enough output headroom to match the historical field, but achieve the final setting by measurement and a biological pilot, not by running every fixture at full power.

The most valuable result of the next season would not be a single “winning” lamp. It would be a calibrated relation among lamp state, measured light field, weather, aerial migration, behaviour, grounding and catch. That would protect the historical value of Ngulia and turn an unavoidable technology transition into a publishable experiment.

## References

### Ngulia archive

- Pearson, D. J. & Backhurst, G. C. (1976). The southward migration of Palaearctic birds over Ngulia, Kenya. [Local PDF](<../../data/02_reference/publications/pdfs/Pearson_Backhurst___1976___The_Southward_Migration_of_Palaearctic_Birds_Over_Ngulia_Kenya.pdf>).
- Pearson, D., Backhurst, G. & Jackson, C. (2014). Palaearctic birds at Ngulia Lodge, Tsavo, Kenya 1969–2012. [Local PDF](<../../data/02_reference/publications/pdfs/149917_394216_1_SM.pdf>).
- Pearson, D. (2016). Ringing and observation of migrants at Ngulia Lodge, 2013–2015. [Local PDF](<../../data/02_reference/publications/pdfs/ajol_file_journals_523_articles_139731_submission_proof_139731_6157_372749_1_10_20160718.pdf>).
- Ngulia Ringing Group annual reports. [Report directory](<../../data/02_reference/reports/>).
- Related planning note: [Future Ngulia protocol and standardisation](../planning/field_protocol.md).

### External research and technical sources

- Adams, C. A., Fernández-Juricic, E., Bayne, E. M., et al. (2021). Effects of artificial light on bird movement and distribution: a systematic map. *Environmental Evidence*, 10, 37. [DOI](https://doi.org/10.1186/s13750-021-00246-8).
- Alaasam, V. J., Duncan, R., Casagrande, S., et al. (2018). Light at night disrupts nocturnal rest and elevates glucocorticoids at cool color temperatures. *Journal of Experimental Zoology Part A*, 329, 465–472. [Open article](https://pmc.ncbi.nlm.nih.gov/articles/PMC6205889/).
- Burt, C. S., Kelly, J. F., Trankina, G. E., et al. (2023). The effects of light pollution on migratory animal behavior. *Trends in Ecology & Evolution*, 38, 355–368. [Publisher page](https://www.sciencedirect.com/science/article/pii/S0169534722003329); [PubMed record](https://pubmed.ncbi.nlm.nih.gov/36610920/).
- Cabrera-Cruz, S. A., Larkin, R. P., Gimpel, M. E., et al. (2021). Potential effect of low-rise, downcast artificial lights on nocturnally migrating land birds. *Integrative and Comparative Biology*, 61, 1216–1236. [DOI](https://doi.org/10.1093/icb/icab154).
- Diaz-Palma, S., Capilla-Lasheras, P., Dominoni, D., Cichoń, M. & Sudyka, J. (2026). Artificial light at night consistently impacts avian physiology and behaviour: a meta-analysis. *Ecology Letters*, 29, e70382. [DOI](https://doi.org/10.1111/ele.70382).
- Evans, W. R., Akashi, Y., Altman, N. S. & Manville, A. M. II (2007). Response of night-migrating songbirds in cloud to colored and flashing light. *North American Birds*, 60, 476–488. [Full text](https://sora.unm.edu/sites/default/files/journals/nab/v060n04/p00476-p00488.pdf).
- Gaston, K. J., Davies, T. W., Bennie, J. & Hopkins, J. (2012). Reducing the ecological consequences of night-time light pollution: options and developments. *Journal of Applied Ecology*, 49, 1256–1266. [Open article](https://pmc.ncbi.nlm.nih.gov/articles/PMC3546378/).
- Gehring, J., Kerlinger, P. & Manville, A. M. II (2009). Communication towers, lights, and birds: successful methods of reducing the frequency of avian collisions. *Ecological Applications*, 19, 505–514. [DOI](https://doi.org/10.1890/07-1708.1).
- Horton, K. G., Buler, J. J., Anderson, S. J., et al. (2023). Artificial light at night is a top predictor of bird migration stopover density. *Nature Communications*, 14, 7446. [Open article](https://pmc.ncbi.nlm.nih.gov/articles/PMC10696060/).
- Jimenez, M. F., Adams, C. A., Burt, C. S., et al. (2026). White light reduces flight height of birds in low-density migration corridor. *The Journal of Wildlife Management*, e70279. [DOI](https://doi.org/10.1002/jwmg.70279); [publisher PDF](https://wildlife.onlinelibrary.wiley.com/doi/pdf/10.1002/jwmg.70279).
- Osterhaus, D. M., Boland, K. C., Lawson, A. J., et al. (2025). Nocturnal flight call monitoring reveals in-flight behavioral alteration by avian migrants in response to artificial light at night. *Biological Conservation*, 311, 111441. [USGS record](https://pubs.usgs.gov/publication/70273994); [DOI](https://doi.org/10.1016/j.biocon.2025.111441).
- Poot, H., Ens, B. J., de Vries, H., et al. (2008). Green light for nocturnally migrating birds. *Ecology and Society*, 13(2), 47. [Full text](https://tethys.pnnl.gov/sites/default/files/publications/Poot-et-al-2008.pdf).
- Rebke, M., Dierschke, V., Weiner, C. N., Aumüller, R., Hill, K. & Hill, R. (2019). Attraction of nocturnally migrating birds to artificial light: the influence of colour, intensity and blinking mode under different cloud cover conditions. *Biological Conservation*, 233, 220–227. [DOI](https://doi.org/10.1016/j.biocon.2019.02.029).
- Van Doren, B. M., Horton, K. G., Dokter, A. M., et al. (2017). High-intensity urban light installation dramatically alters nocturnal bird migration. *PNAS*, 114, 11175–11180. [Open article](https://pmc.ncbi.nlm.nih.gov/articles/PMC5651764/).
- Wiltschko, W. & Wiltschko, R. (1995). Migratory orientation of European robins is affected by the wavelength of light as well as by a magnetic pulse. *Journal of Comparative Physiology A*, 177, 363–369. [DOI](https://doi.org/10.1007/BF00192425).
- Wiltschko, R., Stapput, K., Bischof, H.-J. & Wiltschko, W. (2007). Light-dependent magnetoreception in birds: increasing intensity of monochromatic light changes the nature of the response. *Frontiers in Zoology*, 4, 5. [Open article](https://pmc.ncbi.nlm.nih.gov/articles/PMC1810254/).
- Zhao, X., Zhang, M., Che, X. & Zou, F. (2020). Blue light attracts nocturnally migrating birds. *Ornithological Applications*, 122, duaa002. [DOI](https://doi.org/10.1093/condor/duaa002).

## Review limitations

This is a targeted review, not a registered systematic review. It prioritises field experiments and sources directly relevant to nocturnal migrant attraction, Ngulia-like fog and operational lighting. The literature was updated through 16 September 2026; Jimenez et al. (2026) was published online only nine days before that cut-off and should be checked again when final volume, issue and supplementary materials are available. The archive reconstruction is limited by what has been digitised in this repository. All proposed equivalences should therefore be replaced by field measurements before procurement or biological inference.
