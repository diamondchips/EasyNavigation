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
    var root: () -> AnyView
    var path: [DestinationWrapper] = []
    var fullScreenDestination: DestinationWrapper?
    var sheetDestination: DestinationWrapper?
    
    // Added for animated root replacement
    var rootViewID: UUID = UUID()

    @ObservationIgnored
    weak var parent: Router?
    @ObservationIgnored
    let hasRoot: Bool
    
    // Task management
    @ObservationIgnored
    private var isExecutingOperation = false
    @ObservationIgnored
    private var pendingOperations: [@MainActor () -> Void] = []
    
    // Navigation timing control
    @ObservationIgnored
    public var operationDelay: Duration = .milliseconds(50)
    @ObservationIgnored
    public var waitForUIUpdate: Bool = true
    
    deinit {}
    
    private func executeOperation(_ operation: @escaping @MainActor () -> Void) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Add operation to queue
            pendingOperations.append(operation)
            
            // If already executing, just return - the operation will be picked up
            if isExecutingOperation {
                return
            }
            
            // Process all pending operations
            isExecutingOperation = true
            while !pendingOperations.isEmpty {
                print("Executing operation, \(pendingOperations.count) remaining")
                let nextOperation = pendingOperations.removeFirst()
                nextOperation()
                
                if waitForUIUpdate {
                    // Give UI a chance to update
                    await Task.yield()
                    
                    // Add a delay to ensure UI has time to update properly
                    if operationDelay > .zero {
                        try? await Task.sleep(for: operationDelay)
                    }
                }
            }
            isExecutingOperation = false
        }
    }
    
    public init<Content: View>(parent: Router? = nil, root: @escaping () -> Content) {
        self.parent = parent
        self.root = {
            AnyView(root())
        }
        self.rootViewID = UUID() // Initialize rootViewID
        self.hasRoot = false
    }
    
    // MARK: - Navigation API
    public func push<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(
            destination: AnyView(destination())
        )
        
        executeOperation { [weak self] in
            guard let self = self else { return }
            path.append(wrapper)
        }
    }
    
    @MainActor
    private func replaceRootWithAnimation<Content: View>(_ newRootViewGenerator: @escaping () -> Content) {
        let newRootID = UUID()
        let newGenerator = { AnyView(newRootViewGenerator()) }
        let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .identity)

        withAnimation(.default) {
            self.root = newGenerator
            self.rootViewID = newRootID
            self.path.removeAll()
        }
    }
    
    @MainActor
    private func pushAndRemoveSelfAnimated<Content: View>(_ destination: @escaping () -> Content) async {
        // Path is not empty. Replace the top view on the stack with an animation.
        let newDestinationWrapper = DestinationWrapper(destination: AnyView(destination()))
        
        // Operation 1: Append the new destination. This will be animated as a push.
        executeOperation { [weak self] in
            guard let self = self else { return }
            self.path.append(newDestinationWrapper)
        }
        
        
        do {
            try await Task.sleep(for: .milliseconds(400))
        } catch {
            // Handle cancellation if necessary, e.g., by not proceeding.
            print("Task.sleep in setNewRootAnimated was cancelled: \(error)")
            return
        }
        // Operation 2: Remove the item that was previously at the top (now second to last).
        // Do this without animation.
        // The existing executeOperation mechanism provides a small delay (operationDelay)
        // between Op1 and Op2 here.
        executeOperation { [weak self] in
            guard let self = self else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                // If path has at least 2 items (original_top, new_destination), remove original_top.
                if self.path.count >= 2 {
                    self.path.remove(at: self.path.count - 2)
                }
            }
        }
    }
    
    public func pushAndRemoveSelf<Content: View>(@ViewBuilder _ destination: @escaping () -> Content) {
        // Check current path state to decide strategy. Router is @MainActor.
        if self.path.isEmpty {
            // Use the new method for root replacement if path is empty
            executeOperation { [weak self] in
                self?.replaceRootWithAnimation(destination)
            }
        } else {
            Task {
               await pushAndRemoveSelfAnimated(destination)
            }
        }
    }
    
    public func pushAndRemoveAll<Content: View>(@ViewBuilder _ destination: @escaping () -> Content) {
        // Replace the entire navigation stack with the new destination as the root, animated as a push.
        // Use the new method for root replacement
        executeOperation { [weak self] in
            self?.replaceRootWithAnimation(destination)
        }
    }
    
    public func pop() {
        executeOperation { [weak self] in
            guard let self = self else { return }
            if !path.isEmpty {
                path.removeLast()
            }
        }
    }
    
    public func popToRoot() {
        executeOperation { [weak self] in
            guard let self = self else { return }
            path.removeAll()
        }
    }
    
    // MARK: - Sheets & Covers
    public func present<Content: View>(@ViewBuilder _ destination: () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        print("[Router] Present called. Attempting to present: \(type(of: destination()))") // Hangi view'ı present etmeye çalıştığımızı loglayalım.
        
        executeOperation { [weak self] in
            guard let self = self else {
                print("[Router] Executing operation for present: Self is nil.")
                return
            }
            print("[Router] Executing operation for present. Current fullScreenDestination: \(String(describing: self.fullScreenDestination))")
            self.sheetDestination = nil // Ensure only one modal type is active
            self.fullScreenDestination = wrapper
            print("[Router] fullScreenDestination set to wrapper with id: \(wrapper.id). View type: \(type(of: wrapper.destination))")
        }
    }
    
    public func sheet<Content: View>(@ViewBuilder _ destination: @escaping () -> Content) {
        let wrapper = DestinationWrapper(destination: AnyView(destination()))
        
        executeOperation { [weak self] in
            guard let self = self else { return }
            fullScreenDestination = nil
            sheetDestination = wrapper
        }
    }
    
    public func dismiss() {
        executeOperation { [weak self] in
            guard let self = self else { return }
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
        executeOperation { [weak self] in
            guard let self = self else { return }
            sheetDestination = nil
            fullScreenDestination = nil
            if let parent = parent {
                parent.dismissToRoot()
            }
        }
    }
    
    public func dismissPresented() {
        executeOperation { [weak self] in
            guard let self = self else { return }
            if sheetDestination != nil {
                sheetDestination = nil
            } else if fullScreenDestination != nil {
                fullScreenDestination = nil
            }
        }
    }
}
