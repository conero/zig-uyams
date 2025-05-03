## 更新日志

> 2025年4月13日
>
> Joshua Conero



### todo

- [ ] `#250503`  zig build 在 ReleaseFast及ReleaseSmall无效（无输出）



### v0.0.3/dev

> cli 功能实现





### v0.0.2/2025-05-03

> cli 基础实现

- **cli**
  - feat: App 通过 hashMap 实现命令注册
  - feat: 新增 App.help 用于注册帮助命令
  - break: Arg.new 时更改其需传递内存分配器
- **example/demo**
  - feat: 加入 demo 用于验证多命令注册
  - pref: 加入help命令




### v0.0.1/2025-04-13

> 基本库架构搭建以及初步实现命令行程序

- **cli**
  - feat: 初步实习默认命令方法函数的调用
- **example/demo**
  - feat: 加入初步的示例方法
- doc: 文件加入库的基本实现用示例