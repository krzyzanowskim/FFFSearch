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

public enum FFFGrepMode: UInt8, Sendable {
    case plainText = 0
    case regex = 1
    case fuzzy = 2
}

public struct FFFMatchRange: Sendable, Equatable {
    public let start: UInt32
    public let end: UInt32

    public init(start: UInt32, end: UInt32) {
        self.start = start
        self.end = end
    }
}

public struct FFFFileMatch: Sendable, Equatable {
    public let relativePath: String
    public let fileName: String?
    public let gitStatus: String?
    public let size: UInt64
    public let modified: UInt64
    public let accessFrecencyScore: Int64
    public let modificationFrecencyScore: Int64
    public let totalFrecencyScore: Int64
    public let isBinary: Bool

    public init(
        relativePath: String,
        fileName: String? = nil,
        gitStatus: String? = nil,
        size: UInt64 = 0,
        modified: UInt64 = 0,
        accessFrecencyScore: Int64 = 0,
        modificationFrecencyScore: Int64 = 0,
        totalFrecencyScore: Int64 = 0,
        isBinary: Bool = false
    ) {
        self.relativePath = relativePath
        self.fileName = fileName
        self.gitStatus = gitStatus
        self.size = size
        self.modified = modified
        self.accessFrecencyScore = accessFrecencyScore
        self.modificationFrecencyScore = modificationFrecencyScore
        self.totalFrecencyScore = totalFrecencyScore
        self.isBinary = isBinary
    }
}

public struct FFFDirectoryMatch: Sendable, Equatable {
    public let relativePath: String
    public let directoryName: String?
    public let maxAccessFrecency: Int32

    public init(relativePath: String, directoryName: String? = nil, maxAccessFrecency: Int32 = 0) {
        self.relativePath = relativePath
        self.directoryName = directoryName
        self.maxAccessFrecency = maxAccessFrecency
    }
}

public enum FFFMixedMatch: Sendable, Equatable {
    case file(FFFFileMatch)
    case directory(FFFDirectoryMatch)
}

public struct FFFContentMatch: Sendable, Equatable {
    public let relativePath: String
    public let fileName: String?
    public let gitStatus: String?
    public let lineNumber: Int
    public let lineContent: String
    public let column: UInt32
    public let byteOffset: UInt64
    public let matchRanges: [FFFMatchRange]
    public let contextBefore: [String]
    public let contextAfter: [String]
    public let size: UInt64
    public let modified: UInt64
    public let accessFrecencyScore: Int64
    public let modificationFrecencyScore: Int64
    public let totalFrecencyScore: Int64
    public let fuzzyScore: UInt16?
    public let isBinary: Bool
    public let isDefinition: Bool

    public init(
        relativePath: String,
        lineNumber: Int,
        lineContent: String,
        fileName: String? = nil,
        gitStatus: String? = nil,
        column: UInt32 = 0,
        byteOffset: UInt64 = 0,
        matchRanges: [FFFMatchRange] = [],
        contextBefore: [String] = [],
        contextAfter: [String] = [],
        size: UInt64 = 0,
        modified: UInt64 = 0,
        accessFrecencyScore: Int64 = 0,
        modificationFrecencyScore: Int64 = 0,
        totalFrecencyScore: Int64 = 0,
        fuzzyScore: UInt16? = nil,
        isBinary: Bool = false,
        isDefinition: Bool = false
    ) {
        self.relativePath = relativePath
        self.fileName = fileName
        self.gitStatus = gitStatus
        self.lineNumber = lineNumber
        self.lineContent = lineContent
        self.column = column
        self.byteOffset = byteOffset
        self.matchRanges = matchRanges
        self.contextBefore = contextBefore
        self.contextAfter = contextAfter
        self.size = size
        self.modified = modified
        self.accessFrecencyScore = accessFrecencyScore
        self.modificationFrecencyScore = modificationFrecencyScore
        self.totalFrecencyScore = totalFrecencyScore
        self.fuzzyScore = fuzzyScore
        self.isBinary = isBinary
        self.isDefinition = isDefinition
    }
}

public struct FFFFileSearchResult: Sendable, Equatable {
    public let matches: [FFFFileMatch]
    public let totalMatched: UInt32
    public let totalFiles: UInt32

    public init(matches: [FFFFileMatch], totalMatched: UInt32, totalFiles: UInt32) {
        self.matches = matches
        self.totalMatched = totalMatched
        self.totalFiles = totalFiles
    }
}

public struct FFFDirectorySearchResult: Sendable, Equatable {
    public let matches: [FFFDirectoryMatch]
    public let totalMatched: UInt32
    public let totalDirectories: UInt32

