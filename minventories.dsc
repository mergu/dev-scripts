# This script is a replacement for scarce, bug-ridden non-updated plugins such as Multiverse-Inventories or xInventories.

# Here you may assign worlds to inventory groups.
# Inventory groups completely separate a player's profile across worlds and gamemodes, including their:
# - inventory
# - enderchest
# - armor
# - xp
# - potion effects
# - etc
# You can check the script out for the full list of saved attributes.
# In the below example, a player will share their profile across the world, world_nether, and world_the_end worlds, and will have separate profiles for the dungeons and vip worlds.
# In general, it is best to alter this config with the server offline or no players on. Any worlds not listed will belong to a 'default' inventory group.
# Note that renaming a group will result in the creation of a new group, and thus inventory loss. Old inventories will still be saved in the player yaml files.
# Files are saved to plugins/Denizen/inventories/<UUID>.yml

inv_groups:
  type: data
  debug: false
  groups:
    surbible:
      - s3_nether
      - s3
      - spawn
      - newnether
      - news3
      - s1
      - theendkek
      - s2
      - s1_nether
    dungeons:
      - dungeons
    VIPCreative:
      - dungeonvip
      - NewVIP
    scavenger_hunt:
      - scavenger_hunt
    scavenger_hunt2:
      - scavenger_hunt2
    hallowe2020:
      - hallowe2020

inv_events:
  type: world
  debug: false
  events:
    on player joins:
      - flag player inv_save_ready:!
      - inventory clear
      - inventory d:<player.enderchest> clear
      - if !<server.has_file[inventories/<player.uuid>.yml]>:
        - yaml create id:<player.uuid>_inventories
        - stop
      - ~yaml load:inventories/<player.uuid>.yml id:<player.uuid>_inventories
      - if !<player.is_online>:
        - if <yaml.list.contains[<player.uuid>_inventories]>:
          - yaml unload id:<player.uuid>_inventories
        - stop
      - yaml set current_inventory:! id:<player.uuid>_inventories
      - run change_inventory def:<player.world.name>|<player.gamemode>
      - announce to_console "Login took <queue.time_ran.in_milliseconds>ms for <player.name>"
      - flag player inv_save_ready

    on player quits:
      - if !<player.has_flag[inv_save_ready]>:
        - if <yaml.list.contains[<player.uuid>_inventories]>:
          - yaml unload id:<player.uuid>_inventories
        - stop
      - flag player inv_save_ready:!
      - ~run save_inventory def:<player.world.name>|<player.gamemode>
      - ~yaml savefile:inventories/<player.uuid>.yml id:<player.uuid>_inventories
      - yaml unload id:<player.uuid>_inventories

    on delta time minutely:
      - foreach <server.online_players> as:player:
        - if !<[player].has_flag[inv_save_ready]> || !<[player].is_online>:
          - foreach next
        - flag <[player]> inv_save_ready:!
        - ~run save_inventory def:<[player].world.name>|<[player].gamemode> player:<[player]>
        - ~yaml savefile:inventories/<[player].uuid>.yml id:<[player].uuid>_inventories
        - flag <[player]> inv_save_ready

    on player changes gamemode:
      - inventory close
      - flag player inv_save_ready:!
      - ~run save_inventory def:<player.world.name>|<player.gamemode>
      - run change_inventory def:<player.world.name>|<context.gamemode>
      - announce to_console "Gamemode change took <queue.time_ran.in_milliseconds>ms for <player.name>"
      - flag player inv_save_ready

    on player changes world:
      - inventory close
      - flag player inv_save_ready:!
      - ~run save_inventory def:<context.origin_world.name>|<player.gamemode>
      - run change_inventory def:<context.destination_world.name>|<player.gamemode>
      - announce to_console "World change took <queue.time_ran.in_milliseconds>ms for <player.name>"
      - flag player inv_save_ready

    on player drops item:
      - if <player.gamemode> == creative:
        - flag player no_tp duration:2s

    on player teleports bukkit_priority:highest:
      - if <player.has_flag[no_tp]>:
        - determine passively cancelled
        - narrate "you gotta wait 2 seconds before you can teleport" format:zc_text

get_xp:
  type: procedure
  debug: false
  definitions: player
  script:
    - define lvl <[player].xp_level>
    - if <[lvl]> <= 16:
      - define level_xp <[lvl].add[6].mul[<[lvl]>]>
    - else if <[lvl]> <= 31:
      - define level_xp <[lvl].mul[<[lvl]>].mul[2.5].sub[<[lvl].mul[40.5]>].add[360]>
    - else:
      - define level_xp <[lvl].mul[<[lvl]>].mul[4.5].sub[<[lvl].mul[162.5]>].add[2220]>
    - define curr_xp <[player].xp.mul[<[player].xp_to_next_level>].div[100]>
    - determine <[level_xp].add[<[curr_xp]>].round>

get_inv_group:
  type: procedure
  debug: false
  definitions: worldname
  script:
    - foreach <script[inv_groups].data_key[groups]>:
      - if <[value].contains[<[worldname]>]>:
        - determine <[key]>
    - determine default

