//
//  NodeDetailScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct NodeDetailScreen: View {
  @ObservedObject var node: NodeData
  var breadCrumbsOfNodes = [NodeData]()

  private enum SegmentedControl: Int, Identifiable {
    case causes, effects, initiatives
  }
  @State private var segmentedControl = SegmentedControl.causes
  @State private var isShowingAddNode = false
  @State private var isShowingEdit = false
  @State private var isShowingCreateNode = false
  @State private var presentEffection: EffectionData?
  @State private var updater = false

  var body: some View {
    VStack {
      let breadcrumbs = breadCrumbsOfNodes
        .map { String($0.title.first!) }
        .joined(separator: " -> ")
      Text(breadcrumbs)

      NodeCircle(node: node)
        .frame(height: 232)

      Image(systemName: "arrow.up")
        .font(.system(size: 96, weight: .bold))
        .rotationEffect(.degrees(segmentedControl == .causes ? 0 : 180))
        .animation(.spring(response: 0.2, dampingFraction: 0.3, blendDuration: 1), value: segmentedControl)

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

        Menu {
          Button {
            isShowingAddNode = true
          } label: {
            Label("Add Node", systemImage: "plus")
          }
          Button {
            isShowingCreateNode = true
          } label: {
            Label("Create a New Node", systemImage: "plus")
          }
        } label: {
          Image(systemName: "plus")
        }
      }

      List {
        switch segmentedControl {
        case .causes:
          ForEach(node.listOfCauses) { cause in
            CauseRow(cause: cause) {
              NodeDetailScreen(
                node: cause.cause, breadCrumbsOfNodes: breadCrumbsOfNodes + [self.node]
              )
            } didTapEffection: { effection in
              presentEffection = effection
            }
          }
        case .effects:
          ForEach(node.listOfEffects) { effect in
            EffectRow(effect: effect) {
              NodeDetailScreen(
                node: effect.effected, breadCrumbsOfNodes: breadCrumbsOfNodes + [self.node]
              )
            } didTapEffection: { effection in
              presentEffection = effection
            }
          }
        case .initiatives:
          Text("initiatives")
        }
      }
    }
    .padding(.horizontal)

    .navigationTitle(node.title)
    .toolbar {
      Button("Edit") {
        isShowingEdit = true
      }
    }

    .sheet(isPresented: $isShowingEdit) {
      NavigationView {
        AddNodeScreen(editNode: node)
      }
    }
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
    .sheet(isPresented: $isShowingCreateNode) {
      switch segmentedControl {
      case .causes:
        NavigationView {
          AddNodeScreen { node in
            let store = injectPresistenceStore()
            let effection = EffectionData(context: store.container.viewContext)
            effection.effect = 1

            self.node.addToCauses(effection)
            node.addToEffects(effection)
          }
        }
      case .effects:
        NavigationView {
          AddNodeScreen { node in
            let store = injectPresistenceStore()
            let effection = EffectionData(context: store.container.viewContext)
            effection.effect = 1

            self.node.addToEffects(effection)
            node.addToCauses(effection)
          }
        }
      case .initiatives:
        EmptyView()
      }
    }
  }
}

struct CauseRow<Destination: View>: View {
  @ObservedObject var cause: EffectionData
  @ViewBuilder var destination: () -> Destination
  var didTapEffection: (EffectionData) -> Void

  var body: some View {
    if cause.isDeleted {
      EmptyView()
    } else {
      let node = cause.cause!
      NavigationLink(destination: destination) {
        HStack {
          VStack {
            Text(node.title)
            Rectangle()
              .foregroundColor(Color(uiColor: node.color))
          }

          Button {
          } label: {
            VStack {
              Image(systemName: "arrow.right")
  //              .arrowThickness(effection: cause)
              Text(String(effect: cause.effect))
            }
            .foregroundColor(cause.effect >= 0 ? .green : .red)
          }
          .onTapGesture {
            didTapEffection(cause)
          }
        }
      }.swipeActions {
        Button {
          let store = injectPresistenceStore()
          store.container.viewContext.delete(node)
          store.saveContext()
        } label: {
          Image(systemName: "trash")
        }.tint(.red)

        Button {
          let store = injectPresistenceStore()
          store.container.viewContext.delete(cause)
          store.saveContext()
        } label: {
          Image(systemName: "circle.slash")
        }.tint(.yellow)
      }
    }
  }
}

struct EffectRow<Destination: View>: View {
  @ObservedObject var effect: EffectionData
  @ViewBuilder var destination: () -> Destination
  var didTapEffection: (EffectionData) -> Void

  var body: some View {
    if effect.isDeleted {
      EmptyView()
    } else {
      let node = effect.effected!
      NavigationLink(destination: destination) {
        HStack {
          Button {
          } label: {
            VStack {
              Image(systemName: "arrow.right")
  //              .arrowThickness(effection: effect)
              Text(String(effect: effect.effect))
            }
            .foregroundColor(effect.effect >= 0 ? .green : .red)
          }
          .onTapGesture {
            didTapEffection(effect)
          }

          VStack {
            Text(node.title)
            Rectangle()
              .foregroundColor(Color(uiColor: node.color))
          }
        }
      }.swipeActions {
        Button {
          let store = injectPresistenceStore()
          store.container.viewContext.delete(node)
          store.saveContext()
        } label: {
          Image(systemName: "trash")
        }.tint(.red)

        Button {
          let store = injectPresistenceStore()
          store.container.viewContext.delete(effect)
          store.saveContext()
        } label: {
          Image(systemName: "circle.slash")
        }.tint(.yellow)
      }
    }
  }
}
