feed_command:
  type: command
  name: feed
  debug: false
  description: Satiates a player's hunger.
  usage: /feed (player (#))
  permission: behr.essentials.feed
  tab completions:
    1: <server.online_players.parse[name].exclude[<player.name>]>
  script:
  # % ██ [  Check command arguments               ] ██
    - if <context.args.size> > 2:
      - inject command_syntax

  # % ██ [  For when the player is the target     ] ██
    - if <context.args.is_empty>:
      - feed amount:20 saturation:20
      - narrate "<&color[#33ff33]>Your hunger was satiated"
      - stop

  # % ██ [  For when another player is the target ] ██
    - define user <player>
    - define level <context.args.first>
    - inject player_verification

    - if <context.args.size> == 1:

      - if <[user]> != <player>:
        - narrate "<[user].name>'s hunger was satiated."
      - narrate targets:<[user]> "<&color[#33ff33]>Your hunger was satiated."

  # % ██ [  For when another player is the target ] ██
  # % ██ [  ...potentially starving starving them ] ██
    - else:
    # % ██ [ Presets the oxygen if > 20 || < -20  ] ██
      - define level <context.args.last.min[20].max[-20]>

    # % ██ [ Verify hunger and food level used    ] ██
      - if !<[level].is_integer>:
        - define reason "Food and hunger must be a number"
        - inject command_error

      - if <[level].contains[.]>:
        - define reason "Food and hunger cannot be a decimal"
        - inject command_error

      - if <[level]> == 0:
        - define reason "Food and hunger must be more or less than nothing"
        - inject command_error

    # % ██ [ Check whether to satiate or intensify ] ██
      - feed <[user]> amount:<[level]> saturation:<[level]>
      - if <[level]> > 0:
        - if <[user]> != <player>:
          - narrate "<[user].name>'s hunger was satiated."
        - narrate targets:<[user]> "<&color[#33ff33]>Your hunger was satiated."
      - else:
        - if <[user].name> != <player.name>:
          - narrate "<[user].name>'s hunger was increased."
        - narrate targets:<[user]> "<&color[#ff3333]>Your hunger intensifies."
