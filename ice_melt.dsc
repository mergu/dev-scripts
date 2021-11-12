ice_melt:
  type: world
  events:
    on arrow hits *ice in:area_flagged:ice_melt:
    - stop if:<context.projectile.on_fire.not>
    - remove <context.projectile>
    # Take flood fill with arbitrary radius
    - define ice <context.location.flood_fill[15].types[*ice]>
    # Save the locations so they can be restored
    - flag server ice_restore:|:<[ice]>
    # Break random blocks until the ice is gone
    - while !<[ice].is_empty>:
      # Take 4 random ice blocks, remove them from main list
      - define blocks <[ice].random[4]>
      - define ice <[ice].exclude[<[blocks]>]>
      - modifyblock <[blocks]> air
      # Play sounds/effects - thanks DCaff
      - playsound <context.location> sound:block_lava_extinguish volume:2 pitch:<util.random.decimal[1.6].to[1.9]>
      - playeffect effect:cloud at:<[blocks]> quantity:<util.random.int[1].to[5]> velocity:0.2,0.5,0.2 visibility:100
      - wait 3t
    # Stop ice from melting via light
    on *ice fades in:area_flagged:ice_melt:
    - determine cancelled

ice_restore:
  type: task
  script:
  # Restore melted areas to random ice blocks
  - modifyblock <server.flag[ice_restore]> ice|packed_ice|blue_ice
  # Reset list
  - flag server ice_restore:<list>