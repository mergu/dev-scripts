# @ #1: Need a transition into the next room, found on the left of the room #1 is in
region_handler:
  type: world
  events:
    after player enters region_one_name:
      - run fancy_teleport defmap:teleport=room_two_name

# @ #2: Need a region set where players cannot edit pre-rotated swords
# @ #3 Need a region set where players *can* rotate the un-rotated swords, but not remove them
    on player breaks hanging in:region_two_name|region_three_name:
      - determine cancelled
    on hanging breaks in:region_two_name|region_three_name:
      - determine cancelled
    on player right clicks item_frame in:region_two_name:
      - determine cancelled

# @ #5 Need certain events to trigger when the correlating button is pressed. The event needed can be determined
  # by the color of wool above it
  # - Yellow: Correct button, trigger the opening gate
  # - Red: Incorrect, Deal 1-3 hearts of damage to the player triggering the button
  # - Blue: Incorrect, give the player a random negative potion effect
  # - Gray: Incorrect, spawn 1-3 hostile mobs in the puzzle room
    after player right clicks block in:yellow_buttons:
      - run open_gate_task defmap:door=one
    after player right clicks block in:red_buttons:
      - hurt <util.random.int[1].to[3]>
    after player right clicks block in:blue_buttons:
      - define effects <list[blindness|confusion|harm|invisibility|levitation|poison|slow|weakness|wither]>
      - cast <[effects].random>
    after player right clicks block in:gray_buttons:
      - define random_entities <list[skeleton|zombie|creeper|spider]>
      - spawn <util.list_numbers_to[<util.random.int[1].to[3]>].parse_tag[<[random_entities].random>]> <player.location.random_offset[1,0,1]>


# @ #7 Need a transition to the long hallway to the left of this block.
    after player enters region_four_name:
      - run fancy_teleport defmap:teleport=room_three_name

# @ #9 In this room, I need a handfull of fireballs that will pursue the player as long as they are inside of this room
    after player enters region_five_name:
      - define active <server.has_flag[region_five_name.players]>
      - flag server region_five_name.players:->:<player>

      - if <[active]>:
        - stop

      # ! fireball_speed_magnitude is the speed of the fireballs; higher integers are slow, lower integers are fast
      - define fireball_speed_magnitude 4

      # ! these are pre-defined spawn locations for the fireballs;
      # | list can be generated and added to with: `/ex flag server region_five_name.fireball_spawn_locations:->:<player.location>` at the location you're standing at
      # | list can be purged with `/ex flag server region_five_name.fireball_spawn_locations:!`
      - foreach <server.flag[region_five_name.fireball_spawn_locations]>:
        - spawn fireball save:fireball_entities
        - flag server region_five_name.fireball_entities <entry[fireball_entities].spawned_entities>

      - while <server.has_flag[region_five_name.players]>:
        - foreach <server.flag[region_five_name.fireball_entities]> as:entity:
          - if !<[entity].exists>:
            - flag server region_five_name.fireball_entities:<-:<[entity]>
            - foreach next
          - adjust <[entity]> velocity:<player.location.sub[<[entity].location>].div[<[fireball_speed_magnitude]>]>
          - wait 5t

    after player exits region_five_name:
      - flag server region_five_name..players:<-:<player>
      - if !<server.has_flag[region_five_name.players]>:
        - remove <server.flag[region_five_name.fireball_entities].filter[exists]>
        - flag server region_five_name:!

# @ #10 I also need a boundary that will force teleport the player up if they land on it on the "fog" below
    after player enters region_six_name:
      - run fancy_painful_teleport defmap:teleport=fog_teleport_respawn

# @ 11 I need this door to open when a player is close to it
    after player enters region_seven_name:
      - run open_gate_task defmap:door=two

# @ #12 I need a system that will give the player the book that is currently on the lectern when they read it, and remove it when they exit the room*
#13 I also need a system that will teleport the player to the start of the room if they step on an incorrect pressure plate
  #- The solution is on the ceiling in wool

    after player right clicks lectern:
      - if <player.has_flag[region_six.has_book]>:
        - stop
      - flag player region_six.has_book
      - give <context.location.inventory.list_contents.first>
    after player exits region_six:
      - if <player.inventory.contains_item[written_book]>:
        - take item:written_book

    # ! bad pressure plates would just be easily defined by flagging them via `/ex flag <player.cursor_on> bad_pressure_plate`
    after player stands on *_pressure_plate:
      - if <context.location.has_flag[bad_pressure_plate]>:
        - run fancy_painful_teleport defmap:teleport=region_six_teleport_respawn

# @ #14 I need this door to open when the player has finished the puzzle
    after player enters region_eight_name:
      - run open_gate_task defmap:door=three

# @ #15 I need a transition to the large hallway to the left of this block
    after player enters region_nine_name:
      - run fancy_teleport defmap:teleport=room_four_name

#17 Npc named "Vel", what he says is tbd, need him to vanish when he finishes talking as if he died
    # @ see below maybe
    on npc death:
      - if <npc.script.name.if_null[invalid]> == vel:
        - determine "well, i'm pretty sure he was going to say Behr was the coolest ever but he died a very spontaneous and what seemed to be quick death."

#18 Door that needs to be opened *after* the npc vanishes
      - wait 3s
      - run open_gate_task defmap:door=four

#19 - No block - The entire hall is where the boss fight will take place

# misc:
    after reload scripts:
      - define generic_location <location[0,0,0,<server.worlds.first.name>]>
      - foreach region_one_name|region_two_name|yellow_buttons|red_buttons|blue_buttons|gray_buttons|region_four_name|region_five_name|region_six_name|region_seven_name|region_eight_name|region_nine_name as:area:
        - if !<cuboid[<[area]>].exists>:
          - note <[generic_location].to_cuboid[<[generic_location]>]> as:<[area]>

fancy_teleport:
  type: task
  definitions: location_name
  script:
  # TODO: This title insertion / fade depends on: - resource pack data and structure
    - title title:<&font[fade:black]><&chr[0004]><&chr[F801]><&chr[0004]> fade_in:5t stay:0s fade_out:1s
    - wait 5t
    - teleport <location[<[location_name]>]>

fancy_painful_teleport:
  type: task
  definitions: location_name
  script:
  # TODO: This title insertion / fade depends on: - resource pack data and structure
    - animate <player> animation:hurt
    - title title:<&font[fade:black]><&chr[0004]><&chr[F801]><&chr[0004]> fade_in:3t stay:0s fade_out:1s
    - wait 3t
    - teleport <location[<[location_name]>]>

vel:
  type: assignment
  actions:
    on assignment:
      - trigger name:click state:true
    on click:
      - narrate "hey, i don't know what i was about to say but it's now my time to die, so. bye i guess. Make sure you tell Behr they're pretty and that i think they're the coo-"
      - wait 2s
      - repeat 10:
        - animate <npc> animation:hurt_explosion
        - wait 3t
      - adjust <npc> health:0

testing_fancy_painful_teleport:
  type: world
  events:
    on player enters testing_fancy_painful_teleport_region:
      - run fancy_painful_teleport def:<server.flag[testing_fancy_painful_teleport_back_location]>

open_gate_task:
  type: task
  definitions: door
  script:
    - narrate "Door will open at location: <[door]>"
