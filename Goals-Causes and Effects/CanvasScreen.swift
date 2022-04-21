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
    CanvasView()
  }
}

struct CanvasView: UIViewControllerRepresentable {
  func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {
  }

  func makeUIViewController(context: Context) -> CanvasViewController {
    return CanvasViewController()
  }
}

struct Arrow {
  let a: CGPoint
  let b: CGPoint
  let color: UIColor
  let width: CGFloat
}

let sizeOfNodes: CGFloat = 96

import CoreData

class CanvasViewController: UIViewController {
  private let drawEffectionsView = DrawEffections()
  private let drawPie = DrawPie()

  private let persistenceController = injectPresistenceStore()

  private lazy var animator = UIDynamicAnimator(referenceView: view)

  var tableOfNodeViews = [NSManagedObjectID: NodeView]()

  override func viewDidLoad() {
    super.viewDidLoad()

    drawEffectionsView.frame = view.bounds
    drawEffectionsView.isUserInteractionEnabled = false
    view.addSubview(drawEffectionsView)
    drawPie.frame = view.bounds
    drawPie.isUserInteractionEnabled = false
    view.addSubview(drawPie)

    spawnNodes()
    spawnCategoriesAndNodes()
  }

  var nodesToCreate = [NodeData]()

  let collision = UICollisionBehavior()

  let preventRotation: UIDynamicItemBehavior = {
    let behavior = UIDynamicItemBehavior()
    behavior.allowsRotation = false
    return behavior
  }()

  lazy var gravity: UIFieldBehavior = {
    let behavior = UIFieldBehavior.radialGravityField(position: view.center)
    behavior.minimumRadius = 900
    behavior.strength = 250
    return behavior
  }()

  private func spawnCategoriesAndNodes() {
    let ctx = persistenceController.container.viewContext
    let request = CategoryData.fetchRequest()
    let categories = try! ctx.fetch(request).shuffled()

    drawPie.categories = categories

    let nodes = categories.map { (category: $0, nodes: $0.listOfNodes) }

    let pi = Double.pi
    let bounds = view.bounds
    let largestRadius = max(bounds.width, bounds.height) / 2

    for (index, node) in nodes.enumerated() {
      let piePath = UIBezierPath()
      let startAngle = Double(index) / Double(nodes.count) * 2 * pi
      let endAngle = Double(index+1) / Double(nodes.count) * 2 * pi
      let thisRadius = largestRadius
      let center = CGPoint(x: bounds.width/2, y: bounds.height/2 - 96)
      piePath.move(to: center)

      piePath.addArc(withCenter: center,
        radius: thisRadius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: true)
      piePath.addLine(to: center)
      piePath.close()
      collision.addBoundary(withIdentifier: String(index) as NSCopying, for: piePath)
    }
  }

  private func spawnNodes() {
    let ctx = persistenceController.container.viewContext
    let request = NodeData.fetchRequest()
    nodesToCreate = try! ctx.fetch(request).shuffled()

//    nodesToCreate = nodesToCreate + nodesToCreate + nodesToCreate

    tableOfNodeViews.removeAll()
    makeNextNode()

    animator.addBehavior(gravity)
    animator.addBehavior(collision)
    animator.addBehavior(preventRotation)
  }

