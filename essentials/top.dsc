top_command:
  type: command
  name: top
  debug: false
  description: Takes you to the heighest solid block location
  usage: /top
  permission: behr.essentials.top
  script:
  # % ██ [ Check for args                      ] ██
    - if !<context.args.is_empty>:
      - inject Command_Syntax

  # % ██ [ check if they're already at the top ] ██
    - if <player.location.y> > <player.location.highest.y>:
      - narrate "<&color[#ffe066]>You're already above the highest solid block here"
      - stop

  # % ██ [ Teleports you to the top            ] ██
    - else:
      - flag player behr.essentials.teleport.back.location:<player.location>
      - flag player behr.essentials.teleport.back.world:<player.world.name>
      - narrate "<&color[#33ff33]>Taking you to the top"
      - teleport <player> <player.location.highest.add[0,2,0]>
