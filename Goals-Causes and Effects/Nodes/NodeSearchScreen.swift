//
//  NodeSearchScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct NodeSearchScreen: View {
  enum Destination {
    case cause, effect
  }
  var destination: Destination
  var didSelectNode: (NodeData) -> Void

  @State private var search = ""

  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \NodeData.title, ascending: true)])
  private var nodes: FetchedResults<NodeData>

  @State private var selection: NodeData?

  var body: some View {
    NavigationView {
      VStack {
        TextField("Search Nodes", text: $search)
          .padding()

        List(nodes) { node in
          HStack {
            NodeCircle(node: node)
              .frame(width: 32, height: 32)

            Text(node.title)
          }
          .contentShape(Rectangle())
          .onTapGesture {
            selection = node
          }
        }
      }

      .toolbar {
        NavigationLink {
          AddNodeScreen()
        } label: {
          Image(systemName: "plus")
        }
      }

      .navigationTitle(destination == .cause ? "Add a Cause" : "Add an Effect")
      .navigationBarTitleDisplayMode(.inline)

      .onChange(of: selection) { newValue in
        guard let node = newValue else { return }
        didSelectNode(node)
      }
    }
  }
}
