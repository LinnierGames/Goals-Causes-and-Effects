//
//  ViewController.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 3/26/22.
//

import UIKit
import SwiftUI

class ViewController: UIHostingController<ContentView> {

  init() {
    super.init(rootView: ContentView())
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

struct ContentView: View {
  private let persistenceController = injectPresistenceStore()

  var body: some View {
//    NavigationView {
      TabView {
        NodesScreen()
          .tabItem {
            Image(systemName: "1.square.fill")
            Text("Nodess")
          }

        CategoriesScreen()
          .tabItem {
            Image(systemName: "1.square.fill")
            Text("Categories")
          }
      }
//      CanvasScreen()
//    }
    .environment(\.managedObjectContext, persistenceController.container.viewContext)
  }
}