    public init(matches: [FFFDirectoryMatch], totalMatched: UInt32, totalDirectories: UInt32) {
        self.matches = matches
        self.totalMatched = totalMatched
        self.totalDirectories = totalDirectories
    }
}

public struct FFFMixedSearchResult: Sendable, Equatable {
    public let matches: [FFFMixedMatch]
    public let totalMatched: UInt32
    public let totalFiles: UInt32
    public let totalDirectories: UInt32

    public init(matches: [FFFMixedMatch], totalMatched: UInt32, totalFiles: UInt32, totalDirectories: UInt32) {
        self.matches = matches
        self.totalMatched = totalMatched
        self.totalFiles = totalFiles
        self.totalDirectories = totalDirectories
    }
}

public struct FFFGrepSearchResult: Sendable, Equatable {
    public let matches: [FFFContentMatch]
    public let totalMatched: UInt32
    public let totalFilesSearched: UInt32
    public let totalFiles: UInt32
    public let filteredFileCount: UInt32
    public let nextFileOffset: UInt32
    public let regexFallbackError: String?

    public init(
        matches: [FFFContentMatch],
        totalMatched: UInt32,
        totalFilesSearched: UInt32,
        totalFiles: UInt32,
        filteredFileCount: UInt32,
        nextFileOffset: UInt32,
        regexFallbackError: String?
    ) {
        self.matches = matches
        self.totalMatched = totalMatched
        self.totalFilesSearched = totalFilesSearched
        self.totalFiles = totalFiles
        self.filteredFileCount = filteredFileCount
        self.nextFileOffset = nextFileOffset
        self.regexFallbackError = regexFallbackError
    }
}

public struct FFFScanProgress: Sendable, Equatable {
    public let scannedFilesCount: UInt64
    public let isScanning: Bool
    public let isWatcherReady: Bool
    public let isWarmupComplete: Bool

    public init(scannedFilesCount: UInt64, isScanning: Bool, isWatcherReady: Bool, isWarmupComplete: Bool) {
        self.scannedFilesCount = scannedFilesCount
        self.isScanning = isScanning
        self.isWatcherReady = isWatcherReady
        self.isWarmupComplete = isWarmupComplete
    }
}

public struct FFFIndexConfiguration: Sendable, Equatable {
    public let basePath: String
    public let frecencyDatabasePath: String?
    public let historyDatabasePath: String?
    public let enableMmapCache: Bool
    public let enableContentIndexing: Bool
    public let watch: Bool
    public let aiMode: Bool
    public let logFilePath: String?
    public let logLevel: String?
    public let cacheBudgetMaxFiles: UInt64
    public let cacheBudgetMaxBytes: UInt64
    public let cacheBudgetMaxFileSize: UInt64
    public let enableFileSystemRootScanning: Bool
    public let enableHomeDirectoryScanning: Bool

    public init(
        basePath: String,
        frecencyDatabasePath: String? = nil,
        historyDatabasePath: String? = nil,
        enableMmapCache: Bool = true,
        enableContentIndexing: Bool = true,
        watch: Bool = true,
        aiMode: Bool = true,
        logFilePath: String? = nil,
        logLevel: String? = nil,
        cacheBudgetMaxFiles: UInt64 = 0,
        cacheBudgetMaxBytes: UInt64 = 0,
        cacheBudgetMaxFileSize: UInt64 = 0,
        enableFileSystemRootScanning: Bool = false,
        enableHomeDirectoryScanning: Bool = false
    ) {
        self.basePath = basePath
        self.frecencyDatabasePath = frecencyDatabasePath
        self.historyDatabasePath = historyDatabasePath
        self.enableMmapCache = enableMmapCache
        self.enableContentIndexing = enableContentIndexing
        self.watch = watch
        self.aiMode = aiMode
        self.logFilePath = logFilePath
        self.logLevel = logLevel
        self.cacheBudgetMaxFiles = cacheBudgetMaxFiles
        self.cacheBudgetMaxBytes = cacheBudgetMaxBytes
        self.cacheBudgetMaxFileSize = cacheBudgetMaxFileSize
        self.enableFileSystemRootScanning = enableFileSystemRootScanning
        self.enableHomeDirectoryScanning = enableHomeDirectoryScanning
    }
}

public final class FFFIndex: @unchecked Sendable {
    private let lock = NSLock()
    private var handle: UnsafeMutableRawPointer?

