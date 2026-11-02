# media._

`media._` 是媒体生态的顶层 workspace：OpenCV / FFmpeg 的 Valkyrie 复刻 —— 图像与视频编解码、处理管线、滤镜。

## 原则

- 能用 Valkyrie 写的逻辑不塞进 nyar 编译器硬编码
- 字节读取/端序/位流归 `std.data.binary.codec`，格式适配器不自带字节层
- 摘要/校验归 `std.data.digest`（CRC-32、Adler-32），压缩（deflate/zlib）归 `std.data.binary.codec`
- 文件/网络 IO 是 host capability，不进库包；编解码入口消费已读入的字节数组
- 缺底层能力的操作返回结构化失败，不硬编码、不 fallback

## 组成

- `media`：核心库 —— `image/`（尺寸、像素格式、行布局）、`color/`（像素格式与转换）、`pipeline/`（crop、resize）、`codec/`（PPM、BMP、PNG 适配器）、`video/`（规划层）
- 规划方向见 `projects/media/readme.md`：JPEG/GIF/WebP、MP4/MKV 容器与解复用、PCM 音频、ffmpeg 式 filter 管线图

## 当前状态

- 已落地：图像模型、PPM/BMP 读写、PNG 容器层（签名/chunk/CRC/IHDR/IDAT 聚合 + 扫描线滤波重建）、resize/crop
- PNG 的 IDAT 解压停在 `media.png.inflate_unavailable` 结构化诊断：`std.data.binary.codec` 尚无 deflate 实现（当前未落地）

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
