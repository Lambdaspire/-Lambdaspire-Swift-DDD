
public protocol DomainEvent { }

public extension DomainEvent {
    static var typeIdentifier: String { .init(describing: Self.self) }
}
