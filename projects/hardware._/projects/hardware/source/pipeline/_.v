namespace hardware;

# pipeline 层：ShaderModule → ComputePipeline → BindGroup → dispatch(x, y, z) 计算管线。
#
# 合同要点：
# - shader 程序为扁平 [i64] 定长 4 字字节码（opcode, a0, a1, a2）+ 元数据标量；
#   寄存器机、线性流、v1 无控制流；该 IR 同时是 CPU 解释器输入与各 GPU 后端的翻译源；
# - pipeline 创建即冻结 module 拷贝（值语义），布局槽位声明与 shader 内 storage 指令双向校验；
# - store 指令的目标槽必须声明 storage_read_write；绑定槽集合必须恰好等于布局；
# - BindGroup 是布局关校验凭证；实体资源由 dispatch 调用点的资源表参数携带，
#   GPU provider 侧的描述符集持有不受 V 侧聚合约束牵连；
# - CPU 遍历顺序冻结（group 字典序 z→y→x、lane 字典序 x→y→z），作确定性数值基准。