    public convenience init(configuration: FFFIndexConfiguration) throws {
        try self.init(
            basePath: configuration.basePath,
            frecencyDatabasePath: configuration.frecencyDatabasePath,
            historyDatabasePath: configuration.historyDatabasePath,
            enableMmapCache: configuration.enableMmapCache,
            enableContentIndexing: configuration.enableContentIndexing,
            watch: configuration.watch,
            aiMode: configuration.aiMode,
            logFilePath: configuration.logFilePath,
            logLevel: configuration.logLevel,
            cacheBudgetMaxFiles: configuration.cacheBudgetMaxFiles,
            cacheBudgetMaxBytes: configuration.cacheBudgetMaxBytes,
            cacheBudgetMaxFileSize: configuration.cacheBudgetMaxFileSize,
            enableFileSystemRootScanning: configuration.enableFileSystemRootScanning,
            enableHomeDirectoryScanning: configuration.enableHomeDirectoryScanning
        )
    }

    public init(
        basePath: String,
        frecencyDatabasePath: String? = nil,
        historyDatabasePath: String? = nil,
        enableMmapCache: Bool = true,
        enableContentIndexing: Bool = true,
        watch: Bool = true,
        aiMode: Bool = true,
        logFilePath: String? = nil,
        logLevel: String? = nil,
        cacheBudgetMaxFiles: UInt64 = 0,
        cacheBudgetMaxBytes: UInt64 = 0,
        cacheBudgetMaxFileSize: UInt64 = 0,
        enableFileSystemRootScanning: Bool = false,
        enableHomeDirectoryScanning: Bool = false
    ) throws {
        let resultPointer = try Self.withOptionalCString(frecencyDatabasePath) { frecencyPointer in
            try Self.withOptionalCString(historyDatabasePath) { historyPointer in
                try Self.withOptionalCString(logFilePath) { logFilePointer in
                    try Self.withOptionalCString(logLevel) { logLevelPointer in
                        basePath.withCString { basePathPointer in
                            var options = FffCreateOptions(
                                version: UInt32(FFF_CREATE_OPTIONS_VERSION),
                                base_path: basePathPointer,
                                frecency_db_path: frecencyPointer,
                                history_db_path: historyPointer,
                                enable_mmap_cache: enableMmapCache,
                                enable_content_indexing: enableContentIndexing,
                                watch: watch,
                                ai_mode: aiMode,
                                log_file_path: logFilePointer,
                                log_level: logLevelPointer,
                                cache_budget_max_files: cacheBudgetMaxFiles,
                                cache_budget_max_bytes: cacheBudgetMaxBytes,
                                cache_budget_max_file_size: cacheBudgetMaxFileSize,
                                enable_fs_root_scanning: enableFileSystemRootScanning,
                                enable_home_dir_scanning: enableHomeDirectoryScanning
                            )
                            return fff_create_instance_with(&options)
                        }
                    }
                }
            }
        }

        guard let resultPointer else { throw FFFSearchError.nullHandle("fff_create_instance_with") }
        let handle = try Self.unwrapHandleResult(resultPointer, operation: "fff_create_instance_with")
        guard let handle else { throw FFFSearchError.nullHandle("fff_create_instance_with") }
        self.handle = handle
    }

