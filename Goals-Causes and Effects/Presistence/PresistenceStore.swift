//
//  PresistenceStore.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 3/27/22.
//

import CoreData

func injectPresistenceStore() -> PresistenceStoreImpl {
  PresistenceStoreImpl.shared
}

class PresistenceStoreImpl {
  fileprivate static let shared = PresistenceStoreImpl()

  lazy var container: NSPersistentCloudKitContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    let container = NSPersistentCloudKitContainer(name: "Goals_Causes_and_Effects")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    
    return container
  }()

  private init() {
  }

  @discardableResult
  func newNode(
    title: String,
    notes: String,
    isGood: Bool,
    initialValue: Double,
    category: CategoryData?
  ) -> NodeData {
    let node = NodeData(context: container.viewContext)
    node.title = title
    node.notes = notes
    node.color = isGood ? .green : .red
    node.initialValue = initialValue
    node.category = category

    saveContext()

    return node
  }

  @discardableResult
  func newCategory(title: String) -> CategoryData {
    let category = CategoryData(context: container.viewContext)
    category.title = title

    saveContext()

    return category
  }

  func saveContext () {
    let context = container.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}

enum Shape {
  case circle, square
}
