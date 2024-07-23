//
//  KVK+Extensions.swift
//  KVKUtilities
//
//  Created by Sergei Kviatkovskii on 7/23/24.
//

import SwiftUI

public extension ProcessInfo {
    var isPreviewMode: Bool {
        if let isPreview = environment["XCODE_RUNNING_FOR_PREVIEWS"], isPreview == "1" {
            return true
        } else {
            return false
        }
    }
}

public extension View {
    func setSkeleton(_ visible: Bool) -> some View {
        modifier(SkeletonView(isVisible: visible))
    }
}
