namespace plotter;

# L3 场景：已解析几何的容器。只有像素空间坐标，不含数据、标度或方言结构。

structure PlotScene {
    width: f64
    height: f64
    marks: [Mark]
}
