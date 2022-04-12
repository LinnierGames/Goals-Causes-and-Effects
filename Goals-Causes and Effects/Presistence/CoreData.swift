//
//  CoreData.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 3/27/22.
//

import Foundation

extension NodeData {
  var listOfCauses: [EffectionData] {
    self.causes?.allObjects as? [EffectionData] ?? []
  }
  var listOfCauses2: [NodeData] {
    listOfCauses.map { $0.cause! }
  }

  var listOfEffects: [EffectionData] {
    self.effects?.allObjects as? [EffectionData] ?? []
  }
  var listOfEffects2: [NodeData] {
    listOfEffects.map { $0.effected! }
  }
}
