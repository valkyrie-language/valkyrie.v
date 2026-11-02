namespace database;

# 持久化后端的 provider 合同面（先合同、不实现）。
#
# 文件后端需要的最小宿主能力集合：打开/读/写/刷盘/原子替换/长度/关闭 + 目录同步。
# 每个 [host_contract] 是目标私有 provider 的绑定槽；无 provider 的目标在链接期
# 结构化失败。本面当前未被任何代码路径调用——内存引擎不消费它；文件引擎在
# provider 就位前不参与 `database_open`（fail-closed，不伪造持久性）。
#
# 句柄与错误约定：非负 i64 为有效句柄/成功码，负值为宿主错误，由 V 侧映射为
# 结构化失败；路径与负载均为不透明字节。

# 打开或创建文件，返回句柄（负值为宿主错误）。
[host_contract]
micro database_host_file_open(path: [u8], create_if_missing: bool) -> i64

# 读取 handle 的 [offset, offset + buffer.length) 区间，返回实际读取字节数（负值为错误）。
[host_contract]
micro database_host_file_read(handle: i64, offset: i64, buffer: [u8]) -> i64

# 把 bytes 写入 handle 的 offset 处，返回写入字节数（负值为错误）。
[host_contract]
micro database_host_file_write(handle: i64, offset: i64, bytes: [u8]) -> i64

# 文件长度（负值为错误）。
[host_contract]
micro database_host_file_length(handle: i64) -> i64

# 刷盘：把文件数据与元数据压入持久介质（0 成功，负值为错误）。
[host_contract]
micro database_host_file_sync(handle: i64) -> i64

# 原子替换：以 temp 路径内容替换目标路径（同目录内；0 成功，负值为错误）。
# 替换本身的持久性由 `database_host_directory_sync` 补全。
[host_contract]
micro database_host_file_replace(target_path: [u8], temp_path: [u8]) -> i64

# 目录同步：让目录项（创建/替换）持久（0 成功，负值为错误）。
[host_contract]
micro database_host_directory_sync(path: [u8]) -> i64

# 关闭句柄（幂等；0 成功，负值为错误）。
[host_contract]
micro database_host_file_close(handle: i64) -> i64
