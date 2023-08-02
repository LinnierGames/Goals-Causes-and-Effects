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

  var value: Double {
    // TODO: Prevent cycles
    
    if listOfCauses.isEmpty {
      return initialValue
    }

    var total: Double = 1
    var sum = initialValue

    for causeEffect in listOfCauses {
      sum += causeEffect.cause.value * causeEffect.effect
      total += abs(1 * causeEffect.effect)
    }

    return max(sum / total, 0)
  }
}

extension CategoryData {
  var listOfNodes: [NodeData] {
    self.nodes?.allObjects as? [NodeData] ?? []
  }
}
