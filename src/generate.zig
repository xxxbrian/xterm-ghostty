const std = @import("std");
const ghostty = @import("ghostty_terminfo").ghostty;

extern fn write(fd: i32, buf: [*]const u8, count: usize) isize;

pub fn main() !void {
    var buffer: [64 * 1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try ghostty.encode(&writer);
    try writeAllStdout(writer.buffered());
}

fn writeAllStdout(bytes: []const u8) !void {
    var written: usize = 0;
    while (written < bytes.len) {
        const n = write(1, bytes[written..].ptr, bytes.len - written);
        if (n < 0) return error.WriteFailed;
        written += @intCast(n);
    }
}
