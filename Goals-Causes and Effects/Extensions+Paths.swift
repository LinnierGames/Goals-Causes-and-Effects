//
//  Extensions+Paths.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/20/22.
//

import UIKit

extension UIBezierPath {

  class func arrow(
    from start: CGPoint,
    to end: CGPoint,
    tailWidth: CGFloat,
    headWidth: CGFloat,
    headLength: CGFloat
  ) -> Self {
    let nodeRadius = sizeOfNodes / 2 - 12

    func offsetPoint(s: CGPoint, e: CGPoint, center: CGPoint) -> CGPoint {
      let opposite = e.y - s.y
      let adjacent = e.x - s.x
      let referenceAngle = atan2(opposite, adjacent)

      let x = center.x + cos(referenceAngle) * nodeRadius
      let y = center.y + sin(referenceAngle) * nodeRadius

      return CGPoint(x: x, y: y)
    }

    let offsettedStart = offsetPoint(s: start, e: end, center: start)
    let offsetedEnd = offsetPoint(s: end, e: start, center: end)

    let length = hypot(offsetedEnd.x - offsettedStart.x, offsetedEnd.y - offsettedStart.y)
    let tailLength = length - headLength

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { return CGPoint(x: x, y: y) }
    let points: [CGPoint] = [
      p(0, tailWidth / 2),
      p(tailLength, tailWidth / 2),
      p(tailLength, headWidth / 2),
      p(length, 0),
      p(tailLength, -headWidth / 2),
      p(tailLength, -tailWidth / 2),
      p(0, -tailWidth / 2)
    ]

    let cosine = (offsetedEnd.x - offsettedStart.x) / length
    let sine = (offsetedEnd.y - offsettedStart.y) / length
    let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: offsettedStart.x, ty: offsettedStart.y)

    let path = CGMutablePath()
    path.addLines(between: points, transform: transform)
    path.closeSubpath()

    return self.init(cgPath: path)
  }

}
