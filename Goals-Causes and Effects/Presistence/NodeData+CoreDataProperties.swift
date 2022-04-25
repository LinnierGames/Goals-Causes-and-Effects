//
//  NodeData+CoreDataProperties.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//
//

import Foundation
import CoreData
import UIKit


extension NodeData {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<NodeData> {
    return NSFetchRequest<NodeData>(entityName: "Node")
  }

  @NSManaged public var colorValue: String
  public var color: UIColor {
    get { UIColor(hex: colorValue) ?? .green }
    set { colorValue = newValue.hex ?? "#FFFFFF" }
  }

  @NSManaged public var initialValue: Double
  @NSManaged public var shapeValue: Int16
  public var shape: NodeShape {
    get { NodeShape(rawValue: Int(shapeValue)) ?? .circle }
    set { shapeValue = Int16(newValue.rawValue) }
  }

  @NSManaged public var title: String
  @NSManaged public var notes: String
  @NSManaged public var category: CategoryData?
  @NSManaged public var causes: NSSet!
  @NSManaged public var effects: NSSet!

}

// MARK: Generated accessors for causes
extension NodeData {

  @objc(addCausesObject:)
  @NSManaged public func addToCauses(_ value: EffectionData)

  @objc(removeCausesObject:)
  @NSManaged public func removeFromCauses(_ value: EffectionData)

  @objc(addCauses:)
  @NSManaged public func addToCauses(_ values: NSSet)

  @objc(removeCauses:)
  @NSManaged public func removeFromCauses(_ values: NSSet)

}

// MARK: Generated accessors for effects
extension NodeData {

  @objc(addEffectsObject:)
  @NSManaged public func addToEffects(_ value: EffectionData)

  @objc(removeEffectsObject:)
  @NSManaged public func removeFromEffects(_ value: EffectionData)

  @objc(addEffects:)
  @NSManaged public func addToEffects(_ values: NSSet)

  @objc(removeEffects:)
  @NSManaged public func removeFromEffects(_ values: NSSet)

}

extension NodeData : Identifiable {

}
