import Foundation

public struct IONFILEManager {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
}

extension IONFILEManager: IONFILEDirectoryManager {
    public func createDirectory(atURL pathURL: URL, includeIntermediateDirectories: Bool) throws {
        try withSecurityScopedAccess(to: pathURL) {
            let parentDirectoryURL = pathURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parentDirectoryURL.urlPath) {
                if !includeIntermediateDirectories {
                    throw IONFILEFileManagerError.missingParentFolder
                }
            }
            if fileManager.fileExists(atPath: pathURL.urlPath) {
                throw IONFILEDirectoryManagerError.alreadyExists
            }
            
            try fileManager.createDirectory(at: pathURL, withIntermediateDirectories: includeIntermediateDirectories)
        }
    }

    public func removeDirectory(atURL pathURL: URL, includeIntermediateDirectories: Bool) throws {
        try withSecurityScopedAccess(to: pathURL) {
            if !includeIntermediateDirectories {
                let directoryContents = try listDirectory(atURL: pathURL)
                if !directoryContents.isEmpty {
                    throw IONFILEDirectoryManagerError.notEmpty
                }
            }

            try fileManager.removeItem(at: pathURL)
        }
    }

    public func listDirectory(atURL pathURL: URL) throws -> [URL] {
        try withSecurityScopedAccess(to: pathURL) {
            try fileManager.contentsOfDirectory(at: pathURL, includingPropertiesForKeys: nil)
        }
    }
}

extension IONFILEManager: IONFILEFileManager {
    public func readEntireFile(atURL fileURL: URL, withEncoding encoding: IONFILEEncoding) throws -> IONFILEEncodingValueMapper {
        try withSecurityScopedAccess(to: fileURL) {
            let result: IONFILEEncodingValueMapper
            switch encoding {
            case .byteBuffer:
                let fileData = try readFileAsByteBuffer(from: fileURL)
                result = .byteBuffer(value: fileData)
            case .string(let stringEncoding):
                let fileData = try readFileAsString(from: fileURL, using: stringEncoding.stringEncoding)
                result = .string(encoding: stringEncoding, value: fileData)
            }

            return result
        }
    }

    public func readFileInChunks(atURL fileURL: URL, withEncoding encoding: IONFILEEncoding, andChunkSize chunkSize: Int) throws -> IONFILEChunkPublisher {
        try withSecurityScopedAccess(to: fileURL) {
            .init(fileURL, chunkSize, encoding)
        }
    }

    public func readRange(atURL fileURL: URL, offset: UInt64, length: Int, withEncoding encoding: IONFILEEncoding) throws -> IONFILEEncodingValueMapper {
        try withSecurityScopedAccess(to: fileURL) {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)
            defer {
                try? fileHandle.close()
            }
            
            try fileHandle.seek(toOffset: offset)
            let data = try fileHandle.read(upToCount: length)
            
            guard let data = data else {
                throw IONFILEFileManagerError.fileNotFound(atPath: fileURL.path)
            }
            
            switch encoding {
            case .byteBuffer:
                return .byteBuffer(value: data)
            case .string(let stringEncoding):
                guard let stringData = String(data: data, encoding: stringEncoding.stringEncoding) else {
                    throw IONFILEFileManagerError.cantDecodeData(usingEncoding: stringEncoding)
                }
                return .string(encoding: stringEncoding, value: stringData)
            }
        }
    }

    public func getFileURL(atPath path: String, withSearchPath searchPath: IONFILESearchPath) throws -> URL {
        switch searchPath {
        case .directory(let type):
            try resolveDirectoryURL(forType: type, with: path)
        case .raw:
            try resolveRawURL(from: path)
        }
    }

    public func deleteFile(atURL url: URL) throws {
        try withSecurityScopedAccess(to: url) {
            let path = url.urlPath
            guard fileManager.fileExists(atPath: path) else {
                throw IONFILEFileManagerError.fileNotFound(atPath: path)
            }

            try fileManager.removeItem(at: url)
        }
    }

    public func saveFile(atURL fileURL: URL, withEncodingAndData encodingMapper: IONFILEEncodingValueMapper, includeIntermediateDirectories: Bool) throws {
        try withSecurityScopedAccess(to: fileURL) {
            let fileDirectoryURL = fileURL.deletingLastPathComponent()

            if !fileManager.fileExists(atPath: fileDirectoryURL.urlPath) {
                if includeIntermediateDirectories {
                    try createDirectory(atURL: fileDirectoryURL, includeIntermediateDirectories: true)
                } else {
                    throw IONFILEFileManagerError.missingParentFolder
                }
            }

            switch encodingMapper {
            case .byteBuffer(let value):
                try value.write(to: fileURL)
            case .string(let encoding, let value):
                try value.write(to: fileURL, atomically: false, encoding: encoding.stringEncoding)
            }
        }
    }

    public func appendData(_ encodingMapper: IONFILEEncodingValueMapper, atURL url: URL, includeIntermediateDirectories: Bool) throws {
        try withSecurityScopedAccess(to: url) {
            guard fileManager.fileExists(atPath: url.urlPath) else {
                try saveFile(atURL: url, withEncodingAndData: encodingMapper, includeIntermediateDirectories: includeIntermediateDirectories)
                return
            }

            let dataToAppend: Data
            switch encodingMapper {
            case .byteBuffer(let value):
                dataToAppend = value
            case .string(let encoding, let value):
                guard let valueData = value.data(using: encoding.stringEncoding) else {
                    throw IONFILEFileManagerError.cantDecodeData(usingEncoding: encoding)
                }
                dataToAppend = valueData
            }

            let fileHandle = try FileHandle(forWritingTo: url)
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: dataToAppend)
            try fileHandle.close()
        }
    }

    public func getItemAttributes(atURL url: URL) throws -> IONFILEItemAttributeModel {
        try withSecurityScopedAccess(to: url) {
            let attributesDictionary = try fileManager.attributesOfItem(atPath: url.urlPath)
            return .create(from: attributesDictionary)
        }
    }

    public func renameItem(fromURL originURL: URL, toURL destinationURL: URL) throws {
        try withSecurityScopedAccess(to: originURL) {
            try withSecurityScopedAccess(to: destinationURL) {
                guard try shouldPerformDualPathOperation(fromURL: originURL, toURL: destinationURL) else {
                    return
                }
                try fileManager.moveItem(at: originURL, to: destinationURL)
            }
        }
    }

    public func copyItem(fromURL originURL: URL, toURL destinationURL: URL) throws {
        try withSecurityScopedAccess(to: originURL) {
            try withSecurityScopedAccess(to: destinationURL) {
                guard try shouldPerformDualPathOperation(fromURL: originURL, toURL: destinationURL) else {
                    return
                }
                try fileManager.copyItem(at: originURL, to: destinationURL)
            }
        }
    }
}

