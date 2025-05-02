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
        router = Router(parent: parent, rootDestination: any)
    }

    public var body: some View {
        NavigationStack(path: $router.navigationPath) {
            EmptyView()
                .navigationDestination(for: DestinationWrapper.self) { wrapper in
                    wrapper.destination
                        .environment(router)
                        .environment(getNavigationInformation(isPushed: router.navigationPath.first?.id != wrapper.id))
                        .toolbar(.hidden, for: .navigationBar)
                }
                .environment(router)
        }
        .fullScreenCover(item: $router.fullScreenDestination) { wrapper in
            ViewNavigationWrapper(parent: router) {
                wrapper.destination
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $router.sheetDestination) { wrapper in
            ViewNavigationWrapper(parent: router) {
                wrapper.destination
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { routerStack.push(router) }
        .onDisappear { routerStack.pop(router) }
    }
    
    private func getNavigationInformation(isPushed: Bool) -> NavigationInformations {
        NavigationInformations(
            isPushed: isPushed,
            isPresented: router.parent?.fullScreenDestination != nil || router.parent?.sheetDestination != nil,
            navigationType: router.parent == nil ? .root : router.parent?.fullScreenDestination != nil ? .present : .sheet
        )
    }
}
