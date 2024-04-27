import Foundation

public enum AppScope: String {
    case root
    case libs
    
    public var folder: String {
        rawValue.capitalizingFirstLetter
    }
}
