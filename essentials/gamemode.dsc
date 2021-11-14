gmc_command:
  type: command
  name: gmc
  debug: false
  description: Adjusts another player's or your gamemode to creative mode.
  usage: /gmc
  permission: behrry.essentials.gmc
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
    - define gamemode creative
    - inject gamemode_task

gma_command:
  type: command
  name: gma
  debug: false
  description: Adjusts another player's or your gamemode to adventure mode.
  usage: /gma
  permission: behrry.essentials.gma
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
    - define gamemode adventure
    - inject gamemode_task

gmsp_command:
  type: command
  name: gmsp
  debug: false
  description: Adjusts another player's or your gamemode to spectator mode.
  usage: /gmsp
  permission: behrry.essentials.gmsp
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
    - define gamemode spectator
    - inject gamemode_task

gms_command:
  type: command
  name: gms
  debug: false
  description: Adjusts another player's or your gamemode to survival mode.
  usage: /gms
  permission: behrry.essentials.gms
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
    - define gamemode survival
    - inject gamemode_task

gamemode_task:
  type: task
  debug: false
  definitions: gamemode
  script:
  # % ██ [ Check command arguments                ] ██
    - if <context.args.size> > 1:
      - inject command_syntax

  # % ██ [ Change the player's gamemode           ] ██
    - if <context.args.is_empty>:
      - if <player.gamemode> == <[gamemode]>:
        - narrate "<&color[#ff3333]>You are already in <[gamemode]> mode."
      - else:
        - narrate "<&color[#33ff33]>Gamemode changed to: <&color[#f4ffb3]><[gamemode]>"
        - adjust <player> gamemode:<[gamemode]>

    - else:
  # % ██ [ Change the specified player's gamemode ] ██
      - define user <context.args.first>
      - inject player_verification

      - if <[user].gamemode> == <[gamemode]>:
        - narrate "<[user].name> <&color[#ff3333]>is already in <[gamemode]> mode."
      - else:
        - if <[user].name> != <player.name>:
          - narrate "<[user].name> <&color[#33ff33]>'s gamemode changed to: <&color[#f4ffb3]><[gamemode]>"
        - narrate targets:<[user]> "<&color[#33ff33]>Gamemode changed to: <&color[#f4ffb3]><[gamemode]>"
        - adjust <[user]> gamemode:<[gamemode]>
