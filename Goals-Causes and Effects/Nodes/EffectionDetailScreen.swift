//
//  EffectionDetailScreen.swift
//  Goals-Causes and Effects
//
//  Created by Erick Sanchez on 4/12/22.
//

import SwiftUI

struct EffectionDetailScreen: View {
  @ObservedObject var effection: EffectionData
  var dismiss: () -> Void = {}

  @Environment(\.dismiss) private var dismissEnvironment

  var body: some View {
    NavigationView {
      VStack {
        Text(effection.cause.title)
        NodeCircle(node: effection.cause, showValue: true)
          .frame(width: 232, height: 232)
        Spacer()
        HStack {
          VStack {
            Button("1/4x") {
              effection.effect = 0.25
            }
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
            Button("1/2x") {
              effection.effect = 0.5
            }
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
            Button("1x") {
              effection.effect = 1
            }
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
            Button("2x") {
              effection.effect = 2
            }
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
            Button("4x") {
              effection.effect = 4.sameSign(as: effection.effect)
            }
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
          }
          Spacer()

          Image(systemName: "arrow.down")
            .arrowThickness(effection: effection)
            .foregroundColor(effection.effect >= 0 ? .green : .red)

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
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
            Button("+") {
              guard effection.effect < 0 else { return }
              effection.effect *= -1
            }
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
            Button("-") {
              guard effection.effect >= 0 else { return }
              effection.effect *= -1
            }
            .padding(4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(4)
          }
        }
        Spacer()
        NodeCircle(node: effection.effected, showValue: true)
          .frame(width: 232, height: 232)
        Text(effection.effected.title)
      }
      .padding()

      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            injectPresistenceStore().saveContext()
            dismiss()
            dismissEnvironment()
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

extension View {
  func arrowThickness(effection: EffectionData) -> some View {
    let size: CGFloat
    let weight: Font.Weight

    switch abs(effection.effect) {
    case ...0.25:
      size = 32
      weight = .ultraLight
    case 0.25...0.5:
      size = 32
      weight = .light
    case 0.5...1:
      size = 64
      weight = .regular
    case 1...2:
      size = 64
      weight = .semibold
    case 2...4:
      size = 96
      weight = .heavy
    default:
      size = 32
      weight = .regular
    }

    return font(.system(size: size, weight: weight))
  }
}

class DetailEffectionViewController: UIHostingController<AnyView> {
  init(effection: EffectionData) {
    var vc: UIViewController! = nil
    let dismiss = {
      vc.dismiss(animated: true)
    }

    let rootView = EffectionDetailScreen(effection: effection, dismiss: dismiss)
      .environment(\.managedObjectContext, injectPresistenceStore().container.viewContext)
    super.init(rootView: AnyView(rootView))
    vc = self
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
