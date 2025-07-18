-- Copyright © 2021-2025, Shasta
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * Neither the name of SilverLibs nor the
--       names of its contributors may be used to endorse or promote products
--       derived from this software without specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL Shasta BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


--=============================================================================
--=============================================================================
--====================             DO NOT              ========================
--====================             MODIFY              ========================
--====================            ANYTHING             ========================
--=============================================================================
--=============================================================================

silibs = {} -- Initialize library namespace
silibs.version = '2025.JUL.13.3'

-- This works because SilverLibs is loaded in global file, which is loaded
-- by Mote-Include or Sel-Include so this variable is already initialized.
silibs.base_lib = (selindrile_warned ~= nil and 'selindrile') or (mote_vars ~= nil and 'mote') or 'unknown'
print('SilverLibs: Loaded version \''..silibs.version..'\' with base lib \''..silibs.base_lib..'\'')

--=============================================================================
--=============================================================================
--=============================================================================
--                           Includes/imports
--=============================================================================
--=============================================================================
--=============================================================================
res = include('resources')
packets = include('packets')
chars = include('chat/chars')
extdata = include('extdata')


--=============================================================================
--=============================================================================
--=============================================================================
--                           Constants and maps
--=============================================================================
--=============================================================================
--=============================================================================
silibs.init_time = os.time()

silibs.range_mult = {
  [2] = 1.55,
  [3] = 1.490909,
  [4] = 1.44,
  [5] = 1.377778,
  [6] = 1.30,
  [7] = 1.15,
  [8] = 1.25,
  [9] = 1.377778,
  [10] = 1.45,
  [11] = 1.454545454545455,
  [12] = 1.666666666666667,
}

silibs.default_quick_magic_spells = T{
  ['WhiteMagic'] = S{'Banish', 'Banish II', 'Banish III', 'Banishga', 'Banishga II', 'Arise', 'Raise', 'Raise II', 'Raise III',
                      'Reraise', 'Reraise II', 'Reraise III', 'Reraise IV', 'Reraise V', 'Cure', 'Full Cure', 'Recall-Jugner',
                      'Recall-Meriph', 'Recall-Pashh', 'Teleport-Altep', 'Teleport-Dem', 'Teleport-Holla', 'Teleport-Mea',
                      'Teleport-Vahzl', 'Teleport-Yhoat'},
  ['BlackMagic'] = S{'Tractor', 'Escape', 'Retrace', 'Warp', 'Warp II'},
  ['BardSong'] = S{},
  ['Ninjutsu'] = S{'Myoshu: Ichi', 'Gekka: Ichi', 'Yain: Ichi', 'Kakka: Ichi'},
  ['SummonerPact'] = S{'Carbuncle', 'Cait Sith', 'Alexander', 'Ifrit', 'Shiva', 'Garuda', 'Siren', 'Titan', 'Ramuh', 'Leviathan',
                    'Fenrir', 'Diabolos', 'Odin'},
  ['BlueMagic'] = S{'Cocoon', 'Feather Barrier', 'Memento Mori', 'Zephyr Mantle', 'Amplification', 'Triumphant Roar', 'Exuviation',
                    'Osmosis', 'Fantod', 'Winds of Promy.', 'Barrier Tusk', 'O. Counterstance', 'Pyric Bulwark', 'Harden Shell'},
  ['Geomancy'] = S{}, -- No geo spells should be quick cast
}

silibs.action_type_blockers = {
  ['Magic'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'silence', 'mute', 'Omerta'},
  ['Ranged Attack'] = {'terror', 'petrification', 'stun', 'sleep', 'charm'},
  ['Ability'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'amnesia', 'impairment'},
  ['Item'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'muddle'},
  ['Monster Move'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'amnesia'},
  ['Trade'] = {},
}

silibs.curing_waltz = T{
  [1] = {name='Curing Waltz',     tier=1, lv=15, tp=200, cure_slope=0.25, cure_base=60},
  [2] = {name='Curing Waltz II',  tier=2, lv=30, tp=350, cure_slope=0.5,  cure_base=130},
  [3] = {name='Curing Waltz III', tier=3, lv=45, tp=500, cure_slope=0.75, cure_base=270},
  [4] = {name='Curing Waltz IV',  tier=4, lv=70, tp=650, cure_slope=1,    cure_base=450},
  [5] = {name='Curing Waltz V',   tier=5, lv=87, tp=800, cure_slope=1.25, cure_base=600},
}

-- category == 1=melee, 2=ranged, 3=weaponskill, 4=spell, 6=job ability, 14=unblinkable JA
silibs.action_categories = {
  [1]={category=1,description='Melee Attacks',resource=nil,th_aoe_category=nil},
  [2]={category=2,description='Ranged Attacks',resource=nil,th_aoe_category=nil},
  [3]={category=3,description='Weaponskills',resource='weapon_skills',th_aoe_category='weaponskills'},
  [4]={category=4,description='Spells',resource='spells',th_aoe_category='spells'},
  [6]={category=6,description='Job Abilities',resource='job_abilities',th_aoe_category='abilities'},
  [14]={category=14,description='Unblinkable Job Abilities',resource='job_abilities',th_aoe_category='abilities'},
}

--Luopan Distance Tracking
silibs.geo_debuffs = S{'Gravity','Paralysis','Slow','Languor','Vex','Torpor','Slip','Malaise','Fade','Frailty','Wilt','Poison'}
silibs.luopan_ignore_list = S{'SlipperySilas','HareFamiliar','SheepFamiliar','FlowerpotBill','TigerFamiliar','FlytrapFamiliar','LizardFamiliar','MayflyFamiliar','EftFamiliar','BeetleFamiliar','AntlionFamiliar','CrabFamiliar','MiteFamiliar','KeenearedSteffi','LullabyMelodia','FlowerpotBen','SaberSiravarde','FunguarFamiliar','ShellbusterOrob','ColdbloodComo','CourierCarrie','Homunculus','VoraciousAudrey','AmbusherAllie','PanzerGalahad','LifedrinkerLars','ChopsueyChucky','AmigoSabotender','NurseryNazuna','CraftyClyvonne','PrestoJulio','SwiftSieghard','MailbusterCetas','AudaciousAnna','TurbidToloi','LuckyLulush','DipperYuly','FlowerpotMerle','DapperMac','DiscreetLouise','FatsoFargann','FaithfulFalcorr','BugeyedBroncha','BloodclawShasra','GorefangHobs','GooeyGerard','CrudeRaphie','DroopyDortwin','SunburstMalfik','WarlikePatrick','ScissorlegXerin','RhymingShizuna','AttentiveIbuki','AmiableRoche','HeraldHenry','BrainyWaluis','SuspiciousAlice','HeadbreakerKen','RedolentCandi','CaringKiyomaro','HurlerPercival','AnklebiterJedd','BlackbeardRandy','FleetReinhard','GenerousArthur','ThreestarLynn','BraveHeroGlenn','SharpwitHermes','AlluringHoney','CursedAnnabelle','SwoopingZhivago','BouncingBertha','MosquitoFamilia','Ifrit','Shiva','Garuda','Fenrir','Carbuncle','Ramuh','Leviathan','CaitSith','Diabolos','Titan','Atomos','WaterSpirit','FireSpirit','EarthSpirit','ThunderSpirit','AirSpirit','LightSpirit','DarkSpirit','IceSpirit', 'Azure','Cerulean','Rygor','Firewing','Delphyne','Ember','Rover','Max','Buster','Duke','Oscar','Maggie','Jessie','Lady','Hien','Raiden','Lumiere','Eisenzahn','Pfeil','Wuffi','George','Donryu','Qiqiru','Karav-Marav','Oboro','Darug Borug','Mikan','Vhiki','Sasavi','Tatang','Nanaja','Khocha','Nanaja','Khocha','Dino','Chomper','Huffy','Pouncer','Fido','Lucy','Jake','Rocky','Rex','Rusty','Himmelskralle','Gizmo','Spike','Sylvester','Milo','Tom','Toby','Felix','Komet','Bo','Molly','Unryu','Daisy','Baron','Ginger','Muffin','Lumineux','Quatrevents','Toryu','Tataba','Etoilazuree','Grisnuage','Belorage','Centonnerre','Nouvellune','Missy','Amedeo','Tranchevent','Soufflefeu','Etoile','Tonnerre','Nuage','Foudre','Hyuh','Orage','Lune','Astre','Waffenzahn','Soleil','Courageux','Koffla-Paffla','Venteuse','Lunaire','Tora','Celeste','Galja-Mogalja','Gaboh','Vhyun','Orageuse','Stellaire','Solaire','Wirbelwind','Blutkralle','Bogen','Junker','Flink','Knirps','Bodo','Soryu','Wanaro','Totona','Levian-Movian','Kagero','Joseph','Paparaz','Coco','Ringo','Nonomi','Teter','Gigima','Gogodavi','Rurumo','Tupah','Jyubih','Majha','Luron','Drille','Tournefoux','Chafouin','Plaisantin','Loustic','Histrion','Bobeche','Bougrion','Rouleteau','Allouette','Serenade','Ficelette','Tocadie','Caprice','Foucade','Capillotte','Quenotte','Pacotille','Comedie','Kagekiyo','Toraoh','Genta','Kintoki','Koumei','Pamama','Lobo','Tsukushi','Oniwaka','Kenbishi','Hannya','Mashira','Nadeshiko','E100','Koume','X-32','Poppo','Asuka','Sakura','Tao','Mao','Gadget','Marion','Widget','Quirk','Sprocket','Cogette','Lecter','Coppelia','Sparky','Clank','Calcobrena','Crackle','Ricochet','Josette','Fritz','Skippy','Pino','Mandarin','Jackstraw','Guignol','Moppet','Nutcracker','Erwin','Otto','Gustav','Muffin','Xaver','Toni','Ina','Gerda','Petra','Verena','Rosi','Schatzi','Warashi','Klingel','Clochette','Campanello','Kaiserin','Principessa','Butler','Graf','Caro','Cara','Mademoiselle','Herzog','Tramp','V-1000','Hikozaemon','Nine','Acht','Quattro','Zero','Dreizehn','Seize','Fukusuke','Mataemon','Kansuke','Polichinelle','Tobisuke','Sasuke','Shijimi','Chobi','Aurelie','Magalie','Aurore','Caroline','Andrea','Machinette','Clarine','Armelle','Reinette','Dorlote','Turlupin','Klaxon','Bambino','Potiron','Fustige','Amidon','Machin','Bidulon','Tandem','Prestidige','Purute-Porute','Bito-Rabito','Cocoa','Totomo','Centurion','A7V','Scipio','Sentinel','Pioneer','Seneschal','Ginjin','Amagatsu','Dolly','Fantoccini','Joe','Kikizaru','Whippet','Punchinello','Charlie','Midge','Petrouchka','Schneider','Ushabti','Noel','Yajirobe','Hina','Nora','Shoki','Kobina','Kokeshi','Mame','Bishop','Marvin','Dora','Data','Robin','Robby','Porlo-Moperlo','Paroko-Puronko','Pipima','Gagaja','Mobil','Donzel','Archer','Shooter','Stephen','Mk.IV','Conjurer','Footman','Tokotoko','Sancho','Sarumaro','Picket','Mushroom','Shantotto','Naji','Kupipi','Excenmille','Ayame','NanaaMihgo','Curilla','Volker','Ajido-Marujido','Trion','Zeid','Lion','Tenzen','MihliAliapoh','Valaineral','Joachim','NajaSalaheem','Prishe','Ulmia','ShikareeZ','Cherukiki','IronEater','Gessho','Gadalar','Rainemard','Ingrid','LehkoHabhoka','Nashmeira','Zazarg','Ovjang','Mnejing','Sakura','Luzaf','Najelith','Aldo','Moogle','Fablinix','Maat','D.Shantotto','StarSibyl','Karaha-Baruha','Cid','Gilgamesh','Areuhat','SemihLafihna','Elivira','Noillurie','LhuMhakaracca','FerreousCoffin','Lilisette','Mumor','UkaTotlihn','Klara','RomaaMihgo','KuyinHathdenna','Rahal','Koru-Moru','Pieuje','InvincibleShld','Apururu','JakohWahcondalo','Flaviria','Babban','Abenzio','Rughadjeen','Kukki-Chebukki','Margret','Chacharoon','LheLhangavo','Arciela','Mayakov','Qultada','Adelheid','Amchuchu','Brygid','Mildaurion','Halver','Rongelouts','Leonoyne','Maximilian','Kayeel-Payeel','Robel-Akbel','Kupofried','Selh\'teus','Yoran-Oran','Sylvie','Abquhbah','Balamor','August','Rosulatia','Teodor','Ullegore','Makki-Chebukki','KingOfHearts','Morimar','Darrcuiln','ArkHM','ArkEV','ArkMR','ArkTT','ArkGK','Iroha','Ygnas','Excenmille','Ayame','Maat','Aldo','NajaSalaheem','Lion','Zeid'}


-- Bonuses based on day and weather and gear equipped (in percentage points).
silibs.day_weather_bns = T{
  [0] =  { day=-1, weather=-2, base_day_bn=-10, base_weather_bn=-25, iridescence_bn=-10 },
  [1] =  { day=-1, weather=-1, base_day_bn=-10, base_weather_bn=-10, iridescence_bn=-10 },
  [2] =  { day=-1, weather=0,  base_day_bn=-10, base_weather_bn=0,   iridescence_bn=0   },
  [3] =  { day=-1, weather=1,  base_day_bn=-10, base_weather_bn=10,  iridescence_bn=10  },
  [4] =  { day=-1, weather=2,  base_day_bn=-10, base_weather_bn=25,  iridescence_bn=10  },
  [5] =  { day=0,  weather=-2, base_day_bn=0,   base_weather_bn=-25, iridescence_bn=-10 },
  [6] =  { day=0,  weather=-1, base_day_bn=0,   base_weather_bn=-10, iridescence_bn=-10 },
  [7] =  { day=0,  weather=0,  base_day_bn=0,   base_weather_bn=0,   iridescence_bn=0   },
  [8] =  { day=0,  weather=1,  base_day_bn=0,   base_weather_bn=10,  iridescence_bn=10  },
  [9] =  { day=0,  weather=2,  base_day_bn=0,   base_weather_bn=25,  iridescence_bn=10  },
  [10] = { day=1,  weather=-2, base_day_bn=10,  base_weather_bn=-25, iridescence_bn=-10 },
  [11] = { day=1,  weather=-1, base_day_bn=10,  base_weather_bn=-10, iridescence_bn=-10 },
  [12] = { day=1,  weather=0,  base_day_bn=10,  base_weather_bn=0,   iridescence_bn=0   },
  [13] = { day=1,  weather=1,  base_day_bn=10,  base_weather_bn=10,  iridescence_bn=10  },
  [14] = { day=1,  weather=2,  base_day_bn=10,  base_weather_bn=25,  iridescence_bn=10  },
}

silibs.equippable_bags = L{'inventory','wardrobe','wardrobe2','wardrobe3',
'wardrobe4','wardrobe5','wardrobe6','wardrobe7','wardrobe8'}

silibs.roll_info = {
  [ 98] = {id=98, name='Fighter\'s Roll', short_name='Fighter\'s', lucky=5, unlucky=9, effect='Double Attack Rate', status=310},
  [ 99] = {id=99, name='Monk\'s Roll', short_name='Monk\'s', lucky=3, unlucky=7, effect='Subtle Blow', status=311},
  [100] = {id=100, name='Healer\'s Roll', short_name='Healer\'s', lucky=3, unlucky=7, effect='Cure Potency Received', status=312},
  [101] = {id=101, name='Wizard\'s Roll', short_name='Wizard\'s', lucky=5, unlucky=9, effect='Magic Attack', status=313},
  [102] = {id=102, name='Warlock\'s Roll', short_name='Warlock\'s', lucky=4, unlucky=8, effect='Magic Accuracy', status=314},
  [103] = {id=103, name='Rogue\'s Roll', short_name='Rogue\'s', lucky=5, unlucky=9, effect='Critical Hit Rate', status=315},
  [104] = {id=104, name='Gallant\'s Roll', short_name='Gallant\'s', lucky=3, unlucky=7, effect='Defense', status=316},
  [105] = {id=105, name='Chaos Roll', short_name='Chaos', lucky=4, unlucky=8, effect='Attack', status=317},
  [106] = {id=106, name='Beast Roll', short_name='Beast', lucky=4, unlucky=8, effect='Pet Attack', status=318},
  [107] = {id=107, name='Choral Roll', short_name='Choral', lucky=2, unlucky=6, effect='Spell Interruption Rate', status=319},
  [108] = {id=108, name='Hunter\'s Roll', short_name='Hunter\'s', lucky=4, unlucky=8, effect='Accuracy', status=320},
  [109] = {id=109, name='Samurai Roll', short_name='Samurai', lucky=2, unlucky=6, effect='Store TP', status=321},
  [110] = {id=110, name='Ninja Roll', short_name='Ninja', lucky=4, unlucky=8, effect='Evasion', status=322},
  [111] = {id=111, name='Drachen Roll', short_name='Drachen', lucky=4, unlucky=8, effect='Pet Magic Accuracy/Attack', status=323},
  [112] = {id=112, name='Evoker\'s Roll', short_name='Evoker\'s', lucky=5, unlucky=9, effect='Refresh', status=324},
  [113] = {id=113, name='Magus\'s Roll', short_name='Magus\'s', lucky=2, unlucky=6, effect='Magic Defense', status=325},
  [114] = {id=114, name='Corsair\'s Roll', short_name='Corsair\'s', lucky=5, unlucky=9, effect='Experience Points', status=326},
  [115] = {id=115, name='Puppet Roll', short_name='Puppet', lucky=3, unlucky=7, effect='Pet Magic Attack/Accuracy', status=327},
  [116] = {id=116, name='Dancer\'s Roll', short_name='Dancer\'s', lucky=3, unlucky=7, effect='Regen', status=328},
  [117] = {id=117, name='Scholar\'s Roll', short_name='Scholar\'s', lucky=2, unlucky=6, effect='Conserve MP', status=329},
  [118] = {id=118, name='Bolter\'s Roll', short_name='Bolter\'s', lucky=3, unlucky=9, effect='Movement Speed', status=330},
  [119] = {id=119, name='Caster\'s Roll', short_name='Caster\'s', lucky=2, unlucky=7, effect='Fast Cast', status=331},
  [120] = {id=120, name='Courser\'s Roll', short_name='Courser\'s', lucky=3, unlucky=9, effect='Snapshot', status=332},
  [121] = {id=121, name='Blitzer\'s Roll', short_name='Blitzer\'s', lucky=4, unlucky=9, effect='Attack Delay', status=333},
  [122] = {id=122, name='Tactician\'s Roll', short_name='Tactician\'s', lucky=5, unlucky=8, effect='Regain', status=334},
  [302] = {id=302, name='Allies\' Roll', short_name='Allies\'', lucky=3, unlucky=10, effect='Skillchain Damage', status=335},
  [303] = {id=303, name='Miser\'s Roll', short_name='Miser\'s', lucky=5, unlucky=7, effect='Save TP', status=336},
  [304] = {id=304, name='Companion\'s Roll', short_name='Companion\'s', lucky=2, unlucky=10, effect='Pet Regain and Regen', status=337},
  [305] = {id=305, name='Avenger\'s Roll', short_name='Avenger\'s', lucky=4, unlucky=8, effect='Counter Rate', status=338},
  [390] = {id=390, name='Naturalist\'s Roll', short_name='Naturalist\'s', lucky=3, unlucky=7, effect='Enh. Magic Duration', status=339},
  [391] = {id=391, name='Runeist\'s Roll', short_name='Runeist\'s', lucky=4, unlucky=8, effect='Magic Evasion', status=600},
}
-- Same as silibs.roll_info, just indexed by status ID
silibs.roll_info_by_status = {}
for id,ja in pairs(silibs.roll_info) do
  silibs.roll_info_by_status[ja.status] = ja
end

silibs.elements = {
  list = S{'Light','Dark','Fire','Ice','Wind','Earth','Lightning','Water'},
  weak_to = {
    ['Light']='Dark',
    ['Dark']='Light',
    ['Fire']='Ice',
    ['Ice']='Wind',
    ['Wind']='Earth',
    ['Earth']='Lightning',
    ['Lightning']='Water',
    ['Water']='Fire'
  },
  strong_to = {
    ['Light']='Dark',
    ['Dark']='Light',
    ['Fire']='Water',
    ['Ice']='Fire',
    ['Wind']='Ice',
    ['Earth']='Wind',
    ['Lightning']='Earth',
    ['Water']='Lightning'
  },
  storm_of = {
    ['Light']='Aurorastorm',
    ['Dark']='Voidstorm',
    ['Fire']='Firestorm',
    ['Ice']='Hailstorm',
    ['Wind']='Windstorm',
    ['Earth']='Sandstorm',
    ['Lightning']='Thunderstorm',
    ['Water']='Rainstorm'
  },
  nuke_of = {
    ['Light']='Holy',
    ['Dark']='Comet',
    ['Fire']='Fire',
    ['Ice']='Blizzard',
    ['Wind']='Aero',
    ['Earth']='Stone',
    ['Lightning']='Thunder',
    ['Water']='Water',
  },
  helix_of = {
    ['Light']='Lumino',
    ['Dark']='Nocto',
    ['Fire']='Pyro',
    ['Ice']='Cryo',
    ['Wind']='Anemo',
    ['Earth']='Geo',
    ['Lightning']='Iono',
    ['Water']='Hydro'
  },
  nukera_of = {
    ['Fire']='Fi',
    ['Ice']='Blizza',
    ['Wind']='Ae',
    ['Earth']='Stone',
    ['Lightning']='Thunda',
    ['Water']='Wate'
  },
  nukega_of = {
    ['Fire']='Fira',
    ['Ice']='Blizza',
    ['Wind']='Aero',
    ['Earth']='Stone',
    ['Lightning']='Thunda',
    ['Water']='Water',
  },
  nukeja_of = {
    ['Fire']='Fira',
    ['Ice']='Blizza',
    ['Wind']='Aero',
    ['Earth']='Stone',
    ['Lightning']='Thunda',
    ['Water']='Water',
  },
  spirit_of = {
    ['Light']='Light Spirit',
    ['Dark']='Dark Spirit',
    ['Fire']='Fire Spirit',
    ['Ice']='Ice Spirit',
    ['Wind']='Air Spirit',
    ['Earth']='Earth Spirit',
    ['Lightning']='Thunder Spirit',
    ['Water']='Water Spirit'
  },
  rune_of = {
    ['Light']='Lux',
    ['Dark']='Tenebrae',
    ['Fire']='Ignis',
    ['Ice']='Gelus',
    ['Wind']='Flabra',
    ['Earth']='Tellus',
    ['Lightning']='Sulpor',
    ['Water']='Unda'
  },
  of_rune = {
    ['Lux']='Light',
    ['Tenebrae']='Dark',
    ['Ignis']='Fire',
    ['Gelus']='Ice',
    ['Flabra']='Wind',
    ['Tellus']='Earth',
    ['Sulpor']='Lightning',
    ['Unda']='Water'
  },
  enspell_of = {
    ['Fire']='Enfire',
    ['Ice']='Enblizzard',
    ['Wind']='Enaero',
    ['Earth']='Enstone',
    ['Lightning']='Enthunder',
    ['Water']='Enwater'
  }
}

