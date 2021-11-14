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
    - if <context.args.is_empty>:
      - determine <server.online_players.parse[name].include[<server.worlds.parse[name]>].include_single[~]>

    - define arg_count <context.args.size>
    - if "<context.raw_args.ends_with[ ]>":
      - define arg_count:++

    - if <[arg_count]> == 1:
      - determine <server.online_players.parse[name].include[<server.worlds.parse[name]>].include_single[~].filter[starts_with[<context.args.first>]]>

    - else if <[arg_count]> == 2:
      - if <server.online_players.parse[name].contains[<context.args.first>]>:
        - determine <server.online_players.parse[name].include[<server.worlds.parse[name]>].include_single[~].filter[starts_with[<context.args.get[2].if_null[<empty>]>]]>
      - else if <context.args.first.is_integer> || <context.args.first> == ~:
        - determine ~

    - else if <[arg_count]> == 3:
      - if !<context.args.remove[first].exclude[~|~|~].parse[is_integer].contains[false]> || <server.match_player[<context.args.first>].if_null[invalid]> == invalid:
        - determine ~

    - else if <[arg_count]> == 4:
      - if <server.match_player[<context.args.first>].if_null[invalid]> == invalid:
        - if !<context.args.get[1].to[3].exclude[~|~|~].parse[is_integer].contains[false]>:
          - determine <server.worlds.parse[name].filter[starts_with[<context.args.get[4].if_null[<empty>]>]]>
      - else if !<context.args.remove[first].exclude[~|~].parse[is_integer].contains[false]>:
        - determine ~

    - else if <[arg_count]> == 5 && <server.match_player[<context.args.first>].if_null[invalid]> != invalid && !<context.args.get[2].to[4].exclude[~|~|~].parse[is_integer].contains[false]>:
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
      - foreach <[coordinates]> as:coordinate:
        - if !<[coordinate].is_integer>:
          - if <[coordinate]> == ~:
            - define index <player.location.simple.before_last[,].split[,].get[<[loop_index]>]>
            - define coordinates <[coordinates].set[<[index]>].at[<[loop_index]>]>
            - foreach next
          - define invalid_coordinates:|:<[coordinate]>
      - if <[invalid_coordinates].exists>:
        - if <[invalid_coordinates].size> > 1:
          - define grammar_verb are
          - define grammar_noun coordinates
        - else:
          - define grammar_verb "is an"
          - define grammar_noun coordinate
        - define reason "<[invalid_coordinates].formatted> <[grammar_verb]> invalid <[grammar_noun]>."
        - inject command_error

      - foreach <[coordinates]> as:coordinate:
        - if <[coordinate].abs> > 9000:
          - define reason "Exceeds the server's border: 8000 to -8000 across the X and Z axis"
          - inject command_error
  script:
    - define arg_count <context.args.size>

    - if <[arg_count]> == 0 || <context.args.first> == help:
      - inject teleport_command.help
      - stop

    - choose <context.args.size>:

      # - ██  [  Possibilities:                 ] ██
      # | ██  [  /teleport PlayerTwo            ] ██
      # | ██  [  /teleport world                ] ██
      - case 1:
        - if <server.match_player[<context.args.first>].if_null[invalid]> == invalid:
          - if !<server.worlds.parse[name].contains[<context.args.first>]>:
            - define reason "Invalid player or world name."
            - inject command_error

          - flag player behr.essentials.teleport.back.location:<player.location>
          - flag player behr.essentials.teleport.back.world:<player.world.name>
          - define location <world[<context.args.first>].spawn_location>
          - narrate "<&color[#33ff33]>Teleported you to <[location].simple.proc[colorize]>"
          - teleport <[location]>

        - else:
          - flag player behr.essentials.teleport.back.location:<player.location>
          - flag player behr.essentials.teleport.back.world:<player.world.name>
          - define location <server.match_player[<context.args.first>].location>
          - narrate "<&color[#33ff33]>Teleported you to <[location].simple.proc[colorize]>"
          - teleport <[location]>

      # - ██  [  Possibilities:                 ] ██
      # | ██  [  /teleport PlayerOne world      ] ██
      # | ██  [  /teleport PlayerOne PlayerTwo  ] ██
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
          - flag <[player]> behr.essentials.teleport.back.location:<[player].location>
          - flag <[player]> behr.essentials.teleport.back.world:<[player].world.name>
          - define location <world[<context.args.last>].spawn_location>
          - narrate targets:<[player]> "<&color[#33ff33]>You were teleported to <[location].simple.proc[colorize]>"
          - narrate "<&color[#33ff33]>Teleported <[player].name> to <[location].simple.proc[colorize]>"
          - teleport <[location]>

      # - ██  [  Possibilities:                 ] ██
      # | ██  [  /teleport x y z                ] ██
      - case 3:
        - define coordinates <context.args>
        - inject teleport_command.check.coordinates

        - foreach <[coordinates]> as:coordinate:
          - if <[coordinate].abs> > 9000:
            - define reason "Exceeds the server's border: 8000 to -8000 across the X and Z axis."
            - inject command_error

        - flag player behr.essentials.teleport.back.location:<player.location>
        - flag player behr.essentials.teleport.back.world:<player.world.name>
        - define location <location[<[coordinates].separated_by[,]>].with_world[<player.world>]>
        - narrate "<&color[#33ff33]>Teleported you to <[location].simple.proc[colorize]>"
        - teleport <[location]>

      # - ██  [  Possibilities:                 ] ██
      # | ██  [  /teleport PlayerOne x y z      ] ██
      # | ██  [  /teleport x y z world          ] ██
      - case 4:
        - if <server.match_player[<context.args.first>].if_null[invalid]> == invalid:
          - if !<server.worlds.parse[name].contains[<context.args.last>]>:
            - define reason "Invalid player or world name."
            - inject command_error

          - else:
            - define coordinates <context.args.remove[last]>
            - inject teleport_command.check.coordinates

            - flag player behr.essentials.teleport.back.location:<player.location>
            - flag player behr.essentials.teleport.back.world:<player.world.name>
            - define location <location[<[coordinates].separated_by[,]>].with_world[<context.args.last>]>
            - narrate "<&color[#33ff33]>Teleported you to <[location].simple.proc[colorize]>"
            - teleport <[location]>

        - else:
          - define player <server.match_player[<context.args.first>]>
          - define coordinates <context.args.remove[first]>
          - inject teleport_command.check.coordinates

          - flag <[player]> behr.essentials.teleport.back.location:<[player].location>
          - flag <[player]> behr.essentials.teleport.back.world:<[player].world.name>
          - define location <location[<[coordinates].separated_by[,]>].with_world[<[player].world>]>
          - narrate targets:<[player]> "<&color[#33ff33]>You were teleported to <[location].simple.proc[colorize]>"
          - narrate "<&color[#33ff33]>Teleported <[player].name> to <[location].simple.proc[colorize]>"
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

        - flag <[player]> behr.essentials.teleport.back.location:<[player].location>
        - flag <[player]> behr.essentials.teleport.back.world:<[player].world.name>
        - define location <location[<[coordinates].separated_by[,]>].with_world[<context.args.last>]>
        - narrate targets:<[player]> "<&color[#33ff33]>You were teleported to <[location].simple.proc[colorize]>"
        - narrate "<&color[#33ff33]>Teleported <[player].name> to <[location].simple.proc[colorize]>"
        - teleport <[player]> <[location]>

      # - ██  [  Possibilities:                 ] ██
      # | ██  [  none, please stop              ] ██
      - default:
        - inject teleport_command.help
