import Combine
import Foundation

public class OSFILEChunkPublisher: Publisher {
    public typealias Output = String
    public typealias Failure = Error

    private let url: URL
    private let chunkSize: Int
    private let encoding: OSFILEEncoding

    init(_ url: URL, _ chunkSize: Int, _ encoding: OSFILEEncoding) {
        self.url = url
        self.chunkSize = chunkSize
        self.encoding = encoding
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = OSFILEChunkSubscription(url, chunkSize, encoding, subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private class OSFILEChunkSubscription<S: Subscriber>: Subscription where S.Input == String, S.Failure == Error {
    private let fileHandle: FileHandle?
    private let chunkSize: Int
    private let encoding: OSFILEEncoding
    private let subscriber: S
    private var isCompleted = false

    init(_ url: URL, _ chunkSize: Int, _ encoding: OSFILEEncoding, _ subscriber: S) {
        self.fileHandle = try? FileHandle(forReadingFrom: url)
        self.chunkSize = Self.chunkSizeToUse(basedOn: chunkSize, and: encoding)
        self.encoding = encoding
        self.subscriber = subscriber
    }

    func request(_ demand: Subscribers.Demand) {
        guard let fileHandle = fileHandle, !isCompleted else {
            return subscriber.receive(completion: .failure(OSFILEChunkPublisherError.notAbleToReadFile))
        }

        while demand > .none {
            do {
                if let chunk = try fileHandle.read(upToCount: chunkSize), !chunk.isEmpty {
                    let chunkToEmit: String
                    switch encoding {
                    case .byteBuffer: chunkToEmit = chunk.base64EncodedString()
                    case .string(let encoding):
                        guard let chunkText = String(data: chunk, encoding: encoding.stringEncoding) else {
                            throw OSFILEChunkPublisherError.cantEncodeData
                        }
                        chunkToEmit = chunkText
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
}

private extension OSFILEChunkSubscription {
    static func chunkSizeToUse(basedOn chunkSize: Int, and encoding: OSFILEEncoding) -> Int {
        encoding == .byteBuffer ? chunkSize - chunkSize % 3 + 3 : chunkSize
    }

    func complete(withValue value: Subscribers.Completion<Error>) {
        isCompleted = true
        subscriber.receive(completion: value)
    }
}
