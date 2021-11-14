chat_event_handler:
  type: world
  debug: false
  events:
    on player chats:
      - define targets <server.online_players>
      - narrate PLAYER_MESSAGE=<player.uuid>=<context.message> targets:<[targets]> uuid:<player.uuid>
      - determine cancelled
    on player receives message:
      - define last_msg <player.flag[last_received_message]||null>
      - flag player last_received_message:<context.message> duration:15s
      - if <context.message.starts_with[PLAYER_MESSAGE]>:
        - if !<player.has_flag[chat.style]>:
          - flag player chat.style:compact
        - define parts <context.message.split[=].limit[3]>
        - if <player.flag[chat.style]> == cozy && <[last_msg].starts_with[PLAYER_MESSAGE=<[parts].get[2]>]>:
          - determine "message: <&7><&chr[BB]> <&f><[parts].get[3]>"
        - define player <player[<[parts].get[2]>]>
        # Prefixes
        - define prefix_str <[player].proc[chat_prefix]>
        - if <[prefix_str].length> > 0:
          - define prefix_str "<[prefix_str]> "
        # Suffix
        - define suffix_str <[player].chat_suffix.trim.parse_color>
        # Name
        - define name <[player].display_name>
        - if <[name].ends_with[<&ss>r]>:
          - define name <[name].before_last[<&ss>r]>
        - define click "/seen <[player].name>"
        - define hover "<&a><[player].name><&7>:<n><&7><&chr[BB]> Click to run <&a>/seen <[player].name><n><&7><&chr[BB]> Use <&a>/tpa <&7>and <&a>/tpahere <&7>to teleport"
        - define sep <empty>
        - if <player.flag[chat.style]> == cozy:
          - define sep <n>
        - if <[suffix_str].length> == 0:
          - determine "message:<[prefix_str]><[name].on_click[<[click]>].on_hover[<[hover]>]><&7> <[sep]><&chr[BB]> <&f><[parts].get[3]>"
        - determine "message:<[prefix_str]><[name].on_click[<[click]>].on_hover[<[hover]>]> <[player].flag[flair_style]||<&r>><[suffix_str]><&7> <[sep]><&chr[BB]> <&f><[parts].get[3]>"
