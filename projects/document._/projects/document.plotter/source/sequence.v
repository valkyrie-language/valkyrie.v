namespace document.plot;

# sequence 布局：事件驱动。参与者按输入序横排，事件自上而下推进游标。
#
# v0 规则：参与者盒在顶部；生命线自盒底垂到画布底（虚线）；消息为生命线间
# 水平箭头（自消息为右侧贝塞尔回环）；`SeqActivate`/`SeqDeactivate` 配对成
# 激活条（生命线上的窄矩形）；`SeqNote` 为参与者侧旁的便签框；
# `SeqFrameBegin`/`SeqFrameElse`/`SeqFrameEnd` 围出虚线分块框（else 为框内
# 虚线分隔 + 新标签）。事件占位：消息 40、便签 34、框起止各 12、else 24。

unite PlotSeqEvent {
    [constructor]
    SeqMessage {
        source: utf8
        target: utf8
        label: utf8
    }
    [constructor]
    SeqActivate {
        target: utf8
    }
    [constructor]
    SeqDeactivate {
        target: utf8
    }
    [constructor]
    SeqNote {
        target: utf8
        side: i32
        text: utf8
    }
    [constructor]
    SeqFrameBegin {
        label: utf8
    }
    [constructor]
    SeqFrameElse {
        label: utf8
    }
    SeqFrameEnd
}

structure PlotSequenceSpec {
    participants: [PlotDecl]
    events: [PlotSeqEvent]
}

micro plot_sequence_spec(participants: [PlotDecl], events: [PlotSeqEvent]) -> PlotSequenceSpec {
    return PlotSequenceSpec {
        participants: participants,
        events: events
    }
}

micro plot_sequence_center_of(nodes: [PlotNode], id: utf8) -> f64 {
    let mut index: usize = 0
    while index < nodes.length() {
        if nodes⁅index⁆.id.equals(id) {
            return nodes⁅index⁆.x + nodes⁅index⁆.width / 2.0
        }
        index = index + 1
    }
    return 0.0
}

