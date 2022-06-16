//
//  Helpers.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 6/16/22.
//

import Foundation
import UIKit

extension UIColor {
  convenience init(effection: EffectionData) {
    if effection.effect >= 0 {
      self.init(red: 0, green: 1, blue: 0, alpha: 1)
    } else {
      self.init(red: 1, green: 0, blue: 0, alpha: 1)
    }
  }
}

extension CGFloat {
  init(effection: EffectionData) {
    self = abs(CGFloat(effection.effect))
  }
}

public func pointsOnCircleFor(numberOfPoints: Int, centerX: CGFloat, centerY: CGFloat, radius: CGFloat, precision: UInt = 3) -> [CGPoint] {
  var points = [CGPoint]()
  let angle = CGFloat(M_PI) / CGFloat(numberOfPoints) * 2.0
  let p = CGFloat(pow(10.0, Double(precision)))

  for i in 0..<numberOfPoints {
    let x = centerX - radius * cos(angle * CGFloat(i))
    let roundedX = Double(round(p * x)) / Double(p)
    let y = centerY - radius * sin(angle * CGFloat(i))
    let roundedY = Double(round(p * y)) / Double(p)
    points.append(CGPoint(x: roundedX, y: roundedY))
  }

  print(points)
  return points
}
