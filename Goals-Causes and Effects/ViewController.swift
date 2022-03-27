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

    let ps = injectPresistenceStore()
    let ctx = ps.container.viewContext

//    let happinessTogether = NodeData(context: ctx)
//    happinessTogether.title = "Happiness Together"
//
//    let communicateEasilyEffectOnHappinessTogether =
//      EffectionData(context: ctx)
//
//    let communicateEasily = NodeData(context: ctx)
//    communicateEasily.title = "Communicate Easily"
//
//    communicateEasilyEffectOnHappinessTogether.cause =
//      communicateEasily
//    communicateEasilyEffectOnHappinessTogether.effected =
//      happinessTogether
//    communicateEasilyEffectOnHappinessTogether.effect = 4
//
//    ps.saveContext()
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

struct ContentView: View {
  private let persistenceController = injectPresistenceStore()

  var body: some View {
    NavigationView {
      NodesScreen()
      CanvasScreen()
    }
    .environment(\.managedObjectContext, persistenceController.container.viewContext)
  }
}
