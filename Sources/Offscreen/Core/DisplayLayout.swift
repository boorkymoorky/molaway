import Foundation

enum DisplayLayout {
    static func selectedIndices(frames: [CGRect], cursor: CGPoint, target: DisplayTarget) -> [Int] {
        guard !frames.isEmpty else { return [] }
        switch target {
        case .all: return Array(frames.indices)
        case .primary: return [0]
        case .cursor: return [frames.firstIndex(where: { $0.contains(cursor) }) ?? 0]
        }
    }
    static func windowFrame(current: CGRect, visible: CGRect, centered: Bool) -> CGRect {
        let area = visible.insetBy(dx: 12, dy: 12)
        let width = min(current.width, max(1, area.width))
        let height = min(current.height, max(1, area.height))
        let x = centered ? area.midX - width / 2 : min(max(current.minX, area.minX), area.maxX - width)
        let y = centered ? area.midY - height / 2 : min(max(current.minY, area.minY), area.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }
    static func dashboardFrame(visible: CGRect, anchor: CGPoint, size: CGSize) -> CGRect {
        let wanted = CGRect(x: anchor.x - size.width / 2, y: visible.maxY - size.height - 8, width: size.width, height: size.height)
        return windowFrame(current: wanted, visible: visible, centered: false)
    }
    static func panelFrame(visible: CGRect, desired: CGSize, centered: Bool) -> CGRect {
        let width = min(max(0, desired.width), max(0, visible.width - 32))
        let height = min(max(0, desired.height), max(0, visible.height - 32))
        let x = centered ? visible.midX - width / 2 : visible.maxX - width - 16
        return CGRect(x: x, y: visible.maxY - height - 16, width: width, height: height)
    }
}