-- Credit to Rubenator for the ammo map
-- Maps ammo type (i.e. bullet, bolt, etc) to the range type (i.e. gun, crossbow, etc).
-- Ammo items have an ammo_type field and range items have a range_type field. This map
-- provides a way to check if a specific ammo item can be used by a specific range item.
silibs.ammo_map = T{}
silibs.ammo_range_map = T{
    ['Bullet'] = 'Gun',
    ['Shell'] = 'Cannon',
    ['Bolt'] = 'Crossbow',
    ['Arrow'] = 'Bow',
}
-- Populate ammo_map
gearswap.res.items:slots(function(x) return x and x:contains(3) end):map(function(item)
    if not item.ammo_type or not silibs.ammo_range_map[item.ammo_type] then return end
    local rtype = silibs.ammo_range_map[item.ammo_type]
    silibs.ammo_map[item.en:lower()] = rtype
    silibs.ammo_map[item.enl:lower()] = rtype
end)
setmetatable(silibs.ammo_map, {
  __index = function(t, key)
    if key and type(key) == 'string' then
      key = key:lower()
    end
    return rawget(t, key)
  end
})

silibs.elemental_ws = S{'Aeolian Edge', 'Sanguine Blade', 'Cloudsplitter', 'Seraph Blade', 'Blade: Teki', 'Blade: To', 'Blade: Chi',
    'Tachi: Jinpu', 'Tachi: Koki', 'Cataclysm', 'Wildfire', 'Trueflight', 'Leaden Salute', 'Primal Rend', 'Cyclone',
    'Burning Blade', 'Red Lotus Blade', 'Shining Blade', 'Frostbite', 'Freezebite', 'Dark Harvest', 'Shadow of Death',
    'Infernal Scythe', 'Thunder Thrust', 'Raiden Thrust', 'Blade: Ei', 'Blade: Yu', 'Tachi: Goten', 'Tachi: Kagero',
    'Shining Strike', 'Seraph Strike', 'Flash Nova', 'Rock Crusher', 'Earth Crusher', 'Starburst', 'Sunburst', 'Vidohunir',
    'Garland of Bliss', 'Omniscience', 'Flaming Arrow', 'Hot Shot'}

silibs.proc_ws_abyssea_red = S{'Cyclone', 'Energy Drain', 'Red Lotus Blade', 'Seraph Blade', 'Freezebite', 'Shadow of Death', 'Raiden Thrust',
    'Blade: Ei', 'Tachi: Jinpu', 'Tachi: Koki', 'Seraph Strike', 'Earth Crusher', 'Sunburst'}

silibs.blue_magic_magical_dmg_spells = S{'Anvil Lightning','Blazing Bound','Bomb Toss','Cursed Sphere','Droning Whirlwind',
    'Embalming Earth','Entomb','Firespit','Foul Waters','Ice Break','Leafstorm','Maelstrom',
    'Molting Plumage','Nectarous Deluge','Regurgitation','Rending Deluge','Scouring Spate',
    'Silent Storm','Spectral Floe','Subduction','Tem. Upheaval','Water Bomb'}

silibs.spells_by_name = {}
for k,v in pairs(res.spells) do
  silibs.spells_by_name[v.en] = v
end

silibs.snapshot_weapons = {
  ['Gastraphetes'] = 10,
  ['Acinaces'] = 6,
  ['Compensator'] = 10,
  ['Scout\'s Crossbow'] = 10,
  ['Arke Crossbow'] = 15,
  ['Sharanga'] = 20,
}

silibs.rare_ammo = S{'hauksbok arrow', 'hauksbok bullet', 'hauksbok bolt', 'animikii bullet'}
silibs.equip_locked_spells = S{'Honor March', 'Dispelga', 'Impact'}

silibs.pickable_locks = S{'Treasure Chest', 'Treasure Coffer', 'Chest', 'Coffer', 'Aurum Strongbox'}

silibs.slot_names = T{
  main='main',
  sub='sub',
  ranged='range',
  range='range',
  ammo='ammo',
  head='head',
  body='body',
  hands='hands',
  legs='legs',
  feet='feet',
  neck='neck',
  lear='left_ear',
  ear1='left_ear',
  learring='left_ear',
  left_ear='left_ear',
  rear='right_ear',
  ear2='right_ear',
  rearring='right_ear',
  right_ear='right_ear',
  lring='left_ring',
  ring1='left_ring',
  left_ring='left_ring',
  rring='right_ring',
  ring2='right_ring',
  right_ring='right_ring',
  back='back',
  waist='waist',
}


--=============================================================================
--=============================================================================
--=============================================================================
--               Fix/override base library's functions and variables
--=============================================================================
--=============================================================================
--=============================================================================

