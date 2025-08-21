const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // 创建一个库
    const uymasMod = b.addModule("uymas", .{
        .root_source_file = b.path("src/lib.zig"),
    });

    // 编译用例-demo
    const example_demo = b.addExecutable(.{
        .name = "zuymas",
        .root_module = b.createModule(.{
            // b.createModule defines a new module just like b.addModule but,
            // unlike b.addModule, it does not expose the module to consumers of
            // this package, which is why in this case we don't have to give it a name.
            .root_source_file = b.path("example/zuymas/main.zig"),
            // Target and optimization levels must be explicitly wired in when
            // defining an executable or library (in the root module), and you
            // can also hardcode a specific target for an executable or library
            // definition if desireable (e.g. firmware for embedded devices).
            .target = target,
            .optimize = optimize,
            // List of modules available for import in source files part of the
            // root module.
            .imports = &.{
                // Here "init_015" is the name you will use in your source code to
                // import this module (e.g. `@import("init_015")`). The name is
                // repeated because you are allowed to rename your imports, which
                // can be extremely useful in case of collisions (which can happen
                // importing modules from different packages).
                .{ .name = "uymas", .module = uymasMod },
            },
        }),
    });
    example_demo.root_module.addImport("uymas", b.modules.get("uymas").?);
    //example_demo.step.dependOn(b.getInstallStep());

    // window 下无 libc 时，使用如下进行编译。
    // --library c   表明不依赖任何系统文件！
    // zig build-exe hi.zig --library c
    // 链接 C 标准库
    example_demo.linkLibC();
    b.installArtifact(example_demo);

    // 程序运行
    const run_demo = b.addRunArtifact(example_demo);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_demo.step);
    //if (b.args) |args| {
    //    run_demo.addArgs(args);
    //}
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_demo.step);

    //_ = b.addRunArtifact(example_demo);
}
