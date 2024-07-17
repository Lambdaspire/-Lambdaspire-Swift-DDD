# Lambdaspire Swift DDD

As with any architecturally unopinionated data access layer, SwiftData code is prone to many of the common pitfalls of undisciplined software development: Repetitive code in some monolithic "business layer", poorly contained side-effects, or (worse) business logic carelessly scattered about, offering no clarity on the domain it represents.

This package aims to provide lightweight but opinionated ways to manage your app's domain logic with concepts inspired by the principles of [Domain Driven Design](https://www.amazon.com.au/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215).

## What's Inside (so far)

The package is an ongoing work in progress that will likely never be "finished".

For now, the package provides a basic approach to performing a "Unit of Work" and mechanisms for raising and handling domain events within it.

### Unit of Work

A Unit of Work encompasses a body of activity executed against a given domain context. Upon completion of the work, domain events raised are handled and any necessary transaction management (committing upon success or rolling back upon failure) is performed.

The typical usage would be a `UnitOfWork` wrapping a SwiftData `ModelContext` (i.e. `UnitOfWork<ModelContext>`).

SwiftData Models that are changed, updated, or deleted during the work can raise domain events which will be handled before and/or after committing the changes to persistence.

### Domain Entities

A Domain Entity (in this package) is just an object capable of raising events and exposing those events to some domain context for collection.

The typical usage would be on a SwiftData `@Model`.

Domain Entities are most concisely created with the `@DomainEntity` macro.

```swift
@Model
@DomainEntity
class Customer {

    let uuid: UUID = UUID()

    var orders: [Order] = []

    // ... init ...

    func placeOrder(_ order: Order) {

        orders.append(order)

        raiseEvent(OrderPlaced(customerId: uuid, orderId: order.id))
    }
}
```

The `@DomainEntity` macro adds conformance to `HasDomainEvents` (which enables `raiseEvent`) and creates a `@Transient` array of `DomainEvent` for accumulation during a Unit of Work and collection at the end of it. The code could be written manually, but macro takes care of it and is more future-proof.

### Domain Events and Handlers

Domain events and their handlers allow you to manage the side effects of certain activities that occur within the domain. This may include cleanup tasks when a Model is deleted, scheduling notifications when a Model is created or updated, or (consensual) logging and analytics operations for all data changes.

In this package, there are two types of handlers:
- Pre-commit handlers, and
- Post-commit handlers

Domain events are described as simple structs conforming to `DomainEvent`.

```swift
struct OrderPlaced : DomainEvent {
    var customerId: UUID
    var orderId: UUID
}
```

Domain event handlers can be defined as structs conforming to `DomainEventHandler`.

```swift
struct OrderPlacedHandler : DomainEventHandler {
    static func handle(event: OrderPlaced, resolver: DependencyResolver) async throws {
        resolver
            .resolve(NotificationService.self)
            .notifyCustomer(
                customerId: event.customerId,
                message: "Your Order #\(event.orderId) is being processed.")
    }
}
```

The `handle` function accepts the specific type of `DomainEvent` in question and a `DependencyResolver` to resolve dependencies in a "service locator" fashion.

#### Pre-Commit Handlers

These execute before changes are persisted and will prevent the commission of the Unit of Work if they fail.

Use these for side-effects that are intra-domain, with implications on domain integrity.

Any `DomainEventHandler` is pre-commit by default.

#### Post-Commit Handlers

These execute after changes are persisted and fail gracefully, independently of each other. A failing post-commit handler will not rollback a Unit of Work.

Use these for side-effects that are extra-domain, perhaps with dependencies on external services / resources that may be unreliable.

A `DomainEventHandler` is post-commit if it overrides the default implementation of `static var isPostCommit: Bool { true }` to instead return `false`.

```swift
struct OrderPlacedHandler : DomainEventHandler {

    static let isPostCommit = true

    static func handle(event: OrderPlaced, resolver: DependencyResolver) async throws {
        // unchanged
    }
}
```

#### Multiple Handlers Supported

There can be many handlers for each type of event. The order of execution is not guaranteed, aside from pre-commit handlers preceding all post-commit handlers.

## How to use it

Here's a minimal, illustrative, non-compiling example of all the pieces, combined.

