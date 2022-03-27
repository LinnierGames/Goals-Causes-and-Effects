//
//  NodesScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 3/27/22.
//

import SwiftUI

struct NodesScreen: View {
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \NodeData.title, ascending: true)])
  var nodes: FetchedResults<NodeData>

  var body: some View {
    Text("HI")
    List(nodes, id: \.title) { node in
      VStack(alignment: .leading) {
        Text(node.title!)

        Text("Causes")
          .font(.caption)
        Group {
          if node.listOfCauses2.isEmpty {
            Text("<empty>")
              .font(.caption)
          } else {
            ForEach(Array(node.listOfCauses2), id: \.title) { cause in
              Text(cause.title!)
                .font(.caption)
            }
          }
        }
        .padding(.leading)

        Text("Effects")
          .font(.caption)
        Group {
          if node.listOfEffects2.isEmpty {
            Text("<empty>")
              .font(.caption)
          } else {
            ForEach(Array(node.listOfEffects2), id: \.title) { effect in
              Text(effect.title!)
                .font(.caption)
            }
          }
        }
        .padding(.leading)
      }
    }
  }
}
