gen_y_slice:
  type: procedure
  definitions: blocks|y
  script:
  - determine <[blocks].filter_tag[<[filter_value].y.equals[<[y]>]>]>

gen_flood_slice_list:
  type: task
  definitions: name|c|l
  script:
  # Blocks in the cuboid that support waterlogs
  - narrate "<gray>Finding waterloggables..."
  - define wlogs <[c].blocks.filter_tag[<[filter_value].material.supports[waterlogged]>]>
  # Slice the flood fill into y levels, exclude them in the next iteration
  # Do the same for waterlog y levels
  - define slices <list>
  - define wlog_slices <list>
  # Repeat for the height of the cuboid + 1, from the bottom y
  - define lcount 0
  - repeat <[c].max.y.sub[<[c].min.y>].add[1]> from:<[c].min.y> as:y:
    # Cuboid at y slice (for big structures)
    - define cuboid <[c].with_min[<[c].min.with_y[<[y]>]>].with_max[<[c].max.with_y[<[y]>]>]>
    # Take the flood fill at this cuboid level
    - narrate "<gray>Taking flood fill..."
    - define flood <[l].with_y[<[l].y.add[<[lcount]>]>].flood_fill[<[cuboid]>]>
    - define lcount:+:1

    - narrate "<gray>Generating at Y<&co><[y]>..."
    # Main slices - already accounts for y
    - define slices:->:<[flood]>
    # Waterlog slices
    - define wslice <[wlogs].proc[gen_y_slice].context[<[y]>]>
    - define wlog_slices:->:<[wslice]>
    - define wlogs <[wlogs].exclude[<[wslice]>]>

  - flag server flood_sets.<[name]>.slices:<[slices]>
  - flag server flood_sets.<[name]>.waterlogs:<[wlog_slices]>

debug_flood_slices:
  type: task
  definitions: name
  script:
  - define slices <server.flag[flood_sets.<[name]>.slices]>
  - foreach <[slices]> as:slice:
    - debugblock <[slice]> d:40t
    - wait 10t

flood_cuboid_level:
  type: task
  definitions: slices|waterlogs|y|down
  script:
  # If zero (or less by a mistake), reset all the water
  - if <[y]> <= 0:
    - modifyblock <[slices].first> air
    - adjustblock <[waterlogs].first> waterlogged:false
    - stop
  # If going down, modify the upper slice to air, and end
  - if <[down]>:
    - modifyblock <[slices].get[<[y].add[1]>]> air
    - adjustblock <[waterlogs].get[<[y].add[1]>]> waterlogged:false
    - stop
  # Modify the requested slice to be water
  - modifyblock <[slices].get[<[y]>]> water
  - adjustblock <[waterlogs].get[<[y]>]> waterlogged:true

flood_cuboid:
  type: task
  definitions: name|y|interval
  script:
  - if !<server.has_flag[flood_sets.<[name]>]>:
    - debug error "Invalid flood set '<aqua><[name]><&r>'"
    - stop

  - define slices <server.flag[flood_sets.<[name]>.slices]>
  - define waterlogs <server.flag[flood_sets.<[name]>.waterlogs]>
  # Assume 0 level when flooding for first time
  - define level <server.flag[flood_sets.<[name]>.level].if_null[0]>
  - define diff <[y].sub[<[level]>]>
  # We need to repeat for the difference no matter negative/positive
  - repeat <[diff].abs> as:l:
    # Determine if down or up, then find level
    - if <[diff]> > 0:
      - define new_y <[level].add[<[l]>]>
      - define down false
    - else:
      - define new_y <[level].sub[<[l]>]>
      - define down true
    # Flood the level accordingly
    - run flood_cuboid_level def.slices:<[slices]> def.waterlogs:<[waterlogs]> def.y:<[new_y]> def.down:<[down]>
    - wait <[interval]>
    - repeat next
  # For the next flood, set the level flag
  - flag server flood_sets.<[name]>.level:<[y]>