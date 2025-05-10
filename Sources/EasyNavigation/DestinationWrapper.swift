//
//  DestinationWrapper.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import Foundation
import SwiftUI

public struct DestinationWrapper: Identifiable, Hashable, @unchecked Sendable {
    public let id = UUID()
    let destination: AnyView
    let isTransitioningToRoot: Bool

    init(destination: AnyView, isTransitioningToRoot: Bool = false) {
        self.destination = destination
        self.isTransitioningToRoot = isTransitioningToRoot
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

