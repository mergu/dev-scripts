weather_command:
  type: command
  name: weather
  debug: false
  description: Adjusts the weather.
  usage: /weather <&lt>weather<&gt> (world)
  permission: behr.essentials.weather
  tab completions:
    1: sunny|storm|thunder|rainy
    2: <server.worlds.parse[name].filter[contains_any_text[nether|end].not]>
  script:
  # % ██  [ Check player arguments              ]  ██
    - if <context.args.is_empty> || <context.args.size> > 2:
      - inject command_syntax

    - define weather <context.args.first>
    - if !<[weather].advanced_matches_text[sunny|storm|thunder|rainy]>:
      - define reason "Invalid weather"
      - inject command_error

  # % ██  [ Custom name(s) for weather choices  ]  ██
    - if <[weather]> == rainy:
      - define weather <list[storm|thunder].random>

  # % ██  [ Check if a player specified a world ]  ██
    - if <context.args.size> == 2:
      - define world <context.args.last>
      - if !<server.worlds.parse[name].contains[<[world]>]>:
        - define reason "Invalid world"
        - inject command_error

  # % ██  [ Verify the world supports weather   ]  ██
      - else if <[world].contains_any_text[nether|end]>:
        - define reason "This world doesn't have controllable weather"
        - inject command_error

      - announce "<&color[#33ff33]>Weather changed on <&color[#f4ffb3]><[world]> <&color[#33ff33]>to: <&color[#f4ffb3]><[weather].to_titlecase>"
    - else:
      - announce "<&color[#33ff33]>Weather changed to: <&color[#f4ffb3]><[weather].to_titlecase>"

  # % ██  [ Change the weather for the world    ]  ██
    - weather <[weather]> <[world].if_null[<player.world>]>
