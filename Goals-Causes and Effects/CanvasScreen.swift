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
//    shapeLayer.position = CGPoint(x: 10, y: 10)

    // add the new layer to our custom view
    self.layer.addSublayer(shapeLayer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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

extension UIBezierPath {

  class func arrow(
    from start: CGPoint,
    to end: CGPoint,
    tailWidth: CGFloat,
    headWidth: CGFloat,
    headLength: CGFloat
  ) -> Self {
    let nodeRadius = sizeOfNodes / 2 - 12

    func offsetPoint(s: CGPoint, e: CGPoint, center: CGPoint) -> CGPoint {
      let opposite = e.y - s.y
      let adjacent = e.x - s.x
      let referenceAngle = atan2(opposite, adjacent)

      let x = center.x + cos(referenceAngle) * nodeRadius
      let y = center.y + sin(referenceAngle) * nodeRadius

      return CGPoint(x: x, y: y)
    }

    let offsettedStart = offsetPoint(s: start, e: end, center: start)
    let offsetedEnd = offsetPoint(s: end, e: start, center: end)

    print(start, offsettedStart, end, offsetedEnd)
    let length = hypot(offsetedEnd.x - offsettedStart.x, offsetedEnd.y - offsettedStart.y)
    let tailLength = length - headLength

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { return CGPoint(x: x, y: y) }
    let points: [CGPoint] = [
      p(0, tailWidth / 2),
      p(tailLength, tailWidth / 2),
      p(tailLength, headWidth / 2),
      p(length, 0),
      p(tailLength, -headWidth / 2),
      p(tailLength, -tailWidth / 2),
      p(0, -tailWidth / 2)
    ]

    let cosine = (offsetedEnd.x - offsettedStart.x) / length
    let sine = (offsetedEnd.y - offsettedStart.y) / length
    let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: offsettedStart.x, ty: offsettedStart.y)

    let path = CGMutablePath()
    path.addLines(between: points, transform: transform)
    path.closeSubpath()

    return self.init(cgPath: path)
  }

}

struct Arrow {
  let a: CGPoint
  let b: CGPoint
  let color: UIColor
  let width: CGFloat
}

private let sizeOfNodes: CGFloat = 96

class CanvasViewController: UIViewController {
  private let drawEffectionsView = DrawEffections()

  private let persistenceController = injectPresistenceStore()

  private lazy var animator = UIDynamicAnimator(referenceView: view)

  var tableOfNodeViews = [NSManagedObjectID: NodeView]()

  override func viewDidLoad() {
    super.viewDidLoad()

//    view.backgroundColor = .blue

//    let path1 = UIBezierPath()
//    path1.move(to: CGPoint(x: 0, y: 200))
//    path1.addLine(to: CGPoint(x: view.frame.midX, y: 400))
//    path1.addLine(to: CGPoint(x: view.frame.maxX, y: 200))
//    path1.addLine(to: CGPoint(x: view.frame.midX, y: -300))
//    let pathView = Draw(path: path1)
//    pathView.frame = view.bounds
//    view.addSubview(pathView)

    drawEffectionsView.frame = view.bounds
    drawEffectionsView.isUserInteractionEnabled = false
    view.addSubview(drawEffectionsView)

    spawnNodes()
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

  private func spawnNodes() {
    let ctx = persistenceController.container.viewContext
    let request = NodeData.fetchRequest()
    nodesToCreate = try! ctx.fetch(request).shuffled()

    tableOfNodeViews.removeAll()
    makeNextNode()

//    let path1 = UIBezierPath()
//    path1.move(to: CGPoint(x: 0, y: 200))
//    path1.addLine(to: CGPoint(x: view.frame.midX, y: 400))
//    path1.addLine(to: CGPoint(x: view.frame.maxX, y: 200))
//    path1.addLine(to: CGPoint(x: view.frame.midX, y: -300))

//    if UIDevice.current.userInterfaceIdiom == .pad {
//      collision.addBoundary(withIdentifier: "Cat 1" as NSCopying, for: path1)
//    }

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

import CoreData

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
