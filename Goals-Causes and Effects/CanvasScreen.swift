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

class Draw: UIView {
  let path: UIBezierPath

  init(path: UIBezierPath) {
    self.path = path
    super.init(frame: .zero)

    // Create a CAShapeLayer
    let shapeLayer = CAShapeLayer()

    // The Bezier path that we made needs to be converted to
    // a CGPath before it can be used on a layer.
    shapeLayer.path = path.cgPath

    // apply other properties related to the path
    shapeLayer.strokeColor = UIColor.red.cgColor
    shapeLayer.fillColor = UIColor.white.cgColor
    shapeLayer.lineWidth = 1.0
    shapeLayer.position = CGPoint(x: 10, y: 10)

    // add the new layer to our custom view
    self.layer.addSublayer(shapeLayer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

class CanvasViewController: UIViewController {
  private let persistenceController = injectPresistenceStore()

  private lazy var animator = UIDynamicAnimator(referenceView: view)

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .blue

    let path1 = UIBezierPath()
    path1.move(to: CGPoint(x: 0, y: 200))
    path1.addLine(to: CGPoint(x: view.frame.midX, y: 400))
    path1.addLine(to: CGPoint(x: view.frame.maxX, y: 200))
    path1.addLine(to: CGPoint(x: view.frame.midX, y: -300))
    let pathView = Draw(path: path1)
    pathView.frame = view.bounds
    view.addSubview(pathView)

    let ctx = persistenceController.container.viewContext
    let request = NodeData.fetchRequest()
    let results = try! ctx.fetch(request)

//    let l = UILabel()
//    l.text = "Number of nodes: \(results.count)"


    let l = NodeView(node: results[0])
    l.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(l)
    let m = NodeView(node: results[1])
    m.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(m)

    let gravity = UIFieldBehavior.radialGravityField(position: view.center)
    gravity.addItem(l)
    gravity.addItem(m)
    gravity.minimumRadius = 900
    gravity.strength = 250
//    gravity.animationSpeed = 4
//    gravity.falloff

    l.frame.size = CGSize(width: 164, height: 164)
    l.frame.origin.x = 300
    m.frame.size = CGSize(width: 164, height: 164)
    m.frame.origin.x = view.frame.maxX - m.frame.width - 200
//    l.center = view.center

    let collision = UICollisionBehavior(items: [l, m])

//    path1.addLine(to: CGPoint(x: view.frame.maxX, y: 200))
    collision.addBoundary(withIdentifier: "Cat 1" as NSCopying, for: path1)

    let dl = UIDynamicItemBehavior(items: [l, m])
    dl.allowsRotation = false

    animator.addBehavior(gravity)
    animator.addBehavior(collision)
    animator.addBehavior(dl)

    NSLayoutConstraint.activate([
      l.heightAnchor.constraint(equalToConstant: 164),
      m.heightAnchor.constraint(equalToConstant: 164),
//      l.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//      l.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}

class NodeView: UIView {
  let node: NodeData

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.preferredFont(forTextStyle: .title3)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 2
    return label
  }()

  init(node: NodeData) {
    self.node = node
    super.init(frame: .zero)
    setupView()
    updateUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    layer.cornerRadius = min(bounds.width / 2, bounds.height / 2)
  }

  private func setupView() {
    addSubview(titleLabel)

    let padding: CGFloat = 16

    NSLayoutConstraint.activate([

      // Title label
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
      trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: padding),
      bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding),

      // Keep self as a square
      heightAnchor.constraint(equalTo: widthAnchor),
    ])

    backgroundColor = .lightGray
  }

  private func updateUI() {
    titleLabel.text = node.title
  }
}
