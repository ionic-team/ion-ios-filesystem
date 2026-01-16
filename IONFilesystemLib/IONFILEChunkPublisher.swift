import Combine
import Foundation

public class IONFILEChunkPublisher: Publisher {
    public typealias Output = IONFILEEncodingValueMapper
    public typealias Failure = Error

    private let url: URL
    private let chunkSize: Int
    private let encoding: IONFILEEncoding
    private let offset: Int
    private let length: Int

    init(_ url: URL, _ chunkSize: Int, _ encoding: IONFILEEncoding, _ offset: Int = 0, _ length: Int = -1) {
        self.url = url
        self.chunkSize = chunkSize
        self.encoding = encoding
        self.offset = offset
        self.length = length
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = IONFILEChunkSubscription(url, chunkSize, encoding, offset, length, subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private class IONFILEChunkSubscription<S: Subscriber>: Subscription where S.Input == IONFILEEncodingValueMapper, S.Failure == Error {
    private let fileHandle: FileHandle?
    private let chunkSize: Int
    private let encoding: IONFILEEncoding
    private let offset: Int
    private let length: Int
    private let subscriber: S
    private var isCompleted = false

    init(_ url: URL, _ chunkSize: Int, _ encoding: IONFILEEncoding, _ offset: Int = 0, _ length: Int = -1, _ subscriber: S) {
        self.fileHandle = try? FileHandle(forReadingFrom: url)
        self.chunkSize = chunkSize
        self.encoding = encoding
        self.subscriber = subscriber
        self.offset = offset
        self.length = length
    }

    func request(_ demand: Subscribers.Demand) {
        guard let fileHandle = fileHandle, !isCompleted else {
            return subscriber.receive(completion: .failure(IONFILEChunkPublisherError.notAbleToReadFile))
        }
        
        if (offset > 0) {
            do {
                try fileHandle.seek(toOffset: UInt64(offset))
            }  catch {
                complete(withValue: .failure(error))
                return
            }
        }

        var remainingToRead = Int.max
        if (length > 0) {
            remainingToRead = length
        }
        while demand > .none {
            do {
                var readCount = chunkSize
                if (length > 0) {
                    readCount = min(readCount, remainingToRead)
                }
                if readCount > 0, let chunk = try fileHandle.read(upToCount: readCount), !chunk.isEmpty {
                    remainingToRead -= chunk.count
                    let chunkToEmit: IONFILEEncodingValueMapper
                    switch encoding {
                    case .byteBuffer: chunkToEmit = .byteBuffer(value: chunk)
                    case .string(let encoding):
                        guard let chunkText = String(data: chunk, encoding: encoding.stringEncoding) else {
                            throw IONFILEChunkPublisherError.cantEncodeData(usingEncoding: encoding)
                        }
                        chunkToEmit = .string(encoding: encoding, value: chunkText)
                    }

                    _ = subscriber.receive(chunkToEmit)
                } else {
                    complete(withValue: .finished)
                    break
                }
            } catch {
                complete(withValue: .failure(error))
                break
            }
        }
    }

    func cancel() {
        fileHandle?.closeFile()
    }

    deinit {
        fileHandle?.closeFile()
    }

    private func complete(withValue value: Subscribers.Completion<Error>) {
        isCompleted = true
        subscriber.receive(completion: value)
    }
}