    deinit {
        close()
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

    public func waitForScan(timeoutMilliseconds: UInt64) throws -> Bool {
        try boolResult(operation: "fff_wait_for_scan") { handle in
            fff_wait_for_scan(handle, timeoutMilliseconds)
        }
    }

    public func waitForWatcher(timeoutMilliseconds: UInt64) throws -> Bool {
        try boolResult(operation: "fff_wait_for_watcher") { handle in
            fff_wait_for_watcher(handle, timeoutMilliseconds)
        }
    }

    public func scanFiles() throws {
        try emptyResult(operation: "fff_scan_files") { handle in
            fff_scan_files(handle)
        }
    }

    public func restartIndex(newPath: String) throws {
        try locked { handle in
            let resultPointer = newPath.withCString { pathPointer in
                fff_restart_index(handle, pathPointer)
            }
            try Self.consumeEmptyResult(resultPointer, operation: "fff_restart_index")
        }
    }

    public func refreshGitStatus() throws -> Int64 {
        try intResult(operation: "fff_refresh_git_status") { handle in
            fff_refresh_git_status(handle)
        }
    }

    public func isScanning() throws -> Bool {
        try locked { handle in
            fff_is_scanning(handle)
        }
    }

    public func basePath() throws -> String? {
        try stringResult(operation: "fff_get_base_path") { handle in
            fff_get_base_path(handle)
        }
    }

    public func scanProgress() throws -> FFFScanProgress {
        try locked { handle in
            guard let resultPointer = fff_get_scan_progress(handle) else {
                throw FFFSearchError.nullHandle("fff_get_scan_progress")
            }
            guard let rawHandle = try Self.unwrapHandleResult(resultPointer, operation: "fff_get_scan_progress") else {
                throw FFFSearchError.nullHandle("fff_get_scan_progress")
            }
            let progress = rawHandle.assumingMemoryBound(to: FffScanProgress.self)
            defer { fff_free_scan_progress(progress) }

            return FFFScanProgress(
                scannedFilesCount: progress.pointee.scanned_files_count,
                isScanning: progress.pointee.is_scanning,
                isWatcherReady: progress.pointee.is_watcher_ready,
                isWarmupComplete: progress.pointee.is_warmup_complete
            )
        }
    }

    public func healthCheck(testPath: String? = nil) throws -> String? {
        try locked { handle in
            try Self.withOptionalCString(testPath) { testPathPointer in
                try Self.unwrapStringResult(
                    fff_health_check(handle, testPathPointer),
                    operation: "fff_health_check"
                )
            }
        }
    }

    public func trackQuery(_ query: String, filePath: String) throws -> Bool {
        try locked { handle in
            let resultPointer = query.withCString { queryPointer in
                filePath.withCString { filePathPointer in
                    fff_track_query(handle, queryPointer, filePathPointer)
                }
            }
            guard let resultPointer else { throw FFFSearchError.nullHandle("fff_track_query") }
            defer { fff_free_result(resultPointer) }
            try Self.ensureSuccess(resultPointer)
            return resultPointer.pointee.int_value != 0
        }
    }

    public func historicalQuery(offset: UInt64 = 0) throws -> String? {
        try stringResult(operation: "fff_get_historical_query") { handle in
            fff_get_historical_query(handle, offset)
        }
    }

    public func searchFiles(
        query: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0,
        comboBoostMultiplier: Int32 = 0,
        minComboCount: UInt32 = 0
    ) throws -> [FFFFileMatch] {
        try searchFilesResult(
            query: query,
            pageSize: pageSize,
            pageIndex: pageIndex,
            currentFile: currentFile,
            maxThreads: maxThreads,
            comboBoostMultiplier: comboBoostMultiplier,
            minComboCount: minComboCount
        ).matches
    }

    public func searchFilesResult(
        query: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0,
        comboBoostMultiplier: Int32 = 0,
        minComboCount: UInt32 = 0
    ) throws -> FFFFileSearchResult {
        try locked { handle in
            let resultPointer = try Self.withOptionalCString(currentFile) { currentFilePointer in
                query.withCString { queryPointer in
                    fff_search(
                        handle,
                        queryPointer,
                        currentFilePointer,
                        maxThreads,
                        pageIndex,
                        pageSize,
                        comboBoostMultiplier,
                        minComboCount
                    )
                }
            }
            return try Self.readFileSearchResult(resultPointer, operation: "fff_search")
        }
    }

    public func globFiles(
        pattern: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0
    ) throws -> [FFFFileMatch] {
        try globFilesResult(
            pattern: pattern,
            pageSize: pageSize,
            pageIndex: pageIndex,
            currentFile: currentFile,
            maxThreads: maxThreads
        ).matches
    }

    public func globFilesResult(
        pattern: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0
    ) throws -> FFFFileSearchResult {
        try locked { handle in
            let resultPointer = try Self.withOptionalCString(currentFile) { currentFilePointer in
                pattern.withCString { patternPointer in
                    fff_glob(handle, patternPointer, currentFilePointer, maxThreads, pageIndex, pageSize)
                }
            }
            return try Self.readFileSearchResult(resultPointer, operation: "fff_glob")
        }
    }

    public func searchDirectories(
        query: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0
    ) throws -> [FFFDirectoryMatch] {
        try searchDirectoriesResult(
            query: query,
            pageSize: pageSize,
            pageIndex: pageIndex,
            currentFile: currentFile,
            maxThreads: maxThreads
        ).matches
    }

    public func searchDirectoriesResult(
        query: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0
    ) throws -> FFFDirectorySearchResult {
        try locked { handle in
            let resultPointer = try Self.withOptionalCString(currentFile) { currentFilePointer in
                query.withCString { queryPointer in
                    fff_search_directories(handle, queryPointer, currentFilePointer, maxThreads, pageIndex, pageSize)
                }
            }
            return try Self.readDirectorySearchResult(resultPointer, operation: "fff_search_directories")
        }
    }

    public func searchMixed(
        query: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0,
        comboBoostMultiplier: Int32 = 0,
        minComboCount: UInt32 = 0
    ) throws -> [FFFMixedMatch] {
        try searchMixedResult(
            query: query,
            pageSize: pageSize,
            pageIndex: pageIndex,
            currentFile: currentFile,
            maxThreads: maxThreads,
            comboBoostMultiplier: comboBoostMultiplier,
            minComboCount: minComboCount
        ).matches
    }

    public func searchMixedResult(
        query: String,
        pageSize: UInt32 = 100,
        pageIndex: UInt32 = 0,
        currentFile: String? = nil,
        maxThreads: UInt32 = 0,
        comboBoostMultiplier: Int32 = 0,
        minComboCount: UInt32 = 0
    ) throws -> FFFMixedSearchResult {
        try locked { handle in
            let resultPointer = try Self.withOptionalCString(currentFile) { currentFilePointer in
                query.withCString { queryPointer in
                    fff_search_mixed(
                        handle,
                        queryPointer,
                        currentFilePointer,
                        maxThreads,
                        pageIndex,
                        pageSize,
                        comboBoostMultiplier,
                        minComboCount
                    )
                }
            }
            return try Self.readMixedSearchResult(resultPointer, operation: "fff_search_mixed")
        }
    }

    public func liveGrep(
        query: String,
        pageLimit: UInt32 = 100,
        maxMatchesPerFile: UInt32 = 1,
        timeBudgetMilliseconds: UInt64 = 250,
        contextLineCount: UInt32 = 0,
        mode: FFFGrepMode = .plainText,
        maxFileSize: UInt64 = 0,
        smartCase: Bool = true,
        fileOffset: UInt32 = 0,
        classifyDefinitions: Bool = false
    ) throws -> [FFFContentMatch] {
        try liveGrepResult(
            query: query,
            pageLimit: pageLimit,
            maxMatchesPerFile: maxMatchesPerFile,
            timeBudgetMilliseconds: timeBudgetMilliseconds,
            beforeContextLineCount: contextLineCount,
            afterContextLineCount: contextLineCount,
            mode: mode,
            maxFileSize: maxFileSize,
            smartCase: smartCase,
            fileOffset: fileOffset,
            classifyDefinitions: classifyDefinitions
        ).matches
    }

    public func liveGrepResult(
        query: String,
        pageLimit: UInt32 = 100,
        maxMatchesPerFile: UInt32 = 1,
        timeBudgetMilliseconds: UInt64 = 250,
        beforeContextLineCount: UInt32 = 0,
        afterContextLineCount: UInt32 = 0,
        mode: FFFGrepMode = .plainText,
        maxFileSize: UInt64 = 0,
        smartCase: Bool = true,
        fileOffset: UInt32 = 0,
        classifyDefinitions: Bool = false
    ) throws -> FFFGrepSearchResult {
        try locked { handle in
            let resultPointer = query.withCString { queryPointer in
                fff_live_grep(
                    handle,
                    queryPointer,
                    mode.rawValue,
                    maxFileSize,
                    maxMatchesPerFile,
                    smartCase,
                    fileOffset,
                    pageLimit,
                    timeBudgetMilliseconds,
                    beforeContextLineCount,
                    afterContextLineCount,
                    classifyDefinitions
                )
            }
            return try Self.readGrepSearchResult(resultPointer, operation: "fff_live_grep")
        }
    }

    public func multiGrep(
        patterns: [String],
        constraints: String? = nil,
        pageLimit: UInt32 = 100,
        maxMatchesPerFile: UInt32 = 1,
        timeBudgetMilliseconds: UInt64 = 250,
        beforeContextLineCount: UInt32 = 0,
        afterContextLineCount: UInt32 = 0,
        maxFileSize: UInt64 = 0,
        smartCase: Bool = true,
        fileOffset: UInt32 = 0,
        classifyDefinitions: Bool = false
    ) throws -> [FFFContentMatch] {
        try multiGrepResult(
            patterns: patterns,
            constraints: constraints,
            pageLimit: pageLimit,
            maxMatchesPerFile: maxMatchesPerFile,
            timeBudgetMilliseconds: timeBudgetMilliseconds,
            beforeContextLineCount: beforeContextLineCount,
            afterContextLineCount: afterContextLineCount,
            maxFileSize: maxFileSize,
            smartCase: smartCase,
            fileOffset: fileOffset,
            classifyDefinitions: classifyDefinitions
        ).matches
    }

    public func multiGrepResult(
        patterns: [String],
        constraints: String? = nil,
        pageLimit: UInt32 = 100,
        maxMatchesPerFile: UInt32 = 1,
        timeBudgetMilliseconds: UInt64 = 250,
        beforeContextLineCount: UInt32 = 0,
        afterContextLineCount: UInt32 = 0,
        maxFileSize: UInt64 = 0,
        smartCase: Bool = true,
        fileOffset: UInt32 = 0,
        classifyDefinitions: Bool = false
    ) throws -> FFFGrepSearchResult {
        try locked { handle in
            let joinedPatterns = patterns.joined(separator: "\n")
            let resultPointer = try Self.withOptionalCString(constraints) { constraintsPointer in
                joinedPatterns.withCString { patternsPointer in
                    fff_multi_grep(
                        handle,
                        patternsPointer,
                        constraintsPointer,
                        maxFileSize,
                        maxMatchesPerFile,
                        smartCase,
                        fileOffset,
                        pageLimit,
                        timeBudgetMilliseconds,
                        beforeContextLineCount,
                        afterContextLineCount,
                        classifyDefinitions
                    )
                }
            }
            return try Self.readGrepSearchResult(resultPointer, operation: "fff_multi_grep")
        }
    }

    private func locked<Result>(_ body: (UnsafeMutableRawPointer) throws -> Result) throws -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(requireHandleLocked())
    }

