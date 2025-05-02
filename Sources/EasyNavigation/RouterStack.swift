//
//  RouterStack.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import SwiftUI

@Observable
public final class RouterStack {
    public init() {}

    /// Weak wrapper to avoid retain-cycles
    private struct WeakRouter {
        weak var value: Router?
    }

    @ObservationIgnored
    private var stack: [WeakRouter] = []

    /// Call in `ViewNavigationWrapper.onAppear`
    func push(_ router: Router) {
        // temizle & ekle
        stack.removeAll { $0.value == nil }
        stack.append(WeakRouter(value: router))
    }

    /// Call in `ViewNavigationWrapper.onDisappear`
    func pop(_ router: Router) {
        stack.removeAll { $0.value === router || $0.value == nil }
    }

    /// Router currently on screen (sheet / fullscreen içinde dâhil)
    var topMostRouter: Router? {
        // nil’leri ayıkla, sonuncuyu ver
        stack = stack.filter { $0.value != nil }
        return stack.last?.value
    }
}
