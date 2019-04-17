import Foundation

struct User: Codable, Equatable {
    let id: Int
    let name: String
}

struct Document: Codable, Equatable {
    let id: Int
    let title: String
}

let baseURL = URL(string: "https://www.example.org")!

struct Client {
    let transport: Transport
    init(transport: Transport = NetworkTransport.shared) {
        self.transport = transport
    }
}

extension Client {
    func fetchUser(id: Int,
                   completion:
        @escaping (Result<User, Error>) -> Void)
    {
        let urlRequest = URLRequest(url: baseURL
            .appendingPathComponent("user")
            .appendingPathComponent("\(id)")
        )

        let session = URLSession.shared

        session.dataTask(with: urlRequest) {
            (data, _, error) in
            if let error = error {
                completion(.failure(error))
            }
            else if let data = data {
                let decoder = JSONDecoder()
                completion(Result {
                    try decoder.decode(User.self,
                                       from: data)
                })
            }
            }.resume()
    }

    func fetchDocument(id: Int,
                       completion:
        @escaping (Result<Document, Error>) -> Void)
    {
        let urlRequest = URLRequest(url: baseURL
            .appendingPathComponent("document")
            .appendingPathComponent("\(id)")
        )

        let session = URLSession.shared

        session.dataTask(with: urlRequest) {
            (data, _, error) in
            if let error = error {
                completion(.failure(error))
            }
            else if let data = data {
                let decoder = JSONDecoder()
                completion(Result {
                    try decoder.decode(Document.self,
                                       from: data)
                })
            }
            }.resume()
    }
}

protocol Fetchable: Decodable {
    static var apiBase: String { get }
}

extension User: Fetchable {
    static var apiBase: String { return "user" }
}

extension Document: Fetchable {
    static var apiBase: String { return "document" }
}

//func fetch<Model: Fetchable>(_ model: Model.Type,
//                             id: Int,
//                             completion:
//    @escaping (Result<Model, Error>) -> Void)
//{
//    let urlRequest = URLRequest(url: baseURL
//        .appendingPathComponent(Model.apiBase)
//        .appendingPathComponent("\(id)")
//    )
//
//    let session = URLSession.shared
//
//    session.dataTask(with: urlRequest) {
//        (data, _, error) in
//        if let error = error {
//            completion(.failure(error))
//        }
//        else if let data = data {
//            let decoder = JSONDecoder()
//            completion(Result {
//                try decoder.decode(Model.self,
//                                   from: data)
//            })
//        }
//        }.resume()
//}

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
//extension URLSession: Transport {
//    func fetch(request: URLRequest,
//               completion: @escaping (Result<Data, Error>) -> Void)
//    {
//        self.dataTask(with: request) { (data, _, error) in
//            if let error = error { completion(.failure(error)) }
//            else if let data = data { completion(.success(data)) }
//            }.resume()
//    }
//}

extension Client {
    func fetch<Model: Fetchable>(
        _: Model.Type,
        id: Int,
        completion: @escaping (Result<Model, Error>) -> Void)
    {
        let urlRequest = URLRequest(url: baseURL
            .appendingPathComponent(Model.apiBase)
            .appendingPathComponent("\(id)")
        )

        transport.fetch(request: urlRequest) { data in
            completion(Result {
                let decoder = JSONDecoder()
                return try decoder.decode(Model.self,
                                          from: data.get())
            })
        }
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
    }

    let base: Transport
    var headers: [String: String]
}

let transport = AddHeaders(base: NetworkTransport.shared,
                           headers: ["Authorization": "..."])

let client = Client(transport: transport)
client.fetch(User.self, id: 0) { print($0) }
1

