//
//  AddNodeScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct AddNodeScreen: View {
  @State private var title = ""

  private enum Impact: Int, Identifiable {
    case good, bad
  }
  @State private var impact = Impact.good
  @State private var initalValue: Double = 0.5

  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      HStack {
        Text("Title")
        TextField("title", text: $title)
          .multilineTextAlignment(.trailing)
      }

      HStack {
        Text("Category")
        Spacer()
        Text("None")
      }

      Picker(selection: $impact) {
        Text("Good")
          .tag(Impact.good)
        Text("Bad")
          .tag(Impact.bad)
      } label: {
        EmptyView()
      }
      .pickerStyle(SegmentedPickerStyle())

      Spacer()

      Circle()
        .foregroundColor(impact == .good ? .green : .red)
        .frame(width: 232, height: 232)
    }
    .padding()

    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: dismiss.callAsFunction) {
          Image(systemName: "xmark")
        }
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: pressSave) {
          Image(systemName: "checkmark")
        }
      }
    }
  }

  private func pressSave() {
    let store = injectPresistenceStore()
    store.newNode(title: title, isGood: impact == .good, initialValue: initalValue)
    dismiss()
  }
}
