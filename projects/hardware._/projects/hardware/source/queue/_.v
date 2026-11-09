namespace hardware;

# queue 层：队列族、命令缓冲录制、Fence 时间线同步、多队列并发等待。
#
# 不变量：
# - CommandBuffer 状态机 recording → ended → submitted，仅 ended 可提交，提交后不可再录；
# - 同队列提交按 FIFO 执行，fence 值单调递增；
# - 执行模型两分（合同条款，非缺陷）：CPU 参考后端为立即执行（record 即生效，
#   submit 只做状态与 fence 签发），GPU 后端为延迟执行；conformance 只断言
#   「提交后 fence 可达且结果可见」，不断言「录制后修改的可见性」；
# - 多队列等待（wait_all/wait_any）以 fence 时间线为准，与队列族无关。
