//
//  KVKPlatforms.swift
//
//
//  Created by Sergei Kviatkovskii on 11/4/23.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum Platform {
    case macOS, iOS, iPadOS

    public static let current: Platform = {
#if os(macOS)
        return .macOS
#else
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPadOS
        } else {
            return .iOS
        }
#endif
    }()
}
