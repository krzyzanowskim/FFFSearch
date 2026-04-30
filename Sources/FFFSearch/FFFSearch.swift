import Foundation
import CFFF

public enum FFFSearchError: LocalizedError, Sendable {
    case operationFailed(String)
    case nullHandle(String)

    public var errorDescription: String? {
        switch self {
        case .operationFailed(let message):
            return message
        case .nullHandle(let operation):
            return "FFF returned no handle for \(operation)"
        }
    }
}

public struct FFFFileMatch: Sendable, Equatable {
    public let relativePath: String

    public init(relativePath: String) {
        self.relativePath = relativePath
    }
}

public struct FFFContentMatch: Sendable, Equatable {
    public let relativePath: String
    public let lineNumber: Int
    public let lineContent: String

    public init(relativePath: String, lineNumber: Int, lineContent: String) {
        self.relativePath = relativePath
        self.lineNumber = lineNumber
        self.lineContent = lineContent
    }
}

public final class FFFIndex: @unchecked Sendable {
    private let lock = NSLock()
    private var handle: UnsafeMutableRawPointer?

    public init(
        basePath: String,
        frecencyDatabasePath: String?,
        historyDatabasePath: String?,
        enableMmapCache: Bool = true,
        enableContentIndexing: Bool = true,
        watch: Bool = true,
        aiMode: Bool = true,
        logFilePath: String? = nil,
        logLevel: String? = nil,
        cacheBudgetMaxFiles: UInt64 = 0,
        cacheBudgetMaxBytes: UInt64 = 0,
        cacheBudgetMaxFileSize: UInt64 = 0
    ) throws {
        let resultPointer = try Self.withOptionalCString(frecencyDatabasePath) { frecencyPointer in
            try Self.withOptionalCString(historyDatabasePath) { historyPointer in
                try Self.withOptionalCString(logFilePath) { logFilePointer in
                    try Self.withOptionalCString(logLevel) { logLevelPointer in
                        basePath.withCString { basePathPointer in
                            fff_create_instance2(
                                basePathPointer,
                                frecencyPointer,
                                historyPointer,
                                false,
                                enableMmapCache,
                                enableContentIndexing,
                                watch,
                                aiMode,
                                logFilePointer,
                                logLevelPointer,
                                cacheBudgetMaxFiles,
                                cacheBudgetMaxBytes,
                                cacheBudgetMaxFileSize
                            )
                        }
                    }
                }
            }
        }

        guard let resultPointer else { throw FFFSearchError.nullHandle("fff_create_instance2") }
        let handle = try Self.unwrapHandleResult(resultPointer, operation: "fff_create_instance2")
        guard let handle else { throw FFFSearchError.nullHandle("fff_create_instance2") }
        self.handle = handle
    }

    deinit {
        lock.lock()
        let handle = self.handle
        self.handle = nil
        lock.unlock()

        if let handle {
            fff_destroy(handle)
        }
    }

    public func waitForScan(timeoutMilliseconds: UInt64) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let handle = try requireHandleLocked()
        guard let resultPointer = fff_wait_for_scan(handle, timeoutMilliseconds) else {
            throw FFFSearchError.nullHandle("fff_wait_for_scan")
        }
        defer { fff_free_result(resultPointer) }
        try Self.ensureSuccess(resultPointer)
        return resultPointer.pointee.int_value != 0
    }

    public func searchFiles(query: String, pageSize: UInt32 = 100) throws -> [FFFFileMatch] {
        lock.lock()
        defer { lock.unlock() }

        let handle = try requireHandleLocked()
        let resultPointer = query.withCString { queryPointer in
            fff_search(handle, queryPointer, nil, 0, 0, pageSize, 0, 0)
        }

        guard let resultPointer else { throw FFFSearchError.nullHandle("fff_search") }
        guard let rawHandle = try Self.unwrapHandleResult(resultPointer, operation: "fff_search") else { return [] }
        let searchResult = rawHandle.assumingMemoryBound(to: FffSearchResult.self)
        defer { fff_free_search_result(searchResult) }

        guard let items = searchResult.pointee.items else { return [] }
        var matches: [FFFFileMatch] = []
        matches.reserveCapacity(Int(searchResult.pointee.count))

        for index in 0..<Int(searchResult.pointee.count) {
            let item = items.advanced(by: index).pointee
            guard let relativePathPointer = item.relative_path else { continue }
            matches.append(FFFFileMatch(relativePath: String(cString: relativePathPointer)))
        }
        return matches
    }

    public func liveGrep(
        query: String,
        pageLimit: UInt32 = 100,
        maxMatchesPerFile: UInt32 = 1,
        timeBudgetMilliseconds: UInt64 = 250,
        contextLineCount: UInt32 = 0
    ) throws -> [FFFContentMatch] {
        lock.lock()
        defer { lock.unlock() }

        let handle = try requireHandleLocked()
        let resultPointer = query.withCString { queryPointer in
            fff_live_grep(
                handle,
                queryPointer,
                0,
                0,
                maxMatchesPerFile,
                true,
                0,
                pageLimit,
                timeBudgetMilliseconds,
                contextLineCount,
                contextLineCount,
                false
            )
        }

        guard let resultPointer else { throw FFFSearchError.nullHandle("fff_live_grep") }
        guard let rawHandle = try Self.unwrapHandleResult(resultPointer, operation: "fff_live_grep") else { return [] }
        let grepResult = rawHandle.assumingMemoryBound(to: FffGrepResult.self)
        defer { fff_free_grep_result(grepResult) }

        guard let items = grepResult.pointee.items else { return [] }
        var matches: [FFFContentMatch] = []
        matches.reserveCapacity(Int(grepResult.pointee.count))

        for index in 0..<Int(grepResult.pointee.count) {
            let item = items.advanced(by: index).pointee
            guard let relativePathPointer = item.relative_path,
                  let lineContentPointer = item.line_content else { continue }

            matches.append(FFFContentMatch(
                relativePath: String(cString: relativePathPointer),
                lineNumber: Int(item.line_number),
                lineContent: String(cString: lineContentPointer)
            ))
        }
        return matches
    }

    public func close() {
        lock.lock()
        let handle = self.handle
        self.handle = nil
        lock.unlock()

        if let handle {
            fff_destroy(handle)
        }
    }

    private func requireHandleLocked() throws -> UnsafeMutableRawPointer {
        guard let handle else { throw FFFSearchError.nullHandle("FFFIndex") }
        return handle
    }

    private static func unwrapHandleResult(_ resultPointer: UnsafeMutablePointer<FffResult>, operation: String) throws -> UnsafeMutableRawPointer? {
        defer { fff_free_result(resultPointer) }
        try ensureSuccess(resultPointer)
        return resultPointer.pointee.handle
    }

    private static func ensureSuccess(_ resultPointer: UnsafeMutablePointer<FffResult>) throws {
        guard resultPointer.pointee.success else {
            let message = resultPointer.pointee.error.map { String(cString: $0) } ?? "Unknown FFF error"
            throw FFFSearchError.operationFailed(message)
        }
    }

    private static func withOptionalCString<Result>(
        _ string: String?,
        _ body: (UnsafePointer<CChar>?) throws -> Result
    ) throws -> Result {
        if let string {
            return try string.withCString(body)
        }
        return try body(nil)
    }
}
