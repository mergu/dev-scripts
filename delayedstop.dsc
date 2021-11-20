delayed_stop_handler:
  type: world
  debug: false
  events:
    on stop|restart command:
      - determine passively fulfilled
      - if <context.source_type> == player && !<player.has_permission[zc.stop]>:
        - narrate "<&c>You do not have access to that command"
        - stop
      - flag server stopping
      - announce "<&c>The server will restart in 30 seconds."
      - wait 20s
      - announce "<&c>The server will restart in 10 seconds."
      - wait 7s
      - announce "<&c>The server is restarting..."
      - wait 3s
      - foreach <server.online_players> as:p:
        - kick <[p]>
        - wait 1t
      - wait 1s
      - adjust server save
      - adjust server save_citizens
      - wait 1s
      - foreach <server.worlds> as:world:
        - adjust <[world]> save
        - wait 1s
      - adjust server shutdown
    on player logs in:
      - if <server.has_flag[stopping]>:
        - determine "kicked:Server is restarting."
    on server start:
      - flag server stopping:!