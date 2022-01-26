clearinventory_Command:
  type: command
  name: clearinventory
  debug: false
  description: Clears yours, or another player's inventory
  usage: /clearinventory (player)
  permission: behr.essentials.clearinventory
  aliases:
    - invclear
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
  # % ██ [ Check command arguments               ] ██
    - if <context.args.size> > 1:
        - inject command_syntax

  # % ██ [  For when the player is the target    ] ██
    - if <context.args.is_empty>:
      - inventory clear d:<player.inventory>
      - narrate "<&color[#33ff33]>Your inventory was cleared"

  # % ██ [ For when another player is the target ] ██
    - else:
      - define user <context.args.first>
      - inject player_verification
      - if <[user].name> != <player.name>:
        - narrate "<[user].name><&color[#33ff33]>'s inventory was cleared"
      - narrate targets:<[user]> "<&color[#33ff33]>Your inventory was cleared"
      - inventory clear d:<[user].inventory>
