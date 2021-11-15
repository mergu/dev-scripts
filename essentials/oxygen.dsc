oxygen_command:
  type: command
  name: oxygen
  debug: false
  description: Hungers or satiates a player's oxygen.
  usage: /oxygen (player) <&lt>#<&gt>
  permission: behr.essentials.oxygen
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
  # % ██ [ Check command arguments             ] ██
    - if <context.args.is_empty> || <context.args.size> > 2:
      - inject command_syntax

  # % ██ [ Check if using self or named player ] ██
    - if <context.args.size> == 1:
      - define user <player>
      - define level <context.args.first>
    - else:
      - define user <context.args.first>
      - inject player_verification
  # % ██ [ Presets the oxygen to be:           ] ██
  # | ██ | < (their maximum oxygen) && >= 0;
  # | ██ | and if a decimal, rounds to the 1/30th
  # | ██ | multiplied by 30 to equate to full bubbles
      - define level <context.args.last.min[<[user].max_oxygen>].max[0].round_to_precision[<element[1].div[30]>].mul[30].if_null[invalid]>

  # % ██ [ Verify oxygen number                ] ██
    - if !<[level].is_integer>:
      - define reason "Oxygen must be a number"
      - inject command_error

    - if <[level].contains[.]>:
      - define reason "Oxygen cannot be a decimal"
      - inject command_error

  # % ██ [ Check oxygen adjustment and narrate ] ██
  # % ██ [ Refresh oxygen                      ] ██
    - if <[user].oxygen> > <[level]>:
      - if <[user].name> != <player.name>:
        - narrate "<[user].name> <&color[#33ff33]>'s oxygen level was refreshed"
      - narrate targets:<[user]> "<&color[#33ff33]>Your oxygen level was refreshed"

  # % ██ [ Did nothing / stayed the same       ] ██
    - else if <[user].oxygen> == <[level]>:
      - if <[user]> != <player>:
        - define reason "<[user].name><&color[#f4ffb3]>'s Oxygen level is already <[level]>"
      - else:
        - define reason "<&color[#f4ffb3]>Your oxygen level is already <[level]>"
      - inject command_error

  # % ██ [ Deplete oxygen                      ] ██
    - else if <[user].oxygen> < <[level]>:
      - if <[user]> != <player>:
        - narrate "<[user].name> <&color[#33ff33]>'s oxygen level was depleted"
      - narrate targets:<[user]> "<&color[#ff3333]>Your oxygen level depletes"

    - oxygen <[level].mul[30]> player:<[user]>
