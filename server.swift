#!/usr/bin/swift sh

import Foundation
import Vapor // @vapor

let router = EngineRouter.default()
var services = Services.default()
services.register(router, as: Router.self)

struct RequestInfo: Content {
    let path: String
    let headers: [String: String]
    var body: String?
    let origin: String?

    init(path: String, headers: [String: String], body: String? = nil, origin: String?) {
        self.path = path
        self.headers = headers
        self.body = body
        self.origin = origin
    }
}

func printRequestInfo(info: RequestInfo) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let requestInfoData = try? encoder.encode(info) else { return }
    guard let requestInfoString = String(data: requestInfoData, encoding: .utf8) else { return }
    print(requestInfoString)
}

func request(_ req: Request) throws -> RequestInfo {
    let path = req.http.urlString
    let headers = Dictionary(uniqueKeysWithValues:
        req.http.headers.compactMap { (String($0.name), String($0.value)) })
    let origin = req.http.remotePeer.hostname
    var request = RequestInfo(path: path, headers: headers, origin: origin)
    if req.http.method.string != "GET" {
        request.body = req.http.body.description
    }
    printRequestInfo(info: request)
    return request
}

router.get("/", use: request)
router.get(PathComponent.catchall, use: request)
router.post("/", use: request)
router.post(PathComponent.catchall, use: request)
router.delete("/", use: request)
router.delete(PathComponent.catchall, use: request)
router.put("/", use: request)
router.put(PathComponent.catchall, use: request)

let application = try Application(config: Config.default(), environment: Environment.detect(), services: services)

try application.run()
