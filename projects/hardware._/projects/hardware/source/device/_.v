namespace hardware;

# device 层：设备描述、能力与枚举合同。
#
# Device 是枚举时刻的描述快照：身份（backend_token + ordinal）、kind 词汇与
# capabilities 在枚举时由后端构造完整，消费侧只做纯字段读取，不回调宿主。
# 外部后端（GPU/加速器）的设备在对应 adaptor provider 就位前不参与枚举（fail-closed）。
