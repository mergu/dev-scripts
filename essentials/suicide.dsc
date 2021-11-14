suicide_command:
  type: command
  name: suicide
  debug: false
  description: Kills yourself
  usage: /suicide
  permission: behr.essentials.sucide
  script:
  # % ██ [ Check args ] ██
    - if !<context.args.is_empty>:
      - inject command_syntax

  # % ██ [ Check player's gamemode ] ██
    - define gamemode <player.gamemode>
    - if <list[spectator|creative].contains[<[gamemode]>]>:
      - repeat 10:
        - animate <player> animation:hurt
        - wait 2t
      - adjust <player> health:0
      - stop

  # % ██ [ Check for cooldown ] ██
    - if <player.has_flag[behr.essentials.sucide_cooldown]>:
      - narrate "<&color[#cc0000]>You must wait: <player.flag_expiration[behr.essentials.sucide_cooldown].from_now.formatted_words> <&color[#cc0000]>to do that again"
      - stop

  # % ██ [ Kill self ] ██
    - while ( <player.health> > 0 || <player.is_online> ) && <player.gamemode> == <[gamemode]>:
      - adjust <player> no_damage_duration:1t
      - hurt <player> 1
      - wait 2t
    - flag player behr.essentials.sucide_cooldown expire:10m
