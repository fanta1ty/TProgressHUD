//
//  TProgressHUD.swift
//
//
//  Created by Nguyen, Thinh on 06/06/2023.
//

import Foundation
import UIKit

public let TProgressHUDDidReceiveTouchEventNotification = "TProgressHUDDidReceiveTouchEventNotification"
public let TProgressHUDDidTouchDownInsideNotification = "TProgressHUDDidTouchDownInsideNotification"
public let TProgressHUDWillDisappearNotification = "TProgressHUDWillDisappearNotification"
public let TProgressHUDDidDisappearNotification = "TProgressHUDDidDisappearNotification"
public let TProgressHUDWillAppearNotification = "TProgressHUDWillAppearNotification"
public let TProgressHUDDidAppearNotification = "TProgressHUDDidAppearNotification"

public let TProgressHUDStatusUserInfoKey = "TProgressHUDStatusUserInfoKey"

public enum TProgressHUDStyle: Int {
    case light,
         dark,
         custom
}

public enum TProgressHUDMaskType: Int {
    case none = 1,
         clear,
         black,
         gradient,
         custom
}

public enum TProgressHUDAnimationType: Int {
    case flat,
         native
}

public typealias TProgressHUDShowCompletion = (() -> Void)?
public typealias TProgressHUDDismissCompletion = (() -> Void)?

private let TProgressHUDParallaxDepthPoints: CGFloat = 10.0
private let TProgressHUDUndefinedProgress: CGFloat = -1
private let TProgressHUDDefaultAnimationDuration: CGFloat = 0.15
private let TProgressHUDVerticalSpacing: CGFloat = 12.0
private let TProgressHUDHorizontalSpacing: CGFloat = 12.0
private let TProgressHUDLabelSpacing: CGFloat = 8.0

public class TProgressHUD: UIView {
    public static let sharedView = TProgressHUD(frame: UIApplication.shared.delegate?.window??.bounds ?? .zero)
    
    public var defaultStyle: TProgressHUDStyle = .light
    public var defaultMaskType: TProgressHUDMaskType = .none
    public var defaultAnimationType: TProgressHUDAnimationType = .flat
    public var containerView: UIView?
    public var minimumSize: CGSize = .zero
    public var ringThickness: CGFloat = 2.0
    public var ringRadius: CGFloat = 18.0
    public var ringNoTextRadius: CGFloat = 24.0
    public var cornerRadius: CGFloat = 14.0
    public var font: UIFont = .preferredFont(forTextStyle: .subheadline)
    public var customBackgroundColor: UIColor = .white
    public var foregroundColor: UIColor = .black
    public var foregroundImageColor: UIColor?
    public var backgroundLayerColor: UIColor = .init(white: 0, alpha: 0.4)
    public var imageViewSize: CGSize = .init(width: 28, height: 28)
    public var shouldTintImages: Bool = true
    public var infoImage: UIImage = .init(named: "info", in: bundle, compatibleWith: nil)!
    public var successImage: UIImage = .init(named: "success", in: bundle, compatibleWith: nil)!
    public var errorImage: UIImage = .init(named: "error", in: bundle, compatibleWith: nil)!
    public var viewForExtension: UIView? = nil
    public var graceTimeInterval: TimeInterval = 0
    public var minimumDismissTimeInterval: TimeInterval = 5
    public var maximumDismissTimeInterval: TimeInterval = CGFLOAT_MAX

    private var _offsetFromCenter: UIOffset = .zero
    public var offsetFromCenter: UIOffset! {
        get { _offsetFromCenter }
        set { _offsetFromCenter = newValue }
    }

    public var fadeInAnimationDuration: TimeInterval = 0.15
    public var fadeOutAnimationDuration: TimeInterval = 0.15
    public var maxSupportedWindowLevel: UIWindow.Level = .normal
    public var hapticsEnabled: Bool = false
    public var motionEffectEnabled: Bool = true

