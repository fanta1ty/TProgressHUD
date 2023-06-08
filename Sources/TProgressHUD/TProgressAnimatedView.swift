//
//  TProgressAnimatedView.swift
//
//
//  Created by Nguyen, Thinh on 06/06/2023.
//

import Foundation
import UIKit

public class TProgressAnimatedView: UIView {
    private var _radius: CGFloat = 0.0
    public var radius: CGFloat {
        get { _radius }
        set {
            if newValue != _radius {
                _radius = newValue

                if _ringAnimatedLayer != nil {
                    _ringAnimatedLayer!.removeFromSuperlayer()
                    _ringAnimatedLayer = nil
                }

                if superview != nil {
                    layoutAnimatedLayer()
                }
            }
        }
    }

    private var _strokeThickness: CGFloat = 0.0
    public var strokeThickness: CGFloat {
        get { _strokeThickness }
        set {
            _strokeThickness = newValue

            if _ringAnimatedLayer != nil {
                _ringAnimatedLayer!.lineWidth = newValue
            }
        }
    }

    private var _strokeColor: UIColor?
    public var strokeColor: UIColor? {
        get { _strokeColor }
        set {
            _strokeColor = newValue

            if _ringAnimatedLayer != nil, newValue != nil {
                _ringAnimatedLayer!.strokeColor = newValue!.cgColor
            }
        }
    }

    private var _strokeEnd: CGFloat = 0.0
    public var strokeEnd: CGFloat {
        get { _strokeEnd }
        set {
            _strokeEnd = newValue

            if _ringAnimatedLayer != nil {
                _ringAnimatedLayer!.strokeEnd = newValue
            }
        }
    }

    private var _ringAnimatedLayer: CAShapeLayer?
    public var ringAnimatedLayer: CAShapeLayer {
        if _ringAnimatedLayer == nil {
            let arcCenter = CGPointMake(
                radius + strokeThickness / 2 + 5,
                radius + strokeThickness / 2 + 5
            )

            let smoothedPath = UIBezierPath(
                arcCenter: arcCenter,
                radius: radius,
                startAngle: -CGFloat.pi / 2,
                endAngle: CGFloat.pi + CGFloat.pi / 2,
                clockwise: true
            )

            _ringAnimatedLayer = CAShapeLayer()
            _ringAnimatedLayer!.contentsScale = UIScreen.main.scale
            _ringAnimatedLayer!.frame = CGRect(
                x: 0.0,
                y: 0.0,
                width: arcCenter.x * 2,
                height: arcCenter.y * 2
            )
            _ringAnimatedLayer!.fillColor = UIColor.clear.cgColor
            _ringAnimatedLayer!.strokeColor = strokeColor?.cgColor
            _ringAnimatedLayer!.lineWidth = strokeThickness
            _ringAnimatedLayer!.lineCap = .round
            _ringAnimatedLayer!.lineJoin = .bevel
            _ringAnimatedLayer!.path = smoothedPath.cgPath
        }
        return _ringAnimatedLayer!
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            layoutAnimatedLayer()
        } else {
            if _ringAnimatedLayer != nil {
                _ringAnimatedLayer!.removeFromSuperlayer()
                _ringAnimatedLayer = nil
            }
        }
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

extension TProgressAnimatedView {
    private func layoutAnimatedLayer() {
        layer.addSublayer(ringAnimatedLayer)

        let widthDiff: CGFloat = CGRectGetWidth(bounds) - CGRectGetWidth(ringAnimatedLayer.bounds)
        let heightDiff: CGFloat = CGRectGetHeight(bounds) - CGRectGetHeight(ringAnimatedLayer.bounds)
        ringAnimatedLayer.position = CGPointMake(
            CGRectGetWidth(bounds) - CGRectGetWidth(ringAnimatedLayer.bounds) / 2 - widthDiff / 2,
            CGRectGetHeight(bounds) - CGRectGetHeight(ringAnimatedLayer.bounds) / 2 - heightDiff / 2
        )
    }
}
