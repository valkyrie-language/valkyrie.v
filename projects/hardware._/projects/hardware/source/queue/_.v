namespace hardware;

# queue 层：命令队列 Queue。
#
# 队列绑定单一设备；dispatch 校验队列与输入缓冲同设备。
# CPU 后端同步执行：提交即完成，wait 为空操作，submitted 累计已提交批次数。
# 外部后端的异步提交/ fence / 事件经 host capability 接入（后续块）。
