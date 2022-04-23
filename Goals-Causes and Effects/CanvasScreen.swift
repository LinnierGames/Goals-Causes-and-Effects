//
//  CanvasScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 3/27/22.
//

import Combine
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
//    drawEffectionsView.translatesAutoresizingMaskIntoConstraints = false
    drawEffectionsView.isUserInteractionEnabled = false
    view.addSubview(drawEffectionsView)
    drawPie.frame = view.bounds
//    drawPie.translatesAutoresizingMaskIntoConstraints = false
    drawPie.isUserInteractionEnabled = false
    view.addSubview(drawPie)

//    NSLayoutConstraint.activate([
//
//      // Draw Pie
//      drawPie.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//      drawPie.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//      drawPie.topAnchor.constraint(equalTo: view.topAnchor),
//      drawPie.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//      // Effections
//      drawEffectionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//      drawEffectionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//      drawEffectionsView.topAnchor.constraint(equalTo: view.topAnchor),
//      drawEffectionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//    ])

    spawnCategoriesAndNodes()
  }

//  override func viewDidLayoutSubviews() {
//    super.viewDidLayoutSubviews()
//
//    spawnCategoriesAndNodes()
//  }

//  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//    super.traitCollectionDidChange(previousTraitCollection)
//
//    spawnCategoriesAndNodes()
//  }

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
    collision.removeAllBoundaries()
    tableOfNodeViews.removeAll()
    for subview in view.subviews where subview is NodeView {
      subview.removeFromSuperview()
    }

    let ctx = persistenceController.container.viewContext
    let request = CategoryData.fetchRequest()
    let categories = try! ctx.fetch(request).shuffled()

    drawPie.categories = categories

    let nodes = categories.map { (category: $0, nodes: $0.listOfNodes) }

    let pi = Double.pi
    let bounds = view.bounds
    let largestRadius = max(bounds.width, bounds.height) / 2
    let center = CGPoint(x: bounds.width/2, y: bounds.height/2 - 96)

    // Set up boundaries
    for (index, node) in nodes.enumerated() {
      let piePath = UIBezierPath()
      let startAngle = Double(index) / Double(nodes.count) * 2 * pi
      let endAngle = Double(index+1) / Double(nodes.count) * 2 * pi
      let thisRadius = largestRadius
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

    // Spawn Nodes
    let points = pointsOnCircleFor(
      numberOfPoints: nodes.count, centerX: center.x, centerY: center.y, radius: 400
    )
    let data = zip(nodes, points).map { n, p in
      (category: n.category, nodes: n.nodes, spawnPoint: p)
    }

    for section in data {
      DispatchQueue.global().async {
        for node in section.nodes {
          DispatchQueue.main.async {
            self.makeNode(node, at: section.spawnPoint)
          }

          sleep(1)
        }
      }
    }

    animator.addBehavior(gravity)
    animator.addBehavior(collision)
    animator.addBehavior(preventRotation)
  }

  private func makeNode(_ node: NodeData, at point: CGPoint) {
    let nodeView = NodeView(node: node)
    nodeView.translatesAutoresizingMaskIntoConstraints = false
    nodeView.frame.size = CGSize(width: sizeOfNodes, height: sizeOfNodes)
    nodeView.frame.origin = point
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
    let didLongTapGesture =
      UILongPressGestureRecognizer(target: self, action: #selector(didLongTapNodeView(gesture:)))
    nodeView.addGestureRecognizer(didLongTapGesture)

    tableOfNodeViews[node.objectID] = nodeView
  }

  @objc private func didTapNodeView(gesture: UITapGestureRecognizer) {
    guard let nodeView = gesture.view as? NodeView else { fatalError("not a node view") }
    drawEffections(for: nodeView)
  }

  @objc private func didLongTapNodeView(gesture: UITapGestureRecognizer) {
    guard let nodeView = gesture.view as? NodeView else { fatalError("not a node view") }
    editNode(nodeView)
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

  func editNode(_ nodeView: NodeView) {
    let node = nodeView.node

    let editNodeViewController = EditNodeViewController(node: node)
    present(UINavigationController(rootViewController: editNodeViewController), animated: true)
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

  override func layoutSubviews() {
    super.layoutSubviews()
    updateUI()
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

  override func layoutSubviews() {
    super.layoutSubviews()
    updateUI()
  }

  private func updateUI() {
    layer.sublayers?.removeAll()

    let pi = Double.pi
    let largestRadius = max(bounds.width, bounds.height) / 2

    let nodes = categories.map { (category: $0, nodes: $0.listOfNodes) }
    let points = pointsOnCircleFor(
      numberOfPoints: nodes.count, centerX: center.x, centerY: center.y - 96, radius: 150
    )
    let sections = zip(nodes, points).map { n, p in
      (category: n.category, nodes: n.nodes, spawnPoint: p)
    }

    for (index, section) in sections.enumerated() {
      let piePath = UIBezierPath()
      let startAngle = Double(index) / Double(nodes.count) * 2 * pi
      let endAngle = Double(index+1) / Double(nodes.count) * 2 * pi
      let center = CGPoint(x: bounds.width/2, y: bounds.height/2 - 96)
      let thisRadius = largestRadius
      piePath.move(to: center)

      piePath.addArc(withCenter: center,
        radius: thisRadius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: true)
      piePath.addLine(to: center)
      piePath.close()

      let boundaryLayer = CAShapeLayer()
      boundaryLayer.path = piePath.cgPath
      boundaryLayer.fillColor = UIColor.clear.cgColor
      boundaryLayer.strokeColor = UIColor.red.cgColor
      boundaryLayer.frame = layer.bounds
      self.layer.addSublayer(boundaryLayer)

      let spawnPointPath = UIBezierPath(
        arcCenter: section.spawnPoint, radius: 5, startAngle: 0, endAngle: .pi * 2, clockwise: true
      )
      spawnPointPath.close()

      let spawnPointLayer = CAShapeLayer()
      spawnPointLayer.path = spawnPointPath.cgPath
      spawnPointLayer.fillColor = UIColor.red.cgColor
      spawnPointLayer.frame = layer.bounds
      self.layer.addSublayer(spawnPointLayer)

      let textlayer = CATextLayer()
      let title = section.category.title
      let textWidth = title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
      textlayer.frame = CGRect(x: section.spawnPoint.x, y: section.spawnPoint.y, width: textWidth.width, height: 18)
      textlayer.fontSize = 12
      textlayer.alignmentMode = .center
      textlayer.string = title
      textlayer.isWrapped = true
      textlayer.truncationMode = .end
//      textlayer.backgroundColor = UIColor.white.cgColor
      textlayer.foregroundColor = UIColor.label.cgColor

      self.layer.addSublayer(textlayer)
    }
  }

}

public func pointsOnCircleFor(numberOfPoints: Int, centerX: CGFloat, centerY: CGFloat, radius: CGFloat, precision: UInt = 3) -> [CGPoint] {
  var points = [CGPoint]()
  let angle = CGFloat(M_PI) / CGFloat(numberOfPoints) * 2.0
  let p = CGFloat(pow(10.0, Double(precision)))

  for i in 0..<numberOfPoints {
    let x = centerX - radius * cos(angle * CGFloat(i))
    let roundedX = Double(round(p * x)) / Double(p)
    let y = centerY - radius * sin(angle * CGFloat(i))
    let roundedY = Double(round(p * y)) / Double(p)
    points.append(CGPoint(x: roundedX, y: roundedY))
  }

  print(points)
  return points
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
  @ObservedObject var node: NodeData

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 12)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    return label
  }()

  private lazy var progressView: UIImageView = {
    let view = UIImageView()
    view.backgroundColor = node.color.withAlphaComponent(0.25)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var progressViewHeightConstraint =
    progressView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: node.value)

  private var bag = Set<AnyCancellable>()

  init(node: NodeData) {
    self.node = node
    super.init(frame: .zero)
    setupView()
    updateUI()

    node.objectWillChange.sink { _ in
      self.updateUI()
    }.store(in: &bag)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    layer.cornerRadius = min(bounds.width / 2, bounds.height / 2)
    clipsToBounds = true
  }

  private func setupView() {
    addSubview(progressView)
    addSubview(titleLabel)

    let padding: CGFloat = 16

    NSLayoutConstraint.activate([

      // Title label
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
      titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
      trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: padding),
      bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding),

      // Progress View
      progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
      progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
//      progressViewHeightConstraint,
      progressView.bottomAnchor.constraint(equalTo: bottomAnchor),

      // Keep self as a square
      heightAnchor.constraint(equalTo: widthAnchor),
    ])

//    backgroundColor = node.color.withAlphaComponent(0.25)
    layer.borderColor = UIColor.black.cgColor
    layer.borderWidth = 1
  }

  private func updateUI() {
    titleLabel.text = node.title

    progressViewHeightConstraint.isActive = false
    progressView.removeConstraint(progressViewHeightConstraint)
    progressViewHeightConstraint =
      progressView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: node.value)
    progressViewHeightConstraint.isActive = true
  }
}
