# @ ██████████████████████████████████████████████████████████████████████████████
# @ ██    command Dependencies | Easy injections to keep error messages consistent
# % ██
# % ██  @ command syntax error & stop
# % ██  | injects an error message telling the player they used
# % ██  | the command wrong, shows them the command's syntax,
# % ██  | offers to suggest the command on click and shows
# % ██  | what they actually typed that was wrong, in-case
# % ██  | it could have been a typo or to let them see
# % ██  | for themselves what they typed wrongly
# - ██  [ Usage ] - inject command_syntax
command_syntax:
    type: task
    debug: false
    script:
        - define command "<queue.script.data_key[aliases].first.if_null[<queue.script.data_key[name]>]> "
        - define hover "<&color[#33ff33]>Click to Insert:<n><queue.script.parsed_key[usage].proc[colorize]>"
        - define text "<proc[colorize].context[Syntax: <queue.script.parsed_key[usage]>]>"
        - narrate <proc[msg_hint].context[<[hover]>|<[text]>|<[command]>]>
        - stop

# % ██  @ command general error & stop
# % ██  | injects an error message telling the player they used
# % ██  | the command wrong and why, offers to suggest the
# % ██  | command on click and shows what they actually
# % ██  | typed that was wrong, in-case it could have
# % ██  | been a typo or to let them see for themselves
# % ██  |  what they typed wrongly
# - ██  [ Usage ] - define reason "This is an error because of this reason"
# - ██  [       ] - inject command_error
command_error:
    type: task
    debug: false
    definitions: reason
    script:
        - define command "<queue.script.data_key[aliases].first.if_null[<context.alias.if_null[<context.command>]>]> "
        - define hover "<&color[#ff3333]>You typed<&r><n><&4>/<&color[#ff3333]><context.alias.if_null[<context.command>]> <context.raw_args><n><&color[#33ff33]>Click to insert<&co><n><queue.script.parsed_key[usage].proc[colorize]>"
        - define text <&color[#ff3333]><[reason]>
        - narrate <proc[msg_hint].context[<[hover]>|<[text]>|<[command]>]>
        - stop

# % ██  @ checks if a player name could be a valid player
# % ██  | injects an error message telling the player they
# % ██  | put a player name that didn't match an online player
# - ██  [ Usage ]  - define user playername
# - ██  [       ]  - inject player_verification
player_verification:
  type: task
  debug: false
  definitions: user
  too_short:
    - define hover "<proc[colorize].context[You typed<&co>]><n><&color[#ff3333]>/<context.command.to_lowercase> <context.raw_args>"
    - define text "Input was too short to match a real player"
    - narrate <proc[msg_hover].context[<[hover]>|<[text]>]>
    - stop
  invalid_player:
    - define hover "<proc[colorize].context[You typed<&co>]><n><&color[#ff3333]>/<context.command.to_lowercase> <context.raw_args>"
    - define text "That player does not exist or is offline"
    - narrate <proc[msg_hover].context[<[hover]>|<[text]>]>
    - stop
  script:
    - if <[user].length> < 3:
      - inject player_verification.too_short
    - else if !<server.match_player[<[user]>].exists>:
      - inject player_verification.invalid_player
    - define user <server.match_player[<[user]>]>

# % ██  [ Verifies a player online or offline ] ██
# % ██  | injects an error message telling the player they
# % ██  | put a player name that didn't match an online player
# - ██  [ Usage ]  - define user playername
# - ██  [       ]  - inject player_verification_offline
player_verification_offline:
  type: task
  debug: false
  definitions: user
  too_short:
    - define hover "<proc[colorize].context[You typed<&co>]><n><&color[#ff3333]>/<context.command.to_lowercase> <context.raw_args>"
    - define text "Input was too short to match a real player"
    - narrate <proc[msg_hover].context[<[hover]>|<[text]>]>
    - stop
  invalid_player:
    - define hover "<proc[colorize].context[You typed<&co>]><n><&color[#ff3333]>/<context.command.to_lowercase> <context.raw_args>"
    - define text "That player does not exist"
    - narrate <proc[msg_hover].context[<[hover]>|<[text]>]>
    - stop
  script:
  - if <[user].length> < 3:
    - inject player_verification_offline.too_short
  - else if !<server.match_player[<[user]>].exists>:
    - if !<server.match_offline_player[<[user]>].exists>:
      - inject player_verification_offline.invalid_player
    - else:
      - define user <server.match_offline_player[<[user]>]>
  - else:
      - define user <server.match_player[<[user]>]>

colorize:
  type: procedure
  debug: false
  definitions: string
  script:
    # % ██ [ color tone,  70%  |  main accent, 85%  |  symbols etc, 60% ] ██
    - define 1 <&color[#f4ffb3]>
    - define 2 <&color[#ffcc00]>
    - define text <list>
    - foreach <[string].to_list> as:character:
      - if <[character].matches_character_set[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789]>:
        - define text <[text].include_single[<[1]><[character]>]>
      - else if "<[character].matches_character_set[ <n>]>":
        - define text <[text].include_single[<[character]>]>
      - else:
        - define text <[text].include_single[<[2]><[character]>]>
    - determine <[text].unseparated>
