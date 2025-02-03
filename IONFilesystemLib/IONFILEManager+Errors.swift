enum IONFILEDirectoryManagerError: Error {
    case notEmpty
}

enum IONFILEFileManagerError: Error {
    case cantCreateURL
    case cantDecodeData
    case directoryNotFound
    case fileNotFound
    case missingParentFolder
}

enum IONFILEChunkPublisherError: Error {
    case cantEncodeData
    case notAbleToReadFile
}
