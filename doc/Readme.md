## 文档

> 2025年4月12日









### 起步

使用 zig 初始化项目

```shell
# 初始化包
zig init

# zig 格式化
zig fmt ./..
zig 

# zig 本地标准文档打开
zig std

# 编译是指定模式
# 支持 fast, safe, small
# 经测试，fast 模式确实可加快运行速度
zig build --release=fast
# 与上一致
zig build -Doptimize=ReleaseSafe

# 编译时输出概述
zig build --summary all

# 编译并执行
zig build run

# 跨环境编译
zig build -Doptimize=ReleaseSmall -Dtarget=x86_64-linux-gnu

# zig build 打印相信输出日志
zig build -freference-trace=10

# 文档生成
cd gendoc
zig build-lib -femit-docs=uymasdocs ../src/lib.zig
```











### 附录

#### 参考

- [【实战进阶】用Zig高效引入外部库，打造专属命令行神器！](https://blog.csdn.net/xiaodeshi/article/details/139704110)
- 中国 zig 社区，https://github.com/zigcc
