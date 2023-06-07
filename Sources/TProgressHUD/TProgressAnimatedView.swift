//
//  TProgressAnimatedView.swift
//
//
//  Created by Nguyen, Thinh on 06/06/2023.
//

import Foundation
import UIKit

public class TProgressAnimatedView: UIView {
    public var radius: CGFloat = 0.0
    public var strokeThickness: CGFloat = 0.0
    public var strokeColor: UIColor?
    public var strokeEnd: CGFloat = 0.0

    private var _ringAnimatedLayer: CAShapeLayer?
    public var ringAnimatedLayer: CAShapeLayer {
        if _ringAnimatedLayer == nil {
            let arcCenter = CGPoint(
                x: radius + strokeThickness / 2 + 5,
                y: radius + strokeThickness / 2 + 5
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
            ringAnimatedLayer.removeFromSuperlayer()
        }
    }

    private func layoutAnimatedLayer() {
        let newLayer = ringAnimatedLayer
        layer.addSublayer(newLayer)

        let widthDiff: CGFloat = bounds.size.width - newLayer.bounds.size.width
        let heightDiff: CGFloat = bounds.size.height - newLayer.bounds.size.height
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
        CGSize(
            width: (radius + strokeThickness / 2 + 5) * 2,
            height: (radius + strokeThickness / 2 + 5) * 2
        )
    }
}
