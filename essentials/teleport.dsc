teleport_command:
  type: command
  name: teleport
  debug: false
  description: Teleports you or another player to a location, to a world, or to another player
  usage: /teleport help / (player) ((x y z (world)) / (world) / (player))
  aliases:
    - tp
  permission: behrry.essentials.teleport
  tab complete:
      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerTwo             ] ██
      # | ██  [  /teleport world                 ] ██
      # | ██  [  /teleport PlayerOne world       ] ██
      # | ██  [  /teleport PlayerOne PlayerTwo   ] ██
      # | ██  [  /teleport x y z                 ] ██
      # | ██  [  /teleport PlayerOne x y z       ] ██
      # | ██  [  /teleport x y z world           ] ██
      # | ██  [  /teleport PlayerOne x y z world ] ██
      # % ██  [  Options: Player / World / X / ~ ] ██
    - if <context.args.is_empty>:
      - determine <server.online_players.parse[name].include[<server.worlds.parse[name]>].include_single[~]>

    - define arg_count <context.args.size>
    - if "<context.raw_args.ends_with[ ]>":
      - define arg_count:++

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  same as first                   ] ██
      # % ██  [  Options: Player / World / X / ~ ] ██
    - if <[arg_count]> == 1:
      - determine <server.online_players.parse[name].include[<server.worlds.parse[name]>].include_single[~].filter[starts_with[<context.args.first>]]>

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerOne world       ] ██
      # | ██  [  /teleport PlayerOne PlayerTwo   ] ██
      # | ██  [  /teleport x y z                 ] ██
      # | ██  [  /teleport PlayerOne x y z       ] ██
      # | ██  [  /teleport x y z world           ] ██
      # | ██  [  /teleport PlayerOne x y z world ] ██
      # % ██  [  Options: Player / World / X / Y / ~ ] ██
    - else if <[arg_count]> == 2:
      - if <server.online_players.parse[name].contains[<context.args.first>]>:
        - determine <server.online_players.parse[name].include[<server.worlds.parse[name]>].include_single[~].filter[starts_with[<context.args.get[2].if_null[<empty>]>]]>
      - else if <context.args.first.is_integer> || <context.args.first> == ~:
        - determine ~

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport x y z                 ] ██
      # | ██  [  /teleport PlayerOne x y z       ] ██
      # | ██  [  /teleport x y z world           ] ██
      # | ██  [  /teleport PlayerOne x y z world ] ██
      # % ██  [  Options: Player / Y / Z / ~     ] ██
    - else if <[arg_count]> == 3:
      - if !<context.args.remove[first].exclude[~|~|~].parse[is_integer].contains[false]> || !<server.match_player[<context.args.first>].exists>:
        - determine ~
      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerOne x y z       ] ██
      # | ██  [  /teleport x y z world           ] ██
      # | ██  [  /teleport PlayerOne x y z world ] ██
      # % ██  [  Options: World / Y / Z / ~      ] ██
    - else if <[arg_count]> == 4:
      - if !<server.match_player[<context.args.first>].exists>:
        - if !<context.args.get[1].to[3].exclude[~|~|~].parse[is_integer].contains[false]>:
          - determine <server.worlds.parse[name].filter[starts_with[<context.args.get[4].if_null[<empty>]>]]>
      - else if !<context.args.remove[first].exclude[~|~].parse[is_integer].contains[false]>:
        - determine ~

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerOne x y z world ] ██
      # % ██  [  Options: World                  ] ██
    - else if <[arg_count]> == 5 && <server.match_player[<context.args.first>].exists> && !<context.args.get[2].to[4].exclude[~|~|~].parse[is_integer].contains[false]>:
      - determine <server.worlds.parse[name].filter[starts_with[<context.args.get[5].if_null[<empty>]>]]>

  help:
    - narrate "<&6>/<&e>teleport x y z <&b>| <&a>Teleports you to the coordinates <&2><&lt><&a>x y z<&2><&gt>"
    - narrate "<&6>/<&e>teleport x y z world <&b>| <&a>Teleports you to <&2><&lt><&a>x y z<&2><&gt><&a> on the named world"
    - narrate "<&6>/<&e>teleport world <&b>| <&a>Teleports you to the named world"
    - narrate "<&6>/<&e>teleport PlayerTwo <&b>| <&a>Teleports you to PlayerTwo"
    - narrate "<&6>/<&e>teleport PlayerOne x y z <&b>| <&a>Teleports PlayerOne to <&2><&lt><&a>x y z<&2><&gt>"
    - narrate "<&6>/<&e>teleport PlayerOne x y z world <&b>| <&a>Teleports PlayerOne to <&2><&lt><&a>x y z<&2><&gt><&a> on the named world"
    - narrate "<&6>/<&e>teleport PlayerOne world <&b>| <&a>Teleports PlayerOne to the named world"
    - narrate "<&6>/<&e>teleport PlayerOne PlayerTwo <&b>| <&a>Teleports PlayerOne to PlayerTwo"

  check:
    coordinates:
      # % ██  [  Check each coordinate        ] ██
      # % ██  [  Must be either a number or ~ ] ██
      - foreach <[coordinates]> as:coordinate:
        - if !<[coordinate].is_integer>:

          # % ██  [  If the coordinates a ~, use the player's location ] ██
          - if <[coordinate]> == ~:
            - choose <[loop_index]>:
              - case 1:
                - define coordinates <[coordinates].set_single[<player.location.x>].at[1]>
              - case 2:
                - define coordinates <[coordinates].set_single[<player.location.y>].at[2]>
              - case 3:
                - define coordinates <[coordinates].set_single[<player.location.z>].at[3]>
            - foreach next
          - define invalid_coordinates:|:<[coordinate]>
      - if <[invalid_coordinates].exists>:
        # % ██  [  > 1 invalid coordinates == "<coordinates> are invalid coordinates"  ] ██
        - if <[invalid_coordinates].size> > 1:
          - define grammar_verb are
          - define grammar_noun coordinates
        # % ██  [  < 1 invalid coordinates == "<coordinate> is an invalid coordinate"  ] ██
        - else:
          - define grammar_verb "is an"
          - define grammar_noun coordinate
        - define reason "<[invalid_coordinates].formatted> <[grammar_verb]> invalid <[grammar_noun]>."
        - inject command_error

      - foreach <[coordinates]> as:coordinate:
        - if <[coordinate].abs> > 9000:
          - define reason "Exceeds the server's border: 8000 to -8000 across the X and Z axis"
          - inject command_error

  teleport:
    self_to_location:
      - flag player behr.essentials.teleport.back.location:<player.location>
      - flag player behr.essentials.teleport.back.world:<player.world.name>
      - narrate "<&color[#33ff33]>Teleported you to <[location].simple.proc[colorize]>"
      - teleport <[location]>

    other_player_to_location:
      - flag <[player]> behr.essentials.teleport.back.location:<[player].location>
      - flag <[player]> behr.essentials.teleport.back.world:<[player].world.name>
      - narrate targets:<[player]> "<&color[#33ff33]>You were teleported to <[location].simple.proc[colorize]>"
      - narrate "<&color[#33ff33]>Teleported <[player].name> to <[location].simple.proc[colorize]>"
      - teleport <[player]> <[location]>

  script:
    - define arg_count <context.args.size>

    - if <[arg_count]> == 0 || <context.args.first> == help:
      - inject teleport_command.help
      - stop

    - choose <context.args.size>:

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerTwo             ] ██
      # | ██  [  /teleport world                 ] ██
      - case 1:
        - if !<server.match_player[<context.args.first>].exists>:
          - if !<server.worlds.parse[name].contains[<context.args.first>]>:
            - define reason "Invalid player or world name."
            - inject command_error

          - define location <world[<context.args.first>].spawn_location>
          - inject teleport_command.teleport.self_to_location

        - else:
          - flag player behr.essentials.teleport.back.location:<player.location>
          - flag player behr.essentials.teleport.back.world:<player.world.name>
          - define location <server.match_player[<context.args.first>].location>
          - narrate "<&color[#33ff33]>Teleported you to <server.match_player[<context.args.first>].name>"
          - teleport <[location]>

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerOne world       ] ██
      # | ██  [  /teleport PlayerOne PlayerTwo   ] ██
      - case 2:
        - define player <server.match_player[<context.args.first>].if_null[invalid]>
        - if <[player]> == invalid:
          - define reason "Invalid player name."
          - inject command_error

        - if !<server.worlds.parse[name].contains[<context.args.last>]>:
          - define player_two <server.match_player[<context.args.last>].if_null[invalid]>
          - if <[player_two]> == invalid:
            - define reason "Invalid player or world name."
            - inject command_error

          - else:
            - flag <[player]> behr.essentials.teleport.back.location:<[player].location>
            - flag <[player]> behr.essentials.teleport.back.world:<[player].world.name>
            - define location <[player_two].location>
            - narrate targets:<[player]> "<&color[#33ff33]>You were teleported to <[player_two].name>"
            - narrate targets:<[player_two]> "<&color[#33ff33]><[player].name> was teleported to you."
            - narrate "<&color[#33ff33]>Teleported <[player].name> to <[player_two].name>"
            - teleport <[player]> <[location]>

        - else:
          - define location <world[<context.args.last>].spawn_location>
          - inject teleport_command.teleport.other_player_to_location

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport x y z                 ] ██
      - case 3:
        - define coordinates <context.args>
        - inject teleport_command.check.coordinates

        - define location <location[<[coordinates].separated_by[,]>].with_world[<player.world>]>
        - inject teleport_command.teleport.self_to_location

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerOne x y z       ] ██
      # | ██  [  /teleport x y z world           ] ██
      - case 4:
        - define player <server.match_player[<context.args.first>].if_null[invalid]>
        - if <[player]> == invalid:
          - if !<server.worlds.parse[name].contains[<context.args.last>]>:
            - define reason "Invalid player or world name."
            - inject command_error

          - else:
            - define coordinates <context.args.remove[last]>
            - inject teleport_command.check.coordinates

            - define location <location[<[coordinates].separated_by[,]>].with_world[<context.args.last>]>
            - inject teleport_command.teleport.self_to_location

        - else:
          - define coordinates <context.args.remove[first]>
          - inject teleport_command.check.coordinates

          - define location <location[<[coordinates].separated_by[,]>].with_world[<[player].world>]>
          - inject teleport_command.teleport.other_player_to_location
          - teleport <[player]> <[location]>

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  /teleport PlayerOne x y z world ] ██
      - case 5:
        - define player <server.match_player[<context.args.first>].if_null[invalid]>
        - if <[player]> == invalid:
          - define reason "Invalid player name."
          - inject command_error

        - if !<server.worlds.parse[name].contains[<context.args.last>]>:
          - define reason "Invalid world name."
          - inject command_error

        - define coordinates <context.args.remove[first|last]>
        - inject teleport_command.check.coordinates

        - define location <location[<[coordinates].separated_by[,]>].with_world[<context.args.last>]>
        - inject teleport_command.teleport.other_player_to_location

      # - ██  [  Possibilities:                  ] ██
      # | ██  [  none, please stop               ] ██
      - default:
        - inject teleport_command.help
