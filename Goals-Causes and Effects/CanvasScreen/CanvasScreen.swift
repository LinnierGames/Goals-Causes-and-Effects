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

let sizeOfNodes: CGFloat = 96

import CoreData

class CanvasViewController: UIViewController {
  private let drawEffectionsView = DrawEffections()
  private let drawPie = DrawPie()
  private let drawConnectionView = LineHolderView()

  private let persistenceController = injectPresistenceStore()

  private lazy var animator = UIDynamicAnimator(referenceView: view)

  var tableOfNodeViews = [NSManagedObjectID: NodeView]()

  override func viewDidLoad() {
    super.viewDidLoad()

    drawEffectionsView.frame = view.bounds
    drawEffectionsView.translatesAutoresizingMaskIntoConstraints = false
    drawEffectionsView.isUserInteractionEnabled = false
    view.addSubview(drawEffectionsView)
    drawPie.frame = view.bounds
    drawPie.translatesAutoresizingMaskIntoConstraints = false
    drawPie.isUserInteractionEnabled = false
    view.addSubview(drawPie)
    drawConnectionView.frame = view.bounds
    drawConnectionView.translatesAutoresizingMaskIntoConstraints = false
    drawConnectionView.isUserInteractionEnabled = false
    view.addSubview(drawConnectionView)

    NSLayoutConstraint.activate([

      // Draw Pie
      drawPie.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      drawPie.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      drawPie.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      drawPie.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      // Effections
      drawEffectionsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      drawEffectionsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      drawEffectionsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      drawEffectionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      // Draw Connection
      drawConnectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      drawConnectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      drawConnectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      drawConnectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])

    view.layoutIfNeeded()

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
    let center = drawPie.center//CGPoint(x: bounds.width/2, y: bounds.height/2 - 96)

    // Set up boundaries
    for (index, _) in nodes.enumerated() {
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
      // TODO: Fix the position
//      collision.addBoundary(withIdentifier: String(index) as NSCopying, for: piePath)
    }

    // Spawn Nodes
    let points = pointsOnCircleFor(
      numberOfPoints: nodes.count, centerX: center.x, centerY: center.y, radius: center.x
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
    let didDoubleTapGesture =
      UITapGestureRecognizer(target: self, action: #selector(didDoubleTapNodeView(gesture:)))
    didDoubleTapGesture.numberOfTapsRequired = 2
    nodeView.addGestureRecognizer(didDoubleTapGesture)
    let didPanGesture =
      UIPanGestureRecognizer(target: self, action: #selector(didPanNodeView(gesture:)))
    nodeView.addGestureRecognizer(didPanGesture)

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

  @objc private func didDoubleTapNodeView(gesture: UITapGestureRecognizer) {
    guard let nodeView = gesture.view as? NodeView else { fatalError("not a node view") }
    detailNode(nodeView)
  }

  @objc private func didPanNodeView(gesture: UIPanGestureRecognizer) {
    guard let nodeView = gesture.view as? NodeView else { fatalError("not a node view") }
    drawConnection(from: nodeView, gesture: gesture)
  }

  private var bezierPathLine: UIBezierPath!
  func drawConnection(from sourceNideView: NodeView, gesture: UIPanGestureRecognizer) {

    let point = gesture.location(in: self.view)

    switch gesture.state {
    case .began:
      drawConnectionView.move(to: point)
      drawEffections(for: sourceNideView)
    case .changed:
      drawConnectionView.setLine(to: point)
    case .ended:
      if
        let viewUnderPoint = view.hitTest(point, with: nil),
        let terminalNodeView = viewUnderPoint as? NodeView
      {
        createEffection(between: sourceNideView, and: terminalNodeView)
      }

      drawConnectionView.removeAllPoints()
    default:
      break
    }
  }

  private func createEffection(between sourceNideView: NodeView, and terminalNodeView: NodeView) {
    let store = injectPresistenceStore()
    let effection = EffectionData(context: store.container.viewContext)
    effection.effect = 1

    sourceNideView.node.addToEffects(effection)
    terminalNodeView.node.addToCauses(effection)

    store.saveContext()

    editEffection(effection)
//    drawEffections(for: sourceNideView)
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

  func detailNode(_ nodeView: NodeView) {
    let node = nodeView.node

    let detailNodeViewController = DetailNodeViewController(node: node)
    present(UINavigationController(rootViewController: detailNodeViewController), animated: true)
  }

  func editEffection(_ effection: EffectionData) {
    let detailNodeViewController = DetailEffectionViewController(effection: effection)
    present(UINavigationController(rootViewController: detailNodeViewController), animated: true)
  }
}
