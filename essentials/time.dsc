time_command:
  type: command
  name: time
  debug: false
  description: Changes the time of day
  usage: /time <&lt>Time of Day/0-23999<&gt>
  permission: behr.essentials.time
  tab completions:
    1: start|day|noon|sunset|bedtime|dusk|night|midnight|sunrise|dawn
  script:
  # % ██ [ Check Args ] ██
    - if <context.args.is_empty>:
      - inject command_syntax

  # % ██ [ Check if Arg is a number ] ██
    - if <context.args.first.is_integer>:
      - define int <context.args.first>

    # % ██ [ Check if number is a valid number for usage ] ██
      - if <[int]> < 0:
        - define reason "Time cannot be negative"
        - inject command_error

      - if <[int]> >= 24000:
        - define reason "Time cannot exceed 23,999"
        - inject command_error

      - if <[int].contains[.]>:
        - define reason "Time cannot contain decimals"
        - inject command_error

      - time <[int]>t
      - define time_name <[int].format_number>

  # % ██ [ Match time with time of day by name ] ██
    - else:
      - define time_of_day <context.args.first>
      - choose <[time_of_day]>:
        - case start:
          - time 0
        - case day:
          - time 1000t
        - case noon:
          - time 6000t
        - case sunset:
          - time 11615t
        - case bedtime:
          - time 12542t
        - case dusk:
          - time 12786t
        - case night:
          - time 13000t
        - case midnight:
          - time 18000t
        - case sunrise:
          - time 22200t
        - case dawn:
          - time 23216t
        - default:
          - inject command_syntax
      - define time_name <[time_of_day].to_titlecase>

    - narrate "<&color[#33ff33]>Time set to: <&color[#f4ffb3]><[time_name]>"
