# hardware.conformance

`hardware` 七层合同的 conformance 套件：**同一套按合同项逐条跑，每个注册后端必须全过**。

## 组织与验收口径

- 用例按合同项编号（`C<层><序>`），正反成对；blocked/pending 不计通过。
- 后端注册表参数化（`source/_.v` 的 `conformance_backends`）：当前仅 CPU；真后端经 adaptor 块接入后登记，同一套用例自动复跑。
- CPU 全绿（wasm 真实执行）是进入真后端块的唯一门禁；旧「单后端自证」口径不算验收。
- `[test]` 套件为长期交付物；执行载体当前走消费方 `[export]` harness。

## 用例矩阵

### L1 适配器/设备
| 编号 | 用例 |
|---|---|
| C101 | 枚举恰含 CPU adapter，kind/身份正确 |
| C102 | `adapter_limits` 字段全正且达合同最小档 |
| C103 | `adapter_features` 含 compute+transfer 位 |
| C104 | request 子集 features → Fine |
| C105 | request 超集 → Fail(feature_missing=1006)（反） |
| C106 | device 的 features/limits 与 adapter 快照一致（冻结） |

### L2 内存模型
| 编号 | 用例 |
|---|---|
| C201 | create_heap(unified) → Fine，class/容量正确 |
| C202 | 越容分配 → Fail(out_of_memory=1004)（反） |
| C203 | 非法对齐（非 2 幂） → Fail(alignment_invalid=1008)（反） |
| C204 | device_local 缓冲直接 map → Fail（反） |
| C205 | map_write → 写入 → unmap → 设备侧读回一致（相干性） |
| C206 | 会话未关闭重复 map → Fail(map_conflict=1012)（反） |
| C207 | staging→device_local→staging 往返内容一致 |
| C208 | unmap 后旧 epoch 令牌操作 → Fail（反） |
| C209 | usage 超设备支持 → Fail(usage_not_supported=1007)（反） |

### L3 队列与提交
| 编号 | 用例 |
|---|---|
| C301 | request_queue(compute/transfer) → Fine；无 graphics feature 请求 → Fail（反） |
| C302 | 未 command_end 提交 → Fail(command_state_invalid=1010)（反） |
| C303 | 提交后 fence 值 = 提交序号且 `fence_wait` 立即 true |
| C304 | 同队列两次提交 FIFO：计数与 fence 值单调递增 |
| C305 | 双队列提交，`fences_wait_all` 成功（并发等待合同） |
| C306 | record copy：staging 两端拷贝内容正确 |
| C307 | 提交后的 cmd 再录制/再提交 → Fail（反） |

### L4 计算管线
| 编号 | 用例 |
|---|---|
| C501 | 手工字节码（const/workitem_id/load/add/store/return）建 module/pipeline → Fine |
| C502 | 非法 opcode / 寄存器越界 / 槽引用越界 → Fail(shader_invalid=1013)（反） |
| C503 | store 指向 storage_read 槽 → pipeline_create Fail（反） |
| C504 | 绑定槽集合 ≠ 布局 → bind_group_validate Fail(bind_layout_mismatch=1011)（反） |
| C505 | 双倍映射确定性基准：wg=4、grid(1,1,1)，[1,2,3,4]→[2,4,6,8] |
| C506 | dispatch 越界读 → Fail（反） |
| C507 | dispatch(0,·,·)/超限维 → Fail(dispatch_exceeds_limits=1009)（反） |
| C508 | 双槽 A+B→C 逐元素正确 |
| C509 | workgroup_id 寻址：grid(2,1,1)×wg(2)，各 lane 写 gid*2+lid |
| C510 | barrier 存在且顺序语义确定（CPU 冻结遍历） |

### L5 渲染资源（合同 only）
| 编号 | 用例 |
|---|---|
| C601 | 尺寸 0 texture → Fail(validation)（反） |
| C602 | 合法 texture 创建字段冻结（CPU 实现 pending → blocked，不计通过） |

### L6 故障与恢复
| 编号 | 用例 |
|---|---|
| C701 | 注册表码↔分类↔可恢复三元组全量查表一致 |
| C702 | OOM recoverable=true、device_lost recoverable=false 判定 |
| C703 | lost 设备上的操作 → device_lost=1005（CPU 提供显式 debug mark_lost 入口验恢复路径，标调试专用） |
