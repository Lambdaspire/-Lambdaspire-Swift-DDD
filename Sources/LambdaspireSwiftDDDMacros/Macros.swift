
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

enum DomainEntityMacroUsageError : String, DiagnosticMessage {
    
    case notClass = "Only classes can be Domain Entities."
    
    var message: String { rawValue }
    
    var diagnosticID: MessageID { .init(domain: "LambdaspireSwiftDDD", id: rawValue) } // TODO: What should this be?
    
    var severity: DiagnosticSeverity { .error }
}

public struct DomainEntityMacro : MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
            guard declaration.is(ClassDeclSyntax.self) else {
                context.diagnose(.init(
                    node: node,
                    message: DomainEntityMacroUsageError.notClass))
                return []
            }
            
            let decl: DeclSyntax =
            // TODO: I would prefer this be refactor-friendly.
            """
            extension \(type.trimmed) : HasDomainEvents { }
            """
            
            guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else { return [] }
            
            return [
                extensionDecl
            ]
        }
    
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext) throws -> [DeclSyntax] {
            
            guard declaration.is(ClassDeclSyntax.self) else {
                context.diagnose(.init(
                    node: node,
                    message: DomainEntityMacroUsageError.notClass))
                return []
            }
            
            return [
                // TODO: I would prefer this be refactor-friendly.
                "@Transient var events: [any DomainEvent] = []"
            ]
        }
}

@main
struct LambdaspireSwiftDDDMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DomainEntityMacro.self
    ]
}
