namespace document.vector;

# document.vector — 矢量文本发射：确定性 SVG 原语。
#
# 输出合同：同输入同字节。属性顺序固定（几何在前、样式随后）；
# 属性拼写一律单引号（SVG/XML 两种引号等价），源文件因此不含转义引号；
# 转义逐字符扫描重建，不依赖 host 字符串替换。
