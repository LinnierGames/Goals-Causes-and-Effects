//
//  NodeCircle.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct NodeCircle: View {
  @ObservedObject var node: NodeData
  var showValue = false

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        let value = node.value

        VStack(spacing: 0) {
          let offHeight = (1 - value) * proxy.size.height
          let onHeight = value * proxy.size.height

          Rectangle()
            .frame(width: proxy.size.width, height: offHeight)
            .foregroundColor(.clear)
          Rectangle()
            .frame(width: proxy.size.width, height: onHeight)
            .foregroundColor(Color(uiColor: node.color))
        }

        if showValue {
          Text(value, format: .percent)
        }
      }
      .clipShape(Circle())
    }
  }
}
