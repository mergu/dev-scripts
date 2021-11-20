falling_chunks:
    type: task
    debug: false
    definitions: location
    script:
        # falling_blocks have a weird offset...
        - define location <[location].center.sub[0,0.5,0]>
        # build chunk...
        - define design <queue.definition_map.get[raw_context].get[2].to[last]>
        - define materials <[design].get_sub_items[1].split_by[;]>
        - foreach <[design].get_sub_items[2].split_by[;]> as:offset:
            - spawn falling_block[fallingblock_type=<[materials].get[<[loop_index]>]>] <[location].add[<[offset]>]> persistent save:block
            - define blocks:->:<entry[block].spawned_entity>
        - adjust <[blocks]> gravity:false
        # get lowest blocks in the chunk, then check to see if it's supported, and if not,
        # remove it from the list. One, because we don't need to keep checking blocks we
        # know aren't supported anymore (because you can't build in the dungeon), but
        # also because once the list is empty, we know the platform is no longer suspended.
        - define lowest <[blocks].filter[location.y.equals[<[blocks].sort_by_number[y].first.location.y>]].filter[location.center.down.material.is_solid]>
        # while it should be suspended...
        - while <[lowest].size> > 0:
            # filter by supported...
            - define lowest <[lowest].filter[location.center.down.material.is_solid]>
            - wait 5t
        - adjust <[blocks]> gravity:true
