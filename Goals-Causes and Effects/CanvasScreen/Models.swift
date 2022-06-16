//
//  Models.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 6/16/22.
//

import Foundation
import UIKit

struct Arrow {
  let a: CGPoint
  let b: CGPoint
  let color: UIColor
  let width: CGFloat
}

struct HashablePair<Element: Hashable>: Hashable {
  let a: Element
  let b: Element

  func hash(into hasher: inout Hasher) {
    hasher.combine(a)
    hasher.combine(b)
  }
}