-- Overwrite base implementation of setting elemental gear (it's outdated)
function set_elemental_gear(spell)
end

spell_maps['Aspir III'] = 'Aspir'
spell_maps['Haste'] = 'Haste'
spell_maps['Haste II'] = 'Haste'
spell_maps['Dia II'] = 'Dia'
spell_maps['Dia III'] = 'Dia'
spell_maps['Diaga'] = 'Dia'
spell_maps['Bio II'] = 'Bio'
spell_maps['Bio III'] = 'Bio'
spell_maps['Poison II'] = 'Poison'
spell_maps['Absorb-STR'] = 'Absorb'
spell_maps['Absorb-DEX'] = 'Absorb'
spell_maps['Absorb-VIT'] = 'Absorb'
spell_maps['Absorb-AGI'] = 'Absorb'
spell_maps['Absorb-INT'] = 'Absorb'
spell_maps['Absorb-MND'] = 'Absorb'
spell_maps['Absorb-CHR'] = 'Absorb'
spell_maps['Absorb-ACC'] = 'Absorb'

-- Time delay definition of any function overrides in Mote-Include because it loads before this file
-- These overrides insert SilverLibs function calls where appropriate to automate library setup
function silibs.load_override_functions()
  if silibs.base_lib ~= 'selindrile' then -- Mote overrides
    -- Determines what functions get called when an action is used
    function handle_actions(spell, action)
      -- Init an eventArgs that allows cancelling.
      local eventArgs = {handled = false, cancel = false}

      mote_vars.set_breadcrumbs:clear()

      -- Get the spell mapping, since we'll be passing it to various functions and checks.
      local spellMap = get_spell_map(spell)

      -- General filter checks to see whether this function should be run.
      -- If eventArgs.cancel is set, cancels this function, not the spell.
      if _G['filter_'..action] then
        _G['filter_'..action](spell, spellMap, eventArgs)
      end

      -- If filter didn't cancel it, process user and default actions.
      if not eventArgs.cancel then
        -- Global user handling of this action
        if _G['user_'..action] then
          _G['user_'..action](spell, action, spellMap, eventArgs)

          if eventArgs.cancel then
            cancel_spell()
          end
        end

        if not eventArgs.cancel and not eventArgs.handled and silibs[action] then
          silibs[action](spell, action, spellMap, eventArgs)
        end

        -- Job-specific handling of this action
        if not eventArgs.cancel and not eventArgs.handled and _G['job_'..action] then
          _G['job_'..action](spell, action, spellMap, eventArgs)

          if eventArgs.cancel then
            cancel_spell()
          end
        end

        -- Default handling of this action
        if not eventArgs.cancel and not eventArgs.handled and _G['default_'..action] then
          _G['default_'..action](spell, spellMap)
          display_breadcrumbs(spell, spellMap, action)
        end

        -- Global post-handling of this action
        if not eventArgs.cancel and _G['user_post_'..action] then
          _G['user_post_'..action](spell, action, spellMap, eventArgs)
        end

        -- Job-specific post-handling of this action
        if not eventArgs.cancel and _G['job_post_'..action] then
          _G['job_post_'..action](spell, action, spellMap, eventArgs)
        end

        if not eventArgs.cancel and silibs['post_'..action] then
          silibs['post_'..action](spell, action, spellMap, eventArgs)
        end
      end

      -- Cleanup once this action is done
      if _G['cleanup_'..action] then
        _G['cleanup_'..action](spell, spellMap, eventArgs)
      end
    end

    -- Returns the appropriate idle set based on current state values and location.
    function get_idle_set(petStatus)
      local idleSet = sets.idle

      if not idleSet then
        return {}
      end

      mote_vars.set_breadcrumbs:append('sets')
      mote_vars.set_breadcrumbs:append('idle')

      local idleScope

      if buffactive.weakness then
        idleScope = 'Weak'
      elseif areas.Cities:contains(world.area) then
        idleScope = 'Town'
      else
        idleScope = 'Field'
      end

      if idleSet[idleScope] then
        idleSet = idleSet[idleScope]
        mote_vars.set_breadcrumbs:append(idleScope)
      end

      if idleSet[state.IdleMode.current] then
        idleSet = idleSet[state.IdleMode.current]
        mote_vars.set_breadcrumbs:append(state.IdleMode.current)
      end

      if (pet.isvalid or state.Buff.Pet) and idleSet.Pet then
        idleSet = idleSet.Pet
        petStatus = petStatus or pet.status
        mote_vars.set_breadcrumbs:append('Pet')

        if petStatus == 'Engaged' and idleSet.Engaged then
          idleSet = idleSet.Engaged
          mote_vars.set_breadcrumbs:append('Engaged')
        end
      end

      for _,group in ipairs(classes.CustomIdleGroups) do
        if idleSet[group] then
          idleSet = idleSet[group]
          mote_vars.set_breadcrumbs:append(group)
        end
      end

      idleSet = apply_defense(idleSet)
      idleSet = apply_kiting(idleSet)

      idleSet = silibs.customize_idle(idleSet)

      if user_customize_idle_set then
        idleSet = user_customize_idle_set(idleSet)
      end

      if customize_idle_set then
        idleSet = customize_idle_set(idleSet)
      end

      idleSet = silibs.post_customize_idle(idleSet)

      return idleSet
    end

    -- Returns the appropriate melee set based on current state values.
    function get_melee_set()
      local meleeSet = sets.engaged

      if not meleeSet then
        return {}
      end

      mote_vars.set_breadcrumbs:append('sets')
      mote_vars.set_breadcrumbs:append('engaged')

      if state.CombatForm.has_value and meleeSet[state.CombatForm.value] then
        meleeSet = meleeSet[state.CombatForm.value]
        mote_vars.set_breadcrumbs:append(state.CombatForm.value)
      end

      if state.CombatWeapon.has_value and meleeSet[state.CombatWeapon.value] then
        meleeSet = meleeSet[state.CombatWeapon.value]
        mote_vars.set_breadcrumbs:append(state.CombatWeapon.value)
      end

      if meleeSet[state.OffenseMode.current] then
        meleeSet = meleeSet[state.OffenseMode.current]
        mote_vars.set_breadcrumbs:append(state.OffenseMode.current)
      end

      if meleeSet[state.HybridMode.current] then
        meleeSet = meleeSet[state.HybridMode.current]
        mote_vars.set_breadcrumbs:append(state.HybridMode.current)
      end

      for _,group in ipairs(classes.CustomMeleeGroups) do
        if meleeSet[group] then
          meleeSet = meleeSet[group]
          mote_vars.set_breadcrumbs:append(group)
        end
      end

      meleeSet = apply_defense(meleeSet)
      meleeSet = apply_kiting(meleeSet)

      meleeSet = silibs.customize_melee(meleeSet)

      if customize_melee_set then
        meleeSet = customize_melee_set(meleeSet)
      end

      if user_customize_melee_set then
        meleeSet = user_customize_melee_set(meleeSet)
      end

      meleeSet = silibs.post_customize_melee(meleeSet)

      return meleeSet
    end

    -- Function to apply any active defense set on top of the supplied set
    function apply_defense(baseSet)
      if state.DefenseMode.current ~= 'None' then
        local defenseSet = sets.defense

        defenseSet = sets.defense[state[state.DefenseMode.current .. 'DefenseMode'].current] or defenseSet

        for _,group in ipairs(classes.CustomDefenseGroups) do
          defenseSet = defenseSet[group] or defenseSet
        end

        defenseSet = silibs.customize_defense(defenseSet)

        if customize_defense_set then
          defenseSet = customize_defense_set(defenseSet)
        end

        defenseSet = silibs.post_customize_defense(defenseSet)

        baseSet = set_combine(baseSet, defenseSet)
      end

      return baseSet
    end

    -- Routing function for general known self_commands.  Mappings are at the bottom of the file.
    -- Handles splitting the provided command line up into discrete words, for the other functions to use.
    function self_command(commandArgs)
      local commandArgs = commandArgs
      if type(commandArgs) == 'string' then
        commandArgs = T(commandArgs:split(' '))
        if #commandArgs == 0 then
          return
        end
      end

      -- init a new eventArgs
      local eventArgs = {handled = false}

      silibs.self_command(commandArgs, eventArgs)

      -- Allow jobs to override this code
      if job_self_command then
        job_self_command(commandArgs, eventArgs)
      end

      if not eventArgs.handled then
        -- Of the original command message passed in, remove the first word from
        -- the list (it will be used to determine which function to call), and
        -- send the remaining words as parameters for the function.
        local handleCmd = table.remove(commandArgs, 1)

        if selfCommandMaps[handleCmd] then
          selfCommandMaps[handleCmd](commandArgs)
        end
      end
    end
  else -- Selindrile overrides
    function handle_actions(spell, action)
      -- Init an eventArgs that allows cancelling.
      local eventArgs = {handled = false, cancel = false}

      mote_vars.set_breadcrumbs:clear()

      -- Get the spell mapping, since we'll be passing it to various functions and checks.
      local spellMap = get_spell_map(spell)
      gearswap.refresh_globals(false)

      -- General filter checks to see whether this function should be run.
      -- If eventArgs.cancel is set, cancels this function, not the spell.
      if _G['user_filter_'..action] then
        _G['user_filter_'..action](spell, spellMap, eventArgs)

        if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
          cancel_spell()
          return
        end
      end

      if _G['user_job_filter_'..action] and not eventArgs.cancel then
        _G['user_job_filter_'..action](spell, spellMap, eventArgs)

        if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
          cancel_spell()
          return
        end
      end

      if _G['job_filter_'..action] and not eventArgs.cancel then
        _G['job_filter_'..action](spell, spellMap, eventArgs)

        if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
          cancel_spell()
          return
        end
      end

      if _G['filter_'..action] and not eventArgs.cancel then
        _G['filter_'..action](spell, spellMap, eventArgs)

        if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
          cancel_spell()
          return
        end
      end

      -- If filter didn't cancel it, process user and default actions.
      if not eventArgs.cancel then
        -- Global user handling of this action
        if _G['user_'..action] then
          _G['user_'..action](spell, spellMap, eventArgs)

          if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
            cancel_spell()
            return
          end
        end

        if not eventArgs.cancel and not eventArgs.handled and silibs[action] then
          silibs[action](spell, action, spellMap, eventArgs)
        end

        -- Job-specific handling of this action
        if not eventArgs.cancel and not eventArgs.handled and _G['job_'..action] then
          _G['job_'..action](spell, spellMap, eventArgs)

          if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
              cancel_spell()
            return
          end
        end

        if not eventArgs.cancel and not eventArgs.handled and _G['user_job_'..action] then
          _G['user_job_'..action](spell, spellMap, eventArgs)

          if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
            cancel_spell()
            return
          end
        end

        -- Default handling of this action
        if not eventArgs.cancel and not eventArgs.handled and _G['default_'..action] then
          _G['default_'..action](spell, spellMap, eventArgs)
          display_breadcrumbs(spell, spellMap, action)

          if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
            cancel_spell()
            return
          end
        end

        -- Global user handling of this action
        if _G['extra_user_'..action] then
          _G['extra_user_'..action](spell, spellMap, eventArgs)

          if eventArgs.cancel and (action == 'pretarget' or action == 'precast') then
            cancel_spell()
            return
          end
        end

        -- Global post-handling of this action
        if not eventArgs.cancel and _G['user_post_'..action] then
          _G['user_post_'..action](spell, spellMap, eventArgs)
        end

        -- Job-specific post-handling of this action
        if not eventArgs.cancel and _G['job_post_'..action] then
          _G['job_post_'..action](spell, spellMap, eventArgs)
        end

        if not eventArgs.cancel and _G['user_job_post_'..action] then
          _G['user_job_post_'..action](spell, spellMap, eventArgs)
        end

        if not eventArgs.cancel and _G['default_post_'..action] then
          _G['default_post_'..action](spell, spellMap, eventArgs)
        end

        if not eventArgs.cancel and _G['extra_user_post_'..action] then
          _G['extra_user_post_'..action](spell, spellMap, eventArgs)
        end

        if not eventArgs.cancel and silibs['post_'..action] then
          silibs['post_'..action](spell, action, spellMap, eventArgs)
        end
      end

      -- Cleanup once this action is done
      if _G['cleanup_'..action] then
        _G['cleanup_'..action](spell, spellMap, eventArgs)
      end
    end

    -- Returns the appropriate idle set based on current state values and location.
    function get_idle_set(petStatus)
      local idleSet = sets.idle

      if not idleSet then
        return {}
      end

      mote_vars.set_breadcrumbs:append('sets')
      mote_vars.set_breadcrumbs:append('idle')

      if buffactive.weakness and sets.idle.Weak then
        idleSet = sets.idle.Weak
        mote_vars.set_breadcrumbs:append('Weak')
      end

      if not (player.in_combat or being_attacked) and (state.IdleMode.current:contains('DT') or state.IdleMode.current:contains('Tank')) then
        if state.NonCombatIdleMode and idleSet[state.NonCombatIdleMode.current] then
          idleSet = idleSet[state.NonCombatIdleMode.current]
          mote_vars.set_breadcrumbs:append(state.NonCombatIdleMode.current)
        end
      elseif idleSet[state.IdleMode.current] then
        idleSet = idleSet[state.IdleMode.current]
        mote_vars.set_breadcrumbs:append(state.IdleMode.current)
      end

      if (pet.isvalid or state.Buff.Pet) and idleSet.Pet then
        idleSet = idleSet.Pet
        petStatus = petStatus or pet.status
        mote_vars.set_breadcrumbs:append('Pet')

        if petStatus == 'Engaged' and idleSet.Engaged then
          idleSet = idleSet.Engaged
          mote_vars.set_breadcrumbs:append('Engaged')
        end
      end

      for _,group in ipairs(classes.CustomIdleGroups) do
        if idleSet[group] then
          idleSet = idleSet[group]
          mote_vars.set_breadcrumbs:append(group)
        end
      end

      if buffactive['Elvorseal'] and sets.buff.Elvorseal then
        idleSet = set_combine(idleSet, sets.buff.Elvorseal)
      end

      --Apply time based gear.
      if (state.IdleMode.value == 'Normal' or state.IdleMode.value:contains('Sphere')) and not pet.isvalid then
        if player.hpp < 80 then
          if sets.ExtraRegen then idleSet = set_combine(idleSet, sets.ExtraRegen) end
        end

        if classes.DuskToDawn then
          if sets.DuskIdle then idleSet = set_combine(idleSet, sets.DuskIdle) end
        end

        if classes.Daytime then
          if sets.DayIdle then idleSet = set_combine(idleSet, sets.DayIdle) end
        else
          if sets.NightIdle then idleSet = set_combine(idleSet, sets.NightIdle) end
        end
      end

      if data.areas.assault:contains(world.area) and sets.Assault then
        idleSet = set_combine(idleSet, sets.Assault)
      end
      
      if sets.Reive and buffactive['Reive Mark'] then
        idleSet = set_combine(idleSet, sets.Reive)
      end

      if user_customize_idle_set then
        idleSet = user_customize_idle_set(idleSet)
      end
    
      idleSet = silibs.customize_idle(idleSet)

      if job_customize_idle_set then
        idleSet = job_customize_idle_set(idleSet)
      end
    
      if user_job_customize_idle_set then
        idleSet = user_job_customize_idle_set(idleSet)
      end

      if data.areas.cities:contains(world.area) then
        if sets.idle.Town then
          idleSet = set_combine(idleSet, sets.Kiting, sets.idle.Town)
        elseif sets.Town then
          idleSet = set_combine(idleSet, sets.Kiting, sets.Town)
        else 
          idleSet = set_combine(idleSet, sets.Kiting)
        end

        if (world.area:contains('Adoulin') or world.area == "Celennia Memorial Library") and item_available("Councilor's Garb") then
          idleSet = set_combine(idleSet, {body="Councilor's Garb"})
        elseif (world.area:contains('Bastok') or world.area == "Metalworks") and item_available("Republic Aketon") then
          idleSet = set_combine(idleSet, {body="Republic Aketon"})
        elseif (world.area:contains('Windurst') or world.area == "Heavens Tower") and item_available("Federation Aketon") then
          idleSet = set_combine(idleSet, {body="Federation Aketon"})
        elseif (world.area:contains("San d'Oria") or world.area == "Chateau d'Oraguille") and item_available("Kingdom Aketon") then
          idleSet = set_combine(idleSet, {body="Kingdom Aketon"})
        elseif world.area == "Mog Garden" and item_available("Jubilee Shirt") then
          idleSet = set_combine(idleSet, {body="Jubilee Shirt"})
        end
      end

      idleSet = apply_passive(idleSet)

      if state.Capacity.value then 
        idleSet = set_combine(idleSet, sets.Capacity)
      end

      idleSet = apply_defense(idleSet)
      idleSet = apply_kiting(idleSet)

      if silent_check_disable() and state.DefenseMode.value == 'None' then
        if state.IdleMode.value:contains('MDT') and sets.defense.MDT then
          idleSet = set_combine(idleSet, sets.defense.MDT)
        elseif sets.defense.PDT then
          idleSet = set_combine(idleSet, sets.defense.PDT)
        end
      end

      if state.UnlockWeapons.value and sets.weapons[state.Weapons.value] then
        idleSet = set_combine(idleSet, sets.weapons[state.Weapons.value])
      end

      if (buffactive.sleep or buffactive.Lullaby) and sets.IdleWakeUp then
        if item_available("Sacrifice Torque") and player.main_job == 'SMN' and pet.isvalid then
          idleSet = set_combine(idleSet, sets.IdleWakeUp)
        elseif item_available("Prime Horn") and player.main_job == 'BRD' then
          idleSet = set_combine(idleSet, sets.IdleWakeUp)    
        elseif state.Weapons.value == 'None' or state.UnlockWeapons.value then
            idleSet = set_combine(idleSet, sets.IdleWakeUp)
        elseif state.PWUnlock.value then
          windower.send_command('gs c set unlockweapons true; wait 1; gs c set unlockweapons false')
          idleSet = set_combine(idleSet, sets.IdleWakeUp)
        end
      end

      if buffactive.doom then
        idleSet = set_combine(idleSet, sets.buff.Doom)
      end

      if extra_user_customize_idle_set then
        idleSet = extra_user_customize_idle_set(idleSet)
      end

      idleSet = silibs.post_customize_idle(idleSet)

      return idleSet
    end


    -- Returns the appropriate melee set based on current state values.
    -- Set construction order (all sets after sets.engaged are optional):
    --   sets.engaged[state.CombatForm][state.CombatWeapon][state.OffenseMode][state.DefenseMode][classes.CustomMeleeGroups (any number)]
    function get_melee_set()
      local meleeSet = sets.engaged

      if not meleeSet then
        return {}
      end

      mote_vars.set_breadcrumbs:append('sets')
      mote_vars.set_breadcrumbs:append('engaged')

      if state.CombatForm.has_value and meleeSet[state.CombatForm.value] then
        meleeSet = meleeSet[state.CombatForm.value]
        mote_vars.set_breadcrumbs:append(state.CombatForm.value)
      end

      if state.CombatWeapon.has_value and meleeSet[state.CombatWeapon.value] then
        meleeSet = meleeSet[state.CombatWeapon.value]
        mote_vars.set_breadcrumbs:append(state.CombatWeapon.value)
      end

      if meleeSet[state.OffenseMode.current] then
        meleeSet = meleeSet[state.OffenseMode.current]
        mote_vars.set_breadcrumbs:append(state.OffenseMode.current)
      end

      if meleeSet[state.HybridMode.current] then
        meleeSet = meleeSet[state.HybridMode.current]
        mote_vars.set_breadcrumbs:append(state.HybridMode.current)
      end

      for _,group in ipairs(classes.CustomMeleeGroups) do
        if meleeSet[group] then
          meleeSet = meleeSet[group]
          mote_vars.set_breadcrumbs:append(group)
        end
      end

      if user_customize_melee_set then
        meleeSet = user_customize_melee_set(meleeSet)
      end

      meleeSet = silibs.customize_melee(meleeSet)

      if job_customize_melee_set then
        meleeSet = job_customize_melee_set(meleeSet)
      end

      if user_job_customize_melee_set then
        meleeSet = user_job_customize_melee_set(meleeSet)
      end

      if buffactive['Elvorseal'] and sets.buff.Elvorseal then
        meleeSet = set_combine(meleeSet, sets.buff.Elvorseal)
      end

      if state.ExtraMeleeMode and state.ExtraMeleeMode.value ~= 'None' then
        meleeSet = set_combine(meleeSet, sets[state.ExtraMeleeMode.value])
      end

      meleeSet = apply_passive(meleeSet)

      if state.Capacity.value == true then 
        meleeSet = set_combine(meleeSet, sets.Capacity)
      end

      meleeSet = apply_defense(meleeSet)
      meleeSet = apply_kiting(meleeSet)

      if silent_check_disable() and state.DefenseMode.value == 'None' then
        if state.HybridMode.value:contains('MDT') and sets.defense.MDT then
          meleeSet = set_combine(meleeSet, sets.defense.MDT)
        elseif sets.defense.PDT then
          meleeSet = set_combine(meleeSet, sets.defense.PDT)
        end
      end

      if buffactive['Reive Mark'] and sets.Reive then
        meleeSet = set_combine(meleeSet, sets.Reive)
      end

      if (buffactive.sleep or buffactive.Lullaby) and sets.buff.Sleep then
        if (item_available("Vim Torque") or item_available("Vim Torque +1")) and (player.main_job == 'WAR' or player.main_job == 'PLD' or player.main_job == 'DRK' or player.main_job == 'SAM' or player.main_job == 'DRG') then
          meleeSet = set_combine(meleeSet, sets.buff.Sleep)
        elseif item_available("Frenzy Sallet") and (player.main_job == 'MNK' or player.main_job == 'THF' or player.main_job == 'DRK' or player.main_job == 'BST' or player.main_job == 'SAM' or player.main_job == 'DRG' or player.main_job == 'DNC' or player.main_job == 'RUN') then
          meleeSet = set_combine(meleeSet, sets.buff.Sleep)
        elseif item_available("Berserker's Torque") and (player.main_job == 'WAR' or player.main_job == 'PLD' or player.main_job == 'DRK' or player.main_job == 'SAM' or player.main_job == 'DRG') then
          meleeSet = set_combine(meleeSet, sets.buff.Sleep)
        elseif state.Weapons.value == 'None' or state.UnlockWeapons.value then
          meleeSet = set_combine(meleeSet, sets.buff.Sleep)
        elseif state.PWUnlock.value then
          windower.send_command('gs c set unlockweapons true; wait 1; gs c set unlockweapons false')
          meleeSet = set_combine(meleeSet, sets.buff.Sleep)
        end
      end

      if buffactive.doom then
        meleeSet = set_combine(meleeSet, sets.buff.Doom)
      end

      if extra_user_customize_melee_set then
        meleeSet = extra_user_customize_melee_set(meleeSet)
      end

      if state.UnlockWeapons.value and sets.weapons[state.Weapons.value] then
        meleeSet = set_combine(meleeSet, sets.weapons[state.Weapons.value])
      end

      meleeSet = silibs.post_customize_melee(meleeSet)

      return meleeSet
    end

    -- Function to apply any active defense set on top of the supplied set
    function apply_defense(baseSet)
      if state.DefenseMode.current ~= 'None' then
        local defenseSet = sets.defense

        defenseSet = sets.defense[state[state.DefenseMode.current .. 'DefenseMode'].current] or defenseSet

        for _,group in ipairs(classes.CustomDefenseGroups) do
          defenseSet = defenseSet[group] or defenseSet
        end

        if sets.Reive and buffactive['Reive Mark'] and sets.Reive.neck == "Adoulin's Refuge +1" then
          defenseSet = set_combine(defenseSet, sets.Reive)
        end

        if user_customize_defense_set then
          defenseSet = user_customize_defense_set(defenseSet)
        end

        defenseSet = silibs.customize_defense(defenseSet)

        if job_customize_defense_set then
          defenseSet = job_customize_defense_set(defenseSet)
        end

        if user_job_customize_defense_set then
          defenseSet = user_job_customize_defense_set(defenseSet)
        end

        defenseSet = silibs.post_customize_defense(defenseSet)

        baseSet = set_combine(baseSet, defenseSet)
      end

      return baseSet
    end

    -- Routing function for general known self_commands.  Mappings are at the bottom of the file.
    -- Handles splitting the provided command line up into discrete words, for the other functions to use.
    function self_command(commandArgs)
      local originalCommand = commandArgs
        if type(commandArgs) == 'string' then
          commandArgs = T(commandArgs:split(' '))
          if #commandArgs == 0 then
            return
          end
        end

      if commandArgs[#commandArgs]:startswith('<st') then
        local st_variable = (table.remove(commandArgs, #commandArgs)):lower()
        st_command = table.concat(commandArgs, ' ')
        windower.chat.input('/dance motion '..st_variable..'')
        return
      end

      -- init a new eventArgs
      local eventArgs = {handled = false}

      silibs.self_command(commandArgs, eventArgs)

      -- Allow users to override this code
      if user_job_self_command then
        user_job_self_command(commandArgs, eventArgs)
      end

      -- Allow jobs to override this code
      if not eventArgs.handled and job_self_command then
        job_self_command(commandArgs, eventArgs)
      end

      -- Allow jobs to override this code
      if not eventArgs.handled and user_self_command then
        user_self_command(commandArgs, eventArgs)
      end

      if not eventArgs.handled then
        -- Of the original command message passed in, remove the first word from
        -- the list (it will be used to determine which function to call), and
        -- send the remaining words as parameters for the function.
        local handleCmd = (table.remove(commandArgs, 1)):lower()

        if selfCommandMaps[handleCmd] then
          selfCommandMaps[handleCmd](commandArgs)
        end
      end
    end
  end
end

-- Function to cancel buffs if they'd conflict with using the spell you're attempting.
-- Requirement: Must have Cancel addon installed and loaded for this to work.
-- Main job specific logic has moved to job files instead of this global function.
if silibs.base_lib ~= 'selindrile' then -- Only overwrite Mote's version, not Selindrile's to avoid breaking stuff.
  cancel_conflicting_buffs = function(spell, action, spellMap, eventArgs)
    if (spell.english == 'Spectral Jig' or spell.english == 'Monomi: Ichi' or (spell.english == 'Sneak' and spell.target.type == 'SELF')) and buffactive['Sneak'] then
      send_command('cancel sneak')
    elseif spell.english == 'Utsusemi: Ni' or spell.english == 'Utsusemi: Ichi' then
      -- Prevent casting Utsusemi if you already have 3+ shadows
      if buffactive['Copy Image (3)'] or buffactive['Copy Image (4+)'] then
        add_to_chat(123, '**!! '..spell.english..' Canceled: [3+ IMAGES] !!**')
        cancel_spell()
        eventArgs.cancel = true
      else
        send_command('cancel copy image*')
      end
    elseif spell.english == ('Stoneskin') then
      send_command('@wait 1;cancel stoneskin')
    elseif spell.english == 'Valiance' then
      local abil_recasts = windower.ffxi.get_ability_recasts()
      -- Use Vallation if Valiance is on cooldown or not available at current master level
      if abil_recasts[spell.recast_id] >= 2 or (player.main_job ~= 'RUN' and player.sub_job_level < 50) then
        send_command('input /jobability "Vallation" <me>')
        cancel_spell()
        eventArgs.cancel = true
      -- Cancel Vallation buff before using Valiance
      elseif abil_recasts[spell.recast_id] < 2 and buffactive['Vallation'] then
        cast_delay(0.2)
        send_command('cancel Vallation') -- command requires 'cancel' add-on to work
      end
    -- Cancel Valiance buff before using Vallation
    elseif spell.english == 'Vallation' then
      local abil_recasts = windower.ffxi.get_ability_recasts()
      if buffactive['Valiance'] and abil_recasts[spell.recast_id] < 2 then
        cast_delay(0.2)
        send_command('cancel Valiance') -- command requires 'cancel' add-on to work
      end
    end
  end
end


--=============================================================================
--=============================================================================
--=============================================================================
--                               Initialization
--=============================================================================
--=============================================================================
--=============================================================================

options = options or {}
state = state or {}
info = info or {}
info.tagged_mobs = T{}

function silibs.init_settings()
  -- States
  -- TH mode handling
  state.TreasureMode = M{['description']='Treasure Mode'}
  if player.main_job == 'THF' then
      state.TreasureMode:options('None','Tag','SATA','Fulltime')
  else
      state.TreasureMode:options('None','Tag')
  end
  state.RearmingLock = M(false, 'Rearming Lock')
  state.ShowLuopanUi = M(false, 'Show Luopan UI')
  state.AutoReraise = M{['description']='Auto Reraise Mode', 'Off', 'On', 'Auto'}

  -- Feature flags
  silibs.cancel_outranged_ws_enabled = false
  silibs.cancel_on_blocking_status_enabled = false
  silibs.weapon_rearm_enabled = false
  silibs.auto_lockstyle_enabled = false
  silibs.premade_commands_enabled = false
  silibs.force_lower_cmd = false
  silibs.th_enabled = false
  silibs.th_aoe_disabled = false
  silibs.equip_loop_enabled = false
  silibs.quick_magic_spells = silibs.default_quick_magic_spells:copy()
  silibs.custom_roll_text_enabled = {
    show_self = false,
    show_others = false,
  }
  silibs.custom_roll_timers_enabled = false
  silibs.haste_info_enabled = false
  silibs.elemental_belt_handling_enabled = false
  silibs.elemental_belt_handling_condition = nil
  silibs.snapshot_auto_equip_enabled = false
  silibs.handle_ammo_swaps_enabled = false
  silibs.auto_reraise_enabled = false
  silibs.lock_on_usable_items_enabled = false

  -- Other variables
  -- Most recent weapons (used for re-arming)
  silibs.most_recent_weapons = {main='',sub='',ranged='',ammo=''}
  silibs.lockstyle_set = 0
  silibs.locked_style = false
  silibs.encumbrance = 0
  silibs.waltz_stats = {
    base_chr = 100,
    base_vit = 100,
    bonus_chr = 100,
    bonus_vit = 100,
    waltz_potency = 25,
    waltz_self_potency = 15,
    est_non_party_target_hp = 2000,
  }
  silibs.th_aoe_actions = {
    weaponskills = {
      ['Aeolian Edge'] = {id=30,en='Aeolian Edge',ja='イオリアンエッジ',element=2,icon_id=595,prefix='/weaponskill',range=2,skill=2,skillchain_a='Impaction',skillchain_b='Scission',skillchain_c='Detonation',targets=32,aoe_range=10,aoe_center_self=false},
      ['Cyclone'] = {id=20,en='Cyclone',ja='サイクロン',element=2,icon_id=595,prefix='/weaponskill',range=10,skill=2,skillchain_a='Detonation',skillchain_b='Impaction',skillchain_c='',targets=32,aoe_range=10,aoe_center_self=false},
      ['Shockwave'] = {id=52,en='Shockwave',ja='ショックウェーブ',element=7,icon_id=604,prefix='/weaponskill',range=2,skill=4,skillchain_a='Reverberation',skillchain_b='',skillchain_c='',targets=32,aoe_range=10,aoe_center_self=false},
      ['Earth Crusher'] = {id=178,en='Earth Crusher',ja='アースクラッシャー',element=3,icon_id=632,prefix='/weaponskill',range=2,skill=12,skillchain_a='Detonation',skillchain_b='Impaction',skillchain_c='',targets=32,aoe_range=5,aoe_center_self=false},
      ['Cataclysm'] = {id=189,en='Cataclysm',ja='カタクリスム',element=7,icon_id=633,prefix='/weaponskill',range=2,skill=12,skillchain_a='Compression',skillchain_b='Reverberation',skillchain_c='',targets=32,aoe_range=10,aoe_center_self=false},
    },
    spells = {
      ['Diaga'] = {id=33,en='Diaga',ja='ディアガ',cast_time=1.5,element=6,icon_id=101,icon_id_nq=6,levels={[3]=18,[5]=15},mp_cost=12,prefix='/magic',range=12,recast=6,recast_id=33,requirements=0,skill=35,targets=32,type='WhiteMagic',aoe_range=10,aoe_center_self=false},
      ['Banishga'] = {id=38,en='Banishga',ja='バニシュガ',cast_time=2.75,element=6,icon_id=112,icon_id_nq=6,levels={[3]=15,[7]=30},mp_cost=41,prefix='/magic',range=12,recast=15,recast_id=38,requirements=0,skill=32,targets=32,type='WhiteMagic',aoe_range=10,aoe_center_self=false},
      ['Firaga'] = {id=174,en='Firaga',ja='ファイガ',cast_time=2,element=0,icon_id=245,icon_id_nq=8,levels={[4]=28},mp_cost=57,prefix='/magic',range=12,recast=5,recast_id=174,requirements=0,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=false},
      ['Blizzaga'] = {id=179,en='Blizzaga',ja='ブリザガ',cast_time=2,element=1,icon_id=274,icon_id_nq=9,levels={[4]=32},mp_cost=80,prefix='/magic',range=12,recast=5,recast_id=179,requirements=0,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=false},
      ['Aeroga'] = {id=184,en='Aeroga',ja='エアロガ',cast_time=2,element=2,icon_id=285,icon_id_nq=10,levels={[4]=23},mp_cost=45,prefix='/magic',range=12,recast=5,recast_id=184,requirements=0,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=false},
      ['Stonega'] = {id=189,en='Stonega',ja='ストンガ',cast_time=2,element=3,icon_id=215,icon_id_nq=11,levels={[4]=15},mp_cost=24,prefix='/magic',range=12,recast=5,recast_id=189,requirements=0,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=false},
      ['Thundaga'] = {id=194,en='Thundaga',ja='サンダガ',cast_time=2,element=4,icon_id=265,icon_id_nq=12,levels={[4]=36},mp_cost=105,prefix='/magic',range=12,recast=5,recast_id=194,requirements=0,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=false},
      ['Waterga'] = {id=199,en='Waterga',ja='ウォタガ',cast_time=2,element=5,icon_id=254,icon_id_nq=13,levels={[4]=19},mp_cost=34,prefix='/magic',range=12,recast=5,recast_id=199,requirements=0,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=false},
      ['Poisonga'] = {id=225,en='Poisonga',ja='ポイゾガ',cast_time=2,element=5,icon_id=228,icon_id_nq=13,levels={[4]=24,[8]=26},mp_cost=44,prefix='/magic',range=12,recast=10,recast_id=225,requirements=0,skill=35,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=false},
      ['Venom Shell'] = {id=513,en='Venom Shell',ja='ベノムシェル',blu_points=3,cast_time=3,element=5,icon_id=-1,icon_id_nq=61,levels={[16]=42},mp_cost=86,prefix='/magic',range=4,recast=45,recast_id=513,requirements=0,skill=43,status=41,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=true},
      ['Mysterious Light'] = {id=534,en='Mysterious Light',ja='神秘の光',blu_points=4,cast_time=3.75,element=2,icon_id=-1,icon_id_nq=58,levels={[16]=40},mp_cost=73,prefix='/magic',range=4,recast=24.5,recast_id=534,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=true},
      ['Stinking Gas'] = {id=537,en='Stinking Gas',ja='スティンキングガス',blu_points=2,cast_time=4,element=2,icon_id=-1,icon_id_nq=58,levels={[16]=44},mp_cost=37,prefix='/magic',range=4,recast=60,recast_id=537,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=true},
      ['Blood Saber'] = {id=541,en='Blood Saber',ja='ブラッドセイバー',blu_points=2,cast_time=4,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=48},mp_cost=25,prefix='/magic',range=4,recast=26,recast_id=541,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=true},
      ['Cursed Sphere'] = {id=544,en='Cursed Sphere',ja='カースドスフィア',blu_points=2,cast_time=3,element=5,icon_id=-1,icon_id_nq=61,levels={[16]=18},mp_cost=36,prefix='/magic',range=9,recast=19.5,recast_id=544,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=false},
      ['Sound Blast'] = {id=572,en='Sound Blast',ja='サウンドブラスト',blu_points=1,cast_time=4,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=32},mp_cost=25,prefix='/magic',range=4,recast=30,recast_id=572,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=true},
      ['Sheep Song'] = {id=584,en='Sheep Song',ja='シープソング',blu_points=2,cast_time=3,duration=60,element=6,icon_id=-1,icon_id_nq=62,levels={[16]=16},mp_cost=22,prefix='/magic',range=4,recast=60,recast_id=584,requirements=0,skill=43,status=2,targets=32,type='BlueMagic',aoe_range=4.97,aoe_center_self=true},
      ['Soporific'] = {id=598,en='Soporific',ja='サペリフィック',blu_points=4,cast_time=3,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=24},mp_cost=38,prefix='/magic',range=4,recast=26,recast_id=598,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=4.97,aoe_center_self=true},
      ['Geist Wall'] = {id=605,en='Geist Wall',ja='ガイストウォール',blu_points=3,cast_time=3,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=46},mp_cost=35,prefix='/magic',range=4,recast=30,recast_id=605,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=4.97,aoe_center_self=true},
      ['Blastbomb'] = {id=618,en='Blastbomb',ja='炸裂弾',blu_points=2,cast_time=2.25,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=18},mp_cost=36,prefix='/magic',range=9,recast=15,recast_id=618,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=false},
      ['Battledance'] = {id=620,en='Battle Dance',ja='バトルダンス',blu_points=3,cast_time=1,element=15,icon_id=-1,icon_id_nq=64,levels={[16]=12},mp_cost=12,prefix='/magic',range=4,recast=10,recast_id=620,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=true},
      ['Grand Slam'] = {id=622,en='Grand Slam',ja='グランドスラム',blu_points=2,cast_time=1,element=15,icon_id=-1,icon_id_nq=64,levels={[16]=30},mp_cost=24,prefix='/magic',range=4,recast=14.25,recast_id=622,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=true},
      ['Bomb Toss'] = {id=626,en='Bomb Toss',ja='爆弾投げ',blu_points=3,cast_time=3.75,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=28},mp_cost=42,prefix='/magic',range=9,recast=24.5,recast_id=626,requirements=0,skill=43,targets=32,type='BlueMagic',aoe_range=5,aoe_center_self=false},
      ['Fira'] = {id=828,en='Fira',ja='ファイラ',cast_time=1.5,element=0,icon_id=245,icon_id_nq=8,levels={[21]=40},mp_cost=93,prefix='/magic',range=8,recast=5,recast_id=828,requirements=64,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=true},
      ['Blizzara'] = {id=830,en='Blizzara',ja='ブリザラ',cast_time=1.5,element=1,icon_id=274,icon_id_nq=9,levels={[21]=45},mp_cost=108,prefix='/magic',range=8,recast=5,recast_id=830,requirements=64,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=true},
      ['Aera'] = {id=832,en='Aera',ja='エアロラ',cast_time=1.5,element=2,icon_id=285,icon_id_nq=10,levels={[21]=35},mp_cost=79,prefix='/magic',range=8,recast=5,recast_id=832,requirements=64,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=true},
      ['Stonera'] = {id=834,en='Stonera',ja='ストンラ',cast_time=1.5,element=3,icon_id=215,icon_id_nq=11,levels={[21]=25},mp_cost=54,prefix='/magic',range=8,recast=5,recast_id=834,requirements=64,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=true},
      ['Thundara'] = {id=836,en='Thundara',ja='サンダラ',cast_time=1.5,element=4,icon_id=265,icon_id_nq=12,levels={[21]=50},mp_cost=123,prefix='/magic',range=8,recast=5,recast_id=836,requirements=64,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=true},
      ['Watera'] = {id=838,en='Watera',ja='ウォタラ',cast_time=1.5,element=5,icon_id=254,icon_id_nq=13,levels={[21]=30},mp_cost=66,prefix='/magic',range=8,recast=5,recast_id=838,requirements=64,skill=36,targets=32,type='BlackMagic',aoe_range=10,aoe_center_self=true},
    },
    abilities = {}
  }
  silibs.last_indi = nil
  silibs.last_geo = nil
  silibs.ui = {
    --Luopan Distance Tracking
    luopan = texts.new('${value}', {
      pos = { x=-130, y=80, },
      text = { font='Arial', size=12, },
      flags = { right=true, bold=true, },
      bg = { alpha=0, },
      stroke = { width=2, alpha=192 },
    }),
    bt_color = '\\cs(230,118,116)'
  }
  silibs.dw_needed = 0
  silibs.snapshot_sets = nil
  -- Time in Earth seconds from Unix epoch to the start of the current vana'diel era
  silibs.start_of_era = 0
  silibs.is_doubling_up = nil
  silibs.latest_flurry_buff = nil
  silibs.has_orpheus = false
  silibs.has_obi = false
  silibs.is_double_up_active = false
  silibs.self_timers_symbol = '@'
  -- This map will be used by SilverLibs to determine which ammo to use
  -- Default: Used most of the time. It is also the fallback option in case you don't have any of the other ammo.
  -- Accuracy: Used in high accuracy situations.
  -- Physical_Weaponskill_Ranged: Used for ranged physical weaponskills.
  -- Magic_Damage: Used when you are dealing magic damage.
  -- Magic_Accuracy: Used for Light Shot and Dark Shot.
  -- Quick_Draw: Used when performing Quick Draws (not Light or Dark). This ammo is never consumed.
  -- Physical_Weaponskill_Melee: Used for melee physical weaponskills.
  -- Magical_Weaponskill_Melee: Used for melee magical weaponskills.
  silibs.ammo_assignment = nil
  silibs.auto_reraise_config = {
    set = nil,
    mode = 'off',
    hpp = 10,
  }
  silibs.auto_reraise_hpp_threshold = 10
  -- Each slot can have various locks including manual (set by player calling a command),
  -- and potentially several automated locks used by SilverLibs features such as
  -- when `lock_on_usable_items_enabled` and a usable item is equipped.
  -- Each slot uses a Set to contain locks. Gear swapping will only be allowed for
  -- a slot with an empty Set of locks.
  silibs.locked_slots = {}
  for slot_name in gearswap.default_slot_map:it() do
    silibs.locked_slots[slot_name] = S{}
  end

  -- One-off commands to execute on load

  -- Refresh vana'diel clock offset
  local last_time_packet = windower.packets.last_incoming(0x037)
  if last_time_packet then
    silibs.parse_packet('0x037', last_time_packet)
  end

  silibs.last_midcast_set = {} -- Saves the last midcast set used

  silibs.reset_midaction()
end


--=============================================================================
--=============================================================================
--=============================================================================
--                        General purpose functions
--=============================================================================
--=============================================================================
--=============================================================================
-- Functions that may be used internally by SilverLibs but are also easily
-- able to be used for more general purposes.

-- item_name: string, name of item to search
-- bags_to_search: List (optional), list of bags to search through
-- is_temp_item: boolean (optional), indicates if item is temporary item
function silibs.has_item(item_name, bags_to_search, is_temp_item)
  if item_name and item_name ~= '' then
    local bags
    if is_temp_item then
      bags = L{'temporary'}
    else
      bags = bags_to_search or L{'inventory','safe','storage','locker',
          'satchel','sack','case','wardrobe','safe2','wardrobe2','wardrobe3',
          'wardrobe4','wardrobe5','wardrobe6','wardrobe7','wardrobe8'}
    end
    for bag,_ in bags:it() do
      if player[bag] and player[bag][item_name] then
        return player[bag][item_name]
      end
    end
  end
  
  return false
