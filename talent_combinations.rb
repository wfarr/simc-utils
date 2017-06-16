#!/usr/bin/env ruby

require 'yaml'
require 'active_support/core_ext/object/deep_dup'

TALENT_ROWS = 7
TALENT_COLUMNS = 3

talent_combinations = Array.new(TALENT_ROWS) { |a|
  (1..TALENT_COLUMNS).to_a
}.flatten.combination(7).to_a.map { |a|
  # ignore 2nd row
  a[1] = 0
  # ignore 3rd row
  a[2] = 0
  # always use TM
  a[0] = 1
  # always use EF
  a[4] = 3
  # always use EB
  a[5] = 3
  # always use Asc
  a[6] = 1

  a
}.map(&:join).uniq.flatten

LEGENDARIES = [
  {
    name: "uncertain_reminder",
    id: 143732,
    slot: "head",
    shortname: "UR",
  },
  {
    name: "prydaz_xavarics_magnum_opus",
    id: 132444,
    slot: "neck",
    shortname: "PRYDAZ",
  },
  {
    name: "echoes_of_the_great_sundering",
    id: 137074,
    slot: "shoulders",
    shortname: "ECHOES",
  },
  {
    name: "alakirs_acrimony",
    id: 137102,
    slot: "wrists",
    shortname: "ALAKIRS",
  },
  {
    name: "smoldering_heart",
    id: 151819,
    slot: "hands",
    shortname: "SMOLDERING",
  },
  {
    name: "pristine_protoscale_girdle",
    id: 137083,
    slot: "waist",
    shortname: "GIRDLE",
  },
  {
    name: "roots_of_shaladrassil",
    id: 132466,
    slot: "legs",
    shortname: "ROOTS",
  },
  {
    name: "the_deceivers_blood_pact",
    id: 137035,
    slot: "feet",
    shortname: "DECEIVERS",
  },
  {
    name: "eye_of_the_twisting_nether",
    id: 137050,
    slot: "finger",
    shortname: "EOTN",
  },
  {
    name: "sephuzs_secret",
    id: 132452,
    slot: "finger",
    shortname: "SEPHUZ",
  },
  {
    name: "soul_of_the_farseer",
    id: 151647,
    slot: "finger",
    shortname: "SOUL",
  },
  {
    name: "kiljaedens_burning_wish",
    id: 144259,
    slot: "trinket",
    shortname: "KJBW",
  },
]

legendary_combinations = LEGENDARIES.combination(2).to_a

def add_legendaries(legendaries)
  copy = legendaries.deep_dup

  if copy.all? { |l| l[:slot] == "finger" }
    copy[0][:slot] = "finger1"
    copy[1][:slot] = "finger2"
  end

  copy.each_with_index do |l, idx|
    if l[:slot] == "finger"
      copy[idx][:slot] = "finger2"
    end

    if l[:slot] == "trinket"
      copy[idx][:slot] = "trinket2"
    end
  end

  copy.map { |l|
    str = "#{l[:slot]}=#{l[:name]},id=#{l[:id]},ilevel=970"

    if l[:slot] =~ /finger/
      str << ",enchant=200crit,gems=150crit"
    end

    if l[:slot] =~ /neck/
      str << ",enchant=mark_of_the_claw"
    end

    str
  }.join("\n")
end

def add_copy(talents, legendaries)
  <<-EOS
copy="#{talents}_#{legendaries[0][:shortname]}_#{legendaries[1][:shortname]}",baseline
talents=#{talents}
#{add_legendaries(legendaries)}
EOS
end

def render_combinations_simc(talent_combinations, legendary_combinations)
  <<-EOS
iterations=25000
target_error=0.3
fight_style=patchwerk
fixed_time=1
threads=64

max_time=300

shaman="baseline"
level=110
race=tauren
region=us
server=malganis
role=
professions=alchemy=800/herbalism=815
spec=elemental
artifact=40:0:0:0:0:291:1:292:1:293:1:294:1:295:1:296:1:297:1:298:4:299:4:300:4:301:4:302:4:303:4:304:4:305:4:306:4:1350:1:1387:1:1589:4:1590:1:1591:1:1592:1:1683:10

head=helmet_of_the_skybreaker,id=147178,ilevel=930
neck=string_of_extracted_incisors,id=147013,ilevel=930,enchant=mark_of_the_claw
shoulders=mantle_of_waning_radiance,id=147054,ilevel=930
back=drape_of_the_skybreaker,id=147176,ilevel=930,enchant=binding_of_intellect
chest=harness_of_the_skybreaker,id=147175,ilevel=930
wrists=painsinged_armguards,id=147057,ilevel=930
hands=vicegrip_of_the_unrepentant,id=147048,ilevel=940
waist=waistguard_of_interminable_unity,id=147056,ilevel=930
legs=legguards_of_the_skybreaker,id=147179,ilevel=930
feet=starstalker_treads,id=147046,ilevel=940
finger1=seal_of_the_second_duumvirate,id=147195,ilevel=940,enchant=200haste
finger2=scaled_band_of_servitude,id=147020,ilevel=930,enchant=200crit
trinket1=tome_of_unraveling_sanity,id=147019,ilevel=940
trinket2=spectral_thurible,id=147018,ilevel=930
main_hand=the_fist_of_raden,id=128935,bonus_id=744,ilevel=951,gem_id=147112/142308/147112,relic_id=3563/3518/3563
off_hand=the_highkeepers_ward,id=128936

#{talent_combinations.map { |tc| legendary_combinations.map { |lc| add_copy(tc, lc) }.join("\n") }.join("\n\n") }
EOS
end

puts "rendering #{talent_combinations.count * legendary_combinations.count} profiles"
File.open("rendered.simc", "w+") do |f|
  f.write(render_combinations_simc(talent_combinations, legendary_combinations))
end


# configmap = {
#   "apiVersion" => "v1",
#   "kind" => "ConfigMap",
#   "metadata" => {
#     "name" => "dubs-simc-1",
#   },
#   "data" => {
#     "combinations.simc.file" => render_combinations_simc(combinations),
#   }
# }
# 
# pod = {
#   "apiVersion" => "v1",
#   "kind" => "Pod",
#   "metadata" => {
#     "name" => "dubs-simc-1",
#   },
#   "spec" => {
#     "containers" => [
#       {
#         "name" => "simc",
#         "args" => [
#           "input=/tmp/simc-configs/combinations.simc",
#         ],
#         "image" => "dubs/simc:latest",
#         "resources" => {
#           "requests" => {
#             "cpu" => "28000m",
#             "memory" => "16Gi",
#           },
#           "limits" => {
#             "cpu" => "28000m",
#             "memory" => "16Gi",
#           }
#         },
#         "volumeMounts" => [
#           {
#             "name" => "simc-configs",
#             "mountPath" => "/tmp/simc-configs",
#           },
#         ],
#       },
#     ],
#     "volumes" => [
#       {
#         "name" => "simc-configs",
#         "configMap" => {
#           "name" => "dubs-simc-1",
#           "items" => [
#             {
#               "key" => "combinations.simc.file",
#               "path" => "combinations.simc",
#             },
#           ]
#         }
#       }
#     ]
#   }
# }
# 
# File.open("configmap.yaml", "w+") do |f|
#   f.write YAML.dump(configmap)
# end
# 
# File.open("pod.yaml", "w+") do |f|
#   f.write YAML.dump(pod)
# end
