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
- [x] `#250612` 根据注册的 option 值生成帮助文档
- [x] `#250723` 命令加入网络测试命令（简单的），用于网络编程
- [x] `#250723` 命令加入并发控制测试命令，以作为并发编程测试
- [ ] `#250814` 命令行注册时，返回函数支持泛型处理（即注册多种函数类型）



### v0.2.0/dev

> 功能实现

- **example/zuymas**
  - feat: 加入 tell 命令用于实现网络测试命令
  - feat: 新增命令 interact 用于做交互输入输出
  - feat: 新增命令 cat 用于做文件读取测试
  - feat: 新增命令 thread 用于错误并发测试
  - feat: 新增命令 http 用于模拟web服务器监听
  - feat: 新增命令 echo 用于模拟tcp服务器监听
  - break: 将 `example/demo` 重命名为 zuymas
  - pref: 命令 `test` 优化使其支持数据原始数据已经初步全局命令执行桥接
- **date**
  - feat: 新增方法`timeToDay`/`dayToTime` 用于做日期与时间的转换
  - feat: 新增 `Date.incDay` 用于做日期运行，天数加减
  - feat: 新增方法 `Date.subDate` 用于实现连个日期相加
  - feat: 新增方法 `yearLearKind` 用于获取闰年类型
- **cli**
  - feat: `App` 初步实现不存在的选项值校验
  - feat: `App` 新增方法 `commandWith` 和 `commandListWith` 用于直接item注册、
  - feat: `App` 新增方法 `getSubCommond` 获取子命令
  - feat: `Arg` 新方法 `cmdNext` 用于从重连续命令中获取下一个命令
  - feat: `Arg` 新方法 `getList` 以获取命令列表
  - feat: `Option` 新增方法`getValue`用于获取选项的值
  - feat: `Option` 新增方法`exist/validate`用于判断选项是否设置及数据验证支持
  - feat: 新增方法`RegisterItem.genHelp` 用于初步实现帮助生成
  - feat: 新增方法 `rootPath` 用于获取当前应用所在根目录
  - feat: 新增方法 endHook 用于执行结束时 hook 方法
  - feat: 新增方法 `execAlloc` 以进行快捷的命令行桥接执行
  - feat: 新增结构体 `AppConfig` 用于设置命令是否严格验证选项
  - feat: 新增子集包 `input`，用于命令行输出处理
  - break: `App.registersMap` 由单函数调整为struct 扩展操作
- **string**（新增）
  - feat: 实现方法 `mutable/mutableAlloc` 用于字面字符串转变量
  - feat: 新增 `format` 用于无异常格式化内容
  - feat: 新增方法 `unmanagedListStr` 以将ArrayListUnmanaged转为字符串 
- **number**
  - feat: 新增方法 `formatSizeAlloc` 用于格式化字节类型大小单位转换

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