change_inventory:
  type: task
  debug: false
  definitions: worldname|gamemode
  script:
    - define id <player.uuid>_inventories
    - if !<yaml.list.contains[<[id]>]> || !<player.is_online>:
      - stop
    - define path groups.<proc[get_inv_group].context[<[worldname]>]>.<[gamemode].to_lowercase>
    - if <[path]> == <yaml[<[id]>].read[current_inventory]||false>:
      - stop
    - yaml set current_inventory:<[path]> id:<[id]>
    - inventory clear
    - inventory d:<player.enderchest> clear
    # Inventory
    - define slots <yaml[<[id]>].read[<[path]>.inventory]||<map[]>>
    - if !<[slots].is_empty>:
      - inventory set d:<player.inventory> o:<[slots]>
    # Enderchest
    - define slots <yaml[<[id]>].read[<[path]>.enderchest]||<map[]>>
    - if !<[slots].is_empty>:
      - inventory set d:<player.enderchest> o:<[slots]>
    # Equipment
    - define slots <yaml[<[id]>].read[<[path]>.equipment]||<map[]>>
    - if !<[slots].is_empty>:
      - adjust <player> equipment:<[slots]>
    # Offhand
    - define slots <yaml[<[id]>].read[<[path]>.offhand]||null>
    - if <[slots]> != null:
      # item_in_offhand mec throws an error if the player is dead
      - inventory set d:<player.inventory> o:<[slots]> slot:41
    # Stats
    - define max_health <yaml[<[id]>].read[<[path]>.stats.health_max]||20>
    - adjust <player> max_health:<[max_health]>
    - adjust <player> health:<yaml[<[id]>].read[<[path]>.stats.health].min[<[max_health]>]||20>
    - adjust <player> food_level:<yaml[<[id]>].read[<[path]>.stats.food_level]||20>
    - adjust <player> saturation:<yaml[<[id]>].read[<[path]>.stats.saturation]||0>
    - adjust <player> exhaustion:<yaml[<[id]>].read[<[path]>.stats.exhaustion]||1>
    - adjust <player> fall_distance:<yaml[<[id]>].read[<[path]>.stats.fall_distance]||0>
    - adjust <player> fire_time:<yaml[<[id]>].read[<[path]>.stats.fire_time]||0>
    - adjust <player> oxygen:<yaml[<[id]>].read[<[path]>.stats.oxygen]||15>
    - adjust <player> remove_effects
    - adjust <player> potion_effects:<yaml[<[id]>].read[<[path]>.stats.potion_effects]||<list[]>>
    - experience take <util.int_max>
    - experience give <yaml[<[id]>].read[<[path]>.stats.xp]||0>

save_inventory:
  type: task
  debug: false
  definitions: worldname|gamemode
  script:
    - define id <player.uuid>_inventories
    - if !<yaml.list.contains[<[id]>]> || !<player.is_online>:
      - stop
    - if <[gamemode]> == spectator:
      - stop
    - define path groups.<proc[get_inv_group].context[<[worldname]>]>.<[gamemode].to_lowercase>
    # Inventory
    - define slot_map <player.inventory.map_slots.get_subset[<util.list_numbers_to[36]>]||<map[]>>
    - if <[slot_map].is_empty>:
      - yaml set <[path]>.inventory:! id:<[id]>
    - else:
      - yaml set <[path]>.inventory:<[slot_map]> id:<[id]>
    # Enderchest
    - define slot_map <player.enderchest.map_slots||<map[]>>
    - if <[slot_map].is_empty>:
      - yaml set <[path]>.enderchest:! id:<[id]>
    - else:
      - yaml set <[path]>.enderchest:<[slot_map]> id:<[id]>
    # Equipment
    - define slots <player.equipment_map>
    - if <[slots].is_empty>:
      - yaml set <[path]>.equipment:! id:<[id]>
    - else:
      - yaml set <[path]>.equipment:<[slots]> id:<[id]>
    # Offhand
    # item_in_offhand tag throws an error if the player is dead
    - yaml set <[path]>.offhand:<player.inventory.slot[41]> id:<[id]>
    # Stats
    - yaml set <[path]>.stats.health_max:<player.attribute_base_value[generic_max_health]> id:<[id]>
    - yaml set <[path]>.stats.health:<player.health> id:<[id]>
    - yaml set <[path]>.stats.food_level:<player.food_level> id:<[id]>
    - yaml set <[path]>.stats.saturation:<player.saturation> id:<[id]>
    - yaml set <[path]>.stats.exhaustion:<player.exhaustion> id:<[id]>
    - yaml set <[path]>.stats.fall_distance:<player.fall_distance||0> id:<[id]>
    - yaml set <[path]>.stats.fire_time:<player.fire_time||0> id:<[id]>
    - yaml set <[path]>.stats.oxygen:<player.oxygen> id:<[id]>
    - yaml set <[path]>.stats.potion_effects:<player.list_effects> id:<[id]>
    - yaml set <[path]>.stats.xp:<proc[get_xp].context[<player>]> id:<[id]>
