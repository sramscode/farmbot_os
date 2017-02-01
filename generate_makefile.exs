IO.puts "Backing up old Makefile"
File.cp "Makefile", "Makefile.bac"
version =  Path.join(__DIR__, "VERSION") |> File.read! |> String.strip

{commitish, _} = System.cmd("git", ["log", "--pretty=format:%hQQ%adQQ%f", "-1"])
thing = String.split(commitish, "QQ")
IO.puts "Building default portions"
initial = "# THIS FILE WAS GENERATED BY `build_makefile.exs`
# #{Enum.join(thing, "\n# ")}

default: rpi3

dev_env:
\texport MIX_ENV=dev

prod_env:
\texport MIX_ENV=prod

clean:
\t$(info Cleaning)
\trm -rf apps/NERVES_SYSTEM_*
\trm -rf apps/farmbot/_images
\trm -rf apps/nerves_system_br
\trm -rf deps
\trm -rf _build

test: dev_env
\tscripts/run_tests.sh

## End default portion.\n"

build_system_part = fn(sys) ->
"\n## begin #{sys} portion.

## #{sys} env
env-#{sys}: prod_env
\texport NERVES_TARGET=#{sys}

## #{sys} build
#{sys}: env-#{sys} system-#{sys} firmware-#{sys}
\t$(info Building stuff for #{sys})

## #{sys} create-build
create-build-#{sys}:
\tscripts/clone_system.sh #{sys}

## #{sys} system
system-#{sys}: create-build-#{sys}
\t$(info Building Linux System for #{sys})
\tscripts/build_system.sh #{sys}

## #{sys} firmware
firmware-#{sys}:
\t$(info Building Firmware for #{sys})
\tscripts/build_firmware.sh #{sys}

release-#{sys}: #{sys}
\tscripts/build_release_images.sh #{sys} #{version}

## end #{sys} portion."
end

list = File.ls!("apps")
only_systems = Enum.reduce(list, [], fn(d, acc) ->
  case d do
    # ignore nerves_system_br
    "nerves_system_br" -> acc
    "nerves_system_"<> sys -> [sys | acc]
    _ -> acc
  end
end)

initial_mod = Enum.reduce(only_systems, initial, fn(sys, acc) ->
  IO.puts "Defining system: #{sys}"
  acc <> build_system_part.(sys)
end)

IO.puts "Defining release for #{version}"
final = initial_mod <>
"\n\n## Release will build all the systems.
release: clean #{Enum.map(only_systems, fn(a) -> " release-"<>a end)}"

IO.puts "Writing file."
File.write("Makefile", final)
