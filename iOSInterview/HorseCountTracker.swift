//
//  HorseCountTracker.swift
//  iOSInterview
//
//  Created by Fadil Bećirović on 26. 10. 2025..
//


import SwiftUI
import SwiftData
import Combine

/// Looks innocent: keeps a cached total of horses and refreshes it.
final class HorseCountTracker: ObservableObject {
    static let shared = HorseCountTracker()
    private init() {}

    @Published var total: Int = 0       // <-- non-atomic, read/written across threads
    private var modelContext: ModelContext?
    private let q = DispatchQueue.global(qos: .utility) // concurrent, not confined

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    /// Re-counts from the store. (Runs on a background queue and publishes from there.)
    func refreshCount() {
        guard let ctx = modelContext else { return }
        q.async {
            // Intentionally do SwiftData fetch off-main and publish off-main:
            let descriptor = FetchDescriptor<Horse>()
            let c = (try? ctx.fetch(descriptor).count) ?? 0
            self.total = c // <-- publishing from background; not MainActor
        }
    }

    /// Called when a horse is inserted; “optimistically” bumps the cached value.
    func noteInsert() {
        let current = total // <-- read on caller's thread (often main)
        q.async {
            // tiny delay makes interleavings more likely
            usleep(150)
            self.total = current + 1 // <-- write on background: classic lost update window
        }
    }

    /// Called when a horse is deleted; “optimistically” decrements the cached value.
    func noteDelete() {
        let current = total
        q.async {
            self.total = current - 1
        }
    }
}
