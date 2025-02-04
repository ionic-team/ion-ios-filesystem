import Foundation

enum IONFILEDirectoryManagerError: LocalizedError {
    case notEmpty

    var errorDescription: String? {
        "Folder is not empty."
    }
}

enum IONFILEFileManagerError: LocalizedError, Equatable {
    case cantCreateURL(forPath: String)
    case cantDecodeData(usingEncoding: IONFILEStringEncoding)
    case directoryNotFound(atPath: String)
    case fileNotFound(atPath: String)
    case missingParentFolder

    var errorDescription: String? {
        switch self {
        case .cantCreateURL(let path): "Can't create URL for path '\(path)'."
        case .cantDecodeData(let encoding): "Can't decode data using encoding .\(encoding.rawValue)."
        case .directoryNotFound(let path): "Can't find directory at path '\(path)'."
        case .fileNotFound(let path): "Can't find file at path '\(path)'."
        case .missingParentFolder: "Parent folder doesn't exist."
        }
    }
}

enum IONFILEChunkPublisherError: LocalizedError, Equatable {
    case cantEncodeData(usingEncoding: IONFILEStringEncoding)
    case notAbleToReadFile

    var errorDescription: String? {
        switch self {
        case .cantEncodeData(let encoding): "Can't encode data using encoding .\(encoding.rawValue)."
        case .notAbleToReadFile: "Can't read file."
        }
    }
}
