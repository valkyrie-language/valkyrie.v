# 编译器自举证明

自举是独立证明，不是当前 LeetCode nyar/wasm 题意矩阵的替代品。

seed 从当前 V 源码生成一次完整 candidate 称 source-bootstrap；V candidate 自行从完整当前 manifests/source 闭包生成下一代才称 self-hosted。还需确定性产物与 run contract 收敛、真实执行及完整反作弊证据，才能称 bootstrap-proven。

[完整证明合同](../../../../projects/legion._/projects/legion.tools/documentation/pages/zh-hans/bootstrap-contract.md)定义输入、世代与记录要求。本页不维护实现状态、target 工作包或发布门禁流水账。
