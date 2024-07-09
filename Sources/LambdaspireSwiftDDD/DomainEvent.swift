
protocol DomainEvent { }

extension DomainEvent {
    static var typeIdentifier: String { .init(describing: Self.self) }
}
