## 更新日志

> 2025年4月13日
>
> Joshua Conero



### todo

- [ ] `#250503`  zig build 在 ReleaseFast及ReleaseSmall无效（无输出）
- [ ] `#250510`  新增基础方法用于统计程序运行时间消耗



### v0.1.0/dev

> 功能实现，使其基本可用于命令行程序

- **cli**
  - feat/break: 新增 `checkOptList` 方法并调整 `checkOpt` 使用用于检测选项是否存在
  - feat: 新增 Arg 属性用于保存KV键值对数据
  - feat: Arg 新增 get/getInt 方法用于获取选项值
- **util** (新增)
  - feat: 新增函数 `spendFn` 用于计算程序运行时间耗时




### v0.0.3/2025-05-10

> cli 功能实现，Arg 实现选项列表及选项键值对存储

- **cli**
  - feat: 新增方法 Arg.checkOpt 用于检测选项是否存在
  - feat: Arg 支持选项键值对存储
  - feat: Arg 新增方法 getOptList 用于获取属性列表
  - break: 将注册回调函数变量参数由`*const Arg`调整为`*Arg` 
  - fix: 重写 Arg 实例化函数，并修复 `error.Unexpected: GetLastError(998): 内存位置访问无效` 的错误
- **example/demo**
  - pref: test 命令加入选项值输出






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