namespace yyds.kv;

# yyds.kv — yyds 的 KV 存储内核（Valkyrie 实现）
#
# 内核只拥有分片（shard）级合同：键、记录值、记录、扫描与提交边界。
# 查询、schema、事务编排与协议归 yydb / yyds 上层产品，不进内核。
# 本包为纯计算实现，不依赖文件、网络或并发 host 能力。
