// 命令解析
pub const Arg = struct {
    /// 命令
    command: []u8,
    /// 选项
    options: [][]u8,
};