    private func requireHandleLocked() throws -> UnsafeMutableRawPointer {
        guard let handle else { throw FFFSearchError.nullHandle("FFFIndex") }
        return handle
    }

    private func boolResult(
        operation: String,
        _ call: (UnsafeMutableRawPointer) -> UnsafeMutablePointer<FffResult>?
    ) throws -> Bool {
        try locked { handle in
            guard let resultPointer = call(handle) else { throw FFFSearchError.nullHandle(operation) }
            defer { fff_free_result(resultPointer) }
            try Self.ensureSuccess(resultPointer)
            return resultPointer.pointee.int_value != 0
        }
    }

    private func intResult(
        operation: String,
        _ call: (UnsafeMutableRawPointer) -> UnsafeMutablePointer<FffResult>?
    ) throws -> Int64 {
        try locked { handle in
            guard let resultPointer = call(handle) else { throw FFFSearchError.nullHandle(operation) }
            defer { fff_free_result(resultPointer) }
            try Self.ensureSuccess(resultPointer)
            return resultPointer.pointee.int_value
        }
    }

    private func emptyResult(
        operation: String,
        _ call: (UnsafeMutableRawPointer) -> UnsafeMutablePointer<FffResult>?
    ) throws {
        try locked { handle in
            try Self.consumeEmptyResult(call(handle), operation: operation)
        }
    }

