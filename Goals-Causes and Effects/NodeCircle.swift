//
//  NodeCircle.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct NodeCircle: View {
  @ObservedObject var node: NodeData

  var body: some View {
    GeometryReader { proxy in
      VStack(spacing: 0) {
        let value = node.value
        let offHeight = (1 - value) * proxy.size.height
        let onHeight = value * proxy.size.height

        Rectangle()
          .frame(width: proxy.size.width, height: offHeight)
          .foregroundColor(.clear)
        Rectangle()
          .frame(width: proxy.size.width, height: onHeight)
          .foregroundColor(Color(uiColor: node.color))
      }
      .clipShape(Circle())
    }
  }
}
