## 文档

> 2025年4月12日









### 起步

使用 zig 初始化项目

```shell
# 初始化包
zig init

# zig 格式化
zig fmt ./..


# 编译是指定模式
# 支持 fast, safe, small
zig build --release=fast
# 与上一致
zig build -Doptimize=ReleaseSafe

# 编译时输出g
zig build --summary all
```











### 附录

#### 参考

- [【实战进阶】用Zig高效引入外部库，打造专属命令行神器！](https://blog.csdn.net/xiaodeshi/article/details/139704110)
