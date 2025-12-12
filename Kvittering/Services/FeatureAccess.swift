import Foundation
import Observation

protocol FeatureAccessing {
    func isFeatureEnabled(_ feature: Feature) -> Bool
}

enum Feature: CaseIterable {
    case scanning
    case photoImport
    case manualEntry
    case sharing
    case localStorage
}

@Observable
final class LocalFeatureAccess: FeatureAccessing {
    func isFeatureEnabled(_ feature: Feature) -> Bool { true }
}
