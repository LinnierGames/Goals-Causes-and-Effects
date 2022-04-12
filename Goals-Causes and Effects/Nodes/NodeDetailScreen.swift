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
  @State private var presentEffection: EffectionData?

  var body: some View {
    VStack {
      let breadcrumbs = breadCrumbsOfNodes
        .map { String($0.title.first!) }
        .joined(separator: " -> ")
      Text(breadcrumbs)

      NodeCircle(node: node)
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

struct CauseRow<Destination: View>: View {
  @ObservedObject var cause: EffectionData
  @ViewBuilder var destination: () -> Destination
  var didTapEffection: (EffectionData) -> Void

  var body: some View {
    let node = cause.cause!

    NavigationLink(destination: destination) {
      HStack {
        VStack {
          Text(node.title)
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
          didTapEffection(cause)
        }
      }
    }
  }
}

struct EffectRow<Destination: View>: View {
  @ObservedObject var effect: EffectionData
  @ViewBuilder var destination: () -> Destination
  var didTapEffection: (EffectionData) -> Void

  var body: some View {
    let node = effect.effected!

    NavigationLink(destination: destination) {
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
          didTapEffection(effect)
        }

        VStack {
          Text(node.title)
          Rectangle()
            .foregroundColor(.green)
        }
      }
    }
  }
}
