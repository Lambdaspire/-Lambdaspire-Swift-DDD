
// TODO: Can macros help with the repetition?

public protocol HasDomainEvents {
    var events: [any DomainEvent] { get set }
}

extension HasDomainEvents {
    
    public mutating func clearEvents() {
        events = []
    }
    
    public mutating func raiseEvent<T: DomainEvent>(_ event: T) {
        events.append(event)
    }
}
