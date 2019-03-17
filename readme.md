# server.swift

A simple server for serving static files and testing HTTP requests powered by [Vapor](https://vapor.codes) and [swift sh](https://github.com/mxcl/swift-sh).

## Usage

#### Install swift sh
```console
brew install mxcl/made/swift-sh
```

> More instructions for `swift sh` are available at [https://github.com/mxcl/swift-sh/](https://github.com/mxcl/swift-sh/).

#### Run server.swift
```console
$ swift sh server.swift
```

```console
Server starting on http://0.0.0.0:8000
```

## Serving Static Files
servers.swift will serve all files in the current working directory. 

## Examples

### GET request:

```console
curl -I "http://localhost:8000/get?foo=bar"
```

**server.swift console**

```console
GET request to /get?foo=bar from 127.0.0.1
{
  "path" : "\/get?foo=bar",
  "method" : "GET",
  "headers" : {
    "Accept" : "*\/*",
    "Host" : "localhost:8000",
    "User-Agent" : "curl\/7.54.0"
  },
  "origin" : "127.0.0.1"
}
```

**server.swift HTTP response**

```HTTP
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8
content-length: 140
date: Sun, 17 Mar 2019 14:50:40 GMT
Connection: keep-alive

{"path":"\/get?foo=bar","method":"GET","headers":{"Accept":"*\/*","Host":"localhost:8000","User-Agent":"curl\/7.54.0"},"origin":"127.0.0.1"}
```

### POST request:

```console
curl -I -X "POST" "http://localhost:8000/post" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "foo": "bar"
}'
```

**server.swift console**

```console
POST request to /post from 127.0.0.1
{
  "path" : "\/post",
  "body" : "{\n  \"foo\": \"bar\"\n}",
  "method" : "POST",
  "headers" : {
    "Content-Length" : "18",
    "Host" : "localhost:8000",
    "User-Agent" : "curl\/7.54.0",
    "Content-Type" : "application\/json; charset=utf-8",
    "Accept" : "*\/*"
  },
  "origin" : "127.0.0.1"
}
```

**server.swift HTTP response**

```HTTP
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8
content-length: 240
date: Sun, 17 Mar 2019 14:52:24 GMT
Connection: keep-alive

{"path":"\/post","body":"{\n  \"foo\": \"bar\"\n}","method":"POST","headers":{"Content-Length":"18","Host":"localhost:8000","User-Agent":"curl\/7.54.0","Content-Type":"application\/json; charset=utf-8","Accept":"*\/*"},"origin":"127.0.0.1"}
```

## Contributing

Send a pull request, create an issue or discuss with me on the Vapor discord.

## Powered By

Powered by [Vapor](https://vapor.codes) and [swift sh](https://github.com/mxcl/swift-sh), please consider backing Vapor at [https://opencollective.com/vapor](https://opencollective.com/vapor) and becoming a patron of Max Howell at [https://www.patreon.com/mxcl](https://www.patreon.com/mxcl).