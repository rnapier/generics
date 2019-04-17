protocol Request {
    var id: Int { get }
    associatedtype Response
    var completion: (Response) -> Void { get }
}

struct NameRequest: Request {
    let id: String
    let completion: (String) -> Void
}

struct AgeRequest: Request {
    let id: Int
    let completion: (Int) -> Void
}

let requests: [Request] = [
    NameRequest(id: 1, completion: { print($0.first ?? "none") }),
    AgeRequest(id: 2, completion: { print($0 + 12) })
]

func process<Req: Request>(request: Req) {
    let response: Req.Response = ... ???? ... What?
}


for request in requests {
    switch request {
    case .name(let id, value: String): ...
    case .age(let id, value: Int): ...
    }
}
