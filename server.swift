#!/usr/bin/swift sh

import Foundation
import Vapor // @vapor

let router = EngineRouter.default()
var services = Services.default()
services.register(router, as: Router.self)

var middlewares = MiddlewareConfig()
let currentDirectory = FileManager.default.currentDirectoryPath
let filemiddleware = FileMiddleware(publicDirectory: currentDirectory)
middlewares.use(filemiddleware)
services.register(middlewares)

services.register(NIOServerConfig.default(hostname: "0.0.0.0", port: 8000))

struct RequestInfo: Content {
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

func printRequestInfo(info: RequestInfo) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let requestInfoData = try? encoder.encode(info) else { return }
    guard let requestInfoString = String(data: requestInfoData, encoding: .utf8) else { return }
    print("\n\(info.method) request to \(info.path) from \(info.origin ?? "unknown")")
    print(requestInfoString)
}

func requestHandler(_ req: Request) throws -> RequestInfo {
    let path = req.http.urlString
    let headers = Dictionary(uniqueKeysWithValues:
        req.http.headers.compactMap { (String($0.name), String($0.value)) })
    let origin = req.http.remotePeer.hostname
    let method = req.http.method.string
    var requestData = RequestInfo(path: path, headers: headers, origin: origin, method: method)
    if method != "GET" {
        requestData.body = req.http.body.description
    }
    printRequestInfo(info: requestData)
    return requestData
}

router.get(use: requestHandler)
router.get(PathComponent.catchall, use: requestHandler)
router.post(use: requestHandler)
router.post(PathComponent.catchall, use: requestHandler)
router.delete(use: requestHandler)
router.delete(PathComponent.catchall, use: requestHandler)
router.put(use: requestHandler)
router.put(PathComponent.catchall, use: requestHandler)

let application = try Application(config: Config.default(), environment: Environment.detect(), services: services)

try application.run()
