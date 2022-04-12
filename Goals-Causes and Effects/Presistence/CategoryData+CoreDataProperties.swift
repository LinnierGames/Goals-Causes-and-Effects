//
//  CategoryData+CoreDataProperties.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//
//

import Foundation
import CoreData


extension CategoryData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryData> {
        return NSFetchRequest<CategoryData>(entityName: "Category")
    }

    @NSManaged public var title: String
    @NSManaged public var nodes: NSSet!

}

// MARK: Generated accessors for nodes
extension CategoryData {

    @objc(addNodesObject:)
    @NSManaged public func addToNodes(_ value: NodeData)

    @objc(removeNodesObject:)
    @NSManaged public func removeFromNodes(_ value: NodeData)

    @objc(addNodes:)
    @NSManaged public func addToNodes(_ values: NSSet)

    @objc(removeNodes:)
    @NSManaged public func removeFromNodes(_ values: NSSet)

}

extension CategoryData : Identifiable {

}
