
import Foundation

// This is pure dirt.
class Hooks {
    
    var hooks: [String : () -> Void] = [:]
    
    func use(_ key: String) {
        hooks[key]!()
    }
    
    func hook(_ key: String, fn: @escaping () -> Void) {
        hooks[key] = fn
    }
    
    func hook(fn: @escaping () -> Void) -> String {
        let key: String = UUID().uuidString
        hook(key, fn: fn)
        return key
    }
    
    func unhook(key: String) {
        hooks.removeValue(forKey: key)
    }
    
    func clear() {
        hooks.removeAll()
    }
}

class Boxed<T> {
    var value: T
    
    init(initialValue: T) {
        value = initialValue
    }
}

extension Hooks {
    
    func hook<T>(_ key: String, value: T, fn: @escaping (inout T) -> Void) -> Boxed<T> {
        
        let b: Boxed<T> = .init(initialValue: value)
        
        hook(key) { fn(&b.value) }
        
        return b
    }
}
