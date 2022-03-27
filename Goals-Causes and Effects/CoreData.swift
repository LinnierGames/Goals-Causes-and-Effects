//
//  CoreData.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 3/27/22.
//

import Foundation

extension NodeData {
  var listOfCauses: Set<EffectionData> {
    Set(self.causes?.allObjects as? [EffectionData] ?? [])
  }
  var listOfCauses2: Set<NodeData> {
    Set(listOfCauses.map { $0.cause! })
  }

  var listOfEffects: Set<EffectionData> {
    Set(self.effects?.allObjects as? [EffectionData] ?? [])
  }
  var listOfEffects2: Set<NodeData> {
    Set(listOfEffects.map { $0.effected! })
  }
}