```swift
// Define the domain.
@Model
@DomainEntity
class Customer {

    let uuid: UUID = UUID()
    var orders: [Order] = []

    // ... init ...

    func placeOrder(_ order: Order) {
        orders.append(order)
        raiseEvent(OrderPlaced(customerId: uuid, orderId: order.uuid))
    }
}

@Model
class Order {
    let uuid: UUID = UUID()
    
    // ... init ...
}

struct OrderPlaced : DomainEvent {
    var customerId: UUID
    var orderId: UUID
}

// Define the event handlers.
struct OrderPlacedHandler : DomainEventHandler {

    static let isPostCommit = true

    static func handle(event: OrderPlaced, resolver: DependencyResolver) async throws {
        resolver
            .resolve(NotificationService.self)
            .notifyCustomer(
                customerId: event.customerId,
                message: "Your Order #\(event.orderId) is being processed.")
    }
}

// Define the services.
class NotificationService {
    func notifyCustomer(customerId: UUID, message: String) {
        print("Greetings, valued customer \(customerId).\n\n\(message)\n\nThank you.")
    }
}

func example() async throws {

    // 1. 
    // We'll need a DependencyResolver to connect arbitrary dependencies to the handlers.
    // Use ServiceLocator from LambdaspireDependencyResolution or create your own.
    // Register services / dependencies.
    let serviceLocator: ServiceLocator = .init()
    serviceLocator.register(NotificationService())

    // 2. 
    // The DomainEventHandlerRegistrar is the package's default implementation the 
    // DomainEventDelegator protocol which is responsible for marshalling events to their handlers
    // with dependency resolution capabilities.
    let registrar: DomainEventHandlerRegistrar = .init(resolver: serviceLocator)

    // 3. 
    // Register each handler.
    // In this example, only one.
    registrar.register(OrderPlacedHandler.self)

    // 4.
    // Create a UnitOfWork using the registrar as a delegator and a SwiftData ModelContext.
    // Assume modelContext is already established (perhaps via @Environment).
    let unitOfWork: UnitOfWork<ModelContext> = .init(delegator: registrar, context: modelContext)

    // 5. 
    // Perform domain activity.
    try await unitOfWork.execute { context in
        
        let customer = getCurrentlyAuthenticatedUserCustomerRecord(context)
        
        let pretendNewOrder: Order = .init()

        customer.placeOrder(pretendNewOrder)
    }
}

```

There is a more comprehensive example using SwiftUI in the appendix.

## The End

Found a bug? Got ideas? Put up a Pull Request. 🙏

## Appendix

### More about Domain Event Handlers

Pre-commit handlers fire after the `execute` body finishes and before `context.commit()` is called. If any pre-commit handlers fail, the entire unit of work is aborted and changes are rolled back with `context.rollback()`.

Post-commit handlers fire after a successful commit. Any post-commit handler can fail without disrupting the execution of other post-commit handlers.

### Logging

