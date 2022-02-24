const std = @import("std");
const stbImage = @cImport(@cInclude("stb_image.h"));
pub fn main() anyerror!void {
    _ = stbImage;
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
