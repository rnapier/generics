import Foundation

protocol IDType: Codable, Hashable {
    associatedtype Value
    var value: Value { get }
    init(value: Value)
}

extension IDType {
    init(_ value: Value) { self.init(value: value) }
}

struct User: Codable, Equatable {
    struct ID: IDType { let value: Int }
    let id: ID
    let name: String
}

struct Document: Codable, Equatable {
    struct ID: IDType { let value: String }
    let id: ID
    let title: String
}

let baseURL = URL(string: "https://www.example.org")!

protocol Fetchable: Decodable {
    static var apiBase: String { get }
    associatedtype ID: IDType
    var id: ID { get }
}

extension User: Fetchable {
    static var apiBase: String { return "user" }
}

extension Document: Fetchable {
    static var apiBase: String { return "document" }
}

protocol Transport {
    func fetch(request: URLRequest,
               completion: @escaping (Result<Data, Error>) -> Void)
}

class NetworkTransport: Transport {
    static let shared = NetworkTransport()
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }
    func fetch(request: URLRequest,
               completion: @escaping (Result<Data, Error>) -> Void)
    {
        session.dataTask(with: request) { (data, _, error) in
            if let error = error { completion(.failure(error)) }
            else if let data = data { completion(.success(data)) }
            }.resume()
    }
}

struct Client {
    let transport: Transport
    init(transport: Transport = NetworkTransport.shared) {
        self.transport = transport
    }

    // GET /<model>/<id> -> Model
    func fetch<Model: Fetchable>(
        _ model: Model.Type,
        id: Int,
        completion:
        @escaping (Result<Model, Error>) -> Void)
    {
        let urlRequest = URLRequest(url: baseURL
            .appendingPathComponent(Model.apiBase)
            .appendingPathComponent("\(id)")
        )

        transport.fetch(request: urlRequest) {
            data in
            completion(Result {
                let decoder = JSONDecoder()
                return try decoder.decode(
                    Model.self,
                    from: data.get())
            })
        }
    }

    // POST /keepalive -> Error?
    func keepAlive(
        completion: @escaping (Error?) -> Void)
    {
        var urlRequest = URLRequest(url: baseURL
            .appendingPathComponent("keepalive")
        )
        urlRequest.httpMethod = "POST"

        transport.fetch(request: urlRequest) {
            switch $0 {
            case .success: completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
}

struct Request {
    let urlRequest: URLRequest
    let completion: (Result<Data, Error>) -> Void
}

extension Request {

    // GET /<model>/<id> -> Model
    static func fetching<Model: Fetchable>(
        _: Model.Type,
        id: Model.ID,
        completion: @escaping (Result<Model, Error>) -> Void)
        -> Request
    {
        let urlRequest = URLRequest(url: baseURL
            .appendingPathComponent(Model.apiBase)
            .appendingPathComponent("\(id)")
        )

        return self.init(urlRequest: urlRequest) {
            data in
            completion(Result {
                let decoder = JSONDecoder()
                return try decoder.decode(
                    Model.self,
                    from: data.get())
            })
        }
    }
}

extension Request {

    // POST /keepalive -> Error?
    static func keepAlive(
        completion: @escaping (Error?) -> Void)
        -> Request
    {
        var urlRequest = URLRequest(url: baseURL
            .appendingPathComponent("keepalive")
        )
        urlRequest.httpMethod = "POST"

        return self.init(urlRequest: urlRequest) {
            switch $0 {
            case .success: completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
}

extension Client {
    func fetch(request: Request) {
        transport.fetch(request: request.urlRequest,
                        completion: request.completion)
    }
}

struct AddHeaders: Transport
{
    func fetch(request: URLRequest,
               completion: @escaping (Result<Data, Error>) -> Void)
    {
        var newRequest = request
        for (key, value) in headers {
            newRequest.addValue(value, forHTTPHeaderField: key)
        }
        base.fetch(request: newRequest, completion: completion)
    }

    let base: Transport
    var headers: [String: String]
}

let transport = AddHeaders(base: NetworkTransport.shared,
                           headers: ["Authorization": "..."])

let client = Client(transport: transport)

let request = Request.fetching(User.self,
                               id: User.ID(0),
                               completion: { print($0) })
client.fetch(request: request)
