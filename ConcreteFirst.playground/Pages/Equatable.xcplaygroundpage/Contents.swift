protocol Document {
    var path: String { get set }
    func isEqual(to: Document) -> Bool
}

extension Document where Self: Equatable {
    func isEqual(to other: Document) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

struct TextDocument: Equatable, Document {
    var path: String
    var contents: String
}

struct Spreadsheet: Equatable, Document {
    var path: String
    var cells: [String: String]
}


let passwd = TextDocument(path: "/etc/passwd",
                          contents: "...")

let budget = Spreadsheet(path: "~/Documents/budget",
                         cells: ["A1": "-$46.00"])

let docs: [Document] = [passwd, budget]

extension Sequence where Element == Document {
    func contains(_ element: Element) -> Bool {
        return contains(where: { $0.isEqual(to: element) })
    }
}
docs.contains(passwd)

