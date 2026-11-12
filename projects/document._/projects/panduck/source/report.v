namespace panduck;

# `panduck.report/v0` 线格式声明层。
#
# 转换操作如实记录语义存活与丢失，读报告先于交付。`coverage`/`loss` 对应
# `notedown` 的覆盖模型（`CoverageReport`/`LossMarker`/`SemanticStatus`）；
# notedown 侧模型落定前，本文件以 panduck 自有类型承载。
#
# 线格式中 `coverage.loss` 与顶层 `losses` 是同一数组的两份嵌出；本模型只保留
# `coverage` 一份，由序列化层复制，不做双份存储。

# report 线格式身份。
micro panduck_report_schema() -> utf8 {
    return "panduck.report/v0"
}

# 语义状态：Resolved / Unresolved / Partial / Unsupported / Inferred / Lossy。
enums PanduckSemanticStatus {
    Resolved
    Unresolved
    Partial
    Unsupported
    Inferred
    Lossy
}

# 损失标记：稳定机器码 + 人读说明 + 状态。
structure PanduckLossMarker {
    code: utf8
    message: utf8
    status: PanduckSemanticStatus
}

# 覆盖视图：转换是否无损 + 损失标记集合。
structure PanduckCoverageView {
    complete: bool
    loss: [PanduckLossMarker]
}

# 转换操作类别：单文档转换 / markdown 工程转换。
enums PanduckReportOperation {
    Convert
    ConvertProject
}

# 报告结论：无损失 / 带损失成功。失败不产出 report（错误走诊断通道，不伪造部分报告）。
enums PanduckReportStatus {
    Success
    SuccessWithLoss
}

# 输入条目：来源路径与格式身份。
structure PanduckReportInput {
    path: utf8
    format: utf8
}

# 管线描述：reader/writer 身份与执行阶段序列。
# `transforms` 为 transform pass 名序列；pass 描述结构随 transform 编排块落定。
structure PanduckReportPipeline {
    reader: utf8
    writer: utf8
    stages: [utf8]
    transforms: [utf8]
}

# 诊断严重度（与 `std.data` 的 `DataSeverity` 同形，归本包线格式自有）。
enums PanduckDiagnosticSeverity {
    Error
    Warning
    Info
}

# 报告内嵌诊断条目：稳定机器码 + 严重度 + 人读说明。
structure PanduckReportDiagnostic {
    code: utf8
    severity: PanduckDiagnosticSeverity
    message: utf8
}

# 产物条目：工程相对路径（单文档转换为空串）、格式身份、是否落盘；
# `published_asset_count` 仅 assets 汇总条目使用，其余条目取 -1。
structure PanduckReportOutput {
    path: utf8
    format: utf8
    published: bool
    published_asset_count: i32
}

# `panduck.report/v0` 报告本体。
# `unresolved_assets` 仅 `ConvertProject` 使用（未解析资产来源列表），
# `Convert` 恒为空数组。
structure PanduckReport {
    operation: PanduckReportOperation
    status: PanduckReportStatus
    inputs: [PanduckReportInput]
    pipeline: PanduckReportPipeline
    coverage: PanduckCoverageView
    diagnostics: [PanduckReportDiagnostic]
    outputs: [PanduckReportOutput]
    unresolved_assets: [utf8]
}
