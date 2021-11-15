# path_flag: The flag containing the path. It should be a list of locations that the platform will move to. When it reaches the end of the list, it plays the list backwards
# server_flag: The flag that controls when the platform stops moving. If the server doesn't have this flag, the playform will despawn immediately.
# everything after the two main defs becomes a part building the elevator design. The format should look something like this:
# dirt;1,0,0|grass_block;0,0,0|dirt;-1,0,0
# pass in the material's name, and then three coords; xyz relative to the the first location in the path_flag.
moving_platform:
    type: task
    debug: false
    definitions: path_flag|server_flag
    script:
        - define design    <queue.definition_map.get[raw_context].get[3].to[last]>
        - define materials <[design].get_sub_items[1].split_by[;]>
        - define path      <server.flag[path.<[path_flag]>]>
        - define old_pos <[path].first>
        - define stands <list>
        - define blocks <list>
        #Split the trailing definitions and get the relative offsets (0,0,1|0,0,0|0,0,-1...)
        - foreach <[design].get_sub_items[2].split_by[;]>:
            #Spawn a falling_block in, using the material from the trailing definitions, at the position of the first location
            #from the path flag + the offset. Put all the entities into the "blocks" def, used to remove all entities. Put all
            #armor stands in the "stands" def. Used to move the blocks.
            - run lib_spawn_falling_block def:<[materials].get[<[loop_index]>]>|<[old_pos].add[<[value]>]> save:block
            - define blocks:|:<entry[block].created_queue.determination.first>
            - define stands:->:<entry[block].created_queue.determination.first.first>
        #While the server.flag exists...
        - while <server.flag[platforms.<[server_flag]>].exists>:
            #foreach location in the path def...
            - foreach <[path]> as:new_pos:
                #Stop loop if we are resetting to origin, or if the flag no longer exists...
                - if <server.flag[platforms.<[server_flag]>.reset]> || !<server.flag[platforms.<[server_flag]>].exists>:
                    # If we are resetting rather than cleaning up, we are getting the reset_path, which is a subset of the
                    # regular path. A regular path includes both forward and backwards, so we check to see if we are over the
                    # halfway mark, and if we are, subtrack half the size of the path. Because basically, if our path was 10 long,
                    # point 2 and point 7 will either be the same point, or the two points next to each other. And we don't
                    # want, when we're reversing, to first move away from the origin. So no matter where in the cycle we are,
                    # this should get the path that goes straight back to the origin.
                    - define reset_path <[path].get[1].to[<[loop_index].is_more_than[<[path].size.mul[0.5]>].if_true[<[loop_index].sub[<[path].size.mul[0.5]>]>].if_false[<[loop_index]>]>].reverse>
                    - foreach stop
                - inject moving_platform path:move_platform
            # If we are resetting, we travel the reset path. We don't need to check if we are resetting during the reset path.
            # in practice this means even if we are only resetting for a tick, we have to go all the way back to the origin
            # before we start moving again.
            - if <server.flag[platforms.<[server_flag]>.reset]>:
                - foreach <[reset_path]> as:new_pos:
                    #Stop loop if we if the flag no longer exists...
                    - foreach stop if:<server.flag[platforms.<[server_flag]>].exists.not>
                    - inject moving_platform path:move_platform
        #When the while loop finishes, remove all entities forming the platform. This task should run when needed, and finish
        #when not, for example, spawn the platforms in when a player is in the dungeon, and despawned when they are not.
        - remove <[blocks]>
    move_platform:
        #if the stands are no longer spawned it, remove the flag, and let cleanup happen naturally
        - flag server platforms.<[server_flag]>:! if:<[stands].filter[is_spawned].size.equals[<[stands].size>].not>
        # Stop the platform if moving is false. We also stop waiting if the flag dissapears, which means it will still clean
        # up even if we are paused.
        - waituntil <server.flag[platforms.<[server_flag]>.moving].or[<server.flag[platforms.<[server_flag]>].exists.not>]>
        #Get the movement vector from the old_position and new_position
        - define direction <[new_pos].sub[<[old_pos]>]>
        - define old_pos <[new_pos]>
        #For all the stands...
        - foreach <[stands]> as:stand:
            #Get any player standing on top, and teleport the stand in the direction vector calculated from the path
            - define players:|:<[stand].location.proc[lib_center_on_head].up.find.players.within[1]>
            - teleport <[stand]> <[stand].location.add[<[direction]>]>
        #For all players found standing on the platform...
        - foreach <[players].deduplicate> as:player:
            #If the platform is moving up at all, teleport the player, otherwise you can just adjust their velocity
            #to keep them on the platform.
            - if <[direction].y> > 0:
                - teleport <[player]> <[player].location.add[<[direction]>]>
            - else:
                - adjust <[player]> velocity:<[player].velocity.add[<[direction].mul[0.45]>]>
        - define players:!
        - wait 1t

# make a path
# ease: Ease type (sine, quad, cubic, quart, quint, exp, circ, back, elastic, bounce)
# direction: ease direction (in, out, inout)
# start: A location where the path starts
# end: The location where the path ends
# time: Time in ticks, it should take to get from point A to point B
# flag_name: Flags the server with the path so it can referenced in other scripts. All paths are saved to path.<[flag_name]>
make_path:
    type: task
    debug: false
    definitions: ease|direction|start|end|time|flag_name
    script:
        - define start <[start].add[-0.01,-1.25,0.01]>
        - define end   <[end].add[-0.01,-1.25,0.01]>
        - define x_delta <[end].x.sub[<[start].x>]>
        - define y_delta <[end].y.sub[<[start].y>]>
        - define z_delta <[end].z.sub[<[start].z>]>
        - repeat <[time]>:
            - define path:->:<[start].add[<[value].div[<[time].add[1]>].proc[lib_ease].context[<[ease]>|<[direction]>|0|<[x_delta]>]>,<[value].div[<[time].add[1]>].proc[lib_ease].context[<[ease]>|<[direction]>|0|<[y_delta]>]>,<[value].div[<[time].add[1]>].proc[lib_ease].context[<[ease]>|<[direction]>|0|<[z_delta]>]>]>
        - define path:|:<[path].reverse>
        - flag server path.<[flag_name]>:<[path]>