//
//  KVKTextEditorView.swift
//
//
//  Created by Sergei Kviatkovskii on 5/11/23.
//

import SwiftUI

public struct KVKTextEditorView: View {
    
    @Binding private var text: String
    private let placeholder: String
    private let isDisplayedBorderLine: Bool
    
    public init(text: Binding<String>,
                placeholder: String = "Optional",
                isDisplayedBorderLine: Bool = false) {
        _text = text
        self.placeholder = placeholder
        self.isDisplayedBorderLine = isDisplayedBorderLine
    }
    
    public var body: some View {
        if isDisplayedBorderLine {
            boxView
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.gray, lineWidth: 1)
                )
        } else {
            boxView
        }
    }
    
    private var boxView: some View {
        ZStack {
            TextEditor(text: $text)
            if text.isEmpty {
                VStack {
                    HStack {
                        Text(placeholder)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 5)
                .allowsHitTesting(false)
            }
        }
    }
}

struct KVKTextEditorView_Previews: PreviewProvider {
    
    @State static var text = ""
    
    static var previews: some View {
        KVKTextEditorView(text: Binding(get: { text },
                                     set: { text = $0 }))
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 200)
            .padding()
    }
}
