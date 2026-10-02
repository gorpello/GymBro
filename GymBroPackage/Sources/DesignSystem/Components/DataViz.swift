import PhosphorSwift
import SwiftUI

/// Activity heatmap: columns are weeks, rows are weekdays, each cell a level 0…4.
public struct HeatGrid: View {
    /// `weeks[column][row]`, levels 0 (empty) … 4.
    let weeks: [[Int]]
    let tone: HeatTone
    let spacing: CGFloat
    
    public init(weeks: [[Int]], tone: HeatTone = .ember, spacing: CGFloat = 4) {
        self.weeks = weeks
        self.tone = tone
        self.spacing = spacing
    }
    
    public var body: some View {
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(0..<7, id: \.self) { row in
                GridRow {
                    ForEach(weeks.indices, id: \.self) { column in
                        let level = row < weeks[column].count ? weeks[column][row] : 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(level > 0 ? tone.color(level: level) : GymColor.heatEmpty)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
    }
}

/// Monday-to-Sunday circles with a check on trained days (Home week strip).
public struct WeekStrip: View {
    let initials: [String]
    let done: [Bool]
    let today: Int
    
    public init(initials: [String], done: [Bool], today: Int) {
        self.initials = initials
        self.done = done
        self.today = today
    }
    
    public var body: some View {
        HStack {
            ForEach(initials.indices, id: \.self) { i in
                let isDone = i < done.count && done[i]
                VStack(spacing: 10) {
                    Text(initials[i])
                        .font(.gym(12, i == today ? .extraBold : .semibold, relativeTo: .caption))
                        .foregroundStyle(i == today ? GymColor.text : GymColor.textSecondary)
                    ZStack {
                        Circle().fill(isDone ? GymColor.ember : GymColor.bgRaised2)
                        if isDone {
                            GymIcon(.check, weight: .bold, size: 14)
                                .foregroundStyle(GymColor.onEmber)
                        }
                    }
                    .frame(width: 40, height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Weekly goal ring with "4/4" underneath.
public struct GoalRing: View {
    let done: Int
    let goal: Int
    let size: CGFloat
    
    public init(done: Int, goal: Int, size: CGFloat = 52) {
        self.done = done
        self.goal = goal
        self.size = size
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(GymColor.bgRaised2, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: goal > 0 ? min(1, CGFloat(done) / CGFloat(goal)) : 0)
                    .stroke(GymColor.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: size, height: size)
            Text("\(done)/\(goal)")
                .font(.gym(12, .bold, relativeTo: .caption))
                .foregroundStyle(GymColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Thin trend line ending in a ring, with min/max labels (Progress tiles).
public struct Sparkline: View {
    let values: [Double]
    let showsRange: Bool
    
    public init(_ values: [Double], showsRange: Bool = true) {
        self.values = values
        self.showsRange = showsRange
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            GeometryReader { proxy in
                let points = points(in: proxy.size)
                ZStack {
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for p in points.dropFirst() { path.addLine(to: p) }
                    }
                    .stroke(GymColor.textSecondary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    if let last = points.last {
                        Circle()
                            .strokeBorder(GymColor.text, lineWidth: 2.5)
                            .background(Circle().fill(GymColor.bgRaised))
                            .frame(width: 12, height: 12)
                            .position(last)
                    }
                }
            }
            if showsRange, let lo = values.min(), let hi = values.max() {
                VStack(alignment: .leading) {
                    Text(hi.formatted(.number.precision(.fractionLength(0))))
                    Spacer()
                    Text(lo.formatted(.number.precision(.fractionLength(0))))
                }
                .font(.gym(10, .semibold, relativeTo: .caption2))
                .foregroundStyle(GymColor.textSecondary)
            }
        }
        .accessibilityHidden(true)
    }
    
    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1, let lo = values.min(), let hi = values.max() else { return [] }
        let span = max(hi - lo, 0.0001)
        return values.enumerated().map { i, v in
            CGPoint(
                x: 6 + (size.width - 12) * CGFloat(i) / CGFloat(values.count - 1),
                y: 6 + (size.height - 12) * (1 - CGFloat((v - lo) / span))
            )
        }
    }
}

/// Untouched → full volume legend under heat maps.
public struct HeatLegend: View {
    let low: String
    let high: String
    let tone: HeatTone
    
    public init(low: String, high: String, tone: HeatTone = .ember) {
        self.low = low
        self.high = high
        self.tone = tone
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Text(low)
            ForEach(0..<5, id: \.self) { level in
                Capsule().fill(tone.color(level: level)).frame(height: 6)
            }
            Text(high)
        }
        .font(.gym(11.5, .medium, relativeTo: .caption))
        .foregroundStyle(GymColor.textSecondary)
    }
}

/// Vertical dashed line (`DashedRail`), used by the timelines.
public struct DashedRail: View {
    let color: Color
    
    public init(color: Color = GymColor.accent) {
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
            }
            .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 5]))
        }
        .frame(width: 2)
    }
}
