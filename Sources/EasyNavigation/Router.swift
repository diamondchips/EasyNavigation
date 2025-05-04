//
//  Router.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import SwiftUI

@MainActor
@Observable
public class Router: @unchecked Sendable {
    var path: [DestinationWrapper] = []
    var fullScreenDestination: DestinationWrapper?
    var sheetDestination: DestinationWrapper?
    
    @ObservationIgnored
    weak var parent: Router?
    
    public init(parent: Router? = nil, rootDestination: AnyView) {
        self.parent = parent
        let wrapper = DestinationWrapper(destination: rootDestination)
        path = [wrapper]
    }
    
    // MARK: - Navigation API
    public func push<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(
            destination: AnyView(destination())
        )
        Task { @MainActor in
            path.append(wrapper)
        }
    }
    
    public func pushAndRemoveSelf<Content: View>(@ViewBuilder _ destination: @escaping () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            // First get current path
            var currentPath =  path
            if !currentPath.isEmpty {
                currentPath.removeLast()
                currentPath.append(wrapper)
                withAnimation(.easeInOut) {
                    path = currentPath
                }
            }
        }
    }
    
    public func pushAndRemoveAll<Content: View>(@ViewBuilder _ destination: @escaping () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            
            let newPath = [wrapper]
            withAnimation(.easeInOut) {
                path = newPath
            }
        }
    }
    
    public func pop() {
        Task { @MainActor in
            if path.count > 1 {
                path.removeLast()
            }
        }
    }
    
    public func popToRoot() {
        Task { @MainActor in
            path.removeAll()
        }
    }
    
    // MARK: - Sheets & Covers
    public func present<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            sheetDestination = nil
            fullScreenDestination = wrapper
        }
    }
    
    public func sheet<Content: View>(@ViewBuilder _ destination: @escaping () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        Task { @MainActor in
            fullScreenDestination = nil
            sheetDestination = wrapper
        }
    }
    
    public func dismiss() {
        Task { @MainActor in
            if parent?.sheetDestination != nil {
                parent?.sheetDestination = nil
                return
            }
            if parent?.fullScreenDestination != nil {
                parent?.fullScreenDestination = nil
                return
            }
        }
    }
    
    public func dismissToRoot() {
        
        Task { @MainActor in
            sheetDestination = nil
            fullScreenDestination = nil
            if let parent = parent {
                parent.dismissToRoot()
            }
        }
    }
    
    public func dismissPresented() {
        Task { @MainActor in
            if sheetDestination != nil {
                sheetDestination = nil
            } else if fullScreenDestination != nil {
                fullScreenDestination = nil
            }
        }
    }
}
