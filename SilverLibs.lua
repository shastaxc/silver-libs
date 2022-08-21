-- Version 2022.AUG.15.001
-- Copyright © 2021-2022, Shasta
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
-- DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
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

-------------------------------------------------------------------------------
-- Includes/imports
-------------------------------------------------------------------------------
res = include('resources')
packets = include('packets')


-------------------------------------------------------------------------------
-- One-off commands to execute on load
-------------------------------------------------------------------------------

-- Send request for player stats update
local packet = packets.new('outgoing', 0x061, {})
packets.inject(packet)

options = options or {}
state = state or {}
info = info or {}
info.tagged_mobs = T{}
state.TreasureMode = M{['description']='Treasure Mode'}


-------------------------------------------------------------------------------
-- Flags to enable/disable features and store user settings
-------------------------------------------------------------------------------
silibs.cancel_outranged_ws_enabled = false
silibs.cancel_on_blocking_status_enabled = false
silibs.weapon_rearm_enabled = false
silibs.auto_lockstyle_enabled = false
silibs.premade_commands_enabled = false
silibs.force_lower_cmd = false
silibs.th_enabled = false
silibs.th_aoe_disabled = false


-------------------------------------------------------------------------------
-- Instatiated variables for storing values and states
-------------------------------------------------------------------------------
-- Most recent weapons (used for re-arming)
silibs.most_recent_weapons = {main="empty",sub="empty",ranged="empty",ammo="empty"}
silibs.locked_style = false
silibs.lockstyle_set = 0
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
silibs.playerStats = {}
silibs.playerStats.Base = {}
silibs.playerStats.Bonus = {}
state.RearmingLock = M(false, 'Rearming Lock')
state.ShowLuopanUi = M(false, 'Show Luopan UI')
-- TH mode handling
if player.main_job == 'THF' then
    state.TreasureMode:options('None','Tag','SATA','Fulltime')
else
    state.TreasureMode:options('None','Tag')
