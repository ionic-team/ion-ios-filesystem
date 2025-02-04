import Foundation

public enum IONFILEEncoding: Equatable {
    case byteBuffer
    case string(encoding: IONFILEStringEncoding)
}

public enum IONFILEEncodingValueMapper {
    case byteBuffer(value: Data)
    case string(encoding: IONFILEStringEncoding, value: String)
}

public enum IONFILEStringEncoding: String {
    case ascii
    case utf8
    case utf16

    var stringEncoding: String.Encoding {
        switch self {
        case .ascii: .ascii
        case .utf8: .utf8
        case .utf16: .utf16
        }
    }
}

public enum IONFILESearchPath {
    case directory(type: IONFILEDirectoryType)
    case raw
}

public enum IONFILEDirectoryType {
    case cache
    case document
    case library
    case notSyncedLibrary
    case temporary
}
