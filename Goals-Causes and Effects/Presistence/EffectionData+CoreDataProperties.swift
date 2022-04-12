//
//  EffectionData+CoreDataProperties.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//
//

import Foundation
import CoreData


extension EffectionData {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<EffectionData> {
    return NSFetchRequest<EffectionData>(entityName: "Effection")
  }

  @NSManaged public var effect: Double
//  public var effect: Int {
//    get { Int(effectValue) }
//    set { effectValue = Int16(newValue) }
//  }

  @NSManaged public var cause: NodeData!
  @NSManaged public var effected: NodeData!

}

extension EffectionData : Identifiable {

}
