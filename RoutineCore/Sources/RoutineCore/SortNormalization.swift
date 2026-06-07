public func normalizedSortOrders<ID: Hashable>(for ids: [ID]) -> [ID: Int] {
    var sortOrders: [ID: Int] = [:]
    sortOrders.reserveCapacity(ids.count)

    for id in ids where sortOrders[id] == nil {
        sortOrders[id] = sortOrders.count
    }

    return sortOrders
}