end

function silibs.find_ability(ability_name)
  return res.job_abilities:find(function(ability)
    return ability[language] == ability_name
  end)
end

function silibs.get_ability_table_by_name(ability_name)
  local _, ability = silibs.find_ability(ability_name)
  return ability
end

function silibs.find_spell(spell_name)
  return res.spells:find(function(s)
    return s[language] == spell_name
  end)
end

function silibs.get_spell_table_by_name(spell_name)
  local _, spell = silibs.find_spell(spell_name)
  return spell
end

function silibs.can_access_ability(ability_name)
  local ability_ids = S(windower.ffxi.get_abilities().job_abilities)
  return ability_ids:contains(silibs.find_ability(ability_name))
end

function silibs.can_access_spell(spell_name, spell)
  if spell_name and not spell then
    spell = silibs.get_spell_table_by_name(spell_name)
  end
  local has_learned_spell = windower.ffxi.get_spells()[spell.id] == true
	local spell_jobs = res.spells[spell.id].levels

	-- Filter for spells that you do not know. Exclude Impact, Honor March and Dispelga.
	if not has_learned_spell and not (spell.id == 503 or spell.id == 417 or spell.id == 360) then
		return false
	-- Filter for spells that you know, but do not currently have access to
	elseif (not spell_jobs[player.main_job_id]
      or not (spell_jobs[player.main_job_id] <= player.main_job_level
        or (spell_jobs[player.main_job_id] >= 100
          and silibs.number_of_jps(player.job_points[(res.jobs[player.main_job_id].ens):lower()]) >= spell_jobs[player.main_job_id]
        )
      )
    )
    and (not spell_jobs[player.sub_job_id] or not (spell_jobs[player.sub_job_id] <= player.sub_job_level)) then
		  return false
	elseif res.spells[spell.id].type == 'BlueMagic'
    and not (
      (player.main_job_id == 16
        and (data.spells.unbridled:contains(res.spells[spell.id].en)
         or table.contains(windower.ffxi.get_mjob_data().spells,spell.id)
        )
      )
      or (player.sub_job_id == 16 and table.contains(windower.ffxi.get_sjob_data().spells,spell.id))
    ) then	
		  return false
	else
		return true
	end
end

function silibs.can_recast_ability(ability_name, time)
  time = time or 1
  local ability = silibs.get_ability_table_by_name(ability_name)
  return windower.ffxi.get_ability_recasts()[ability.recast_id] <= time
end

function silibs.can_recast_spell(spell_name, time)
  time = time or 1
  local spell = silibs.get_spell_table_by_name(spell_name)
  return windower.ffxi.get_spell_recasts()[spell.recast_id] <= time
end

-- Takes in a mob table or spawn_type and determines if target is enemy
function silibs.is_target_enemy(mob_table)
  return (mob_table and mob_table.spawn_type == 16) or mob_table == 16
end

-- Returns table of monsters within given distance, accounting for model sizes
-- Given range must be in yalms
-- TODO: Observe npc update packets and keep list of mobs in memory
function silibs.get_enemies_in_range(range, aoe_center_target)
  local return_list = T{}
  local center = aoe_center_target or player
  local npcs = windower.ffxi.get_mob_array()
  for index,mob in pairs(npcs) do
    -- Check if mob is monster
    if mob and mob.spawn_type == 16 then
      -- Check if in range (aoe do not account for model size or z axis distance)
      local distance = math.sqrt((mob.x - center.x)^2 + (mob.y - center.y)^2)
      local is_in_range = distance <= (center.model_size + range + mob.model_size)
      if is_in_range then
        return_list:append(mob)
      end
    end
  end
  return return_list
end

-- Function to get the current weather intensity: 0 for none, 1 for single weather, 2 for double weather.
function silibs.get_weather_intensity()
  return gearswap.res.weather[world.weather_id].intensity
end

-- Returns details of item if you have it. Optional get_count boolean will
-- also return count of all instances of the item with that name that you
-- have in all wardrobes and inventory. get_count defaults to true
function silibs.get_item(item_name, --[[optional]]get_count)
  if get_count == nil then
    get_count = true
  end
  local item = nil
  local count = 0
  if item_name and item_name ~= '' then
    local bags = L{'inventory','wardrobe','wardrobe2','wardrobe3','wardrobe4','wardrobe5','wardrobe6','wardrobe7','wardrobe8'}
    for bag,_ in bags:it() do
      if player[bag] and player[bag][item_name] then
        item = player[bag][item_name]
        if not get_count then return end
        count = count + (item.count or 1)
      end
    end
  end
  if item then
    item.count = count
  end
  return item
end

function silibs.get_dual_wield_needed()
  if silibs.haste_info_enabled then
    return silibs.dw_needed
  end
end

function silibs.is_weapon(input)
  -- Check if input is a weapon table {name='...', augments='...'} or a string
  local weapon_name = type(input) == 'table' and input.name or input
  if weapon_name then
    local item = res.items:with('en', weapon_name)
    if item and item.category == 'Weapon' then
      -- Ensure it's not a grip, which also have category as "Weapon"
      if item.slots ~= S{1} then
        return true
      end
    end
  end
  return false
end

-- Check sub slot to see if you currently have equipped weapons in a dual wielding configuration
function silibs.is_dual_wielding()
  local sub_weapon_name = sub_weapon_name or (player and player.equipment and player.equipment.sub)
  return silibs.is_weapon(sub_weapon_name)
end

function silibs.can_dual_wield()
  local abilities = windower.ffxi.get_abilities()
  local traits = S(abilities.job_traits)
  if traits:contains(18) then
    return true
  end
  return false
end

function silibs.actual_cost(spell)
  local cost = spell.mp_cost
  if buffactive['Manafont'] or buffactive['Manawell'] then
    return 0
  elseif spell.type == 'WhiteMagic' then
    if buffactive['Penury'] then
      return cost * 0.5
    elseif buffactive['Light Arts'] or buffactive['Addendum: White'] then
      return cost * 0.9
    elseif buffactive['Dark Arts'] or buffactive['Addendum: Black'] then
      return cost * 1.1
    end
  elseif spell.type == 'BlackMagic' then
    if buffactive['Parsimony'] then
      return cost * 0.5
    elseif buffactive['Dark Arts'] or buffactive['Addendum: Black'] then
      return cost * 0.9
    elseif buffactive['Light Arts'] or buffactive['Addendum: White'] then
      return cost * 1.1
    end
  end
  return cost
end

-- Credit to Rubenator
function silibs.get_equipped_item_data(slot)
  local item = gearswap.items[gearswap.to_windower_bag_api(gearswap.res.bags[gearswap.items.equipment[slot].bag_id].en)][gearswap.items.equipment[slot].slot]
  return player.equipment[slot] ~= empty and item and item.id and gearswap.res.items[item.id] or 'empty'
end

function silibs.midaction()
  return silibs.is_midaction
end

-- Lock name is required, must be the first parameter, and cannot be a "slot" name.
-- All other parameters should be slot names or 'all' indicating which slots to lock.
function silibs.lock(lock_name, ...)
  -- Parameters are accessed in the magic "arg" variable
  for k,v in pairs(arg) do
    if v then
      -- Force all parameters to lowercase string
      v = tostring(v):lower()
    end
  end

  -- Ensure lock name is not a slot or 'all'
  if silibs.slot_names:contains(lock_name) or lock_name == 'all' then
    windower.add_to_chat(123, 'SilverLibs: Lock name \''..lock_name..'\' is invalid.')
    return
  end

  -- If 'all' is specified as one of the params, update slot list to include all slots
  local is_all_slots = false
  if table.contains(arg, 'all') or arg.n == 0 then
    is_all_slots = true
    -- Update list to include all slot names
    arg = gearswap.default_slot_map
  end

  -- Remove extra table parameter
  arg.n=nil

  local errorSlots = L{}
  for k,v in pairs(arg) do
    if v then
      local slot_name = silibs.slot_names[v]
      if slot_name then
        -- Lock slot
        silibs.locked_slots[slot_name]:add(lock_name)
      else
        errorSlots:append(v)
      end
    end
  end

  if lock_name == 'manual' then
    if errorSlots:length() == 0 then
      -- Print success message
      local succStr = is_all_slots and 'all' or table.concat(arg, ', ')
      windower.add_to_chat(1, string.char(0x1F, 207)..'SilverLibs: \''..lock_name..'\' lock added to ['..succStr..'] slots.')
    elseif errorSlots:length() == 1 then
      -- Print single error message
      local errStr = errorSlots:concat(', ')
      windower.add_to_chat(123, 'SilverLibs: ['..errStr..'] is not a valid slot name.')
    else
      -- Print plural error message
      local errStr = errorSlots:concat(', ')
      windower.add_to_chat(123, 'SilverLibs: ['..errStr..'] are not a valid slot names.')
    end
  end
end

-- Lock name is required, must be the first parameter, and cannot be a "slot" name.
-- All other parameters should be slot names or 'all' indicating which slots to unlock.
function silibs.unlock(lock_name, ...)
  -- Parameters are accessed in the magic "arg" variable
  for k,v in pairs(arg) do
    if v then
      -- Force all parameters to lowercase string
      v = tostring(v):lower()
    end
  end

  -- Ensure lock name is not a slot or 'all'
  if silibs.slot_names:contains(lock_name) or lock_name == 'all' then
    windower.add_to_chat(123, 'SilverLibs: Lock name \''..lock_name..'\' is invalid.')
    return
  end

  -- If 'all' is specified as one of the params, update slot list to include all slots.
  -- Also consider 'all' slots if none are specified
  local is_all_slots = false
  if table.contains(arg, 'all') or arg.n == 0 then
    is_all_slots = true
    -- Update list to include all slot names
    arg = gearswap.default_slot_map
  end

  -- Remove extra table parameter
  arg.n=nil

  local errorSlots = L{}
  for k,v in pairs(arg) do
    if v then
      local slot_name = silibs.slot_names[v]
      if slot_name then
        -- Unlock slot
        silibs.locked_slots[slot_name]:remove(lock_name)
      else
        errorSlots:append(v)
      end
    end
  end

  if lock_name == 'manual' then
    if errorSlots:length() == 0 then
      -- Print success message
      local succStr = is_all_slots and 'all' or table.concat(arg, ', ')
      windower.add_to_chat(1, string.char(0x1F, 207)..'SilverLibs: \''..lock_name..'\' lock removed from ['..succStr..'] slots.')
    elseif errorSlots:length() == 1 then
      -- Print single error message
      local errStr = errorSlots:concat(', ')
      windower.add_to_chat(123, 'SilverLibs: ['..errStr..'] is not a valid slot name.')
    else
      -- Print plural error message
      local errStr = errorSlots:concat(', ')
      windower.add_to_chat(123, 'SilverLibs: ['..errStr..'] are not a valid slot names.')
    end
  end
end

-- All parameters should be slot names indicating which slots to clear locks.
function silibs.clearlocks(...)
  -- Parameters are accessed in the magic "arg" variable
  for k,v in pairs(arg) do
    if v then
      -- Force all parameters to lowercase string
      v = tostring(v):lower()
    end
  end

  -- If 'all' is specified as one of the params, update slot list to include all slots.
  -- Also consider 'all' slots if none are specified
  local is_all_slots = false
  if table.contains(arg, 'all') or arg.n == 0 then
    is_all_slots = true
    -- Update list to include all slot names
    arg = gearswap.default_slot_map
  end

  -- Remove extra table parameter
  arg.n=nil

  local errorSlots = L{}
  for k,v in pairs(arg) do
    if v then
      local slot_name = silibs.slot_names[v]
      if slot_name then
        -- Unlock slot
        silibs.locked_slots[slot_name] = S{}
      else
        errorSlots:append(v)
      end
    end
  end

  if errorSlots:length() == 0 then
    -- Print success message
    local succStr = is_all_slots and 'all' or table.concat(arg, ', ')
    windower.add_to_chat(1, string.char(0x1F, 207)..'SilverLibs: All locks removed from ['..succStr..'] slots.')
  elseif errorSlots:length() == 1 then
    -- Print single error message
    local errStr = errorSlots:concat(', ')
    windower.add_to_chat(123, 'SilverLibs: ['..errStr..'] is not a valid slot name.')
  else
    -- Print plural error message
    local errStr = errorSlots:concat(', ')
    windower.add_to_chat(123, 'SilverLibs: ['..errStr..'] are not a valid slot names.')
  end
end

function silibs.use_sneak()
  local cmd
  -- If access to a spell or job ability (or multiples), attempt to use that (or those) first
  -- If JA not available, attempt to use spells that consume MP
  -- If those not available, attempt to use spells that consume items
  -- If those not available, attempt to use items
  if not cmd
    and silibs.can_access_ability('Spectral Jig')
    and silibs.can_recast_ability('Spectral Jig') then
    cmd = 'input /ja "Spectral Jig" <me>'
  end
  if not cmd
    and silibs.can_access_spell("Sneak") then
      cmd = 'input /ma "Sneak" <stpc>'
  end
  if not cmd
    and silibs.can_access_spell('Monomi: Ichi')
    and silibs.can_recast_spell('Monomi: Ichi', 5)
    and silibs.has_item('Sanjaku-Tenugui', L{'inventory'}) then
      cmd = 'input /ma "Monomi: Ichi" <me>'
  end
  if not cmd and silibs.has_item('Silent Oil', L{'inventory'}) then
    cmd = 'input /item "Silent Oil" <me>'
  end

  if not cmd then
    add_to_chat(123, 'No form of Sneak available!')
  else
    send_command(cmd)
  end
end

function silibs.use_invisible()
  local cmd
  -- If access to a spell or job ability (or multiples), attempt to use that (or those) first
  -- If JA not available, attempt to use spells that consume MP
  -- If those not available, attempt to use spells that consume items
  -- If those not available, attempt to use items
  if not cmd
    and silibs.can_access_ability('Spectral Jig')
    and silibs.can_recast_ability('Spectral Jig') then
    cmd = 'input /ja "Spectral Jig" <me>'
  end
  if not cmd
    and silibs.can_access_spell('Invisible') then
      cmd = 'input /ma "Invisible" <stpc>'
  end
  if not cmd
    and silibs.can_access_spell('Tonko: Ni')
    and silibs.can_recast_spell('Tonko: Ni')
    and silibs.has_item('Shinobi-Tabi', L{'inventory'}) then
      cmd = 'input /ma "Tonko: Ni" <me>'
  end
  if not cmd
    and silibs.can_access_spell('Tonko: Ichi')
    and silibs.can_recast_spell('Tonko: Ichi')
    and silibs.has_item('Shinobi-Tabi', L{'inventory'}) then
      cmd = 'input /ma "Tonko: Ichi" <me>'
  end
  if not cmd and silibs.has_item('Prism Powder', L{'inventory'}) then
    cmd = 'input /item "Prism Powder" <me>'
  end

  if not cmd then
    add_to_chat(123, 'No form of Invisible available!')
  else
    send_command(cmd)
  end
end

function silibs.get_last_midcast_set()
  return silibs.last_midcast_set or {}
end


--=============================================================================
--=============================================================================
--=============================================================================
--                       Feature-supporting functions
--=============================================================================
--=============================================================================
--=============================================================================
-- Functions that are needed to support SilverLibs features, but not intended
-- for general use.

-- Calculate how long the action should take and set a timer. If the is_midaction flag does not
-- reset by then, reset manually.
function silibs.set_midaction(spell, action, spellMap, eventArgs)
  silibs.is_midaction = true
  -- Set time based on expected cast time plus a buffer
  local buffer = 3
  -- Certain actions have an expected cast time. We can expect the cast time to 
  -- vary with buffs. Not going to account for gear modifications to cast time.
  -- Items always handle fine
  local cast_time = spell.cast_time or 0
  local speed_mod = 1
  if spell.action_type == 'Magic' then
    if buffactive['slow'] or buffactive['Slow'] then
      speed_mod = speed_mod + 0.25
    end
    if buffactive['elegy'] or buffactive['Elegy'] then
      speed_mod = speed_mod + 0.25
    end
    if buffactive['haste'] or buffactive['Haste'] then
      speed_mod = speed_mod - 0.1
    end
    if buffactive['march'] or buffactive['March'] then
      speed_mod = speed_mod - 0.1
    end

    -- Haste cannot make speed less than 15% cast time
    speed_mod = (speed_mod < 0.15 and 0.15) or speed_mod
  end

  silibs.midaction_expected_finish_time = os.clock() + (cast_time * speed_mod) + buffer
end

function silibs.reset_midaction()
  silibs.is_midaction = false
  silibs.midaction_expected_finish_time = 0
end

-- mode: Enumeration 'on', 'off', 'auto', 'cycle' (default). Sets appropriate state based on activated feature.
-- 'cycle' mode cycles through each state and is the default if no mode is specified for this function.
function silibs.set_auto_reraise_state(mode)
  if silibs.auto_reraise_enabled then
    if mode == 'on' then
      state.AutoReraise:set('On')
    elseif mode == 'off' then
      state.AutoReraise:set('Off')
    elseif mode == 'auto' then
      state.AutoReraise:set('Auto')
    else
      state.AutoReraise:cycle()
    end

    -- Print out new mode
    windower.add_to_chat(141, state.AutoReraise.description..string.char(31,1)..' set to '..string.char(31,141)..state.AutoReraise.current)
  end
end

-- Based on the mode you're in, may need to also check HP state and equip appropriate gear
-- If HP lower than defined threshold in 'auto' mode, equip gear
-- If in 'on' mode, equip gear
function silibs.get_auto_reraise_gear()
  if state.AutoReraise.value == 'On' or (state.AutoReraise.value == 'Auto' and player.hpp < silibs.auto_reraise_config.hpp) then
    return silibs.auto_reraise_config.set
  end

  return {}
end

-- This should go at the end of your post_midcast function
-- Input the parameters for spell, spell map, and boolean values for whether you
-- actually possess the hachirin-no-obi and orpheus's sash.
-- May not work properly if you have modified spell maps for the relevant spells.
function silibs.handle_elemental_belts(spell, spellMap, phase)
  if not silibs.has_obi and not silibs.has_orpheus then return end

  local has_iridescence = gearswap.equip_list and (gearswap.equip_list.main == 'Chatoyant Staff' or gearswap.equip_list.main == 'Iridal Staff') or false
  local waist = (gearswap.equip_list and gearswap.equip_list.waist) or player.equipment.waist
  local fallback_midcast_waist = (type(waist)=='table' and waist.name) or (type(waist)=='string' and waist) or 'empty'

  if phase == 'precast' then
    -- Handle belts for elemental damage
    if (spell.type == 'WeaponSkill' and silibs.elemental_ws:contains(spell.english))
      or (spell.type == 'CorsairShot' and (spell.english ~= 'Light Shot' and spell.english ~= 'Dark Shot'))
    then
      local base_day_weather_mult = silibs.get_day_weather_multiplier(spell.element, false, has_iridescence)
      local obi_mult = silibs.get_day_weather_multiplier(spell.element, true, has_iridescence)
      local orpheus_mult = silibs.get_orpheus_multiplier(spell.element, spell.target.distance, has_iridescence)

      -- Determine which combination to use: orpheus, hachirin-no-obi, or neither
      if silibs.has_obi and ((not silibs.has_orpheus and obi_mult > base_day_weather_mult) or (silibs.has_orpheus and obi_mult >= orpheus_mult)) then
        -- Obi is better than orpheus and better than nothing
        equip({waist='Hachirin-no-Obi'})
      elseif silibs.has_orpheus and (orpheus_mult - base_day_weather_mult > 0.01 or (fallback_midcast_waist == 'Hachirin-no-obi' and obi_mult < base_day_weather_mult)) then
        -- Orpheus is better than obi and better than nothing
        equip({waist='Orpheus\'s Sash'})
      end
    end
  elseif phase == 'midcast' then
    -- Handle belts for elemental damage
    if (
      fallback_midcast_waist ~= 'Hachirin-no-Obi' and fallback_midcast_waist ~= 'Orpheus\'s Sash'
        and ((spell.type == 'WeaponSkill' and silibs.elemental_ws:contains(spell.english))
          or (spell.type == 'CorsairShot' and (spell.english ~= 'Light Shot' and spell.english ~= 'Dark Shot'))))
      or ((spell.skill == 'Elemental Magic'
        and spell.english ~= 'Impact'
        and spell.english ~= 'Meteor'
        and spellMap ~= 'Helix'
        and spellMap ~= 'ElementalEnfeeble')
        or (spell.skill == 'Blue Magic' and silibs.blue_magic_magical_dmg_spells:contains(spell.english))
        or spellMap == 'ElementalNinjutsu'
        or spell.english == 'Holy' or spell.english == 'Holy II')
    then
      local base_day_weather_mult = silibs.get_day_weather_multiplier(spell.element, false, has_iridescence)
      local obi_mult = silibs.get_day_weather_multiplier(spell.element, true, has_iridescence)
      local orpheus_mult = silibs.get_orpheus_multiplier(spell.element, spell.target.distance, has_iridescence)

      -- Determine which combination to use: orpheus, hachirin-no-obi, or neither
      if silibs.has_obi and ((not silibs.has_orpheus and obi_mult > base_day_weather_mult) or (silibs.has_orpheus and obi_mult >= orpheus_mult)) then
        -- Obi is better than orpheus and better than nothing
        equip({waist='Hachirin-no-Obi'})
      elseif silibs.has_orpheus and (orpheus_mult - base_day_weather_mult > 0.01 or (fallback_midcast_waist == 'Hachirin-no-obi' and obi_mult < base_day_weather_mult)) then
        -- Orpheus is better than obi and better than nothing
        equip({waist='Orpheus\'s Sash'})
      end
    elseif silibs.has_obi and (spellMap == 'Cure' or spellMap == 'Curaga') then
      local obi_mult = silibs.get_day_weather_multiplier(spell.element, true, has_iridescence)
      if obi_mult > 1 then -- Must be net positive
        equip({waist='Hachirin-no-Obi'})
      end
    elseif silibs.has_obi and (spellMap == 'Drain' or spellMap == 'Aspir') then
      local obi_mult = silibs.get_day_weather_multiplier(spell.element, true, has_iridescence)
      if obi_mult > 1.08 then -- Must beat Fucho-no-Obi
        equip({waist='Hachirin-no-Obi'})
      end
    end
  end
end

