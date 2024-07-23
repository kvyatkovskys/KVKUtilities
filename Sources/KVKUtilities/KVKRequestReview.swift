//
//  File.swift
//  KVKUtilities
//
//  Created by Sergei Kviatkovskii on 7/23/24.
//

import Foundation
import SwiftUI
import StoreKit

public final class RequestReview: AboutAppInfo {
    
    @AppStorage("runsSinceLastRequest") private var runsSinceLastRequest = 0
    @AppStorage("version") private var version = ""
    
    private let limit = 20
    
    public func showReviewIfNeeded() {
        runsSinceLastRequest += 1
        
        guard currentVersion != version else {
            runsSinceLastRequest = 0
            return
        }
        guard runsSinceLastRequest == limit, let scene = UIWindowScene.focused else { return }
                
        SKStoreReviewController.requestReview(in: scene)
        runsSinceLastRequest = 0
        version = currentVersion
    }
    
}

public protocol AboutAppInfo {}

public extension AboutAppInfo {
    
    var appBundleId: String? {
        Bundle.main.bundleIdentifier
    }
    
    var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }
    
    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var currentVersion: String {
        "Version \(appVersion) (\(appBuild))"
    }
    
}
