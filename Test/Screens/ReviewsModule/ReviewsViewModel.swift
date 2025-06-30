import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?

    private var state: State
    private let networkService: NetworkService
    private let cashingServise: CashingServise
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        networkService: NetworkService = NetworkService(),
        cashingService: CashingServise = CashingServise(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.networkService = networkService
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
        self.cashingServise = cashingService
        super.init()
        
        setup()
    }
    
    private func setup() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            networkService.getReviews(offset: state.offset, completion: gotReviews)
        }
    }
}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: NetworkService.ResponseResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            do {
                let data = try result.get()
                let reviews = try decoder.decode(Reviews.self, from: data)
                state.items += reviews.items.map(makeReviewItem)
                
                state.offset += state.limit
                state.shouldLoad = true
                if state.offset >= reviews.count {
                    state.shouldLoad = false
                    state.items.append(makeCountItem(reviews))
                }
            } catch {
                state.shouldLoad = true
            }
            
            onStateChange?(state)
        }
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }
    
    /// Функция для склонения слова "отзывы" с различными числительными.
    func formatReviewsCount(_ count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 14 {
            return "\(count) отзывов"
        } else if remainder10 == 1 {
            return "\(count) отзыв"
        } else if remainder10 >= 2 && remainder10 <= 4 {
            return "\(count) отзыва"
        } else {
            return "\(count) отзывов"
        }
    }
    
    /// Метод для загрузки фотографии.
    func loadPhoto(url: String, completion: @escaping () -> Void) {
        DispatchQueue(label: "com.test.serial", attributes: .concurrent).async { [weak self] in
            self?.networkService.loadPhoto(url: url, completion: { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    guard
                        let data = (try? result.get()),
                        let name = url.components(separatedBy: "/").last
                    else { return completion() }
                    let image = UIImage(data: data)
                
                    self?.cashingServise.addImage(name: name, image: image)
                    completion()
                }
            })
        }
    }
    
    /// Получить изображение из кеша или перенаправить на его загрузку.
    /// Если нету картинки, то вместо нее blink image.
    func getImages(
        photoUrls: [String], allowsLoad: Bool = true,
        completion: (() -> Void)? = nil) -> [UIImage?] {
        var images: [UIImage?] = []
        let group = DispatchGroup()
        
        photoUrls.forEach { url in
            if let name = url.components(separatedBy: "/").last,
                let image = cashingServise.getImage(name: name) {
                images.append(image)
            } else {
                images.append(UIImage.blink)
                if allowsLoad {
                    group.enter()
                    loadPhoto(url: url) {
                        group.leave()
                    }
                }
            }
        }
            
        group.notify(queue: .main) {
            completion?()
        }
            
        return images
    }
    
    func reloadRowForCashedImages(id: UUID, photoUrls: [String]) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.images = getImages(photoUrls: photoUrls, allowsLoad: false)
        state.items[index] = item
        onStateChange?(state)
    }
}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig
    typealias CountItem = ReviewCountCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let id = UUID()
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let username = "\(review.firstName) \(review.lastName)".attributed(font: .username)
        let rating = ratingRenderer.ratingImage(review.rating)
        let avatar = UIImage(named: "l5w5aIHioYc")
        let images = getImages(photoUrls: review.photoUrls) { [weak self] in
            self?.reloadRowForCashedImages(id: id, photoUrls: review.photoUrls)
        }
        
        let item = ReviewItem(
            id: id,
            avatar: avatar,
            username: username,
            rating: rating,
            reviewText: reviewText,
            created: created,
            images: images) { [weak self] id in
                self?.showMoreReview(with: id)
            }
        
        return item
    }

    func makeCountItem(_ reviews: Reviews) -> CountItem {
        let string = formatReviewsCount(reviews.count)
        let countText = string.attributed(font: .reviewCount, color: .reviewCount)
        return CountItem(countText: countText)
    }
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
