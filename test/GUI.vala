/*
 * brickdm -- Brick Display Manager for LEGO Mindstorms EV3/ev3dev
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
 * GUI.vala:
 *
 * Version of Brick Display Manager that runs if GTK for testing.
 */

using Gee;
using Gtk;
using M2tk;
using U8g;

namespace BrickDisplayManager {
    public class RootInfo {
        public unowned M2tk.Element element;
        public uint8 value;
    }

    class GUI : Object {
        static HashMap<weak GM2tk, weak GUI> gui_map;

        static construct {
            gui_map = new HashMap<weak GM2tk, weak GUI> ();
        }

        Deque<RootInfo> root_stack = new LinkedList<RootInfo> ();

        GM2tk m2tk;
        HomeScreen home_screen;
        NetworkStatusScreen network_status_screen;
        BatteryInfoScreen battery_info_screen;
        ShutdownScreen shutdown_screen;
        BatteryStatusBarItem battery_status_bar_item;
        StatusBar status_bar;
        bool dirty = true;
        bool active { get { return lcd.u8g_active; } }

        public FakeEV3LCDDevice lcd { get; private set; }

        public GUI () {
            lcd = new FakeEV3LCDDevice ();

            GM2tk.init_graphics(lcd.u8g_device, U8gGraphics.font_icon_handler);
            U8gGraphics.set_toggle_font_icon (Font.m2tk_icon_9, 73, 72);
            U8gGraphics.set_radio_font_icon (Font.m2tk_icon_9, 82, 80);
            U8gGraphics.set_additional_text_x_padding (3);
            U8gGraphics.background_color = 255;

            home_screen = new HomeScreen ();
            network_status_screen = new NetworkStatusScreen ();
            battery_info_screen = new BatteryInfoScreen ();
            shutdown_screen = new ShutdownScreen ();
            battery_status_bar_item = new BatteryStatusBarItem ();
            status_bar = new StatusBar ();

            home_screen.add_menu_item ("Network", network_status_screen);
            home_screen.add_menu_item ("Battery", battery_info_screen);
            home_screen.add_menu_item ("Shutdown", shutdown_screen);
            status_bar.add_right (battery_status_bar_item);

            m2tk = new GM2tk (home_screen, event_source, event_handler,
                color_frame_shadow_frame_graphics_handler);
            gui_map[m2tk] = this;
            m2tk.home2 = shutdown_screen;
            m2tk.font[0] = Font.x11_7x13;
            m2tk.font[1] = Font.m2tk_icon_9;
            m2tk.root_element_changed.connect (on_root_element_changed);

            Timeout.add(50, on_draw_timer);
        }

        ~GUI () {
            gui_map.unset(m2tk);
        }

        public static GUI from_gm2tk (GM2tk m2) {
            return gui_map[m2];
        }

        void on_root_element_changed (Element new_root, Element old_root,
            uint8 value)
        {
            if (value != uint8.MAX) {
                var info = new RootInfo ();
                info.element = old_root;
                info.value = value;
                root_stack.offer_head (info);
            }
        }

        /**
         * This function should be exactly the same as the
         * on_draw_timer() function in the real GUI.vala
         */
        bool on_draw_timer () {
            if (active) {
                m2tk.check_key ();
                dirty |= m2tk.handle_key ();
                dirty |= m2tk.root.dirty;
                dirty |= status_bar.dirty;
                if (dirty) {
                    unowned Graphics u8g = GM2tk.graphics;
                    u8g.begin_draw ();
                    m2tk.draw ();
                    if (status_bar.visible)
                        status_bar.draw (u8g);
                    u8g.end_draw ();
                    dirty = false;
                    if (m2tk.root.dirty)
                        m2tk.root.dirty = false;
                    if (status_bar.dirty)
                        status_bar.dirty = false;
                }
            }
            return true;
        }

