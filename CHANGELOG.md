# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Features
- Add read operations, namely `readEntireFile(atURL:withEncoding:)`, `readFileInChunks(atURL:withEncoding:andChunkSize:)`, `listDirectory(atURL:)`, `getItemAttributes(atPath:)` and `getFileURL(atPath: withSearchPath:)`.
- Add write operations, namely `saveFile(atURL:withEncodingAndData:includeIntermediateDirectories:)` and `appendData(_:atURL:includeIntermediateDirectories:)`.
- Add directory operations, namely `createDirectory(atURL:includeIntermediateDirectories:)` and `removeDirectory(atURL:includeIntermediateDirectories:)`.
- Add file management operations, namely `deleteFile(atURL:)`, `renameItem(fromURL:toURL:)` and `copyItem(fromURL:toURL:)`.

### Chores
- Add dependency management contract file for CocoaPods and Swift Package Manager.
- Add GitHub Actions workflows.
- Create Repository