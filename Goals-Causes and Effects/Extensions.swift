//
//  Extensions.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import UIKit

extension UIColor {
  convenience init?(hex: String) {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
      cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
      return nil
    }

    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    self.init(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: CGFloat(1.0)
    )
  }

  var hex: String? {
    guard let components = self.cgColor.components, components.count == 4 else { return nil }

    let r = components[0]
    let g = components[1]
    let b = components[2]

    return String(
      format: "#%02lX%02lX%02lX",
      lroundf(Float(r * 255)),
      lroundf(Float(g * 255)),
      lroundf(Float(b * 255))
    )
  }
}

import SwiftUI

extension View {
  @ViewBuilder
  func `if`<T>(_ condition: Bool, transform: (Self) -> T) -> some View where T: View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

extension Identifiable where Self: RawRepresentable, RawValue == Int {
  var id: Int {
    self.rawValue
  }
}

extension String {
  init(effect: Double) {
    self = String(effect) + "x"
  }
}

struct DismissKeyboard<Label: View>: View {
  var label: Label

  init(@ViewBuilder label: () -> Label) {
    self.label = label()
  }

  init() where Label == Text {
    self.label = Text("Dismiss")
  }

  var body: some View {
    Button {
      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    } label: {
      label
    }
  }
}

struct DismissKeyboard_Previews: PreviewProvider {
  static var previews: some View {
    DismissKeyboard()
  }
}
