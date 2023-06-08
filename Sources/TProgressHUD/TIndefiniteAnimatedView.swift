//
//  TIndefiniteAnimatedView.swift
//
//
//  Created by Nguyen, Thinh on 06/06/2023.
//

import Foundation
import UIKit

public class TIndefiniteAnimatedView: UIView {
    private var _strokeThickness: CGFloat = 0.0
    public var strokeThickness: CGFloat {
        get { _strokeThickness }
        set {
            _strokeThickness = newValue

            if _indefiniteAnimatedLayer != nil {
                _indefiniteAnimatedLayer!.lineWidth = newValue
            }
        }
    }

    private var _radius: CGFloat = 0.0
    public var radius: CGFloat {
        get { _radius }
        set {
            if newValue != _radius {
                _radius = newValue

                if _indefiniteAnimatedLayer != nil {
                    _indefiniteAnimatedLayer!.removeFromSuperlayer()
                    _indefiniteAnimatedLayer = nil
                }

                if superview != nil {
                    layoutAnimatedLayer()
                }
            }
        }
    }

    private var _strokeColor: UIColor?
    public var strokeColor: UIColor? {
        get { _strokeColor }
        set {
            _strokeColor = newValue

            if _indefiniteAnimatedLayer != nil {
                _indefiniteAnimatedLayer!.strokeColor = newValue?.cgColor
            }
        }
    }

    private var _indefiniteAnimatedLayer: CAShapeLayer?
    public var indefiniteAnimatedLayer: CAShapeLayer {
        get {
            if _indefiniteAnimatedLayer == nil {
                let arcCenter = CGPoint(
                    x: radius + strokeThickness / 2 + 5,
                    y: radius + strokeThickness / 2 + 5
                )
                let smoothedPath = UIBezierPath(
                    arcCenter: arcCenter,
                    radius: radius,
                    startAngle: CGFloat.pi * 3 / 2,
                    endAngle: CGFloat.pi / 2 + CGFloat.pi * 5,
                    clockwise: true
                )

                _indefiniteAnimatedLayer = CAShapeLayer()
                _indefiniteAnimatedLayer!.contentsScale = UIScreen.main.scale
                _indefiniteAnimatedLayer!.frame = CGRect(
                    x: 0.0,
                    y: 0.0,
                    width: arcCenter.x * 2,
                    height: arcCenter.y * 2
                )
                _indefiniteAnimatedLayer!.fillColor = UIColor.clear.cgColor
                _indefiniteAnimatedLayer!.strokeColor = strokeColor?.cgColor
                _indefiniteAnimatedLayer!.lineWidth = strokeThickness
                _indefiniteAnimatedLayer!.lineCap = .round
                _indefiniteAnimatedLayer!.lineJoin = .bevel
                _indefiniteAnimatedLayer!.path = smoothedPath.cgPath

                let maskLayer = CALayer()
                #if SWIFT_PACKAGE
                maskLayer.contents = UIImage(
                    named: "angle-mask",
                    in: .module,
                    compatibleWith: nil
                )!.cgImage
                #else
                let localBundle = Bundle(for: self)
                maskLayer.contents = UIImage(
                    named: "angle-mask",
                    in: localBundle,
                    compatibleWith: nil
                )!.cgImage
                #endif

                maskLayer.frame = _indefiniteAnimatedLayer!.bounds
                _indefiniteAnimatedLayer!.mask = maskLayer

                let animationDuration: TimeInterval = 1
                let linearCurve = CAMediaTimingFunction(name: .linear)

                let animation = CABasicAnimation(keyPath: "transform.rotation")
                animation.fromValue = 0
                animation.toValue = CGFloat.pi * 2
                animation.duration = animationDuration
                animation.timingFunction = linearCurve
                animation.isRemovedOnCompletion = false
                animation.repeatCount = Float.infinity
                animation.fillMode = .forwards
                animation.autoreverses = false
                _indefiniteAnimatedLayer!.mask?.add(animation, forKey: "rotate")

                let animationGroup = CAAnimationGroup()
                animationGroup.duration = animationDuration
                animationGroup.repeatCount = Float.infinity
                animationGroup.isRemovedOnCompletion = false
                animationGroup.timingFunction = linearCurve

                let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
                strokeStartAnimation.fromValue = 0.015
                strokeStartAnimation.toValue = 0.515

                let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
                strokeEndAnimation.fromValue = 0.485
                strokeEndAnimation.toValue = 0.985

                animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
                _indefiniteAnimatedLayer!.add(animationGroup, forKey: "progress")
            }
            return _indefiniteAnimatedLayer!
        }
        set { _indefiniteAnimatedLayer = newValue }
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            layoutAnimatedLayer()
        } else {
            if _indefiniteAnimatedLayer != nil {
                _indefiniteAnimatedLayer!.removeFromSuperlayer()
                _indefiniteAnimatedLayer = nil
            }
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        layoutAnimatedLayer()
    }

    override public var frame: CGRect {
        get { super.frame }
        set {
            if !CGRectEqualToRect(newValue, super.frame) {
                super.frame = newValue

                if superview != nil {
                    layoutAnimatedLayer()
                }
            }
        }
    }

    override public func sizeThatFits(_: CGSize) -> CGSize {
        CGSize(
            width: (radius + strokeThickness / 2 + 5) * 2,
            height: (radius + strokeThickness / 2 + 5) * 2
        )
    }
}

// MARK: - Private Functions

extension TIndefiniteAnimatedView {
    private func layoutAnimatedLayer() {
        if indefiniteAnimatedLayer.superlayer == nil {
            layer.addSublayer(indefiniteAnimatedLayer)
        }

        let widthDiff = CGRectGetWidth(bounds) - CGRectGetWidth(indefiniteAnimatedLayer.bounds)
        let heightDiff = CGRectGetHeight(bounds) - CGRectGetHeight(indefiniteAnimatedLayer.bounds)

        indefiniteAnimatedLayer.position = CGPointMake(
            CGRectGetWidth(bounds) - CGRectGetWidth(indefiniteAnimatedLayer.bounds) / 2 - widthDiff / 2,
            CGRectGetHeight(bounds) - CGRectGetHeight(indefiniteAnimatedLayer.bounds) / 2 - heightDiff / 2
        )
    }
}