    private static var bundle: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle(for: TProgressHUD.self)
        #endif
    }
    
    private var _graceTimer: Timer?
    private var graceTimer: Timer? {
        get { _graceTimer }
        set {
            if _graceTimer != nil {
                _graceTimer!.invalidate()
                _graceTimer = nil
            }

            if newValue != nil {
                _graceTimer = newValue
            }
        }
    }

    private var _fadeOutTimer: Timer?
    private var fadeOutTimer: Timer? {
        get { _fadeOutTimer }
        set {
            if _fadeOutTimer != nil {
                _fadeOutTimer!.invalidate()
                _fadeOutTimer = nil
            }

            if newValue != nil {
                _fadeOutTimer = newValue
            }
        }
    }

    private var _controlView: UIControl?
    private var controlView: UIControl {
        get {
            if _controlView == nil {
                _controlView = UIControl()
                _controlView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                _controlView!.backgroundColor = .clear
                _controlView!.isUserInteractionEnabled = true
                _controlView!.addTarget(
                    self,
                    action: #selector(controlViewDidReceiveTouchEvent(sender:forEvent:)),
                    for: .touchDown
                )
            }
            if let windowBounds = UIApplication.shared.delegate?.window??.bounds {
                _controlView!.frame = windowBounds
            }
            return _controlView!
        }
        set { _controlView = newValue }
    }

    private var _backgroundView: UIView?
    private var backgroundView: UIView {
        get {
            if _backgroundView == nil {
                _backgroundView = UIView()
                _backgroundView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            if _backgroundView!.superview == nil {
                insertSubview(_backgroundView!, belowSubview: hudView)
            }
            if defaultMaskType == .gradient {
                if backgroundRadialGradientLayer == nil {
                    backgroundRadialGradientLayer = TRadialGradientLayer(layer: layer)
                }
                if backgroundRadialGradientLayer!.superlayer == nil {
                    _backgroundView!.layer.insertSublayer(backgroundRadialGradientLayer!, at: 0)
                }
                _backgroundView!.backgroundColor = .clear
            } else {
                if backgroundRadialGradientLayer != nil, backgroundRadialGradientLayer!.superlayer != nil {
                    backgroundRadialGradientLayer!.removeFromSuperlayer()
                }
                if defaultMaskType == .black {
                    _backgroundView!.backgroundColor = UIColor(white: 0, alpha: 0.4)
                } else if defaultMaskType == .custom {
                    _backgroundView!.backgroundColor = backgroundLayerColor
                } else {
                    _backgroundView!.backgroundColor = .clear
                }
            }
            if _backgroundView != nil {
                _backgroundView!.frame = bounds
            }
            if backgroundRadialGradientLayer != nil {
                backgroundRadialGradientLayer!.frame = bounds
                var gradientCenter = center
                gradientCenter.y = (bounds.size.height - visibleKeyboardHeight) / 2.0
                backgroundRadialGradientLayer!.gradientCenter = gradientCenter
                backgroundRadialGradientLayer!.setNeedsDisplay()
            }
            return _backgroundView!
        }
        set { _backgroundView = newValue }
    }

    private var backgroundRadialGradientLayer: TRadialGradientLayer?
    private var _hudView: UIVisualEffectView?
    private var hudView: UIVisualEffectView {
        get {
            if _hudView == nil {
                _hudView = UIVisualEffectView()
                _hudView!.layer.masksToBounds = true
                _hudView!.autoresizingMask = [
                    .flexibleBottomMargin,
                    .flexibleTopMargin,
                    .flexibleRightMargin,
                    .flexibleLeftMargin,
                ]
            }

            if _hudView!.superview == nil {
                addSubview(_hudView!)
            }
            _hudView!.layer.cornerRadius = cornerRadius
            return _hudView!
        }
        set { _hudView = newValue }
    }

    private var hudViewCustomBlurEffect: UIBlurEffect?
    private var _statusLabel: UILabel?
    private var statusLabel: UILabel {
        get {
            if _statusLabel == nil {
                _statusLabel = UILabel(frame: .zero)
                _statusLabel!.backgroundColor = .clear
                _statusLabel!.adjustsFontSizeToFitWidth = true
                _statusLabel!.textAlignment = .center
                _statusLabel!.baselineAdjustment = .alignCenters
                _statusLabel!.numberOfLines = 0
            }
            if _statusLabel!.superview == nil {
                hudView.contentView.addSubview(_statusLabel!)
            }

            _statusLabel!.textColor = foregroundColorForStyle
            _statusLabel!.font = font
            return _statusLabel!
        }
        set { _statusLabel = newValue }
    }

    private var _imageView: UIImageView?
    private var imageView: UIImageView {
        get {
            if _imageView != nil, !CGSizeEqualToSize(_imageView!.bounds.size, imageViewSize) {
                _imageView!.removeFromSuperview()
                _imageView = nil
            }
            if _imageView == nil {
                _imageView = UIImageView(frame: .init(
                    x: 0,
                    y: 0,
                    width: imageViewSize.width,
                    height: imageViewSize.height
                )
                )
            }
            if _imageView!.superview == nil {
                hudView.contentView.addSubview(_imageView!)
            }
            return _imageView!
        }
        set { _imageView = newValue }
    }

    private var _indefiniteAnimatedView: UIView?
    private var indefiniteAnimatedView: UIView {
        get {
            if defaultAnimationType == .flat {
                if _indefiniteAnimatedView != nil, !(_indefiniteAnimatedView is TIndefiniteAnimatedView) {
                    _indefiniteAnimatedView!.removeFromSuperview()
                    _indefiniteAnimatedView = nil
                }

                if _indefiniteAnimatedView == nil {
                    _indefiniteAnimatedView = TIndefiniteAnimatedView(frame: .zero)
                }

                if let animatedView = _indefiniteAnimatedView as? TIndefiniteAnimatedView {
                    animatedView.strokeColor = foregroundColorForStyle
                    animatedView.strokeThickness = ringThickness
                    animatedView.radius = (statusLabel.text != nil && !statusLabel.text!.isEmpty) ? ringRadius : ringNoTextRadius
                }
            } else {
                if _indefiniteAnimatedView != nil, !(_indefiniteAnimatedView is UIActivityIndicatorView) {
                    _indefiniteAnimatedView!.removeFromSuperview()
                    _indefiniteAnimatedView = nil
                }

                if _indefiniteAnimatedView == nil {
                    _indefiniteAnimatedView = UIActivityIndicatorView(style: .whiteLarge)
                }

                if let animatedView = _indefiniteAnimatedView as? UIActivityIndicatorView {
                    animatedView.color = foregroundColorForStyle
                }
            }

            _indefiniteAnimatedView!.sizeToFit()
            return _indefiniteAnimatedView!
        }
        set { _indefiniteAnimatedView = newValue }
    }

    private var _ringView: TProgressAnimatedView?
    private var ringView: TProgressAnimatedView {
        get {
            if _ringView == nil {
                _ringView = TProgressAnimatedView(frame: .zero)
            }
            _ringView!.strokeColor = foregroundImageColorForStyle
            _ringView!.strokeThickness = ringThickness
            _ringView!.radius = (statusLabel.text != nil && !statusLabel.text!.isEmpty) ? ringRadius : ringNoTextRadius
            return _ringView!
        }
        set { _ringView = newValue }
    }

    private var _backgroundRingView: TProgressAnimatedView?
    private var backgroundRingView: TProgressAnimatedView {
        get {
            if _backgroundRingView == nil {
                _backgroundRingView = TProgressAnimatedView(frame: .zero)
                _backgroundRingView!.strokeEnd = 1.0
            }

            _backgroundRingView!.strokeColor = foregroundColorForStyle.withAlphaComponent(0.1)
            _backgroundRingView!.strokeThickness = ringThickness
            _backgroundRingView!.radius = (statusLabel.text != nil && !statusLabel.text!.isEmpty) ? ringRadius : ringNoTextRadius
            return _backgroundRingView!
        }
        set { _backgroundRingView = newValue }
    }

    private var progress: CGFloat = 0.0
    private var activityCount: UInt = 0

    private var _visibleKeyboardHeight: CGFloat = 0
    private var visibleKeyboardHeight: CGFloat {
        get {
            var keyboardWindow: UIWindow? = nil
            for testWindow in UIApplication.shared.windows {
                if !testWindow.isKind(of: UIWindow.self) {
                    keyboardWindow = testWindow
                    break
                }
            }

            if let keyboardWindowSubviews = keyboardWindow?.subviews {
                for possibleKeyboard in keyboardWindowSubviews {
                    let viewName = String(describing: type(of: possibleKeyboard))
                    if viewName.hasPrefix("UI") {
                        if viewName.hasSuffix("PeripheralHostView") || viewName.hasSuffix("Keyboard") {
                            return possibleKeyboard.bounds.height
                        } else if viewName.hasSuffix("InputSetContainerView") {
                            for possibleKeyboardSubview in possibleKeyboard.subviews {
                                let viewName = String(describing: type(of: possibleKeyboardSubview))
                                if viewName.hasPrefix("UI"), viewName.hasSuffix("InputSetHostView") {
                                    let convertedRect = possibleKeyboard.convert(possibleKeyboardSubview.frame, to: self)
                                    let intersectedRect = convertedRect.intersection(bounds)

                                    if !intersectedRect.isNull {
                                        return intersectedRect.height
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return 0
        }
        set { _visibleKeyboardHeight = newValue }
    }

    private var _frontWindow: UIWindow?
    private var frontWindow: UIWindow? {
        get {
            let frontToBackWindows = UIApplication.shared.windows.reversed()

            for window in frontToBackWindows {
                let windowOnMainScreen = window.screen == UIScreen.main
                let windowIsVisible = !window.isHidden && (window.alpha > 0)
                let windowLevelSupported = window.windowLevel >= .normal && window.windowLevel <= maxSupportedWindowLevel
                let windowKeyWindow = window.isKeyWindow

                if windowOnMainScreen, windowIsVisible, windowLevelSupported, windowKeyWindow {
                    return window
                }
            }

            return nil
        }
        set { _frontWindow = newValue }
    }

    private var _hapticGenerator: UINotificationFeedbackGenerator?
    private var hapticGenerator: UINotificationFeedbackGenerator? {
        get {
            if !hapticsEnabled {
                return nil
            }

            if _hapticGenerator == nil {
                _hapticGenerator = UINotificationFeedbackGenerator()
            }

            return _hapticGenerator
        }
        set { _hapticGenerator = newValue }
    }

    private var isInitializing = false

    private var foregroundColorForStyle: UIColor {
        if defaultStyle == .light {
            return .black
        } else if defaultStyle == .dark {
            return .white
        } else {
            return foregroundColor
        }
    }

    private var foregroundImageColorForStyle: UIColor {
        if foregroundImageColor != nil {
            return foregroundImageColor!
        } else {
            return foregroundColorForStyle
        }
    }

    private var backgroundColorForStyle: UIColor {
        if defaultStyle == .light {
            return .white
        } else if defaultStyle == .dark {
            return .black
        } else {
            return customBackgroundColor
        }
    }

    private var notificationUserInfo: [AnyHashable: Any]? {
        (statusLabel.text != nil && !statusLabel.text!.isEmpty) ? [TProgressHUDStatusUserInfoKey: statusLabel.text!] : nil
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.isInitializing = true

        isUserInteractionEnabled = false
        self.activityCount = 0
        backgroundView.alpha = 0
        imageView.alpha = 0
        statusLabel.alpha = 0
        indefiniteAnimatedView.alpha = 0
        ringView.alpha = 0
        backgroundRingView.alpha = 0

        self.customBackgroundColor = .white
        self.foregroundColor = .black
        self.backgroundLayerColor = .init(white: 0, alpha: 0.4)

        self.defaultMaskType = .none
        self.defaultStyle = .light
        self.defaultAnimationType = .flat
        self.minimumSize = .zero
        self.font = .preferredFont(forTextStyle: .headline)

        self.imageViewSize = .init(width: 28, height: 28)
        self.shouldTintImages = true
        
        #if SWIFT_PACKAGE
        self.infoImage = UIImage(named: "info", in: .module, compatibleWith: nil)!
        self.successImage = UIImage(named: "success", in: .module, compatibleWith: nil)!
        self.errorImage = UIImage(named: "error", in: .module, compatibleWith: nil)!
        #else
        let localBundle = Bundle(for: TProgressHUD.self)
        self.infoImage = UIImage(named: "info", in: localBundle, compatibleWith: nil)!
        self.successImage = UIImage(named: "success", in: localBundle, compatibleWith: nil)!
        self.errorImage = UIImage(named: "error", in: localBundle, compatibleWith: nil)!
        #endif

        self.ringThickness = 2
        self.ringRadius = 18
        self.ringNoTextRadius = 24

        self.cornerRadius = 14

        self.graceTimeInterval = 0
        self.minimumDismissTimeInterval = 5
        self.maximumDismissTimeInterval = CGFLOAT_MAX

        self.fadeInAnimationDuration = TProgressHUDDefaultAnimationDuration
        self.fadeOutAnimationDuration = TProgressHUDDefaultAnimationDuration
        self.maxSupportedWindowLevel = .normal
        self.hapticsEnabled = false
        self.motionEffectEnabled = true

        accessibilityIdentifier = "TProgressHUD"
        isAccessibilityElement = true

        self.isInitializing = false
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public Static Functions

public extension TProgressHUD {
    static func setStatus(status: String) {
        sharedView.setStatus(status: status)
    }

    static func setDefaultStyle(style: TProgressHUDStyle) {
        sharedView.defaultStyle = style
    }

    static func setDefaultMaskType(maskType: TProgressHUDMaskType) {
        sharedView.defaultMaskType = maskType
    }

    static func setDefaultAnimationType(type: TProgressHUDAnimationType) {
        sharedView.defaultAnimationType = type
    }

    static func setContainerView(containerView: UIView?) {
        sharedView.containerView = containerView
    }

    static func setMinimumSize(minimumSize: CGSize) {
        sharedView.minimumSize = minimumSize
    }

    static func setRingThickness(ringThickness: CGFloat) {
        sharedView.ringThickness = ringThickness
    }

    static func setRingRadius(radius: CGFloat) {
        sharedView.ringRadius = radius
    }

    static func setRingNoTextRadius(radius: CGFloat) {
        sharedView.ringNoTextRadius = radius
    }

    static func setCornerRadius(cornerRadius: CGFloat) {
        sharedView.cornerRadius = cornerRadius
    }

    static func setBorderColor(color: UIColor) {
        sharedView.hudView.layer.borderColor = color.cgColor
    }

    static func setBorderWidth(width: CGFloat) {
        sharedView.hudView.layer.borderWidth = width
    }

    static func setFont(font: UIFont) {
        sharedView.font = font
    }

    static func setForegroundColor(color: UIColor) {
        sharedView.foregroundColor = color
        setDefaultStyle(style: .custom)
    }

    static func setForegroundImageColor(color: UIColor) {
        sharedView.foregroundImageColor = color
        setDefaultStyle(style: .custom)
    }

    static func setBackgroundColor(color: UIColor) {
        sharedView.backgroundColor = color
        setDefaultStyle(style: .custom)
    }

    static func setHudViewCustomBlurEffect(blurEffect: UIBlurEffect) {
        sharedView.hudViewCustomBlurEffect = blurEffect
        setDefaultStyle(style: .custom)
    }

    static func setBackgroundLayerColor(color: UIColor) {
        sharedView.backgroundLayerColor = color
    }

    static func setImageViewSize(size: CGSize) {
        sharedView.imageViewSize = size
    }

    static func setShouldTintImages(shouldTintImages: Bool) {
        sharedView.shouldTintImages = shouldTintImages
    }

    static func setInfoImage(image: UIImage) {
        sharedView.infoImage = image
    }

    static func setSuccessImage(image: UIImage) {
        sharedView.successImage = image
    }

    static func setErrorImage(image: UIImage) {
        sharedView.errorImage = image
    }

    static func setViewForExtension(view: UIView) {
        sharedView.viewForExtension = view
    }

    static func setGraceTimeInterval(interval: TimeInterval) {
        sharedView.graceTimeInterval = interval
    }

    static func setMinimumDismissTimeInterval(interval: TimeInterval) {
        sharedView.minimumDismissTimeInterval = interval
    }

    static func setMaximumDismissTimeInterval(interval: TimeInterval) {
        sharedView.maximumDismissTimeInterval = interval
    }

    static func setFadeInAnimationDuration(duration: TimeInterval) {
        sharedView.fadeInAnimationDuration = duration
    }

    static func setFadeOutAnimationDuration(duration: TimeInterval) {
        sharedView.fadeOutAnimationDuration = duration
    }

    static func setMaxSupportedWindowLevel(windowLevel: UIWindow.Level) {
        sharedView.maxSupportedWindowLevel = windowLevel
    }

    static func setHapticsEnabled(hapticsEnabled: Bool) {
        sharedView.hapticsEnabled = hapticsEnabled
    }

    static func setMotionEffectEnabled(motionEffectEnabled: Bool) {
        sharedView.motionEffectEnabled = motionEffectEnabled
    }

    static func isVisible() -> Bool {
        sharedView.backgroundView.alpha > 0
    }
}

// MARK: - Show Functions

public extension TProgressHUD {
    static func show() {
        showWithStatus(status: "")
    }

    static func showWithMaskType(
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        show()
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func showWithStatus(
        status: String
    ) {
        showProgress(
            progress: TProgressHUDUndefinedProgress,
            status: status
        )
    }

    static func showWithStatus(
        status: String,
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        showWithStatus(status: status)
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func showProgress(
        progress: CGFloat
    ) {
        showProgress(
            progress: progress,
            status: ""
        )
    }

    static func showProgress(
        progress: CGFloat,
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        showProgress(progress: progress)
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func showProgress(
        progress: CGFloat,
        status: String
    ) {
        sharedView.showProgress(progress: progress, status: status)
    }

    static func showProgress(
        progress: CGFloat,
        status: String,
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        sharedView.showProgress(progress: progress, status: status)
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func showInfoWithStatus(
        status: String
    ) {
        showImage(image: sharedView.infoImage, status: status)

        DispatchQueue.main.async {
            sharedView.hapticGenerator?.notificationOccurred(.warning)
        }
    }

    static func showInfoWithStatus(
        status: String,
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        showInfoWithStatus(status: status)
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func showSuccessWithStatus(
        status: String
    ) {
        showImage(image: sharedView.successImage, status: status)

        DispatchQueue.main.async {
            sharedView.hapticGenerator?.notificationOccurred(.success)
        }
    }

    static func showSuccessWithStatus(
        status: String,
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        showSuccessWithStatus(status: status)
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func showErrorWithStatus(
        status: String
    ) {
        showImage(image: sharedView.errorImage, status: status)

        DispatchQueue.main.async {
            sharedView.hapticGenerator?.notificationOccurred(.error)
        }
    }

    static func showErrorWithStatus(
        status: String,
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        showErrorWithStatus(status: status)
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func showImage(
        image: UIImage,
        status: String
    ) {
        let displayInterval = displayDurationForString(string: status)
        sharedView.showImage(
            image: image,
            status: status,
            duration: displayInterval
        )
    }

    static func showImage(
        image: UIImage,
        status: String,
        maskType: TProgressHUDMaskType
    ) {
        let existingMaskType = sharedView.defaultMaskType
        setDefaultMaskType(maskType: maskType)
        showImage(image: image, status: status)
        setDefaultMaskType(maskType: existingMaskType)
    }

    static func displayDurationForString(
        string: String
    ) -> TimeInterval {
        let minimum = max(CGFloat(string.count) * 0.06 + 0.5, sharedView.minimumDismissTimeInterval)
        return min(minimum, sharedView.maximumDismissTimeInterval)
    }

    static func popActivity() {
        if sharedView.activityCount > 0 {
            sharedView.activityCount -= 1
        }
        if sharedView.activityCount == 0 {
            sharedView.dismiss()
        }
    }

    static func dismiss() {
        dismissWithDelay(
            delay: 0,
            completion: nil
        )
    }

    static func dismissWithCompletion(
        completion _: TProgressHUDDismissCompletion
    ) {
        dismissWithDelay(delay: 0, completion: nil)
    }

    static func dismissWithDelay(
        delay _: TimeInterval
    ) {
        dismissWithDelay(
            delay: 0,
            completion: nil
        )
    }

    static func dismissWithDelay(
        delay: TimeInterval,
        completion: TProgressHUDDismissCompletion
    ) {
        sharedView.dismissWithDelay(
            delay: delay,
            completion: completion
        )
    }

    static func setOffsetFromCenter(
        offset: UIOffset
    ) {
        sharedView.offsetFromCenter = offset
    }

    static func resetOffsetFromCenter() {
        setOffsetFromCenter(offset: .zero)
    }
}

// MARK: - Private Functions

extension TProgressHUD {
    private func setStatus(status: String) {
        statusLabel.text = status
        statusLabel.isHidden = status.isEmpty
        updateHUDFrame()
    }

    private func updateHUDFrame() {
        let imageUsed = imageView.image != nil && !imageView.isHidden
        let progressUsed = imageView.isHidden

        var labelRect = CGRect.zero
        var labelHeight: CGFloat = 0
        var labelWidth: CGFloat = 0

        if statusLabel.text != nil && !statusLabel.text!.isEmpty {
            let constraintSize = CGSizeMake(200, 300)
            labelRect = (statusLabel.text! as NSString).boundingRect(
                with: constraintSize,
                options: [.usesFontLeading, .truncatesLastVisibleLine, .usesLineFragmentOrigin],
                attributes: [NSAttributedString.Key.font: statusLabel.font!],
                context: nil
            )
            labelHeight = CGFloat(ceilf(Float(CGRectGetHeight(labelRect))))
            labelWidth = CGFloat(ceilf(Float(CGRectGetWidth(labelRect))))
        }
        var hudWidth: CGFloat = 0
        var hudHeight: CGFloat = 0
        var contentWidth: CGFloat = 0
        var contentHeight: CGFloat = 0

        if imageUsed || progressUsed {
            contentWidth = CGRectGetWidth(imageUsed ? imageView.frame : indefiniteAnimatedView.frame)
            contentHeight = CGRectGetHeight(imageUsed ? imageView.frame : indefiniteAnimatedView.frame)
        }

        hudWidth = TProgressHUDHorizontalSpacing + CGFloat.maximum(labelWidth, contentWidth) + TProgressHUDHorizontalSpacing
        hudHeight = TProgressHUDVerticalSpacing + labelHeight + contentHeight + TProgressHUDVerticalSpacing

        if (statusLabel.text != nil && !statusLabel.text!.isEmpty) && (imageUsed || progressUsed) {
            hudHeight += TProgressHUDLabelSpacing
        }

        hudView.bounds = CGRectMake(0, 0, CGFloat.maximum(minimumSize.width, hudWidth), CGFloat.maximum(minimumSize.height, hudHeight))

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        var centerY: CGFloat = 0
        if statusLabel.text != nil && !statusLabel.text!.isEmpty {
            let yOffset = CGFloat.maximum(
                TProgressHUDVerticalSpacing,
                (minimumSize.height - contentHeight - TProgressHUDLabelSpacing - labelHeight) / 2.0
            )
            centerY = yOffset + contentHeight / 2.0
        } else {
            centerY = CGRectGetMidY(hudView.bounds)
        }

        indefiniteAnimatedView.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)

        if progress != TProgressHUDUndefinedProgress {
            let center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)
            backgroundRingView.center = center
            ringView.center = center
        }
        imageView.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)

        if imageUsed || progressUsed {
            centerY = CGRectGetMaxY(imageUsed ? imageView.frame : indefiniteAnimatedView.frame) + TProgressHUDLabelSpacing + labelHeight / 2.0
        } else {
            centerY = CGRectGetMidY(hudView.bounds)
        }

        statusLabel.frame = labelRect
        statusLabel.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)

        CATransaction.commit()
    }
}

// MARK: - Private Action Functions

extension TProgressHUD {
    @objc
    private func controlViewDidReceiveTouchEvent(
        sender _: AnyObject?,
        forEvent: UIEvent
    ) {
        NotificationCenter.default.post(
            name: NSNotification.Name(TProgressHUDDidReceiveTouchEventNotification),
            object: self,
            userInfo: notificationUserInfo
        )

        guard let touch = forEvent.allTouches?.first else { return }
        let touchLocation = touch.location(in: self)

        if CGRectContainsPoint(hudView.frame, touchLocation) {
            NotificationCenter.default.post(
                name: NSNotification.Name(TProgressHUDDidTouchDownInsideNotification),
                object: self,
                userInfo: notificationUserInfo
            )
        }
    }

    @objc
    private func fadeIn(_ data: Any?) {
        updateHUDFrame()
        positionHUD(notification: nil)

        let accessibilityString = statusLabel.text?.components(separatedBy: .newlines).joined(separator: " ")

        if defaultMaskType == .none {
            controlView.isUserInteractionEnabled = true
            accessibilityLabel = accessibilityString ?? "Loading"
            isAccessibilityElement = true
            controlView.accessibilityViewIsModal = true
        } else {
            controlView.isUserInteractionEnabled = false
            hudView.accessibilityLabel = accessibilityString ?? "Loading"
            hudView.isAccessibilityElement = true
            controlView.accessibilityViewIsModal = false
        }

        var duration: Any?

        if let data = data {
            duration = data is Timer ? (data as! Timer).userInfo : data
        }

        if backgroundView.alpha != 1.0 {
            NotificationCenter.default.post(
                name: NSNotification.Name(TProgressHUDWillAppearNotification),
                object: self,
                userInfo: notificationUserInfo
            )

            hudView.transform = hudView.transform.scaledBy(x: 1.3, y: 1.3)

            let animationsBlock: () -> Void = { [weak self] in
                guard let self = self else { return }
                self.hudView.transform = CGAffineTransform.identity
                self.fadeInEffects()
            }

            let completionBlock: () -> Void = { [weak self] in
                guard let self = self else { return }
                if self.backgroundView.alpha == 1.0 {
                    self.registerNotifications()

                    NotificationCenter.default.post(
                        name: NSNotification.Name(TProgressHUDDidAppearNotification),
                        object: self,
                        userInfo: notificationUserInfo
                    )
                    UIAccessibility.post(notification: .screenChanged, argument: nil)
                    UIAccessibility.post(notification: .announcement, argument: statusLabel.text)

                    if duration != nil {
                        self.fadeOutTimer = Timer.scheduledTimer(
                            timeInterval: duration as? Double ?? 0,
                            target: self,
                            selector: #selector(dismiss),
                            userInfo: nil,
                            repeats: false
                        )
                        RunLoop.main.add(self.fadeOutTimer!, forMode: RunLoop.Mode.common)
                    }
                }
            }

            if fadeInAnimationDuration > 0 {
                UIView.animate(
                    withDuration: fadeInAnimationDuration,
                    delay: 0,
                    options: [.allowUserInteraction, .curveEaseIn, .beginFromCurrentState],
                    animations: {
                        animationsBlock()
                    },
                    completion: { _ in
                        completionBlock()
                    }
                )
            } else {
                animationsBlock()
                completionBlock()
            }

            setNeedsDisplay()
        } else {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
            UIAccessibility.post(notification: .announcement, argument: statusLabel.text)

            if duration != nil {
                fadeOutTimer = Timer.scheduledTimer(
                    timeInterval: duration as? Double ?? 0,
                    target: self,
                    selector: #selector(dismiss),
                    userInfo: nil,
                    repeats: false
                )
                RunLoop.main.add(fadeOutTimer!, forMode: RunLoop.Mode.common)
            }
        }
    }

    @objc
    private func positionHUD(notification: Notification?) {
        var keyboardHeight: CGFloat = 0
        var animationDuration: Double = 0
        
        if let windowFrame = UIApplication.shared.delegate?.window??.bounds {
            frame = windowFrame
        }

        let orientation = UIApplication.shared.statusBarOrientation

        if notification != nil {
            let keyboardInfo = notification!.userInfo as! [String: Any]
            let keyboardFrame = keyboardInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
            animationDuration = keyboardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double

            if
                notification!.name == UIResponder.keyboardWillShowNotification ||
                notification!.name == UIResponder.keyboardDidShowNotification
            {
                keyboardHeight = CGRectGetWidth(keyboardFrame)

                if orientation.isPortrait {
                    keyboardHeight = CGRectGetHeight(keyboardFrame)
                }
            }
        } else {
            keyboardHeight = visibleKeyboardHeight
        }

        let orientationFrame = bounds
        let statusBarFrame = UIApplication.shared.statusBarFrame

        if motionEffectEnabled {
            updateMotionEffectForOrientation(orientation: orientation)
        }

        var activeHeight = CGRectGetHeight(orientationFrame)
        if keyboardHeight > 0 {
            activeHeight += CGRectGetHeight(statusBarFrame) * 2
        }
        activeHeight -= keyboardHeight

        let posX = CGRectGetMidX(orientationFrame)
        let posY = floorf(Float(activeHeight) * 0.45)

        let rotateAngle = 0
        let newCenter = CGPointMake(posX, CGFloat(posY))

        if notification != nil {
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) { [weak self] in
                guard let self = self else { return }
                self.moveToPoint(
                    newCenter: newCenter,
                    rotateAngle: CGFloat(rotateAngle)
                )
                self.hudView.setNeedsDisplay()
            }
        } else {
            moveToPoint(
                newCenter: newCenter,
                rotateAngle: CGFloat(rotateAngle)
            )
        }
    }

    @objc
    private func dismiss() {
        dismissWithDelay(delay: 0, completion: nil)
    }

    private func dismissWithDelay(
        delay: TimeInterval,
        completion: TProgressHUDDismissCompletion
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            NotificationCenter.default.post(
                name: Notification.Name(TProgressHUDWillDisappearNotification),
                object: nil,
                userInfo: self.notificationUserInfo
            )

            self.activityCount = 0

            let animationsBlock: () -> Void = {
                self.hudView.transform = CGAffineTransformScale(
                    self.hudView.transform,
                    1.0 / 1.3,
                    1.0 / 1.3
                )

                self.fadeOutEffects()
            }

            let completionBlock: () -> Void = { [weak self] in
                guard let self = self else { return }
                if self.backgroundView.alpha == 0 {
                    self.controlView.removeFromSuperview()
                    self.backgroundView.removeFromSuperview()
                    self.hudView.removeFromSuperview()
                    self.removeFromSuperview()

                    self.progress = TProgressHUDUndefinedProgress
                    self.cancelRingLayerAnimation()
                    self.cancelIndefiniteAnimatedViewAnimation()

                    NotificationCenter.default.removeObserver(self)
                    NotificationCenter.default.post(
                        name: NSNotification.Name(TProgressHUDDidDisappearNotification),
                        object: self,
                        userInfo: notificationUserInfo
                    )

                    if let rootController = UIApplication.shared.keyWindow?.rootViewController {
                        rootController.setNeedsStatusBarAppearanceUpdate()
                    }

                    if completion != nil {
                        completion!()
                    }
                }
            }
            
            let dipatchTime = DispatchTime.now() + delay
            DispatchQueue.main.asyncAfter(deadline: dipatchTime) {
                self.graceTimer = nil

                if self.fadeOutAnimationDuration > 0 {
                    UIView.animate(
                        withDuration: self.fadeOutAnimationDuration,
                        delay: 0,
                        options: [.allowUserInteraction, .curveEaseOut, .beginFromCurrentState],
                        animations: {
                            animationsBlock()
                        },
                        completion: { _ in
                            completionBlock()
                        }
                    )
                } else {
                    animationsBlock()
                    completionBlock()
                }
            }

            self.setNeedsDisplay()
        }
    }
}

// MARK: - Private Show/Dismiss Functions

extension TProgressHUD {
    private func showProgress(
        progress: CGFloat,
        status: String
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.fadeOutTimer != nil {
                self.activityCount = 0
            }

            self.fadeOutTimer = nil
            self.graceTimer = nil
            self.updateViewHierarchy()

            self.imageView.isHidden = true
            self.imageView.image = nil

            self.statusLabel.isHidden = status.isEmpty
            self.statusLabel.text = status
            self.progress = progress

            if progress >= 0 {
                self.cancelIndefiniteAnimatedViewAnimation()

                if self.ringView.superview == nil {
                    self.hudView.contentView.addSubview(self.ringView)
                }
                if self.backgroundRingView.superview == nil {
                    self.hudView.contentView.addSubview(self.backgroundRingView)
                }
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.ringView.strokeEnd = progress
                CATransaction.commit()

                if progress == 0 {
                    self.activityCount += 1
                }
            } else {
                self.cancelRingLayerAnimation()
                self.hudView.contentView.addSubview(self.indefiniteAnimatedView)

                if self.indefiniteAnimatedView.responds(to: #selector(UIActivityIndicatorView.startAnimating)) {
                    self.indefiniteAnimatedView.perform(#selector(UIActivityIndicatorView.startAnimating))
                }

                self.activityCount += 1
            }

            if self.graceTimeInterval > 0, self.backgroundView.alpha == 0 {
                self.graceTimer = Timer(
                    timeInterval: self.graceTimeInterval,
                    target: self,
                    selector: #selector(self.fadeIn),
                    userInfo: nil,
                    repeats: false
                )
                RunLoop.main.add(self.graceTimer!, forMode: RunLoop.Mode.common)
            } else {
                self.fadeIn(nil)
            }

            self.hapticGenerator?.prepare()
        }
    }

    private func updateViewHierarchy() {
        if controlView.superview == nil {
            if containerView != nil {
                containerView!.addSubview(controlView)
            } else {
                frontWindow?.addSubview(controlView)
            }
        } else {
            controlView.superview!.bringSubviewToFront(controlView)
        }

        if superview == nil {
            controlView.addSubview(self)
        }
    }

    private func cancelIndefiniteAnimatedViewAnimation() {
        if indefiniteAnimatedView.responds(to: #selector(UIActivityIndicatorView.stopAnimating)) {
            indefiniteAnimatedView.perform(#selector(UIActivityIndicatorView.stopAnimating))
        }

        indefiniteAnimatedView.removeFromSuperview()
    }

    private func cancelRingLayerAnimation() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        hudView.layer.removeAllAnimations()
        ringView.strokeEnd = 0

        CATransaction.commit()

        ringView.removeFromSuperview()
        backgroundRingView.removeFromSuperview()
    }

    private func updateMotionEffectForOrientation(
        orientation: UIInterfaceOrientation
    ) {
        let xMotionEffectType: UIInterpolatingMotionEffect.EffectType = orientation.isPortrait ? .tiltAlongHorizontalAxis : .tiltAlongVerticalAxis
        let yMotionEffectType: UIInterpolatingMotionEffect.EffectType = orientation.isPortrait ? .tiltAlongVerticalAxis : .tiltAlongHorizontalAxis

        updateMotionEffectForXMotionEffectType(
            xMotionEffectType,
            yMotionEffectType: yMotionEffectType
        )
    }

    private func updateMotionEffectForXMotionEffectType(
        _ xMotionEffectType: UIInterpolatingMotionEffect.EffectType,
        yMotionEffectType: UIInterpolatingMotionEffect.EffectType
    ) {
        let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: xMotionEffectType)
        effectX.minimumRelativeValue = -TProgressHUDParallaxDepthPoints
        effectX.maximumRelativeValue = TProgressHUDParallaxDepthPoints

        let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: yMotionEffectType)
        effectY.minimumRelativeValue = -TProgressHUDParallaxDepthPoints
        effectY.maximumRelativeValue = TProgressHUDParallaxDepthPoints

        let effectGroup = UIMotionEffectGroup()
        effectGroup.motionEffects = [effectX, effectY]

        hudView.motionEffects = []
        hudView.addMotionEffect(effectGroup)
    }

    private func moveToPoint(
        newCenter: CGPoint,
        rotateAngle angle: CGFloat
    ) {
        hudView.transform = CGAffineTransformMakeRotation(angle)

        if containerView != nil {
            hudView.center = CGPointMake(
                containerView!.center.x + offsetFromCenter.horizontal,
                containerView!.center.y + offsetFromCenter.vertical
            )
        } else {
            hudView.center = CGPointMake(
                newCenter.x + offsetFromCenter.horizontal,
                newCenter.y + offsetFromCenter.vertical
            )
        }
    }

    private func fadeInEffects() {
        if defaultStyle != .custom {
            let blurEffectStyle = defaultStyle == .dark ? UIBlurEffect.Style.dark : UIBlurEffect.Style.light
            let blurEffect = UIBlurEffect(style: blurEffectStyle)
            hudView.effect = blurEffect
            hudView.backgroundColor = backgroundColorForStyle.withAlphaComponent(0.6)
        } else {
            hudView.effect = hudViewCustomBlurEffect
            hudView.backgroundColor = backgroundColorForStyle
        }

        backgroundView.alpha = 1.0
        imageView.alpha = 1.0
        statusLabel.alpha = 1.0
        indefiniteAnimatedView.alpha = 1.0
        ringView.alpha = 1.0
        backgroundView.alpha = 1.0
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(positionHUD(notification:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(positionHUD(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(positionHUD(notification:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(positionHUD(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(positionHUD(notification:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(positionHUD(notification:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    private func fadeOutEffects() {
        if defaultStyle != .custom {
            hudView.effect = nil
        }

        hudView.backgroundColor = .clear
        backgroundView.alpha = 0
        imageView.alpha = 0
        statusLabel.alpha = 0
        indefiniteAnimatedView.alpha = 0
        ringView.alpha = 0
        backgroundRingView.alpha = 0
    }

    private func showImage(
        image: UIImage,
        status: String,
        duration: TimeInterval
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.fadeOutTimer = nil
            self.graceTimer = nil
            self.updateViewHierarchy()

            self.progress = TProgressHUDUndefinedProgress
            self.cancelRingLayerAnimation()
            self.cancelIndefiniteAnimatedViewAnimation()

            if self.shouldTintImages {
                if image.renderingMode != .alwaysTemplate {
                    self.imageView.image = image.withRenderingMode(.alwaysTemplate)
                } else {
                    self.imageView.image = image
                }
                self.imageView.tintColor = self.foregroundImageColorForStyle
            } else {
                self.imageView.image = image
            }
            self.imageView.isHidden = false

            self.statusLabel.isHidden = status.isEmpty
            self.statusLabel.text = status

            if self.graceTimeInterval > 0, self.backgroundView.alpha == 0 {
                self.graceTimer = Timer(
                    timeInterval: self.graceTimeInterval,
                    target: self,
                    selector: #selector(self.fadeIn),
                    userInfo: duration,
                    repeats: false
                )
                RunLoop.main.add(self.graceTimer!, forMode: RunLoop.Mode.common)
            } else {
                self.fadeIn(duration)
            }
        }
    }
}
