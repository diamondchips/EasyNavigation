//
//  RouterActor.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import Foundation
import SwiftUI

actor RouterActor: Sendable {
    private var path: [DestinationWrapper]
    private var fullScreen: DestinationWrapper?
    private var sheet: DestinationWrapper?
    private let parent: RouterActor?
    
    init(parent: RouterActor? = nil, root: DestinationWrapper) {
        self.parent = parent
        self.path = [root]
    }
    
    // MARK: - Accessors
    func getPath() async -> [DestinationWrapper] { path }
    func getFullScreenDestination() async -> DestinationWrapper? { fullScreen }
    func getSheetDestination() async -> DestinationWrapper? { sheet }
    
    // MARK: - Setters
    func setPath(_ newPath: [DestinationWrapper]) async {
        path = newPath
    }
    
    // MARK: - Navigation Mutators
    func push(_ wrapper: DestinationWrapper) async {
        path.append(wrapper)
    }
    
    func pushAndRemoveSelf(_ wrapper: DestinationWrapper) async {
        if !path.isEmpty { 
            path.removeLast() 
        }
        path.append(wrapper)
    }
    
    func pushAndRemoveAll(_ wrapper: DestinationWrapper) async {
        path = [wrapper]
    }
    
    func pop() async {
        if !path.isEmpty { path.removeLast() }
    }
    
    func popToRoot() async {
        path.removeAll()
    }
    
    // MARK: - Sheet & FullScreen
    func present(_ wrapper: DestinationWrapper) async {
        // Clear any existing sheet before fullScreen
        sheet = nil
        fullScreen = wrapper
    }
    
    func sheet(_ wrapper: DestinationWrapper) async {
        // Clear any existing fullScreen before sheet
        fullScreen = nil
        sheet = wrapper
    }
    
    func clearFullScreen() async {
        fullScreen = nil
    }
    
    func clearSheet() async {
        sheet = nil
    }
    
    // MARK: - Dismissal
    func dismiss() async {
        if sheet != nil {
            sheet = nil
            return
        }
        if fullScreen != nil {
            fullScreen = nil
            return
        }
        if let parent = parent {
            await parent.dismiss()
        }
    }
    
    func dismissToRoot() async {
        sheet = nil
        fullScreen = nil
        path.removeAll()
        if let parent = parent {
            await parent.dismissToRoot()
        }
    }
}
