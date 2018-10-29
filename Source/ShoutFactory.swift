import UIKit
import OpenSans

let shoutView = ShoutView()

open class ShoutView: UIView {
    
    public struct Dimensions {
        public static let indicatorHeight: CGFloat = 6
        public static let indicatorWidth: CGFloat = 50
        public static let imageSize: CGFloat = 48
        public static let imageOffset: CGFloat = 18
        public static var textOffset: CGFloat = 18
        public static var touchOffset: CGFloat = 40
        public static var margin: CGFloat = 12
    }
    
    private enum NotificationBarType {
        case singleButton
        case doubleButton
    }
    
    private var barType: NotificationBarType = .singleButton {
        didSet {
            switch barType {
            case .singleButton:
                gotItButton.isHidden = false
                laterButton.isHidden = true
                confirmButton.isHidden = true
            case .doubleButton:
                gotItButton.isHidden = true
                laterButton.isHidden = false
                confirmButton.isHidden = false
            }
        }
    }
    
    open fileprivate(set) lazy var shadowView: UIView = {
        let view = UIView()
        view.layer.shadowOffset = CGSize(width: 0, height: 7)
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.32).cgColor
        view.layer.shadowRadius = 16
        view.backgroundColor = UIColor.white
        view.layer.shadowOpacity = 0.6
        return view
    }()
    
    open fileprivate(set) lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorList.Shout.background
        view.clipsToBounds = true
        view.layer.cornerRadius = 6
        
        return view
    }()
    
    open fileprivate(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = Dimensions.imageSize / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    open fileprivate(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.openSansFont(ofSize: 14)
        label.textColor = ColorList.Shout.title
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        
        return label
    }()
    
    open fileprivate(set) lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        return view
    }()
    
    open fileprivate(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.openSansFont(ofSize: 14)
        label.textColor = ColorList.Shout.subtitle
        label.numberOfLines = 2
        
        return label
    }()
    
    open fileprivate(set) lazy var gotItButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("OK", for: .normal)
        btn.backgroundColor = UIColor.init(red: 251/255, green: 52/255, blue: 73/255, alpha: 1)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.openSansFont(ofSize: 14)
        btn.layer.cornerRadius = 2
        btn.addTarget(self, action: #selector(silent), for: .touchUpInside)
        return btn
    }()
    
    open fileprivate(set) lazy var laterButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Later", for: .normal)
        let titleColor = UIColor.init(red: 251/255, green: 52/255, blue: 73/255, alpha: 1)
        btn.setTitleColor(titleColor, for: .normal)
        btn.titleLabel?.font = UIFont.openSansFont(ofSize: 14)
        btn.backgroundColor = UIColor.white
        btn.layer.cornerRadius = 2
        btn.layer.borderColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        btn.layer.borderWidth = 1
        btn.addTarget(self, action: #selector(silent), for: .touchUpInside)
        return btn
    }()
    
    open fileprivate(set) lazy var confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Confirm", for: .normal)
        btn.backgroundColor = UIColor.init(red: 251/255, green: 52/255, blue: 73/255, alpha: 1)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.openSansFont(ofSize: 14)
        btn.layer.cornerRadius = 2
        btn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return btn
    }()
    
    open fileprivate(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(ShoutView.handleTapGestureRecognizer))
        
        return gesture
        }()
    
    open fileprivate(set) var announcement: Announcement?
    open fileprivate(set) var displayTimer = Timer()
    open fileprivate(set) var panGestureActive = false
    open fileprivate(set) var shouldSilent = false
    open fileprivate(set) var completion: (() -> ())?
    
    private var subtitleLabelOriginalHeight: CGFloat = 0
    
    // MARK: - Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(shadowView)
        addSubview(backgroundView)
        [imageView, titleLabel, subtitleLabel].forEach {
            $0.autoresizingMask = []
            backgroundView.addSubview($0)
        }
        backgroundView.addSubview(separator)
        backgroundView.addSubview(gotItButton)
        backgroundView.addSubview(laterButton)
        backgroundView.addSubview(confirmButton)
        
        clipsToBounds = false
        isUserInteractionEnabled = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0.5)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 0.5
        
        backgroundView.addGestureRecognizer(tapGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ShoutView.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    // MARK: - Configuration
    
    open func craft(_ announcement: Announcement, to: UIViewController, completion: (() -> ())?) {
        panGestureActive = false
        shouldSilent = false
        configureView(announcement)
        shout(to: to)
        
        self.completion = completion
        self.barType = completion == nil ? .singleButton : .doubleButton
    }
    
    open func configureView(_ announcement: Announcement) {
        self.announcement = announcement
        imageView.image = announcement.image
        titleLabel.text = announcement.title
        subtitleLabel.text = announcement.subtitle
        
        displayTimer.invalidate()
        displayTimer = Timer.scheduledTimer(timeInterval: announcement.duration,
                                            target: self, selector: #selector(ShoutView.displayTimerDidFire), userInfo: nil, repeats: false)
        
        setupFrames()
    }
    
    open func shout(to controller: UIViewController) {
        controller.view.addSubview(self)
        
        frame.origin.y = -frame.height
        UIView.animate(withDuration: 0.35, animations: {
            self.frame.origin.y = self.safeYCoordinate
        })
    }
    
    // MARK: - Setup
    
    public func setupFrames() {
        let totalWidth = UIScreen.main.bounds.width
        let textOffsetX: CGFloat = Dimensions.textOffset
        
        [titleLabel, subtitleLabel].forEach {
            $0.frame.size.width = totalWidth - (textOffsetX * 2) - 2 * Dimensions.margin
            $0.sizeToFit()
        }
        
        titleLabel.frame.origin = CGPoint(x: textOffsetX, y: 9)
        let separatorY = titleLabel.frame.maxY + 9
        separator.frame = CGRect.init(x: 0, y: separatorY, width: totalWidth, height: 0.5)
        subtitleLabel.frame.origin = CGPoint(x: textOffsetX, y: separator.frame.maxY + 8)
        let buttonY = subtitleLabel.frame.maxY + 16
        let buttonWidth = (totalWidth - 2 * Dimensions.margin - 3 * textOffsetX) / 2
        let buttonHeight: CGFloat = 32
        laterButton.frame = CGRect(x: textOffsetX, y: buttonY, width: buttonWidth, height: buttonHeight)
        confirmButton.frame = CGRect(x: laterButton.frame.maxX + textOffsetX, y: buttonY, width: buttonWidth, height: buttonHeight)
        let singleBtnX = (totalWidth - 2 * Dimensions.margin - buttonWidth) / 2
        gotItButton.frame = CGRect(x: singleBtnX, y: buttonY, width: buttonWidth, height: buttonHeight)
        
        frame = CGRect(x: 0, y: safeYCoordinate,
                       width: totalWidth, height: gotItButton.frame.maxY + 16 + Dimensions.touchOffset)
    }
    
    // MARK: - Frame
    
    open override var frame: CGRect {
        didSet {
            let bgWidth = frame.size.width - 2 * Dimensions.margin
            backgroundView.frame = CGRect(x: Dimensions.margin, y: safeYCoordinate,
                                          width: bgWidth,
                                          height: frame.size.height - Dimensions.touchOffset)
            shadowView.frame = CGRect(x: Dimensions.margin + 3, y: safeYCoordinate + 3,
                                      width: bgWidth - 6,
                                      height: frame.size.height - Dimensions.touchOffset - 6)
        }
    }
    
    // MARK: - Actions
    
    @objc open func silent() {
        UIView.animate(withDuration: 0.35, animations: {
            //      self.frame.size.height = 0
            self.frame.origin.y = -self.frame.height
        }, completion: { finished in
            //        self.completion?()
            self.displayTimer.invalidate()
            self.removeFromSuperview()
        })
    }
    
    @objc func confirmAction() {
        self.completion?()
        silent()
    }
    
    // MARK: - Timer methods
    
    @objc open func displayTimerDidFire() {
        shouldSilent = true
        
        if panGestureActive { return }
        silent()
    }
    
    // MARK: - Gesture methods
    
    @objc fileprivate func handleTapGestureRecognizer() {
        guard let announcement = announcement else { return }
        announcement.action?()
        silent()
    }
    
    // MARK: - Handling screen orientation
    
    @objc func orientationDidChange() {
        setupFrames()
    }
}
