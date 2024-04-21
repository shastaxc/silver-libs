-- Version 2024.APR.21.002
-- Copyright © 2021-2024, Shasta
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

-------------------------------------------------------------------------------
-- Includes/imports
-------------------------------------------------------------------------------
res = include('resources')
packets = include('packets')
chars = include('chat/chars')
extdata = include('extdata')


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
-- Instatiated variables for storing values and states
-------------------------------------------------------------------------------
-- Most recent weapons (used for re-arming)
silibs.most_recent_weapons = {main='empty',sub='empty',ranged='empty',ammo='empty'}
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
silibs.default_th_aoe_actions = {
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

silibs.ui = {}
--Luopan Distance Tracking
silibs.ui.luopan = texts.new('${value}', {
  pos = { x=0, y=50, },
  text = { font='Arial', size=12, },
  flags = { right=false, bold=true, },
  bg = { alpha=0, },
  stroke = { width=2, alpha=192 },
})
silibs.ui.bt_color = '\\cs(230,118,116)'
silibs.has_obi = false
silibs.has_orpheus = false
silibs.latest_flurry_buff = nil


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
  [ 98] = {id=98, name='Fighter\'s Roll', lucky=5, unlucky=9, effect='Double Attack Rate'},
  [ 99] = {id=99, name='Monk\'s Roll', lucky=3, unlucky=7, effect='Subtle Blow'},
  [100] = {id=100, name='Healer\'s Roll', lucky=3, unlucky=7, effect='Cure Potency Received'},
  [101] = {id=101, name='Wizard\'s Roll', lucky=5, unlucky=9, effect='Magic Attack'},
  [102] = {id=102, name='Warlock\'s Roll', lucky=4, unlucky=8, effect='Magic Accuracy'},
  [103] = {id=103, name='Rogue\'s Roll', lucky=5, unlucky=9, effect='Critical Hit Rate'},
  [104] = {id=104, name='Gallant\'s Roll', lucky=3, unlucky=7, effect='Defense'},
  [105] = {id=105, name='Chaos Roll', lucky=4, unlucky=8, effect='Attack'},
  [106] = {id=106, name='Beast Roll', lucky=4, unlucky=8, effect='Pet Attack'},
  [107] = {id=107, name='Choral Roll', lucky=2, unlucky=6, effect='Spell Interruption Rate'},
  [108] = {id=108, name='Hunter\'s Roll', lucky=4, unlucky=8, effect='Accuracy'},
  [109] = {id=109, name='Samurai Roll', lucky=2, unlucky=6, effect='Store TP'},
  [110] = {id=110, name='Ninja Roll', lucky=4, unlucky=8, effect='Evasion'},
  [111] = {id=111, name='Drachen Roll', lucky=4, unlucky=8, effect='Pet Magic Accuracy/Attack'},
  [112] = {id=112, name='Evoker\'s Roll', lucky=5, unlucky=9, effect='Refresh'},
  [113] = {id=113, name='Magus\'s Roll', lucky=2, unlucky=6, effect='Magic Defense'},
  [114] = {id=114, name='Corsair\'s Roll', lucky=5, unlucky=9, effect='Experience Points'},
  [115] = {id=115, name='Puppet Roll', lucky=3, unlucky=7, effect='Pet Magic Attack/Accuracy'},
  [116] = {id=116, name='Dancer\'s Roll', lucky=3, unlucky=7, effect='Regen'},
  [117] = {id=117, name='Scholar\'s Roll', lucky=2, unlucky=6, effect='Conserve MP'},
  [118] = {id=118, name='Bolter\'s Roll', lucky=3, unlucky=9, effect='Movement Speed'},
  [119] = {id=119, name='Caster\'s Roll', lucky=2, unlucky=7, effect='Fast Cast'},
  [120] = {id=120, name='Courser\'s Roll', lucky=3, unlucky=9, effect='Snapshot'},
  [121] = {id=121, name='Blitzer\'s Roll', lucky=4, unlucky=9, effect='Attack Delay'},
  [122] = {id=122, name='Tactician\'s Roll', lucky=5, unlucky=8, effect='Regain'},
  [302] = {id=302, name='Allies\' Roll', lucky=3, unlucky=10, effect='Skillchain Damage'},
  [303] = {id=303, name='Miser\'s Roll', lucky=5, unlucky=7, effect='Save TP'},
  [304] = {id=304, name='Companion\'s Roll', lucky=2, unlucky=10, effect='Pet Regain and Regen'},
  [305] = {id=305, name='Avenger\'s Roll', lucky=4, unlucky=8, effect='Counter Rate'},
  [390] = {id=390, name='Naturalist\'s Roll', lucky=3, unlucky=7, effect='Enh. Magic Duration'},
  [391] = {id=391, name='Runeist\'s Roll', lucky=4, unlucky=8, effect='Magic Evasion'},
}

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

