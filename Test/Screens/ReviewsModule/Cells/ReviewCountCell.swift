import UIKit

struct ReviewCountCellConfig {
    
    /// Общее количество сообщений
    let countText: NSAttributedString
    
    /// размер экранов TableView
    var tableSize: CGSize = .zero
    
    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCountCellLayout()
}

extension ReviewCountCellConfig: TableCellConfig {
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCountCell else { return }
        cell.countTextLabel.attributedText = countText
        cell.config = self
    }
    
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
}


final class ReviewCountCell: UITableViewCell {
    fileprivate var config: Config?
    
    fileprivate var countTextLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        countTextLabel.frame = layout.countTextLabelFrame
    }
}

private extension ReviewCountCell {
    func setupCell() {
        setupCountLabel()
    }
    
    func setupCountLabel() {
        contentView.addSubview(countTextLabel)
        countTextLabel.textAlignment = .center
    }
}

// MARK: - Layout

private final class ReviewCountCellLayout {
    
    // MARK: Фреймы
    private(set) var countTextLabelFrame = CGRect.zero
    
    // MARK: Отступы
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    // MARK: Расчёт фреймов и высоты ячейки
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let textHeight = config.countText.font()?.lineHeight
        
        countTextLabelFrame = CGRect(
            origin: CGPoint(x: insets.left, y: insets.top),
            size: CGSize(
                width: maxWidth - insets.left - insets.right,
                height: textHeight ?? .zero
            )
        )
        
        return countTextLabelFrame.maxY + insets.bottom
    }
}

fileprivate typealias Config = ReviewCountCellConfig
