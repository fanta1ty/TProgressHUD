//
//  TRadialGradientLayer.swift
//
//
//  Created by Nguyen, Thinh on 06/06/2023.
//

import Foundation
import QuartzCore

public class TRadialGradientLayer: CALayer {
    public var gradientCenter: CGPoint = .zero

    public override func draw(in context: CGContext) {
        let locationsCount = 2
        let locations: [CGFloat] = [0.0, 1.0]
        let colors: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(
            colorSpace: colorSpace,
            colorComponents: colors,
            locations: locations,
            count: locationsCount
        )!

        let radius = min(bounds.size.width, bounds.size.height)
        context.drawRadialGradient(
            gradient,
            startCenter: gradientCenter,
            startRadius: 0,
            endCenter: gradientCenter,
            endRadius: radius,
            options: .drawsAfterEndLocation
        )
    }
}
