maxhealth_command:
  type: command
  name: maxhealth
  debug: false
  description: Adjusts a player's max health up to 100.
  usage: /maxhealth (player) <&lt>#<&gt>
  aliases:
      - maxhp
  permission: behr.essentials.maxhealth
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
  # % ██ [ Check command arguments              ] ██
    - if <context.args.is_empty> || <context.args.size> > 2:
      - inject Command_Syntax

    # % ██ [ Default self ] ██
    - if <context.args.size> == 1:
      - define user <player>

  # % ██ [ Check if specifying another user     ] ██
    - else:
      - define user <context.args.first>
      - inject player_verification
    - define new_health <context.args.last>

  # % ██ [ Check health argument                ] ██
    - if !<[new_health].is_integer>:
      - define reason "Health is measured as a number."
      - inject command_error

    - if <[new_health]> < 1:
      - define reason "Health cannot be negative or below 1."
      - inject command_error

    - if <[new_health].contains[.]>:
      - define reason "Health cannot have a decimal."
      - inject command_error

    - if <[new_health]> > 100:
      - define reason "Health can range up to 100."
      - inject command_error

  # % ██ [ Adjust health                        ] ██
    - adjust <[user]> max_health:<[new_health]>
    - narrate targets:<[user]> "<&color[#33ff33]>Maximum Health adjusted to <&color[#f4ffb3]><[new_health]>"
    - if <context.args.size> == 2:
      - narrate targets:<player> "<[user].name><&color[#33ff33]>'s Maximum Health set to: <&color[#f4ffb3]><[new_health]>"