There is some light logging implemented using the static `Log` from `Lambdaspire-Swift-Abstractions`. To see the logs, make sure you set up the logger with something that implements `LambdaspireSwiftLogging.Logger`. You may find the [`Lambdaspire-Swift-Logging`](https://github.com/Lambdaspire/Lambdaspire-Swift-Logging) package helpful (though, at time of writing, it leaves much to be desired).

```swift
import LambdaspireAbstractions
import LambdaspireLogging

// Log to console.
Log.setLogger(PrintLogger())
```

### Complete, Working Code Example

```swift

import SwiftUI
import SwiftData
import LambdaspireLogging
import LambdaspireSwiftDDD
import LambdaspireAbstractions
import LambdaspireDependencyResolution

// MARK: Resolver and Delegator setup

// NOTE:
// It is not ideal to declare the resolver and delegator as global singletons.
// It is, however, convenient for this example.

let resolver: ServiceLocator = {
    let s: ServiceLocator = .init()
    s.register(Police())
    s.register(IT())
    s.register(HR())
    s.register(Legal())
    return s
}()

let delegator: DomainEventHandlerRegistrar = {
    let d: DomainEventHandlerRegistrar = .init(resolver: resolver)
    d.register(When_EmployeeWasFired_PrepareLegally.self)
    d.register(When_EmployeeWasFired_RevokeAllAccess.self)
    d.register(When_EmployeeWasFired_DestroyAllTheEvidence.self)
    d.register(When_EmployeeWasHired_PerformPoliceCheck.self)
    return d
}()

// MARK: App

@main
struct LambdaspireSwiftDDDExampleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Employee.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: View

struct ContentView: View {
    
    @State private var displayedError: DomainError?
    
    @Query private var employees: [Employee]
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(employees) { e in
                    NavigationLink {
                        Text(verbatim: e.name)
                    } label: {
                        LabeledContent(e.name, value: e.isFired ? "Fired" : "Employed")
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            fire(e)
                        } label: {
                            Text("Fire")
                        }
                        .tint(.red)
                    }
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
                ToolbarItem {
                    Button(action: addEmployee) {
                        Text("Recruit Random Person")
                    }
                }
            }
        } detail: {
            Text("Select an Employee")
        }
        .alert(
            isPresented: .init(
                get: { displayedError != nil },
                set: { if !$0 { displayedError = nil } }
            ),
            error: displayedError) { _ in
                Button("OK") { }
            } message: { e in
                Text(e.localizedDescription)
            }

    }
    
    var unitOfWork: UnitOfWork<ModelContext> {
        // HACK: ModelContext autosaves. This seems difficult to override in SwiftUI ModelContexts injected via @Environment.
        modelContext.autosaveEnabled = false
        return .init(delegator: delegator, context: modelContext)
    }

    private func addEmployee() {
        Task.detached {
            do {
                try await unitOfWork.execute { c in
                    let employee = Employee()
                    try employee.getHired()
                    c.insert(employee)
                }
            } catch let error as DomainError {
                displayedError = error
            } catch {
                // Uh oh.
            }
        }
    }

    private func fire(_ employee: Employee) {
        Task.detached {
            do {
                try await unitOfWork.execute { c in
                    try employee.getFired()
                }
            } catch let error as DomainError {
                displayedError = error
            } catch {
                // Uh oh.
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Employee.self, inMemory: true, isAutosaveEnabled: false)
}

// MARK: Domain

@Model
@DomainEntity
final class Employee {
    
    var uuid: UUID = UUID()
    var name: String = ""
    var isInducted: Bool = false
    var isFired: Bool = false
    
    init(uuid: UUID = .init(), name: String = names.randomElement()!, isInducted: Bool = false, isFired: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.isInducted = isInducted
        self.isFired = isFired
    }
    
    func getHired() throws {
        
        guard !isInducted else {
            throw DomainError("I've been here for a long time.")
        }
        
        isInducted = true
        
        raiseEvent(EmployeeWasHired(name: name))
    }
    
    func getFired() throws {
        
        guard !isFired else {
            throw DomainError("You can't fire me! I'm already fired!")
        }
        
        isFired = true
        
        raiseEvent(EmployeeWasFired(employeeId: uuid))
    }
}

struct EmployeeWasFired : DomainEvent {
    var employeeId: UUID
}

struct EmployeeWasHired : DomainEvent {
    var name: String
}

struct When_EmployeeWasHired_PerformPoliceCheck : DomainEventHandler {
    
    static func handle(event: EmployeeWasHired, resolver: any DependencyResolver) async throws {
        // As this is a pre-commit handler,
        // And the background check throws a DomainError if it fails,
        // A failure here will prevent the employee being persisted.
        try await resolver
            .resolve(Police.self)
            .backgroundCheck(name: event.name)
    }
}

struct When_EmployeeWasFired_RevokeAllAccess : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: EmployeeWasFired, resolver: any DependencyResolver) async throws {
        resolver
            .resolve(IT.self)
            .revokeAllAccess(employeeId: event.employeeId)
    }
}

struct When_EmployeeWasFired_DestroyAllTheEvidence : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: EmployeeWasFired, resolver: any DependencyResolver) async throws {
        resolver
            .resolve(HR.self)
            .destroyAllTheEvidence(employeeId: event.employeeId)
    }
}

struct When_EmployeeWasFired_PrepareLegally : DomainEventHandler {
    
    static var isPostCommit: Bool { true }
    
    static func handle(event: EmployeeWasFired, resolver: any DependencyResolver) async throws {
        resolver
            .resolve(Legal.self)
            .cya(employeeId: event.employeeId)
    }
}

class IT {
    func revokeAllAccess(employeeId: UUID) {
        print("sudo revoko accesso -f")
    }
}

class HR {
    func destroyAllTheEvidence(employeeId: UUID) {
        print("I'm sorry, IT must have accidentally deleted all your emails.")
    }
}

class Legal {
    func cya(employeeId: UUID) {
        print("The law isn't exacty black and white on this, so we should be fine.")
    }
}

class Police {
    func backgroundCheck(name: String) async throws {
        if Bool.random() {
            throw DomainError("\(name) is a wanted criminal who escaped from prison so we have rejected their application.")
        }
    }
}

struct DomainError : LocalizedError {
    
    private var message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var errorDescription: String? { message }
}


// MARK: Stuff

let names = [
    "Jim",
    "Jone",
    "Jackie",
    "John",
    "Jane",
    "Jill",
    "Julian",
    "Jules",
    "Jen",
    "Jasper",
    "Jacko",
    "Jerry"
]

```
