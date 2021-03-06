/*
 * connman -- DBus bindings for ConnMan <https://01.org/connman>
 *
 * Copyright (C) 2014 David Lechner <david@lechnology.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY throws IOError; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Manager.vala:
 */

using Gee;

namespace ConnMan {
    public class Manager : Object {
        net.connman.Manager dbus_proxy;

        public ManagerState state {
            get { return dbus_proxy.state; }
        }

        public bool offline_mode {
            get { return dbus_proxy.offline_mode; }
            set {
                if (value == offline_mode)
                    return;
                try {
                    dbus_proxy.set_property_sync ("OfflineMode", value);
                } catch (Error err) {
                    critical ("%s", err.message);
                }
            }
        }

        public signal void technology_added (Technology technology);
        public signal void technology_removed (ObjectPath path);
        public signal void services_changed (GenericArray<Service> changed, ObjectPath[] removed);

        public static async Manager new_async () throws IOError {
            var manager = new Manager ();
            weak Manager weak_manager = manager;
            manager.dbus_proxy = yield Bus.get_proxy (BusType.SYSTEM,
                net.connman.SERVICE_NAME, net.connman.Manager.OBJECT_PATH);
            manager.dbus_proxy.property_changed.connect (weak_manager.on_property_changed);
            var properties = yield manager.dbus_proxy.get_properties ();
            properties.foreach ((k, v) =>
                ((DBusProxy)manager.dbus_proxy).set_cached_property (k, v));
            manager.dbus_proxy.technology_added.connect (weak_manager.on_technology_added);
            manager.dbus_proxy.technology_removed.connect (weak_manager.on_technology_removed);
            manager.dbus_proxy.services_changed.connect (weak_manager.on_services_changed);
            return manager;
        }

        public async Gee.List<Technology> get_technologies () throws IOError {
            var technologies = yield dbus_proxy.get_technologies ();
            var result = new ArrayList<Technology> ();
            foreach (var item in technologies) {
                var tech = yield Technology.from_path (item.path);
                item.properties.foreach ((k, v) =>
                    ((DBusProxy)tech.dbus_proxy).set_cached_property(k, v));
                result.add (tech);
            }
            return result;
        }

        public async GenericArray<Service> get_services () throws IOError {
            var services = yield dbus_proxy.get_services ();
            var result = new GenericArray<Service> ();
            foreach (var item in services) {
                var serv = yield Service.from_path (item.path);
                item.properties.foreach ((k, v) =>
                    ((DBusProxy)serv.dbus_proxy).set_cached_property (k, v));
                result.add (serv);
            }
            return result;
        }

        public async Gee.List<Peer> get_peers () throws IOError {
            var peers = yield dbus_proxy.get_peers ();
            var result = new ArrayList<Peer> ();
            foreach (var item in peers) {
                var peer = yield Peer.from_path (item.path);
                item.properties.foreach ((k, v) =>
                    ((DBusProxy)peer.dbus_proxy).set_cached_property (k, v));
                result.add (peer);
            }
            return result;
        }

        public async void register_agent (ObjectPath path) throws IOError {
            yield dbus_proxy.register_agent (path);
        }

        public async void unregister_agent (ObjectPath path) throws IOError {
            yield dbus_proxy.unregister_agent (path);
        }

        void on_technology_added (ObjectPath path, HashTable<string, Variant> properties) {
            try {
                var tech = Technology.from_path_sync (path);
                properties.foreach ((k, v) =>
                    ((DBusProxy)tech.dbus_proxy).set_cached_property (k, v));
                technology_added (tech);
            } catch (IOError err) {
                critical ("%s", err.message);
            }
        }

        void on_technology_removed (ObjectPath path) {
            technology_removed (path);
        }

        void on_services_changed (net.connman.ManagerObject[] changed, ObjectPath[] removed) {
            try {
                var services = new GenericArray<Service>();
                foreach (var item in changed) {
                    var service = Service.from_path_sync (item.path);
                    item.properties.foreach ((k, v) =>
                        service.on_property_changed (k, v));
                    services.add (service);
                }
                services_changed (services, removed);
            } catch (IOError err) {
                critical ("%s", err.message);
            }
        }

        void on_property_changed (string name, Variant? value) {
            ((DBusProxy)dbus_proxy).set_cached_property (name, value);
            switch (name) {
            case "State":
                notify_property ("state");
                break;
            case "OfflineMode":
                notify_property ("offline-mode");
                break;
            default:
                critical ("Unknown dbus property '%s'", name);
                break;
            }
        }
    }

    [DBus (use_string_marshalling = true)]
    public enum ManagerState {
        [DBus (value = "offline")]
        OFFLINE,
        [DBus (value = "idle")]
        IDLE,
        [DBus (value = "ready")]
        READY,
        [DBus (value = "online")]
        ONLINE;
    }
}

namespace net.connman {
    public const string SERVICE_NAME = "net.connman";

    [DBus (name = "net.connman.Manager")]
    public interface Manager : Object {
        public const string OBJECT_PATH = "/";

        public abstract async HashTable<string, Variant> get_properties () throws IOError;
        public abstract async void set_property (string name, Variant? value) throws IOError;
        [DBus (name = "SetProperty")]
        public abstract void set_property_sync (string name, Variant? value) throws IOError;
        public abstract async ManagerObject[] get_technologies () throws IOError;
        public abstract async ManagerObject[] get_services () throws IOError;
        public abstract async ManagerObject[] get_peers () throws IOError;
        // deprecated
        //public abstract async ObjectPath ConnectProvider (HashTable<string, Variant> provider throws IOError;
        //public abstract async void remove_provider (ObjectPath path) throws IOError;
        public abstract async void register_agent (ObjectPath object) throws IOError;
        public abstract async void unregister_agent (ObjectPath object) throws IOError;
        public abstract async void register_counter (ObjectPath path, uint accuracy, uint period) throws IOError;
        public abstract async void unregister_counter (ObjectPath path) throws IOError;
        public abstract async ObjectPath create_session (HashTable<string, Variant> settings, ObjectPath notifier) throws IOError;
        public abstract async void destroy_session (ObjectPath session) throws IOError;
        public abstract async ObjectPath request_private_network (HashTable<string, Variant> options, out HashTable<string, Variant> fd) throws IOError;
        public abstract async void release_private_network (ObjectPath path) throws IOError;

        public signal void technology_added (ObjectPath path, HashTable<string, Variant> properties);
        public signal void technology_removed (ObjectPath path);
        public signal void services_changed (ManagerObject[] changed, ObjectPath[] removed);
        public signal void peers_changed (ManagerObject[] changed, ObjectPath[] removed);
        public signal void property_changed (string name, Variant? value);

        public abstract ConnMan.ManagerState state { get; }
        public abstract bool offline_mode { get; }
        // deprecated
        //public abstract bool session_mode { get; }
    }

    public struct ManagerObject {
        ObjectPath path;
        HashTable<string, Variant> properties;
    }
}
