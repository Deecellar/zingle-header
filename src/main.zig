const std = @import("std");
const hello = @cImport(@cInclude("hello.h"));
pub fn main() anyerror!void {
    hello.helloWorld();
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
