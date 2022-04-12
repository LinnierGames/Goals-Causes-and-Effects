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
    Circle()
      .foregroundColor(Color(uiColor: node.color))
      .border(Color.gray.opacity(0.15))
  }
}