    private func stringResult(
        operation: String,
        _ call: (UnsafeMutableRawPointer) -> UnsafeMutablePointer<FffResult>?
    ) throws -> String? {
        try locked { handle in
            try Self.unwrapStringResult(call(handle), operation: operation)
        }
    }

    private static func consumeEmptyResult(_ resultPointer: UnsafeMutablePointer<FffResult>?, operation: String) throws {
        guard let resultPointer else { throw FFFSearchError.nullHandle(operation) }
        defer { fff_free_result(resultPointer) }
        try ensureSuccess(resultPointer)
    }

    private static func unwrapHandleResult(
        _ resultPointer: UnsafeMutablePointer<FffResult>,
        operation: String
    ) throws -> UnsafeMutableRawPointer? {
        defer { fff_free_result(resultPointer) }
        try ensureSuccess(resultPointer)
        return resultPointer.pointee.handle
    }

    private static func unwrapStringResult(
        _ resultPointer: UnsafeMutablePointer<FffResult>?,
        operation: String
    ) throws -> String? {
        guard let resultPointer else { throw FFFSearchError.nullHandle(operation) }
        defer { fff_free_result(resultPointer) }
        try ensureSuccess(resultPointer)

        guard let rawHandle = resultPointer.pointee.handle else { return nil }
        let stringPointer = rawHandle.assumingMemoryBound(to: CChar.self)
        defer { fff_free_string(stringPointer) }
        return String(cString: stringPointer)
    }

    private static func ensureSuccess(_ resultPointer: UnsafeMutablePointer<FffResult>) throws {
        guard resultPointer.pointee.success else {
            let message = resultPointer.pointee.error.map { String(cString: $0) } ?? "Unknown FFF error"
            throw FFFSearchError.operationFailed(message)
        }
    }

