//
//  DeepLinkCenter.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import Foundation

public actor DeepLinkCenter<ViewDestination: ViewDestinationRepresentable> {
    // Keeps links that arrived while app was “locked”
    private var pending: [ViewDestination] = []
    let routerStack: RouterStack
    
    public init(routerStack: RouterStack) {
        self.routerStack = routerStack
    }

    /// Call from AppDelegate / notification delegate / openURL
    public func enqueue(_ link: URL) async {
        guard let destination = ViewDestination(from: link) else { return }
        pending.append(destination)
        tryDeliver()
    }

    /// Call whenever login, onboarding, etc. finishes
    func tryDeliver() {
        // get front-most router (you expose this via Environment)
        if let router = routerStack.topMostRouter,
           let link   = pending.first
        {
            Task {
                pending.removeFirst()
                await route(link, on: router)
                tryDeliver()
            }
        }
    }

    @MainActor
    private func route(_ destination: ViewDestination, on router: Router) async {
        let view = destination.view
        Task { @MainActor in
            router.present {
                view
            }
        }
    }
}
