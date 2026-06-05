import Config

config :jibble_bot,
  email: System.get_env("JIBBLE_EMAIL"),
  password: System.get_env("JIBBLE_PASSWORD")

