fly_command:
  type: command
  name: fly
  debug: false
  description: Grants or disables flight for yourself or another player
  usage: /fly (player)
  permission: behr.essentials.fly
  tab completions:
    1: <server.online_players.parse[name]>
  script:
    - if <context.args.size> > 1:
      - inject command_syntax

    - else if <context.args.is_empty>:
      - adjust <player> can_fly:<player.can_fly.not>
      - if <player.can_fly>:
        - narrate "<&color[#33ff33]>Flight enabled"
      - else:
        - narrate "<&color[#33ff33]>Flight disabled"

    - else:
      - define user <context.args.first>
      - inject player_verification
      - adjust <[user]> can_fly:<[user].can_fly.not>
      - if <[user].can_fly>:
        - narrate "<&color[#33ff33]>Flight enabled for <[user].name>"
        - narrate targets:<[user]> "<&color[#33ff33]>Flight enabled"
      - else:
        - narrate "<&color[#33ff33]>Flight disabled for <[user].name>"
        - narrate targets:<[user]> "<&color[#33ff33]>Flight disabled"
