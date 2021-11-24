burning_leaves:
    type: world
    debug: false
    events:
        on player shoots *_leaves in:box:
            - define cuboid <cuboid[box]>
            - inject burning_leaves path:burn_task
    burn_task:
        # if arrow is on fire...
        - if <context.projectile.on_fire>:
            # get all leaves in the cuboid, flagged with the burn group flag that matches the impact's burn group
            # (a shrine might have more than one leaf burning puzzle, so we only want to get the one), then remove
            # all flagged leaf blocks, since they've already been ignited (so we don't try to ignite twice), then
            # sort by distance.
            - define leaves <[cuboid].blocks_flagged[burn_group].filter[has_flag[ignited].not].filter[flag[burn_group].equals[<context.location.flag[burn_group]>]].proc[lib_sort_by_distance_to].context[<context.location>]>
            # Flags all leaves so they don't get double ignited...
            - flag <[leaves]> ignited expire:1m
            # run the modifyblock, but with varying levels of delay, based off of where in the loop it is.
            # That will make it so the fire spreads out from the impact location. Also, pass in a def of the
            # air block, which is calculated by finding which face isn't exposed by air, subtracting that location
            # from the original location, which gives a vector for the face opposite of that location, then using
            # that vector to get the location of where the fire should be
            - foreach <[leaves]>:
                - run burning_leaves path:remove def.leaf_block:<[value]> def.air_block:<[value].add[<[value].sub[<[value].proc[lib_surrounding_blocks].filter[material.advanced_matches[air].not].first>]>]> delay:<util.random.int[<[loop_index].mul[4]>].to[<[loop_index].mul[8]>]>t
    remove:
        - modifyblock <[air_block]> fire[faces=<[leaf_block].sub[<[air_block]>].vector_to_face>]
        - wait <util.random.int[10].to[15]>t
        - modifyblock <[leaf_block]> air
