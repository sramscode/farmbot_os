use Mix.Config

# Mix configs.
target = Mix.Project.config[:target]
env = Mix.env()

# Transports
mqtt_transport = Farmbot.Transport.GenMqtt
redis_transport = Farmbot.Transport.Redis

config :logger, utc_log: true

# I force colors because they are important.
config :logger, :console, colors: [enabled: true, info: :cyan]

# Iex needs colors too.
config :iex, :colors, enabled: true

# send a message to these modules when we successfully log in.
config :farmbot, auth_callbacks: [mqtt_transport]

# frontend <-> bot transports.
config :farmbot, transports: [mqtt_transport, redis_transport]

# bot <-> firmware transports.
config :farmbot, expected_fw_version: "GENESIS.V.01.10.EXPERIMENTAL"

# Rollbar
config :farmbot, rollbar_access_token: "dcd79b191ab84aa3b28259cbb80e2060"

# give the ability to start a redis server instance in dev mode.
config :farmbot, :redis,
  server: System.get_env("REDIS_SERVER") || false,
  port: System.get_env("REDIS_SERVER_PORT") || 6379

# This is usually in the `priv` dir of :tzdata, but our fs is read only.
config :tzdata, :data_dir, "/tmp"
config :tzdata, :autoupdate, :disabled

# Path for the `fs` module to watch.
config :fs, path: "/tmp/images"

# Import configuration specific to out environment.
import_config "#{env}.exs"

# import config specific to our nerves_target
IO.puts "using #{target} - #{env} configuration."
import_config "hardware/#{target}/hardware.exs"
config :nerves, :firmware,
  rootfs_additions: "config/hardware/#{target}/rootfs-additions-#{env}"