  private func makeNextNode() {
    let spawnPoint = UIDevice.current.userInterfaceIdiom == .pad
      ? CGPoint(x: 200, y: 0)
      : CGPoint(x: view.frame.midX + .random(in: -200..<200), y: view.frame.minY)
    let spawnDelay: TimeInterval = 1

    guard !nodesToCreate.isEmpty else {
      return
    }

    let node = nodesToCreate.removeLast()

    let nodeView = NodeView(node: node)
    nodeView.translatesAutoresizingMaskIntoConstraints = false
    nodeView.frame.size = CGSize(width: sizeOfNodes, height: sizeOfNodes)
    nodeView.frame.origin = spawnPoint
    view.insertSubview(nodeView, belowSubview: drawEffectionsView)

    NSLayoutConstraint.activate([
      nodeView.heightAnchor.constraint(equalToConstant: sizeOfNodes),
    ])

    gravity.addItem(nodeView)
    collision.addItem(nodeView)
    preventRotation.addItem(nodeView)

    let didTapGesture =
    UITapGestureRecognizer(target: self, action: #selector(didTapNodeView(gesture:)))
    nodeView.addGestureRecognizer(didTapGesture)

    tableOfNodeViews[node.objectID] = nodeView

    DispatchQueue.main.asyncAfter(deadline: .now() + spawnDelay) { [weak self] in
      self?.makeNextNode()
    }
  }

  @objc private func didTapNodeView(gesture: UITapGestureRecognizer) {
    guard let nodeView = gesture.view as? NodeView else { fatalError("not a node view") }
    drawEffections(for: nodeView)
  }

  func drawEffections(for nodeView: NodeView) {
    let node = nodeView.node

    var arrows = [Arrow]()
    var queue = [EffectionData]()
    queue.append(contentsOf: node.listOfEffects)
    queue.append(contentsOf: node.listOfCauses)

    var visited = Set<HashablePair<NSManagedObjectID>>()
    while !queue.isEmpty {
      let effection = queue.removeLast()
      let pair = HashablePair(a: effection.cause!.objectID, b: effection.effected!.objectID)

      guard !visited.contains(pair) else { continue }
      visited.insert(pair)

      guard
        let causeNodeView = tableOfNodeViews[effection.cause!.objectID],
        let effectedNodeView = tableOfNodeViews[effection.effected!.objectID]
      else {
        continue
      }

      let arrow = Arrow(
        a: causeNodeView.center,
        b: effectedNodeView.center,
        color: UIColor(effection: effection), width: CGFloat(effection: effection)
      )

      arrows.append(arrow)
//      queue.append(contentsOf: effection.effected!.listOfEffects)
    }

    drawEffectionsView.arrows = arrows
  }
}

struct HashablePair<Element: Hashable>: Hashable {
  let a: Element
  let b: Element

  func hash(into hasher: inout Hasher) {
    hasher.combine(a)
    hasher.combine(b)
  }
}

class DrawEffections: UIView {
  var arrows = [Arrow]() {
    didSet {
      updateUI()
    }
  }

  private func updateUI() {
    layer.sublayers?.removeAll()

    for arrow in arrows {
      // Create a CAShapeLayer
      let shapeLayer = CAShapeLayer()

      // The Bezier path that we made needs to be converted to
      // a CGPath before it can be used on a layer.
      let scale: CGFloat = 10
      let arrowPath = UIBezierPath.arrow(
        from: arrow.a, to: arrow.b,
        tailWidth: arrow.width * scale, headWidth: arrow.width * scale,
        headLength: arrow.width * scale / 2
      )
      shapeLayer.path = arrowPath.cgPath

      // apply other properties related to the path
//      shapeLayer.strokeColor = UIColor.red.cgColor
      shapeLayer.fillColor = arrow.color.cgColor
//      shapeLayer.lineWidth = 1.0
      shapeLayer.frame = layer.bounds

      // add the new layer to our custom view
      self.layer.addSublayer(shapeLayer)
    }
  }

}

class DrawPie: UIView {
  var categories = [CategoryData]() {
    didSet {
      updateUI()
    }
  }

  private func updateUI() {
    layer.sublayers?.removeAll()

    let pi = Double.pi
    let largestRadius = max(bounds.width, bounds.height) / 2

    let nodes = categories.map { (category: $0, nodes: $0.listOfNodes) }

    for (index, node) in nodes.enumerated() {
      let piePath = UIBezierPath()
      let startAngle = Double(index) / Double(nodes.count) * 2 * pi
      let endAngle = Double(index+1) / Double(nodes.count) * 2 * pi
      let thisRadius = largestRadius
      let center = CGPoint(x: bounds.width/2, y: bounds.height/2 - 96)
      piePath.move(to: center)

      piePath.addArc(withCenter: center,
        radius: thisRadius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: true)
      piePath.addLine(to: center)
      piePath.close()

      let shapeLayer = CAShapeLayer()
      shapeLayer.path = piePath.cgPath

      // apply other properties related to the path
      shapeLayer.fillColor = UIColor.clear.cgColor
      shapeLayer.strokeColor = UIColor.red.cgColor
      shapeLayer.frame = layer.bounds

      // add the new layer to our custom view
      self.layer.addSublayer(shapeLayer)
    }
  }

}

extension UIColor {
  convenience init(effection: EffectionData) {
    if effection.effect >= 0 {
      self.init(red: 0, green: 1, blue: 0, alpha: 1)
    } else {
      self.init(red: 1, green: 0, blue: 0, alpha: 1)
    }
  }
}

extension CGFloat {
  init(effection: EffectionData) {
    self = abs(CGFloat(effection.effect))
  }
}

class NodeView: UIView {
  let node: NodeData

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 12)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
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

    backgroundColor = node.color.withAlphaComponent(0.25)
  }

  private func updateUI() {
    titleLabel.text = node.title
  }
}
