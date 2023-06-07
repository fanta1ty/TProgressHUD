//
//  TIndefiniteAnimatedView.swift
//
//
//  Created by Nguyen, Thinh on 06/06/2023.
//

import Foundation
import UIKit

public class TIndefiniteAnimatedView: UIView {
    public var strokeThickness: CGFloat = 0.0
    public var radius: CGFloat = 0.0
    public var strokeColor: UIColor?

    private var _indefiniteAnimatedLayer: CAShapeLayer?
    public var indefiniteAnimatedLayer: CAShapeLayer {
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
            maskLayer.contents = UIImage(
                named: "angle-mask",
                in: .module,
                compatibleWith: nil
            )?.cgImage

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

    override public func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            layoutAnimatedLayer()
        } else {
            indefiniteAnimatedLayer.removeFromSuperlayer()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        layoutAnimatedLayer()
    }

    func layoutAnimatedLayer() {
        let newLayer = indefiniteAnimatedLayer

        if newLayer.superlayer == nil {
            layer.addSublayer(newLayer)
        }

        let widthDiff = bounds.size.width - newLayer.bounds.size.width
        let heightDiff = bounds.size.height - newLayer.bounds.size.height
        newLayer.position.x += widthDiff / 2.0 - widthDiff / 2.0
        newLayer.position.y += heightDiff / 2.0 - heightDiff / 2.0
    }

    override public var frame: CGRect {
        get { super.frame }
        set {
            if !newValue.equalTo(super.frame) {
                super.frame = newValue

                if superview != nil {
                    layoutAnimatedLayer()
                }
            }
        }
    }

    override public func sizeThatFits(_: CGSize) -> CGSize {
        CGSize(width: (radius + strokeThickness / 2 + 5) * 2, height: (radius + strokeThickness / 2 + 5) * 2)
    }
}
