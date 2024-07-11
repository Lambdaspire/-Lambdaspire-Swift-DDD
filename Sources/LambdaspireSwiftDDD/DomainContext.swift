
public protocol DomainContext {
    
    func commit() async throws
    
    func rollback() async throws
    
    func collectEventRaisers() async throws -> [any HasDomainEvents]
}