silibs.rare_ammo = S{'hauksbok arrow', 'hauksbok bullet', 'animikii bullet'}
silibs.equip_locked_spells = S{'Honor March', 'Dispelga', 'Impact'}


-------------------------------------------------------------------------------
-- Fix Mote's mistakes
-------------------------------------------------------------------------------

-- Overwrite Mote's implementation of setting elemental gear (it's outdated)
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
  silibs.equip_loop_enabled = false
  silibs.quick_magic_spells = silibs.default_quick_magic_spells:copy()
  silibs.custom_roll_text_enabled = {
    show_self = false,
    show_others = false,
  }
  silibs.haste_info_enabled = false
  silibs.elemental_belt_handling_enabled = false
  silibs.elemental_belt_handling_condition = nil
  silibs.snapshot_auto_equip_enabled = false

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
  state.RearmingLock = M(false, 'Rearming Lock')
  state.ShowLuopanUi = M(false, 'Show Luopan UI')

  -- TH mode handling
  if player.main_job == 'THF' then
      state.TreasureMode:options('None','Tag','SATA','Fulltime')
  else
      state.TreasureMode:options('None','Tag')
  end
  silibs.th_aoe_actions = table.copy(silibs.default_th_aoe_actions)
  
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
  silibs.ui.bt_color = '\\cs(230,118,116)'
  silibs.dw_needed = 0

  silibs.snapshot_sets = nil

  silibs.is_midaction = false
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
        return player[bag][item_name]
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
    equip(silibs.most_recent_weapons)
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
    elseif player.main_job == 'THF' then
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
  if silibs.custom_roll_text_enabled.show_self then
    -- Detect roll actions used by self in order to display results
    if act and type(act) == 'table' and act.category == 6 and silibs.roll_info[act.param] then
      local do_printout
      if act.actor_id == player.id then -- This is your own roll
        do_printout = true
      elseif silibs.custom_roll_text_enabled.show_others then -- Check if we wanna display rolls from other players
        for i=1,#act.targets do
          if act.targets[i].id == player.id then
            do_printout = true
            break
          end
        end
      end

      if do_printout then
        silibs.display_roll_info(act)
      end
    end
  end
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
      elseif snapshot_sets[i+1] then
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
      end
    end

    -- If velocity sets are still empty, fill with regular snapshot sets
    for i=0,70,1 do
      -- Fill in velocity sets
      if not snapshot_sets['Velocity'][i] and snapshot_sets[i] then
        snapshot_sets['Velocity'][i] = set_combine(snapshot_sets[i], {})
      end
    end
  end
  
  silibs.snapshot_sets = snapshot_sets
end

function silibs.on_action_for_flurry(act)
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

    -- TODO: Add snapshot traits/gifts
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
      eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
    elseif silibs.snapshot_sets[snapshot_needed] then
      equip(silibs.snapshot_sets[snapshot_needed])
      eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
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


-------------------------------------------------------------------------------
-- Helpful/Supporting functions
-------------------------------------------------------------------------------
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

