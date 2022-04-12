//
//  EffectionDetailScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct EffectionDetailScreen: View {
  @ObservedObject var effection: EffectionData

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      VStack {
        Text(effection.cause.title)
        NodeCircle(node: effection.cause)
          .frame(width: 232, height: 232)
        Spacer()
        HStack {
          VStack {
            Button("1/4x") {
              effection.effect = 0.25
            }
            Button("1/2x") {
              effection.effect = 0.5
            }
            Button("1x") {
              effection.effect = 1
            }
            Button("2x") {
              effection.effect = 2
            }
            Button("4x") {
              effection.effect = 4.sameSign(as: effection.effect)
            }
          }
          Spacer()

          Text(String(effection.effect))

          Spacer()
          VStack {
            Button {
              // Flip arrow
              let newEffected = effection.cause!
              let newCause = effection.effected!
              effection.effected = newEffected
              effection.cause = newCause
            } label: {
              Image(systemName: "arrow.up.arrow.down")
            }
            Button("+") {
              guard effection.effect < 0 else { return }
              effection.effect *= -1
            }
            Button("-") {
              guard effection.effect >= 0 else { return }
              effection.effect *= -1
            }
          }
        }
        Spacer()
        NodeCircle(node: effection.effected)
          .frame(width: 232, height: 232)
        Text(effection.effected.title)
      }
      .padding()

      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            injectPresistenceStore().saveContext()
            dismiss()
          } label: {
            Image(systemName: "checkmark")
          }
        }
      }
    }
  }
}

extension Double {
  func sameSign(as other: Double) -> Double {
    if other >= 0 {
      return abs(self)
    } else {
      return -abs(self)
    }
  }
}
