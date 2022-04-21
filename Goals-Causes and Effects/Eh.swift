//
//  Eh.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/20/22.
//

import UIKit

class Draw: UIView {
  let path: UIBezierPath

  init(path: UIBezierPath) {
    self.path = path
    super.init(frame: .zero)

    // Create a CAShapeLayer
    let shapeLayer = CAShapeLayer()

    // The Bezier path that we made needs to be converted to
    // a CGPath before it can be used on a layer.
    shapeLayer.path = path.cgPath

    // apply other properties related to the path
    shapeLayer.strokeColor = UIColor.red.cgColor
    shapeLayer.fillColor = UIColor.white.cgColor
    shapeLayer.lineWidth = 1.0
//    shapeLayer.position = CGPoint(x: 10, y: 10)

    // add the new layer to our custom view
    self.layer.addSublayer(shapeLayer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
