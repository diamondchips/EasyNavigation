//
//  ViewDestinationRepresentable.swift
//  EasyNavigation
//
//  Created by Salihcan Kahya on 2.05.2025.
//

import Foundation
import SwiftUI

public protocol ViewDestinationRepresentable {
    init?(from url: URL)
    var view: AnyView { get }
}
