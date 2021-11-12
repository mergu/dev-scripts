flooder:
  type: item
  material: bucket
  display name: <blue>Flooder
  enchantments:
  - aqua_affinity:1
  mechanisms:
    hides: ENCHANTS
  lore:
  - <aqua>Left-click to start a new set
  - <aqua>Shift-left-click to view available sets

flooder_function:
  type: world
  events:
    on player left clicks block with:flooder:
    - determine passively cancelled

    - if <player.is_sneaking>:
      - narrate "<gold><underline>Flood slice sets"
      - foreach <server.flag[flood_sets].keys> as:set:
        - narrate "<dark_gray>- <gray><[set].before[_flood_slices]>"
      - stop

    - if <player.has_flag[flooder_selection]>:
      - narrate "<red>Flood selection cancelled."
      - flag <player> flooder_selection:!
      - stop

    - if !<player.has_flag[ctool_selection]>:
      - narrate "<red>No cuboid selected! Click <yellow><underline><element[HERE].on_click[/ctool]><&r> <red>to get the Cuboid Selector Tool."
      - stop

    - define cuboid <player.flag[ctool_selection]>
    - debugblock <[cuboid].outline>

    - define yr <player.location.y.round_down>
    - narrate "<green>Displaying outline of selected cuboid."
    - narrate "<green>Your selection will generate to <gold>Y<&co><[yr]> <gray>(<[yr].sub[<[cuboid].min.y>]> above min)<green>."
    - narrate "<yellow>Type in chat to name this flood group or left-click again to cancel."

    - flag <player> flooder_selection.cuboid:<[cuboid]>
    - flag <player> flooder_selection.loc:<player.location>

    on player chats flagged:flooder_selection:
    - determine passively cancelled
    - define name <context.message.replace_text[<&sp>].with[_]>
    - run gen_flood_slice_list def:<[name]>|<player.flag[flooder_selection.cuboid]>|<player.flag[flooder_selection.loc]>

    - clickable debug_flood_slices def:<[name]> save:debug
    - narrate "<green>Generated flood slices."
    - narrate "<green>Click <yellow><underline><element[HERE].on_click[<entry[debug].command>]><&r> <green>to view them in order."

    - flag <player> flooder_selection:!