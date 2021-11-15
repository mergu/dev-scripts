block_carrying_events:
    type: world
    events:
        on player right clicks shulker entity_flagged:carryable:
            #put carryable above head, remove the actual shulker block so it doesn't prevent movement
            - ratelimit player 1t
            - if !<player.has_flag[carrying]>:
                - flag player carrying
                - define stand <context.entity.vehicle>
                - remove <[stand].passengers.filter[is_mob]>
                - mount <[stand]>|<player>
        on player right clicks block:
            - inject block_carrying_events path:handle_block
        on player right clicks armor_stand entity_flagged:carryable:
            #When the block is above you, the armor stand gets in the way of clicking 99% of the time, so we actually have to
            #do on click armor stand and some raytrace logic to work around that.
            - inject block_carrying_events path:handle_block
    handle_block:
        - if <player.has_flag[carrying]>:
            # Get location due to armor stand bounding box shenanigans...
            - define location <player.cursor_on[4.5].center>
            - flag player carrying:!
            - define stand <player.passenger>
            # Unmount stand, readd the shulker...
            - mount cancel <[stand]>
            - adjust <[stand]> passengers:<[stand].passenger>|lib_entity_shulker
            - define is_pressure_plate <[location].material.name.equals[light_weighted_pressure_plate]>
            # if we click on the ground, put it one block above the block we clicked. in the case of a pressure plate
            # we actually want to shift it down into the pressure plate, since the pressure plate is "taking up" that blocks space
            - define location <[location].down[<[is_pressure_plate].if_true[1].if_false[0.25]>]>
            - teleport <[stand]> <[location]>
            - playsound <[location]> sound:BLOCK_COPPER_PLACE pitch:<proc[lib_random_pitch]> sound_category:BLOCKS
            # Play animation for when the block is placed on a pressure plate.
            - if <[is_pressure_plate]>:
                - ~run make_path def:circ|inout|<[location].up[1.25]>|<[location].up[1.75]>|15|temp save:path_a
                - ~run make_path def:bounce|out|<[location].up[1.75]>|<[location].up[0.95]>|10|temp save:path_b
                - define path_a <entry[path_a].created_queue.determination.first>
                - define path_b <entry[path_b].created_queue.determination.first>
                # Only get half of each path, since normally a path is from A -> B -> A
                - define path_a <[path_a].get[1].to[<[path_a].size.mul[0.5]>]>
                - define path_b <[path_b].get[1].to[<[path_b].size.mul[0.5]>]>
                - wait 10t
                - foreach <[path_a]>:
                    - teleport <[stand]> <[value]>
                    - wait 1t
                - wait 5t
                - foreach <[path_b]>:
                    - teleport <[stand]> <[value]>
                    - wait 1t
                # Cluh clunk
                - playsound <[location]> sound:BLOCK_IRON_DOOR_CLOSE pitch:0.5

spawn_carryable_block:
    type: task
    definitions: material|location
    script:
        - run lib_spawn_falling_block def:<[material]>|<[location].add[-0.01,-1.25,0.01]> save:block
        - define entities <entry[block].created_queue.determination.last>
        - flag <[entities]> carryable
        # Play particles at the blocks location. They stop when the entity despawns. Despawn all entities in the
        # area with a "carryable" flag for clean up.
        - while <[entities].first.is_spawned>:
            - playeffect effect:wax_off at:<[entities].first.location.up[1.25]> quantity:15 offset:0.45,0.45,0.45
            - repeat 10:
                - wait 1t
                - while stop if:<[entities].first.is_spawned.not>