    private static func readFileSearchResult(
        _ resultPointer: UnsafeMutablePointer<FffResult>?,
        operation: String
    ) throws -> FFFFileSearchResult {
        guard let resultPointer else { throw FFFSearchError.nullHandle(operation) }
        guard let rawHandle = try unwrapHandleResult(resultPointer, operation: operation) else {
            return FFFFileSearchResult(matches: [], totalMatched: 0, totalFiles: 0)
        }
        let searchResult = rawHandle.assumingMemoryBound(to: FffSearchResult.self)
        defer { fff_free_search_result(searchResult) }

        let count = fff_search_result_get_count(searchResult)
        var matches: [FFFFileMatch] = []
        matches.reserveCapacity(Int(count))

        for index in 0..<count {
            guard let item = fff_search_result_get_item(searchResult, index),
                  let relativePath = string(fff_file_item_get_relative_path(item)) else { continue }

            matches.append(FFFFileMatch(
                relativePath: relativePath,
                fileName: string(fff_file_item_get_file_name(item)),
                gitStatus: normalizedGitStatus(string(fff_file_item_get_git_status(item))),
                size: fff_file_item_get_size(item),
                modified: fff_file_item_get_modified(item),
                accessFrecencyScore: fff_file_item_get_access_frecency_score(item),
                modificationFrecencyScore: fff_file_item_get_modification_frecency_score(item),
                totalFrecencyScore: fff_file_item_get_total_frecency_score(item),
                isBinary: fff_file_item_get_is_binary(item)
            ))
        }

        return FFFFileSearchResult(
            matches: matches,
            totalMatched: fff_search_result_get_total_matched(searchResult),
            totalFiles: fff_search_result_get_total_files(searchResult)
        )
    }

    private static func readDirectorySearchResult(
        _ resultPointer: UnsafeMutablePointer<FffResult>?,
        operation: String
    ) throws -> FFFDirectorySearchResult {
        guard let resultPointer else { throw FFFSearchError.nullHandle(operation) }
        guard let rawHandle = try unwrapHandleResult(resultPointer, operation: operation) else {
            return FFFDirectorySearchResult(matches: [], totalMatched: 0, totalDirectories: 0)
        }
        let searchResult = rawHandle.assumingMemoryBound(to: FffDirSearchResult.self)
        defer { fff_free_dir_search_result(searchResult) }

        let count = searchResult.pointee.count
        var matches: [FFFDirectoryMatch] = []
        matches.reserveCapacity(Int(count))

        for index in 0..<count {
            guard let item = fff_dir_search_result_get_item(searchResult, index),
                  let relativePath = string(item.pointee.relative_path) else { continue }

            matches.append(FFFDirectoryMatch(
                relativePath: relativePath,
                directoryName: string(item.pointee.dir_name),
                maxAccessFrecency: item.pointee.max_access_frecency
            ))
        }

        return FFFDirectorySearchResult(
            matches: matches,
            totalMatched: searchResult.pointee.total_matched,
            totalDirectories: searchResult.pointee.total_dirs
        )
    }

    private static func readMixedSearchResult(
        _ resultPointer: UnsafeMutablePointer<FffResult>?,
        operation: String
    ) throws -> FFFMixedSearchResult {
        guard let resultPointer else { throw FFFSearchError.nullHandle(operation) }
        guard let rawHandle = try unwrapHandleResult(resultPointer, operation: operation) else {
            return FFFMixedSearchResult(matches: [], totalMatched: 0, totalFiles: 0, totalDirectories: 0)
        }
        let searchResult = rawHandle.assumingMemoryBound(to: FffMixedSearchResult.self)
        defer { fff_free_mixed_search_result(searchResult) }

        let count = searchResult.pointee.count
        var matches: [FFFMixedMatch] = []
        matches.reserveCapacity(Int(count))

        for index in 0..<count {
            guard let item = fff_mixed_search_result_get_item(searchResult, index),
                  let relativePath = string(item.pointee.relative_path) else { continue }

            if item.pointee.item_type == 0 {
                matches.append(.file(FFFFileMatch(
                    relativePath: relativePath,
                    fileName: string(item.pointee.display_name),
                    gitStatus: normalizedGitStatus(string(item.pointee.git_status)),
                    size: item.pointee.size,
                    modified: item.pointee.modified,
                    accessFrecencyScore: item.pointee.access_frecency_score,
                    modificationFrecencyScore: item.pointee.modification_frecency_score,
                    totalFrecencyScore: item.pointee.total_frecency_score,
                    isBinary: item.pointee.is_binary
                )))
            } else {
                matches.append(.directory(FFFDirectoryMatch(
                    relativePath: relativePath,
                    directoryName: string(item.pointee.display_name),
                    maxAccessFrecency: Int32(clamping: item.pointee.access_frecency_score)
                )))
            }
        }

        return FFFMixedSearchResult(
            matches: matches,
            totalMatched: searchResult.pointee.total_matched,
            totalFiles: searchResult.pointee.total_files,
            totalDirectories: searchResult.pointee.total_dirs
        )
    }

