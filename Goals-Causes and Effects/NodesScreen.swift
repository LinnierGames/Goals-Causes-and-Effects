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
    NavigationView {
      List {
        ForEach(nodes, id: \.title) { node in
          NavigationLink {
            NodeDetailScreen(node: node)
          } label: {
            VStack(alignment: .leading) {
              HStack {
                NodeCircle(node: node)
                  .frame(width: 32, height: 32)
                Text(node.title)
              }

              Text("Causes")
                .font(.caption)
              Group {
                if node.listOfCauses2.isEmpty {
                  Text("<empty>")
                    .font(.caption)
                } else {
                  ForEach(Array(node.listOfCauses2), id: \.title) { cause in
                    Text(cause.title)
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
                    Text(effect.title)
                      .font(.caption)
                  }
                }
              }
              .padding(.leading)
            }
          }
        }.onDelete { offsets in
          let store = injectPresistenceStore()
          offsets.map { nodes[$0] }.forEach(store.container.viewContext.delete)
          store.saveContext()
        }
      }
      .navigationTitle("Nodes")

      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          NavigationLink {
            AddNodeScreen()
          } label: {
            Image(systemName: "plus")
          }
          NavigationLink(destination: { CanvasScreen() }, label: { Text("Picture") })
        }
      }
    }
  }
}
