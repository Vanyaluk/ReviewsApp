import UIKit

final class RootViewController: UIViewController {

    private lazy var rootView = RootView(onTapReviews: openReviews)

    override func loadView() {
        view = rootView
    }
}

// MARK: - Private

private extension RootViewController {
    func openReviews() {
        let reviewsScreenAssembly = ReviewsScreenAssembly()
        let controller = reviewsScreenAssembly.assemble()
        navigationController?.pushViewController(controller, animated: true)
    }
}
