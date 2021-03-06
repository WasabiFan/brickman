/*
 * brickman -- Brick Manager for LEGO Mindstorms EV3/ev3dev
 *
 * Copyright (C) 2014 David Lechner <david@lechnology.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * NetworkConnectionMenuItem.vala: Custom MenuItem for showing network connection status.
 */

using EV3devKit;

namespace BrickManager {
    public class NetworkConnectionMenuItem : EV3devKit.MenuItem {
        const string PERCENT = "%";

        Label signal_strength_label;

        public string connection_name {
            get { return label.text; }
            set { label.text = value; }
        }

        int _signal_strength;
        public int signal_strength {
            get { return _signal_strength; }
            set {
                _signal_strength = value;
                if (value == 0)
                    signal_strength_label.text = null;
                else
                    signal_strength_label.text = "%d%s".printf (value, PERCENT);
            }
        }

        public NetworkConnectionMenuItem () {
            base.with_button (new Button (), new Label ());
            button.pressed.connect (on_button_pressed);
            var hbox = new Box.horizontal ();
            button.add (hbox);
            hbox.add (label);
            hbox.add (new Spacer ());
            signal_strength_label = new Label ();
            hbox.add (signal_strength_label);
        }

        void on_button_pressed () {
            if (menu == null)
                return;
            var network_connections_window = menu.window as NetworkConnectionsWindow;
            if (network_connections_window == null)
                return;
            network_connections_window.connection_selected (represented_object);
        }
    }
}
