//
//  ContentView.swift
//  iOSInterview
//
//  Created by Fadil Bećirović on 19. 10. 2025..
//
import SwiftUI
import SwiftData

struct HomeScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]

    @StateObject private var tracker = HorseCountTracker.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Subtle, plausibly “useful” stat:
                HStack {
                    Text("Total horses:")
                    Text("\(tracker.total)").font(.title3).bold()
                }

                List {
                    ForEach(horses) { horse in
                        NavigationLink(destination: HorseDetailView(horse: horse)) {
                            VStack(alignment: .leading) {
                                Text(horse.name)
                                Text(horse.breed)
                                Text("\(horse.age) years old")
                            }
                        }
                    }
                    .onDelete(perform: deleteHorse)
                }
                .navigationTitle("Horse List")

                NavigationLink(destination: AddHorseView(modelContext: modelContext)) {
                    Text("Add Horse")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .onAppear {
                // Looks normal: set up and refresh once when the screen appears
                tracker.configure(with: modelContext)
                tracker.refreshCount()
            }
        }
    }

    private func deleteHorse(at offsets: IndexSet) {
        // Your original background delete — we’ll also “note” the change.
        DispatchQueue.global(qos: .background).async {
            for index in offsets {
                let horseToDelete = self.horses[index]
                self.modelContext.delete(horseToDelete)
                HorseCountTracker.shared.noteDelete() // innocuous, but racy
            }
            try? self.modelContext.save()
        }
    }
    
    // Function to check if horses list is empty and add dummy horses
    private func checkAndAddDummyHorses() {
        // If the horses list is empty, add some dummy horses
        if horses.isEmpty {
            let dummyHorses = [
                Horse(name: "Thunder", breed: "Arabian", age: 4),
                Horse(name: "Storm", breed: "Thoroughbred", age: 3),
                Horse(name: "Bella", breed: "Quarter Horse", age: 5)
            ]
            // Insert dummy horses into the model context
            dummyHorses.forEach { horse in
                modelContext.insert(horse)
            }
            print("Dummy horses added!")
        }
    }
}

struct AddHorseView: View {
    private let modelContext: ModelContext
    @State private var horseName = ""
    @State private var horseBreed = ""
    @State private var horseAge = ""
    @Environment(\.dismiss) var dismiss

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    var body: some View {
        Form {
            Section(header: Text("Horse Information")) {
                TextField("Enter Horse Name", text: $horseName)
                TextField("Enter Horse Breed", text: $horseBreed)
                TextField("Enter Horse Age", text: $horseAge)
            }
            Button("Save Horse") { addHorse() }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .navigationTitle("Add New Horse")
    }

    private func addHorse() {
        let newHorse = Horse(name: horseName, breed: horseBreed, age: Int(horseAge) ?? 0)
        modelContext.insert(newHorse)
        try? modelContext.save()

        // Subtle: bump the cached total “optimistically” from a different queue.
        DispatchQueue.global(qos: .userInitiated).async {
            HorseCountTracker.shared.noteInsert()
        }

        dismiss()
    }
}

struct HorseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State var horse: Horse // Mutable state for the horse

    var body: some View {
        VStack {
            Text("Editing Horse: \(horse.name)")
                .font(.largeTitle)
            
            TextField("Horse Name", text: $horse.name) // Directly modifying the horse name
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Horse Breed", text: $horse.breed) // Directly modifying the breed
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Horse Age", value: $horse.age, format: .number) // Modifying age
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Save Changes") {
                saveChanges() // Simulate saving changes (bad practice)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .navigationTitle("Horse Details")
    }

    private func saveChanges() {
        // Mistake: Unsafe modification of horse details in the background
        DispatchQueue.global(qos: .background).async {
            // Editing the horse's age in a background thread
            let modifiedHorse = self.horse
            modifiedHorse.age += 1 // Increment the horse's age
            
            DispatchQueue.main.async {
                // Applying changes on the main thread (wrong practice)
                self.horse = modifiedHorse // Update the horse in the view model unsafely
                print("Saved changes to the horse: \(modifiedHorse.name), Age: \(modifiedHorse.age)")
            }
        }
    }
}

@Model
final class Horse: Identifiable { // Ensuring it conforms to Identifiable
    var name: String
    var breed: String
    var age: Int
    var id: String { name } // Using name as the unique ID for simplicity, not safe at all!!!!
    
    init(name: String, breed: String, age: Int) {
        self.name = name
        self.breed = breed
        self.age = age
    }
}

#Preview {
    HomeScreenView()
}
