//
//  Router.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import SwiftUI

@Observable
open class Router {
    var fullScreenDestination: DestinationWrapper?
    var sheetDestination: DestinationWrapper?
    var navigationPath = [DestinationWrapper]()
    
    @ObservationIgnored
    let parent: Router?
    
    init(parent: Router? = nil, rootDestination: AnyView) {
        self.parent = parent
        navigationPath.append(DestinationWrapper(destination: rootDestination))
    }
    
    public func push<Content: View>(@ViewBuilder _ destination: () -> Content) {
        navigationPath.append(
            DestinationWrapper(
                destination: AnyView(destination())
            )
        )
    }
    
    public func pushAndRemoveSelf<Content: View>(@ViewBuilder _ destination: () -> Content) {
        var paths = navigationPath
        paths.removeLast()
        paths.append(DestinationWrapper(
            destination: AnyView(destination())
        ))
        
        navigationPath = paths
    }
    
    public func pushAndRemoveAll<Content: View>(@ViewBuilder _ destination: () -> Content) {
        navigationPath = [
            DestinationWrapper(
                destination: AnyView(destination())
            )
        ]
    }
    
    public func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    public func popToRoot() {
        pop()
        if navigationPath.isEmpty { return }
        popToRoot()
    }
    
    public func present<Content: View>(@ViewBuilder _ destination: () -> Content) {
        fullScreenDestination = DestinationWrapper(
            destination: AnyView(destination())
        )
    }
    
    public func sheet<Content: View>(@ViewBuilder _ destination: () -> Content) {
        sheetDestination = DestinationWrapper(
            destination: AnyView(destination())
        )
    }
    
    public func dismiss() {
        if let parent {
            if parent.sheetDestination != nil {
                parent.sheetDestination = nil
            } else if parent.fullScreenDestination != nil {
                parent.fullScreenDestination = nil
            }
        }
    }
    
    public func dismissToRoot() {
        if let parent {
            if parent.sheetDestination != nil {
                parent.sheetDestination = nil
            } else if parent.fullScreenDestination != nil {
                parent.fullScreenDestination = nil
            }
            
            parent.popToRoot()
        }
    }
}
