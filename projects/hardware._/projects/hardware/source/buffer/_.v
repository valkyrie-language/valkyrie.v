namespace hardware;

# buffer 层：泛型设备缓冲 Buffer<T>。
#
# host→device 写（write）、device→host 读（read）、device↔device 传输（transfer_to）。
# CPU 后端下缓冲体是普通 V 数组（值语义），传输为函数式重建拷贝；
# 外部后端的分配/传输经 host capability 接入，缺位即 HardwareFault。
