# Nimbus

See the current temperature and weather conditions for your location.

![Nimbus Screenshot](/data/screenshot.png)

This is a fork of the original app https://github.com/danirabbit/nimbus.

## Building, Testing, and Installation

You'll need the following dependencies to build:
* libgeoclue-2-dev
* libadwaita-1
* libgtk-4-dev
* libgweather-4-dev
* meson
* valac

You'll need the following dependencies to run:
* geoclue-2.0

Run `meson build` to configure the build environment and run `ninja test` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.github.danirabbit.nimbus`

    ninja install
    io.github.danirabbit.nimbus
