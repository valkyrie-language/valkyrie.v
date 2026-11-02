namespace media;

# video/ — 视频层锚点（roadmap，见本包 readme.md，第一批不落地实现）。
#
# 规划职责：
# - MP4/MKV 容器与解复用：box/EBML 结构解析走 `std.data.binary.codec` 字节层；
# - 帧序列模型：时间基（timebase）、帧率、关键帧索引；
# - PCM 音频基础：采样格式、声道布局、重采样；
# - ffmpeg 式 filter 管线图：source/filter/sink 有向图，复用 `std.collection.DirectedGraph`。
