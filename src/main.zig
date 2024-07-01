const std = @import("std");
const c = @cImport({
    @cInclude("libnotify/notify.h");
});

pub fn main() !void {
    const check_interval = 60; // in seconds

    _ = c.notify_init("init");

    // Paths
    var buf1: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var buf2: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const bat_cur_path = try std.fs.realpath("/sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0C0A:00/power_supply/BAT0/energy_now", &buf1);
    const bat_max_path = try std.fs.realpath("/sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0C0A:00/power_supply/BAT0/energy_full", &buf2);

    while (true) {
        // Open battery information files
        const cur_file = try std.fs.openFileAbsolute(bat_cur_path, .{});
        const max_file = try std.fs.openFileAbsolute(bat_max_path, .{});
        defer cur_file.close();
        defer max_file.close();

        // Read the informations
        var bat_cur_buffer: [1024]u8 = undefined;
        var bat_max_buffer: [1024]u8 = undefined;
        const cur_size = try cur_file.read(&bat_cur_buffer);
        const max_size = try max_file.read(&bat_max_buffer);
        const bat_cur = try std.fmt.parseInt(u64, bat_cur_buffer[0 .. cur_size - 1], 10); // -1 because of the EOF
        const bat_max = try std.fmt.parseInt(u64, bat_max_buffer[0 .. max_size - 1], 10); // -1 because of the EOF

        std.debug.print("Battery energy: {d} for max of {d}\n", .{ bat_cur, bat_max });
        const percentage: f64 = @as(f64, @floatFromInt(bat_cur)) / @as(f64, @floatFromInt(bat_max)) * 100.0;
        std.debug.print("Battery percentage: {d}\n", .{percentage});

        if (percentage < 25.0) {
            const n = c.notify_notification_new("Your computer is hungry for energy 🧟🤤!", "Miam miam I need energy🪫🪫🪫", "dialog-information");
            _ = c.notify_notification_show(n, null);
        }

        std.time.sleep(check_interval * std.time.ns_per_s);
    }

    c.notify_uninit();
}
