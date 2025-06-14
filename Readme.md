## Zig-Uymas

> Zig 版本 Uymas
>
> 2025年4月12日
>
> Joshua Conero





基于 [zig](https://github.com/ziglang/zig) （版本v0.14.0+） 的基础库，以加深对zig 的学习，官网地址：https://ziglang.org/ 。





### 使用

使用命令 zig fetch 引入包

```shell
# 安装指定的 commit
zig fetch --save https://github.com/conero/zig-uyams/archive/{commit}.zip

# 自定更新包到 zig.build.zon 中,如
.dependencies = .{
    .zig_uymas = .{
        .url = "https://bgithub.xyz/conero/zig-uyams/archive/fe46f8b6f44478e18290a4ff3a38a3a2a73c758e.zip",
        .hash = "zig_uymas-0.0.0-qNy_KwIaAABwTg1cRaVGdrH7qq6kpnJE0q8GMvM5dp7D",
        // 是否开启懒加载
        .lazy = true,
    },
},
```



build.zig 中加入依赖

```zig
// 加载依赖
const zig_uymas = b.dependency("zig_uymas", .{});

// 加入到 exe 中
const exe = b.addExecutable(.{});

...
// 使用依赖
exe.root_module.addImport("uymas", zig_uymas.module("uymas"));
```



build.zig 中加入赖依赖

```zig
// 懒加载
const zig_uymas = b.lazyDependency("zig_uymas", .{});

// 加入到 exe 中
const exe = b.addExecutable(.{});
if(zig_uymas) |uymas_mod|{
	exe.root_module.addImport("uymas", uymas_mod.module("uymas"));
}
```



main.zig 中使用

```zig
const uymas = @import("uymas");

...
```



### 注意

windows 中文乱码

```shell
# powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

