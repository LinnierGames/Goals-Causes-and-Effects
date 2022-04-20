//
//  AddNodeScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct AddNodeScreen: View {
  var node: NodeData?
  var didCreateNode: (NodeData) -> Void

  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CategoryData.title, ascending: true)])
  private var categories: FetchedResults<CategoryData>

  @State private var title = ""

  private enum Impact: Int, Identifiable {
    case good, bad
  }
  @State private var impact = Impact.good
  @State private var category: CategoryData?
  @State private var initalValue: Double = 0.5

  @Environment(\.dismiss) var dismiss

  init(didCreateNode: @escaping (NodeData) -> Void = { _ in }) {
    self.node = nil
    self.didCreateNode = didCreateNode
  }

  init(editNode: NodeData) {
    self.node = editNode
    self.didCreateNode = { _ in }
    self._title = State(initialValue: editNode.title)
    self._impact = State(initialValue: editNode.color == .green ? .good : .bad)
    self._initalValue = State(initialValue: editNode.initialValue)
    self._category = State(initialValue: editNode.category)
  }

  var body: some View {
    VStack {
      HStack {
        Text("Title")
        TextField("title", text: $title)
          .multilineTextAlignment(.trailing)
      }

      HStack {
        Text("Category")
        Spacer()
        Picker(selection: $category) {
          Text("None")
            .tag(nil as CategoryData?)
          ForEach(categories) { category in
            Text(category.title)
              .tag(category as CategoryData?)
          }
        } label: {
          EmptyView()
        }
      }

      Picker(selection: $impact) {
        Text("Good")
          .tag(Impact.good)
        Text("Bad")
          .tag(Impact.bad)
      } label: {
        EmptyView()
      }
      .pickerStyle(SegmentedPickerStyle())

      Spacer()

      Circle()
        .foregroundColor(impact == .good ? .green : .red)
        .frame(width: 232, height: 232)
    }
    .padding()

    .navigationBarBackButtonHidden(true)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: dismiss.callAsFunction) {
          Image(systemName: "xmark")
        }
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: pressSave) {
          Image(systemName: "checkmark")
        }
      }
    }
  }

  private func pressSave() {
    let store = injectPresistenceStore()

    if let node = node {
      node.title = title
      node.color = impact == .good ? .green : .red
      node.initialValue = initalValue
      node.category = category
      store.saveContext()
    } else {
      let node = store.newNode(
        title: title,
        isGood: impact == .good,
        initialValue: initalValue,
        category: category
      )
      didCreateNode(node)
    }

    dismiss()
  }
}
