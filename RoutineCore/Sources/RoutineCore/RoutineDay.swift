import Foundation

public struct RoutineDay: Codable, Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init?(year: Int, month: Int, day: Int) {
        guard Self.isValidGregorianDate(year: year, month: month, day: day) else {
            return nil
        }

        self.year = year
        self.month = month
        self.day = day
    }

    public init?(key: String) {
        let segments = key.split(separator: "-", omittingEmptySubsequences: false)
        guard segments.count == 3 else {
            return nil
        }

        guard segments[0].count == 4, segments[1].count == 2, segments[2].count == 2 else {
            return nil
        }

        guard
            let year = Int(segments[0]),
            let month = Int(segments[1]),
            let day = Int(segments[2])
        else {
            return nil
        }

        self.init(year: year, month: month, day: day)
    }

    public var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func < (lhs: RoutineDay, rhs: RoutineDay) -> Bool {
        lhs.key < rhs.key
    }

    private static func isValidGregorianDate(year: Int, month: Int, day: Int) -> Bool {
        guard (1...9_999).contains(year), (1...12).contains(month), day >= 1 else {
            return false
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")

        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else {
            return false
        }

        let resolvedComponents = calendar.dateComponents([.year, .month, .day], from: date)
        return
            resolvedComponents.year == year && resolvedComponents.month == month && resolvedComponents.day == day
    }
}
