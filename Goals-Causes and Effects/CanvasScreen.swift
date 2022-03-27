//
//  CanvasScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 3/27/22.
//

import UIKit
import SwiftUI

struct CanvasScreen: View {
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \NodeData.title, ascending: true)])
  var nodes: FetchedResults<NodeData>

  var body: some View {
//    Canvas { context, size in
//      let n = nodes.count
//      context.stroke(
//          Path(ellipseIn: CGRect(origin: .zero, size: size)),
//          with: .color(.green),
//          lineWidth: 4)
//      context.draw(Text("Number of nodes: \(n)"), at: CGPoint(x: size.width / 2, y: size.height / 2))
//    }

//    GeometryReader { proxy in
      CanvasView()
//    }
  }
}

struct CanvasView: UIViewControllerRepresentable {
  func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {
  }

  func makeUIViewController(context: Context) -> CanvasViewController {
    return CanvasViewController()
  }
}

class CanvasViewController: UIViewController {
  private let persistenceController = injectPresistenceStore()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .blue

    let ctx = persistenceController.container.viewContext
    let request = NodeData.fetchRequest()
    let results = try! ctx.fetch(request)

    let l = UILabel()
    l.text = "Number of nodes: \(results.count)"
    l.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(l)

    NSLayoutConstraint.activate([
      l.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      l.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