function silibs.can_access_spell(spell_name, spell)
  local _
  if spell_name and not spell then
    _, spell = silibs.find_spell(spell_name)
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
  local base_chr = silibs.playerStats['Base']['CHR'] or silibs.waltz_stats.base_chr
  local base_vit = silibs.playerStats['Base']['VIT'] or silibs.waltz_stats.base_vit
  local bonus_chr = silibs.playerStats['Bonus']['CHR'] or silibs.waltz_stats.bonus_chr
  local bonus_vit = silibs.playerStats['Bonus']['VIT'] or silibs.waltz_stats.bonus_vit

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

-- Function to get the current weather intensity: 0 for none, 1 for single weather, 2 for double weather.
function silibs.get_weather_intensity()
  return gearswap.res.weather[world.weather_id].intensity
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

-- Check for proper ammo when shooting or weaponskilling
-- RNG and THF job luas should contain a map of weapon-to-ammo for DefaultAmmo,
-- MagicAmmo, AccAmmo, and WSAmmo in this format:
--   DefaultAmmo = {
--     ['Gastraphetes'] = "Quelling Bolt",
--     ['Fomalhaut'] = "Chrono Bullet",
--   }
--
-- COR job lua should contain a series of variables defining ammo for gear.RAbullet,
-- gear.MAbullet, gear.RAccbullet, gear.MAccbullet, gear.WSbullet, and gear.QDbullet in the following format:
--   gear.RAbullet = 'Chrono Bullet'
function silibs.equip_ammo(spell, action, spellMap, eventArgs)
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
    macc_ammo = player.equipment.range and MagicAmmo[player.equipment.range]
    ws_ammo = player.equipment.range and WSAmmo[player.equipment.range]
    qd_ammo = 'empty'
  elseif player.main_job == 'COR' then
    default_ammo = gear.RAbullet
    magic_ammo = gear.MAbullet
    acc_ammo = gear.RAccbullet
    macc_ammo = gear.MAccbullet
    ws_ammo = gear.WSbullet
    qd_ammo = gear.QDbullet
  end
  if not default_ammo then
    add_to_chat(123, 'Default ammo is undefined.')
    equip({ammo='empty'})
    return
  end

  -- Protect against shooting hauksbok ammo
  if silibs.rare_ammo:contains(default_ammo:lower()) then
    swapped_ammo = empty
    equip({ammo=swapped_ammo})
    eventArgs.cancel = true
    add_to_chat(123, '** Action Canceled: Remove Hauksbok/Animikii ammo from \'default ammo\'. **')
    return
  elseif silibs.rare_ammo:contains(magic_ammo:lower()) then
    swapped_ammo = empty
    equip({ammo=swapped_ammo})
    eventArgs.cancel = true
    add_to_chat(123, '** Action Canceled: Remove Hauksbok/Animikii ammo from \'magic ammo\'. **')
    return
  elseif silibs.rare_ammo:contains(acc_ammo:lower()) then
    swapped_ammo = empty
    equip({ammo=swapped_ammo})
    eventArgs.cancel = true
    add_to_chat(123, '** Action Canceled: Remove Hauksbok/Animikii ammo from \'accuracy ammo\'. **')
    return
  elseif silibs.rare_ammo:contains(ws_ammo:lower()) then
    swapped_ammo = empty
    equip({ammo=swapped_ammo})
    eventArgs.cancel = true
    add_to_chat(123, '** Action Canceled: Remove Hauksbok/Animikii ammo from \'weaponskill ammo\'. **')
    return
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
        add_to_chat(3, 'Acc ammo unavailable. Falling back to default ammo.')
      else
        -- If neither is available, empty the ammo slot
        swapped_ammo = empty
        equip({ammo=swapped_ammo})
        cancel_spell()
        add_to_chat(123, '** Action Canceled: [ Acc & default ammo unavailable. ] **')
        eventArgs.cancel = true
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
          equip({ammo=swapped_ammo})
        elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
          swapped_ammo = default_ammo
          equip({ammo=swapped_ammo})
          add_to_chat(3, 'Magic ammo unavailable. Using default ammo.')
        else
          swapped_ammo = empty
          equip({ammo=swapped_ammo})
          cancel_spell()
          add_to_chat(123, '** Action Canceled: [ Magic & default ammo unavailable. ] **')
          eventArgs.cancel = true
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
            add_to_chat(3, 'Acc ammo unavailable. Using WS ammo.')
          elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            equip({ammo=swapped_ammo})
            add_to_chat(3, 'Acc & WS ammo unavailable. Using default ammo.')
          else
            swapped_ammo = empty
            equip({ammo=swapped_ammo})
            cancel_spell()
            add_to_chat(123, '** Action Canceled: [ Acc, WS, & default ammo unavailable. ] **')
            eventArgs.cancel = true
            return
          end
        else
          if ws_ammo and silibs.has_item(ws_ammo, silibs.equippable_bags) then
            swapped_ammo = ws_ammo
            equip({ammo=swapped_ammo})
          elseif silibs.has_item(default_ammo, silibs.equippable_bags) then
            swapped_ammo = default_ammo
            equip({ammo=swapped_ammo})
            add_to_chat(3, 'WS ammo unavailable. Using default ammo.')
          else
            swapped_ammo = empty
            equip({ammo=swapped_ammo})
            cancel_spell()
            add_to_chat(123, '** Action Canceled: [ WS & default ammo unavailable. ] **')
            eventArgs.cancel = true
            return
          end
        end
      end
    else -- Melee WS
      -- melee magical weaponskills
      if silibs.elemental_ws:contains(spell.english) then
        -- If ranged weapon is accipiter/sparrowhawk and using non-ranged WS, equip WSD ammo
        local rweapon = player.equipment.range
        local range_type = res.items:with('en', rweapon).range_type
        if rweapon and range_type == 'Bow' and silibs.has_item('Hauksbok Arrow', silibs.equippable_bags) then
          swapped_ammo = 'Hauksbok Arrow'
          equip({ammo=swapped_ammo})
        elseif rweapon and range_type == 'Gun' and silibs.has_item('Hauksbok Bullet', silibs.equippable_bags) then
          swapped_ammo = 'Hauksbok Bullet'
          equip({ammo=swapped_ammo})
        elseif magic_ammo and silibs.has_item(magic_ammo, silibs.equippable_bags) then
          swapped_ammo = magic_ammo
          equip({ammo=swapped_ammo})
        elseif default_ammo and silibs.has_item(default_ammo, silibs.equippable_bags) then
          swapped_ammo = default_ammo
          equip({ammo=swapped_ammo})
          add_to_chat(3, 'Magic ammo unavailable. Using default ammo.')
        else
          swapped_ammo = empty
          equip({ammo=swapped_ammo})
          -- Return from function without ammo but don't cancel action. Ammo not needed for melee WS.
          return
        end
      else -- melee physical weaponskills
        -- If ranged weapon is accipiter/sparrowhawk and using non-ranged WS, equip WSD ammo
        local rweapon = player.equipment.range
        local range_type = res.items:with('en', rweapon).range_type
        if rweapon and range_type == 'Bow' and silibs.has_item('Hauksbok Arrow', silibs.equippable_bags) then
          swapped_ammo = 'Hauksbok Arrow'
          equip({ammo=swapped_ammo})
        end
      end
    end
  elseif spell.type == 'CorsairShot' then
    if macc_ammo and silibs.has_item(qd_ammo, silibs.equippable_bags)
        and spell.english == 'Light Shot' or spell.english == 'Dark Shot' then
      swapped_ammo = macc_ammo
      equip({ammo=swapped_ammo})
    elseif qd_ammo and silibs.has_item(qd_ammo, silibs.equippable_bags) then
      swapped_ammo = qd_ammo
      equip({ammo=swapped_ammo})
    elseif silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
      equip({ammo=swapped_ammo})
      add_to_chat(3, 'QD ammo unavailable. Using default ammo.')
    else
      swapped_ammo = empty
      equip({ammo=swapped_ammo})
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ QD & default ammo unavailable. ] **')
      eventArgs.cancel = true
      return
    end
  elseif spell.english == 'Shadowbind' or spell.english == 'Bounty Shot' or spell.english == 'Eagle Eye Shot' then
    if silibs.has_item(default_ammo, silibs.equippable_bags) then
      swapped_ammo = default_ammo
      equip({ammo=swapped_ammo})
    else
      swapped_ammo = empty
      equip({ammo=swapped_ammo})
      cancel_spell()
      add_to_chat(123, '** Action Canceled: [ Default ammo unavailable. ] **')
      eventArgs.cancel = true
      return
    end
  end
  local swapped_item = get_item(swapped_ammo)
  if player.equipment.ammo ~= 'empty' and swapped_item ~= nil and swapped_item.count < options.ammo_warning_limit
      and not silibs.rare_ammo:contains(swapped_item.shortname:lower()) then
    add_to_chat(39,'*** Ammo \''..swapped_item.shortname..'\' running low! *** ('..swapped_item.count..')')
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

