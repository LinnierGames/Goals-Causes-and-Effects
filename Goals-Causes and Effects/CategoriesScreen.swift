//
//  CategoriesScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/20/22.
//

import SwiftUI

struct CategoriesScreen: View {
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CategoryData.title, ascending: true)])
  var categories: FetchedResults<CategoryData>

  @State var isShowingNewCategoryAlert = false

  var body: some View {
    NavigationView {
      List {
        ForEach(categories, id: \.title) { category in
          Text(category.title)
        }
      }
      .alert(
        isPresented: $isShowingNewCategoryAlert,
        textAlert: TextAlert(title: "New Category", message: "enter a name", action: { newCategory in
          let title = newCategory ?? "Untitled"

          let store = injectPresistenceStore()
          store.newCategory(title: title)
        })
      )
      .navigationTitle("Categories")

      .toolbar {
        Button {
          isShowingNewCategoryAlert = true
        } label: {
          Image(systemName: "plus")
        }
      }
    }
  }
}
