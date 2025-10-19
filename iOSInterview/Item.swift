//
//  Item.swift
//  iOSInterview
//
//  Created by Fadil Bećirović on 19. 10. 2025..
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