function silibs.get_dual_wield_needed()
  if silibs.haste_info_enabled then
    return silibs.dw_needed
  end
end

-- Check sub slot to see if you currently have equipped weapons in a dual wielding configuration
function silibs.is_dual_wielding()
  local sub_weapon_name = player and player.equipment and player.equipment.sub
  if sub_weapon_name then
    local item = res.items:with('en', sub_weapon_name)
    if item and item.category == 'Weapon' then
      return true
    end
  end
  return false
end

function silibs.can_dual_wield()
  local abilities = windower.ffxi.get_abilities()
  local traits = S(abilities.job_traits)
  if traits:contains(18) then
    return true
  end
  return false
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
      local tierkey = {'ara3','ara2','ara'}
      local tierlist = {['ara3']='ra III',['ara2']='ra II',['ara']='ra'}
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

function silibs.get_spell_table_by_name(spell_name)
	for k in pairs(res.spells) do
		if res.spells[k][language] == spell_name then
			return res.spells[k]
		end
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
      or spell.english == 'Kaustra'
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

function silibs.midaction()
  return silibs.is_midaction
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

function silibs.enable_haste_info()
  silibs.haste_info_enabled = true
  send_command('hi report')
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


-------------------------------------------------------------------------------
-- Gearswap lifecycle hooks
-------------------------------------------------------------------------------
function silibs.user_setup_hook()
  silibs.locked_style = false -- Lockstyle unlocks on subjob change
  silibs.set_lockstyle()
