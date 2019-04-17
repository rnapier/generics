//import Foundation
//
//protocol IDType: Codable, Hashable {
//    associatedtype Value
//    var value: Value { get }
//    init(value: Value)
//}
//
//extension IDType {
//    init(_ value: Value) { self.init(value: value) }
//}
//
//struct User: Codable, Equatable {
//    struct ID: IDType { let value: Int }
//    let id: ID
//    let name: String
//}
//
//struct Document: Codable, Equatable {
//    struct ID: IDType { let value: String }
//    let id: ID
//    let title: String
//}
//
//protocol Fetchable: Decodable {
//    static var apiBase: String { get }
//    associatedtype ID
//    var id: ID { get }
//}
//
//protocol Cacheable: Fetchable {
//    static var cache: [Self.ID: Self] { get set }
//}
//
//var userCache: [User.ID: User] = [:]
//extension User: Fetchable {
//    static var cache: [User.ID: User] {
//        get { return userCache }
//        set { userCache = newValue }
//    }
//    static var apiBase: String { return "user" }
//}
//
//var documentCache: [Document.ID: Document] = [:]
//extension Document: Fetchable {
//    static var cache: [Document.ID: Document] {
//        get { return documentCache }
//        set { documentCache = newValue }
//    }
//    static var apiBase: String { return "document" }
//}
//
//let baseURL = URL(string: "https://www.example.org")!
//
//protocol Transport {
//    func fetch(request: URLRequest,
//               completion: @escaping (Result<Data, Error>) -> Void)
//}
//
//class NetworkTransport: Transport {
//    static let shared = NetworkTransport()
//    let session: URLSession
//    init(session: URLSession = .shared) { self.session = session }
//    func fetch(request: URLRequest,
//               completion: @escaping (Result<Data, Error>) -> Void)
//    {
//        session.dataTask(with: request) { (data, _, error) in
//            if let error = error { completion(.failure(error)) }
//            else if let data = data { completion(.success(data)) }
//            }.resume()
//    }
//}
//
//func fetch<Model: Cacheable>(
//    _ model: Model.Type,
//    id: Int,
//    with transport: Transport = NetworkTransport.shared,
//    completion: @escaping (Result<Model, Error>) -> Void)
//{
//    if let model = Model.cache[id] {
//        completion(.success(model))
//    }
//
//    let urlRequest = URLRequest(url: baseURL
//        .appendingPathComponent(Model.apiBase)
//        .appendingPathComponent("\(id)")
//    )
//
//    transport.fetch(request: urlRequest) { data in
//        completion(Result {
//            let decoder = JSONDecoder()
//            let model = try decoder.decode(Model.self,
//                                           from: data.get())
//            Model.cache[id] = model
//            return model
//        })
//    }
//}
//
//struct CacheRefresh {
//    var perform: () -> Void
//    init<Model: Fetchable>(id: Model.ID) {
//
//    }
//}
//
//fetch(User.self, id: 0) { print($0) }
////fetch(Document.self, id: "x") { print($0) }
//1
//
//func updateCache<Model: Fetchable>(with id: Model) {}
