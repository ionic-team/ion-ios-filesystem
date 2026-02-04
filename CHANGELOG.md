## 1.1.0

### Features

- Feature: Alternative `readFile` and `readFileInChunks` methods with optional `length` and `offset` parameters.

## 1.0.1

### Fixes

- Do not add trailing slash to files.

## 1.0.0

### Features
- Add read operations, namely `readEntireFile(atURL:withEncoding:)`, `readFileInChunks(atURL:withEncoding:andChunkSize:)`, `listDirectory(atURL:)`, `getItemAttributes(atPath:)` and `getFileURL(atPath: withSearchPath:)`.
- Add write operations, namely `saveFile(atURL:withEncodingAndData:includeIntermediateDirectories:)` and `appendData(_:atURL:includeIntermediateDirectories:)`.
- Add directory operations, namely `createDirectory(atURL:includeIntermediateDirectories:)` and `removeDirectory(atURL:includeIntermediateDirectories:)`.
- Add file management operations, namely `deleteFile(atURL:)`, `renameItem(fromURL:toURL:)` and `copyItem(fromURL:toURL:)`.

### Chores
- Add dependency management contract file for CocoaPods and Swift Package Manager.
- Add GitHub Actions workflows.
- Create Repository