micro plot_sequence_full(spec: PlotSequenceSpec) -> PlotScene {
    let font: BoxFont = plot_font()
    let margin: f64 = plot_margin()
    let h_gap: f64 = 60.0
    let node_height: f64 = font.em + 8.0

    let mut max_width: f64 = 0.0
    let mut index: usize = 0
    while index < spec.participants.length() {
        let width: f64 = spec.participants⁅index⁆.label.length() as f64 * font.em + 16.0
        if width > max_width {
            max_width = width
        }
        index = index + 1
    }

    let mut nodes: [PlotNode] = []
    index = 0
    while index < spec.participants.length() {
        let label_width: f64 = spec.participants⁅index⁆.label.length() as f64 * font.em + 16.0
        nodes = push(nodes, plot_node(
            spec.participants⁅index⁆.id,
            spec.participants⁅index⁆.label,
            margin + index as f64 * (max_width + h_gap) + (max_width - label_width) / 2.0,
            margin,
            label_width,
            node_height
        ))
        index = index + 1
    }

    # 第一遍：推进游标求画布高与事件 y 位；激活配对求条段；框求包围区间。
    let mut edges: [PlotEdge] = []
    let mut notes: [PlotNote] = []
    let mut activations: [PlotActivation] = []
    let mut frames: [PlotFrame] = []
    let mut open_activations: [PlotEdge] = []
    let mut open_frames: [utf8] = []
    let mut frame_start_ys: [f64] = []
    let mut frame_dividers: [f64] = []
    let mut y: f64 = margin + node_height + 20.0
    index = 0
    while index < spec.events.length() {
        match spec.events⁅index⁆ {
            case SeqMessage(payload):
                y = y + 40.0
                edges = push(edges, plot_edge_direct(payload.source, payload.target, payload.label, plot_sequence_center_of(nodes, payload.source), y, plot_sequence_center_of(nodes, payload.target), y))
            case SeqActivate(payload):
                y = y + 12.0
                open_activations = push(open_activations, PlotActivation {
                    center_x: plot_sequence_center_of(nodes, payload.target),
                    y1: y,
                    y2: 0.0 - 1.0
                })
            case SeqDeactivate(payload):
                y = y + 12.0
                let mut found: i32 = -1
                let mut scan: usize = 0
                while scan < open_activations.length() {
                    if open_activations⁅scan⁆.center_x == plot_sequence_center_of(nodes, payload.target) {
                        found = scan as i32
                    }
                    scan = scan + 1
                }
                if found >= 0 {
                    let open_index: usize = found as usize
                    activations = push(activations, PlotActivation {
                        center_x: open_activations⁅open_index⁆.center_x,
                        y1: open_activations⁅open_index⁆.y1,
                        y2: y
                    })
                    open_activations = plot_remove_activation(open_activations, open_index)
                }
            case SeqNote(payload):
                y = y + 14.0
                let note_width: f64 = payload.text.length() as f64 * font.em + 12.0
                let center: f64 = plot_sequence_center_of(nodes, payload.target)
                if payload.side < 0 {
                    notes = push(notes, PlotNote {
                        x: center - note_width - 12.0,
                        y: y,
                        width: note_width,
                        text: payload.text
                    })
                } else {
                    notes = push(notes, PlotNote {
                        x: center + 12.0,
                        y: y,
                        width: note_width,
                        text: payload.text
                    })
                }
                y = y + 20.0
            case SeqFrameBegin(payload):
                y = y + 12.0
                open_frames = push(open_frames, payload.label)
                frame_start_ys = push(frame_start_ys, y)
                frame_dividers = push(frame_dividers, -1.0)
            case SeqFrameElse(payload):
                y = y + 24.0
                if open_frames.length() > 0 {
                    let top: usize = open_frames.length() - 1
                    let mut divided: [f64] = frame_dividers
                    divided⁅top⁆ = y - 12.0
                    frame_dividers = divided
                }
            case SeqFrameEnd:
                y = y + 12.0
                if open_frames.length() > 0 {
                    let top: usize = open_frames.length() - 1
                    let mut divider_list: [f64] = []
                    if frame_dividers⁅top⁆ >= 0.0 {
                        divider_list = push(divider_list, frame_dividers⁅top⁆)
                    }
                    frames = push(frames, PlotFrame {
                        label: open_frames⁅top⁆,
                        x: margin - 8.0,
                        y: frame_start_ys⁅top⁆ - 12.0,
                        width: spec.participants.length() as f64 * (max_width + h_gap) - h_gap + 16.0,
                        height: y - frame_start_ys⁅top⁆ + 4.0,
                        dividers: divider_list
                    })
                    open_frames = plot_remove_text(open_frames, top)
                    frame_start_ys = plot_remove_f64(frame_start_ys, top)
                    frame_dividers = plot_remove_f64(frame_dividers, top)
                }
        }
        index = index + 1
    }

    # 未闭合的激活条如实拉到画布底。
    let mut scan: usize = 0
    while scan < open_activations.length() {
        activations = push(activations, PlotActivation {
            center_x: open_activations⁅scan⁆.center_x,
            y1: open_activations⁅scan⁆.y1,
            y2: y
        })
        scan = scan + 1
    }

    let height: f64 = y + 40.0

    let mut lifelines: [utf8] = []
    index = 0
    while index < spec.participants.length() {
        lifelines = push(lifelines, spec.participants⁅index⁆.id)
        index = index + 1
    }

    return PlotScene {
        width: margin * 2.0 + spec.participants.length() as f64 * (max_width + h_gap) - h_gap,
        height: height,
        nodes: nodes,
        edges: edges,
        lifelines: lifelines,
        clusters: [],
        activations: activations,
        notes: notes,
        frames: frames
    }
}

micro plot_remove_activation(items: [PlotActivation], index: usize) -> [PlotActivation] {
    let mut out: [PlotActivation] = []
    let mut position: usize = 0
    while position < items.length() {
        if position != index {
            out = push(out, items⁅position⁆)
        }
        position = position + 1
    }
    return out
}

micro plot_remove_text(items: [utf8], index: usize) -> [utf8] {
    let mut out: [utf8] = []
    let mut position: usize = 0
    while position < items.length() {
        if position != index {
            out = push(out, items⁅position⁆)
        }
        position = position + 1
    }
    return out
}

micro plot_remove_f64(items: [f64], index: usize) -> [f64] {
    let mut out: [f64] = []
    let mut position: usize = 0
    while position < items.length() {
        if position != index {
            out = push(out, items⁅position⁆)
        }
        position = position + 1
    }
    return out
}

# 旧签名兼容：纯消息序列（无激活/便签/分块）。
micro plot_sequence(decls: [PlotDecl], messages: [PlotEdge]) -> PlotScene {
    let mut events: [PlotSeqEvent] = []
    let mut index: usize = 0
    while index < messages.length() {
        events = push(events, SeqMessage {
            source: messages⁅index⁆.source,
            target: messages⁅index⁆.target,
            label: messages⁅index⁆.label
        })
        index = index + 1
    }
    return plot_sequence_full(plot_sequence_spec(decls, events))
}
