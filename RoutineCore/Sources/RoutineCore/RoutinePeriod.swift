public enum RoutinePeriod: String, Codable, CaseIterable, Identifiable, Sendable {
    case weekly
    case monthly

    public var id: String {
        rawValue
    }
}
