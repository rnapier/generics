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
}

extension Client {
    func fetch<Model: Fetchable>(
        _ model: Model.Type,
        id: Model.ID,
        with transport: Transport = NetworkTransport.shared,
        completion: @escaping (Result<Model, Error>) -> Void)
    {
        let urlRequest = URLRequest(url: baseURL
            .appendingPathComponent(Model.apiBase)
            .appendingPathComponent("\(id.value)")
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

//fetch(User.self, id: User.ID(0), with: NetworkTransport.shared) { print($0) }

//protocol IDType: Codable, Hashable {
//    associatedtype Model
//    associatedtype Value
//    var value: Value { get }
//    init(value: Value)
//}

//let refreshIDs: [IDType] = [User.ID(4),
//                            Document.ID("budget")]
//
//let modelTypeForID = [
//    User.ID.self: User.self,
//    Document.ID.self: Document.self,
//]

//for id in refreshIDs {
//    guard let model = modelTypeForID[id] else { continue }
//    refresh(id.modelType, id: id)
//}
//

func refresh<Model: Fetchable>(_: Model.Type, id: Model.ID) {}

struct RefreshRequests {
    let perform: () -> Void
}

extension RefreshRequests {
    init(userID: User.ID) {
        self.init(perform: { refresh(User.self, id: userID) })
    }

    init(documentID: Document.ID) {
        self.init(perform: { refresh(Document.self, id: documentID) })
    }
}

let refreshes = [
    RefreshRequests(userID: User.ID(4)),
    RefreshRequests(documentID: Document.ID("budget")),
]

for refresh in refreshes {
    refresh.perform()
}

//let ids: [IDType] = [
//    User.ID(1),
//    Document.ID("budget")
//]
//
//for id in ids {
//    fetch(id.TypeIDRefersTo, id: id.value) { ... }
//}
