namespace container;

# container — 容器生态核心合同。
#
# 承载算法无关的通用概念：内容寻址（digest 文法 + 算法族注册）、Descriptor、
# media type 注册表、Layer / 层链、Image / ImageConfig、Reference、ContentStore /
# Registry 合同、运行时模型、失败模型。OCI / Docker / k8s 都是它之上的规范化落地。
#
# 分层纪律：
# - 算法计算（sha256/sha512）与 hex 编码归 `std.data.digest`，本包只按算法名分发，
#   绝不重写哈希。
# - 文法层解析（digest/reference 字符串）错误容许，走 `std.data::DataOutcome` 诊断；
#   内容层与存储/完整性/运行时失败是硬失败，走 `ContainerFailure` 语言错误通道。
# - media type 不硬编码字符串分支，经注册表 + kind 分类；具体类型由各规范包注册。
# - registry 网络访问是独立 host capability，本包只立接口。
