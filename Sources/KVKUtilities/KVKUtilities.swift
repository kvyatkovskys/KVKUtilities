//
//  KVKUtilities.swift
//
//
//  Created by Sergei Kviatkovskii on 9/25/22.
//

import SwiftUI

#if canImport(UIKit)

struct SkeletonView: ViewModifier {
    
    var isVisible: Bool
    
    func body(content: Content) -> some View {
        if isVisible {
            content
                .redacted(reason: [.placeholder]).disabled(true)
        } else {
            content
        }
    }
    
}

public extension UIWindowScene {
    static var focused: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
    }
}

public extension UIApplication {
    
    var orientation: UIInterfaceOrientation {
        UIWindowScene.focused?.interfaceOrientation ?? .unknown
    }
    
    var activeWindows: [UIWindow]? {
        connectedScenes
            .first { $0.activationState == .foregroundActive && $0 is UIWindowScene }
            .flatMap { $0 as? UIWindowScene }?.windows
    }
    
    var activeWindow: UIWindow? {
        connectedScenes
            .first { $0.activationState == .foregroundActive && $0 is UIWindowScene }
            .flatMap { $0 as? UIWindowScene }?.windows
            .first(where: \.isKeyWindow)
    }
    
    var allWindows: [UIWindow] {
        connectedScenes
            .first { $0 is UIWindowScene }
            .flatMap { $0 as? UIWindowScene }?.windows ?? []
    }
    
    var lastActiveWindow: UIWindow? {
        connectedScenes
            .first { $0 is UIWindowScene }
            .flatMap { $0 as? UIWindowScene }?.windows
            .first(where: \.isKeyWindow)
    }
    
    var isUserEnabledAllWindows: Bool {
        get {
            (activeWindows ?? []).allSatisfy { $0.isUserInteractionEnabled == true }
        }
        set {
            activeWindows?.forEach { $0.isUserInteractionEnabled = newValue }
        }
    }
    
}

public extension NSObject {
    // https://stackoverflow.com/questions/75073023/how-to-trigger-swiftui-datepicker-programmatically
    func accessibilityDescendant(passing test: (Any) -> Bool) -> Any? {
        
        if test(self) { return self }
        
        for child in accessibilityElements ?? [] {
            if test(child) { return child }
            if let child = child as? NSObject, let answer = child.accessibilityDescendant(passing: test) {
                return answer
            }
        }
        
        for subview in (self as? UIView)?.subviews ?? [] {
            if test(subview) { return subview }
            if let answer = subview.accessibilityDescendant(passing: test) {
                return answer
            }
        }
        
        return nil
    }
    
    func accessibilityDescendant(identifiedAs id: String) -> Any? {
        accessibilityDescendant {
            // For reasons unknown, I cannot cast a UIView to a UIAccessibilityIdentification at runtime.
            ($0 as? UIView)?.accessibilityIdentifier == id
            || ($0 as? UIAccessibilityIdentification)?.accessibilityIdentifier == id
        }
    }
    
    func buttonAccessibilityDescendant() -> Any? {
        accessibilityDescendant { ($0 as? NSObject)?.accessibilityTraits == .button }
    }
}

public extension SwiftUI.View {
    
    func triggerViewByID(_ id: String) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let view = window.accessibilityDescendant(identifiedAs: id) as? NSObject,
           let button = view.buttonAccessibilityDescendant() as? NSObject {
            button.accessibilityActivate()
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

public struct AvatarView<Content, Shape: SwiftUI.Shape>: View where Content: View {
    
    private let url: URL?
    private let isActive: Bool
    private let placeholder: () -> Content?
    private let shape: Shape
    
    public init(url: URL?,
                isActive: Bool = false,
                @ViewBuilder placeholder: @escaping () -> Content? = { PlaceholderStubImage() },
                @ViewBuilder shape: @escaping () -> Shape? = { Circle() }) {
        self.url = url
        self.isActive = isActive
        self.placeholder = placeholder
        self.shape = shape() ?? Circle() as! Shape
    }
    
    public var body: some View {
        EmptyView()
//        KFImage(url)
//            .cacheOriginalImage()
//            .placeholder {
//                placeholder()
//            }
//            .resizable()
//            .scaledToFill()
//            .frame(minWidth: 40, maxWidth: 60, minHeight: 40, maxHeight: 60)
//            .clipShape(shape)
    }
    
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarView(url: URL(string: ""))
    }
}

public struct PlaceholderStubImage: View {
    
    public init() {}
    
    public var body: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .foregroundColor(.gray.opacity(0.7))
            .scaledToFit()
            .clipShape(Circle())
    }
    
}

public struct CornerRadiusStyle: ViewModifier {
    public var radius: CGFloat
    public var corners: UIRectCorner
    
