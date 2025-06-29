import UIKit

final class PhotoCell: UICollectionViewCell {
    
    private let photoImageView = UIImageView()
    
    static let id = "photo_cell_id"
    private var image: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        photoImageView.frame = contentView.frame
    }
}

private extension PhotoCell {
    func setup() {
        setupImageView()
    }
    
    func setupImageView() {
        contentView.addSubview(photoImageView)
        photoImageView.backgroundColor = .clear
        photoImageView.layer.cornerRadius = 8.0
        photoImageView.layer.cornerCurve = .continuous
        photoImageView.clipsToBounds = true
        photoImageView.contentMode = .scaleAspectFill
    }
}


// MARK: Internal
extension PhotoCell {
    func set(image: UIImage?) {
        self.image = image
        photoImageView.image = self.image
    }
}
