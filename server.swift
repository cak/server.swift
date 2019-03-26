#!/usr/bin/swift sh

import Foundation
import NIOHTTP1 // apple/swift-nio -> 1.0.0
import NIO

class Server {
    let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    func run(host: String, port: Int) {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).then {
                    channel.pipeline.add(handler: requestHandler())
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

    final class requestHandler: ChannelInboundHandler {
        typealias InboundIn = HTTPServerRequestPart
        var requestData: RequestInfo?
        var requestHead: HTTPRequestHead?
        var requestBody: String = ""

        func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
            let req = unwrapInboundIn(data)

            switch req {
            case let .head(head):
                requestHead = head
                let headers = Dictionary(uniqueKeysWithValues:
                    head.headers.compactMap { (String($0.name), String($0.value)) })
                let path = head.uri
                let origin = ctx.remoteAddress?.description
                let method = "\(head.method)"

                requestData = RequestInfo(path: path, headers: headers, origin: origin, method: method)

            case let .body(bodyData):
                let dataString = bodyData.getString(at: bodyData.readerIndex, length: bodyData.readableBytes)
                requestBody += dataString ?? ""
            case .end:
                requestData?.body = requestBody

                let responseBody = printRequestInfo(info: requestData)
                var headers = HTTPHeaders()
                headers.add(name: "Server", value: "server.swift")
                headers.add(name: "content-type", value: "application/json; charset=utf-8")
                headers.add(name: "Content-Length", value: "\(responseBody.1)")
                if let originValue = requestHead?.headers["origin"].first {
                    headers.add(name: "access-control-allow-origin", value: originValue)
                    headers.add(name: "access-control-allow-headers", value: "accept, authorization, content-type, origin, x-requested-with")
                    headers.add(name: "access-control-allow-methods", value: "GET, POST, PUT, OPTIONS, DELETE, PATCH")
                    headers.add(name: "access-control-max-age", value: "600")
                }

                let head = HTTPResponseHead(version: requestHead!.version,
                                            status: .ok, headers: headers)
                let part = HTTPServerResponsePart.head(head)
                _ = ctx.channel.write(part)

                var buffer = ctx.channel.allocator.buffer(capacity: responseBody.1)
                buffer.write(string: responseBody.0)
                let bodypart = HTTPServerResponsePart.body(.byteBuffer(buffer))
                _ = ctx.channel.write(bodypart)
                _ = ctx.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).then {
                    ctx.channel.close()
                }
            }
        }
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
    print("\n\(info.method) request to \(info.path) from \(info.origin ?? "unknown")")
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
for i in 0 ..< args.count {
    let argument = args[i]
    switch argument {
    case "--hostname":
        hostname = (i + 1 < args.count) ? args[i + 1] : "0.0.0.0"
    case "--port":
        port = (i + 1 < args.count) ? Int(args[i + 1]) ?? 8000 : 8000
    default:
        break
    }
}

Server().run(host: hostname, port: port)