private extension IONFILEManager {
    func withSecurityScopedAccess<T>(to fileURL: URL, perform operation: () throws -> T) throws -> T {
        // Check if the URL requires security-scoped access
        let requiresSecurityScope = fileURL.startAccessingSecurityScopedResource()

        // Use defer to ensure we stop accessing the security-scoped resource
        // only if we started accessing it
        defer {
            if requiresSecurityScope {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }

    func readFileAsByteBuffer(from fileURL: URL) throws -> Data {
        try Data(contentsOf: fileURL)
    }

    func readFileAsString(from fileURL: URL, using stringEncoding: String.Encoding) throws -> String {
        try String(contentsOf: fileURL, encoding: stringEncoding)
    }

    func resolveDirectoryURL(forType directoryType: IONFILEDirectoryType, with path: String) throws -> URL {
        guard let directoryURL = directoryType.fetchURL(using: fileManager) else {
            throw IONFILEFileManagerError.directoryNotFound(atPath: path)
        }
        return fixPathComponentsIfNeeded(path.isEmpty ? directoryURL : directoryURL.urlWithAppendingPath(path))
    }

    func resolveRawURL(from path: String) throws -> URL {
        guard let rawURL = URL(string: path) else {
            throw IONFILEFileManagerError.cantCreateURL(forPath: path)
        }
        return fixPathComponentsIfNeeded(rawURL)
    }

    func shouldPerformDualPathOperation(fromURL originURL: URL, toURL destinationURL: URL) throws -> Bool {
        guard originURL != destinationURL else {
            return false
        }

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: destinationURL.urlPath, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                try deleteFile(atURL: destinationURL)
            }
        }

        return true
    }
    
    private func fixPathComponentsIfNeeded(_ url: URL) -> URL {
        // 1) add trailing slash in case of directory
        var isDirectory: ObjCBool = false
        var urlToReturn = url
        let fileExists = fileManager.fileExists(atPath: url.urlPath, isDirectory: &isDirectory)
        if !urlToReturn.absoluteString.hasSuffix("/"), isDirectory.boolValue || (!fileExists && url.pathExtension.isEmpty) {
            urlToReturn = urlToReturn.appendingPathComponent("")
        }
        // 2) remove duplicate slashes //, except for the ones indicating the scheme (e.g. 'file://')
        var urlStringWithoutDuplicateSeparators = urlToReturn.absoluteString.replacingOccurrences(
            of: #"(?<!:)/{2,}(?!/)"#,
            with: "/",
            options: .regularExpression
        )
        if (urlToReturn.absoluteString.contains(":///")) {
            // the regex may ommit a slash after ://, which is incorrect because it breaks in case of an absolute file path
            urlStringWithoutDuplicateSeparators = urlStringWithoutDuplicateSeparators.replacingOccurrences(of: "://", with: ":///")
        }
        if let finalUrl = URL(string: urlStringWithoutDuplicateSeparators) {
            urlToReturn = finalUrl
        }
        return urlToReturn
    }
}

private extension IONFILEDirectoryType {
    struct Keys {
        static let noCloudPath = "NoCloud"
    }

    func fetchURL(using fileManager: FileManager) -> URL? {
        switch self {
        case .cache:
            fetchURL(using: fileManager, forSearchPath: .cachesDirectory)
        case .document:
            fetchURL(using: fileManager, forSearchPath: .documentDirectory)
        case .library:
            fetchURL(using: fileManager, forSearchPath: .libraryDirectory)
        case .notSyncedLibrary:
            fetchNotSyncedLibrary(using: fileManager)
        case .temporary:
            fileManager.temporaryDirectory
        }
    }

    private func fetchURL(using fileManager: FileManager, forSearchPath searchPath: FileManager.SearchPathDirectory) -> URL? {
        fileManager.urls(for: searchPath, in: .userDomainMask).first
    }

    private func fetchNotSyncedLibrary(using fileManager: FileManager) -> URL? {
        var url = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?.urlWithAppendingPath(Keys.noCloudPath)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? url?.setResourceValues(resourceValues)

        return url
    }
}
