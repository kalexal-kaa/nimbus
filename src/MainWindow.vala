/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2017-2023 Danielle Foré (https://danirabbit.github.io/)
 */

public class MainWindow : Adw.ApplicationWindow {
    private Gtk.Stack stack;
    private Gtk.Spinner spinner;
    private Gtk.Grid grid;
    private Gtk.Box location_disabled_box;
    private GWeather.Location? location = null;
    private GWeather.Info weather_info;

    construct {
        set_title("Nimbus");

        weather_info = new GWeather.Info (location) {
            contact_info = "danielle@elementary.io"
        };

        var weather_icon = new Gtk.Image.from_icon_name (weather_info.get_icon_name ()) {
            pixel_size = 64
        };

        var weather_label = new Gtk.Label (weather_info.get_sky ()) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.END,
            hexpand = true
        };
        weather_label.add_css_class ("title-3");

        var temp_label = new Gtk.Label (weather_info.get_temp ()) {
            halign = Gtk.Align.START
        };
        temp_label.add_css_class ("title-1");

        var wind_label = new Gtk.Label (weather_info.get_wind ());
        wind_label.add_css_class ("title-4");

        var location_label = new Gtk.Label ("") {
            halign = Gtk.Align.END,
            valign = Gtk.Align.START
        };

        grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.attach (weather_icon, 0, 0, 1, 2);
        grid.attach (temp_label, 1, 0, 1, 2);
        grid.attach (wind_label, 1, 2, 1, 2);
        grid.attach (weather_label, 2, 0);
        grid.attach (location_label, 2, 1);
        grid.add_css_class ("weather");

        spinner = new Gtk.Spinner () {
            halign = Gtk.Align.CENTER,
            vexpand = true,
            spinning = true
        };

        location_disabled_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        var icon = new Gtk.Image.from_icon_name ("face-sad");
        icon.pixel_size = 64;
        var label_info = new Gtk.Label (_("Unable to Get Location"));
        label_info.add_css_class ("title-1");
        var label_description = new Gtk.Label (_("Make sure location access is turned on in settings"));
        label_description.add_css_class ("title-3");
        location_disabled_box.append (icon);
        location_disabled_box.append (label_info);
        location_disabled_box.append (label_description);

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            valign = Gtk.Align.CENTER,
            vhomogeneous = false
        };
        stack.add_child (spinner);
        stack.add_child (grid);
        stack.add_child (location_disabled_box);

        var headerbar = new Adw.HeaderBar();
        headerbar.add_css_class ("flat");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (headerbar);
        box.append (stack);

        set_content (box);

        get_location ();

        notify["is-active"].connect (() => {
            if (stack.visible_child == spinner || !is_active) {
                return;
            }

            if (location == null) {
                get_location ();
            } else {
                weather_info.update ();
            }
        });

        weather_info.updated.connect (() => {
            if (location == null) {
                return;
            }

            location_label.label = dgettext ("libgweather-locations", location.get_city_name ());

            weather_icon.icon_name = weather_info.get_icon_name ();
            weather_label.label = dgettext ("libgweather", weather_info.get_sky ());

            double temp;
            weather_info.get_value_temp (GWeather.TemperatureUnit.CENTIGRADE, out temp);
            temp_label.label = _("%i°").printf ((int) temp);

            double speed;
            GWeather.WindDirection direction;
            weather_info.get_value_wind (GWeather.SpeedUnit.MS, out speed, out direction);
            wind_label.label = _("%s,  %i m/s").printf (direction.to_string(), (int) speed);

            switch (weather_icon.icon_name) {
                case "weather-clear-night":
                case "weather-few-clouds-night":
                    css_classes = {"night", "background", "csd"};
                    break;
                case "weather-few-clouds":
                case "weather-overcast":
                case "weather-showers":
                case "weather-showers-scattered":
                    css_classes = {"showers", "background", "csd"};
                    break;
                default:
                    css_classes = {"day", "background", "csd"};
                    break;
            }
        });
    }

    private void get_location () {
        stack.visible_child = spinner;

        get_gclue_simple.begin ((obj, res) => {
            var simple = get_gclue_simple.end (res);
            if (simple != null) {
                simple.notify["location"].connect (() => {
                    on_location_updated (simple.location.latitude, simple.location.longitude);
                });

                on_location_updated (simple.location.latitude, simple.location.longitude);
            } else {
                stack.visible_child = location_disabled_box;
            }
        });
    }

    private async GClue.Simple? get_gclue_simple () {
        try {
            var simple = yield new GClue.Simple (Application.get_default ().application_id, GClue.AccuracyLevel.CITY, null);
            return simple;
        } catch (Error e) {
            warning ("Failed to connect to GeoClue2 service: %s", e.message);
            return null;
        }
    }

    private void on_location_updated (double latitude, double longitude) {
        location = GWeather.Location.get_world ();
        location = location.find_nearest_city (latitude, longitude);
        if (location != null) {
            weather_info.location = location;
            weather_info.update ();
            stack.visible_child = grid;
        }
    }
}