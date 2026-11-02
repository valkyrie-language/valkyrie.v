namespace media;

# media — 媒体生态核心库（OpenCV / FFmpeg 的 Valkyrie 复刻，第一个落地块）。
#
# 分层：
# - image/    图像模型：尺寸、像素格式、打包行布局、边界检查的像素访问
# - color/    颜色模型：像素格式身份、通道语义、格式间转换
# - pipeline/ 处理管线：crop、resize 等图像 → 图像变换
# - codec/    编解码适配器：PPM（P6）、BMP（24 位 BI_RGB）、PNG（容器层 + 滤波重建）
# - video/    视频层锚点（roadmap）：容器解复用、帧序列、PCM 音频
#
# 分层纪律：
# - 字节读取/端序/位流 归 `std.data.binary.codec`，本包不自带端序读取实现；
# - 摘要/校验（CRC-32、Adler-32）归 `std.data.digest`；
# - 压缩（deflate/zlib）归 `std.data.binary.codec`（当前未落地，见 readme）；
# - 文件/网络 IO 是 host capability，不进本包（入口消费已读入的字节数组）。
#
# 数组访问纪律：与 codec 同口径 —— 一律走 `std::collection::array::{get,set,length}`
# 裸合同并自行做边界检查；`⁅ ⁆`/`get`/`unwrap` 包装层携带 panic（raise）路径，
# 与错误容许合同相斥，且当前各后端尚无 raise 目标合同。
#
# 常数纪律：二进制 magic 与格式常数（PNG 签名、BMP 头字段、chunk 类型、
# 尺寸上限）用具名零参函数表达（语言暂无顶层常量声明）；ASCII 记号一律写
# 字符/字节字面量（工具链按形参特化），禁止 `as u32` 后与数字码点比较。
#
# 位运算载道纪律：wasm 后端把 `u32 >> n` 错误 lowering 成左旋，凡右移一律经
# u64 载道取值后截回（同源记录见 `std.data.digest` 头部）。
#
# 诊断码表登记于本包 readme.md；诊断 span 单位为字节偏移（相对输入缓冲起址）。
