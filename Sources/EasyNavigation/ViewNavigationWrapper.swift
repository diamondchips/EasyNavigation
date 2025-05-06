//
//  ViewNavigationWrapper.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import SwiftUI

public struct ViewNavigationWrapper: View {
    @State private var router: Router
    @Environment(RouterStack.self) private var routerStack
    
    public init<Content: View>(parent: Router? = nil, @ViewBuilder content: () -> Content) {
        let any = AnyView(content())
        router = Router(parent: parent)
        router.path.append(DestinationWrapper(destination: any))
    }
    
    public var body: some View {
        ViewBody(
            router: router
        ) {
            EmptyView()
        }
    }
}

public struct TabViewNavigationWrapper: View {
    @State private var router: Router
    @Environment(RouterStack.self) private var routerStack
    let content: AnyView
    
    public init<Content: View>(parent: Router? = nil, @ViewBuilder content: () -> Content) {
        router = Router(parent: parent)
        self.content = AnyView(content())
    }
    
    public var body: some View {
        ViewBody(
            router: router
        ) {
            content
        }
    }
    
    private func createNavigationInformation(isPushed: Bool) -> NavigationInformations {
        return NavigationInformations(
            isPushed: isPushed,
            isPresenting: router.parent != nil,
            navigationType: router.parent == nil ? .root : router.parent?.fullScreenDestination != nil ? .present : .sheet
        )
    }
}

private struct ViewBody<Content: View>: View {
    @Environment(RouterStack.self) private var routerStack
    
    @Bindable var router: Router
    let content: Content
    
    init(router: Router, @ViewBuilder content: () -> Content) {
        self.router = router
        self.content = content()
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: DestinationWrapper.self) { wrapper in
                    wrapper
                        .destination
                        .toolbar(.hidden, for: .navigationBar)
                        .environment(router)
                        .environment(createNavigationInformation(isPushed: router.path.first?.id != wrapper.id))
                }
        }
        .fullScreenCover(item: $router.fullScreenDestination, onDismiss: {
            router.fullScreenDestination = nil
        }) { wrapper in
            ViewNavigationWrapper(parent: router) {
                wrapper.destination
            }
            .environment(createNavigationInformation(isPushed: false))
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $router.sheetDestination, onDismiss: {
            router.sheetDestination = nil
        }) { wrapper in
            ViewNavigationWrapper(parent: router) {
                wrapper.destination
            }
            .environment(createNavigationInformation(isPushed: false))
            .toolbar(.hidden, for: .navigationBar)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { routerStack.push(router) }
        .onDisappear { routerStack.pop(router) }
    }
    
    private func createNavigationInformation(isPushed: Bool) -> NavigationInformations {
        return NavigationInformations(
            isPushed: isPushed,
            isPresenting: router.parent != nil,
            navigationType: router.parent == nil ? .root : router.parent?.fullScreenDestination != nil ? .present : .sheet
        )
    }
}

