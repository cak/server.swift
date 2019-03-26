# server.swift

A simple server for testing HTTP requests powered by [SwiftNIO](https://github.com/apple/swift-nio) and [swift sh](https://github.com/mxcl/swift-sh).

## Usage

#### Install swift sh
```console
brew install mxcl/made/swift-sh
```

> More instructions for `swift sh` are available at [https://github.com/mxcl/swift-sh/](https://github.com/mxcl/swift-sh/).

#### Run server.swift
```console
swift sh <(curl -L https://github.com/cak/server.swift/raw/master/server.swift)
```

```console
Starting server.swift on [IPv4]0.0.0.0/0.0.0.0:8000
```

*Alternatively, you can clone the repository and run `‌swift sh server.swift`*

## Command Line Arguments
The hostname and port can be specified with `--hostname` and `--port`

```console
swift sh server.swift --hostname "localhost" --port 8080
```

```console
Starting server.swift on [IPv6]::1/::1:8080
```

## Examples

### GET request:

```console
curl -i "http://localhost:8000/get?foo=bar" \
     -H 'origin: https://serversideswift.dev'
```

**Console**

```console
GET request to /get?foo=bar from [IPv6]::1/::1:52978
{
  "path" : "\/get?foo=bar",
  "method" : "GET",
  "headers" : {
    "Accept" : "*\/*",
    "Host" : "localhost:8000",
    "origin" : "https:\/\/serversideswift.dev",
    "User-Agent" : "curl\/7.54.0"
  },
  "origin" : "[IPv6]::1\/::1:52978"
}
```

**HTTP Response**

```HTTP
HTTP/1.1 200 OK
Server: server.swift
content-type: application/json; charset=utf-8
Content-Length: 244
access-control-allow-origin: https://serversideswift.dev
access-control-allow-headers: accept, authorization, content-type, origin, x-requested-with
access-control-allow-methods: GET, POST, PUT, OPTIONS, DELETE, PATCH
access-control-max-age: 600

{
  "path" : "\/get?foo=bar",
  "method" : "GET",
  "headers" : {
    "Accept" : "*\/*",
    "Host" : "localhost:8000",
    "origin" : "https:\/\/serversideswift.dev",
    "User-Agent" : "curl\/7.54.0"
  },
  "origin" : "[IPv6]::1\/::1:52978"
}
```

### POST request:

```console
curl -X "POST" "http://localhost:8000/post" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "foo": "bar"
}'
```

**Console**

```console
POST request to /post from [IPv4]127.0.0.1/127.0.0.1:51299
{
  "path" : "\/post",
  "body" : "{\n  \"foo\": \"bar\"\n}",
  "method" : "POST",
  "headers" : {
    "Content-Type" : "application\/json; charset=utf-8",
    "Host" : "localhost:8000",
    "Accept" : "*\/*",
    "Content-Length" : "18",
    "User-Agent" : "curl\/7.54.0"
  },
  "origin" : "[IPv4]127.0.0.1\/127.0.0.1:51299"
}
```

**HTTP Response**

```HTTP
HTTP/1.1 200 OK
Server: server.swift
content-type: application/json; charset=utf-8
Content-Length: 365

{
  "path" : "\/post",
  "body" : "{\"foo\":\"bar\"}",
  "method" : "POST",
  "headers" : {
    "Content-Type" : "application\/json; charset=utf-8",
    "Host" : "localhost:8000",
    "Connection" : "close",
    "Content-Length" : "13",
    "User-Agent" : "Paw\/3.1.8 (Macintosh; OS X\/10.14.3) GCDHTTPRequest"
  },
  "origin" : "[IPv4]127.0.0.1\/127.0.0.1:51266"
}
```

## Contributing

Send a pull request or create an issue.