end

function silibs.precast_hook(spell, action, spellMap, eventArgs)
  if silibs.cancel_outranged_ws_enabled then
    silibs.cancel_outranged_ws(spell, eventArgs)
  end
  if silibs.cancel_on_blocking_status_enabled then
    silibs.cancel_on_blocking_status(spell, eventArgs)
  end
  if silibs.snapshot_auto_equip_enabled then
    silibs.select_snapshot_set_for_ranged_attacks(spell, eventArgs)
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
      eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
    end
    if player.sub_job == 'RDM' and player.sub_job_level > 0 and customEquipSet['RDM'] then
      customEquipSet = customEquipSet['RDM']
      equip(customEquipSet)
      eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
    end
    if player.main_job == 'SCH' then
      if spell.type == 'WhiteMagic' and (buffactive['Light Arts'] or buffactive['Addendum: White']) then
        if customEquipSet['Grimoire'] then
          customEquipSet = customEquipSet['Grimoire']
          equip(customEquipSet)
          eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
        elseif customEquipSet['LightArts'] then
          customEquipSet = customEquipSet['LightArts']
          equip(customEquipSet)
          eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
        end
      elseif spell.type == 'BlackMagic' and (buffactive['Dark Arts'] or buffactive['Addendum: Black']) then
        -- Add Grimoire set if exists
        if customEquipSet['Grimoire'] then
          customEquipSet = customEquipSet['Grimoire']
          equip(customEquipSet)
          eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
        elseif customEquipSet['DarkArts'] then
          customEquipSet = customEquipSet['DarkArts']
          equip(customEquipSet)
          eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
        end
      end
    end
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
  silibs.is_midaction = true
