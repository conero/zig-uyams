## 更新日志

> 2025年4月13日
>
> Joshua Conero



### todo

- [x] `#250503`  zig build 在 ReleaseFast及ReleaseSmall无效（无输出）
- [x] `#250510`  新增基础方法用于统计程序运行时间消耗
- [x] `#250530` 新增日期个格式化已经获取本地时间的方法
- [x] `#250603`  demo 包重命名为 `zuymas /zumas`之类的
- [ ] `#250603`  windows 尝试没人修改当前命令行对话中的字符集，使其输出不乱码
- [x] `#250606`  cli 新增选项识别，不支持的选项进行验证提示



### v0.2.0/dev

> 功能实现

- **example/zuymas**
  - break: 将 `example/demo` 重命名为 zuymas
- **date**
  - feat: 新增方法`timeToDay`/`dayToTime` 用于做日期与时间的转换
  - feat: 新增 `Date.incDay` 用于做日期运行，天数加减
  - feat: 新增方法 `Date.subDate` 用于实现连个日期相加
  - feat: 新增方法 `yearLearKind` 用于获取闰年类型
- **cli**
  - feat: `App` 初步实现不存在的选项值校验
  - feat: `App` 新增方法 `commandWith` 和 `commandListWith` 用于直接item注册、
  - feat: `App` 新增方法 `getSubCommond` 获取子命令
  - feat: `Option` 新增方法`getValue`用于获取选项的值
  - feat: `Option` 新增方法`exist/validate`用于判断选项是否设置及数据验证支持
  - break: `App.registersMap` 由单函数调整为struct 扩展操作
- **其他**
  - pref: 删除 zig init 初始化创建的模板函数










### v0.1.0/2025-06-05

> 功能实现，使其基本可用于命令行程序

- **cli**
  - feat/break: 新增 `checkOptList` 方法并调整 `checkOpt` 使用用于检测选项是否存在
  - feat: 新增 Arg 属性用于保存KV键值对数据
  - feat: Arg 新增 get/getInt 方法用于获取选项值，getInt 支持k/w等结尾
  - feat: Arg 新增方法 getF64 用于获取浮点型数据
  - pref: Arg 选项解析完善，支持 “-key value value” 的解析
- **util** (新增)
  - feat: 新增函数 `spendFn` 用于计算程序运行时间耗时
- **date**（新增/实验性）
  - feat: 实现基于时间戳到日期格式生成，以及本地区间格式化

- **number**（新增）
  - feat: 新增函数 `strToInt` 实现字符串转 int
  - feat: 新增函数 `strToF64` 实现字符串转 float64
  - feat: 新增函数 `simplify` 用于对数字进行压缩
- **example/demo**
  - feat: 新增 `time` 命令用于生成当前时间
  - feat: 新增 `version` 命令输出库的版本信息
  - pref: test 命令加入 cmd 展示已经for测试时输出 \r 格式






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