    private static func readGrepSearchResult(
        _ resultPointer: UnsafeMutablePointer<FffResult>?,
        operation: String
    ) throws -> FFFGrepSearchResult {
        guard let resultPointer else { throw FFFSearchError.nullHandle(operation) }
        guard let rawHandle = try unwrapHandleResult(resultPointer, operation: operation) else {
            return FFFGrepSearchResult(
                matches: [],
                totalMatched: 0,
                totalFilesSearched: 0,
                totalFiles: 0,
                filteredFileCount: 0,
                nextFileOffset: 0,
                regexFallbackError: nil
            )
        }
        let grepResult = rawHandle.assumingMemoryBound(to: FffGrepResult.self)
        defer { fff_free_grep_result(grepResult) }

        let count = fff_grep_result_get_count(grepResult)
        var matches: [FFFContentMatch] = []
        matches.reserveCapacity(Int(count))

        for index in 0..<count {
            guard let item = fff_grep_result_get_match(grepResult, index),
                  let relativePath = string(fff_grep_match_get_relative_path(item)),
                  let lineContent = string(fff_grep_match_get_line_content(item)) else { continue }

            matches.append(FFFContentMatch(
                relativePath: relativePath,
                lineNumber: Int(fff_grep_match_get_line_number(item)),
                lineContent: lineContent,
                fileName: string(fff_grep_match_get_file_name(item)),
                gitStatus: normalizedGitStatus(string(fff_grep_match_get_git_status(item))),
                column: fff_grep_match_get_col(item),
                byteOffset: fff_grep_match_get_byte_offset(item),
                matchRanges: matchRanges(from: item),
                contextBefore: contextLines(from: item, count: fff_grep_match_get_context_before_count, line: fff_grep_match_get_context_before),
                contextAfter: contextLines(from: item, count: fff_grep_match_get_context_after_count, line: fff_grep_match_get_context_after),
                size: fff_grep_match_get_size(item),
                modified: fff_grep_match_get_modified(item),
                accessFrecencyScore: fff_grep_match_get_access_frecency_score(item),
                modificationFrecencyScore: fff_grep_match_get_modification_frecency_score(item),
                totalFrecencyScore: fff_grep_match_get_total_frecency_score(item),
                fuzzyScore: fff_grep_match_get_has_fuzzy_score(item) ? fff_grep_match_get_fuzzy_score(item) : nil,
                isBinary: fff_grep_match_get_is_binary(item),
                isDefinition: fff_grep_match_get_is_definition(item)
            ))
        }

        return FFFGrepSearchResult(
            matches: matches,
            totalMatched: fff_grep_result_get_total_matched(grepResult),
            totalFilesSearched: fff_grep_result_get_total_files_searched(grepResult),
            totalFiles: fff_grep_result_get_total_files(grepResult),
            filteredFileCount: fff_grep_result_get_filtered_file_count(grepResult),
            nextFileOffset: fff_grep_result_get_next_file_offset(grepResult),
            regexFallbackError: string(fff_grep_result_get_regex_fallback_error(grepResult))
        )
    }

    private static func matchRanges(from match: UnsafePointer<FffGrepMatch>) -> [FFFMatchRange] {
        let count = fff_grep_match_get_match_ranges_count(match)
        guard count > 0 else { return [] }

        var ranges: [FFFMatchRange] = []
        ranges.reserveCapacity(Int(count))
        for index in 0..<count {
            guard let range = fff_grep_match_get_match_range(match, index) else { continue }
            ranges.append(FFFMatchRange(start: range.pointee.start, end: range.pointee.end))
        }
        return ranges
    }

    private static func contextLines(
        from match: UnsafePointer<FffGrepMatch>,
        count: (UnsafePointer<FffGrepMatch>?) -> UInt32,
        line: (UnsafePointer<FffGrepMatch>?, UInt32) -> UnsafePointer<CChar>?
    ) -> [String] {
        let lineCount = count(match)
        guard lineCount > 0 else { return [] }

        var lines: [String] = []
        lines.reserveCapacity(Int(lineCount))
        for index in 0..<lineCount {
            guard let contextLine = string(line(match, index)) else { continue }
            lines.append(contextLine)
        }
        return lines
    }

    private static func string(_ pointer: UnsafePointer<CChar>?) -> String? {
        pointer.map { String(cString: $0) }
    }

    private static func string(_ pointer: UnsafeMutablePointer<CChar>?) -> String? {
        pointer.map { String(cString: $0) }
    }

    private static func normalizedGitStatus(_ gitStatus: String?) -> String? {
        guard let gitStatus, !gitStatus.isEmpty, gitStatus != "unknown" else { return nil }
        return gitStatus
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
