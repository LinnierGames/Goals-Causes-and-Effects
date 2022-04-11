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

  @State var selection: String?

  var items = ["A", "B"]

  var body: some View {
    VStack {
      Text("HI")
      List(nodes, id: \.title) { node in
        NavigationLink {
          NodeDetailScreen(node: node)
        } label: {
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

    .if(UIDevice.current.userInterfaceIdiom == .phone) { view in
      view
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

struct NodeDetailScreen: View {
  @ObservedObject var node: NodeData
  var breadCrumbsOfNodes = [NodeData]()

  private enum SegmentedControl: Int, Identifiable {
    case causes, effects, initiatives
  }
  @State private var segmentedControl = SegmentedControl.causes
  @State private var isShowingAddNode = false
  @State private var presentEffection: EffectionData?

  var body: some View {
    VStack {
      let breadcrumbs = breadCrumbsOfNodes
        .map { String($0.title!.first!) }
        .joined(separator: " -> ")
      Text(breadcrumbs)

      Circle()
        .foregroundColor(.green)
        .frame(height: 232)
        .padding(.vertical, 16)

      HStack {
        Picker(selection: $segmentedControl) {
          Text("Causes")
            .tag(SegmentedControl.causes)
          Text("Effects")
            .tag(SegmentedControl.effects)
          Text("initiatives")
            .tag(SegmentedControl.initiatives)
        } label: {
          EmptyView()
        }
        .pickerStyle(SegmentedPickerStyle())

        Button(action: pressAdd) {
          Image(systemName: "plus")
        }
      }

      List {
        switch segmentedControl {
        case .causes:
          ForEach(node.listOfCauses) { cause in
            let node = cause.cause!

            NavigationLink {
              NodeDetailScreen(node: node, breadCrumbsOfNodes: breadCrumbsOfNodes + [self.node])
            } label: {
              HStack {
                VStack {
                  Text(node.title!)
                  Rectangle()
                    .foregroundColor(.green)
                }

                Button {
                } label: {
                  VStack {
                    Image(systemName: "arrow.right.square")
                    Text(String(effect: Int(cause.effect)))
                  }
                  .foregroundColor(cause.effect >= 0 ? .green : .red)
                }
                .onTapGesture {
                  presentEffection = cause
                }
              }
            }
          }
        case .effects:
          ForEach(node.listOfEffects) { effect in
            let node = effect.effected!

            NavigationLink {
              NodeDetailScreen(node: node, breadCrumbsOfNodes: breadCrumbsOfNodes + [self.node])
            } label: {
              HStack {
                Button {
                } label: {
                  VStack {
                    Image(systemName: "arrow.right.square")
                    Text(String(effect: Int(effect.effect)))
                  }
                  .foregroundColor(effect.effect >= 0 ? .green : .red)
                }
                .onTapGesture {
                  presentEffection = effect
                }

                VStack {
                  Text(node.title!)
                  Rectangle()
                    .foregroundColor(.green)
                }
              }
            }
          }
        case .initiatives:
          Text("initiatives")
        }
      }
    }
    .padding(.horizontal)

    .navigationTitle(node.title!)

    .sheet(isPresented: $isShowingAddNode) {
      NodeSearchScreen(
        destination: segmentedControl == .causes ? .cause : .effect,
        didSelectNode: { node in
          isShowingAddNode = false

          let store = injectPresistenceStore()
          let effection = EffectionData(context: store.container.viewContext)
          effection.effect = 1

          switch segmentedControl {
          case .causes:
            self.node.addToCauses(effection)
            node.addToEffects(effection)
          case .effects:
            self.node.addToEffects(effection)
            node.addToCauses(effection)
          case .initiatives:
            break
          }

          store.saveContext()
        }
      )
    }
    .sheet(item: $presentEffection) { effection in
      EffectionDetailScreen(effection: effection)
    }
  }

  private func pressAdd() {
    isShowingAddNode = true
  }
}

struct EffectionDetailScreen: View {
  var effection: EffectionData

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      VStack {
        Text(effection.cause!.title!)
        Circle()
          .foregroundColor(.green)
          .frame(width: 232, height: 232)
        Spacer()
        Text(String(effection.effect))
        Spacer()
        Circle()
          .foregroundColor(.green)
          .frame(width: 232, height: 232)
        Text(effection.effected!.title!)
      }
      .padding()

      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: dismiss.callAsFunction) {
            Image(systemName: "checkmark")
          }
        }
      }
    }
  }
}

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
            Circle()
              .foregroundColor(.green)
              .frame(width: 32, height: 32)

            Text(node.title!)
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

  private func pressAdd() {

  }
}

struct AddNodeScreen: View {
  @State private var title = ""

  private enum Impact: Int, Identifiable {
    case good, bad
  }
  @State private var impact = Impact.good
  @State private var initalValue: Double = 0.5

  @Environment(\.dismiss) var dismiss

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
        Text("None")
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
    store.newNode(title: title, isGood: impact == .good, initialValue: initalValue)
    dismiss()
  }
}

extension String {
  init(effect: Int) {
    self = String(effect) + "x"
  }
}

//import CoreData
//
//struct MyPreview: PreviewProvider {
//  static let data: NodeData = {
//    let data = NodeData(context: NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))
//    data.title = "Hello"
//    return data
//  }()
//
//  static var previews: some View {
//    NodeDetailScreen(node: data)
//  }
//}
