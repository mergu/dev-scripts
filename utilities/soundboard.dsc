soundboard_command:
  type: command
  debug: false
  name: soundboard
  permissions: test
  usage: /soundboard (favorites/page <&lt>#<&gt>/search <&lt>Sound<&gt>/play <&lt>Sound<&gt>)
  description: Plays sounds or opens the Sound Board.
  aliases:
    - sb
  tab complete:
    - define list <list[favorites|page|search|play]>
    - if <context.args.size> == 0:
      - determine <[list]>
    - else if <context.args.size> == 1 && !<context.raw_args.ends_with[<&sp>]>:
      - determine <[list].filter[starts_with[<context.args.last>]]>

    - define sounds <server.sound_types.parse[replace[_].with[<&sp>].to_titlecase.replace[<&sp>].with[_]]>
    - if <context.raw_args.ends_with[<&sp>]>:
      - choose <context.args.first>:
        - case page:
          - determine <util.list_numbers_to[30]>
        - case search Play:
          - determine <[sounds]>
        - default:
          - determine <empty>
    - else if <context.args.size> == 2 && !<context.raw_args.ends_with[<&sp>]>:
      - choose <context.args.first>:
        - case page:
          - determine <util.list_numbers_to[30].filter[starts_with[<context.args.last>]]>
        - case search:
          - determine <[sounds].filter[contains[<context.args.last>]]>
        - case Play:
          - determine <[sounds].filter[starts_with[<context.args.last>]]>
        - default:
          - determine <empty>
  script:
    - choose <context.args.size>:
      - case 0:
        - run soundboard defmap:action=main_menu
      - case 1:
        - choose <context.args.first>:
          - case favorites:
            - run soundboard defmap:action=favorites_menu;page=1
          - default:
            - inject Command_Syntax
      - case 2:
        - choose <context.args.first>:
          - case page:
            - define page <context.args.get[2]>
            - define max_page <server.sound_types.size.div[27]>
            - if <[page]> > 0 && <[page]> < <[max_page]> && !<[page].contains[.]>:
              - run soundboard defmap:action=soundboard_menu;page=<[page]>
            - else:
              - narrate "<&4>I<&c>nvalid <&4>N<&c>umber<&4>. <&6>/<&e>page 1<&6>-<&e><[max_page]>"
          - case search:
            - run soundboard defmap:action=searched_menu;query=<context.args.get[2]>|page=1
            - narrate "<&6>S<&e>howing <&6>R<&e>esults <&6>f<&e>or<&6>: <&a><context.args.get[2]>"
          - case play:
            - if <server.sound_types.contains[<context.args.get[2]>]>:
              - playsound <player> sound:<context.args.get[2]>
            - else:
              - narrate "<&4>I<&c>nvalid <&4>S<&c>ound<&4>."
          - default:
            - inject Command_Syntax
      - default:
        - inject Command_Syntax

sound_handler:
  type: world
  debug: false
  events:
    on player chats flagged:behrry.developmental.search_wait bukkit_priority:lowest priority:-1:
      - determine passively cancelled
      - flag player behrry.developmental.search_wait:!
      - flag player behrry.developmental.searchedsounds
      - narrate "<&6>S<&e>howing <&6>R<&e>esults <&6>f<&e>or<&6>: <&a><context.message>"
      - run soundboard defmap:action=searched_menu;query=<context.message>;page=1


soundboard:
  type: task
  debug: false
  definitions: click|slot
  script:
    - if !<[action].exists>:
      - define action main_menu

    - choose <[action]>:
      - case main_menu:
        - playsound sound:ENTITY_ENDER_EYE_DEATH <player> pitch:<util.random.decimal[1.8].to[2]>
        - define size 9
        - define display "<&6>S<&e>ound <&6>B<&e>oard"
        - define lore "<list[<empty>|<&7>View & Play sounds]>"
        - define flags <map[menu=soundboard;action=soundboard_menu;page=1]>
        - define skin <script[letters].data_key[misc.note]>
        - define soft_menu:|:blank|blank|<item[action_item].with[material=player_head;display=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>
        - inject soundboard.favorites_button
        - inject soundboard.search_button
        - define soft_menu:|:<[favorites]>|blank|<[search]>|blank|blank|blank

        - define inventory <inventory[generic[title=<&2>Sound<&sp>Menu;size=<[size]>;contents=<[soft_menu]>]]>
        - inventory open d:<[inventory]>

      - case searched_Menu:
        - playsound sound:ENTITY_ENDER_EYE_DEATH <player> pitch:<util.random.decimal[1.8].to[2]>
        - inject soundboard.main_menu_button
        - define query <[query]>
        - define sounds <server.sound_types.filter[contains[<[query]>]]>
        - if <[sounds].is_empty>:
          - narrate "<&4>N<&c>o <&4>R<&c>esults."
          - run soundboard defmap:action=main_menu
          - stop
        - define inventory_size <[sounds].size.div[9].round_up.min[4].max[2].mul[9]>
        - define index <proc[page_numbers].context[<[page]>|<[inventory_size].sub[9]>]>
        - define sound_selection <[sounds].get[<[index].first>].to[<[index].get[2]>]>
        - define max_page <[sounds].size.div[9].round_up>
        - inject soundboard.sound_buttons
        - define active_menu searched_Menu
        - inject soundboard.page_buttons
        - inject soundboard.favorites_button
        - inject soundboard.stop_sound_button
        - inject soundboard.search_button

        - define inventory "<inventory[generic[size=<[inventory_size]>;title=<[page]>/<[max_page]> sounds w/:<[query]>]]>"
        - if <element[9].sub[<element[<[sounds].size>].mod[9]>]> != 0:
          - repeat <element[9].sub[<element[<[sounds].size>].mod[9]>]>:
            - define items:->:<item[blank]>

        - define soft_menu:|:<[left].first>|<[left].get[2]>|<[main_menu]>|<[favorites]>|<[stop_sound]>|<[search]>|<item[blank]>|<[right].first>|<[right].get[2]>

        - inventory set d:<[inventory]> o:<[items].parse[with_flag[map:<map[query=<[query]>]>]]>
        - inventory set d:<[inventory]> o:<[soft_menu].parse[with_flag[map:<map[query=<[query]>]>]]> slot:<[inventory_size].sub[8]>
        - inventory open d:<[inventory]>

      - case favorites_menu:
        - playsound sound:ENTITY_ENDER_EYE_DEATH <player> pitch:<util.random.decimal[1.8].to[2]>
        - inject soundboard.main_menu_button
        - if !<player.has_flag[behrry.developmental.favorite_sounds]>:
          - define soft_menu:|:blank|blank|<[main_menu]>|blank|blank|blank|blank|blank|blank
          - define inventory_size 9
          - define inventory <inventory[generic[size=9]]>
        - else:
          - define sounds <player.flag[behrry.developmental.favorite_sounds]>
          - define inventory_size <[sounds].size.div[9].round_up.min[4].max[2].mul[9]>
          - define index <proc[page_numbers].context[<[page]>|<[inventory_size].sub[9]>]>
          - define sound_selection <[sounds].get[<[index].first>].to[<[index].get[2]>]>
          - define max_page <[sounds].size.div[9].round_up>
          - inject soundboard.sound_buttons
          - define active_menu favoritesMenu
          - inject soundboard.page_buttons
          - inject soundboard.stop_sound_button
          - define inventory "<inventory[generic[size=<[inventory_size]>;title=Favorites <[page]>/<[max_page]>]]>"
          - if <element[9].sub[<element[<[sounds].size>].mod[9]>]> != 0:
            - repeat <element[9].sub[<element[<[sounds].size>].mod[9]>]>:
              - define items:->:blank

          - define soft_menu:|:<[left].first>|<[left].get[2]>|<[main_menu]>|blank|<[stop_sound]>|blank|blank|<[right].first>|<[right].get[2]>

          - inventory set d:<[inventory]> o:<[items]>
        - inventory set d:<[inventory]> o:<[soft_menu]> slot:<[inventory_size].sub[8]>
        - inventory open d:<[inventory]>


      - case soundboard_menu:
        - playsound sound:ENTITY_ENDER_EYE_DEATH <player> pitch:<util.random.decimal[1.8].to[2]>
        - define index <proc[page_numbers].context[<[page]>|27]>
        - define sounds <server.sound_types>
        - define sound_selection <[sounds].get[<[index].first>].to[<[index].get[2]>]>
        - define max_page <[sounds].size.div[27].round_down>
        - inject soundboard.sound_buttons
        - define active_menu soundboard_menu
        - inject soundboard.page_buttons
        - inject soundboard.main_menu_button
        - inject soundboard.favorites_button
        - inject soundboard.stop_sound_button
        - inject soundboard.search_button

        - define soft_menu:|:<[left].first>|<[left].get[2]>|<[main_menu]>|<[favorites]>|<[stop_sound]>|<[search]>|blank|<[right].first>|<[right].get[2]>

        - define title "<&2>Sounds <&6><[page]><&4>/<&6><[max_page]>"
        - define inventory <inventory[generic[size=36;title=<[title]>]]>
        - inventory set d:<[inventory]> o:<[items]>
        - inventory set d:<[inventory]> o:<[soft_menu]> slot:28
        - inventory open d:<[inventory]>

      - case play_sound:
        - choose <[click]>:
          - case drop:
            - if <player.has_flag[behrry.developmental.favorite_sounds]>:
              - if <player.flag[behrry.developmental.favorite_sounds].contains[<[sound]>]>:
                - narrate "<&c>This sound is already in your favorites."
                - stop
            - define old_material <player.open_inventory.slot[<[slot]>].material.name>
            - if <[old_material]> == white_stained_glass:
              - inventory adjust d:<player.open_inventory> slot:<[slot]> material:lime_stained_glass
            - else:
              - inventory adjust d:<player.open_inventory> slot:<[slot]> enchantments:silk_touch,1
            - inventory adjust d:<player.open_inventory> slot:<[slot]> "lore:<list[<empty>|<&3>Ctrl<&b>+<&3>Q<&b>:<&7> Remove from favorites|<&3>Click<&b>: <&7>Play sound|<&3>Shift<&b>+<&3>Click<&b>: <&7>Script Copy]>"
            - playsound <player> sound:BLOCK_note_BLOCK_BASS pitch:2
            - narrate "<&6>[<&e><[sound].replace[_].with[ ].to_titlecase><&6>] <&2>a<&a>dded <&2>t<&a>o <&2>f<&a>avorites"
            - flag player behrry.developmental.favorite_sounds:->:<[sound]>

          - case control_drop:
            - if <player.has_flag[behrry.developmental.favorite_sounds]>:
              - if <player.flag[behrry.developmental.favorite_sounds].contains[<[sound]>]>:
                - flag player behrry.developmental.favorite_sounds:<-:<[sound]>
                - define old_material <player.open_inventory.slot[<[slot]>].material.name>
                - if <[old_material]> == lime_stained_glass:
                  - inventory adjust d:<player.open_inventory> slot:<[slot]> material:white_stained_glass
                - else:
                  - inventory adjust d:<player.open_inventory> slot:<[slot]> remove_enchantments
                - inventory adjust d:<player.open_inventory> slot:<[slot]> "lore:<list[<empty>|<&3>Q Key<&b>:<&7> Add to favorites|<&3>Click<&b>: <&7>Play sound|<&3>Shift<&b>+<&3>Click<&b>: <&7>Script Copy]>"
                - playsound <player> sound:BLOCK_note_BLOCK_BASS
                - narrate "<&6>[<&e><[sound].replace[_].with[ ].to_titlecase><&6>] <&4>R<&c>emoved <&4>f<&c>rom <&4>f<&c>avorites."

          - case shift_left shift_right:
            - define Insert "- playsound sound:<[sound]> <&lt>player<&gt>"
            - define Hover "<&2>Shift Click to Insert<&2>:<&nl><&e><[Insert]>"
            - define Text <&e><[sound]>
            - playsound sound:ENTITY_ENDER_EYE_DEATH <player> pitch:0
            - narrate "<&a>Shift Click for Copy<&2>: <proc[msg_hover_ins].context[<[Hover]>|<[Text]>|<[Insert]>]>"
          - default:
            - playsound <player> sound:<[sound]>

      - case stop_sound:
        - actionbar "<&4>sounds Stopped"
        - execute as_op "stop_sound <player.name> master" silent

      - case search:
        - inventory close
        - flag player behrry.developmental.search_wait duration:30s
        - while <player.has_flag[behrry.developmental.search_wait]> && <player.is_online>:
          - title "subtitle:<&2>T<&a>ype <&2>S<&a>ound <&2>S<&a>earch" fade_in:0t
          - actionbar '<&4>"<&c>stop<&4>"<&7> to cancel<&4><element[.].repeat[<[Loop_index].mod[3]>]>'
          - wait 1s

  page_buttons:
    - if <[page]> == 1:
      - define left <list[<item[blank]>|<item[blank]>]>
    - else:
      - define display "<&6><&chr[25c0]><&sp> [<&e>Previous<&6>]"
      - define lore "<list[<empty>|<&7>Change Page]>"
      - define flags <map[menu=soundboard;action=<[active_menu]>;page=<[page].sub[1]>]>
      - define skin <script[letters].data_key[misc.left]>
      - define previous <item[action_item].with[material=player_head;display_name=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>
      - if <[page].sub[1]> == 1:
        - define left <list[<item[blank]>|<[previous]>]>
      - else:
        - define display "<&6><&chr[25c0]><&sp> [<&e>First<&6>]"
        - define flags <map[menu=soundboard;action=<[active_menu]>;page=1]>
        - define skin <script[letters].data_key[misc.first]>
        - define first <item[action_item].with[material=player_head;display_name=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>
        - define left <list[<[first]>|<[previous]>]>

    - if <[page]> == <[max_page]>:
      - define right <list[<item[blank]>|<item[blank]>]>
    - else:
      - define display "<&6>[<&e>Next<&6>] <&chr[25b6]>"
      - define lore "<list[<empty>|<&7>Change page]>"
      - define flags <map[menu=soundboard;action=<[active_menu]>;page=<[page].add[1]>]>
      - define skin <script[letters].data_key[misc.right]>
      - define next <item[action_item].with[material=player_head;display_name=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>

      - if <[page].add[1]> == <[max_page]>:
        - define right <list[<item[blank]>|<[Next]>]>
      - else:
        - define display "<&6>[<&e>Last<&6>] <&chr[25b6]>"
        - define flags <map[menu=soundboard;action=<[active_menu]>;page=<[max_page]>]>
        - define skin <script[letters].data_key[misc.last]>
        - define last <item[action_item].with[material=player_head;display_name=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>
        - define right <list[<[Next]>|<[last]>]>

  main_menu_button:
    - define display "<&6>M<&e>ain <&6>M<&e>enu"
    - define lore "<list[<empty>|<&7>Return to Main Menu]>"
    - define flags <map[menu=soundboard;action=main_menu;page=1]>
    - define skin <script[letters].data_key[misc.note]>
    - define main_menu <item[action_item].with[material=player_head;display_name=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>

  favorites_button:
    - define display "<&d><&l><&chr[272F]> <&5>F<&d>avorites"
    - define lore "<list[<empty>|<&7>Show favorites]>"
    - define flags <map[menu=soundboard;action=favorites_menu;page=1]>
    - define skin <script[letters].data_key[misc.star]>
    - define favorites <item[action_item].with[material=player_head;display_name=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>

  sound_buttons:
    - foreach <[sound_selection]> as:Sound:
      - define item <item[action_item].with[material=<[sound].proc[soundgui_itemproc]>]>
      - if <player.flag[behrry.developmental.favorite_sounds].contains[<[sound]>]||false>:
        #- define material lime_Stained_Glass
        - define lore "<list[<empty>|<&3>Ctrl<&b>+<&3>Q<&b>:<&7> Remove from favorites]>"
        - define item <[item].with[enchantments=silk_touch,1;]>
      - else:
        #- define material white_stained_glass
        - define lore "<list[<empty>|<&3>Q Key<&b>:<&7> Add to favorites]>"
      - define display <&e><[sound].replace[_].with[<&sp>].to_titlecase>
      - define lore "<[lore].include[<&3>Click<&b>: <&7>Play sound|<&3>Shift<&b>+<&3>Click<&b>: <&7>Script Copy]>"
      - define flags <map[menu=soundboard;action=play_sound;sound=<[sound]>]>
      - define item <[item].with[display_name=<[display]>;lore=<[lore]>;hides=all].with_flag[map:<[flags]>]>
      - define items:->:<[item]>

  search_button:
    - define display <&6>S<&e>earch
    - define lore "<list[<empty>|<&7>search for sounds]>"
    - define flags <map[menu=soundboard;action=search]>
    - define skin <script[letters].data_key[misc.question]>
    - define search <item[action_item].with[material=player_head;display_name=<[display]>;lore=<[lore]>;skull_skin=a|<[skin]>].with_flag[map:<[flags]>]>

  stop_sound_button:
    - define display "<&4>S<&c>top <&4>S<&c>ounds"
    - define lore "<list[<empty>|<&7>Click to stop all sounds]>"
    - define flags <map[menu=soundboard;action=stop_sound]>
    - define stop_sound <item[action_item].with[material=barrier;display_name=<[display]>;lore=<[lore]>].with_flag[map:<[flags]>]>

page_numbers:
  type: procedure
  definitions: page|size
  debug: false
  script:
    - define i1 <[size].mul[<[page].sub[1]>].add[1]>
    - define i2 <[size].mul[<[page].sub[1]>].add[<[size]>]>
    - determine <list[<[i1]>|<[i2]>]>



letters:
  type: data
  misc:
    question: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMTAzNWM1MjgwMzZiMzg0YzUzYzljOGExYTEyNTY4NWUxNmJmYjM2OWMxOTdjYzlmMDNkZmEzYjgzNWIxYWE1NSJ9fX0=
    note: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZjIyZTQwYjRiZmJjYzA0MzMwNDRkODZkNjc2ODVmMDU2NzAyNTkwNDI3MWQwYTc0OTk2YWZiZTNmOWJlMmMwZiJ9fX0=
    left: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvODFjOTZhNWMzZDEzYzMxOTkxODNlMWJjN2YwODZmNTRjYTJhNjUyNzEyNjMwM2FjOGUyNWQ2M2UxNmI2NGNjZiJ9fX0=
    first: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNjU2YWJiNGM3NGQxMWJiM2VjY2E5ZWQ0MjcwY2RiZGRlZWE5NzA1ODIyZmQzM2I5NGUwNWM0N2MzZWU1NmY5MCJ9fX0=
    right: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMzMzYWU4ZGU3ZWQwNzllMzhkMmM4MmRkNDJiNzRjZmNiZDk0YjM0ODAzNDhkYmI1ZWNkOTNkYThiODEwMTVlMyJ9fX0=
    last: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvOWVmNjY0ZDUwNmU5NzUzNDkzOTE5ODVjMWNkMDcxY2VhN2Q0NjMxNzYzZTVhMmY5MTRmYTQ3MGNjMmJkYTIwYSJ9fX0=
    star: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvOWJlNzIwMzlhNDBmMTAwMmZiYTZhYjFiYjVmN2YwMGQ3MGY1M2I0YjQ4YzJlOWJmMGYxYmVhNzA4MzAwODFhYyJ9fX0=
  characters:
    a: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYTUxN2I0ODI5YjgzMTkyYmQ3MjcxMTI3N2E4ZWZjNDE5NjcxMWU0MTgwYzIyYjNlMmI4MTY2YmVhMWE5ZGUxOSJ9fX0=
    b: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZTExMzFhY2E1ZmNmZTZlNThmNjE2ZmY4YmVmZDAyNzQxNmZlNmI5OGViNWVjNjQyZTAzNWVkODMzOTYwN2JmMCJ9fX0=
    c: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYjJlNTk0ZWExNTQ4NmViMTkyNjFmMjExMWU5NTgzN2FkNmU5YTZiMWQ1NDljNzBlY2ZlN2Y4M2U0MTM2MmI1NyJ9fX0=
    d: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNmIzMWI3OWUzODBkZjMxZDVhNGQ2NDliMWFlOWZjMDIwNjdkN2U5OTQ4NzEyMmQwNGQ2ZDZhYjdmN2RlNjE4MSJ9fX0=
    e: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYjc3MTY1YzlkYjc2M2E5YWNkMTNjMDYyMjBlOTJkM2M5NzBkZmEzNmRhYzU2ZTU5NTdkMDJkMzZmNWE5ZjBiOCJ9fX0=
    f: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvODQ0MmIwNjZlMGU1ZTA5YTZlNmJiOTk4OWNjMjc0NTFmMmJkNzhmYjBkYzcyMTA4YWE5NDBmYzlkYjFjMjRlMSJ9fX0=
    g: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNWMxYThmYzhlYTQ1ZDc0NDMwNzkxNmViNTBkZGNhNWU0MDA2NWEzNDYxYThlNDY5NDkwNDM5ZjllMjRmNGYyNCJ9fX0=
    h: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZGNhMjRhYzhjMTNkMjE3MjBmZjVhY2JmMmVlZTcyNzBjNWIzNjYyMzgzMjA4ZGI5MzcyMWQwNTQ5YjQ1YjllNSJ9fX0=
    i: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvODRiY2M5NTMxYWRlMmUwNjM5YTZhZTAzYzc4YmMwN2ExYTliZTYwZmM2ZjNlM2ZlMzkzNzBmYjU2YzZiNTk3NiJ9fX0=
    j: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZWIwNjBiYmU0ZDZkNjAxNDY5YjQ5ZTEwNTI1M2ViYWUwNTI5MzA5OGE5NzRiNmYyZDU2ODRmOTQxY2E1YTVmYyJ9fX0=
    k: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYjM3ZTUxY2UwZDRjOGVhZGY2NzU5NDFhNDVlMTBiOTI4ZTQzZDIyZWFiNTM5YWM4ODZlZGJmNDBiYjg3ZWMwZiJ9fX0=
    l: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMjA2YmM0MTdlM2MwNmIyMjczNWQ1MzlmOWM2YzhmZDdjMWVmZDE5MjM2ZTJjMzgxNTM0MDUxZDlkNmJlZTgwNCJ9fX0=
    m: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMWQ3MTYyNTZkNzI3YmExZGYxOGY4MjZmMTE5MDUxYzMzYTM5NDIwOWE5NWJlODM3Y2NmNmZhZTllZTZiODcxYiJ9fX0=
    N: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZTcxM2QyNjAxZTM1MjQyZDM1MDE4Y2VjZTNiMzRjNjFiZjUwMDFmNWRiZDc0NjNhNGM1NTg3YWMzNjViM2QxZiJ9fX0=
    o: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMzUzODViMDVlN2FmNTQ2MzViMTBmMDJjZGIwMDQ1NjcyYzkxYzcyNGNmMTY0ZTUxOTNhNGY3YmU3MjkyZmYzMCJ9fX0=
    p: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYjU1MzE0MWFhYmU4OWE4YTU4MDRhMTcyMTMzYjQzZDVkMGVlMDU0OWNjMTlkYjAzODU2ODQwNDNjZmE5NDZhNSJ9fX0=
    q: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYTRkNzQ2ZTdlMzUzNGU3Mjk5NTZmMWEwNDc1NzgzMmZhM2JmOWUyZDE0ZWY2ZDBkYjhkY2ZjNGUyMTUzMjMzOCJ9fX0=
    r: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNTU4MjdmNDVhYWU2NTY4MWJiMjdlM2UwNDY1YWY2MjI4ZWQ2MjkyYmI2M2IwYTc3NjQ1OTYyMjQ3MjdmOGQ4MSJ9fX0=
    s: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZGNkN2QxNGM2ZGI4NDFlNTg2NDUxMWQxNmJhNzY3MGIzZDIwMzgxNDI0NjY5ODFmZWIwNWFmYzZlNWVkYzZjYiJ9fX0=
    t: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYjk0YWMzNmQ5YTZmYmZmMWM1NTg5NDEzODFlNGRjZjU5NWRmODI1OTEzZjZjMzgzZmZhYTcxYjc1NmE4NzVkMyJ9fX0=
    u: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZTgwNjBmYWVjNDUwOTdlZWZhNjgwODhhNWMwNzY1Nzc0MzQyNmUwNDUzZjhiNjZjZjI2YjgzOWMwNDg2NGMwMCJ9fX0=
    v: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZmEzZmE5MTZiNWU1OTE1ZTAyNmI5MWIyNjQ1NDQzOThmZjAyZDFlZWRlNzYzMGJjODE1OGYzYTY2M2NhMDJhZCJ9fX0=
    w: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMjMzMjRkMWZhMDcwY2Y2OThmMmJlNTM5ZDY5ZmY0MzhhYWE2YjFmNDk0YzVlMDEzYzdlZTlkOWMzM2ViODNjMCJ9fX0=
    x: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNTVkNWM3NWY2Njc1ZWRjMjkyZWEzNzg0NjA3Nzk3MGQyMjZmYmQ1MjRlN2ZkNjgwOGYzYTQ3ODFhNTQ5YjA4YyJ9fX0=
    y: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvMWFkMzBlOWUyNTcwNWM1MWI4NDZlNzRlNzc3OTYyM2I2OWMwNzQ0NjQ1ZGEwMDA0ZDRkYjBmZTQ2MzM2ZmY4ZSJ9fX0=
    z: eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvOWEyNGIwZjZjMTg0ZmYxNzM2ODZjN2QxMjhkZjUzNmQxMGI3MjgwZjgwMDg2MzZhNTU0NmYxYzc3NzIzNDM1NCJ9fX0=

action_item:
    type: item
    debug: false
    material: stick
blank:
    type: item
    debug: false
    material: black_stained_glass_pane
    display name: <&f>
    mechanisms:
      custom_model_data: 1
action_item_handler:
  type: world
  debug: false
  events:
    on player clicks action_item in inventory:
      - if <context.item.has_flag[map]> && <context.item.flag[map].contains[menu|action]>:
        - determine passively cancelled
        - run <script[<context.item.flag[map.menu]>]> defmap:<context.item.flag[map]> def:<context.click>|<context.raw_slot>
    on player clicks blank in inventory:
      - determine cancelled


# below script snippets taken from:
# @author Apademide
# @date 2021-09-12
# @denizen-build 1.2.1-b5752-DEV
# @script-version 1.0

soundgui_itemproc:
  type: procedure
  definitions: sound
  debug: false
  script:
  - choose <[sound].before[_]>:
    - case BLOCK:
      - determine <script.data_key[data.BLOCKS.CUSTOMS.<[sound]>].if_null[<script.data_key[data.BLOCKS.MATERIALS].filter_tag[<[FILTER_VALUE].advanced_matches_text[*<[SOUND].after[BLOCK_].before[_]>*]>].first>]>
    - case ENTITY:
      - determine <script.data_key[data.ENTITIES.CUSTOMS.<[sound]>].if_null[<script.data_key[data.ENTITIES.MATERIALS].filter_tag[<[FILTER_VALUE].advanced_matches_text[*<[SOUND].after[ENTITY_].before[_]>*]>].first>]>
    - case ITEM:
      - determine <script.data_key[data.ITEMS.CUSTOMS.<[sound]>].if_null[<script.data_key[data.ITEMS.MATERIALS].filter_tag[<[FILTER_VALUE].advanced_matches_text[*<[SOUND].after[ITEM_].before[_]>*]>].first>]>
    - default:
      - if <material[<[sound]>].is_item.if_null[false]>:
        - determine <[sound]>
      - if <player.flag[behrry.developmental.favorite_sounds].contains[<[sound]>]||false>:
        - determine lime_stained_glass
      - else:
        - determine white_stained_glass

  data:
    ITEMS:
      CUSTOMS:
        ITEM_CROP_PLANT: wheat
        ITEM_FIRECHARGE_USE: fire_charge
        ITEM_FLINTANDSTEEL_USE: flint_and_steel
      MATERIALS:
      - armor_stand
      - waxed_copper_block
      - bone_block
      - bookshelf
      - glass_bottle
      - bucket
      - chorus_plant
      - crossbow
      - white_dye
      - elytra
      - glowstone
      - wooden_hoe
      - honeycomb
      - honey_block
      - pink_wool
      - lodestone
      - nether_gold_ore
      - shield
      - wooden_shovel
      - spyglass
      - totem_of_undying
      - trident
    ENTITIES:
      CUSTOMS:
        ENTITY_GENERIC_BIG_FALL: leather_boots
        ENTITY_GENERIC_BURN: flint_and_steel
        ENTITY_GENERIC_DEATH: iron_sword
        ENTITY_GENERIC_DRINK: glass_bottle
        ENTITY_GENERIC_EAT: cooked_beef
        ENTITY_GENERIC_EXPLODE: tnt
        ENTITY_GENERIC_EXTINGUISH_FIRE: flint_and_steel
        ENTITY_GENERIC_HURT: iron_sword
        ENTITY_GENERIC_SMALL_FALL: leather_boots
        ENTITY_GENERIC_SPLASH: water_bucket
        ENTITY_GENERIC_SWIM: water_bucket
        ENTITY_HOSTILE_BIG_FALL: leather_boots
        ENTITY_HOSTILE_DEATH: iron_sword
        ENTITY_HOSTILE_HURT: iron_sword
        ENTITY_HOSTILE_SMALL_FALL: leather_boots
        ENTITY_HOSTILE_SPLASH: water_bucket
        ENTITY_HOSTILE_SWIM: water_bucket
        ENTITY_ILLUSIONER_AMBIENT: splash_potion
        ENTITY_ILLUSIONER_CAST_SPELL: splash_potion
        ENTITY_ILLUSIONER_DEATH: splash_potion
        ENTITY_ILLUSIONER_HURT: splash_potion
        ENTITY_ILLUSIONER_MIRROR_MOVE: splash_potion
        ENTITY_ILLUSIONER_PREPARE_BLINDNESS: splash_potion
        ENTITY_ILLUSIONER_PREPARE_MIRROR: splash_potion
        ENTITY_LEASH_KNOT_BREAK: lead
        ENTITY_LEASH_KNOT_PLACE: lead
      MATERIALS:
      - armor_stand
      - arrow
      - axolotl_bucket
      - bat_spawn_egg
      - beef
      - blaze_rod
      - oak_boat
      - cat_spawn_egg
      - chicken
      - cod_bucket
      - cow_spawn_egg
      - creeper_spawn_egg
      - dolphin_spawn_egg
      - donkey_spawn_egg
      - dragon_egg
      - drowned_spawn_egg
      - elder_guardian_spawn_egg
      - enderman_spawn_egg
      - endermite_spawn_egg
      - ender_chest
      - evoker_spawn_egg
      - experience_bottle
      - firework_rocket
      - fishing_rod
      - pufferfish_bucket
      - fox_spawn_egg
      - ghast_tear
      - glowstone
      - goat_spawn_egg
      - hoglin_spawn_egg
      - horse_spawn_egg
      - husk_spawn_egg
      - iron_ore
      - item_frame
      - lightning_rod
      - lingering_potion
      - llama_spawn_egg
      - magma_block
      - minecart
      - mooshroom_spawn_egg
      - mule_spawn_egg
      - ocelot_spawn_egg
      - painting
      - panda_spawn_egg
      - parrot_spawn_egg
      - phantom_spawn_egg
      - piglin_spawn_egg
      - pig_spawn_egg
      - pillager_spawn_egg
      - player_head
      - polar_bear_spawn_egg
      - rabbit_spawn_egg
      - ravager_spawn_egg
      - salmon_bucket
      - sheep_spawn_egg
      - shulker_box
      - silverfish_spawn_egg
      - skeleton_spawn_egg
      - slime_block
      - snowball
      - snow
      - spider_eye
      - splash_potion
      - glow_squid_spawn_egg
      - stray_spawn_egg
      - strider_spawn_egg
      - tnt
      - tropical_fish_bucket
      - turtle_egg
      - vex_spawn_egg
      - villager_spawn_egg
      - vindicator_spawn_egg
      - wandering_trader_spawn_egg
      - witch_spawn_egg
      - wither_rose
      - wolf_spawn_egg
      - zoglin_spawn_egg
      - zombie_spawn_egg
      - zombified_piglin_spawn_egg
    BLOCKS:
      CUSTOMS:
        BLOCK_CROP_BREAK: wheat
        BLOCK_BLASTFURNACE_FIRE_CRACKLE: blast_furnace
        BLOCK_ENCHANTMENT_TABLE_USE: enchanting_table
        BLOCK_METAL_BREAK: iron_block
        BLOCK_METAL_FALL: iron_block
        BLOCK_METAL_HIT: iron_block
        BLOCK_METAL_PLACE: iron_block
        BLOCK_METAL_PRESSURE_PLATE_CLICK_OFF: iron_block
        BLOCK_METAL_PRESSURE_PLATE_CLICK_ON: iron_block
        BLOCK_METAL_STEP: iron_block
      MATERIALS:
      - amethyst_block
      - ancient_debris
      - anvil
      - azalea_leaves
      - bamboo
      - barrel
      - basalt
      - beacon
      - beehive
      - bell
      - big_dripleaf
      - bone_block
      - brewing_stand
      - dead_bubble_coral_block
      - cake
      - calcite
      - campfire
      - candle
      - cave_spider_spawn_egg
      - chain
      - chest
      - chorus_plant
      - comparator
      - composter
      - conduit
      - copper_ore
      - dead_tube_coral_block
      - deepslate
      - dispenser
      - dripstone_block
      - ender_chest
      - end_rod
      - oak_fence
      - dead_fire_coral_block
      - flowering_azalea_leaves
      - crimson_fungus
      - furnace
      - gilded_blackstone
      - glass
      - grass_block
      - gravel
      - grindstone
      - hanging_roots
      - honey_block
      - iron_ore
      - ladder
      - jack_o_lantern
      - large_fern
      - lava_bucket
      - lever
      - lily_of_the_valley
      - lodestone
      - medium_amethyst_bud
      - moss_carpet
      - netherite_block
      - netherrack
      - nether_gold_ore
      - note_block
      - crimson_nylium
      - piston
      - pointed_dripstone
      - polished_granite
      - end_portal_frame
      - white_concrete_powder
      - pumpkin
      - redstone_ore
      - respawn_anchor
      - rooted_dirt
      - crimson_roots
      - sand
      - scaffolding
      - sculk_sensor
      - shroomlight
      - shulker_box
      - slime_block
      - small_dripleaf
      - smithing_table
      - smoker
      - snow
      - soul_sand
      - spore_blossom
      - crimson_stem
      - stone
      - sweet_berries
      - tripwire_hook
      - tuff
      - weeping_vines
      - nether_wart_block
      - water_bucket
      - wet_sponge
      - wooden_sword
      - stripped_oak_wood
      - white_wool
