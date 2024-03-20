//
//  KVKScrollView.swift
//
//
//  Created by Sergei Kviatkovskii on 3/20/24.
//

import SwiftUI

public struct KVKScrollView<Content: View>: View {
    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let onScroll: ScrollAction
    private var content: Content
    
    public typealias ScrollAction = (_ offset: CGPoint) -> Void
    
    public init(_ axes: Axis.Set = .vertical,
                showsIndicators: Bool = true,
                onScroll: ScrollAction? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.onScroll = onScroll ?? { _ in }
        self.content = content()
    }
    
    public var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            ZStack(alignment: .top) {
                ScrollViewOffsetTracker()
                content
            }
        }
        .withOffsetTracking(action: onScroll)
    }
}

private struct ScrollTestView: View {
    @State var scrollOffset: CGPoint = .zero
    
    var body: some View {
        NavigationView {
            KVKScrollView(onScroll: handleScroll) {
                LazyVStack {
                    ForEach(0...100, id: \.self) { idx in
                        Text("\(idx)")
                            .padding()
                        Divider()
                    }
                }
            }
            .navigationTitle("Offset: \(scrollOffset.y)")
            .navigationViewStyle(.stack)
        }
    }
    
    func handleScroll(_ offset: CGPoint) {
        scrollOffset = offset
    }
}

#Preview {
    ScrollTestView()
}

enum ScrollOffsetNamespace {
    static let namespace = "scrollView"
}

struct ScrollOffsetPreferenceKey: PreferenceKey {

    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

struct ScrollViewOffsetTracker: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geo.frame(in: .named(ScrollOffsetNamespace.namespace)).origin
                )
        }
        .frame(height: 0)
    }
}

private extension ScrollView {
    func withOffsetTracking(action: @escaping (_ offset: CGPoint) -> Void) -> some View {
        coordinateSpace(name: ScrollOffsetNamespace.namespace)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
    }
}
