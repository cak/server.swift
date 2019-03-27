#!/usr/bin/swift sh

import Foundation
import NIO
import NIOHTTP1 // apple/swift-nio -> 2.0.0

class Server {
    func run(host: String, port: Int) {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                    channel.pipeline.addHandler(RequestHandler())
                }
            }

        do {
            let channel =
                try bootstrap.bind(host: host, port: port)
                .wait()
            print("Starting server.swift on \(channel.localAddress!)")

            try channel.closeFuture.wait()
        } catch {
            fatalError("server.swift failed to start: \(error)")
        }
    }

    final class RequestHandler: ChannelInboundHandler {
        typealias InboundIn = HTTPServerRequestPart
        var requestHead: HTTPRequestHead?
        var requestData: RequestInfo?
        var requestBodyBuffer: ByteBuffer?

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let req = unwrapInboundIn(data)

            switch req {
            case let .head(head):
                requestHead = head
                let headers = Dictionary(uniqueKeysWithValues:
                    head.headers.compactMap { (String($0.name), String($0.value)) })
                let path = head.uri
                let origin = context.remoteAddress?.description
                let method = "\(head.method)"
                requestData = RequestInfo(path: path, headers: headers, origin: origin, method: method)
                requestBodyBuffer = context.channel.allocator.buffer(capacity: 0)
            case var .body(buffer: bodyBuffer):
                requestBodyBuffer?.writeBuffer(&bodyBuffer)
            case .end:
                if let bufferString = bufferToString(requestBodyBuffer) {
                    requestData?.body = bufferString
                }

                let responseBody = printRequestInfo(info: requestData)
                var headers = HTTPHeaders()
                addHeaders(headers: &headers, reqHeaders: requestHead?.headers, responseLength: responseBody.1)
                let head = HTTPResponseHead(version: requestHead!.version,
                                            status: .ok, headers: headers)
                let headpart = HTTPServerResponsePart.head(head)
                context.channel.write(headpart)
                var buffer = context.channel.allocator.buffer(capacity: responseBody.1)
                buffer.writeString(responseBody.0)
                let bodypart = HTTPServerResponsePart.body(.byteBuffer(buffer))
                context.channel.write(bodypart, promise: nil)
                context.flush()
            }

            func channelReadComplete(context: ChannelHandlerContext) {
                context.flush()
            }

            func errorCaught(context: ChannelHandlerContext, error: Error) {
                print("Server Error: \(error.localizedDescription)")
                context.close(promise: nil)
            }
        }
    }
}

func bufferToString(_ buffer: ByteBuffer?) -> String? {
    guard let buf = buffer else { return nil }
    guard let bufferString = buf.getString(at: buf.readerIndex,
                                           length: buf.readableBytes) else { return nil }
    if bufferString.count > 0 {
        return bufferString
    }
    return nil
}

func addHeaders(headers: inout HTTPHeaders,
                reqHeaders: HTTPHeaders?,
                responseLength: Int) {
    headers.add(name: "Server", value: "server.swift")
    headers.add(name: "content-type", value: "application/json; charset=utf-8")
    headers.add(name: "Content-Length", value: "\(responseLength)")
    if let origin = reqHeaders?["origin"].first {
        headers.add(name: "access-control-allow-origin", value: origin)
        headers.add(name: "access-control-allow-headers",
                    value: "accept, authorization, content-type, origin, x-requested-with")
        headers.add(name: "access-control-allow-methods",
                    value: "GET, POST, PUT, OPTIONS, DELETE, PATCH")
        headers.add(name: "access-control-max-age", value: "600")
    }
}

func printRequestInfo(info: RequestInfo?) -> (String, Int) {
    guard let info = info else { return (string: "Empty", data: 0) }
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let requestInfoData = try? encoder.encode(info) else {
        return (string: "Empty", data: 0)
    }
    guard let requestInfoString = String(data: requestInfoData, encoding: .utf8) else {
        return (string: "Empty", data: 0)
    }
    print("\n\(info.method) request to \(info.path) from \(info.origin ?? "UNKNOWN")")
    print(requestInfoString)
    return (requestInfoString, requestInfoData.count)
}

struct RequestInfo: Codable {
    let path: String
    let headers: [String: String]
    var body: String?
    let origin: String?
    let method: String

    init(path: String,
         headers: [String: String],
         body: String? = nil,
         origin: String?,
         method: String) {
        self.path = path
        self.headers = headers
        self.body = body
        self.origin = origin
        self.method = method
    }
}

var hostname = "0.0.0.0"
var port = 8000

let args = CommandLine.arguments
for index in 0 ..< args.count {
    let argument = args[index]
    switch argument {
    case "--hostname":
        hostname = (index + 1 < args.count) ? args[index + 1] : "0.0.0.0"
    case "--port":
        port = (index + 1 < args.count) ? Int(args[index + 1]) ?? 8000 : 8000
    default:
        break
    }
}

Server().run(host: hostname, port: port)
