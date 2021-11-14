heal_command:
  type: command
  name: heal
  debug: false
  description: Heals yourself or another player
  usage: /heal (player)
  permission: behr.essentials.heal
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
  # % ██ [ Check command arguments         ] ██
    - if <context.args.is_empty>:
      - define user <player>

  # % ██ [ Check if healing another player ] ██
    - else if <context.args.size> == 1:
      - define user <context.args.first>
      - inject player_verification

    - else:
      - inject command_syntax

  # % ██ [ Heal player                     ] ██
    - heal <[user]>
    - adjust <[user]> food_level:20

    - if <context.args.size> == 1 && <[user].name> != <player.name>:
      - narrate "<&color[#33ff33]><[user].name> was healed."
    - narrate targets:<[user]> "<&color[#33ff33]>You were healed."
