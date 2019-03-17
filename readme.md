# server.swift

A simple server for testing HTTP requests powered by [Vapor](https://vapor.codes) and [swift sh](https://github.com/mxcl/swift-sh).

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
Server starting on http://localhost:8080
```


## Examples

**GET request:**

```console
curl "http://localhost:8080/get?foo=bar"
```

**server.swift response**

```JSON
{
  "path" : "\/get?foo=bar",
  "headers" : {
    "User-Agent" : "curl\/7.54.0",
    "Accept" : "*\/*",
    "Host" : "localhost:8080"
  },
  "origin" : "::1"
}
```

**POST request:**

```console
curl -X "POST" "http://localhost:8080/post" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d $'{
  "foo": "bar"
}'
```

**server.swift response**

```JSON
{
  "path" : "\/post",
  "body" : "{\n  \"foo\": \"bar\"\n}",
  "headers" : {
    "Content-Type" : "application\/json; charset=utf-8",
    "Host" : "localhost:8080",
    "Accept" : "*\/*",
    "Content-Length" : "18",
    "User-Agent" : "curl\/7.54.0"
  },
  "origin" : "::1"
}
```