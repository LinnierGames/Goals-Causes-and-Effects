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
  @State private var notes = ""

  private enum Impact: Int, Identifiable {
    case good, bad
  }
  @State private var impact = Impact.good
  @State private var category: CategoryData?
  @State private var initalValue: Double = 0.5

  @Environment(\.dismiss) var dismissEnvironment
  var dismiss: () -> Void

  init(didCreateNode: @escaping (NodeData) -> Void = { _ in }, dismiss: (() -> Void)? = nil) {
    self.node = nil
    self.didCreateNode = didCreateNode
    self.dismiss = dismiss ?? {}
  }

  init(editNode: NodeData, dismiss: (() -> Void)? = nil) {
    self.node = editNode
    self.didCreateNode = { _ in }
    self._title = State(initialValue: editNode.title)
    self._notes = State(initialValue: editNode.notes)
    self._impact = State(initialValue: editNode.color == .green ? .good : .bad)
    self._initalValue = State(initialValue: editNode.initialValue)
    self._category = State(initialValue: editNode.category)
    self.dismiss = dismiss ?? {}
  }

  var body: some View {
    VStack {
      HStack {
        Text("Title")
        TextField("title", text: $title)
          .multilineTextAlignment(.trailing)
      }

      HStack {
        Text("Inital value")
        Spacer()
        Text(initalValue, format: .percent)
      }
      Slider(value: $initalValue, in: 0...1)

      VStack {
        HStack {
          Text("Notes")
          Spacer()
          DismissKeyboard()
        }
        TextEditor(text: $notes)
          .frame(height: 96)
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

//      NodeCircle(node: node)
      Circle()
        .foregroundColor(impact == .good ? .green : .red)
        .frame(width: 132, height: 132)
    }
    .padding()

    .navigationBarBackButtonHidden(true)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          dismiss()
          dismissEnvironment()
        } label: {
          Image(systemName: "xmark")
        }
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: pressSave) {
          Image(systemName: "checkmark")
        }
      }
    }

    .ignoresSafeArea(.keyboard)
  }

  private func pressSave() {
    let store = injectPresistenceStore()

    if let node = node {
      node.title = title
      node.notes = notes
      node.color = impact == .good ? .green : .red
      node.initialValue = initalValue
      node.category = category
      store.saveContext()
    } else {
      let node = store.newNode(
        title: title,
        notes: notes,
        isGood: impact == .good,
        initialValue: initalValue,
        category: category
      )
      didCreateNode(node)
    }

    dismiss()
    dismissEnvironment()
  }
}

class EditNodeViewController: UIHostingController<AnyView> {
  init(node: NodeData) {
    var vc: UIViewController! = nil
    let dismiss = {
      vc.dismiss(animated: true)
    }

    let rootView = AddNodeScreen(editNode: node, dismiss: dismiss)
      .environment(\.managedObjectContext, injectPresistenceStore().container.viewContext)
    super.init(rootView: AnyView(rootView))
    vc = self
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
