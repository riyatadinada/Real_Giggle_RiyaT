import Foundation

/// Represents whether the current user is signing in / viewing the app
/// as a service provider or a service receiver.
/// Kept small and Codable so it can be persisted if needed.
public enum UserRole: String, Codable, CaseIterable, Hashable {
    case provider
    case receiver

    public var displayName: String {
        switch self {
        case .provider: return "Provider"
        case .receiver: return "Receiver"
        }
    }
}
