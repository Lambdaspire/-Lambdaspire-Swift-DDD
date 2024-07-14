
@attached(member, names: named(events))
@attached(extension, conformances: HasDomainEvents)
public macro DomainEntity() = #externalMacro(module: "LambdaspireSwiftDDDMacros", type: "DomainEntityMacro")
