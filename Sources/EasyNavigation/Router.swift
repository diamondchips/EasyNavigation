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
        let path = await actor.getPath()
        let fullScreen = await actor.getFullScreenDestination()
        let sheet = await actor.getSheetDestination()
        
        withAnimation {
            navigationPath = path
            fullScreenDestination = fullScreen
            sheetDestination = sheet
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
            // First get current path
            var currentPath = await actor.getPath()
            if !currentPath.isEmpty {
                currentPath.removeLast()
                currentPath.append(wrapper)
                
                // Update actor
                await actor.setPath(currentPath)
                
                // Apply animation explicitly
                withAnimation(.easeInOut) {
                    navigationPath = currentPath
                }
                
                // Sync other states
                fullScreenDestination = await actor.getFullScreenDestination()
                sheetDestination = await actor.getSheetDestination()
            }
        }
    }
    
    public func pushAndRemoveAll<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            // Create a new path with just the destination
            let newPath = [wrapper]
            
            // Update actor
            await actor.setPath(newPath)
            
            // Apply animation explicitly
            withAnimation(.easeInOut) {
                navigationPath = newPath
            }
            
            // Sync other states
            fullScreenDestination = await actor.getFullScreenDestination()
            sheetDestination = await actor.getSheetDestination()
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