        static uint8 event_source(M2 m2, EventSourceMessage msg) {
            switch(msg) {
            case EventSourceMessage.GET_KEY:
                switch (Curses.getch ()) {
                /* Actual keys on the EV3 */
                case Curses.Key.DOWN:
                    return Key.EVENT | Key.DATA_DOWN;
                case Curses.Key.UP:
                    return Key.EVENT | Key.DATA_UP;
                case Curses.Key.LEFT:
                    return Key.EVENT | Key.PREV;
                case Curses.Key.RIGHT:
                    return Key.EVENT | Key.NEXT;
                case '\n':
                    return Key.EVENT | Key.SELECT;
                case Curses.Key.BACKSPACE:
                    return Key.EVENT | Key.EXIT;

                /* Other keys in case a keyboard or keypad is plugged in */
                case Curses.Key.BTAB:
                case Curses.Key.PREVIOUS:
                    return Key.EVENT | Key.PREV;
                case Curses.Key.NEXT:
                  return Key.EVENT | Key.NEXT;
                case Curses.Key.ENTER:
                case Curses.Key.OPEN:
                   return Key.EVENT | Key.SELECT;
                case Curses.Key.CANCEL:
                case Curses.Key.EXIT:
                    return Key.EVENT | Key.EXIT;
                case Curses.Key.HOME:
                    return Key.EVENT | Key.HOME;
                case Curses.Key.SHOME:
                    return Key.EVENT | Key.HOME2;
                case Curses.Key.F0+1:
                    return Key.EVENT | Key.Q1;
                case Curses.Key.F0+2:
                    return Key.EVENT | Key.Q2;
                case Curses.Key.F0+3:
                    return Key.EVENT | Key.Q3;
                case Curses.Key.F0+4:
                    return Key.EVENT | Key.Q4;
                case Curses.Key.F0+5:
                    return Key.EVENT | Key.Q5;
                case Curses.Key.F0+6:
                    return Key.EVENT | Key.Q6;
                case '0':
                    return Key.EVENT | Key.KEYPAD_0;
                case '1':
                    return Key.EVENT | Key.KEYPAD_1;
                case '2':
                  return Key.EVENT | Key.KEYPAD_2;
                case '3':
                    return Key.EVENT | Key.KEYPAD_3;
                case '4':
                    return Key.EVENT | Key.KEYPAD_4;
                case '5':
                    return Key.EVENT | Key.KEYPAD_5;
                case '6':
                    return Key.EVENT | Key.KEYPAD_6;
                case '7':
                    return Key.EVENT | Key.KEYPAD_7;
                case '8':
                    return Key.EVENT | Key.KEYPAD_8;
                case '9':
                    return Key.EVENT | Key.KEYPAD_9;
                case '*':
                    return Key.EVENT | Key.KEYPAD_STAR;
                case '#':
                    return Key.EVENT | Key.KEYPAD_HASH;
              }
              return Key.NONE;
            case EventSourceMessage.INIT:
                Curses.cbreak();
                Curses.noecho();
                Curses.stdscr.keypad(true);
                Curses.stdscr.nodelay(true);
                break;
            }
            return 0;
        }

        static uint8 event_handler(M2 m2, EventHandlerMessage msg,
            uint8 arg1, uint8 arg2)
        {
            unowned Nav nav = m2.nav;

            switch(msg) {
            case EventHandlerMessage.SELECT:
                return nav.user_down(true);

            case EventHandlerMessage.EXIT:
                // if there is no valid parent, then go to the previous root
                if (nav.user_up() == 0) {
                    var gm2tk = GM2tk.from_m2 (m2);
                    var gui = GUI.from_gm2tk (gm2tk);
                    var info = gui.root_stack.poll_head();
                    if (info != null) {
                        m2.set_root(info.element, info.value, uint8.MAX);
                    } else {
                        m2.set_root (m2.home2);
                    }
                }
                return 1;

            case EventHandlerMessage.NEXT:
                return nav.user_next();

            case EventHandlerMessage.PREV:
                return nav.user_prev();

            case EventHandlerMessage.DATA_DOWN:
                if (nav.data_down() == 0)
                    return nav.user_next();
                return 1;

            case EventHandlerMessage.DATA_UP:
                if (nav.data_up() == 0)
                    return nav.user_prev ();
                return 1;
            }

            if (msg >= Key.Q1 && msg <= Key.LOOP_END) {
                if (nav.quick_key((Key)msg - Key.Q1 + 1) != 0)
                {
                    if (nav.is_data_entry)
                        return nav.data_up ();
                    return nav.user_down (true);
                }
            }

            if (msg >= ElementCallbackMessage.SPACE) {
                nav.data_char (msg);      // assign the char
                return nav.user_next ();  // go to next position
            }
            return 0;
        }
    }
}