end

function silibs.midcast_hook(spell, action, spellMap, eventArgs)
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
      eventArgs.handled=true -- Prevents Mote lib from overwriting the equipSet
    end
  end
end

function silibs.post_midcast_hook(spell, action, spellMap, eventArgs)
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
end

function silibs.aftercast_hook(spell, action, spellMap, eventArgs)
  silibs.is_midaction = false
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
      end
    end

    -- Every 0.33 seconds, check to re-arm weapons
    if now - silibs.timer2 > 0.33 then
      silibs.timer2 = now
      if silibs.weapon_rearm_enabled then
        silibs.update_and_rearm_weapons()
      end
    end

    -- Every 0.5 seconds, check to re-arm weapons
    if now - silibs.timer3 > 0.5 then
      silibs.timer3 = now
      if silibs.equip_loop_enabled
          and not silibs.midaction()
          and not ((player.main_job == 'SMN'
            or player.main_job == 'BST'
            or player.main_job == 'PUP')
            and pet_midaction()) then
        send_command('gs c update')
      end
    end

    -- Every 20 seconds clean TH tagged mob list
    if now - silibs.timer4 > 20 then
      silibs.timer4 = now
      if state.TreasureMode.value ~= 'None' then
        silibs.cleanup_tagged_mobs()
      end
    end
  end
end)

windower.raw_register_event('outgoing chunk', function(id, data, modified, injected, blocked)
  if id == 0x053 then -- Send lockstyle command to server
    local type = data:unpack('I', 0x05)
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
    local encumbrance = data:unpack('I', 0x61)
    if encumbrance ~= silibs.encumbrance then
      silibs.locked_style = false
      silibs.encumbrance = encumbrance
      silibs.set_lockstyle()
    end
  elseif id == 0x061 then -- Contains info about player stats
    local p = packets.parse('incoming', data)

    silibs.playerStats['Base']['STR'] = p['Base STR'] -- Includes STR merits
    silibs.playerStats['Base']['DEX'] = p['Base DEX'] -- Includes DEX merits
    silibs.playerStats['Base']['VIT'] = p['Base VIT'] -- Includes VIT merits
    silibs.playerStats['Base']['AGI'] = p['Base AGI'] -- Includes AGI merits
    silibs.playerStats['Base']['INT'] = p['Base INT'] -- Includes INT merits
    silibs.playerStats['Base']['MND'] = p['Base MND'] -- Includes MND merits
    silibs.playerStats['Base']['CHR'] = p['Base CHR'] -- Includes CHR merits
    silibs.playerStats['Bonus']['STR'] = p['Added STR']
    silibs.playerStats['Bonus']['DEX'] = p['Added DEX']
    silibs.playerStats['Bonus']['VIT'] = p['Added VIT']
    silibs.playerStats['Bonus']['AGI'] = p['Added AGI']
    silibs.playerStats['Bonus']['INT'] = p['Added INT']
    silibs.playerStats['Bonus']['MND'] = p['Added MND']
    silibs.playerStats['Bonus']['CHR'] = p['Added CHR']
  end
  silibs.on_incoming_chunk_for_th(id, data, modified, injected, blocked)
end)

windower.raw_register_event('action', function(action)
  silibs.on_action_for_th(action)
  silibs.on_action_for_rolls(action)
  silibs.on_action_for_flurry(action)
end)

windower.raw_register_event('zone change', function(new_zone, old_zone)
  silibs.on_zone_change_for_th(new_zone, old_zone)
end)

windower.raw_register_event('incoming text', function(old, new, color)
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

  return new, color
end)

silibs.init_settings()
return silibs