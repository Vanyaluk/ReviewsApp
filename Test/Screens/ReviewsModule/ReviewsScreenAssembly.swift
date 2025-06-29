// Сборщик экрана отзывов

final class ReviewsScreenAssembly {

    /// Создаёт контроллер списка отзывов, проставляя нужные зависимости.
    func assemble() -> ReviewsViewController {
        let networkService = NetworkService()
        let viewModel = ReviewsViewModel(networkService: networkService)
        let controller = ReviewsViewController(viewModel: viewModel)
        return controller
    }
}