end
silibs.th_aoe_actions = {
  weaponskills = {
    ["Aeolian Edge"] = {id=30,en="Aeolian Edge",ja="イオリアンエッジ",element=2,icon_id=595,prefix="/weaponskill",range=2,skill=2,skillchain_a="Impaction",skillchain_b="Scission",skillchain_c="Detonation",targets=32,aoe_range=10,aoe_center_self=false},
    ["Cyclone"] = {id=20,en="Cyclone",ja="サイクロン",element=2,icon_id=595,prefix="/weaponskill",range=10,skill=2,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32,aoe_range=10,aoe_center_self=false},
    ["Shockwave"] = {id=52,en="Shockwave",ja="ショックウェーブ",element=7,icon_id=604,prefix="/weaponskill",range=2,skill=4,skillchain_a="Reverberation",skillchain_b="",skillchain_c="",targets=32,aoe_range=10,aoe_center_self=false},
    ["Earth Crusher"] = {id=178,en="Earth Crusher",ja="アースクラッシャー",element=3,icon_id=632,prefix="/weaponskill",range=2,skill=12,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32,aoe_range=5,aoe_center_self=false},
    ["Cataclysm"] = {id=189,en="Cataclysm",ja="カタクリスム",element=7,icon_id=633,prefix="/weaponskill",range=2,skill=12,skillchain_a="Compression",skillchain_b="Reverberation",skillchain_c="",targets=32,aoe_range=10,aoe_center_self=false},
  },
  spells = {
    ["Diaga"] = {id=33,en="Diaga",ja="ディアガ",cast_time=1.5,element=6,icon_id=101,icon_id_nq=6,levels={[3]=18,[5]=15},mp_cost=12,prefix="/magic",range=12,recast=6,recast_id=33,requirements=0,skill=35,targets=32,type="WhiteMagic",aoe_range=10,aoe_center_self=false},
    ["Banishga"] = {id=38,en="Banishga",ja="バニシュガ",cast_time=2.75,element=6,icon_id=112,icon_id_nq=6,levels={[3]=15,[7]=30},mp_cost=41,prefix="/magic",range=12,recast=15,recast_id=38,requirements=0,skill=32,targets=32,type="WhiteMagic",aoe_range=10,aoe_center_self=false},
    ["Firaga"] = {id=174,en="Firaga",ja="ファイガ",cast_time=2,element=0,icon_id=245,icon_id_nq=8,levels={[4]=28},mp_cost=57,prefix="/magic",range=12,recast=5,recast_id=174,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
    ["Blizzaga"] = {id=179,en="Blizzaga",ja="ブリザガ",cast_time=2,element=1,icon_id=274,icon_id_nq=9,levels={[4]=32},mp_cost=80,prefix="/magic",range=12,recast=5,recast_id=179,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
    ["Aeroga"] = {id=184,en="Aeroga",ja="エアロガ",cast_time=2,element=2,icon_id=285,icon_id_nq=10,levels={[4]=23},mp_cost=45,prefix="/magic",range=12,recast=5,recast_id=184,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
    ["Stonega"] = {id=189,en="Stonega",ja="ストンガ",cast_time=2,element=3,icon_id=215,icon_id_nq=11,levels={[4]=15},mp_cost=24,prefix="/magic",range=12,recast=5,recast_id=189,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
    ["Thundaga"] = {id=194,en="Thundaga",ja="サンダガ",cast_time=2,element=4,icon_id=265,icon_id_nq=12,levels={[4]=36},mp_cost=105,prefix="/magic",range=12,recast=5,recast_id=194,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
    ["Waterga"] = {id=199,en="Waterga",ja="ウォタガ",cast_time=2,element=5,icon_id=254,icon_id_nq=13,levels={[4]=19},mp_cost=34,prefix="/magic",range=12,recast=5,recast_id=199,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
    ["Poisonga"] = {id=225,en="Poisonga",ja="ポイゾガ",cast_time=2,element=5,icon_id=228,icon_id_nq=13,levels={[4]=24,[8]=26},mp_cost=44,prefix="/magic",range=12,recast=10,recast_id=225,requirements=0,skill=35,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
    ["Venom Shell"] = {id=513,en="Venom Shell",ja="ベノムシェル",blu_points=3,cast_time=3,element=5,icon_id=-1,icon_id_nq=61,levels={[16]=42},mp_cost=86,prefix="/magic",range=4,recast=45,recast_id=513,requirements=0,skill=43,status=41,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
    ["Mysterious Light"] = {id=534,en="Mysterious Light",ja="神秘の光",blu_points=4,cast_time=3.75,element=2,icon_id=-1,icon_id_nq=58,levels={[16]=40},mp_cost=73,prefix="/magic",range=4,recast=24.5,recast_id=534,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
    ["Stinking Gas"] = {id=537,en="Stinking Gas",ja="スティンキングガス",blu_points=2,cast_time=4,element=2,icon_id=-1,icon_id_nq=58,levels={[16]=44},mp_cost=37,prefix="/magic",range=4,recast=60,recast_id=537,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
    ["Blood Saber"] = {id=541,en="Blood Saber",ja="ブラッドセイバー",blu_points=2,cast_time=4,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=48},mp_cost=25,prefix="/magic",range=4,recast=26,recast_id=541,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
    ["Cursed Sphere"] = {id=544,en="Cursed Sphere",ja="カースドスフィア",blu_points=2,cast_time=3,element=5,icon_id=-1,icon_id_nq=61,levels={[16]=18},mp_cost=36,prefix="/magic",range=9,recast=19.5,recast_id=544,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=false},
    ["Sound Blast"] = {id=572,en="Sound Blast",ja="サウンドブラスト",blu_points=1,cast_time=4,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=32},mp_cost=25,prefix="/magic",range=4,recast=30,recast_id=572,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
    ["Sheep Song"] = {id=584,en="Sheep Song",ja="シープソング",blu_points=2,cast_time=3,duration=60,element=6,icon_id=-1,icon_id_nq=62,levels={[16]=16},mp_cost=22,prefix="/magic",range=4,recast=60,recast_id=584,requirements=0,skill=43,status=2,targets=32,type="BlueMagic",aoe_range=4.97,aoe_center_self=true},
    ["Soporific"] = {id=598,en="Soporific",ja="サペリフィック",blu_points=4,cast_time=3,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=24},mp_cost=38,prefix="/magic",range=4,recast=26,recast_id=598,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=4.97,aoe_center_self=true},
    ["Geist Wall"] = {id=605,en="Geist Wall",ja="ガイストウォール",blu_points=3,cast_time=3,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=46},mp_cost=35,prefix="/magic",range=4,recast=30,recast_id=605,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=4.97,aoe_center_self=true},
    ["Blastbomb"] = {id=618,en="Blastbomb",ja="炸裂弾",blu_points=2,cast_time=2.25,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=18},mp_cost=36,prefix="/magic",range=9,recast=15,recast_id=618,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=false},
    ["Battledance"] = {id=620,en="Battle Dance",ja="バトルダンス",blu_points=3,cast_time=1,element=15,icon_id=-1,icon_id_nq=64,levels={[16]=12},mp_cost=12,prefix="/magic",range=4,recast=10,recast_id=620,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
    ["Grand Slam"] = {id=622,en="Grand Slam",ja="グランドスラム",blu_points=2,cast_time=1,element=15,icon_id=-1,icon_id_nq=64,levels={[16]=30},mp_cost=24,prefix="/magic",range=4,recast=14.25,recast_id=622,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
    ["Bomb Toss"] = {id=626,en="Bomb Toss",ja="爆弾投げ",blu_points=3,cast_time=3.75,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=28},mp_cost=42,prefix="/magic",range=9,recast=24.5,recast_id=626,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=false},
    ["Fira"] = {id=828,en="Fira",ja="ファイラ",cast_time=1.5,element=0,icon_id=245,icon_id_nq=8,levels={[21]=40},mp_cost=93,prefix="/magic",range=8,recast=5,recast_id=828,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
    ["Blizzara"] = {id=830,en="Blizzara",ja="ブリザラ",cast_time=1.5,element=1,icon_id=274,icon_id_nq=9,levels={[21]=45},mp_cost=108,prefix="/magic",range=8,recast=5,recast_id=830,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
    ["Aera"] = {id=832,en="Aera",ja="エアロラ",cast_time=1.5,element=2,icon_id=285,icon_id_nq=10,levels={[21]=35},mp_cost=79,prefix="/magic",range=8,recast=5,recast_id=832,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
    ["Stonera"] = {id=834,en="Stonera",ja="ストンラ",cast_time=1.5,element=3,icon_id=215,icon_id_nq=11,levels={[21]=25},mp_cost=54,prefix="/magic",range=8,recast=5,recast_id=834,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
    ["Thundara"] = {id=836,en="Thundara",ja="サンダラ",cast_time=1.5,element=4,icon_id=265,icon_id_nq=12,levels={[21]=50},mp_cost=123,prefix="/magic",range=8,recast=5,recast_id=836,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
    ["Watera"] = {id=838,en="Watera",ja="ウォタラ",cast_time=1.5,element=5,icon_id=254,icon_id_nq=13,levels={[21]=30},mp_cost=66,prefix="/magic",range=8,recast=5,recast_id=838,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
  },
  abilities = {}
}

silibs.last_indi = nil
silibs.last_geo = nil

silibs.ui = {}
--Luopan Distance Tracking
silibs.ui.luopan = texts.new('${value}', {
  pos = { x=0, y=50, },
  text = { font='Arial', size=12, },
  flags = { right=false, bold=true, },
  bg = { alpha=0, },
  stroke = { width=2, alpha=192 },
})


-------------------------------------------------------------------------------
-- Constants and maps
-------------------------------------------------------------------------------
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

silibs.action_type_blockers = {
  ['Magic'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'silence', 'mute', 'Omerta'},
  ['Ranged Attack'] = {'terror', 'petrification', 'stun', 'sleep', 'charm'},
  ['Ability'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'amnesia', 'impairment'},
  ['Item'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'muddle'},
  ['Monster Move'] = {'terror', 'petrification', 'stun', 'sleep', 'charm', 'amnesia'},
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

silibs.ui.bt_color = '\\cs(230,118,116)'

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


-------------------------------------------------------------------------------
-- Fix Mote's mistakes
-------------------------------------------------------------------------------

-- Overwrite Mote's implementation of setting elemental gear (it's outdated)
function set_elemental_gear(spell)
end


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

function silibs.init_settings()
  silibs.cancel_outranged_ws_enabled = false
  silibs.cancel_on_blocking_status_enabled = false
  silibs.weapon_rearm_enabled = false
  silibs.auto_lockstyle_enabled = false
  silibs.premade_commands_enabled = false
  silibs.force_lower_cmd = false
  silibs.th_enabled = false
  silibs.th_aoe_disabled = false

  silibs.most_recent_weapons = {main="",sub="",ranged="",ammo=""}
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
  state.RearmingLock = M(false, 'Rearming Lock')
  state.ShowLuopanUi = M(false, 'Show Luopan UI')

  -- TH mode handling
  if player.main_job == 'THF' then
      state.TreasureMode:options('None','Tag','SATA','Fulltime')
  else
      state.TreasureMode:options('None','Tag')
  end
  silibs.th_aoe_actions = {
    weaponskills = {
      ["Aeolian Edge"] = {id=30,en="Aeolian Edge",ja="イオリアンエッジ",element=2,icon_id=595,prefix="/weaponskill",range=2,skill=2,skillchain_a="Impaction",skillchain_b="Scission",skillchain_c="Detonation",targets=32,aoe_range=10,aoe_center_self=false},
      ["Cyclone"] = {id=20,en="Cyclone",ja="サイクロン",element=2,icon_id=595,prefix="/weaponskill",range=10,skill=2,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32,aoe_range=10,aoe_center_self=false},
      ["Shockwave"] = {id=52,en="Shockwave",ja="ショックウェーブ",element=7,icon_id=604,prefix="/weaponskill",range=2,skill=4,skillchain_a="Reverberation",skillchain_b="",skillchain_c="",targets=32,aoe_range=10,aoe_center_self=false},
      ["Earth Crusher"] = {id=178,en="Earth Crusher",ja="アースクラッシャー",element=3,icon_id=632,prefix="/weaponskill",range=2,skill=12,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32,aoe_range=5,aoe_center_self=false},
      ["Cataclysm"] = {id=189,en="Cataclysm",ja="カタクリスム",element=7,icon_id=633,prefix="/weaponskill",range=2,skill=12,skillchain_a="Compression",skillchain_b="Reverberation",skillchain_c="",targets=32,aoe_range=10,aoe_center_self=false},
    },
    spells = {
      ["Diaga"] = {id=33,en="Diaga",ja="ディアガ",cast_time=1.5,element=6,icon_id=101,icon_id_nq=6,levels={[3]=18,[5]=15},mp_cost=12,prefix="/magic",range=12,recast=6,recast_id=33,requirements=0,skill=35,targets=32,type="WhiteMagic",aoe_range=10,aoe_center_self=false},
      ["Banishga"] = {id=38,en="Banishga",ja="バニシュガ",cast_time=2.75,element=6,icon_id=112,icon_id_nq=6,levels={[3]=15,[7]=30},mp_cost=41,prefix="/magic",range=12,recast=15,recast_id=38,requirements=0,skill=32,targets=32,type="WhiteMagic",aoe_range=10,aoe_center_self=false},
      ["Firaga"] = {id=174,en="Firaga",ja="ファイガ",cast_time=2,element=0,icon_id=245,icon_id_nq=8,levels={[4]=28},mp_cost=57,prefix="/magic",range=12,recast=5,recast_id=174,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
      ["Blizzaga"] = {id=179,en="Blizzaga",ja="ブリザガ",cast_time=2,element=1,icon_id=274,icon_id_nq=9,levels={[4]=32},mp_cost=80,prefix="/magic",range=12,recast=5,recast_id=179,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
      ["Aeroga"] = {id=184,en="Aeroga",ja="エアロガ",cast_time=2,element=2,icon_id=285,icon_id_nq=10,levels={[4]=23},mp_cost=45,prefix="/magic",range=12,recast=5,recast_id=184,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
      ["Stonega"] = {id=189,en="Stonega",ja="ストンガ",cast_time=2,element=3,icon_id=215,icon_id_nq=11,levels={[4]=15},mp_cost=24,prefix="/magic",range=12,recast=5,recast_id=189,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
      ["Thundaga"] = {id=194,en="Thundaga",ja="サンダガ",cast_time=2,element=4,icon_id=265,icon_id_nq=12,levels={[4]=36},mp_cost=105,prefix="/magic",range=12,recast=5,recast_id=194,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
      ["Waterga"] = {id=199,en="Waterga",ja="ウォタガ",cast_time=2,element=5,icon_id=254,icon_id_nq=13,levels={[4]=19},mp_cost=34,prefix="/magic",range=12,recast=5,recast_id=199,requirements=0,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
      ["Poisonga"] = {id=225,en="Poisonga",ja="ポイゾガ",cast_time=2,element=5,icon_id=228,icon_id_nq=13,levels={[4]=24,[8]=26},mp_cost=44,prefix="/magic",range=12,recast=10,recast_id=225,requirements=0,skill=35,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=false},
      ["Venom Shell"] = {id=513,en="Venom Shell",ja="ベノムシェル",blu_points=3,cast_time=3,element=5,icon_id=-1,icon_id_nq=61,levels={[16]=42},mp_cost=86,prefix="/magic",range=4,recast=45,recast_id=513,requirements=0,skill=43,status=41,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
      ["Mysterious Light"] = {id=534,en="Mysterious Light",ja="神秘の光",blu_points=4,cast_time=3.75,element=2,icon_id=-1,icon_id_nq=58,levels={[16]=40},mp_cost=73,prefix="/magic",range=4,recast=24.5,recast_id=534,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
      ["Stinking Gas"] = {id=537,en="Stinking Gas",ja="スティンキングガス",blu_points=2,cast_time=4,element=2,icon_id=-1,icon_id_nq=58,levels={[16]=44},mp_cost=37,prefix="/magic",range=4,recast=60,recast_id=537,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
      ["Blood Saber"] = {id=541,en="Blood Saber",ja="ブラッドセイバー",blu_points=2,cast_time=4,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=48},mp_cost=25,prefix="/magic",range=4,recast=26,recast_id=541,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
      ["Cursed Sphere"] = {id=544,en="Cursed Sphere",ja="カースドスフィア",blu_points=2,cast_time=3,element=5,icon_id=-1,icon_id_nq=61,levels={[16]=18},mp_cost=36,prefix="/magic",range=9,recast=19.5,recast_id=544,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=false},
      ["Sound Blast"] = {id=572,en="Sound Blast",ja="サウンドブラスト",blu_points=1,cast_time=4,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=32},mp_cost=25,prefix="/magic",range=4,recast=30,recast_id=572,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
      ["Sheep Song"] = {id=584,en="Sheep Song",ja="シープソング",blu_points=2,cast_time=3,duration=60,element=6,icon_id=-1,icon_id_nq=62,levels={[16]=16},mp_cost=22,prefix="/magic",range=4,recast=60,recast_id=584,requirements=0,skill=43,status=2,targets=32,type="BlueMagic",aoe_range=4.97,aoe_center_self=true},
      ["Soporific"] = {id=598,en="Soporific",ja="サペリフィック",blu_points=4,cast_time=3,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=24},mp_cost=38,prefix="/magic",range=4,recast=26,recast_id=598,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=4.97,aoe_center_self=true},
      ["Geist Wall"] = {id=605,en="Geist Wall",ja="ガイストウォール",blu_points=3,cast_time=3,element=7,icon_id=-1,icon_id_nq=63,levels={[16]=46},mp_cost=35,prefix="/magic",range=4,recast=30,recast_id=605,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=4.97,aoe_center_self=true},
      ["Blastbomb"] = {id=618,en="Blastbomb",ja="炸裂弾",blu_points=2,cast_time=2.25,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=18},mp_cost=36,prefix="/magic",range=9,recast=15,recast_id=618,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=false},
      ["Battledance"] = {id=620,en="Battle Dance",ja="バトルダンス",blu_points=3,cast_time=1,element=15,icon_id=-1,icon_id_nq=64,levels={[16]=12},mp_cost=12,prefix="/magic",range=4,recast=10,recast_id=620,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
      ["Grand Slam"] = {id=622,en="Grand Slam",ja="グランドスラム",blu_points=2,cast_time=1,element=15,icon_id=-1,icon_id_nq=64,levels={[16]=30},mp_cost=24,prefix="/magic",range=4,recast=14.25,recast_id=622,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=true},
      ["Bomb Toss"] = {id=626,en="Bomb Toss",ja="爆弾投げ",blu_points=3,cast_time=3.75,element=0,icon_id=-1,icon_id_nq=56,levels={[16]=28},mp_cost=42,prefix="/magic",range=9,recast=24.5,recast_id=626,requirements=0,skill=43,targets=32,type="BlueMagic",aoe_range=5,aoe_center_self=false},
      ["Fira"] = {id=828,en="Fira",ja="ファイラ",cast_time=1.5,element=0,icon_id=245,icon_id_nq=8,levels={[21]=40},mp_cost=93,prefix="/magic",range=8,recast=5,recast_id=828,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
      ["Blizzara"] = {id=830,en="Blizzara",ja="ブリザラ",cast_time=1.5,element=1,icon_id=274,icon_id_nq=9,levels={[21]=45},mp_cost=108,prefix="/magic",range=8,recast=5,recast_id=830,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
      ["Aera"] = {id=832,en="Aera",ja="エアロラ",cast_time=1.5,element=2,icon_id=285,icon_id_nq=10,levels={[21]=35},mp_cost=79,prefix="/magic",range=8,recast=5,recast_id=832,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
      ["Stonera"] = {id=834,en="Stonera",ja="ストンラ",cast_time=1.5,element=3,icon_id=215,icon_id_nq=11,levels={[21]=25},mp_cost=54,prefix="/magic",range=8,recast=5,recast_id=834,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
      ["Thundara"] = {id=836,en="Thundara",ja="サンダラ",cast_time=1.5,element=4,icon_id=265,icon_id_nq=12,levels={[21]=50},mp_cost=123,prefix="/magic",range=8,recast=5,recast_id=836,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
      ["Watera"] = {id=838,en="Watera",ja="ウォタラ",cast_time=1.5,element=5,icon_id=254,icon_id_nq=13,levels={[21]=30},mp_cost=66,prefix="/magic",range=8,recast=5,recast_id=838,requirements=64,skill=36,targets=32,type="BlackMagic",aoe_range=10,aoe_center_self=true},
    },
    abilities = {}
  }
  
  silibs.last_indi = nil
  silibs.last_geo = nil

  silibs.ui = {}
  --Luopan Distance Tracking
  silibs.ui.luopan = texts.new('${value}', {
    pos = { x=0, y=50, },
    text = { font='Arial', size=12, },
    flags = { right=false, bold=true, },
    bg = { alpha=0, },
    stroke = { width=2, alpha=192 },
  })

end

-- 'ws_range' expected to be the range pulled from weapon_skills.lua
-- 's' is self player object
-- 't' is target object
function silibs.is_ws_out_of_range(ws_range, s, t)
  if ws_range == nil or s == nil or t == nil then
    print('Invalid params for is_ws_out_of_range.')
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
  if spell.type ~= "WeaponSkill" then
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
  local forbidden_statuses = silibs.action_type_blockers[spell.action_type]
  for k,status in pairs(forbidden_statuses) do
    if buffactive[status] then
      windower.add_to_chat(167, 'Stopped due to status.')
      eventArgs.cancel = true -- Ensures gear doesn't swap
      return -- Ends function without finishing loop
    end
  end
end

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
        return true
      end
    end
  end
  
  return false
end

-- Saves the state of your weapons
-- Re-arms your weapons when conditions are met
-- Can be temporarily disabled by adding a toggled rearming lock state:
--    state.RearmingLock = M(false, 'Rearming Lock')
-- Which can be turned off or off with a keybind
--    send_command('bind @w gs c toggle RearmingLock')
function silibs.update_and_rearm_weapons()
  -- Save state of any equipped weapons
  if player.equipment.main ~= "empty" and player.equipment.main ~= nil then
    if not is_encumbered('main') then
      silibs.most_recent_weapons.main = player.equipment.main
    end
    if not is_encumbered('sub') then
      silibs.most_recent_weapons.sub = player.equipment.sub
    end
  end
  if player.equipment.ammo == "empty" or player.equipment.ammo == nil then
    if player.equipment.ranged ~= "empty" and player.equipment.ranged ~= nil then
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
    if player.equipment.ranged ~= "empty" and player.equipment.ranged ~= nil then
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
  -- Table fills the string "empty" for empty slot. It won't return nil
  -- Must check if sub is also empty (and weapon) because if main hand is removed while dual wielding, the sub stays on for
  -- 1 cycle longer which will result in the main hand re-equipping but not the sub
  -- Also, if the sub is a shield, it will stay on even if main hand is removed.
  local is_sub_armor
  if player.equipment.sub and player.equipment.sub ~= 'empty' then
    is_sub_armor = res.items:with('en', player.equipment.sub).category == 'Armor'
  else
    is_sub_armor = false
  end
  if ((player.equipment.main == "empty" and silibs.most_recent_weapons.main ~= "empty" and player.equipment.sub == "empty")
      or (player.equipment.main == "empty" and silibs.most_recent_weapons.main ~= "empty" and is_sub_armor)
      or (player.equipment.ranged == "empty" and silibs.most_recent_weapons.ranged ~= "empty"))
      and (state.RearmingLock == nil or state.RearmingLock.value == false) then
    equip(silibs.most_recent_weapons)
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
  if silibs.premade_commands_enabled  then
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
    elseif lowerCmdParams[1] == 'usekey' or lowerCmdParams[1] == 'noinvis' then
      send_command('cancel Invisible; cancel Hide; cancel Gestation; cancel Camouflage')
      if lowerCmdParams[1] == 'usekey' then
        silibs.use_key()
      end
      eventArgs.handled = true
    elseif lowerCmdParams[1] == 'faceaway' then
      windower.ffxi.turn(player.facing - math.pi);
      eventArgs.handled = true
    end
    if silibs.force_lower_cmd then
      cmdParams = lowerCmdParams
    end
  end
end

function silibs.use_sneak()
  local cmd
  -- If access to a spell or job ability (or multiples), attempt to use that (or those) first
  -- If JA not available, attempt to use spells that consume MP
  -- If those not available, attempt to use spells that consume items
  -- If those not available, attempt to use items
  if not cmd
    and silibs.can_access_ability("Spectral Jig")
    and silibs.can_recast_ability("Spectral Jig") then
    cmd = 'input /ja "Spectral Jig" <me>'
  end
  if not cmd
    and silibs.can_access_spell("Sneak") then
      cmd = 'input /ma "Sneak" <stpc>'
  end
  if not cmd
    and silibs.can_access_spell("Monomi: Ichi")
    and silibs.can_recast_spell("Monomi: Ichi", 5)
    and silibs.has_item('Sanjaku-Tenugui', L{'inventory'}) then
      cmd = 'input /ma "Monomi: Ichi" <me>'
  end
  if not cmd and silibs.has_item('Silent Oil', L{'inventory'}) then
    cmd = 'input /item "Silent Oil" <me>'
  end

  send_command(cmd)
end

function silibs.use_invisible()
  local cmd
  -- If access to a spell or job ability (or multiples), attempt to use that (or those) first
  -- If JA not available, attempt to use spells that consume MP
  -- If those not available, attempt to use spells that consume items
  -- If those not available, attempt to use items
  if not cmd
    and silibs.can_access_ability("Spectral Jig")
    and silibs.can_recast_ability("Spectral Jig") then
    cmd = 'input /ja "Spectral Jig" <me>'
  end
  if not cmd
    and silibs.can_access_spell("Invisible") then
      cmd = 'input /ma "Invisible" <stpc>'
  end
  if not cmd
    and silibs.can_access_spell("Tonko: Ni")
    and silibs.can_recast_spell("Tonko: Ni")
    and silibs.has_item('Shinobi-Tabi', L{'inventory'}) then
      cmd = 'input /ma "Tonko: Ni" <me>'
  end
  if not cmd
    and silibs.can_access_spell("Tonko: Ichi")
    and silibs.can_recast_spell("Tonko: Ichi")
    and silibs.has_item('Shinobi-Tabi', L{'inventory'}) then
      cmd = 'input /ma "Tonko: Ichi" <me>'
  end
  if not cmd and silibs.has_item('Prism Powder', L{'inventory'}) then
    cmd = 'input /item "Prism Powder" <me>'
  end

  send_command(cmd)
end

function silibs.use_key()
  if player.target.type ~= 'NONE' then
    if player.target.name == 'Sturdy Pyxis' then
      send_command('@input /item "Forbidden Key" <t>')
    elseif player.main_job == 'THF' then
      if silibs.has_item('Skeleton Key', L{'inventory'}) then
        send_command('@input /item "Skeleton Key" <t>')
      elseif silibs.has_item('Living Key', L{'inventory'}) then
        send_command('@input /item "Living Key" <t>')
      elseif silibs.has_item('Thief\'s Tools', L{'inventory'}) then
        send_command('@input /item "Thief\'s Tools" <t>')
      end
    end
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
  if spell.english == "Healing Waltz" or spell.english == "Divine Waltz" or spell.english == "Divine Waltz II" then
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
  if spell.target.type == "SELF" then
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
          info.tagged_mobs[target.id] = os.time()
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
            info.tagged_mobs[target.id] = os.time()
          end
        end
      end
    -- If mob acts, keep an update of last action time for TH bookkeeping
    elseif info.tagged_mobs[action.actor_id] then
      info.tagged_mobs[action.actor_id] = os.time()
    -- If anyone else acts, check if any of the targets are our tagged mobs
    else
      for index,target in pairs(action.targets) do
        if info.tagged_mobs[target.id] then
          info.tagged_mobs[target.id] = os.time()
        end
      end
    end
  end
end

-- Remove mobs that we've marked as tagged with TH if we haven't seen any activity from or on them
-- for over 3 minutes.  This is to handle deagros, player deaths, or other random stuff where the
-- mob is lost, but doesn't die.
function silibs.cleanup_tagged_mobs()
  local current_time = os.time()
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
  if id == 0x29 then
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


-------------------------------------------------------------------------------
-- Helpful/Supporting functions
-------------------------------------------------------------------------------
function silibs.update_ui(frame_count)
  if frame_count%15 == 0 then
    if state.ShowLuopanUi.value then
      update_ui_luopan_distance_tracker()
    end
  end
end

function update_ui_luopan_distance_tracker()
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
      if dist_between < (6 + v.model_size) and not (v.status == 2 or v.status == 3) and v.name and v.name ~= '' and v.name ~= "Luopan" and v.valid_target and v.model_size > 0 then
        if silibs.geo_debuffs:contains(silibs.last_geo) then
          if v.is_npc and not (v.in_party or silibs.luopan_ignore_list:contains(v.name)) then
            if battle_target and battle_target.id == v.id then
              luopan_txtbox = luopan_txtbox..' '..silibs.ui.bt_color..v.name.." "..string.format("%.2f",dist_between).."\\cs(255,255,255)\n"
            else
              luopan_txtbox = luopan_txtbox..' '..v.name.." "..string.format("%.2f",dist_between).."\n"
            end
            geo_count = geo_count + 1
          end
        elseif v.in_party then
          luopan_txtbox = luopan_txtbox..' '..v.name.." "..string.format("%.2f",dist_between).."\n"
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
      if dist_between < (6 + v.model_size) and (v.status == 1 or v.status == 0) and v.name and v.name ~= '' and v.name ~= "Luopan" and v.name ~= s.name and v.valid_target and v.model_size > 0 then
        if silibs.geo_debuffs:contains(silibs.last_indi) then
          if v.is_npc and not (v.in_party or silibs.luopan_ignore_list:contains(v.name)) then
            if battle_target and battle_target.id == v.id then
              luopan_txtbox = luopan_txtbox..' '..silibs.ui.bt_color..v.name.." "..string.format("%.2f",dist_between).."\\cs(255,255,255)\n"
            else
              luopan_txtbox = luopan_txtbox..' '..v.name.." "..string.format("%.2f",dist_between).."\n"
            end
            indi_count = indi_count + 1
          end
        else
          if v.in_party then
            luopan_txtbox = luopan_txtbox..' '..v.name.." "..string.format("%.2f",dist_between).."\n"
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

function silibs.find_ability(ability_name)
  return res.job_abilities:find(function(ability)
    return ability.en == ability_name
  end)
end

function silibs.find_spell(spell_name)
  return res.spells:find(function(s)
    return s.en == spell_name
  end)
end

function silibs.can_access_ability(ability_name)
  local ability_ids = S(windower.ffxi.get_abilities().job_abilities)
  return ability_ids:contains(silibs.find_ability(ability_name))
end

function silibs.can_access_spell(spell_name)
  local _, spell = silibs.find_spell(spell_name)
  local has_learned_spell = windower.ffxi.get_spells()[spell.id] ~= nil
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
  local _, ability = silibs.find_ability(ability_name)
  return windower.ffxi.get_ability_recasts()[ability.recast_id] <= time
end

function silibs.can_recast_spell(spell_name, time)
  time = time or 1
  local _, spell = silibs.find_spell(spell_name)
  return windower.ffxi.get_spell_recasts()[spell.recast_id] <= time
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

  -- Get stats (these are not 100% up-to-date, has about 1-2 seconds lag)
  local base_chr = silibs.playerStats["Base"]["CHR"] or silibs.waltz_stats.base_chr
  local base_vit = silibs.playerStats["Base"]["VIT"] or silibs.waltz_stats.base_vit
  local bonus_chr = silibs.playerStats["Bonus"]["CHR"] or silibs.waltz_stats.bonus_chr
  local bonus_vit = silibs.playerStats["Bonus"]["VIT"] or silibs.waltz_stats.bonus_vit

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
  elseif (spell_element == elements.weak_to[day_element]) then
    day_align = -1
  end

  -- Get current weather
  local weather_element = world.weather_element
  -- Find weather alignment vs spell used
  local weather_align = 0
  -- Same element = positive alignment, 
  if (spell_element == weather_element) then
    weather_align = 1
  elseif (spell_element == elements.weak_to[weather_element]) then
    weather_align = -1
  end
  -- Double weather = x2 bonus
  weather_align = weather_align * get_weather_intensity()

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
-- Assumes that the given spell is an elemental WS.
-- +15% dmg less than 1.93', +1% dmg > 13', scale linearly between 1.93' and 13'.
-- Also includes base weather/day bonuses based on proc chance.
function silibs.get_orpheus_multiplier(spell_element, distance)
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
    distance_bn = 15
  end

  -- Convert bonus (percentage) into multiplier (decimal)
  local multiplier = (1 + (distance_bn / 100)) * silibs.get_day_weather_multiplier(spell_element, false, false)
  return multiplier
end

-- Check for proper ammo when shooting or weaponskilling
function silibs.equip_ammo(spell)
  -- If throwing weapon, return empty as ammo
  if player.equipment.range and player.equipment.range ~= 'empty' then
    local weapon_stats = res.items:with('en', player.equipment.range)
    if weapon_stats.skill == 27 then
      equip({ammo='empty'})
      return
    end
  end

  local swapped_ammo = nil
  local default_ammo
  local magic_ammo
  local acc_ammo
  local ws_ammo
  if player.main_job == 'RNG' or player.main_job == 'THF' then
    default_ammo = player.equipment.range and DefaultAmmo[player.equipment.range]
    magic_ammo = player.equipment.range and MagicAmmo[player.equipment.range]
    acc_ammo = player.equipment.range and AccAmmo[player.equipment.range]
    ws_ammo = player.equipment.range and WSAmmo[player.equipment.range]
    qd_ammo = 'empty'
  elseif player.main_job == 'COR' then
    default_ammo = gear.RAbullet
    magic_ammo = gear.MAbullet
    acc_ammo = gear.RAccbullet
    ws_ammo = gear.WSbullet
    qd_ammo = gear.QDbullet
  end

  if spell.action_type == 'Ranged Attack' then
    -- If in ranged acc mode, use acc bullet (fall back to default bullet if out of acc ammo)
    if state.RangedMode.value ~= 'Normal' then
      if acc_ammo and silibs.has_item(acc_ammo, silibs.equippable_bags) then
        swapped_ammo = acc_ammo
        equip({ammo=swapped_ammo})
      elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
        -- Fall back to default ammo, if there is any
        swapped_ammo = default_ammo
        equip({ammo=swapped_ammo})
        add_to_chat(3,"Acc ammo unavailable. Falling back to default ammo.")
      else
        -- If neither is available, empty the ammo slot
        swapped_ammo = empty
        equip({ammo=swapped_ammo})
        cancel_spell()
        add_to_chat(123, '** Action Canceled: [ Acc & default ammo unavailable. ] **')
        return
      end
    elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
      equip({ammo=swapped_ammo})
    else
      swapped_ammo = empty
      equip({ammo=swapped_ammo})
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ Default ammo unavailable. ] **')
      return
    end
  elseif spell.type == 'WeaponSkill' then
    -- Ranged WS
    if spell.skill == 'Marksmanship' or spell.skill == 'Archery' then
      -- ranged magical weaponskills
      if elemental_ws:contains(spell.english) then
        if magic_ammo and silibs.has_item(magic_ammo, silibs.equippable_bags) then
          swapped_ammo = magic_ammo
          equip({ammo=swapped_ammo})
        elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
          swapped_ammo = default_ammo
          equip({ammo=swapped_ammo})
          add_to_chat(3,"Magic ammo unavailable. Using default ammo.")
        else
          swapped_ammo = empty
          equip({ammo=swapped_ammo})
          cancel_spell()
          add_to_chat(123, '** Action Canceled: [ Magic & default ammo unavailable. ] **')
          return
        end
      else -- ranged physical weaponskills
        if state.RangedMode.value ~= 'Normal' then
          if acc_ammo and silibs.has_item(acc_ammo, silibs.equippable_bags) then
            swapped_ammo = acc_ammo
            equip({ammo=swapped_ammo})
          elseif ws_ammo and silibs.has_item(ws_ammo, silibs.equippable_bags) then
            swapped_ammo = ws_ammo
            equip({ammo=swapped_ammo})
            add_to_chat(3,"Acc ammo unavailable. Using WS ammo.")
          elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            equip({ammo=swapped_ammo})
            add_to_chat(3,"Acc & WS ammo unavailable. Using default ammo.")
          else
            swapped_ammo = empty
            equip({ammo=swapped_ammo})
            cancel_spell()
            add_to_chat(123, '** Action Canceled: [ Acc, WS, & default ammo unavailable. ] **')
            return
          end
        else
          if ws_ammo and silibs.has_item(ws_ammo, silibs.equippable_bags) then
            swapped_ammo = ws_ammo
            equip({ammo=swapped_ammo})
          elseif silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            equip({ammo=swapped_ammo})
            add_to_chat(3,"WS ammo unavailable. Using default ammo.")
          else
            swapped_ammo = empty
            equip({ammo=swapped_ammo})
            cancel_spell()
            add_to_chat(123, '** Action Canceled: [ WS & default ammo unavailable. ] **')
            return
          end
        end
      end
    else -- Melee WS
      -- melee magical weaponskills
      if elemental_ws:contains(spell.english) then
        -- If ranged weapon is accipiter/sparrowhawk and using non-ranged WS, equip WSD ammo
        local rweapon = player.equipment.range
        if rweapon and rweapon == 'Accipiter' or (rweapon:length() >= 11 and rweapon:startswith('Sparrowhawk'))
            and silibs.has_item('Hauksbok Arrow', silibs.equippable_bags) then
          swapped_ammo = 'Hauksbok Arrow'
          equip({ammo=swapped_ammo})
        elseif magic_ammo and silibs.has_item(magic_ammo, silibs.equippable_bags) then
          swapped_ammo = magic_ammo
          equip({ammo=swapped_ammo})
        elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
          swapped_ammo = default_ammo
          equip({ammo=swapped_ammo})
          add_to_chat(3,"Magic ammo unavailable. Using default ammo.")
        else
          swapped_ammo = empty
          equip({ammo=swapped_ammo})
          return
        end
      else -- melee physical weaponskills
        -- If ranged weapon is accipiter/sparrowhawk and using non-ranged WS, equip WSD ammo
        local rweapon = player.equipment.range
        if rweapon and rweapon == 'Accipiter' or (rweapon:length() >= 11 and rweapon:startswith('Sparrowhawk'))
            and silibs.has_item('Hauksbok Arrow', silibs.equippable_bags) then
          swapped_ammo = 'Hauksbok Arrow'
          equip({ammo=swapped_ammo})
        end
      end
    end
  elseif spell.type == 'CorsairShot' then
    if qd_ammo and silibs.has_item(qd_ammo, silibs.equippable_bags) then
      swapped_ammo = qd_ammo
      equip({ammo=swapped_ammo})
    elseif silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
      equip({ammo=swapped_ammo})
      add_to_chat(3,"QD ammo unavailable. Using default ammo.")
    else
      swapped_ammo = empty
      equip({ammo=swapped_ammo})
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ QD & default ammo unavailable. ] **')
      return
    end
  elseif spell.english == "Shadowbind" or spell.english == "Bounty Shot" or spell.english == "Eagle Eye Shot" then
    if silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
      equip({ammo=swapped_ammo})
    else
      swapped_ammo = empty
      equip({ammo=swapped_ammo})
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ Default ammo unavailable. ] **')
      return
    end
  end
  local swapped_item = get_item(swapped_ammo)
  if player.equipment.ammo ~= 'empty' and swapped_item ~= nil and swapped_item.count < options.ammo_warning_limit
      and not S{'hauksbok arrow', 'hauksbok bullet', 'animikii bullet'}:contains(swapped_item.shortname) then
    add_to_chat(39,"*** Ammo '"..swapped_item.shortname.."' running low! *** ("..swapped_item.count..")")
  end
end


-------------------------------------------------------------------------------
-- Feature-enabling functions
-------------------------------------------------------------------------------
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
    silibs.set_lockstyle()
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

function silibs.enable_ui(feature_config)
  if feature_config and feature_config.geo_luopan then
    if feature_config.geo_luopan.align_right then
      silibs.ui.luopan:right_justified(feature_config.geo_luopan.align_right)
    end
    if feature_config.geo_luopan.x and feature_config.geo_luopan.y then
      silibs.ui.luopan:pos(
        feature_config.geo_luopan.x,
        feature_config.geo_luopan.y
      )
    end
    state.ShowLuopanUi:set(true)
  end

  -- Turn on this UI if no config was passed but job is GEO
  if not feature_config and (player.main_job == 'GEO' or player.sub_job == 'GEO') then
    state.ShowLuopanUi:set(true)
  end
end


-------------------------------------------------------------------------------
-- Gearswap lifecycle hooks
-------------------------------------------------------------------------------
function silibs.user_setup_hook()
  silibs.set_lockstyle()
end

function silibs.precast_hook(spell, action, spellMap, eventArgs)
  if silibs.cancel_outranged_ws_enabled then
    silibs.cancel_outranged_ws(spell, eventArgs)
  end
  if silibs.cancel_on_blocking_status_enabled then
    silibs.cancel_on_blocking_status(spell, eventArgs)
  end
end

function silibs.post_precast_hook(spell, action, spellMap, eventArgs)
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

  if not spell.interrupted then
    if spell.english:startswith('Indi-') then
      if spell.target.type == 'SELF' then
        silibs.last_indi = string.sub(spell.english,6)
      end
		elseif spell.english:startswith('Geo-') or spell.english == "Mending Halation" or spell.english == "Radial Arcana" then
			eventArgs.handled = true
			if spell.english:startswith('Geo-') then
				silibs.last_geo = string.sub(spell.english,5)
			end
    end
  end
end

function silibs.midcast_hook(spell, action, spellMap, eventArgs)
end

function silibs.post_midcast_hook(spell, action, spellMap, eventArgs)
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
end

function silibs.aftercast_hook(spell, action, spellMap, eventArgs)
end

function silibs.post_aftercast_hook(spell, action, spellMap, eventArgs)
end

function silibs.customize_idle_set(idleSet)
  return idleSet
end

function silibs.customize_melee_set(meleeSet)
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
  return meleeSet
end

function silibs.customize_defense_set(defenseSet)
  return defenseSet
end

-------------------------------------------------------------------------------
-- Event hooks
-------------------------------------------------------------------------------
-- Executes on every frame. This is just a way to create a perpetual loop.
frame_count=1
windower.register_event('prerender',function()
  if windower.ffxi.get_info().logged_in and windower.ffxi.get_player() then
    -- Use frame count to limit execution rate
    -- Every 10 frames (roughly 0.16-0.33 seconds depending on FPS)
    if frame_count%10 == 0 then
      if silibs.weapon_rearm_enabled then
        silibs.update_and_rearm_weapons()
      end
    end
    -- Every 600 frames (roughly 10-20 seconds depending on FPS)
    if frame_count%600 == 0 then
      if state.TreasureMode.value ~= 'None' then
        -- Clean TH tagged mob list
        silibs.cleanup_tagged_mobs()
      end
    end

    silibs.update_ui(frame_count)

    -- Increment frame_count but prevent overflows
    if frame_count > 10000 then
      frame_count = 1
    else
      frame_count = frame_count + 1
    end
  end
end)

-- Hook into job/subjob change event (happens BEFORE job starts changing)
windower.raw_register_event('outgoing chunk', function(id, data, modified, injected, blocked)
  if id == 0x100 then -- Sending job change command to server
    -- Re-init settings if changing main
    local newmain = data:byte(5)
    local newsub = data:byte(6)
    if res.jobs[newmain] and newmain ~= 0 and newmain ~= player.main_job_id then
      silibs.init_settings()
    end
  elseif id == 0x053 then -- Send lockstyle command to server
    local type = data:unpack("I",0x05)
    if type == 0 then -- This is lockstyle 'disable' command
      silibs.locked_style = false
    else -- Various diff ways to set lockstyle
      silibs.locked_style = true
    end
  end
end)

-- Set lockstyle again when encumbrance value changes (which disables lockstyle as a side effect)
windower.raw_register_event('incoming chunk', function(id, data, modified, injected, blocked)
  if id == 0x01B then -- Contains info about player's encumbrance status
    local encumbrance = data:unpack('I',0x61)
    if encumbrance ~= silibs.encumbrance then
      silibs.locked_style = false
      silibs.encumbrance = encumbrance
      silibs.set_lockstyle()
    end
  elseif id == 0x061 then -- Contains info about player stats
    local p = packets.parse('incoming', data)

    silibs.playerStats["Base"]["STR"] = p["Base STR"] -- Includes STR merits
    silibs.playerStats["Base"]["DEX"] = p["Base DEX"] -- Includes DEX merits
    silibs.playerStats["Base"]["VIT"] = p["Base VIT"] -- Includes VIT merits
    silibs.playerStats["Base"]["AGI"] = p["Base AGI"] -- Includes AGI merits
    silibs.playerStats["Base"]["INT"] = p["Base INT"] -- Includes INT merits
    silibs.playerStats["Base"]["MND"] = p["Base MND"] -- Includes MND merits
    silibs.playerStats["Base"]["CHR"] = p["Base CHR"] -- Includes CHR merits
    silibs.playerStats["Bonus"]["STR"] = p["Added STR"]
    silibs.playerStats["Bonus"]["DEX"] = p["Added DEX"]
    silibs.playerStats["Bonus"]["VIT"] = p["Added VIT"]
    silibs.playerStats["Bonus"]["AGI"] = p["Added AGI"]
    silibs.playerStats["Bonus"]["INT"] = p["Added INT"]
    silibs.playerStats["Bonus"]["MND"] = p["Added MND"]
    silibs.playerStats["Bonus"]["CHR"] = p["Added CHR"]
  end
  silibs.on_incoming_chunk_for_th(id, data, modified, injected, blocked)
end)

windower.raw_register_event('action', function(action)
  silibs.on_action_for_th(action)
end)

windower.raw_register_event('zone change', function(new_zone, old_zone)
  silibs.on_zone_change_for_th(new_zone, old_zone)
end)

return silibs