    struct CornerRadiusShape: Shape {

        var radius = CGFloat.infinity
        var corners = UIRectCorner.allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }

    public func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

public extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyle(radius: radius, corners: corners))
    }
}

public struct TextFieldBeginEditingViewModifier: SwiftUI.ViewModifier {
    
    public let action: (NotificationCenter.Publisher.Output) -> Void
    
    public func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { (obj) in
                action(obj)
            }
    }
    
}

public extension SwiftUI.View {
    
    func onRecieveTextFieldBeginEditing(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void) -> some SwiftUI.View {
        modifier(TextFieldBeginEditingViewModifier(action: action))
    }
    
}

public struct AlertModel {
    public var title: String
    public var message: String?
    public var buttons: [AlertButtonModel]
    
    public struct AlertButtonModel: Identifiable {
        public var title: String = ""
        public var role: ButtonRole?
        public var action: (() -> Void)?
        
        public init(title: String, role: ButtonRole? = nil, action: (() -> Void)? = nil) {
            self.title = title
            self.role = role
            self.action = action
        }
        
        public var id: Int {
            title.hashValue
        }
        
        public static var okBtn: AlertButtonModel {
            AlertButtonModel(title: "OK")
        }
        
        public static var cancelBtn: AlertButtonModel {
            AlertButtonModel(title: "Cancel", role: .cancel)
        }
    }
    
    public init(title: String = "", message: String? = nil, buttons: [AlertButtonModel] = []) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }
    
    public init(withError: String) {
        title = "Error"
        message = withError
        buttons = [.okBtn]
    }
    
}

public struct AlertContentView: ViewModifier {
    
    public var alert: AlertModel?
    @Binding public var isAlertPresented: Bool
    
    init(alert: AlertModel? = nil, isAlertPresented: Binding<Bool>) {
        self.alert = alert
        _isAlertPresented = isAlertPresented
    }
    
    public func body(content: Content) -> some View {
        content
            .alert(alert?.title ?? "",
                   isPresented: $isAlertPresented,
                   presenting: alert,
                   actions: { (item) in
                ForEach(item.buttons) { (btn) in
                    Button(btn.title, role: btn.role, action: btn.action ?? {})
                }
            }, message: { (item) in
                if let msg = item.message {
                    Text(msg)
                }
            })
    }
    
}

public struct AlertTextFieldView: ViewModifier {
    
    public var alert: AlertModel?
    public var placeholder: String?
    public var keyboardType: UIKeyboardType = .default
    public var isSecureField: Bool
    @Binding public var isAlertPresented: Bool
    @Binding public var text: String
    
    public func body(content: Content) -> some View {
        content
            .alert(alert?.title ?? "",
                   isPresented: $isAlertPresented,
                   presenting: alert,
                   actions: { (item) in
                if isSecureField {
                    SecureField(placeholder ?? "Enter name", text: $text)
                        .keyboardType(keyboardType)
                } else {
                    TextField(placeholder ?? "Enter name", text: $text)
                        .keyboardType(keyboardType)
                }
                ForEach(item.buttons.indices, id: \.self) { (idx) in
                    let btn = item.buttons[idx]
                    Button(btn.title, role: btn.role, action: btn.action ?? {})
                }
            }, message: { (item) in
                if let msg = item.message {
                    Text(msg)
                }
            })
    }
    
}


public extension SwiftUI.View {
    
    func showAlert(_ alert: AlertModel?, isAlertPresented: Binding<Bool>) -> some SwiftUI.View {
        modifier(AlertContentView(alert: alert, isAlertPresented: isAlertPresented))
    }
    
    func showTextFieldAlert(_ alert: AlertModel?,
                            isSecureField: Bool = false,
                            placeholder: String? = nil,
                            keyboardType: UIKeyboardType = .default,
                            isAlertPresented: Binding<Bool>,
                            text: Binding<String>) -> some View {
        modifier(AlertTextFieldView(alert: alert,
                                    placeholder: placeholder,
                                    keyboardType: keyboardType,
                                    isSecureField: isSecureField,
                                    isAlertPresented: isAlertPresented,
                                    text: text))
    }
    
    func withNoAnimation(action: (() -> Void)?) {
        UIView.setAnimationsEnabled(false)
        action?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.setAnimationsEnabled(true)
        }
    }
}

public struct EmptyViewWithText: SwiftUI.View {
    
    @SwiftUI.State public var text: String
    
    public init(text: String = "Nothing to show.") {
        self.text = text
    }
    
    public var body: some SwiftUI.View {
        VStack {
            if #available(iOS 17.0, *) {
                ContentUnavailableView {
                    Label(text, systemImage: "doc.text.magnifyingglass")
                }
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .resizable()
                        .font(.body)
                        .foregroundStyle(.gray)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Text(text)
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.regularMaterial)
        .edgesIgnoringSafeArea(.all)
    }
    
}

