# media

媒体生态核心库：图像模型（尺寸、像素格式、行布局）、颜色转换、处理管线（crop、resize）与图像编解码适配器（PPM、BMP、PNG）。OpenCV / FFmpeg 复刻的第一个落地块。

## 边界

- 本包承载图像的内存模型与格式适配：字节流 ↔ `MediaRaster`。
- 字节读取/端序/位流归 `std.data.binary.codec`；本包经 `DataByteCursor` 消费，不自带端序读取实现。
- CRC-32 / Adler-32 校验归 `std.data.digest`；deflate/zlib 解压归 `std.data.binary.codec`（当前未落地）。
- 文件/网络 IO 是 host capability，不进本包；入口消费已读入的 `[u8]`。
- 数组访问走 `std::collection::array::{get,set,length}` 裸合同并自行边界检查；不用携带 panic 路径的包装层（与错误容许合同相斥）。

## 分层

| 目录 | 职责 |
|:---|:---|
| `source/image/` | `MediaRaster` 模型：尺寸、像素格式、打包行布局、边界检查访问 |
| `source/color/` | 像素格式身份、通道语义、格式间转换（gray/rgb/rgba） |
| `source/pipeline/` | 图像 → 图像变换：crop、resize（最近邻） |
| `source/codec/` | 格式适配器：PPM（P6）、BMP（24 位 BI_RGB）、PNG（容器层 + 滤波重建） |
| `source/video/` | 视频层锚点（尚未落地，见「规划方向」） |

## 诊断码表

按 `std.data` 三态产出合同，码由格式侧自定义并在包内登记。除注明外严重度为 Error；span 单位为字节偏移（相对输入缓冲起址）。

| 码 | 语义 |
|:---|:---|
| `media.image.empty_dimension` | 宽度或高度为 0 |
| `media.image.too_large` | 像素字节总量超过 2^32-1（单侧上限 2^24） |
| `media.image.buffer_length_mismatch` | 像素缓冲长度与 宽×高×通道 不符 |
| `media.image.out_of_bounds` | 像素坐标越界 |
| `media.image.bad_channel` | 通道下标越出像素格式通道数 |
| `media.pipeline.empty_target` | 目标尺寸为 0 |
| `media.pipeline.crop_out_of_bounds` | 裁剪区域越出源图 |
| `media.ppm.bad_magic` | 魔数非 `P6`/`P3` |
| `media.ppm.unsupported_variant` | `P3`（ASCII 栅格）暂不提供 |
| `media.ppm.bad_header_byte` | 头段出现非数字非空白字节 |
| `media.ppm.truncated_header` | 头段 token 未读完输入即耗尽 |
| `media.ppm.unsupported_maxval` | maxval ≠ 255 |
| `media.ppm.truncated_raster` | 栅格字节数不足 宽×高×3 |
| `media.ppm.trailing_bytes` | （Warning）栅格后有多余字节 |
| `media.bmp.bad_magic` | 魔数非 `BM` |
| `media.bmp.truncated_header` | 54 字节头未读完输入即耗尽 |
| `media.bmp.size_field_mismatch` | （Warning）文件长度与头声明不符 |
| `media.bmp.unsupported_header_size` | INFOHEADER 尺寸 ≠ 40 |
| `media.bmp.invalid_dimension` | 宽度或高度为 0，或宽度为负 |
| `media.bmp.unsupported_layout` | 高度为负（top-down 行序）暂不提供 |
| `media.bmp.bad_planes` | planes 字段 ≠ 1 |
| `media.bmp.unsupported_bit_depth` | 位深 ≠ 24 |
| `media.bmp.unsupported_compression` | 压缩方式 ≠ 0（BI_RGB） |
| `media.bmp.bad_data_offset` | 像素数据偏移越界或小于头长 |
| `media.bmp.truncated_raster` | 行数据（含 4 字节对齐填充）不足 |
| `media.png.truncated_signature` | 不足 8 字节签名 |
| `media.png.bad_signature` | 签名不符 |
| `media.png.truncated_chunk` | chunk 头/数据/CRC 截断 |
| `media.png.crc_mismatch` | chunk CRC-32 校验不符（不中断遍历） |
| `media.png.missing_ihdr` | 首个 chunk 非 IHDR 或 IHDR 非法 |
| `media.png.bad_ihdr_length` | IHDR 数据 ≠ 13 字节 |
| `media.png.invalid_dimension` | IHDR 宽度或高度为 0 |
| `media.png.unsupported_bit_depth` | 位深 ≠ 8 |
| `media.png.unsupported_color_type` | 颜色类型非 0/2/6（调色板与 gray+alpha 未落地，见「当前已知限制」） |
| `media.png.bad_compression_method` | IHDR 压缩方法字节 ≠ 0 |
| `media.png.bad_filter_method` | IHDR 滤波方法字节 ≠ 0 |
| `media.png.unsupported_interlace` | Adam7 隔行暂不提供 |
| `media.png.unknown_critical_chunk` | 未知关键 chunk（不中断遍历） |
| `media.png.missing_idat` | 无 IDAT |
| `media.png.missing_iend` | 流结束于 IEND 之前 |
| `media.png.inflate_unavailable` | IDAT 解压依赖 `std.data.binary.codec` 的 deflate（当前未落地） |
| `media.png.unfilter_length_mismatch` | 滤波重建输入长度 ≠ 高×(1+行字节) |
| `media.png.unknown_filter_type` | 扫描线滤波类型 > 4 |

## 当前已知限制

本包在这些边界上如实失败，不硬编码、不 fallback：

- **deflate/zlib 解压**：`std.data.binary.codec` 尚无 inflate 实现。PNG 解码在 IDAT 聚合完成后停于 `media.png.inflate_unavailable` 结构化诊断，几何信息（宽/高/像素格式）仍经部分结果返回。
- **raise/panic 后端合同**：`[test]` 内的 `std::types::panic` 在后端尚无 raise 目标合同，编译阶段结构化失败；本包 `test/` 正反测试当前编译受阻，运行时验证经 `examples/media-drive` 的值返回探针产出。
- **编译验证暂不提供**：当前工具链在跨文件调用解析上存在阻塞，`test/` 复跑待工具链修复。
- **字节文件读取**：无 `read_file_bytes` host contract，fixture 以字节字面量内嵌于 `test/fixtures.v`（含推导注释），不落盘。
- **PNG 颜色类型 4（gray+alpha）**：像素格式模型当前无 `GrayAlpha8`，按 `media.png.unsupported_color_type` 结构化失败；随颜色模型扩展补。

## 规划方向

1. 图像模型、PPM/BMP 读写、PNG 容器层与滤波重建、resize/crop（已落地）
2. codec 层 deflate 落地后接通 PNG 解码全链；PNG 编码；PPM `P3`、BMP top-down 与 32 位位深
3. JPEG 基线解码、GIF、WebP
4. `video/` 层：MP4/MKV 容器与解复用、帧序列模型
5. PCM 音频基础（采样格式、声道布局、重采样）
6. ffmpeg 式 filter 管线图（复用 `std.collection.DirectedGraph`）

## 目录约定

- `source/`：库源码（按上表分层）
- `test/`：`[test]` 正反测试；`test/fixtures.v` 为内嵌字节 fixture（见上方「当前已知限制」）
- 运行时证据：`examples/media-drive/`（值返回探针 + node 已知答案断言，随编译验证恢复复跑）
