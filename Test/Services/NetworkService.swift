import Foundation
import UIKit

/// Класс для загрузки отзывов.
final class NetworkService {

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

}

// MARK: - Internal

extension NetworkService {

    typealias ResponseResult = Result<Data, ResponseError>

    enum ResponseError: Error {
        case badURL
        case badData
    }
    
    enum EmptyError: Error {
        case e
    }

    func getReviews(offset: Int = 0, completion: @escaping (ResponseResult) -> Void) {
        guard let url = bundle.url(forResource: "getReviews.response", withExtension: "json") else {
            return completion(.failure(.badURL))
        }

        // Симулируем сетевой запрос - не менять
        usleep(.random(in: 100_000...1_000_000))

        do {
            let data = try Data(contentsOf: url)
            completion(.success(data))
        } catch {
            completion(.failure(.badData))
        }
    }
    
    /// Имитация загрузки фото из сети.
    func loadPhoto(url: String, completion: @escaping (ResponseResult) -> Void) {
        guard
            let named = url.components(separatedBy: "/").last,
            let image = UIImage(named: named)
        else { return completion(.failure(.badURL)) }
        
        // Симулируем сетевой запрос - не менять
        usleep(.random(in: 300_000...1_500_000))
        
        if let data = image.jpegData(compressionQuality: 1.0) {
            completion(.success(data))
        } else {
            completion(.failure(.badData))
        }
    }
}