public struct EmptyViewWithContent<Content>: SwiftUI.View where Content: SwiftUI.View {
    
    public var content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some SwiftUI.View {
        VStack() {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .edgesIgnoringSafeArea(.all)
    }
    
}


struct EmptyViewWithText_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            EmptyViewWithText()
            EmptyViewWithContent {
                VStack {
                    Button("Test") {
                        
                    }
                    .padding()
                }
            }
        }
    }
    
}

public struct NavigationBarModifier: ViewModifier {
    
    private var backgroundColor: Color
    
    public init(backgroundColor: Color) {
        self.backgroundColor = backgroundColor
    }
    
    public func body(content: Content) -> some SwiftUI.View {
        if #available(iOS 16.0, *) {
            content
                .toolbarBackground(backgroundColor)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            ZStack {
                VStack {
                    GeometryReader { (render) in
                        backgroundColor
                            .frame(height: render.safeAreaInsets.top)
                            .edgesIgnoringSafeArea(.top)
                    }
                }
                content
            }
        }
    }
}

public struct AttributedText: SwiftUI.View {
    @SwiftUI.State private var size: CGSize = .zero
    public let attributedString: NSAttributedString
    
    public init(_ attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }
    
    public var body: some SwiftUI.View {
        AttributedTextRepresentable(attributedString: attributedString, size: $size)
            .frame(width: size.width, height: size.height)
    }
    
    struct AttributedTextRepresentable: UIViewRepresentable {
        
        let attributedString: NSAttributedString
        @Binding var size: CGSize

        func makeUIView(context: Context) -> UILabel {
            let label = UILabel()
            
            label.lineBreakMode = .byClipping
            label.numberOfLines = 0

            return label
        }
        
        func updateUIView(_ uiView: UILabel, context: Context) {
            uiView.attributedText = attributedString
            
            DispatchQueue.main.async {
                size = uiView.sizeThatFits(uiView.superview?.bounds.size ?? .zero)
            }
        }
    }
}

public extension SwiftUI.View {
    
    func transparentCover<Content: SwiftUI.View>(isPresented: Binding<Bool>, widthRatio: CGFloat = 0.8, heightRatio: CGFloat = 0.9, useFixMinScreenSize: Bool = false, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some SwiftUI.View {
        modifier(ProxyScreenModifier(isPresented: isPresented, isFullScreenCover: true, useFixMinScreenSize: useFixMinScreenSize, widthRatio: widthRatio, heightRatio: heightRatio, onDismiss: onDismiss, screenContent: content))
    }
    
    func transparentCover<Item, Content>(item: Binding<Item?>, widthRatio: CGFloat = 0.8, heightRatio: CGFloat = 0.9, useFixMinScreenSize: Bool = false, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some SwiftUI.View where Item: Identifiable, Content: SwiftUI.View {
        modifier(ProxyScreenItemModifier(item: item, isFullScreenCover: true, useFixMinScreenSize: useFixMinScreenSize, widthRatio: widthRatio, heightRatio: heightRatio, onDismiss: onDismiss, screenContent: content))
    }
    
}

public extension SwiftUI.View {
    
    func customAlert<Content: SwiftUI.View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some SwiftUI.View {
        modifier(ProxyAlertModifier(isPresented: isPresented, screenContent: content))
    }
    
}

private struct ProxyAlertModifier<ScreenContent: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    let screenContent: () -> (ScreenContent)
    
    private var minWidth: CGFloat {
//        if Platform.current == .iOS {
//            return Utilities.activeWindowSize.width * 0.8
//        } else {
            return 300
      //  }
    }
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ZStack {
                    let maxHeight: CGFloat = 100 // Utilities.activeWindowSize.height * 0.8
                    VStack {
                        screenContent()
                            .padding()
                    }
                    .background(.thickMaterial)
                    .cornerRadius(10)
                    .ignoresSafeArea(.keyboard)
                    .frame(minWidth: minWidth, maxWidth: minWidth, minHeight: 300, maxHeight: maxHeight)
                }
                .background(TransparentBackground())
                .edgesIgnoringSafeArea(.all)
            }
    }
}

