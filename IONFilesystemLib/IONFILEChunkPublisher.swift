import Combine
import Foundation

public class IONFILEChunkPublisher: Publisher {
    public typealias Output = IONFILEEncodingValueMapper
    public typealias Failure = Error

    private let url: URL
    private let chunkSize: Int
    private let encoding: IONFILEEncoding

    init(_ url: URL, _ chunkSize: Int, _ encoding: IONFILEEncoding) {
        self.url = url
        self.chunkSize = chunkSize
        self.encoding = encoding
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = IONFILEChunkSubscription(url, chunkSize, encoding, subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private class IONFILEChunkSubscription<S: Subscriber>: Subscription where S.Input == IONFILEEncodingValueMapper, S.Failure == Error {
    private let fileHandle: FileHandle?
    private let chunkSize: Int
    private let encoding: IONFILEEncoding
    private let subscriber: S
    private var isCompleted = false

    init(_ url: URL, _ chunkSize: Int, _ encoding: IONFILEEncoding, _ subscriber: S) {
        self.fileHandle = try? FileHandle(forReadingFrom: url)
        self.chunkSize = chunkSize
        self.encoding = encoding
        self.subscriber = subscriber
    }

    func request(_ demand: Subscribers.Demand) {
        guard let fileHandle = fileHandle, !isCompleted else {
            return subscriber.receive(completion: .failure(IONFILEChunkPublisherError.notAbleToReadFile))
        }

        while demand > .none {
            do {
                if let chunk = try fileHandle.read(upToCount: chunkSize), !chunk.isEmpty {
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
