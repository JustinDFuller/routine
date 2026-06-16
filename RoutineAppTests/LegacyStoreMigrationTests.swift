import Foundation
import XCTest

@testable import Routine

final class LegacyStoreMigrationTests: XCTestCase {
    private var rootURL: URL!
    private var fileManager: FileManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        fileManager = FileManager.default
        rootURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try fileManager.removeItem(at: rootURL)
        rootURL = nil
        fileManager = nil

        try super.tearDownWithError()
    }

    func testCopiesStoreAndSidecarFilesWhenAllExist() throws {
        let legacyURL = try makeLegacyStore(named: "Legacy", contents: ["": "store", "-wal": "wal", "-shm": "shm"])
        let groupURL = rootURL.appendingPathComponent("Group/default.store")

        try RoutineModelContainer.copyLegacyStore(from: legacyURL, to: groupURL, fileManager: fileManager)

        XCTAssertEqual(try contents(of: groupURL), "store")
        XCTAssertEqual(try contents(of: sidecar(groupURL, "-wal")), "wal")
        XCTAssertEqual(try contents(of: sidecar(groupURL, "-shm")), "shm")
    }

    func testCopiesOnlyFilesThatExist() throws {
        let legacyURL = try makeLegacyStore(named: "Legacy", contents: ["": "store", "-wal": "wal"])
        let groupURL = rootURL.appendingPathComponent("Group/default.store")

        try RoutineModelContainer.copyLegacyStore(from: legacyURL, to: groupURL, fileManager: fileManager)

        XCTAssertEqual(try contents(of: groupURL), "store")
        XCTAssertEqual(try contents(of: sidecar(groupURL, "-wal")), "wal")
        XCTAssertFalse(fileManager.fileExists(atPath: sidecar(groupURL, "-shm").path))
    }

    func testOverwritesExistingDestinationStore() throws {
        let legacyURL = try makeLegacyStore(named: "Legacy", contents: ["": "real-data"])
        let groupURL = rootURL.appendingPathComponent("Group/default.store")
        try fileManager.createDirectory(at: groupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try write("empty-widget-store", to: groupURL)

        try RoutineModelContainer.copyLegacyStore(from: legacyURL, to: groupURL, fileManager: fileManager)

        XCTAssertEqual(try contents(of: groupURL), "real-data")
    }

    func testCreatesDestinationDirectoryWhenMissing() throws {
        let legacyURL = try makeLegacyStore(named: "Legacy", contents: ["": "store"])
        let groupURL = rootURL.appendingPathComponent("NewGroupDir/Nested/default.store")

        try RoutineModelContainer.copyLegacyStore(from: legacyURL, to: groupURL, fileManager: fileManager)

        XCTAssertEqual(try contents(of: groupURL), "store")
    }

    private func makeLegacyStore(named name: String, contents: [String: String]) throws -> URL {
        let directory = rootURL.appendingPathComponent(name)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let storeURL = directory.appendingPathComponent("default.store")
        for (suffix, fileContents) in contents {
            try write(fileContents, to: sidecar(storeURL, suffix))
        }

        return storeURL
    }

    private func sidecar(_ storeURL: URL, _ suffix: String) -> URL {
        guard suffix.isEmpty == false else {
            return storeURL
        }

        return
            storeURL
            .deletingLastPathComponent()
            .appendingPathComponent(storeURL.lastPathComponent + suffix)
    }

    private func write(_ string: String, to url: URL) throws {
        try string.write(to: url, atomically: true, encoding: .utf8)
    }

    private func contents(of url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }
}
