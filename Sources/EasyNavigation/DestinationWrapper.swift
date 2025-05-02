//
//  DestinationWrapper.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import Foundation
import SwiftUI

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
