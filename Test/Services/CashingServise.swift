import UIKit

/// Класс для кэширования изображений.
final class CashingServise {
    
    private var cash: [String: UIImage?] = [:]
    
    init() {}
    
}

extension CashingServise {
    
    func getImage(name: String) -> UIImage? {
        if let image = cash[name] {
            return image
        }
        return nil
    }
    
    func addImage(name: String, image: UIImage?) {
        if !cash.keys.contains(name) {
            cash[name] = image
        }
    }
    
}