-- Returns the total day/weather damage multiplier based on what
-- enhancing gear you have equipped and the element of the spell/ability
-- you want to use.
-- Does not include the flat +15% potency bonus that Chatoyant Staff always has.
function silibs.get_day_weather_multiplier(spell_element, is_obi_equipped, has_iridescence)
  -- Get current day
  local day_element = world.day_element
  -- Find day alignment vs spell used
  local day_align = 0
  -- Same element = positive alignment
  if (spell_element == day_element) then
    day_align = 1
  elseif (spell_element == silibs.elements.weak_to[day_element]) then
    day_align = -1
  end

  -- Get current weather
  local weather_element = world.weather_element
  -- Find weather alignment vs spell used
  local weather_align = 0
  -- Same element = positive alignment, 
  if (spell_element == weather_element) then
    weather_align = 1
  elseif (spell_element == silibs.elements.weak_to[weather_element]) then
    weather_align = -1
  end
  -- Double weather = x2 bonus
  weather_align = weather_align * silibs.get_weather_intensity()

  -- Using alignments, retrieve bonus values
  local row_index = silibs.day_weather_bns:find(function(row)
    return (row.day == day_align) and (row.weather == weather_align)
  end)
  local row = silibs.day_weather_bns[row_index]

  -- Base proc rates
  local d_rate = 1/5
  local w_rate = 1/3
  local i_rate = 1/3

  -- Obi makes both weather and day proc chance 100%
  if (is_obi_equipped and has_iridescence) then
    d_rate = 1
    w_rate = 1
    i_rate = 1
  elseif (is_obi_equipped and not has_iridescence) then
    d_rate = 1
    w_rate = 1
    i_rate = 0
  elseif (not is_obi_equipped and has_iridescence) then
    i_rate = 1
  end

  -- Retrieve potencies based on current day and weather
  local d_pot = row.base_day_bn
  local w_pot = row.base_weather_bn
  local i_pot = row.iridescence_bn

  -- Compute average value of day and weather effects based on proc rate
  -- Two possible formulas based on whether iridescence is present or not
  local dwi_rate = d_rate * w_rate * i_rate
  local dw_rate = (d_rate * w_rate) - dwi_rate
  local wi_rate = (w_rate * i_rate) - dwi_rate
  local di_rate = (d_rate * i_rate) - dwi_rate
  local d_only_rate = d_rate - dw_rate - di_rate - dwi_rate
  local w_only_rate = w_rate - dw_rate - wi_rate - dwi_rate
  local i_only_rate = i_rate - wi_rate - di_rate - dwi_rate

  local total_avg_bonus = (dwi_rate * (d_pot + w_pot + i_pot))
      + (dw_rate * (d_pot + w_pot))
      + (wi_rate * (w_pot + i_pot))
      + (di_rate * (d_pot + i_pot))
      + (d_only_rate * d_pot)
      + (w_only_rate * w_pot)
      + (i_only_rate * i_pot)

  -- Convert bonus (percentage) into multiplier (decimal)
  local multiplier = 1 + (total_avg_bonus / 100)
  return multiplier
end

-- Gets the damage multiplier of Orpheus sash based on distance from target.
-- Bonus only exists if the spell used has elemental alignment.
-- +15% dmg less than 1.93', +1% dmg > 13', scale linearly between 1.93' and 13'.
-- Also includes base weather/day bonuses based on proc chance.
function silibs.get_orpheus_multiplier(spell_element, distance, has_iridescence)
  has_iridescence = (has_iridescence ~= nil and has_iridescence) or false
  -- Distance is assumed to be measured from center of self to center of target.
  -- Distance of Orpheus bonus is assumed to be the distance from edge of player
  -- model to edge of target model.
  -- Modify the given distance to account for the model sizes...
  local player_model_size = windower.ffxi.get_mob_by_target('me').model_size
  local t = windower.ffxi.get_mob_by_target('t') or windower.ffxi.get_mob_by_target('st')
  distance = distance - player_model_size - t.model_size

  local distance_bn = 0
  if distance <= 1.93 then
    distance_bn = 15
  elseif distance > 1.93 and distance < 13 then
    local rise = 15-1
    local run = 13-1.93
    local slope = -1 * (rise / run)
    distance_bn = (slope * distance) + 16.44083107497741644
  elseif distance > 13 then
    distance_bn = 1
  end

  -- Convert bonus (percentage) into multiplier (decimal)
  local multiplier = (1 + (distance_bn / 100)) * silibs.get_day_weather_multiplier(spell_element, false, has_iridescence)
  return multiplier
end

