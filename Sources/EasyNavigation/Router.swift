//
//  Router.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import SwiftUI

@Observable
public class Router: @unchecked Sendable {
    var navigationPath: [DestinationWrapper] = []
    var fullScreenDestination: DestinationWrapper?
    var sheetDestination: DestinationWrapper?
    
    @ObservationIgnored
    private let actor: RouterActor
    
    @ObservationIgnored
    weak var parent: Router?
    
    public init(parent: Router? = nil, rootDestination: AnyView) {
        self.parent = parent
        let parentActor = parent?.actor
        let rootWrapper = DestinationWrapper(destination: rootDestination)
        self.actor = RouterActor(parent: parentActor, root: rootWrapper)
        navigationPath = [rootWrapper]
        Task { @MainActor in await syncState() }
    }
    
    private func syncState() async {
        _ = withAnimation {
            Task {
                navigationPath = await actor.getPath()
                fullScreenDestination = await actor.getFullScreenDestination()
                sheetDestination = await actor.getSheetDestination()
            }
        }
    }
    
    // MARK: - Navigation API
    public func push<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            await actor.push(wrapper)
            await syncState()
        }
    }
    
    public func pushAndRemoveSelf<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            // 1) Animasyonsuz olarak mevcut ekranı hem aktörden hem navPath'ten kaldır
            await actor.pushAndRemoveSelf(wrapper)
            await syncState()
        }
    }
    
    public func pushAndRemoveAll<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            await actor.pushAndRemoveAll(wrapper)
            await syncState()
        }
    }
    
    public func pop() {
        Task { @MainActor in
            await actor.pop()
            await syncState()
        }
    }
    
    public func popToRoot() {
        Task { @MainActor in
            await actor.popToRoot()
            await syncState()
        }
    }
    
    // MARK: - Sheets & Covers
    public func present<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            // clear sheet before presenting fullScreen
            await actor.clearSheet()
            await actor.present(wrapper)
            await syncState()
        }
    }
    
    public func sheet<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            // clear fullScreen before presenting sheet
            await actor.clearFullScreen()
            await actor.sheet(wrapper)
            await syncState()
        }
    }
    
    public func dismiss() {
        Task { @MainActor in
            await actor.dismiss()
            await syncState()
            if let parent {
                await parent.syncState()
            }
        }
    }
    
    public func dismissToRoot() {
        Task { @MainActor in
            await actor.dismissToRoot()
            await syncState()
            if let parent {
                await parent.syncState()
            }
        }
    }
}
