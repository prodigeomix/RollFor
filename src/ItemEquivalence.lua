RollFor = RollFor or {}
local m = RollFor

if m.ItemEquivalence then return end

local M = {}
local function getn( t )
  if m.getn then return m.getn( t ) end
  if table.getn then return table.getn( t ) end
  local count = 0
  while t[ count + 1 ] do count = count + 1 end
  return count
end

-- Turtle WoW Tier sets with spec variants (Holy/Prot/Ret, Resto/Feral/Balance, etc.)
-- When players soft-reserve an item on raidres.top, they typically reserve the base Vanilla item ID.
-- On Turtle WoW, raid bosses drop spec-specific variants directly.
-- These equivalence groups map all spec variants for a given slot so soft-reserves,
-- rolls, and awarded loot match seamlessly regardless of which variant dropped.
-- Covers:
--   - Molten Core (Tier 1)
--   - Blackwing Lair & Onyxia (Tier 2)
--   - Temple of Ahn'Qiraj (Tier 2.5 / AQ40)
--   - Naxxramas (Tier 3 & Tier 3.5)
local groups = {
  --------------------------------------------------------------------------
  -- Tier 1 (Molten Core)
  --------------------------------------------------------------------------
  -- T1PaladinC
  { 16854, 47000, 47008 }, -- Lawbringer Helm, Lawbringer Helmet, Lawbringer Crown
  { 16856, 47001, 47009 }, -- Lawbringer Spaulders, Lawbringer Shoulderguards, Lawbringer Pauldrons
  { 16853, 47002, 47010 }, -- Lawbringer Chestguard, Lawbringer Chestguard, Lawbringer Chestplate
  { 16857, 47003, 47011 }, -- Lawbringer Bracers, Lawbringer Wristguards, Lawbringer Bindings
  { 16860, 47004, 47012 }, -- Lawbringer Gauntlets, Lawbringer Handguards, Lawbringer Gauntlets
  { 16858, 47005, 47013 }, -- Lawbringer Belt, Lawbringer Waistguard, Lawbringer Girdle
  { 16855, 47006, 47014 }, -- Lawbringer Legplates, Lawbringer Legguards, Lawbringer Leggings
  { 16859, 47007, 47015 }, -- Lawbringer Boots, Lawbringer Greaves, Lawbringer Sabatons
  -- T1PriestC
  { 16813, 47198 }, -- Circlet of Prophecy, Coronet of Prophecy
  { 16816, 47199 }, -- Mantle of Prophecy, Shoulderpads of Prophecy
  { 16815, 47200 }, -- Robes of Prophecy, Raiments of Prophecy
  { 16819, 47201 }, -- Vambraces of Prophecy, Bracers of Prophecy
  { 16812, 47202 }, -- Gloves of Prophecy, Handguards of Prophecy
  { 16817, 47203 }, -- Girdle of Prophecy, Sash of Prophecy
  { 16814, 47204 }, -- Pants of Prophecy, Pants of Prophecy
  { 16811, 47205 }, -- Boots of Prophecy, Sandals of Prophecy
  -- T1DruidC
  { 16834, 47330, 47338 }, -- Cenarion Helm, Cenarion Circlet, Cenarion Helmet
  { 16836, 47331, 47339 }, -- Cenarion Spaulders, Cenarion Mantle, Cenarion Shoulderpads
  { 16833, 47332, 47340 }, -- Cenarion Vestments, Cenarion Vest, Cenarion Raiments
  { 16830, 47333, 47341 }, -- Cenarion Bracers, Cenarion Wristbands, Cenarion Wristguards
  { 16831, 47334, 47342 }, -- Cenarion Gloves, Cenarion Handwraps, Cenarion Handguards
  { 16828, 47335, 47343 }, -- Cenarion Belt, Cenarion Sash, Cenarion Girdle
  { 16835, 47336, 47344 }, -- Cenarion Leggings, Cenarion Trousers, Cenarion Pants
  { 16829, 47337, 47345 }, -- Cenarion Boots, Cenarion Slippers, Cenarion Treads
  -- T1ShamanC
  { 16842, 47120, 47128 }, -- Earthfury Helmet, Earthfury Crown, Earthfury Visor
  { 16844, 47121, 47129 }, -- Earthfury Epaulets, Earthfury Pauldrons, Earthfury Epaulets
  { 16841, 47122, 47130 }, -- Earthfury Vestments, Earthfury Breastplate, Earthfury Raiments
  { 16840, 47123, 47131 }, -- Earthfury Bracers, Earthfury Bracelets, Earthfury Bindings
  { 16839, 47124, 47132 }, -- Earthfury Gloves, Earthfury Fists, Earthfury Gauntlets
  { 16838, 47125, 47133 }, -- Earthfury Belt, Earthfury Girdle, Earthfury Sash
  { 16843, 47126, 47134 }, -- Earthfury Legguards, Earthfury Leggings, Earthfury Legplates
  { 16837, 47127, 47135 }, -- Earthfury Boots, Earthfury Sabatons, Earthfury Greaves
  -- T1MageC
  { 16795, 47078 }, -- Arcanist Crown, Arcanist Circlet
  { 16797, 47079 }, -- Arcanist Mantle, Arcanist Epaulets
  { 16798, 47080 }, -- Arcanist Robes, Arcanist Vestments
  { 16799, 47081 }, -- Arcanist Bindings, Arcanist Wristbands
  { 16801, 47082 }, -- Arcanist Gloves, Arcanist Handwraps
  { 16802, 47083 }, -- Arcanist Belt, Arcanist Cord
  { 16796, 47084 }, -- Arcanist Leggings, Arcanist Trousers
  { 16800, 47085 }, -- Arcanist Boots, Arcanist Slippers
  -- T1WarlockC
  { 16808, 47276 }, -- Felheart Horns, Felheart Crown
  { 16807, 47277 }, -- Felheart Shoulder Pads, Felheart Mantle
  { 16809, 47278 }, -- Felheart Robes, Felheart Raiments
  { 16804, 47279 }, -- Felheart Bracers, Felheart Bindings
  { 16805, 47280 }, -- Felheart Gloves, Felheart Handwraps
  { 16806, 47281 }, -- Felheart Belt, Felheart Sash
  { 16810, 47282 }, -- Felheart Pants, Felheart Leggings
  { 16803, 47283 }, -- Felheart Slippers, Felheart Boots
  -- T1WarriorC
  { 16866, 47240 }, -- Helm of Might, Crown of Might
  { 16868, 47241 }, -- Pauldrons of Might, Pauldrons of Might
  { 16865, 47242 }, -- Breastplate of Might, Chestplate of Might
  { 16861, 47243 }, -- Bracers of Might, Bracers of Might
  { 16863, 47244 }, -- Gauntlets of Might, Gauntlets of Might
  { 16864, 47245 }, -- Belt of Might, Girdle of Might
  { 16867, 47246 }, -- Legplates of Might, Leggings of Might
  { 16862, 47247 }, -- Sabatons of Might, Sabatons of Might
  --------------------------------------------------------------------------
  -- Tier 2 (Blackwing Lair & Onyxia)
  --------------------------------------------------------------------------
  -- T2PaladinC
  { 16955, 47016, 47024 }, -- Judgement Crown, Judgement Helmet, Judgement Crown
  { 16953, 47017, 47025 }, -- Judgement Spaulders, Judgement Shoulderguards, Judgement Pauldrons
  { 16958, 47018, 47026 }, -- Judgement Breastplate, Judgement Chestguard, Judgement Chestplate
  { 16951, 47019, 47027 }, -- Judgement Bindings, Judgement Wristguards, Judgement Bindings
  { 16956, 47020, 47028 }, -- Judgement Gauntlets, Judgement Handguards, Judgement Gauntlets
  { 16952, 47021, 47029 }, -- Judgement Belt, Judgement Waistguard, Judgement Girdle
  { 16954, 47022, 47030 }, -- Judgement Legplates, Judgement Legguards, Judgement Leggings
  { 16957, 47023, 47031 }, -- Judgement Sabatons, Judgement Greaves, Judgement Sabatons
  -- T2PriestC
  { 16921, 47206 }, -- Halo of Transcendence, Coronet of Transcendence
  { 16924, 47207 }, -- Pauldrons of Transcendence, Shoulderpads of Transcendence
  { 16923, 47208 }, -- Robes of Transcendence, Raiments of Transcendence
  { 16926, 47209 }, -- Bindings of Transcendence, Bracers of Transcendence
  { 16920, 47210 }, -- Handguards of Transcendence, Handguards of Transcendence
  { 16925, 47211 }, -- Belt of Transcendence, Sash of Transcendence
  { 16922, 47212 }, -- Leggings of Transcendence, Pants of Transcendence
  { 16919, 47213 }, -- Boots of Transcendence, Sandals of Transcendence
  -- T2DruidC
  { 16900, 47346, 47354 }, -- Stormrage Cover, Stormrage Circlet, Stormrage Helmet
  { 16902, 47347, 47355 }, -- Stormrage Pauldrons, Stormrage Mantle, Stormrage Shoulderpads
  { 16897, 47348, 47356 }, -- Stormrage Chestguard, Stormrage Vest, Stormrage Raiments
  { 16904, 47349, 47357 }, -- Stormrage Bracers, Stormrage Wristbands, Stormrage Wristguards
  { 16899, 47350, 47358 }, -- Stormrage Handguards, Stormrage Handwraps, Stormrage Handguards
  { 16903, 47351, 47359 }, -- Stormrage Belt, Stormrage Sash, Stormrage Girdle
  { 16901, 47352, 47360 }, -- Stormrage Legguards, Stormrage Trousers, Stormrage Pants
  { 16898, 47353, 47361 }, -- Stormrage Boots, Stormrage Slippers, Stormrage Treads
  -- T2ShamanC
  { 16947, 47136, 47144 }, -- Helmet of Ten Storms, Crown of Ten Storms, Helmet of Ten Storms
  { 16945, 47137, 47145 }, -- Epaulets of Ten Storms, Pauldrons of Ten Storms, Spaulders of Ten Storms
  { 16950, 47138, 47146 }, -- Breastplate of Ten Storms, Breastplate of Ten Storms, Chestpiece of Ten Storms
  { 16943, 47139, 47147 }, -- Bracers of Ten Storms, Bracelets of Ten Storms, Bracers of Ten Storms
  { 16948, 47140, 47148 }, -- Gauntlets of Ten Storms, Fists of Ten Storms, Gloves of Ten Storms
  { 16944, 47141, 47149 }, -- Belt of Ten Storms, Girdle of Ten Storms, Belt of Ten Storms
  { 16946, 47142, 47150 }, -- Legplates of Ten Storms, Leggings of Ten Storms, Pants of Ten Storms
  { 16949, 47143, 47151 }, -- Greaves of Ten Storms, Sabatons of Ten Storms, Boots of Ten Storms
  -- T2MageC
  { 16914, 47086 }, -- Netherwind Crown, Netherwind Circlet
  { 16917, 47087 }, -- Netherwind Mantle, Netherwind Epaulets
  { 16916, 47088 }, -- Netherwind Robes, Netherwind Vestments
  { 16918, 47089 }, -- Netherwind Bindings, Netherwind Wristbands
  { 16913, 47090 }, -- Netherwind Gloves, Netherwind Handwraps
  { 16818, 47091 }, -- Netherwind Belt, Netherwind Cord
  { 16915, 47092 }, -- Netherwind Pants, Netherwind Trousers
  { 16912, 47093 }, -- Netherwind Boots, Netherwind Slippers
  -- T2WarlockC
  { 16929, 47284 }, -- Nemesis Skullcap, Nemesis Crown
  { 16932, 47285 }, -- Nemesis Spaulders, Nemesis Mantle
  { 16931, 47286 }, -- Nemesis Robes, Nemesis Raiments
  { 16934, 47287 }, -- Nemesis Bracers, Nemesis Bindings
  { 16928, 47288 }, -- Nemesis Gloves, Nemesis Handwraps
  { 16933, 47289 }, -- Nemesis Belt, Nemesis Sash
  { 16930, 47290 }, -- Nemesis Leggings, Nemesis Leggings
  { 16927, 47291 }, -- Nemesis Boots, Nemesis Slippers
  -- T2WarriorC
  { 16963, 47248 }, -- Helm of Wrath, Crown of Wrath
  { 16961, 47249 }, -- Pauldrons of Wrath, Pauldrons of Wrath
  { 16966, 47250 }, -- Breastplate of Wrath, Chestplate of Wrath
  { 16959, 47251 }, -- Bracelets of Wrath, Bindings of Wrath
  { 16964, 47252 }, -- Gauntlets of Wrath, Gloves of Wrath
  { 16960, 47253 }, -- Waistband of Wrath, Girdle of Wrath
  { 16962, 47254 }, -- Legplates of Wrath, Leggings of Wrath
  { 16965, 47255 }, -- Sabatons of Wrath, Sabatons of Wrath
  --------------------------------------------------------------------------
  -- Tier 2.5 (Temple of Ahn'Qiraj)
  --------------------------------------------------------------------------
  -- AQ40PaladinC
  { 21387, 47032, 47037 }, -- #x30#=ds=, #r2#, Avenger's Helmet, Avenger's Helm
  { 21391, 47033, 47038 }, -- #x25#=ds=, #r1#, Avenger's Shoulderguards, Avenger's Spaulders
  { 21389, 47034, 47039 }, -- #x32#=ds=, #r3#, Avenger's Chestguard, Avenger's Breastplate
  { 21390, 47035, 47040 }, -- #x31#=ds=, #r2#, Avenger's Legguards, Avenger's Legplates
  { 21388, 47036, 47041 }, -- #x25#=ds=, #r1#, Avenger's Greaves, Avenger's Boots
  -- AQ40PriestC
  { 21348, 47214, 33016 }, -- #x26#=ds=, #r2#, Coronet of the Oracle, Crown of the Oracle
  { 21350, 47215, 33017 }, -- #x29#=ds=, #r1#, Spaulders of the Oracle, Shoulderpads of the Oracle
  { 21351, 47216, 33018 }, -- #x28#=ds=, #r3#, Vestments of the Oracle, Robes of the Oracle
  { 21352, 47217, 33019 }, -- #x27#=ds=, #r2#, Trousers of the Oracle, Leggings of the Oracle
  { 21349, 47218, 33020 }, -- #x29#=ds=, #r1#, Treads of the Oracle, Sandals of the Oracle
  -- AQ40DruidC
  { 21353, 47362, 47367 }, -- #x30#=ds=, #r2#, Genesis Helm, Genesis Helmet
  { 21354, 47363, 47368 }, -- #x25#=ds=, #r1#, Genesis Spaulders, Genesis Shoulderpads
  { 21357, 47364, 47369 }, -- #x28#=ds=, #r3#, Genesis Vestments, Genesis Raiments
  { 21356, 47365, 47370 }, -- #x31#=ds=, #r2#, Genesis Leggings, Genesis Pants
  { 21355, 47366, 47371 }, -- #x25#=ds=, #r1#, Genesis Boots, Genesis Treads
  -- AQ40ShamanC
  { 21372, 47152, 47157 }, -- #x30#=ds=, #r2#, Stormcaller's Crown, Stormcaller's Helmet
  { 21376, 47153, 47158 }, -- #x25#=ds=, #r1#, Stormcaller's Pauldrons, Stormcaller's Spaulders
  { 21374, 47154, 47159 }, -- #x32#=ds=, #r3#, Stormcaller's Breastplate, Stormcaller's Chestpiece
  { 21375, 47155, 47160 }, -- #x31#=ds=, #r2#, Stormcaller's Leggings, Stormcaller's Pants
  { 21373, 47156, 47161 }, -- #x25#=ds=, #r1#, Stormcaller's Sabatons, Stormcaller's Boots
  -- AQ40MageC
  { 21347, 47094 }, -- #x26#=ds=, #r2#, Enigma Crown
  { 21345, 47095 }, -- #x25#=ds=, #r1#, Enigma Epaulets
  { 21343, 47096 }, -- #x28#=ds=, #r3#, Enigma Vestments
  { 21346, 47097 }, -- #x27#=ds=, #r2#, Enigma Trousers
  { 21344, 47098 }, -- #x25#=ds=, #r1#, Enigma Slippers
  -- AQ40WarlockC
  { 21337, 47292 }, -- #x26#=ds=, #r2#, Doomcaller's Crown
  { 21335, 47293 }, -- #x25#=ds=, #r1#, Doomcaller's Spaulders
  { 21334, 47294 }, -- #x28#=ds=, #r3#, Doomcaller's Raiments
  { 21336, 47295 }, -- #x31#=ds=, #r2#, Doomcaller's Leggings
  { 21338, 47296 }, -- #x25#=ds=, #r1#, Doomcaller's Slippers
  --------------------------------------------------------------------------
  -- Tier 3 (Naxxramas)
  --------------------------------------------------------------------------
  -- T3PaladinC
  { 22428, 47042, 47051 }, -- Redemption Helm, Redemption Helmet, Redemption Crown
  { 22429, 47043, 47052 }, -- Redemption Spaulders, Redemption Shoulderguards, Redemption Pauldrons
  { 22425, 47044, 47053 }, -- Redemption Tunic, Redemption Chestguard, Redemption Chestplate
  { 22424, 47045, 47054 }, -- Redemption Bracers, Redemption Wristguards, Redemption Bindings
  { 22426, 47046, 47055 }, -- Redemption Gloves, Redemption Handguards, Redemption Gauntlets
  { 22431, 47047, 47056 }, -- Redemption Belt, Redemption Waistguard, Redemption Girdle
  { 22427, 47048, 47057 }, -- Redemption Pants, Redemption Legguards, Redemption Leggings
  { 22430, 47049, 47058 }, -- Redemption Boots, Redemption Greaves, Redemption Sabatons
  { 23066, 47050, 47059 }, -- Ring of Redemption, Signet of Redemption, Band of Redemption
  -- T3PriestC
  { 22514, 47219 }, -- Circlet of Faith, Coronet of Faith
  { 22515, 47220 }, -- Shoulderpads of Faith, Shoulderpads of Faith
  { 22512, 47221 }, -- Robe of Faith, Raiments of Faith
  { 22519, 47222 }, -- Bindings of Faith, Bracers of Faith
  { 22517, 47223 }, -- Gloves of Faith, Handguards of Faith
  { 22518, 47224 }, -- Belt of Faith, Sash of Faith
  { 22513, 47225 }, -- Leggings of Faith, Pants of Faith
  { 22516, 47226 }, -- Sandals of Faith, Sandals of Faith
  { 23061, 47227 }, -- Ring of Faith, Ring of Faith
  -- T3DruidC
  { 22490, 47372, 47381 }, -- Dreamwalker Headpiece, Dreamwalker Circlet, Dreamwalker Helmet
  { 22491, 47373, 47382 }, -- Dreamwalker Spaulders, Dreamwalker Mantle, Dreamwalker Shoulderpads
  { 22488, 47374, 47383 }, -- Dreamwalker Tunic, Dreamwalker Vest, Dreamwalker Raiments
  { 22495, 47375, 47384 }, -- Dreamwalker Bracers, Dreamwalker Wristbands, Dreamwalker Wristguards
  { 22493, 47376, 47385 }, -- Dreamwalker Handguards, Dreamwalker Handwraps, Dreamwalker Handwraps
  { 22494, 47377, 47386 }, -- Dreamwalker Belt, Dreamwalker Sash, Dreamwalker Girdle
  { 22489, 47378, 47387 }, -- Dreamwalker Legguards, Dreamwalker Trousers, Dreamwalker Pants
  { 22492, 47379, 47388 }, -- Dreamwalker Boots, Dreamwalker Slippers, Dreamwalker Treads
  { 23064, 47380, 47389 }, -- Ring of the Dreamwalker, Signet of the Dreamwalker, Band of the Dreamwalker
  -- T3ShamanC
  { 22466, 47162, 47171 }, -- Earthshatter Headpiece, Earthshatter Crown, Earthshatter Helmet
  { 22467, 47163, 47172 }, -- Earthshatter Spaulders, Earthshatter Pauldrons, Earthshatter Epaulets
  { 22464, 47164, 47173 }, -- Earthshatter Tunic, Earthshatter Breastplate, Earthshatter Raiments
  { 22471, 47165, 47174 }, -- Earthshatter Wristguards, Earthshatter Bracelets, Earthshatter Bindings
  { 22469, 47166, 47175 }, -- Earthshatter Handguards, Earthshatter Fists, Earthshatter Gauntlets
  { 22470, 47167, 47176 }, -- Earthshatter Girdle, Earthshatter Girdle, Earthshatter Sash
  { 22465, 47168, 47177 }, -- Earthshatter Legguards, Earthshatter Leggings, Earthshatter Legplates
  { 22468, 47169, 47178 }, -- Earthshatter Boots, Earthshatter Sabatons, Earthshatter Greaves
  { 23065, 47170, 47179 }, -- Ring of the Earthshatterer, Signet of the Earthshatterer, Loop of the Earthshatterer
  -- T3MageC
  { 22498, 47099 }, -- Frostfire Circlet, Frostfire Crown
  { 22499, 47100 }, -- Frostfire Shoulderpads, Frostfire Epaulets
  { 22496, 47101 }, -- Frostfire Robe, Frostfire Vestments
  { 22503, 47102 }, -- Frostfire Bindings, Frostfire Bracers
  { 22501, 47103 }, -- Frostfire Gloves, Frostfire Handwraps
  { 22502, 47104 }, -- Frostfire Belt, Frostfire Cord
  { 22497, 47105 }, -- Frostfire Leggings, Frostfire Trousers
  { 22500, 47106 }, -- Frostfire Sandals, Frostfire Slippers
  { 23062, 47107 }, -- Frostfire Ring, Frostfire Signet
  -- T3WarlockC
  { 22506, 47297 }, -- Plagueheart Circlet, Plagueheart Crown
  { 22507, 47298 }, -- Plagueheart Shoulderpads, Plagueheart Mantle
  { 22504, 47299 }, -- Plagueheart Robe, Plagueheart Raiments
  { 22511, 47300 }, -- Plagueheart Bracers, Plagueheart Bindings
  { 22509, 47301 }, -- Plagueheart Gloves, Plagueheart Handwraps
  { 22510, 47302 }, -- Plagueheart Belt, Plagueheart Sash
  { 22505, 47303 }, -- Plagueheart Leggings, Plagueheart Leggings
  { 22508, 47304 }, -- Plagueheart Sandals, Plagueheart Boots
  { 23063, 47305 }, -- Plagueheart Ring, Plagueheart Signet
  -- T3WarriorC
  { 22418, 47261 }, -- Dreadnaught Helmet, Dreadnaught Crown
  { 22419, 47262 }, -- Dreadnaught Pauldrons, Dreadnaught Pauldrons
  { 22416, 47263 }, -- Dreadnaught Breastplate, Dreadnaught Chestplate
  { 22423, 47264 }, -- Dreadnaught Bracers, Dreadnaught Bindings
  { 22421, 47265 }, -- Dreadnaught Gauntlets, Dreadnaught Gloves
  { 22422, 47266 }, -- Dreadnaught Waistguard, Dreadnaught Girdle
  { 22417, 47267 }, -- Dreadnaught Legplates, Dreadnaught Leggings
  { 22420, 47268 }, -- Dreadnaught Sabatons, Dreadnaught Sabatons
  { 23059, 47269 }, -- Ring of the Dreadnaught, Ring of the Dreadnaught
  --------------------------------------------------------------------------
  -- Tier 3.5 (Naxxramas / End-game)
  --------------------------------------------------------------------------
  -- T35PaladinC
  { 47060, 47066, 47072 }, -- Lionheart Headpiece, Lionheart Helmet, Lionheart Crown
  { 47061, 47067, 47073 }, -- Lionheart Spaulders, Lionheart Shoulderguards, Lionheart Pauldrons
  { 47062, 47068, 47074 }, -- Lionheart Breastplate, Lionheart Chestguard, Lionheart Chestplate
  { 47063, 47069, 47075 }, -- Lionheart Legplates, Lionheart Legguards, Lionheart Leggings
  { 47064, 47070, 47076 }, -- Lionheart Boots, Lionheart Greaves, Lionheart Sabatons
  { 47065, 47071, 47077 }, -- Lionheart Amulet, Lionheart Pendant, Lionheart Choker
  -- T35PriestC
  { 47228, 47234 }, -- Crown of Pestilence, Coronet of Pestilence
  { 47229, 47235 }, -- Shoulderpads of Pestilence, Shoulderpads of Pestilence
  { 47230, 47236 }, -- Robes of Pestilence, Raiments of Pestilence
  { 47231, 47237 }, -- Leggings of Pestilence, Pants of Pestilence
  { 47232, 47238 }, -- Boots of Pestilence, Sandals of Pestilence
  { 47233, 47239 }, -- Amulet of Pestilence, Pendant of Pestilence
  -- T35DruidC
  { 47390, 47396, 47402 }, -- Helm of the Talon, Circlet of the Talon, Helmet of the Talon
  { 47391, 47397, 47403 }, -- Spaulders of the Talon, Mantle of the Talon, Shoulderpads of the Talon
  { 47392, 47398, 47404 }, -- Vestments of the Talon, Vest of the Talon, Raiments of the Talon
  { 47393, 47399, 47405 }, -- Leggings of the Talon, Trousers of the Talon, Pants of the Talon
  { 47394, 47400, 47406 }, -- Boots of the Talon, Slippers of the Talon, Treads of the Talon
  { 47395, 47401, 47407 }, -- Amulet of the Talon, Pendant of the Talon, Choker of the Talon
  -- T35ShamanC
  { 47180, 47186, 47192 }, -- Stormhowl Crown, Stormhowl Helmet, Stormhowl Headpiece
  { 47181, 47187, 47193 }, -- Stormhowl Pauldrons, Stormhowl Epaulets, Stormhowl Spaulders
  { 47182, 47188, 47194 }, -- Stormhowl Breastplate, Stormhowl Raiments, Stormhowl Tunic
  { 47183, 47189, 47195 }, -- Stormhowl Leggings, Stormhowl Legplates, Stormhowl Legguards
  { 47184, 47190, 47196 }, -- Stormhowl Sabatons, Stormhowl Greaves, Stormhowl Boots
  { 47185, 47191, 47197 }, -- Choker of the Stormhowl, Pendant of the Stormhowl, Amulet of the Stormhowl
  -- T35MageC
  { 47108, 47114 }, -- Crown of the Guardian, Circlet of the Guardian
  { 47109, 47115 }, -- Mantle of the Guardian, Epaulets of the Guardian
  { 47110, 47116 }, -- Robes of the Guardian, Vestments of the Guardian
  { 47111, 47117 }, -- Leggings of the Guardian, Trousers of the Guardian
  { 47112, 47118 }, -- Boots of the Guardian, Slippers of the Guardian
  { 47113, 47119 }, -- Pendant of the Guardian, Amulet of the Guardian
  -- T35WarlockC
  { 47306, 47312 }, -- Nathrezim Crown, Nathrezim Skullcap
  { 47307, 47313 }, -- Nathrezim Mantle, Nathrezim Spaulders
  { 47308, 47314 }, -- Nathrezim Raiments, Nathrezim Robes
  { 47309, 47315 }, -- Nathrezim Leggings, Nathrezim Pants
  { 47310, 47316 }, -- Nathrezim Boots, Nathrezim Slippers
  { 47311, 47317 }, -- Nathrezim Amulet, Nathrezim Pendant
}

local item_to_group = {}

---@param group number[]
local function index_group( group )
  for i = 1, getn( group ) do
    local item_id = group[ i ]
    item_to_group[ item_id ] = group
  end
end

for i = 1, getn( groups ) do
  index_group( groups[ i ] )
end

---@param group number[]
function M.register_group( group )
  if not group or getn( group ) <= 1 then return end
  table.insert( groups, group )
  index_group( group )
end

---@param item_id number
---@return number[]
function M.get_equivalent_item_ids( item_id )
  if not item_id then return {} end
  local group = item_to_group[ item_id ]
  if group then return group end
  return { item_id }
end

---@param item_id_a number
---@param item_id_b number
---@return boolean
function M.are_items_equivalent( item_id_a, item_id_b )
  if not item_id_a or not item_id_b then return false end
  if item_id_a == item_id_b then return true end

  local group = item_to_group[ item_id_a ]
  if not group then return false end

  for i = 1, getn( group ) do
    if group[ i ] == item_id_b then return true end
  end

  return false
end

---Dynamically inspect AtlasLoot if loaded, to discover any additional multi-table sets
function M.init_from_atlasloot()
  ---@diagnostic disable-next-line: undefined-global
  if not AtlasLoot_Data or not AtlasLoot_Data["AtlasLootSetItems"] then return end

  ---@diagnostic disable-next-line: undefined-global
  local set_items = AtlasLoot_Data["AtlasLootSetItems"]

  for _, set_tables in pairs( set_items ) do
    if type( set_tables ) == "table" and getn( set_tables ) > 1 then
      local min_slots = nil
      for i = 1, getn( set_tables ) do
        local tbl = set_tables[ i ]
        if type( tbl ) == "table" then
          local count = getn( tbl )
          if not min_slots or count < min_slots then
            min_slots = count
          end
        end
      end

      if min_slots and min_slots > 0 then
        for slot_idx = 1, min_slots do
          local new_group = {}
          for i = 1, getn( set_tables ) do
            local tbl = set_tables[ i ]
            local item_entry = tbl[ slot_idx ]
            local item_id = item_entry and item_entry[ 1 ]
            if item_id and type( item_id ) == "number" and item_id > 0 then
              table.insert( new_group, item_id )
            end
          end

          if getn( new_group ) > 1 then
            M.register_group( new_group )
          end
        end
      end
    end
  end
end

m.ItemEquivalence = M
return M
