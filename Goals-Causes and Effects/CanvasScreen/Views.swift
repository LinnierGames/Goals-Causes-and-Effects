//
//  Views.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 6/16/22.
//

import Combine
import SwiftUI
import UIKit

class LineHolderView: UIView {

  private var bezierPathLine: UIBezierPath!
  private var bufferImage: UIImage?

  override init(frame: CGRect) {

    super.init(frame: frame)
    initializeView()
  }

  required init?(coder aDecoder: NSCoder) {

    super.init(coder: aDecoder)
    initializeView()
  }

  private var currentPoint: CGPoint?
  func move(to point: CGPoint) {
    currentPoint = point
    bezierPathLine.move(to: point)
  }
  
  func setLine(to point: CGPoint) {
    guard let currentPoint = currentPoint else { return }

    bezierPathLine.removeAllPoints()
    bezierPathLine.move(to: currentPoint)
    bezierPathLine.addLine(to: point)
    setNeedsDisplay()
  }

  func removeAllPoints() {
    //    saveBufferImage()
    bezierPathLine.removeAllPoints()
    currentPoint = nil
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    bufferImage?.draw(in: rect)
    drawLine()
  }

  private func drawLine() {
    UIColor.red.setStroke()
    bezierPathLine.stroke()
  }

  private func initializeView() {

    isMultipleTouchEnabled = false

    bezierPathLine = UIBezierPath()
    bezierPathLine.lineWidth = 4

    self.backgroundColor = UIColor.clear

    //    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewDragged(_:)))
    //    addGestureRecognizer(panGesture)
  }

  @objc func viewDragged(_ sender: UIPanGestureRecognizer) {

    let point = sender.location(in: self)

    if point.x < 0 || point.x > frame.width || point.y < 0 || point.y > frame.height {
      return
    }

    switch sender.state {

    case .began:
      bezierPathLine.move(to: point)
      break

    case .changed:
      bezierPathLine.addLine(to: point)
      setNeedsDisplay()
      break

    case .ended:
      saveBufferImage()
      bezierPathLine.removeAllPoints()
      break
    default:
      break
    }
  }

  private func saveBufferImage() {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
    if bufferImage == nil {
      let fillPath = UIBezierPath(rect: self.bounds)
      UIColor.clear.setFill()
      fillPath.fill()
    }
    bufferImage?.draw(at: .zero)
    drawLine()
    bufferImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
  }
}


/// Overlay canvas view for drawing the given `arrows`
///
///    *  *             *  *
///  *      *         *      *
/// *        * ----\ *        *
/// *        * ----/ *        *
///  *      *         *      *
///    *  *             *  *
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

/// Overlay canvas view for drawing the given `categories` in a pie as the background
///
/// Includes the titles of each category
///
///    *  *
///  *    * *
/// * (f)*   *
/// *   *    *
/// *   * (h)*
///  *  *   *
///    ** *
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
      numberOfPoints: nodes.count, centerX: center.x, centerY: center.y, radius: 150
    )
    let sections = zip(nodes, points).map { n, p in
      (category: n.category, nodes: n.nodes, spawnPoint: p)
    }

    for (index, section) in sections.enumerated() {
      let piePath = UIBezierPath()
      let startAngle = Double(index) / Double(nodes.count) * 2 * pi
      let endAngle = Double(index+1) / Double(nodes.count) * 2 * pi
      let center = CGPoint(x: bounds.width/2, y: bounds.height/2)
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

/// Circle view for the given `node`
///
/// Displays the title, background color, and the current `node.value`
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
  private var shapeLayer = CAShapeLayer()

  init(node: NodeData) {
    self.node = node
    super.init(frame: .zero)

    setupView()
    updateUI()

    node.objectWillChange.sink { _ in
      self.updateUI()
    }.store(in: &bag)

    node.listOfEffects.forEach {
      $0.objectWillChange.sink { _ in
        self.updateUI()
      }.store(in: &bag)
    }
    node.listOfCauses.forEach {
      $0.objectWillChange.sink { _ in
        self.updateUI()
      }.store(in: &bag)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    layer.cornerRadius = min(bounds.width / 2, bounds.height / 2)
    shapeLayer.frame = bounds
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

    let starPath = UIBezierPath()
    starPath.addStar(rect: bounds, extrusion: 20, points: 5)

    let boundaryLayer = CAShapeLayer()
    boundaryLayer.path = starPath.cgPath
    boundaryLayer.fillColor = UIColor.clear.cgColor
    boundaryLayer.strokeColor = UIColor.red.cgColor
    boundaryLayer.frame = layer.bounds
    layer.addSublayer(boundaryLayer)

//    layer.addSublayer(shapeLayer)
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

extension CGPoint {
  func pointFrom(angle: CGFloat, radius: CGFloat) -> CGPoint {
    return CGPoint(x: self.x + radius * cos(CGFloat.pi - angle), y: self.y - radius * sin(CGFloat.pi - angle))
  }
}

extension UIBezierPath {
  func addStar(rect: CGRect, extrusion: CGFloat, points: Int) {
    self.move(to: CGPoint(x: 0, y: 0))
    let center = CGPoint(x: rect.width / 2.0, y: rect.height / 2.0)
    var angle:CGFloat = -CGFloat.pi / 2.0
    let angleIncrement = CGFloat.pi * 2.0 / CGFloat(points)
    let radius = rect.width / 2.0
    var firstPoint = true
    for _ in 1...points {
      let point = center.pointFrom(angle: angle, radius: radius)
      let nextPoint = center.pointFrom(angle: angle + angleIncrement, radius: radius)
      let midPoint = center.pointFrom(angle: angle + angleIncrement / 2.0, radius: extrusion)
      if firstPoint {
        firstPoint = false
        self.move(to: point)
      }
      self.addLine(to: midPoint)
      self.addLine(to: nextPoint)
      angle += angleIncrement
    }
  }
}