-- Meant for use inside a job_self_command callback
function silibs.handle_elemental(cmdParams, element)
  if not cmdParams or not cmdParams[1] or not cmdParams[2] then
    add_to_chat(123,'Error: No elemental command given.')
    return
  end

  local target = '<t>'
  -- Check if element came in cmdParams. This should take priority.
  if cmdParams[4] then -- Must be element
    element = cmdParams[4]
  elseif cmdParams[3] then
    -- 3rd param could be target specifier or element
    if not cmdParams[3]:startswith('<') then
      element = cmdParams[3]
    else
      target = cmdParams[3]
    end
  end

  -- Clean up element capitalization
  element = element:lower():ucfirst()

  local command = cmdParams[2]:lower()
  if command == 'storm' then
    -- Determine tier of storm
    local tier = (player.main_job == 'SCH' and player.job_points.sch.jp_spent > 100 and ' II') or ''
    send_command('@input /ma "'..silibs.elements.storm_of[element]..''..tier..'" '..target..'')
  elseif command:contains('tier') then
    local tierlist = {['tier1']='',['tier2']=' II',['tier3']=' III',['tier4']=' IV',['tier5']=' V',['tier6']=' VI'}
    local selected_spell

    -- Revise tier list under certain conditions
    if element == 'Light' then
      if (player.main_job == 'WHM' or player.main_job == 'PLD') then
        tierlist = {['tier1']='',['tier2']=' II',}
      end
    elseif element == 'Dark' then
      if player.main_job == 'BLM' then
        tierlist = {['tier1']='',}
      end
    end

    -- If command is just "tier" and does not include the number of tier, use smart selection of highest available nuke
    if command == 'tier' then
      local spell_recasts = windower.ffxi.get_spell_recasts()
      for i=6,1,-1 do
        local spell = tierlist['tier'..i] and silibs.elements.nuke_of[element]..tierlist['tier'..i] or nil
        local spell_detail = silibs.spells_by_name[spell]
        if spell_detail then
          local is_spell_available = silibs.can_access_spell(nil, spell_detail) and silibs.actual_cost(spell_detail) <= player.mp
          local timer = spell_recasts[spell_detail.recast_id] -- Divide by 60 to get time in seconds
          if is_spell_available and timer < 6 then
            selected_spell = spell
            break
          end
        end
      end
    else -- Command specifies tier
      -- Check if requested spell is learned (or exists at all), if not then downselect tier until find an available spell
      local spell = silibs.elements.nuke_of[element]..tierlist[command]
      local spell_detail = silibs.spells_by_name[spell]
      if spell_detail and silibs.can_access_spell(nil, spell_detail) then
        selected_spell = spell
      else
        local spell_index = tonumber(command:slice(#command))
        for i=spell_index,1,-1 do
          spell = tierlist['tier'..i] and silibs.elements.nuke_of[element]..tierlist['tier'..i] or nil
          spell_detail = silibs.spells_by_name[spell]
          if spell_detail and silibs.can_access_spell(nil, spell_detail) and silibs.actual_cost(spell_detail) <= player.mp then
            selected_spell = spell
            break
          end
        end
      end
    end
    if not selected_spell then
      add_to_chat(123, 'No '..element..' nukes available.')
      return
    end
    send_command('@input /ma "'..selected_spell..'" '..target..'')
  elseif command:contains('ga') then
    if element == 'Light' or element == 'Dark' then
      add_to_chat(123, 'No corresponding -ga spell for '..element)
    end

    local tierlist = {['ga1']='',['ga2']=' II',['ga3']=' III',['ga4']=' IV',['ga5']=' V'}
    local selected_spell

    -- If command is just "ga" and does not include the number of tier, use smart selection of highest available nuke
    if command == 'ga' then
      local spell_recasts = windower.ffxi.get_spell_recasts()
      for i=5,1,-1 do
        local spell = tierlist['ga'..i] and silibs.elements.nukega_of[element]..'ga'..tierlist['ga'..i] or nil
        local spell_detail = silibs.spells_by_name[spell]
        if spell_detail then
          local is_spell_available = silibs.can_access_spell(nil, spell_detail) and silibs.actual_cost(spell_detail) <= player.mp
          local timer = spell_recasts[spell_detail.recast_id] -- Divide by 60 to get time in seconds
          if is_spell_available and timer < 6 then
            selected_spell = spell
            break
          end
        end
      end
    else -- Command specifies tier
      -- Check if requested spell is learned (or exists at all), if not then downselect tier until find an available spell
      local spell = silibs.elements.nukega_of[element]..'ga'..tierlist[command]
      local spell_detail = silibs.spells_by_name[spell]
      if spell_detail and silibs.can_access_spell(nil, spell_detail) then
        selected_spell = spell
      else
        local spell_index = tonumber(command:slice(#command))
        for i=spell_index,1,-1 do
          spell = tierlist['ga'..i] and silibs.elements.nukega_of[element]..'ga'..tierlist['ga'..i] or nil
          spell_detail = silibs.spells_by_name[spell]
          if spell_detail and silibs.can_access_spell(nil, spell_detail) and silibs.actual_cost(spell_detail) <= player.mp then
            selected_spell = spell
            break
          end
        end
      end
    end
    if not selected_spell then
      add_to_chat(123, 'No '..element..' nukes available.')
      return
    end
    send_command('@input /ma "'..selected_spell..'" '..target..'')
  elseif command == 'helix' then
    send_command('@input /ma "'..silibs.elements.helix_of[element]..'helix II" '..target..'')
  elseif command == 'enspell' then
    if element ~= 'Light' and element ~= 'Dark' then
      send_command('@input /ma '..silibs.elements.enspell_of[element]..' <me>')
    else
      add_to_chat(123, 'No corresponding Enspell for '..element)
    end
  elseif command:contains('ara') then
    if element ~= 'Light' and element ~= 'Dark' then
      -- local spell_recasts = windower.ffxi.get_spell_recasts()
      local tierkey = {'ara3','ara2','ara1'}
      local tierlist = {['ara3']='ra III',['ara2']='ra II',['ara1']='ra'}
      local nuke = silibs.elements.nukera_of[element]
      if command == 'ara' then
        for i in ipairs(tierkey) do
          if silibs.actual_cost(silibs.get_spell_table_by_name(nuke..tierlist[tierkey[i]]..'')) < player.mp then
            send_command('@input /ma "'..nuke..tierlist[tierkey[i]]..'" '..target)
            return
          end
        end
      else
        send_command('@input /ma "'..nuke..tierlist[command]..'" '..target)
      end
    else
      add_to_chat(123, 'No corresponding -ara spell for '..element)
    end
  elseif command:contains('ja') then
    if element ~= 'Light' and element ~= 'Dark' then
      local nuke = silibs.elements.nukeja_of[element]..'ja'
      send_command('@input /ma "'..nuke..'" '..target)
    else
      add_to_chat(123, 'No corresponding -ja spell for '..element)
    end
  else
    add_to_chat(123,'Unrecognized elemental command.')
  end
end

--[[
Check for proper ammo when shooting or weaponskilling.

Job luas should contain a map of weapon type to ammo in this format:
  ammo_assignment = {
    Bow = {
      Default = "Chrono Arrow",
      Accuracy = "Yoichi's Arrow",
      Physical_Weaponskill_Ranged = "Chrono Arrow",
      Magic_Damage = "Chrono Arrow",
      Magic_Accuracy = "Devastating Bullet",
      Quick_Draw = "Hauksbok Bullet",
      Physical_Weaponskill_Melee = "Hauksbok Arrow", -- Does not get consumed
      Magical_Weaponskill_Melee = "Hauksbok Arrow", -- Does not get consumed
    },
    Crossbow = {
      Default = "Quelling Bolt",
      Accuracy = "Quelling Bolt",
      Physical_Weaponskill_Ranged = "Quelling Bolt",
      Magic_Damage = "Quelling Bolt",
      Magic_Accuracy = "Devastating Bullet",
      Quick_Draw = "Hauksbok Bullet",
      Physical_Weaponskill_Melee = "Hauksbok Bolt", -- Does not get consumed
      Magical_Weaponskill_Melee = "Hauksbok Bolt", -- Does not get consumed
    },
    Gun_or_Cannon = {
      Default = "Chrono Bullet",
      Accuracy = "Eradicating Bullet",
      Physical_Weaponskill_Ranged = "Chrono Bullet",
      Magic_Damage = "Devastating Bullet",
      Magic_Accuracy = "Devastating Bullet",
      Quick_Draw = "Hauksbok Bullet",
      Physical_Weaponskill_Melee = "Hauksbok Bullet", -- Does not get consumed
      Magical_Weaponskill_Melee = "Hauksbok Bullet", -- Does not get consumed
    }
  }
]]--
function silibs.equip_ammo(spell, action, spellMap, eventArgs)
  -- Determine weapon type
  local range_type
  if player.equipment.range and player.equipment.range ~= 'empty' then
    local weapon_stats = res.items:with('en', player.equipment.range)
    -- If throwing weapon, return empty as ammo
    if weapon_stats.skill == 27 then
      equip({ammo='empty'})
      return
    elseif weapon_stats.range_type == 'Bow' then
      range_type = 'Bow'
    elseif weapon_stats.range_type == 'Crossbow' then
      range_type = 'Crossbow'
    elseif weapon_stats.range_type == 'Gun' or weapon_stats.range_type == 'Cannon' then
      range_type = 'Gun_or_Cannon'
    end
  end

  -- Attempting to shoot with inappropriate weapon
  if not range_type then
    return
  end

  if not silibs.ammo_assignment then
    add_to_chat(123, 'ammo_assignment map not defined!')
    equip({ammo='empty'}) -- Just in case, unequip any current ammo to avoid accidental firing
    eventArgs.cancel = true
    return
  end
  if not silibs.ammo_assignment[range_type] then
    add_to_chat(123, 'ammo_assignment '..range_type..' sub-map not defined!')
    equip({ammo='empty'}) -- Just in case, unequip any current ammo to avoid accidental firing
    eventArgs.cancel = true
    return
  end

  local default_ammo = silibs.ammo_assignment[range_type].Default
  local acc_ammo = silibs.ammo_assignment[range_type].Accuracy
  local phys_ra_ws_ammo = silibs.ammo_assignment[range_type].Physical_Weaponskill_Ranged or silibs.ammo_assignment[range_type].Physical_Weaponskill
  local magic_ammo = silibs.ammo_assignment[range_type].Magic_Damage
  local macc_ammo = silibs.ammo_assignment[range_type].Magic_Accuracy or silibs.ammo_assignment[range_type].Magic_Damage
  local qd_ammo = silibs.ammo_assignment[range_type].Quick_Draw
  local phys_melee_ws_ammo = silibs.ammo_assignment[range_type].Physical_Weaponskill_Melee
  local magic_melee_ws_ammo = silibs.ammo_assignment[range_type].Magical_Weaponskill_Melee

  if not default_ammo then
    add_to_chat(123, 'Default ammo is undefined.')
    equip({ammo='empty'})
    cancel_spell()
    eventArgs.cancel = true
    return
  end

  -- Protect against shooting hauksbok ammo
  if silibs.rare_ammo:contains(default_ammo:lower()) then
    add_to_chat(123, '** Action Canceled: Remove rare ammo from \'Default\' ammo assignment. **')
    equip({ammo='empty'})
    cancel_spell()
    eventArgs.cancel = true
    return
  elseif silibs.rare_ammo:contains(acc_ammo:lower()) then
    add_to_chat(123, '** Action Canceled: Remove rare ammo from \'Accuracy\' ammo assignment. **')
    equip({ammo='empty'})
    cancel_spell()
    eventArgs.cancel = true
    return
  elseif silibs.rare_ammo:contains(phys_ra_ws_ammo:lower()) then
    add_to_chat(123, '** Action Canceled: Remove rare ammo from \'Physical_Weaponskill\' ammo assignment. **')
    equip({ammo='empty'})
    cancel_spell()
    eventArgs.cancel = true
    return
  elseif silibs.rare_ammo:contains(magic_ammo:lower()) then
    add_to_chat(123, '** Action Canceled: Remove rare ammo from \'Magic_Damage\' ammo assignment. **')
    equip({ammo='empty'})
    cancel_spell()
    eventArgs.cancel = true
    return
  elseif silibs.rare_ammo:contains(macc_ammo:lower()) then
    add_to_chat(123, '** Action Canceled: Remove rare ammo from \'Magic_Accuracy\' ammo assignment. **')
    equip({ammo='empty'})
    cancel_spell()
    eventArgs.cancel = true
    return
  end

  local swapped_ammo
  if spell.action_type == 'Ranged Attack' then
    -- If in ranged acc mode, use acc bullet (fall back to default bullet if out of acc ammo)
    if state.RangedMode.value ~= 'Normal' then
      if acc_ammo and silibs.has_item(acc_ammo, silibs.equippable_bags) then
        swapped_ammo = acc_ammo
      elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
        -- Fall back to default ammo, if there is any
        swapped_ammo = default_ammo
        add_to_chat(3, 'Acc ammo unavailable. Falling back to default ammo.')
      else
        -- If neither is available, empty the ammo slot
        swapped_ammo = 'empty'
        cancel_spell()
        add_to_chat(123, '** Action Canceled: [ Acc & default ammo unavailable. ] **')
        eventArgs.cancel = true
        return
      end
    elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
    else
      swapped_ammo = 'empty'
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ Default ammo unavailable. ] **')
      eventArgs.cancel = true
      return
    end
  elseif spell.type == 'WeaponSkill' then
    -- Ranged WS
    if spell.skill == 'Marksmanship' or spell.skill == 'Archery' then
      -- ranged magical weaponskills
      if silibs.elemental_ws:contains(spell.english) then
        if magic_ammo and silibs.has_item(magic_ammo, silibs.equippable_bags) then
          swapped_ammo = magic_ammo
        elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
          swapped_ammo = default_ammo
          add_to_chat(3, 'Magic ammo unavailable. Using default ammo.')
        else
          swapped_ammo = 'empty'
          cancel_spell()
          add_to_chat(123, '** Action Canceled: [ Magic & default ammo unavailable. ] **')
          eventArgs.cancel = true
          return
        end
      else -- ranged physical weaponskills
        if state.RangedMode.value ~= 'Normal' then
          if acc_ammo and silibs.has_item(acc_ammo, silibs.equippable_bags) then
            swapped_ammo = acc_ammo
          elseif phys_ra_ws_ammo and silibs.has_item(phys_ra_ws_ammo, silibs.equippable_bags) then
            swapped_ammo = phys_ra_ws_ammo
            add_to_chat(3, 'Acc ammo unavailable. Using WS ammo.')
          elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            add_to_chat(3, 'Acc & WS ammo unavailable. Using default ammo.')
          else
            swapped_ammo = 'empty'
            equip({ammo=swapped_ammo})
            cancel_spell()
            add_to_chat(123, '** Action Canceled: [ Acc, WS, & default ammo unavailable. ] **')
            eventArgs.cancel = true
            return
          end
        else
          if phys_ra_ws_ammo and silibs.has_item(phys_ra_ws_ammo, silibs.equippable_bags) then
            swapped_ammo = phys_ra_ws_ammo
          elseif silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            add_to_chat(3, 'WS ammo unavailable. Using default ammo.')
          else
            swapped_ammo = 'empty'
            cancel_spell()
            add_to_chat(123, '** Action Canceled: [ WS & default ammo unavailable. ] **')
            eventArgs.cancel = true
            return
          end
        end
      end
    else -- Melee WS
      -- Magical
      if silibs.elemental_ws:contains(spell.english) then
        -- Use ammo explicitly defined for this situation
        if magic_melee_ws_ammo and silibs.has_item(magic_melee_ws_ammo, silibs.equippable_bags) then
          swapped_ammo = magic_melee_ws_ammo
        else
          -- Fallback ammo if not user-defined
          if range_type == 'Bow' and player.main_job == 'RNG' and silibs.has_item('Hauksbok Arrow', silibs.equippable_bags) then
            swapped_ammo = 'Hauksbok Arrow'
          elseif range_type == 'Gun_or_Cannon' and (player.main_job == 'RNG' or player.main_job == 'COR') and silibs.has_item('Hauksbok Bullet', silibs.equippable_bags) then
            swapped_ammo = 'Hauksbok Bullet'
          elseif range_type == 'Crossbow' and player.main_job == 'RNG' and silibs.has_item('Hauksbok Bolt', silibs.equippable_bags) then
            swapped_ammo = 'Hauksbok Bolt'
          elseif magic_ammo and silibs.has_item(magic_ammo, silibs.equippable_bags) then
            swapped_ammo = magic_ammo
          elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            add_to_chat(3, 'Magic ammo unavailable. Using default ammo.')
          else
            swapped_ammo = 'empty'
          end
        end
      else -- Physical
        -- Use ammo explicitly defined for this situation
        if phys_melee_ws_ammo and silibs.has_item(phys_melee_ws_ammo, silibs.equippable_bags) then
          swapped_ammo = phys_melee_ws_ammo
        else
          -- Fallback ammo if not user-defined
          if range_type == 'Bow' and player.main_job == 'RNG' and silibs.has_item('Hauksbok Arrow', silibs.equippable_bags) then
            swapped_ammo = 'Hauksbok Arrow'
          elseif range_type == 'Gun_or_Cannon' and (player.main_job == 'RNG' or player.main_job == 'COR') and silibs.has_item('Hauksbok Bullet', silibs.equippable_bags) then
            swapped_ammo = 'Hauksbok Bullet'
          elseif range_type == 'Crossbow' and player.main_job == 'RNG' and silibs.has_item('Hauksbok Bolt', silibs.equippable_bags) then
            swapped_ammo = 'Hauksbok Bolt'
          elseif magic_ammo and silibs.has_item(magic_ammo, silibs.equippable_bags) then
            swapped_ammo = magic_ammo
          elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            add_to_chat(3, 'Magic ammo unavailable. Using default ammo.')
          else
            swapped_ammo = 'empty'
          end
        end
      end
    end
  elseif spell.type == 'CorsairShot' then
    if macc_ammo and silibs.has_item(qd_ammo, silibs.equippable_bags)
        and spell.english == 'Light Shot' or spell.english == 'Dark Shot' then
      swapped_ammo = macc_ammo
    elseif qd_ammo and silibs.has_item(qd_ammo, silibs.equippable_bags) then
      swapped_ammo = qd_ammo
    elseif silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
      add_to_chat(3, 'QD ammo unavailable. Using default ammo.')
    else
      swapped_ammo = 'empty'
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ QD & default ammo unavailable. ] **')
      eventArgs.cancel = true
      return
    end
  elseif spell.english == 'Shadowbind' or spell.english == 'Bounty Shot' or spell.english == 'Eagle Eye Shot' then
    if silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
    else
      swapped_ammo = 'empty'
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ Default ammo unavailable. ] **')
      eventArgs.cancel = true
      return
    end
  end

  if swapped_ammo and swapped_ammo ~= 'empty' then
    local swapped_item = silibs.get_item(swapped_ammo)
    if swapped_item then
      -- Warn player if ammo is running low (unless it's rare ammo in which case it's always gonna be low so ignore).
      if options.ammo_warning_limit
        and swapped_item.count < options.ammo_warning_limit
        and not silibs.rare_ammo:contains(swapped_item.shortname:lower())
      then
        add_to_chat(39,'*** Ammo \''..swapped_item.shortname..'\' running low! *** ('..swapped_item.count..')')
      end
    else
      add_to_chat(123, '** Ammo unavailable: [ '..swapped_ammo..' ] **')
      swapped_ammo = 'empty'
      cancel_spell()
      eventArgs.cancel = true
      return
    end

    equip({ammo=swapped_ammo})
  end
end

-- Sticking this at the end of job_post_precast() or job_post_midcast() will prevent range/ammo swaps that
-- would drop your TP. Great to use inside a conditional such as "if in battle mode on RDM or BLU, don't drop TP"
-- Credit to Rubenator for assistance on this one
function silibs.prevent_ammo_tp_loss()
  equip({range=''}) -- Prevent range swap from happening. Unless it's an instrument, this always drops TP

  local range = player.equipment.range
  range = (type(range)=='table' and range.name) or (type(range)=='string' and range) or 'empty'

  local new_ammo = gearswap.equip_list.ammo
  new_ammo = (type(new_ammo)=='table' and new_ammo.name) or (type(new_ammo)=='string' and new_ammo) or 'empty'

  -- Allow ammo swapping if there is not going to be a range weapon or no ammo
  if not range or range == 'empty' or not new_ammo or new_ammo == 'empty' then return end

  -- Pull more details about the range weapon (mainly so we can check its range type)
  range = res.items:with('name', range)

  -- If we cannot get stats for range weapon, allow ammo swap
  if not range or not range.range_type then return end

  -- Check if new ammo will be compatible with the new range weapon and
  -- prevent swap of ammo if incompatible
  if silibs.ammo_map[new_ammo] ~= range.range_type then
    --add_to_chat(122, 'WARNING: %s is not the correct ammo type for %s.':format(ammo, range.english))
    equip({ammo=''}) -- Prevent ammo swap from happening
  end
end

function silibs.protect_rare_ammo(spell, action, spellMap, eventArgs)
  local ammo = gearswap.equip_list.ammo or player.equipment.ammo
  ammo = (type(ammo)=='table' and ammo.name) or (type(ammo)=='string' and ammo) or 'empty'

  -- Check if this is an action that might expend ammo
  if silibs.rare_ammo:contains(ammo:lower())
    and (spell.action_type == 'Ranged Attack'
    or (spell.type == 'WeaponSkill' and (spell.skill == 'Marksmanship' or spell.skill == 'Archery'))
    or spell.english == 'Shadowbind'
    or spell.english == 'Bounty Shot'
    or spell.english == 'Eagle Eye Shot')
  then
    -- Protect against shooting rare ammo
    equip({ammo=empty})
    eventArgs.cancel = true
    cancel_spell()
    add_to_chat(123, '** Action Canceled: Protecting rare ammo. **')
  end
end

function silibs.number_of_jps(jp_tab)
    local count = 0
    for _,v in pairs(jp_tab) do
        count = count + v*(v+1)
    end
    return count/2
end

-- Values used for calculations can be customized in player's lua by setting silibs.waltz_stats
function silibs.waltz_cure_amount(tier, target)
  -- HP Cured = floor(
  --              floor(Slope×(User's CHR + Target's VIT) + Base + 2*(Waltz Job Point Tiers))
  --              × 1+((Waltz Potency gear + Waltz Potency Received gear)/100)
  --            )

  -- Determine slope (main vs sub DNC)
  -- The slope is halved when Dancer is subbed.
  local slope = silibs.curing_waltz[tier].cure_slope
  if player.main_job == 'DNC' then
    slope = slope
  elseif player.sub_job == 'DNC' then
    slope = 0.5 * slope
  else
    return
  end

  local cure_base = silibs.curing_waltz[tier].cure_base

  local base_chr = silibs.waltz_stats.base_chr
  local base_vit = silibs.waltz_stats.base_vit
  local bonus_chr = silibs.waltz_stats.bonus_chr
  local bonus_vit = silibs.waltz_stats.bonus_vit

  if not target then
    return
  end

  local isTargetingSelf = target.name == player.name
  local waltz_jp_count = 0
  if player.main_job == 'DNC' then
    waltz_jp_count = player.job_points.dnc.waltz_potency
  end

  -- Add waltz potency from gear.
  -- Enforce game's caps: waltz potency gear 50%; waltz potency received gear 30%
  local potency = math.min(silibs.waltz_stats.waltz_potency, 50)
  if isTargetingSelf then
    potency = potency + math.min(silibs.waltz_stats.waltz_self_potency, 30)
  end
  potency = potency / 100 -- convert to percentiles for mathing

  return math.floor(
    math.floor((slope * (base_chr + bonus_chr + base_vit + bonus_vit)) + cure_base + (2 * waltz_jp_count))
    * (1+potency)
  )
end

-- Credit to Selindrile for this function
function silibs.update_ui_luopan_distance_tracker()
  local s = windower.ffxi.get_mob_by_target('me')
  local my_luopan
  if windower.ffxi.get_mob_by_target('pet') then
    my_luopan = windower.ffxi.get_mob_by_target('pet')
  else
    my_luopan = nil
  end
  local luopan_txtbox = ''
  local indi_count = 0
  local geo_count = 0
  local battle_target = windower.ffxi.get_mob_by_target('bt') or false
  if my_luopan and silibs.last_geo then
    luopan_txtbox = luopan_txtbox..' \\cs(0,255,0)Geo-'..silibs.last_geo..':\\cs(255,255,255)\n'
    for i,v in pairs(windower.ffxi.get_mob_array()) do
      local dist_between = ((my_luopan.x - v.x)*(my_luopan.x-v.x) + (my_luopan.y-v.y)*(my_luopan.y-v.y)):sqrt()
      if dist_between < (6 + v.model_size) and not (v.status == 2 or v.status == 3) and v.name and v.name ~= '' and v.name ~= 'Luopan' and v.valid_target and v.model_size > 0 then
        if silibs.geo_debuffs:contains(silibs.last_geo) then
          if v.is_npc and not (v.in_party or silibs.luopan_ignore_list:contains(v.name)) then
            if battle_target and battle_target.id == v.id then
              luopan_txtbox = luopan_txtbox..' '..silibs.ui.bt_color..v.name..' '..string.format('%.2f',dist_between)..'\\cs(255,255,255)\n'
            else
              luopan_txtbox = luopan_txtbox..' '..v.name..' '..string.format('%.2f',dist_between)..'\n'
            end
            geo_count = geo_count + 1
          end
        elseif v.in_party then
          luopan_txtbox = luopan_txtbox..' '..v.name..' '..string.format('%.2f',dist_between)..'\n'
          geo_count = geo_count + 1
        end
      end
    end
  end

  if buffactive['Colure Active'] and silibs.last_indi then
    if my_luopan then
      luopan_txtbox = luopan_txtbox..'\n'
    end
    luopan_txtbox = luopan_txtbox..' \\cs(0,255,0)Indi-'..silibs.last_indi..':\\cs(255,255,255)\n'
    for i,v in pairs(windower.ffxi.get_mob_array()) do
      local dist_between = ((s.x - v.x)*(s.x-v.x) + (s.y-v.y)*(s.y-v.y)):sqrt()
      if dist_between < (6 + v.model_size) and (v.status == 1 or v.status == 0) and v.name and v.name ~= '' and v.name ~= 'Luopan' and v.name ~= s.name and v.valid_target and v.model_size > 0 then
        if silibs.geo_debuffs:contains(silibs.last_indi) then
          if v.is_npc and not (v.in_party or silibs.luopan_ignore_list:contains(v.name)) then
            if battle_target and battle_target.id == v.id then
              luopan_txtbox = luopan_txtbox..' '..silibs.ui.bt_color..v.name..' '..string.format('%.2f',dist_between)..'\\cs(255,255,255)\n'
            else
              luopan_txtbox = luopan_txtbox..' '..v.name..' '..string.format('%.2f',dist_between)..'\n'
            end
            indi_count = indi_count + 1
          end
        else
          if v.in_party then
            luopan_txtbox = luopan_txtbox..' '..v.name..' '..string.format('%.2f',dist_between)..'\n'
            indi_count = indi_count + 1
          end
        end
      end
    end
  end

  silibs.ui.luopan.value = luopan_txtbox
  if (my_luopan and geo_count ~= 0) or (buffactive['Colure Active'] and indi_count ~= 0) then
    silibs.ui.luopan:visible(true)
  else
    silibs.ui.luopan:visible(false)
  end
end

function silibs.interact()
  local t = (player and player.target and player.target.name) or nil
  if player.target.type ~= 'NONE' then
    -- Handle gathering points
    if t == 'Logging Point' then
      send_command('@input /item "Hatchet" <t>')
    elseif t == 'Harvesting Point' then
      send_command('@input /item "Sickle" <t>')
    elseif t == 'Mining Point' then
      send_command('@input /item "Pickaxe" <t>')
    -- Handle keys
    elseif t == 'Sturdy Pyxis' then
      send_command('@input /item "Forbidden Key" <t>')
    elseif player.main_job == 'THF' and silibs.pickable_locks:contains(t) then
      if silibs.has_item('Skeleton Key', L{'inventory'}) then
        send_command('@input /item "Skeleton Key" <t>')
      elseif silibs.has_item('Living Key', L{'inventory'}) then
        send_command('@input /item "Living Key" <t>')
      elseif silibs.has_item('Thief\'s Tools', L{'inventory'}) then
        send_command('@input /item "Thief\'s Tools" <t>')
      else
        add_to_chat(123, 'Out of lockpicking tools!')
      end
    elseif t == 'Sanraku' then
      send_command('@input /item "Soul Plate" <t>')
    elseif t == 'Maze Mongers Shopfront' then
      local mazes = S{'Maze Tabula M01', 'Maze Tabula M02', 'Maze Tabula M03',
          'Maze Tabula R01', 'Maze Tabula R02', 'Maze Tabula R03',}
      -- Determine if a maze tabula is in inventory
      for maze in pairs(mazes) do
        local item = silibs.has_item(maze, L{'inventory'})
        if item then
          local charges = string.sub(extdata.decode(item).value, 41, 41)
          if charges ~= '0' then
            add_to_chat(207 , 'SilverLibs: '..maze..' has '..charges..' charges.')
            send_command('@input /item "'..maze..'" <t>')
            break
          else
            add_to_chat(123, 'SilverLibs: '..maze..' has no charges.')
          end
        end
      end
    elseif world.area:startswith('Abyssea') then
      send_command('abysseapopper pop')
    end
  end
end

function silibs.trap_soul()
  -- Check if inventory is full
  local inv_info = windower.ffxi.get_bag_info(0)
  local is_inv_full = inv_info and inv_info.count == inv_info.max
  if is_inv_full then
    add_to_chat(123, 'Cannot use soultrapper. Inventory is full.')
    return
  end
  local selected_trapper = player.equipment.range == 'Soultrapper 2000' and 'Soultrapper 2000'
      or player.equipment.range == 'Soultrapper' and 'Soultrapper'
  if selected_trapper then
    local selected_ammo = silibs.has_item('Blank High-Speed Soul Plate', silibs.equippable_bags) and 'Blank High-Speed Soul Plate'
        or silibs.has_item('Blank Soulplate', silibs.equippable_bags) and 'Blank Soulplate'
    if selected_ammo then
      -- Check if ammo is already equipped and equip it if not
      if player.equipment.ammo ~= selected_ammo then
        equip({ammo=selected_ammo})
        send_command('gs c update') -- Call the update command to force gear change
      end
      -- Trap soul by using soultrapper item
      send_command('input /item "'..selected_trapper..'" <t>')
      -- Return cooldown
      return selected_trapper == 'Soultrapper' and 60 or selected_trapper == 'Soultrapper 2000' and 30
    else
      add_to_chat(123, 'Out of soul plates.')
      return
    end
  else
    add_to_chat(123, 'Soultrapper not equipped.')
    return
  end
end

-- Utility function for automatically adjusting the waltz spell being used to match HP needs and TP limits.
-- If most appropriate Waltz is on cooldown, switch to next best match (higher tier if off cooldown and have the TP, otherwise lower)
function silibs.refine_waltz(spell, action, spellMap, eventArgs)
  -- In the case where this might be called from Selindrile lua, arguments are structured differently
  -- like so: refine_waltz(spell, spellMap, eventArgs)
  if not eventArgs then
    eventArgs = spellMap
    spellMap = action
  end
  if spell.type ~= 'Waltz' then
    return
  end

  -- Don't modify anything for Healing Waltz or Divine Waltzes
  if spell.english == 'Healing Waltz' or spell.english == 'Divine Waltz' or spell.english == 'Divine Waltz II' then
    return
  end

  -- Trim waltz table to what's available for player's level
  local viable_waltzes = T{}
  
  for k,v in ipairs(silibs.curing_waltz) do
    if player.main_job == 'DNC' and player.main_job_level >= v.lv then
      viable_waltzes:append(v)
    elseif player.sub_job == 'DNC' and player.sub_job_level >= v.lv then
      viable_waltzes:append(v)
    end
  end

  -- If no viable waltzes, cancel operation
  if #viable_waltzes == 0 then
    add_to_chat(122,'Job requirement failed for '..spell.english'!')
    eventArgs.cancel = true
    return
  end

  local missingHP

  -- If curing ourself, get our exact missing HP
  if spell.target.type == 'SELF' then
    missingHP = player.max_hp - player.hp
  -- If curing someone in our alliance, we can estimate their missing HP
  elseif spell.target.isallymember then
    local target = find_player_in_alliance(spell.target.name)
    local est_max_hp = target.hp / (target.hpp/100)
    missingHP = math.floor(est_max_hp - target.hp)
  else
    local est_max_hp = silibs.waltz_stats.est_non_party_target_hp
    missingHP = math.floor(est_max_hp - (est_max_hp * spell.target.hpp/100))
  end

  -- If missing HP cannot be calculated, or is too low, cancel operation
  -- Don't block when curing others to allow for waking them up.
  if not missingHP or (missingHP < 40 and spell.target.name == player.name) then
    add_to_chat(122,'Full HP!')
    eventArgs.cancel = true
    return
  end

  local waltz

  -- If we have an estimated missing HP value, we can adjust the preferred tier used.
  for k,v in ipairs(viable_waltzes) do
    if not waltz then
      if missingHP < silibs.waltz_cure_amount(k, spell.target) then
        if silibs.can_recast_ability(v.name) then
          waltz = v
        end
      end
    end
  end
  -- Default to highest tier if none selected yet (all higher than most appropriate are on cooldown)
  if not waltz then
    waltz = viable_waltzes:last()
  end

  -- Downgrade the spell to what we can afford that's not on cooldown
  if (player.tp < waltz.tp and not buffactive.trance) or not silibs.can_recast_ability(waltz.name) then
    local bad_tier = waltz.tier
    waltz = nil
    -- Loop down through viable waltzes starting at index for the current waltz tier
    for k,v in ipairs(viable_waltzes:reverse()) do
      if not waltz and v.tier < bad_tier and player.tp >= v.tp and silibs.can_recast_ability(v.name) then
        waltz = v
      end
    end
    -- If went through all viable waltzes and still don't have one selected, cancel operation
    if not waltz then
      add_to_chat(122, 'Insufficient TP ['..tostring(player.tp)..'] or all on cooldown. Cancelling.')
      eventArgs.cancel = true
      return
    end
  end

  if waltz.name ~= spell.english then
    send_command('@input /ja "'..waltz.name..'" '..tostring(spell.target.raw))
    eventArgs.cancel = true
    return
  end

  if missingHP and missingHP > 0 then
    add_to_chat(122,'Trying to cure '..tostring(missingHP)..' HP using '..waltz.name..'.')
  end
end

function silibs.set_waltz_stats(table)
  silibs.waltz_stats.base_chr = player.base_chr
  silibs.waltz_stats.base_vit = player.base_vit
  -- Write given values to settings table
  for k,v in pairs(table) do
    if rawget(silibs.waltz_stats,k) ~= nil then
      silibs.waltz_stats[k] = v
    else
      print('Silibs: Invalid waltz stat defined \''..tostring(k)..'\'')
    end
  end
end

-- On any action event, mark mobs that we tag with TH.  Also, update the last time tagged mobs were acted on.
function silibs.on_action_for_th(action)
  if type(action) ~= 'table' then return end
  local action_details
  local action_category = action and silibs.action_categories[action.category]
  local resource
  if action_category then
    resource = res[action_category.resource]
  end
  if resource then
    action_details = resource[action.param]
  end

  -- category == 1=melee, 2=ranged, 3=weaponskill, 4=spell, 6=job ability, 14=unblinkable JA
  -- Only bother if Treasure mode is on
  if state.TreasureMode.value ~= 'None' and action_category then
    -- If player takes action
    if action.actor_id == player.id then
      -- If single target offensive action taken, mark mob as tagged
      if action.target_count == 1 then
        local target = windower.ffxi.get_mob_by_id(action.targets[1].id)
        if silibs.is_target_enemy(target) then
          local prev_tagged
          if info.tagged_mobs[target.id] then
            prev_tagged = true
          end
          -- Update mob in tag list
          info.tagged_mobs[target.id] = os.clock()
          -- Melee attacks alone do not cause update to engaged set, so call manually
          if (state.TreasureMode.value == 'Tag' or state.TreasureMode.value == 'SATA')
            and not prev_tagged and action_category.category == 1
          then
            equip(get_melee_set()) -- Sets the equipment table to be used in next update
            send_command('gs c update') -- Call the update command to force gear change
          end
        end
      -- If AoE offensive action taken and action is in list of th_aoe_actions, mark all mobs as tagged
      elseif action.target_count > 1
        and not silibs.th_aoe_disabled
        and action_details
        and silibs.th_aoe_actions[action_category.th_aoe_category][action_details.name]
      then
        for index,target in pairs(action.targets) do
          -- Get additional info about target
          target = windower.ffxi.get_mob_by_id(target.id)
          -- Determine if action was offensive based on target type
          if silibs.is_target_enemy(target) then
            info.tagged_mobs[target.id] = os.clock()
          end
        end
      end
    -- If mob acts, keep an update of last action time for TH bookkeeping
    elseif info.tagged_mobs[action.actor_id] then
      info.tagged_mobs[action.actor_id] = os.clock()
    -- If anyone else acts, check if any of the targets are our tagged mobs
    else
      for index,target in pairs(action.targets) do
        if info.tagged_mobs[target.id] then
          info.tagged_mobs[target.id] = os.clock()
        end
      end
    end
  end
end

-- Remove mobs that we've marked as tagged with TH if we haven't seen any activity from or on them
-- for over 3 minutes.  This is to handle deagros, player deaths, or other random stuff where the
-- mob is lost, but doesn't die.
function silibs.cleanup_tagged_mobs()
  local current_time = os.clock()
  -- Search list and flag old entries.
  for target_id,last_action_time in pairs(info.tagged_mobs) do
    local time_since_last_action = current_time - last_action_time
    if time_since_last_action > 180 then
      -- Clean out mobs flagged for removal.
      info.tagged_mobs[target_id] = nil
      if _settings.debug_mode then
        add_to_chat(123,'Over 3 minutes since last action on mob '..target_id..'. Removing from tagged mobs list.')
      end
    end
  end
end

-- Need to use this event handler to listen for deaths in case Battlemod is loaded,
-- because Battlemod blocks the 'action message' event.
--
-- This function removes mobs from our tracking table when they die.
function silibs.on_incoming_chunk_for_th(id, data, modified, injected, blocked)
  if id == 0x29 and silibs.th_enabled then
      local target_id = data:unpack('I',0x09)
      local message_id = data:unpack('H',0x19)%32768

      -- Remove mobs that die from our tagged mobs list.
      if info.tagged_mobs[target_id] then
          -- 6 == actor defeats target
          -- 20 == target falls to the ground
          if message_id == 6 or message_id == 20 then
              if _settings.debug_mode then add_to_chat(123,'Mob '..target_id..' died. Removing from tagged mobs table.') end
              info.tagged_mobs[target_id] = nil
          end
      end
  end
end

-- Clear out the entire tagged mobs table when zoning.
function silibs.on_zone_change_for_th(new_zone, old_zone)
  if _settings.debug_mode then add_to_chat(123,'Zoning. Clearing tagged mobs table.') end
  info.tagged_mobs:clear()
end

function silibs.on_action_for_rolls(act)
  -- Detect roll actions used by self in order to display results
  if act and type(act) == 'table' and act.category == 6 and silibs.roll_info[act.param] then
    local roll_self_or_party
    if act.actor_id == player.id then -- This is your own roll
      roll_self_or_party = 'self'
    else -- Party member rolled this and it hit you
      for i=1,#act.targets do
        if act.targets[i].id == player.id then
          roll_self_or_party = 'party'
          break
        end
      end
    end
    
    if roll_self_or_party == 'self' or roll_self_or_party == 'party' then
      if silibs.custom_roll_timers_enabled then
        local is_self = roll_self_or_party == 'self'
        local message_id = act.targets[1].actions[1].message
        local roll_info = silibs.roll_info[act.param]

        -- 420 = first roll, 424 and 425 = double up
        if message_id == 420 or message_id == 424 or message_id == 425 then
          local roll_value = act.targets[1].actions[1].param
          local active_roll = silibs.my_active_rolls[roll_info.status]
          if active_roll then -- If already tracking, update value
            if active_roll.value ~= roll_value or active_roll.is_self ~= is_self then
              silibs.clear_roll_timer(active_roll)
              -- Update roll value
              active_roll.value = roll_value
              active_roll.is_self = is_self
              -- Update timer text
              silibs.set_roll_timer(active_roll)
            end
          else -- If not tracking, start tracking
            silibs.my_active_rolls[roll_info.status] = roll_info
            silibs.my_active_rolls[roll_info.status].value = roll_value
            silibs.my_active_rolls[roll_info.status].is_self = is_self
            -- We don't know the expiration from this message.
            -- Let the buff packet update handle correcting the timer. We can at least create
            -- it with a default expiration to show that a roll buff exists
            silibs.set_roll_timer(silibs.my_active_rolls[roll_info.status])
          end
        elseif message_id == 426 then -- Busted double up
          local active_roll = silibs.my_active_rolls[roll_info.status]
          if active_roll then -- If tracking this roll, clear it from tracking and clear timer
            silibs.clear_roll_timer(active_roll)
            silibs.my_active_rolls[roll_info.status] = nil
          end
          silibs.clear_double_up_timer() -- Busting removes the Double Up Chance buff
        end
      end
    end

    -- Handle displaying text
    if roll_self_or_party == 'self' then
      if silibs.custom_roll_text_enabled.show_self then silibs.display_roll_info(act) end
    elseif roll_self_or_party == 'party' then
      if silibs.custom_roll_text_enabled.show_others then silibs.display_roll_info(act) end
    end
  end
end

function silibs.parse_buff_update_packet(data)
  if silibs.custom_roll_timers_enabled then
    -- Sends buff ID and expiration for all of main player's current buffs
    -- Update buff durations. credit: Akaden, Buffed addon
    -- This packet is triggered when any buff is gained or dropped
    -- With this packet we can track our roll buffs and update timers properly
    local order = data:unpack('H',0x05)
    if order == 9 then
      local buffs = T{}

      -- If you have no buffs, the buffs table will be empty (printed like {})
      -- Sometimes, such as when zoning, it will give you a full 32 buff list
      -- where every id == 0. That packet can be ignored, to avoid dumping buffs when
      -- you really shouldn't. Mark it as a dud and don't process.
      local is_dud

      -- read ids
      for i = 1, 32 do
        local index = 0x09 + ((i-1) * 0x02)
        local status_i = data:unpack('H', index)

        if i == 1 and status_i == 0 then
          is_dud = true
          break
        end

        if status_i ~= 255 then
          buffs[i] = { id = status_i }
        end
      end

      if not is_dud then
        local is_double_buff_still_active = false
        -- read times
        for i = 1, 32 do
          
          local buff = buffs[i]
          local roll = buff and silibs.roll_info_by_status[buff.id]
          if roll then
            local active_roll = silibs.my_active_rolls[buff.id]
            if not active_roll then
              -- Start tracking this new roll if not already tracking
              silibs.my_active_rolls[roll.status] = roll
              active_roll = silibs.my_active_rolls[roll.status]
              active_roll.value = 0
            end

            -- Update expirations for my active rolls
            roll.is_still_active = true
            if not roll.is_timer_set then
              local index = 0x49 + ((i-1) * 0x04)
              roll.expiration = silibs.from_server_time(data:unpack('I', index))
              silibs.set_roll_timer(roll)
              roll.is_timer_set = true
            end
          elseif buff and buff.id == 308 then -- Double-Up Chance
            is_double_buff_still_active = true
            if not silibs.is_double_up_active then
              local index = 0x49 + ((i-1) * 0x04)
              local expiration = silibs.from_server_time(data:unpack('I', index))
              silibs.set_double_up_timer(expiration)
            end
          end
        end

        -- Remove any rolls marked as active that were not in this update packet, because it
        -- means they are no longer active
        for k,v in pairs(silibs.my_active_rolls) do
          if not v.is_still_active then
            silibs.clear_roll_timer(v)
            silibs.my_active_rolls[k] = nil
          else
            v.is_still_active = nil
          end
        end

        if not is_double_buff_still_active and silibs.is_double_up_active then
          silibs.clear_double_up_timer()
        end
      end
    end
  end
end

function silibs.set_double_up_timer(expiration)
  local exp = expiration and expiration-os.time() or 45
  exp = math.floor(exp)
  send_command('@timers c "Double-Up Chance" ' ..exp.. ' down abilities/00193.png')
  silibs.is_double_up_active = true
end

function silibs.clear_double_up_timer()
  send_command('@timers d "Double-Up Chance"')
  silibs.is_double_up_active = false
end

function silibs.clear_roll_timer(roll)
  send_command('@timers d "'..silibs.roll_timer_name(roll)..'"')
  roll.is_timer_set = false
end

function silibs.set_roll_timer(roll)
  local exp = roll and roll.expiration and roll.expiration-os.time() or 600
  exp = math.floor(exp)
  if roll then
    send_command('@timers c "'..silibs.roll_timer_name(roll)..'" ' ..exp.. ' down abilities/00193.png')
  end
end

function silibs.roll_timer_name(roll)
  local self_flag = roll.is_self and silibs.self_timers_symbol or ''
  local value_str = ''

  if roll.value > 0 then
    value_str = ' '..roll.value
    if roll.value == roll.lucky then
      value_str = value_str..' Lucky'
    elseif roll.value == roll.unlucky then
      value_str = value_str..' Unlucky'
    elseif roll.value == 11 then
      value_str = value_str..' MAX'
    end
  end

  return self_flag..roll.short_name..value_str
end

function silibs.from_server_time(t)
  return t / 60 + silibs.start_of_era
end

function silibs.determine_snapshot_sets()
  local snapshot_sets = {}
  snapshot_sets['Velocity'] = {}
  if sets then
    for i=70,0,-1 do
      if sets['Snapshot'..i] then
        snapshot_sets[i] = set_combine(sets['Snapshot'..tostring(i)], {})
      elseif snapshot_sets[i+1] then
        snapshot_sets[i] = set_combine(snapshot_sets[i+1], {})
      end
      -- Fill in velocity sets
      if sets['Velocity'] and sets['Velocity']['Snapshot'..tostring(i)] then
        snapshot_sets['Velocity'][i] = set_combine(sets['Velocity']['Snapshot'..tostring(i)], {})
      elseif snapshot_sets['Velocity'][i+1] then
        snapshot_sets['Velocity'][i] = set_combine(snapshot_sets['Velocity'][i+1], {})
      end
    end

    -- Backfill
    for i=0,70,1 do
      if not snapshot_sets[i] and snapshot_sets[i-1] then
        snapshot_sets[i] = set_combine(snapshot_sets[i-1], {})
      end
      -- Fill in velocity sets
      if not snapshot_sets['Velocity'][i] and snapshot_sets['Velocity'][i-1] then
        snapshot_sets['Velocity'][i] = set_combine(snapshot_sets['Velocity'][i-1], {})
      -- If velocity sets are still empty, fill with regular snapshot sets
      elseif not snapshot_sets['Velocity'][i] and snapshot_sets[i] then
        snapshot_sets['Velocity'][i] = set_combine(snapshot_sets[i], {})
      end
    end
  end

  silibs.snapshot_sets = snapshot_sets
end

function silibs.on_action_for_flurry(act)
  if type(action) ~= 'table' then return end

  -- Check if you are a target of spell
  local actionTargets = act.targets
  local playerId = windower.ffxi.get_player().id
  local isTarget = false
  for _, target in ipairs(actionTargets) do
    if playerId == target.id then
      isTarget = true
    end
  end
  if isTarget == true then
    if act.category == 4 then
      local param = act.param
      if param == 845 and flurry ~= 2 then
        silibs.latest_flurry_buff = 1
      elseif param == 846 then
        silibs.latest_flurry_buff = 2
      end
    end
  end
end

function silibs.select_snapshot_set_for_ranged_attacks(spell, eventArgs)
  if spell.action_type == 'Ranged Attack' then
    if not silibs.snapshot_sets then
      silibs.determine_snapshot_sets()
    end
    -- Determine weapon flurry
    local snapshot_needed = 70
    local main_bonus = player.equipment.main and silibs.snapshot_weapons[player.equipment.main] or 0
    local sub_bonus = player.equipment.sub and silibs.snapshot_weapons[player.equipment.sub] or 0
    local range_bonus = player.equipment.range and silibs.snapshot_weapons[player.equipment.range] or 0
    
    snapshot_needed = snapshot_needed - main_bonus
    snapshot_needed = snapshot_needed - sub_bonus
    snapshot_needed = snapshot_needed - range_bonus

    -- Determine magic flurry
    if buffactive['Flurry'] then
      if silibs.latest_flurry_buff == 1 then
        snapshot_needed = snapshot_needed - 15
      elseif silibs.latest_flurry_buff == 2 then
        snapshot_needed = snapshot_needed - 30
      end
    end

    if buffactive['Embrava'] then
      snapshot_needed = snapshot_needed - 25
    end

    -- Add snapshot traits/gifts
    -- COR 5% at 100 JP, 10% at 1200 JP
    -- RNG 2% per merit
    if player.main_job == 'COR' then
      if player.job_points.cor.jp_spent >= 1200 then
        snapshot_needed = snapshot_needed - 10
      elseif player.job_points.cor.jp_spent >= 100 then
        snapshot_needed = snapshot_needed - 5
      end
    elseif player.main_job == 'RNG' then
      snapshot_needed = snapshot_needed - (player.merits.snapshot * 2)
    end

    -- Ensure snapshot_needed does not go negative
    snapshot_needed = math.max(snapshot_needed, 0)

    if buffactive['Velocity Shot'] and silibs.snapshot_sets['Velocity'][snapshot_needed] then
      equip(silibs.snapshot_sets['Velocity'][snapshot_needed])
      eventArgs.handled = true -- Prevents Mote/Sel lib from overwriting the equipSet
    elseif silibs.snapshot_sets[snapshot_needed] then
      equip(silibs.snapshot_sets[snapshot_needed])
      eventArgs.handled = true -- Prevents Mote/Sel lib from overwriting the equipSet
    end
  end
end

function silibs.display_roll_info(act)
  --This is used later to allow/disallow busting
  --If you are not the rollActor you will not be disallowed to bust.
  local actor_is_self = act.actor_id == player.id
  local roll_id = act.param
  local roll_result = act.targets[1].actions[1].param
  local roll_char = chars['circle'..roll_result]
  local roll_size = (actor_is_self and state.LuzafRing and state.LuzafRing.value and chars.circlejot..' ') or ''
  local roll_info = silibs.roll_info[roll_id]
  local source_char = actor_is_self and '' or chars.implies..' '
  local members_affected = {}

  local party = windower.ffxi.get_party()
  for member in pairs(party) do
    for affected_target = 1, #act.targets do
      --if mob is nil then the party member is not in zone, will fire an error.
      if type(party[member]) == 'table' and party[member].mob and act.targets[affected_target].id == party[member].mob.id then
        members_affected[affected_target] = party[member].name
      end
    end
  end

  local members_affected_str = table.concat(members_affected, ', ')
  local is_busted
  if roll_result == roll_info.lucky or roll_result == 11 then -- Make result green
    roll_char = string.char(31,204)..roll_char
  elseif roll_result == roll_info.unlucky then
    roll_char = string.char(31,167)..roll_char -- Make result red
  elseif roll_result == 12 and #members_affected > 0 then -- Busted
    roll_char = string.char(31,167)..chars.times -- Make result red
    is_busted = true
  end

  if is_busted then
    add_to_chat(001, source_char..roll_char..' Bust '..roll_char..' '..string.char(0x1E, 6)..roll_info.name..string.char(31,167))
  else
    add_to_chat(001, source_char..roll_char..' '..string.char(0x1E, 6)..roll_info.name..string.char(31,001)..
        ' (Luck: '..string.char(31,204)..roll_info.lucky..string.char(31,001)..
               '/'..string.char(31,167)..roll_info.unlucky..string.char(31,001)..
        '): '..roll_size..members_affected_str)
  end
end

function silibs.update_combat_form()
  if silibs.get_dual_wield_needed() <= 0 or not silibs.is_dual_wielding() then
    state.CombatForm:reset()
  else
    if silibs.get_dual_wield_needed() > 0 and silibs.get_dual_wield_needed() <= 11 then
      state.CombatForm:set('LowDW')
    elseif silibs.get_dual_wield_needed() > 11 and silibs.get_dual_wield_needed() <= 18 then
      state.CombatForm:set('MidDW')
    elseif silibs.get_dual_wield_needed() > 18 and silibs.get_dual_wield_needed() <= 31 then
      state.CombatForm:set('HighDW')
    elseif silibs.get_dual_wield_needed() > 31 and silibs.get_dual_wield_needed() <= 42 then
      state.CombatForm:set('SuperDW')
    elseif silibs.get_dual_wield_needed() > 42 then
      state.CombatForm:set('MaxDW')
    end
  end
end

-- Saves the state of your weapons
-- Re-arms your weapons when conditions are met
-- Can be temporarily disabled by adding a toggled rearming lock state:
--    state.RearmingLock = M(false, 'Rearming Lock')
-- Which can be turned off or off with a keybind
--    send_command('bind @w gs c toggle RearmingLock')
function silibs.update_and_rearm_weapons()
  -- Save state of any equipped weapons
  if player.equipment.main ~= 'empty' and player.equipment.main ~= '' and player.equipment.main ~= nil then
    if not is_encumbered('main') then
      silibs.most_recent_weapons.main = player.equipment.main
    end
    if not is_encumbered('sub') then
      silibs.most_recent_weapons.sub = player.equipment.sub
    end
  end
  if player.equipment.ammo == 'empty' or player.equipment.ammo == '' or player.equipment.ammo == nil then
    if player.equipment.ranged ~= 'empty' and player.equipment.ranged ~= '' and player.equipment.ranged ~= nil then
      -- Only save if ranged is a combat item
      local rangedItem = res.items:with('name', player.equipment.ranged)
      if res.skills[rangedItem.skill].category == 'Combat' then
        if not is_encumbered('ranged') then
          silibs.most_recent_weapons.ranged = player.equipment.ranged
        end
        if not is_encumbered('ammo') then
          silibs.most_recent_weapons.ammo = player.equipment.ammo
        end
      end
    end
  -- If ammo is an ammunition (like bullet), update ranged if not empty
  elseif res.items:with('en', player.equipment.ammo).skill ~= nil and
      res.items:with('en', player.equipment.ammo).skill > 0 then
    if player.equipment.ranged ~= 'empty' and player.equipment.ranged ~= '' and player.equipment.ranged ~= nil then
      -- Only save if ranged is a combat item
      local rangedItem = res.items:with('name', player.equipment.ranged)
      if res.skills[rangedItem.skill].category == 'Combat' then
        if not is_encumbered('ranged') then
          silibs.most_recent_weapons.ranged = player.equipment.ranged
        end
        if not is_encumbered('ammo') then
          silibs.most_recent_weapons.ammo = player.equipment.ammo
        end
      end
    end
  -- If ammo is a stat item (like Aurgelmir Orb), update ranged even if empty
  else
    if not is_encumbered('ranged') then
      silibs.most_recent_weapons.ranged = player.equipment.ranged
    end
    if not is_encumbered('ammo') then
      silibs.most_recent_weapons.ammo = player.equipment.ammo
    end
  end

  -- Disarm Handling
  -- Table fills the string 'empty' for empty slot. It won't return nil
  -- Must check if sub is also empty (and weapon) because if main hand is removed while dual wielding, the sub stays on for
  -- 1 cycle longer which will result in the main hand re-equipping but not the sub
  -- Also, if the sub is a shield, it will stay on even if main hand is removed.
  local is_sub_armor
  if player.equipment.sub and player.equipment.sub ~= '' and player.equipment.sub ~= 'empty' then
    is_sub_armor = res.items:with('en', player.equipment.sub).category == 'Armor'
  else
    is_sub_armor = false
  end
  if ((player.equipment.main == 'empty' and silibs.most_recent_weapons.main ~= 'empty' and silibs.most_recent_weapons.main ~= '' and player.equipment.sub == 'empty')
      or (player.equipment.main == 'empty' and silibs.most_recent_weapons.main ~= 'empty' and silibs.most_recent_weapons.main ~= '' and is_sub_armor)
      or (player.equipment.ranged == 'empty' and silibs.most_recent_weapons.ranged ~= 'empty' and silibs.most_recent_weapons.ranged ~= ''))
      and (state.RearmingLock == nil or state.RearmingLock.value == false) then
    send_command('gs c rearm')
  end
end

function silibs.set_lockstyle()
  if not silibs.auto_lockstyle_enabled then
    return
  end
  -- Set lockstyle 3 seconds after changing job, trying immediately will error
  coroutine.schedule(function()
    if silibs.locked_style == false and silibs.lockstyle_set > 0 then
      send_command('input /lockstyleset '..silibs.lockstyle_set)
    end
  end, 3)
  -- In case lockstyle was on cooldown for first command, try again (lockstyle has 10s cd)
  coroutine.schedule(function()
    if silibs.locked_style == false and silibs.lockstyle_set > 0 then
      send_command('input /lockstyleset '..silibs.lockstyle_set)
    end
  end, 10)
end

function silibs.self_command(cmdParams, eventArgs)
  if silibs.premade_commands_enabled then
    local lowerCmdParams = T{}
    -- Make all cmdParams lowercase
    for i,j in ipairs(cmdParams) do
      lowerCmdParams[i] = j:lower()
    end
    if lowerCmdParams[1] == 'sneak' then
      silibs.use_sneak()
      eventArgs.handled = true
    elseif lowerCmdParams[1] == 'invis' or lowerCmdParams[1] == 'invisible' then
      silibs.use_invisible()
      eventArgs.handled = true
    elseif lowerCmdParams[1] == 'interact' or lowerCmdParams[1] == 'noinvis' then
      send_command('cancel Invisible; cancel Hide; cancel Gestation; cancel Camouflage')
      if lowerCmdParams[1] == 'interact' then
        silibs.interact()
      end
      eventArgs.handled = true
    elseif lowerCmdParams[1] == 'faceaway' then
      windower.ffxi.turn(player.facing - math.pi);
      eventArgs.handled = true
    elseif lowerCmdParams[1] == 'pause' then
      silibs.equip_loop_enabled = not silibs.equip_loop_enabled
      windower.add_to_chat(001, string.char(0x1F, 207)..'SilverLibs: '
          ..(silibs.equip_loop_enabled and 'Unpaused' or 'Paused')
          ..' equip loop.')
    elseif lowerCmdParams[1] == 'soultrapper' then
      if lowerCmdParams[2] ~= 'stop' then
        -- loop
        local cooldown = silibs.trap_soul()
        if cooldown then
          send_command:schedule(cooldown + 5, 'gs c soultrapper')
        end
      end
    elseif lowerCmdParams[1] == 'autoreraise' then
      silibs.set_auto_reraise_state(lowerCmdParams[2])
    elseif lowerCmdParams[1] == 'lock' then
      silibs.lock('manual', lowerCmdParams:slice(2):unpack())
    elseif lowerCmdParams[1] == 'unlock' then
      silibs.unlock('manual', lowerCmdParams:slice(2):unpack())
    elseif lowerCmdParams[1] == 'clearlocks' then
      silibs.clearlocks(lowerCmdParams:slice(2):unpack())
    end
    if silibs.force_lower_cmd then
      cmdParams = lowerCmdParams
    end
  end
  if silibs.haste_info_enabled then
    if cmdParams[1] == 'hasteinfo' then
      silibs.dw_needed = tonumber(cmdParams[2])
      if not silibs.midaction() then
        handle_equipping_gear(player.status)
      end
    end
  end
  if cmdParams[1] == 'rearm' then
    -- Filter locked slots out of equip command
    local weaponset_to_equip = silibs.enforce_gear_locks(silibs.most_recent_weapons)
    equip(weaponset_to_equip)
  end
end

-- 'ws_range' expected to be the range pulled from weapon_skills.lua
-- 's' is self player object
-- 't' is target object
function silibs.is_ws_out_of_range(ws_range, s, t)
  if ws_range == nil or s == nil or t == nil then
    print('Silibs: Invalid params for is_ws_out_of_range.')
    return true
  end

  local distance = t.distance:sqrt()
  local is_out_of_range = distance > (t.model_size + ws_range * silibs.range_mult[ws_range] + s.model_size)

  if is_out_of_range then
    windower.add_to_chat(167, 'Target out of range.')
  end

  return is_out_of_range
end

-- 'spell' is the same as input parameter in job_precast function of Mote libs
-- 'eventArgs' is the same as input parameter in job_precast function of Mote libs
function silibs.cancel_outranged_ws(spell, eventArgs)
  -- Ensure spell is a weaponskill to proceed
  if spell.type ~= 'WeaponSkill' or spell.targets['Self'] then
    return
  end

  local player = windower.ffxi.get_mob_by_target('me')
  local target = windower.ffxi.get_mob_by_id(spell.target.id)

  if silibs.is_ws_out_of_range(spell.range, player, target) then
    cancel_spell() -- Blocks the outgoing action packet that would perform the WS
    eventArgs.cancel = true -- Ensures gear doesn't swap
  end
end

-- Don't swap gear if status forbids the action
-- 'spell' is the same as input parameter in job_precast function of Mote libs
-- 'eventArgs' is the same as input parameter in job_precast function of Mote libs
function silibs.cancel_on_blocking_status(spell, eventArgs)
  local forbidden_statuses = silibs.action_type_blockers[spell.action_type] or {}
  for k,status in pairs(forbidden_statuses) do
    if buffactive[status] then
      windower.add_to_chat(167, 'Stopped due to status.')
      eventArgs.cancel = true -- Ensures gear doesn't swap
      return -- Ends function without finishing loop
    end
  end
end

-- Prevent gear from equipping if lock is enabled
function silibs.enforce_gear_locks(set_to_combine)
  local overrides = {}
  for k,v in pairs(silibs.locked_slots) do
    local slot_name = k
    local locks = v
    if not locks:empty() then
      overrides[slot_name]=player.equipment[slot_name]
    end
  end

  -- If set_to_combine is passed in, use set_combine and return the set
  -- otherwise just use equip() function
  if set_to_combine then
    set_to_combine = set_combine(set_to_combine, overrides)
  else
    equip(overrides)
  end

  return set_to_combine
end


--=============================================================================
--=============================================================================
--=============================================================================
--                     Feature-enabling functions
--=============================================================================
--=============================================================================
--=============================================================================
function silibs.enable_cancel_outranged_ws()
  silibs.cancel_outranged_ws_enabled = true
end

function silibs.enable_cancel_on_blocking_status()
  silibs.cancel_on_blocking_status_enabled = true
end

function silibs.enable_weapon_rearm()
  silibs.weapon_rearm_enabled = true
end

function silibs.enable_auto_lockstyle(set_number)
  if set_number then
    silibs.lockstyle_set = set_number
    silibs.auto_lockstyle_enabled = true
  end
end

function silibs.enable_premade_commands(feature_config)
  silibs.premade_commands_enabled = true
  if feature_config and feature_config.force_lower_cmd == false then
    silibs.force_lower_cmd = false
  else
    silibs.force_lower_cmd = true
  end
end

function silibs.enable_waltz_refiner(table)
  if not table then table = {} end
  silibs.set_waltz_stats(table)
  -- Overwrite the global function refine_waltz with our own.
  refine_waltz = silibs.refine_waltz
end

function silibs.enable_th(feature_config)
  silibs.th_enabled = true

  -- Set starting TH mode
  if feature_config and feature_config.starting_mode then
    state.TreasureMode:set(feature_config.starting_mode)
  elseif player.main_job == 'THF' then
    state.TreasureMode:set('Tag')
  end

  if feature_config and feature_config.disable_aoe_tag then
    silibs.th_aoe_disabled = true
  end

  -- User-defined aoe actions should overwrite/append existing lists
  if feature_config and feature_config.aoe_actions then
    for k,v in pairs(feature_config.aoe_actions) do
      local name = v.name
      local aoe_range = v.aoe_range
      local aoe_center_self = v.aoe_center_self
      -- If valid weaponskill and range not 0, add to list
      local found = res.weapon_skills:with('en', name) or res.spells:with('en', name) or res.job_abilities:with('en', name)
      if found then
        found.aoe_range = aoe_range
        found.aoe_center_self = aoe_center_self
        -- Only allow ranges between 0 and 30
        if found.aoe_range > 0 and found.aoe_range < 30 then
          -- Place into proper category
          if found.prefix == '/weaponskill' then
            silibs.th_aoe_actions.weaponskills[name] = found
          elseif found.prefix == '/magic' then
            silibs.th_aoe_actions.spells[name] = found
          elseif found.prefix == '/jobability' then
            silibs.th_aoe_actions.abilities[name] = found
          end
        else
          windower.add_to_chat(123, 'Silibs: \''..name..'\' invalid range of '..aoe_range..'.')
        end
      else
        windower.add_to_chat(123, 'Silibs: \''..name..'\' invalid name. Not a WS, spell, or JA')
      end
    end
  end

  -- Override any other TH libraries that might already be loaded
  on_status_change_for_th = function() end
  on_target_change_for_th = function() end
  on_action_for_th = function() end
  on_incoming_chunk_for_th = function() end
  on_zone_change_for_th = function() end
  if job_state_change_via_th then
    job_state_change = job_state_change_via_th
  end
end

function silibs.enable_luopan_ui(luopan_config)
  if luopan_config then
    if luopan_config.align_right then
      silibs.ui.luopan:right_justified(luopan_config.align_right)
    end
    if luopan_config.x and luopan_config.y then
      silibs.ui.luopan:pos(
        luopan_config.x,
        luopan_config.y
      )
    end
    if luopan_config.is_visible_by_default == false then
      state.ShowLuopanUi:set(false)
    else
      state.ShowLuopanUi:set(true)
    end
  end

  -- Turn on this UI if no config was passed but job is GEO
  if not luopan_config and (player.main_job == 'GEO' or player.sub_job == 'GEO') then
    state.ShowLuopanUi:set(true)
  end
end

function silibs.customize_quick_magic_spells(custom_quick_magic_spells)
  local is_input_valid = true
  local spell_types = S{'WhiteMagic', 'BlackMagic', 'BardSong', 'Ninjutsu', 'SummonerPact', 'BlueMagic', 'Geomancy'}

  -- If input is valid, customize spell list
  if custom_quick_magic_spells and type(custom_quick_magic_spells) == 'table' then
    for spell_type, _ in spell_types:it() do
      if custom_quick_magic_spells[spell_type] then
        if type(custom_quick_magic_spells[spell_type]) == 'table' then
          silibs.quick_magic_spells[spell_type] = S(custom_quick_magic_spells[spell_type])
        else
          is_input_valid = false
        end
      end
    end
  end

  if not is_input_valid then
    print('Silibs: customize_quick_magic_spells input is not a valid format.')
  end
end

function silibs.enable_equip_loop()
  silibs.equip_loop_enabled = true
end

function silibs.enable_custom_roll_text(hide_others_rolls)
  silibs.custom_roll_text_enabled.show_self = true
  silibs.custom_roll_text_enabled.show_others = true
  if hide_others_rolls then
    silibs.custom_roll_text_enabled.show_others = false
  end
end

function silibs.enable_custom_roll_timers(self_timers_symbol)
  silibs.custom_roll_timers_enabled = true
  if self_timers_symbol then
    silibs.self_timers_symbol = self_timers_symbol
  end
end

function silibs.enable_haste_info()
  silibs.haste_info_enabled = true
  send_command('hasteinfo report')
end

function silibs.enable_elemental_belt_handling(has_obi, has_orpheus, condition_fn)
  silibs.elemental_belt_handling_enabled = true
  silibs.has_obi = has_obi
  silibs.has_orpheus = has_orpheus
  silibs.elemental_belt_handling_condition = condition_fn
end

function silibs.enable_snapshot_auto_equip()
  silibs.snapshot_auto_equip_enabled = true
  silibs.latest_flurry_buff = buffactive['Flurry'] and 1 or nil
end

function silibs.enable_handle_ammo_swaps(ammo_map)
  silibs.handle_ammo_swaps_enabled = true
  silibs.ammo_assignment = ammo_map
end

-- config has options:
-- At least one slot must be defined: 'head', 'body'
-- mode (optional string): set default mode, either 'on', 'off', or 'auto' (default: auto)
-- hpp (optional number): determines HP threshold for which 'auto' mode will equip reraise gear (default: 10)
function silibs.enable_auto_reraise(config)
  if not config or not config.set then
    windower.add_to_chat(123, 'Silibs: No valid gear set defined for auto reraise mode')
  else
    silibs.auto_reraise_config.set = config.set
    silibs.auto_reraise_enabled = true
  end

  if config.mode == 'on' or config.mode == 'off' or config.mode == 'auto' then
    silibs.auto_reraise_config.mode = config.mode
  end

  silibs.set_auto_reraise_state(silibs.auto_reraise_config.mode)

  silibs.auto_reraise_config.hpp = config.hpp or 10
end

function silibs.enable_lock_on_usable_items()
  silibs.lock_on_usable_items_enabled = true
end


--=============================================================================
--=============================================================================
--=============================================================================
--                         Gearswap lifecycle hooks
--=============================================================================
--=============================================================================
--=============================================================================
function silibs.user_setup_hook()
  silibs.locked_style = false -- Lockstyle unlocks on subjob change
  silibs.set_lockstyle()
  
  if silibs.custom_roll_timers_enabled then
    send_command('reload timers')
  
    -- Rolls will be tracked here indexed by name. A packet listener will remove rolls from this list
    -- when they fall off, and update timers based on data coming from the game.
    silibs.my_active_rolls = {
      -- Example: [321] = silibs.roll_info + {value=3, expiration=12345, is_timer_set=false, is_self=true},
    }
    -- Check if any rolls are currently active and begin tracking them. Just have to assume they were
    -- rolled by self.
    for id,ja in pairs(silibs.roll_info) do
      if buffactive[ja.name] then
        silibs.my_active_rolls[ja.status] = ja
        silibs.my_active_rolls[ja.status].value = 0
        silibs.my_active_rolls[ja.status].is_self = false
      end
    end
    
    -- Timers addon hasn't reloaded yet. Must delay so that it creates timers after the reload
    for status_id,active_roll in pairs(silibs.my_active_rolls) do
      silibs.set_roll_timer:schedule(2, active_roll)
    end
  end
end

function silibs.precast(spell, action, spellMap, eventArgs)
  if silibs.cancel_outranged_ws_enabled then
    silibs.cancel_outranged_ws(spell, eventArgs)
  end
  if silibs.cancel_on_blocking_status_enabled then
    silibs.cancel_on_blocking_status(spell, eventArgs)
  end
  if silibs.snapshot_auto_equip_enabled then
    silibs.select_snapshot_set_for_ranged_attacks(spell, eventArgs)
  end

  if silibs.handle_ammo_swaps_enabled then
    silibs.equip_ammo(spell, action, spellMap, eventArgs)
  end

  -- Cancel action if casting Warp II on self
  if spell.english == 'Warp II' and spell.target.type == 'SELF' then
    eventArgs.cancel = true
    add_to_chat(123, '** Action canceled: Detected casting Warp II on self. **')
  end

  -- Use special FC set under certain conditions.
  -- SCH can use sets.precast.FC.QuickMagic.RDM.Grimoire for example. Really, any combination of
  -- QuickMagic, RDM, and Grimoire (or LightArts or DarkArts) as long as it's in that order
  if spell.action_type == 'Magic' and sets.precast.FC then
    local customEquipSet = select_specific_set(sets.precast.FC, spell, spellMap)
    -- Add optional casting mode
    if customEquipSet[state.CastingMode.current] then
      customEquipSet = customEquipSet[state.CastingMode.current]
    end
    -- If spell is on the quick magic list, and user has a quick magic set, use it
    if customEquipSet['QuickMagic'] and (spell.type == 'Trust' or silibs.quick_magic_spells[spell.type]:contains(spell.en)) then
      customEquipSet = customEquipSet['QuickMagic']
      equip(customEquipSet)
      eventArgs.handled = true -- Prevents Mote lib from overwriting the equipSet
    end
    if player.sub_job == 'RDM' and player.sub_job_level > 0 and customEquipSet['RDM'] then
      customEquipSet = customEquipSet['RDM']
      equip(customEquipSet)
      eventArgs.handled = true -- Prevents Mote lib from overwriting the equipSet
    end
    if player.main_job == 'SCH' then
      if spell.type == 'WhiteMagic' and (buffactive['Light Arts'] or buffactive['Addendum: White']) then
        if customEquipSet['Grimoire'] then
          customEquipSet = customEquipSet['Grimoire']
          equip(customEquipSet)
          eventArgs.handled = true -- Prevents Mote lib from overwriting the equipSet
        elseif customEquipSet['LightArts'] then
          customEquipSet = customEquipSet['LightArts']
          equip(customEquipSet)
          eventArgs.handled = true -- Prevents Mote lib from overwriting the equipSet
        end
      elseif spell.type == 'BlackMagic' and (buffactive['Dark Arts'] or buffactive['Addendum: Black']) then
        -- Add Grimoire set if exists
        if customEquipSet['Grimoire'] then
          customEquipSet = customEquipSet['Grimoire']
          equip(customEquipSet)
          eventArgs.handled = true -- Prevents Mote lib from overwriting the equipSet
        elseif customEquipSet['DarkArts'] then
          customEquipSet = customEquipSet['DarkArts']
          equip(customEquipSet)
          eventArgs.handled = true -- Prevents Mote lib from overwriting the equipSet
        end
      end
    end
  end
end

function silibs.post_precast(spell, action, spellMap, eventArgs)
  if silibs.th_enabled and state.TreasureMode.value ~= 'None' and spell.action_type ~= 'Item' then
    -- Equip TH gear if appropriate
    if state.TreasureMode.value == 'Fulltime'
      or (state.TreasureMode.value == 'SATA'
        and (((state.Buff['Sneak Attack'] or state.Buff['Trick Attack'])
            and spell.type == 'WeaponSkill'
            and spell.target.type == 'MONSTER')
          or (spell.name == 'Sneak Attack' or spell.name == 'Trick Attack')))
      or (state.TreasureMode.value == 'Tag'
        and spell.target.type == 'MONSTER'
        and not info.tagged_mobs[spell.target.id])
    then
      -- If using RA, use RA TH set if it exists
      if player.equipment.range and player.equipment.range ~= 'empty' then
        if sets.TreasureHunter.RA then
          equip(sets.TreasureHunter.RA)
        else
          windower.add_to_chat(123, 'Silibs: sets.TreasureHunter.RA not found.')
        end
      else
        if sets.TreasureHunter then
          equip(sets.TreasureHunter)
        else
          windower.add_to_chat(123, 'Silibs: sets.TreasureHunter not found.')
        end
      end
    -- Handle AoE actions separately
    elseif (not silibs.th_aoe_disabled and state.TreasureMode.value == 'Tag') then
      local aoe_action = (spell.type == 'WeaponSkill' and silibs.th_aoe_actions.weaponskills[spell.name])
        or (spell.action_type == 'Magic' and silibs.th_aoe_actions.spells[spell.name])
        or (spell.type == 'JobAbility' and silibs.th_aoe_actions.abilities[spell.name])
      if aoe_action then
        -- Get list of enemies in range
        local aoe_center_target = (aoe_action.aoe_center_self and player) or (not aoe_action.aoe_center_self and spell.target)
        -- Round up the range; better to equip TH for mobs slightly out of range than to not equip and end up having mobs marked
        -- as tagged with TH when you didn't actually have the TH gear on.
        local enemies = silibs.get_enemies_in_range(math.ceil(aoe_action.aoe_range), aoe_center_target)
        -- If spell targeting enemy but centered on self (such as Geist Wall), ensure the targeted enemy
        -- is also in the enemies list because it could be outside of the aoe but still hit it because it was the target
        if not enemies:with('id', spell.target.id) and aoe_action.aoe_center_self and spell.target.type == 'MONSTER' then
          enemies:append(spell.target)
        end
        -- If at least one enemy is not yet tagged with TH, equip TH set
        local end_loop
        for k,v in pairs(enemies) do
          if not end_loop and not info.tagged_mobs[v.id] and v.hpp > 0 then
            -- If using RA, use RA TH set if it exists
            if player.equipment.range and player.equipment.range ~= 'empty' then
              if sets.TreasureHunter.RA then
                equip(sets.TreasureHunter.RA)
              end
            else
              if sets.TreasureHunter then
                equip(sets.TreasureHunter)
              end
            end
            end_loop = true
            -- To save us from having to process all this again in midcast, set a flag to tell
            -- Midcast function to keep TH set on if this action has a cast time
            if aoe_action.cast_time then
              spell.use_th_midcast = true
            end
          end
        end
      end
    end
  end

  if spell.type == 'CorsairRoll' then
    silibs.is_doubling_up = false
  elseif spell.english == 'Double-Up' then
    silibs.is_doubling_up = true
  end

  if not spell.interrupted then
    if spell.english:startswith('Indi-') then
      if spell.target.type == 'SELF' then
        silibs.last_indi = string.sub(spell.english,6)
      end
		elseif spell.english:startswith('Geo-') or spell.english == 'Mending Halation' or spell.english == 'Radial Arcana' then
			eventArgs.handled = true
			if spell.english:startswith('Geo-') then
				silibs.last_geo = string.sub(spell.english,5)
			end
    end
  end

  -- Equip elemental belts if appropriate
  if silibs.elemental_belt_handling_enabled and (silibs.elemental_belt_handling_condition == nil or silibs.elemental_belt_handling_condition()) then
    silibs.handle_elemental_belts(spell, spellMap, 'precast')
  end

  silibs.protect_rare_ammo(spell, action, spellMap, eventArgs)

  -- Ignore equip for locked slots
  silibs.enforce_gear_locks()

  -- Equip auto-reraise gear as appropriate
  equip(silibs.get_auto_reraise_gear())

  -- Should always be last in post_precast
  silibs.set_midaction(spell, action, spellMap, eventArgs)
end

function silibs.midcast(spell, action, spellMap, eventArgs)
  -- If spell is on the quick magic list, and user has a quick magic set, use it
  if spell.action_type == 'Magic' and sets.precast.FC then
    local customEquipSet = select_specific_set(sets.precast.FC, spell, spellMap)
    -- Add optional casting mode
    if customEquipSet[state.CastingMode.current] then
      customEquipSet = customEquipSet[state.CastingMode.current]
    end
    if customEquipSet['QuickMagic'] and (spell.type == 'Trust' or silibs.quick_magic_spells[spell.type]:contains(spell.en)) then
      customEquipSet = customEquipSet['QuickMagic']
      equip(customEquipSet)
      if player.sub_job == 'RDM' and player.sub_job_level > 0 and customEquipSet['RDM'] then
        customEquipSet = customEquipSet['RDM']
        equip(customEquipSet)
      end
      eventArgs.handled = true -- Prevents Mote lib from overwriting the equipSet
    end
  end
end

function silibs.post_midcast(spell, action, spellMap, eventArgs)
  if silibs.handle_ammo_swaps_enabled then
    silibs.equip_ammo(spell, action, spellMap, eventArgs)
  end

  -- Equip elemental belts if appropriate
  if silibs.elemental_belt_handling_enabled and (silibs.elemental_belt_handling_condition == nil or silibs.elemental_belt_handling_condition()) then
    silibs.handle_elemental_belts(spell, spellMap, 'midcast')
  end

  -- TH needs to be on for midcast too in order to apply TH to mob
  -- SATA-compatible actions (melee & WS) do not have midcast
  if silibs.th_enabled and state.TreasureMode.value ~= 'None' and spell.action_type ~= 'Item' then
    -- Equip TH gear if appropriate
    if state.TreasureMode.value == 'Fulltime'
      or (state.TreasureMode.value == 'Tag'
        and spell.target.type == 'MONSTER'
        and not info.tagged_mobs[spell.target.id]) -- Single target tagging
      or spell.use_th_midcast -- AoE tagging
    then
      -- If using RA, use RA TH set if it exists
      if player.equipment.range and player.equipment.range ~= 'empty' then
        if sets.TreasureHunter.RA then
          equip(sets.TreasureHunter.RA)
        else
          windower.add_to_chat(123, 'Silibs: sets.TreasureHunter.RA not found.')
        end
      else
        if sets.TreasureHunter then
          equip(sets.TreasureHunter)
        else
          windower.add_to_chat(123, 'Silibs: sets.TreasureHunter not found.')
        end
      end
    end
  end

  -- Ignore equip for locked slots
  silibs.enforce_gear_locks()

  -- Equip auto-reraise gear as appropriate
  equip(silibs.get_auto_reraise_gear())

  silibs.last_midcast_set = set_combine(gearswap.equip_list, {})
end

function silibs.aftercast(spell, action, spellMap, eventArgs)
  if silibs.custom_roll_timers_enabled then
    if spell.type == 'CorsairRoll' then
      -- Update timers
      if not spell.interrupted then
        if not silibs.is_doubling_up then -- First of a new roll
          -- Fix roll duration timer
          silibs.is_doubling_up = nil
          silibs.my_active_rolls[spell.status] = silibs.roll_info[spell.id]
          silibs.my_active_rolls[spell.status].value = spell.value
          silibs.my_active_rolls[spell.status].is_self = true
          silibs.set_double_up_timer()
        else -- Double-up
          if spell.value > 11 then -- Busted
            silibs.clear_roll_timer(silibs.my_active_rolls[spell.status])
            silibs.my_active_rolls[spell.status] = nil
            silibs.clear_double_up_timer()
          else -- Not busted double-up
            -- Clear current timer, allows new one to be created with the buff update packet
            silibs.clear_roll_timer(silibs.my_active_rolls[spell.status])

            local old_exp = silibs.my_active_rolls[spell.status] and silibs.my_active_rolls[spell.status].expiration or nil
            silibs.my_active_rolls[spell.status] = silibs.roll_info[spell.id]
            silibs.my_active_rolls[spell.status].value = spell.value
            silibs.my_active_rolls[spell.status].is_self = true
            silibs.my_active_rolls[spell.status].expiration = old_exp

            silibs.set_roll_timer(silibs.my_active_rolls[spell.status])
          end
        end
      else
        silibs.is_doubling_up = nil
      end
    end
  end
end

function silibs.post_aftercast(spell, action, spellMap, eventArgs)
  silibs.reset_midaction()

  -- Equip auto-reraise gear as appropriate
  equip(silibs.get_auto_reraise_gear())
end

function silibs.customize_idle(idleSet)
  return idleSet
end

function silibs.post_customize_idle(idleSet)
  -- Ignore equip for locked slots
  idleSet = silibs.enforce_gear_locks(idleSet)

  -- Equip auto-reraise gear as appropriate
  idleSet = set_combine(idleSet, silibs.get_auto_reraise_gear())

  return idleSet
end

function silibs.customize_melee(meleeSet)
  return meleeSet
end

function silibs.post_customize_melee(meleeSet)
  if silibs.th_enabled and state.TreasureMode.value ~= 'None' then
    local current_target = windower.ffxi.get_mob_by_target('t')
    local is_target_enemy = silibs.is_target_enemy(current_target)
    
    -- Equip TH gear if appropriate
    if state.TreasureMode.value == 'Fulltime'
      or (state.TreasureMode.value == 'SATA'
        and (state.Buff['Sneak Attack'] or state.Buff['Trick Attack'])
        and is_target_enemy)
      or ((state.TreasureMode.value == 'Tag' or state.TreasureMode.value == 'SATA')
        and is_target_enemy
        and not info.tagged_mobs[current_target.id])
    then
      -- If using RA, use RA TH set if it exists
      if player.equipment.range and player.equipment.range ~= 'empty' then
        if sets.TreasureHunter.RA then
          meleeSet = set_combine(meleeSet, sets.TreasureHunter.RA)
        end
      else
        if sets.TreasureHunter then
          meleeSet = set_combine(meleeSet, sets.TreasureHunter)
        end
      end
    end
  end

  -- Ignore equip for locked slots
  meleeSet = silibs.enforce_gear_locks(meleeSet)

  -- Equip auto-reraise gear as appropriate
  meleeSet = set_combine(meleeSet, silibs.get_auto_reraise_gear())

  return meleeSet
end

function silibs.customize_defense(defenseSet)
  return defenseSet
end

function silibs.post_customize_defense(defenseSet)
  -- Ignore equip for locked slots
  defenseSet = silibs.enforce_gear_locks(defenseSet)

  -- Equip auto-reraise gear as appropriate
  defenseSet = set_combine(defenseSet, silibs.get_auto_reraise_gear())

  return defenseSet
end


--=============================================================================
--=============================================================================
--=============================================================================
--                               Event hooks
--=============================================================================
--=============================================================================
--=============================================================================
-- Executes on every frame. This is just a way to create a perpetual loop.
silibs.timer1 = os.clock()
silibs.timer2 = os.clock()
silibs.timer3 = os.clock()
silibs.timer4 = os.clock()
windower.raw_register_event('prerender',function()
  local now = os.clock()

  if windower.ffxi.get_info().logged_in and windower.ffxi.get_player() then
    -- Every 0.25 seconds update Luopan UI
    if now - silibs.timer1 > 0.25 then
      silibs.timer1 = now
      if state.ShowLuopanUi.value then
        silibs.update_ui_luopan_distance_tracker()
      else
        silibs.ui.luopan:visible(false)
      end
    end

    -- Every 0.33 seconds, check to re-arm weapons
    if now - silibs.timer2 > 0.33 then
      silibs.timer2 = now
      if silibs.weapon_rearm_enabled then
        silibs.update_and_rearm_weapons()
      end
    end

    -- Every 0.5 seconds, check to re-arm gear or cancel Boost
    if now - silibs.timer3 > 0.5 then
      silibs.timer3 = now
      if silibs.equip_loop_enabled
          and os.time() - silibs.init_time > 3
          and not silibs.midaction()
          and not ((player.main_job == 'SMN'
            or player.main_job == 'BST'
            or player.main_job == 'PUP')
            and pet_midaction()) then
        send_command('gs c update')
      end

      if buffactive['Boost'] and player.tp == 3000 then
        send_command('cancel boost')
      end
    end

    -- Every 20 seconds clean TH tagged mob list
    if now - silibs.timer4 > 20 then
      silibs.timer4 = now
      if state.TreasureMode.value ~= 'None' then
        silibs.cleanup_tagged_mobs()
      end
    end

    -- Check if we've been stuck in midaction for a while, reset it because
    -- we're probably in an error state.
    if silibs.is_midaction and now > silibs.midaction_expected_finish_time then
      silibs.reset_midaction()
      send_command('gs c update')
    end
  end
end)

windower.raw_register_event('outgoing chunk', function(id, data, modified, injected, blocked)
  if id == 0x053 then -- Send lockstyle command to server
    local type = data:unpack('C', 0x05)
    if type == 0 then -- This is lockstyle 'disable' command
      silibs.locked_style = false
    else -- Various diff ways to set lockstyle
      silibs.locked_style = true
    end
  end
end)

windower.raw_register_event('incoming chunk', function(id, data, modified, injected, blocked)
  -- Set lockstyle again if it ever gets disabled due to action player did not initiate such as
  -- if an enemy force unequips your gear.
  if id == 0x009 then
    local is_lockstyle_enabled = data:unpack('C', 0x0B) == 11
    -- If incoming message is saying lockstyle is off but we're internally tracking that it is locked
    -- try to re-enable lockstyle. Checking both vars should help prevent re-enabling lockstyle when
    -- the player manually disabled it themselves.
    if not is_lockstyle_enabled and silibs.locked_style then
      silibs.locked_style = false
      silibs.set_lockstyle()
    end
  -- Set lockstyle again when encumbrance value changes (which disables lockstyle as a side effect)
  elseif id == 0x01B then -- Contains info about player's encumbrance status
    local encumbrance = data:unpack('I', 0x61)
    if encumbrance ~= silibs.encumbrance then
      silibs.encumbrance = encumbrance
      if silibs.locked_style then
        silibs.locked_style = false
        silibs.set_lockstyle()
      end
    end
  elseif id == 0x029 then
    -- Message IDs can be found here https://github.com/Windower/Lua/wiki/Message-IDs
    local p = packets.parse('incoming', data)
    if p.Message == 429 then -- roll already up
      silibs.reset_midaction()
      send_command('gs c update')
    end
  elseif id == 0x037 then
    -- Update clock offset; required for packet 0x063 to work properly
    silibs.parse_packet('0x037', data)
  elseif id == 0x063 then -- Set Update packet
    silibs.parse_buff_update_packet(data)
  end
  silibs.on_incoming_chunk_for_th(id, data, modified, injected, blocked)
end)

function silibs.parse_packet(packet_id, packet)
  if packet_id == '0x037' then
    -- Info provided by Akaden
    silibs.start_of_era = math.floor(os.time() - (((packet:unpack("I",0x41)*60 - packet:unpack("I",0x3D)) % 0x100000000) / 60))
  end
end

windower.raw_register_event('action', function(action)
  if action then
    silibs.on_action_for_th(action)
    silibs.on_action_for_rolls(action)
    silibs.on_action_for_flurry(action)
  end
end)

windower.raw_register_event('zone change', function(new_zone, old_zone)
  silibs.on_zone_change_for_th(new_zone, old_zone)
end)

windower.raw_register_event('incoming text', function(old, new, color)
  if silibs.custom_roll_text_enabled.show_self or silibs.custom_roll_text_enabled.show_others then
    if old then
      -- Hides Battlemod roll output
      if old:match('Roll.* The total.*') or old:match('.*Roll.*' .. string.char(0x81, 0xA8)) or old:match('.*uses Double.*The total') and color ~= 123 then
          return true
      end

      --Hides Vanilla roll output
      if old:match('.* receives the effect of .* Roll.') ~= nil then
          return true
      end
    end
  end

  return new, color
end)


--=============================================================================
--=============================================================================
--=============================================================================
--                            Deprecated Functions
--=============================================================================
--=============================================================================
--=============================================================================

-- DEPRECATED
function silibs.precast_hook(...)
end

-- DEPRECATED
function silibs.post_precast_hook(...)
end

-- DEPRECATED
function silibs.midcast_hook(...)
end

-- DEPRECATED
function silibs.post_midcast_hook(...)
end

-- DEPRECATED
function silibs.aftercast_hook(...)
end

-- DEPRECATED
function silibs.post_aftercast_hook(...)
end

-- DEPRECATED
function silibs.customize_idle_set(idleSet)
  return idleSet
end

-- DEPRECATED
function silibs.customize_melee_set(meleeSet)
  return meleeSet
end

-- DEPRECATED
function silibs.customize_defense_set(defenseSet)
  return defenseSet
end


--=============================================================================
--=============================================================================
--=============================================================================
--                        Execute Functions On Load
--=============================================================================
--=============================================================================
--=============================================================================
silibs.init_settings()
silibs.load_override_functions:schedule(1)
return silibs
