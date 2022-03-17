const std = @import("std");
const Self = @This();

step: std.build.Step,
builder: *std.build.Builder,
source: []std.build.FileSource,
defines: [][]const u8,
output_file: std.build.GeneratedFile,
/// Allocates a ZingleHeaderStep, caller owns memory
pub fn create(builder: *std.build.Builder, files: [][]const u8, defines: [][]const u8) *Self {
    var sources = builder.allocator.alloc(std.build.FileSource, files.len) catch unreachable;
    for(files) |v,i| {
        sources[i] = .{.path = builder.allocator.dupe(u8, v) catch unreachable};
    }
    return createSource(builder, sources, defines);
}

/// Allocates a ZingleHeaderStep, caller owns memory
pub fn createSource(builder: *std.build.Builder, sources: []std.build.FileSource, defines: [][]const u8) *Self {
    const self = builder.allocator.create(Self) catch unreachable;
    self.defines = builder.allocator.dupe([]const u8, defines) catch unreachable;
    self.* = Self{
        .step = std.build.Step.init(.custom, "single-header", builder.allocator, make),
        .builder = builder,
        .source = sources,
        .defines = self.builder.dupeStrings(defines),
        .output_file = std.build.GeneratedFile{ .step = &self.step },
    };
    for (sources) |source| {
        source.addStepDependencies(&self.step);
    }
    return self;
}
pub fn getFileSource(self: *const Self) std.build.FileSource {
    return std.build.FileSource{ .generated = &self.output_file };
}

fn make(step: *std.build.Step) !void {
    const self = @fieldParentPtr(Self, "step", step);
    const source_file_name = self.source[0].getPath(self.builder);

    // std.debug.print("source = '{s}'\n", .{source_file_name});

    const basename = std.fs.path.basename(source_file_name);

    const output_name = blk: {
        if (std.mem.indexOf(u8, basename, ".")) |index| {
            break :blk try std.mem.join(self.builder.allocator, ".", &[_][]const u8{
                basename[0..index],
                "c",
            });
        } else {
            break :blk try std.mem.join(self.builder.allocator, ".", &[_][]const u8{
                basename,
                "c",
            });
        }
    };
    var output_buffer = std.ArrayList(u8).init(self.builder.allocator);
    defer output_buffer.deinit();
    var writer = output_buffer.writer();

    for (self.defines) |m| {
        try writer.print("#define {s}\n", .{m});
    }
    for (self.source) |s| {
        try writer.print("#include \"{s}\"\n", .{s.getPath(self.builder)});
    }
    var hash = std.crypto.hash.blake2.Blake2b384.init(.{});

    hash.update("C9XVU4MxSDFZz2to");

    hash.update(basename);
    hash.update(output_buffer.items);
    var digest: [48]u8 = undefined;
    hash.final(&digest);

    var hash_basename: [64]u8 = undefined;
    _ = std.fs.base64_encoder.encode(&hash_basename, &digest);
    const output_dir = try std.fs.path.join(self.builder.allocator, &[_][]const u8{
        self.builder.cache_root,
        "o",
        &hash_basename,
    });

    var dir = std.fs.cwd().makeOpenPath(output_dir, .{}) catch |err| {
        std.debug.print("unable to make path {s}: {s}\n", .{ output_dir, @errorName(err) });
        return err;
    };

    self.output_file.path = try std.fs.path.join(self.builder.allocator, &[_][]const u8{
        output_dir,
        output_name,
    });

    dir.writeFile(output_name, output_buffer.items) catch |err| {
        std.debug.print("unable to write {s} into {s}: {s}\n", .{
            output_name,
            output_dir,
            @errorName(err),
        });
        return err;
    };
}

/// Allocates a ZingleHeaderStep, caller owns memory
pub fn addSingleHeaderFiles(exeLibObj: *std.build.LibExeObjStep, paths: [][]const u8, defines: [][]const u8, flags: [][]const u8) *Self {
    var zingle_step = create(exeLibObj.builder, paths, defines);
    zingle_step.step.make() catch unreachable;
    var cSource = std.build.CSourceFile{ .source = zingle_step.getFileSource(), .args = flags };
    exeLibObj.step.dependOn(&zingle_step.step);
    exeLibObj.addCSourceFileSource(cSource);
    return zingle_step;
}
pub fn addSingleHeaderFile(exeLibObj: *std.build.LibExeObjStep, path: []const u8, defines: [][]const u8, flags: [][]const u8) *Self {
    return addSingleHeaderFiles(exeLibObj,&.{path},defines,flags);
}

pub fn free(self: *const Self) void {
    for (self.defines) |v| {
        self.builder.allocator.free(v);
    }
    for(self.source) |v| {
        self.builder.allocator.free(v.path);
    }
    self.builder.allocator.free(self.defines);
    self.builder.allocator.free(self.source);
    self.builder.allocator.destroy(self);
}
