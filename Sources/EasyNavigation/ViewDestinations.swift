//
//  ViewDestinations.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import SwiftUI
import Combine

public protocol ViewDestinationRepresentable {
    init?(from url: URL)
    var view: AnyView { get }
}

public actor DeepLinkCenter<ViewDestination: ViewDestinationRepresentable> {
    // Keeps links that arrived while app was “locked”
    private var pending: [ViewDestination] = []
    let routerStack: RouterStack
    
    public init(routerStack: RouterStack) {
        self.routerStack = routerStack
    }

    /// Call from AppDelegate / notification delegate / openURL
    public func enqueue(_ link: URL) {
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
            pending.removeFirst()
            route(link, on: router)
            tryDeliver()
        }
    }

    private func route(_ destination: ViewDestination, on router: Router) {
        router.push {
            destination.view
        }
    }
}


struct DestinationWrapper: Identifiable, Hashable, Equatable {
    static func == (lhs: DestinationWrapper, rhs: DestinationWrapper) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: String
    let destination: AnyView
    init(destination: AnyView) {
        self.id = UUID().uuidString
        self.destination = destination
    }
}

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

@Observable
open class NavigationInformations {
    public let isPushed: Bool
    public let isPresented: Bool
    public let navigationType: NavigationType
    let id: String
    
    init(
        isPushed: Bool,
        isPresented: Bool,
        navigationType: NavigationType
    ) {
        self.isPushed = isPushed
        self.navigationType = navigationType
        self.isPresented = isPresented
        id = UUID().uuidString
    }
    
    public enum NavigationType {
        case root
        case present
        case sheet
    }
}

public struct ViewNavigationWrapper: View {
    
    @State var router: Router
    @Environment(RouterStack.self) private var routerStack
    
    public init<Content: View>(
        parent: Router? = nil,
        @ViewBuilder content: () -> Content
    ) {
        let anyView = AnyView(content())
        self.router = Router(
            parent: parent,
            rootDestination: anyView
        )
    }
    
    public var body: some View {
        NavigationStack(path: $router.navigationPath) {
            EmptyView()
                .navigationDestination(
                    for: DestinationWrapper.self,
                    destination: { wrapper in
                        wrapper
                            .destination
                            .environment(router)
                            .environment(getNavigationInformation(isPushed: router.navigationPath.first?.id != wrapper.id))
                            .toolbar(.hidden, for: .navigationBar)
                    }
                )
                .environment(router)
        }
        .fullScreenCover(item: $router.fullScreenDestination) { wrapper in
            ViewNavigationWrapper(
                parent: router,
                content: {
                    wrapper.destination
                }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $router.sheetDestination) { wrapper in
            ViewNavigationWrapper(
                parent: router,
                content: {
                    wrapper.destination
                }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear{ routerStack.push(router) }
        .onDisappear { routerStack.pop(router)  }
    }
    
    private func getNavigationInformation(isPushed: Bool) -> NavigationInformations {
        NavigationInformations(
            isPushed: isPushed,
            isPresented: router.parent?.fullScreenDestination != nil || router.parent?.sheetDestination != nil,
            navigationType: router.parent == nil ? .root : router.parent?.fullScreenDestination != nil ? .present : .sheet
        )
    }
}