private struct ProxyScreenModifier<ScreenContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    var isFullScreenCover = false
    var useFixMinScreenSize = false
    var widthRatio: CGFloat = 0.8
    var heightRatio: CGFloat = 0.9
    var onDismiss: (() -> Void)?
    let screenContent: () -> (ScreenContent)
    
    private var width: CGFloat {
        if useFixMinScreenSize {
            return 100 // Utilities.minimalWindowAppSize.width * 0.9
        } else {
            return 100 // Utilities.activeWindowSize.width * widthRatio
        }
    }
    
    private var height: CGFloat {
        if useFixMinScreenSize {
            return 100 // Utilities.minimalWindowAppSize.height - 100
        } else {
            return 100 // Utilities.activeWindowSize.height * heightRatio
        }
    }

    func body(content: Content) -> some View {
        if isFullScreenCover {
            content
                .fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) {
                    ZStack {
                        screenContent()
                            .cornerRadius(10)
                            .ignoresSafeArea(.keyboard)
                            .frame(width: width, height: height)
                    }
                    .background(TransparentBackground())
                    .edgesIgnoringSafeArea(.all)
                }
        } else {
            content
                .sheet(isPresented: $isPresented, onDismiss: onDismiss, content: screenContent)
        }
    }

}

private struct ProxyScreenItemModifier<FullScreenContent: View, Item: Identifiable>: ViewModifier {

    @Binding var item: Item?
    var isFullScreenCover = false
    var useFixMinScreenSize = false
    var widthRatio: CGFloat = 0.8
    var heightRatio: CGFloat = 0.9
    var onDismiss: (() -> Void)?
    let screenContent: (Item) -> (FullScreenContent)
    
    private var width: CGFloat {
        if useFixMinScreenSize {
            return 100 // Utilities.minimalWindowAppSize.width * 0.9
        } else {
            return 100 // Utilities.activeWindowSize.width * widthRatio
        }
    }
    
    private var height: CGFloat {
        if useFixMinScreenSize {
            return 100 // Utilities.minimalWindowAppSize.height - 100
        } else {
            return 100 // Utilities.activeWindowSize.height * heightRatio
        }
    }

    func body(content: Content) -> some View {
        if isFullScreenCover {
            content
                .fullScreenCover(item: $item, onDismiss: onDismiss) { (value) in
                    ZStack {
                        screenContent(value)
                            .cornerRadius(10)
                            .ignoresSafeArea(.keyboard)
                            .frame(width: width, height: height)
                    }
                    .background(TransparentBackground())
                    .edgesIgnoringSafeArea(.all)
                }
        } else {
            content
                .sheet(item: $item, onDismiss: onDismiss, content: screenContent)
        }
    }

}

public struct TransparentAlertBackground: UIViewRepresentable {
    
    public init() {}

    public func makeUIView(context: Context) -> UIView {
        InnerView()
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
    
    private class InnerView: UIView {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            DispatchQueue.main.async { [weak self] in
                self?.superview?.superview?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

public struct TransparentBackground: UIViewRepresentable {
    
    public init() {}

    public func makeUIView(context: Context) -> UIView {
        InnerView()
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
    
    private class InnerView: UIView {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            DispatchQueue.main.async { [weak self] in
                self?.superview?.superview?.backgroundColor = UIColor.black.withAlphaComponent(0.05)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                UIView.animate(withDuration: 0.25) {
                    self?.superview?.superview?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                }
            }
        }
    }
}

struct TransparentTestView: View {
    
    @SwiftUI.State var isCoverPresented = false
    @SwiftUI.State var isAlertPresented = false
    @SwiftUI.State var query = ""
    
    var body: some View {
        VStack {
            Menu("Menu") {
                Button("Open") {
                    isCoverPresented.toggle()
                }
                .padding()
            }
            Button("Open") {
                isCoverPresented.toggle()
            }
            .padding()
            Button("Custom Alert") {
                isAlertPresented.toggle()
            }
            .padding()
        }
        .customAlert(isPresented: $isAlertPresented) {
            VStack {
                Text("Title with long test dsgkjsngjkdfngjkndkjngdjkngjkdnfjkgnjkdfngjkndfjkngjkdfjkgndfjkngjkndfjngjkdfnjkgnjkdfgjkdfjkngjkdnfjkgnjkdfngjkdfjkngjkdfngjkndfjkgnjkdfngjkndfjkng")
                    .multilineTextAlignment(.center)
                TextField("optional", text: $query)
                    .padding(.vertical, 5)
                Divider()
                HStack {
                    Button("Cancel", role: .cancel) {
                        withNoAnimation {
                            isAlertPresented.toggle()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Button("OK") {
                        
                    }
                    .disabled(query.isEmpty)
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 5)
            }
        }
        .transparentCover(isPresented: $isCoverPresented, widthRatio: 0.6) {
            VStack {
                TextField("enter", text: .constant(""))
                    .padding()
                Button("Hide Keyboard") {
                    // UIApplication.shared.endEditing(true)
                }
                Button("Close") {
                    isCoverPresented.toggle()
                }
                .padding()
            }
            .background(.white)
        }
    }
    
}

struct TransparentTestView_Previews: PreviewProvider {
    
    static var previews: some View {
        TransparentTestView()
    }
    
}
#endif
