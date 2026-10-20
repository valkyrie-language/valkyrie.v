# 编译器自举证明合同

本合同仅定义证明术语，不安排当前实现工作。当前交付是全部理想 solution.v 的 nyar/wasm 真实题意矩阵，自举不替代它。

## 输入与世代

每一代均从完整、当前、已冻结的 manifests/source 依赖闭包独立编译，记录实际来源、内容、Compiler/host/target/profile 与 artifact digest。

- seed-package-built：Rust 装配层可重复生成完整 Wasm/Node seed 包。
- seed-package-runnable：Node 可执行 seed 包 CLI。
- source-bootstrap：seed 从当前 V 源码生成完整、可运行的 Legion candidate。
- self-hosted：V 产出的 candidate 自己运行，从同一完整当前 V 源码闭包生成下一代。
- stage-converged：相邻 V generations 的确定性 canonical ArtifactSet 与 run contract 收敛。
- bootstrap-proven：self-hosted、收敛、真实执行和反作弊证据全部成立。

版本输出、smoke、一次 Rust→V 编译不能称 self-hosted。未来发布门槛需要的证明必须完整记录，不能由脚本存在、局部绿色或其他 target 代替。

## Compiler 边界

Legion 只调用 WorkspaceResolver、Compiler、ArtifactStore。绑定、实例/evidence 需求固定点、HIR/Semantic MIR、linker 和 backend plans 都由 Compiler 拥有。

禁止宿主代编译、网络兜底、预解析图注入、body_source 重解析、复制旧 artifact、跳阶段或 compatible success wrapper。核心依赖来源必须显式冻结，不能失效后静默换 registry 包。

## 证明记录

每代记录命令、真实退出状态、输入及产物清单/摘要、来源、export/invoke 与结果。跳过、缺字段、未执行、部分产物或无法复核均为未通过。

确定性比较包含规定范围的产物和运行合同；任何允许差异必须有明确格式原因及规范化规则，不能笼统忽略 glue 或 metadata。V candidate 无法编译时停止该证明，不生成或比较旧下一代文件。
