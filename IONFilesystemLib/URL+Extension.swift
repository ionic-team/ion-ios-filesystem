import Foundation

extension URL {
    public var urlPath: String {
        if #available(iOS 16.0, *) {
            path(percentEncoded: false)
        } else {
            path.removingPercentEncoding ?? path
        }
    }

    func urlWithAppendingPath(_ path: String) -> URL {
        if #available(iOS 16.0, *) {
            appending(path: path)
        } else {
            appendingPathComponent(path)
        }
    }
}
