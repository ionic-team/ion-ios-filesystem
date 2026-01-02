import Foundation

public protocol IONFILEDirectoryManager {
    func createDirectory(atURL: URL, includeIntermediateDirectories: Bool) throws
    func removeDirectory(atURL: URL, includeIntermediateDirectories: Bool) throws
    func listDirectory(atURL: URL) throws -> [URL]
}

public protocol IONFILEFileManager {
    func readEntireFile(atURL: URL, withEncoding: IONFILEEncoding) throws -> IONFILEEncodingValueMapper
    func readFileInChunks(atURL: URL, withEncoding: IONFILEEncoding, andChunkSize: Int) throws -> IONFILEChunkPublisher
    func readRange(atURL: URL, offset: UInt64, length: Int, withEncoding encoding: IONFILEEncoding) throws -> IONFILEEncodingValueMapper
    func getFileURL(atPath: String, withSearchPath: IONFILESearchPath) throws -> URL
    func deleteFile(atURL: URL) throws
    func saveFile(atURL: URL, withEncodingAndData: IONFILEEncodingValueMapper, includeIntermediateDirectories: Bool) throws
    func appendData(_ data: IONFILEEncodingValueMapper, atURL: URL, includeIntermediateDirectories: Bool) throws
    func getItemAttributes(atURL: URL) throws -> IONFILEItemAttributeModel
    func renameItem(fromURL: URL, toURL: URL) throws
    func copyItem(fromURL: URL, toURL: URL) throws
}
