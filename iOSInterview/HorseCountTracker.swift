//
//  HorseCountTracker.swift
//  iOSInterview
//
//  Created by Fadil Bećirović on 26. 10. 2025..
//

import SwiftUI
import SwiftData
import Combine

final class HorseCountTracker: ObservableObject {
    static let shared = HorseCountTracker()
    private init() {}

    @Published var total: Int = 0
    private var modelContext: ModelContext?
    private let q = DispatchQueue.global(qos: .utility)

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    func refreshCount() {
        guard let ctx = modelContext else { return }
        q.async {
            let descriptor = FetchDescriptor<Horse>()
            let c = (try? ctx.fetch(descriptor).count) ?? 0
            self.total = c
        }
    }

    func noteInsert() {
        let current = total
        q.async {
            usleep(150)
            self.total = current + 1
        }
    }

    func noteDelete() {
        let current = total
        q.async {
            self.total = current - 1
        }
    }
}
